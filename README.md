# spec-pipeline

A shell script that processes feature specs through five isolated Claude Code sessions before any code gets written.

```
Draft spec → Refiner → Critic → Assembler → Second Critic → Resolver → Implementation-ready spec
```

Each phase runs in its own context window. The Critic has never seen the Refiner's reasoning — it only reads the output files. The Second Critic has never seen the pipeline that produced the final spec — it reviews with fresh eyes. This catches a category of bugs that single-pass review misses.

## What it does

**Phase 1 — Refiner.** Reads your spec, then reads your actual codebase. Checks every claim: do the types match? Do the storage keys exist? Do the route params match the real router? Are analytics events consistent with your naming conventions? Produces a reconciliation report and a refined spec with mismatches fixed.

**Phase 2 — Critic.** Starts fresh (new session, zero Refiner context). Checks different things: are stories atomic? What about edge cases? Are acceptance criteria clear? Is anything over-scoped? Are there UX gaps? Produces a critique report.

**Phase 3 — Assembler.** Merges findings into the final spec. Can fix factual errors (wrong type names, missing keys) but cannot change UX behavior — any UX-affecting finding becomes a `DECISION NEEDED` comment for you to resolve.

**Phase 4 — Second Critic.** Starts fresh (new session, zero pipeline context). Reviews the final spec as a senior engineer who has never seen it before. Evaluates implementation readiness — flags ambiguities, contradictions, missing details, and untestable acceptance criteria. Produces a final review report.

**Phase 5 — Resolver.** Reads the final spec and the second critic's review. Classifies each finding as VALID (applies the fix), NITPICK (ignores it), or REQUIRES DECISION (adds a `DECISION NEEDED` comment). Same guardrails as the Assembler — may fix factual errors and tighten acceptance criteria, but may not change UX behavior. Produces a resolution log and overwrites the final spec with fixes applied.

## Install

```bash
git clone https://github.com/yourusername/spec-pipeline.git
cd spec-pipeline
./install.sh /path/to/your/project
```

This copies two files into your project:
- `process-spec.sh` at the project root
- `.claude/commands/process-spec.md` for the slash command

And adds `.spec-pipeline/` to your `.gitignore`.

### Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Claude Pro or Max subscription (for CLI access)
- Run from your project root (so Claude Code picks up your `CLAUDE.md`)

## Usage

### Via Claude Code slash command

```
/process-spec path/to/spec.md
```

This runs the full pipeline and gives you a summary of findings.

### Via terminal

```bash
# Full pipeline
./process-spec.sh path/to/spec.md

# Full pipeline — all 5 phases including Second Critic + Resolver
./process-spec.sh path/to/spec.md --full

# Skip assembly — just get the two reports (phases 1-2 only)
./process-spec.sh path/to/spec.md --skip-assembly

# Show log tails after each phase
./process-spec.sh path/to/spec.md --verbose
```

## Output

Everything lands in `.spec-pipeline/`:

| File | Phase | Description |
|------|-------|-------------|
| `reconciliation-report.md` | Refiner | Every mismatch between spec and codebase |
| `refined-spec.md` | Refiner | Spec with factual errors fixed |
| `critique-report.md` | Critic | Edge cases, atomicity, scope, UX gaps |
| `final-spec.md` | Assembler / Resolver | Implementation-ready spec (updated by Resolver) |
| `final-review.md` | Second Critic | Implementation readiness review |
| `resolution-log.md` | Resolver | Disposition of each review finding |
| `*-log.txt` | All | Raw Claude Code output for debugging |

## What each phase checks

### Refiner
- Type/interface field names vs actual code
- Component, service, and hook existence
- Navigation params vs real router
- Storage keys, DB tables, cache keys
- Analytics events vs naming conventions
- API request/response shapes
- File manifest completeness
- Codebase pattern adherence

### Critic
- Story atomicity (2-5 files sweet spot)
- Hidden inter-story dependencies
- Edge cases (empty state, offline, unauth, out-of-order)
- Acceptance criteria clarity
- Over-scoping / gold-plating
- "Do not touch" guardrail validity
- Story sequencing logic
- Loading/error/transition state gaps
- Analytics event gaps
- Codebase convention adherence
- UX intent clarity (preventing downstream drift)

### Assembler constraints
The Assembler **may** change: type names, field names, storage keys, API contracts, missing edge case docs, story sequencing, acceptance criteria.

The Assembler **may not** change: UX behavior, component hierarchy, screen layout, copy/messaging, analytics events.

### Second Critic
- Implementation readiness (could an engineer start building tomorrow?)
- Ambiguities that would cause divergent implementations
- Missing details that force unplanned design decisions
- Internal contradictions
- Testability of acceptance criteria
- Edge case coverage gaps
- Scope reasonableness

### Resolver constraints
The Resolver classifies each Second Critic finding as VALID (fix it), NITPICK (ignore it), or REQUIRES DECISION (add a `DECISION NEEDED` comment).

The Resolver **may** change: type names, field names, storage keys, API contracts, missing edge case docs, story sequencing, acceptance criteria, missing documentation.

The Resolver **may not** change: UX behavior, component hierarchy, screen layout, copy/messaging, analytics events.

## How it works

The pipeline solves the DAG problem with the simplest approach that provides real context isolation: a shell script calling `claude -p` five times.

```
process-spec.sh
  │
  ├── claude -p (Refiner)
  │     Reads: spec + codebase
  │     Writes: reconciliation-report.md, refined-spec.md
  │
  │   ── context wall (files on disk only) ──
  │
  ├── claude -p (Critic)
  │     Reads: refined-spec.md, reconciliation-report.md
  │     Writes: critique-report.md
  │
  │   ── context wall (files on disk only) ──
  │
  ├── claude -p (Assembler)
  │     Reads: all three files
  │     Writes: final-spec.md
  │
  │   ── context wall (files on disk only) ──
  │
  ├── claude -p (Second Critic)
  │     Reads: final-spec.md + codebase
  │     Writes: final-review.md
  │
  │   ── context wall (files on disk only) ──
  │
  └── claude -p (Resolver)
        Reads: final-spec.md, final-review.md
        Writes: final-spec.md (updated), resolution-log.md
```

Each invocation is a completely separate Claude Code session. The Critic cannot see the Refiner's chain of thought — only its output files. The Second Critic has zero context about the pipeline — it reviews the final spec as if encountering it for the first time. This is the same reason code reviews work better when the reviewer isn't the author.

## Writing specs that work well with the pipeline

The pipeline is framework-agnostic, but it works best with specs that include:

- **Type definitions** — interfaces, schemas, or data shapes the Refiner can verify
- **A file manifest** — list of files to create or modify
- **Implementation stories** — atomic units of work (2-5 files each), sequenced with dependencies declared
- **"Do not touch" guardrails** — files and systems that must not change
- **Analytics events** — event names and properties the Refiner can check against your codebase
- **Edge cases** — the Critic will flag missing ones, but starting with some helps

## Customizing

The Refiner and Critic prompts live as plain text blocks inside `process-spec.sh`. Common customizations:

- Add project-specific checks to the Refiner (e.g., "verify all colors use design system tokens")
- Add domain-specific edge cases to the Critic (e.g., "what happens with 10k records?")
- Tighten Assembler guardrails if it makes changes you didn't authorize
- Adjust `--max-turns` if phases are running out of room (Refiner: 40, Critic: 25, Assembler: 15, Second Critic: 25, Resolver: 15)

## macOS note

macOS ships bash 3.2. The script uses `IFS= read -r -d '' VAR <<'EOF' || true` for prompt variables instead of `VAR=$(cat <<EOF)` because bash 3.2 misparses `)` inside heredocs nested in command substitution.

## Cost and time

Five Claude Code sessions per run. On a Max plan, this is included in your subscription. On API billing, roughly $3-8 per run depending on spec and codebase size. Wall clock: 15-30 minutes.

## When NOT to use this

- Trivial changes (copy tweaks, padding, colors)
- Pure backend work where the Critic's UX checks aren't relevant
- Exploratory prototyping where you're still figuring out what to build
- Hotfixes where speed matters more than process

## License

MIT

---
allowed-tools: Bash(./process-spec.sh:*), Read
description: Run the spec processing pipeline (Refiner → Critic → Assembler) on a spec file
---

Run the spec processing pipeline on the following spec:

```
./process-spec.sh $ARGUMENTS
```

After it finishes, read these files if they exist:
- .spec-pipeline/reconciliation-report.md
- .spec-pipeline/critique-report.md
- .spec-pipeline/final-spec.md
- .spec-pipeline/final-review.md
- .spec-pipeline/resolution-log.md

Give me a summary:
1. Refiner: count of MISMATCH, MISSING, SUGGESTION, VERIFIED findings
2. Critic: count of CRITICAL, IMPORTANT, NICE-TO-HAVE, WELL DONE findings
3. Second Critic: count of findings by area (ambiguities, missing details, edge cases, etc.)
4. Resolver: count of VALID, NITPICK, REQUIRES DECISION dispositions
5. Any DECISION NEEDED items from the final spec
6. Overall readiness assessment
7. Your recommendation: implement as-is, fix minor issues, or needs another pass

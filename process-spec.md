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

Give me a summary:
1. Refiner: count of MISMATCH, MISSING, SUGGESTION, VERIFIED findings
2. Critic: count of CRITICAL, IMPORTANT, NICE-TO-HAVE, WELL DONE findings
3. Any DECISION NEEDED items from the final spec
4. Overall readiness assessment
5. Your recommendation: implement as-is, fix minor issues, or needs another pass

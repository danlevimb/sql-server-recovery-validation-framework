<p align="center">
<a href="../README.md">Home</a> |
<a href="scheduler-behavior.md">Back</a>
</p>

# Scenario 9 — Backup Already in Progress
### A backup operation is currently running.

### 🔍 Evidence
  - Database is skipped

<p align="center">
  <img src="../../docs/evidence/images/Scenario9_BackupAlreadyinProgress.jpg" width="900">
</p>

### Interpretation
  - The scheduler avoids overlapping operations
  - Concurrency control is enforced
  - System stability is preserved

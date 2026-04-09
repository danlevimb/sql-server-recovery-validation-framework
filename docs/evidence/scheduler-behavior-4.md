<p align="center">
<a href="../README.md">Home</a> |
<a href="scheduler-behavior.md">Back</a>
</p>

# Scenario 4 — DIFF Backup Due
### Differential backup is required based on effective baseline.

### 🔍 Evidence
  - `DiffDue = 1`
  - `SelectedBackupType = DIFF`

<p align="center">
  <img src="../../docs/evidence/images/Scenario4_DIFFBackupDue.jpg" width="900">
</p>

### Interpretation
  - DIFF is evaluated against the latest effective baseline (FULL or DIFF)
  - Restore chain consistency is maintained

<p align="center">
<a href="../README.md">Home</a> |
<a href="scheduler-behavior.md">Back</a>
</p>

# Scenario 3 — FULL Backup Due
### Full backup frequency threshold has been reached.

### 🔍 Evidence
  - `FullDue = 1`
  - `SelectedBackupType = FULL`

<p align="center">
  <img src="../../docs/evidence/images/Scenario3_FullBackupDue.jpg" width="900">
</p>

### Interpretation
  - FULL backups take precedence over other types
  - Baseline reset is correctly applied
  - DIFF chain integrity is preserved

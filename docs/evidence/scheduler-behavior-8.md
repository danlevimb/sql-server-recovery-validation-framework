<p align="center">
<a href="../README.md">Home</a> |
<a href="scheduler-behavior.md">Back</a>
</p>

# Scenario 8 — Correlation Across Execution
### Multiple backups executed within the same scheduler run.

### 🔍 Evidence
```sql
SELECT DatabaseName, BackupType, CorrelationID
FROM log.BackupRun
ORDER BY StartedAt DESC;
```
<p align="center">
  <img src="../../docs/evidence/images/Scenario8_CorrelationAcrossExecution.jpg" width="900">
</p>

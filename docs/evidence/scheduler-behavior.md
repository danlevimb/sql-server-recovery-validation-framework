<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a>
</p>

# Scheduler Behavior

This section demonstrates how the framework behaves under different runtime conditions when executing the policy-driven scheduler:

- [`cfg.usp_RunScheduledBackups`](../../docs/procedures/usp_RunScheduledBackups.md)

The goal is to validate that the system:

- Makes correct decisions based on configuration  
- Adapts dynamically to changing conditions  
- Maintains operational consistency  
- Avoids unnecessary or redundant executions  

---

# Overview

The scheduler operates under a **trigger-based model**:

  - A SQL Server Agent Job runs every 5 minutes  
  - The procedure evaluates all databases  
  - Decisions are made dynamically using:
  - Configuration ([`[cfg].[Tier]`](../../sql/01_Tables/cfg.Tier.md), [`[cfg].[DatabasePolicy]`](../../sql/01_Tables/cfg.DatabasePolicy.md))  
  - Execution history ([`[log].[BackupRun]`](../../sql/01_Tables/log.BackupRun.md))  

---

# Scenario 1 — No Backup Due
### Description

No backup frequency thresholds have been reached.

---

### Execution

```sql
EXEC cfg.usp_RunScheduledBackups
    @DryRun = 1,
    @Debug = 1;
```

### 🔍 Evidence
<p align="center">
  <img src="../../docs/evidence/images/Scenario1_NoBackupDue.jpg" width="900">
</p>

Decision matrix showing:
  - SelectedBackupType = NULL
  - DecisionReason = 'No backup due in current cycle'
  
### Interpretation
  - The scheduler evaluates correctly
  - No unnecessary backups are executed
  - System remains idle when no action is required

# Scenario 2 — LOG Backup Due
### Description

Transaction log frequency has been exceeded.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]

*Decision matrix showing:*
  - `LogDue = 1`
  - `SelectedBackupType = LOG`
  - `DecisionReason = 'LOG frequency reached'`

### Interpretation
  - LOG backups are triggered precisely when required
  - Frequency is respected per Tier configuration
  - RPO enforcement is consistent

# Scenario 3 — FULL Backup Due
### Description

Full backup frequency threshold has been reached.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]
    - `FullDue = 1`
    - `SelectedBackupType = FULL`

### Interpretation
  - FULL backups take precedence over other types
  - Baseline reset is correctly applied
  - DIFF chain integrity is preserved

# Scenario 4 — DIFF Backup Due
### Description

Differential backup is required based on effective baseline.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]
  - `DiffDue = 1`
  - `SelectedBackupType = DIFF`

### Interpretation
  - DIFF is evaluated against the latest effective baseline (FULL or DIFF)
  - Restore chain consistency is maintained

# Scenario 5 — Recovery Model Constraint
### Description

Database is configured with SIMPLE recovery model.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]
  - `recovery_model_desc = SIMPLE`
  - `SelectedBackupType = NULL`

### Interpretation
  - LOG backups are correctly skipped
  - Recovery model rules are enforced
  - No invalid operations are attempted

# Scenario 6 — FULL Does Not Reset LOG Cadence
## Description

A FULL backup is executed, followed shortly by a scheduler cycle.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]  
  - Recent FULL backup exists
  - `LastLogAt` still older than LOG frequency
  - `SelectedBackupType = LOG`

### Interpretation
  - LOG cadence remains stable
  - FULL backups do not reset LOG timing
  - RPO is preserved independently

# Scenario 7 — Multiple Databases, Independent Decisions
### Description

Multiple databases evaluated in a single execution cycle.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]

|DatabaseName |	SelectedBackupType |
|-------|--------|
|LabCriticalDB | LOG |
|TestCDC | LOG |
|WideWorldImporters |	NULL |

### Interpretation
  - Each database is evaluated independently
  - Different decisions can coexist in the same cycle
  - Scheduler behaves as a per-database decision engine

# Scenario 8 — Correlation Across Execution
### Description

Multiple backups executed within the same scheduler run.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]

```sql
SELECT DatabaseName, BackupType, CorrelationID
FROM log.BackupRun
ORDER BY StartedAt DESC;
```

### Interpretation
  - All operations share a common CorrelationID
  - Execution grouping is preserved
  - Traceability across operations is ensured

# Scenario 9 — Backup Already in Progress
### Description

A backup operation is currently running.

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]
  - `HasRunningBackup = 1`
  - Database is skipped

### Interpretation
  - The scheduler avoids overlapping operations
  - Concurrency control is enforced
  - System stability is preserved

# Scenario 10 — Dynamic Policy Change
### Description

Tier configuration or database policy is modified.

### Example

```sql
UPDATE cfg.Tier
SET Log_Freq_Minutes = 10
WHERE TierID = 0;
```

🔍 Evidence
👉 [INSERT SCREENSHOT HERE]
  - Scheduler adapts immediately
  - New frequency is applied without restart

### Interpretation
  - System is fully metadata-driven
  - No job changes required
  - Behavior adjusts dynamically

### Key Observations
  - Decisions are made at runtime, not predefined
  - Backup execution is demand-driven
  - System adapts instantly to configuration changes
  - Operational cadence is preserved
  - Concurrency and integrity constraints are enforced

# Conclusion

The scheduler behaves as a dynamic decision engine, not a static job executor.

It ensures that:

  - Backups are executed only when required
  - Policies are consistently enforced
  - System behavior remains predictable and traceable

This transforms backup scheduling into an adaptive, policy-driven system aligned with real operational needs.




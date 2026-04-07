<p align="center">
<a href="/README.md">Home</a> |
<a href="../docs/architecture.md">Architecture</a>
</p>

# Examples

This section demonstrates practical usage scenarios of the framework across its main operational stages:

- Backup Stage
- Restore Stage 
- Recovery Validation  

Each example reflects real-world situations where the framework can be applied independently or as part of an integrated workflow.

---

# Backup Stage

### 1. Batch Backup Execution by Tier

Execute backups for all databases within a specific Tier.

```sql
EXEC cfg.usp_BackupByTierAndType
    @BackupType = 'FULL',
    @TierID = 1,
    @PathType = 'PRIMARY',
    @WithCompression = 1,
    @WithChecksum = 1;
```
### 2. Single Database Backup

Execute a backup for a specific database.
```sql
EXEC cfg.usp_BackupDatabase
    @DatabaseName = 'LabCriticalDB',
    @BackupType = 'LOG',
    @PathType = 'PRIMARY',
    @WithCompression = 1,
    @WithChecksum = 1;
```

Use case:

Emergency backup before critical operations
Manual intervention scenarios

### 3. Automated Backup Scheduling (Policy-Driven)

Trigger the intelligent backup scheduler.

```sql
EXEC cfg.usp_RunScheduledBackups
    @DryRun = 1,
    @Debug = 1;
EXEC cfg.usp_RunScheduledBackups;
```

Use case:

Fully automated backup execution
Policy-driven environments
Continuous RPO enforcement

# Restore Stage

### 4. Full Restore Validation Scenario

Execute a complete restore validation workflow.

```sql
EXEC cfg.usp_RunRestoreTests
    @SourceDatabase = 'LabCriticalDB';
```

Use case:

Continuous recovery validation
Disaster recovery testing
Backup reliability verification

### 5. Point-in-Time Restore (STOPAT)

Restore a database to a specific moment in time.

```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_StopAt',
    @StopAt = '2026-04-06 12:17:00.000';
```

Use case:

Recover from accidental updates or deletes
Data correction after logical errors

### 6. Marker-Based Restore (STOPBEFOREMARK)

Restore to a transaction boundary defined by a marker.

```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_BeforeMark',
    @StopBeforeMark = 'RT_20260406_121500';
```

Use case:

Application release rollback
Recovery to a known safe state
Controlled rollback scenarios

# Validation Stage

### 7. Canary-Based Validation (Integrated)

Execute full validation via orchestrator.

```sql
EXEC cfg.usp_RunRestoreTests
    @SourceDatabase = 'LabCriticalDB',
    @Debug = 1;
```

Use case:

Validate recovery boundaries automatically
Ensure data integrity across restore operations

### 8. Manual Canary Validation

Validate restore correctness using a specific marker.

```sql
EXEC cfg.usp_ValidatePitrCanary
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_BeforeMark',
    @MarkName = 'RT_20260406_121500';
```

Use case:

Targeted validation of recovery scenarios
Independent verification workflows
Advanced Scenarios

### 9. Recovery After Critical Data Corruption

Scenario:

Accidental UPDATE without WHERE
Restore required to precise moment

```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_Recovery',
    @StopAt = '2026-04-06 11:59:59.000';
```

### 10. Pre-Deployment Safety Marker

Create a marker before a major release:

```sql
BEGIN TRANSACTION ReleaseMarker
WITH MARK 'PRE_RELEASE_20260406';
COMMIT;
```

Then restore if needed:

```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_PreRelease',
    @StopBeforeMark = 'PRE_RELEASE_20260406';
```

### 11. Audit and Traceability

Retrieve execution history:

```sql
SELECT *
FROM log.BackupRun
ORDER BY StartedAt DESC;
SELECT *
FROM log.RestoreTestRun
ORDER BY StartedAt DESC;
SELECT *
FROM log.RestoreStepExecution
ORDER BY RestoreRunID, StepOrder;
```

Use case:

Audit compliance
Forensic analysis
Performance tracking
Summary

The framework supports multiple usage patterns:

Automated operation via policy-driven scheduling
Manual execution for targeted scenarios
Validation workflows for continuous recovery assurance

Each component can be used independently or combined into a complete data protection and recovery validation pipeline.

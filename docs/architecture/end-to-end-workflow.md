<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# End-to-End Workflow

The framework executes a complete data protection and recovery validation cycle by combining **policy-driven backup orchestration**, **deterministic restore logic**, and **data-level validation**.

---

### 1. Scheduling Trigger

A SQL Server Agent Job executes the orchestration procedure at a fixed interval (e.g. every 5 minutes):

- [`cfg.usp_RunScheduledBackups`](../../docs/procedures/usp_RunScheduledBackups.md)

The job itself does not contain logic; it acts as a **trigger mechanism** that activates the decision engine.

---

### 2. Policy Evaluation (Decision Engine)

The orchestration layer evaluates backup requirements dynamically:

- Reads configuration from [`cfg.Tier`](../../sql/01_Tables/cfg.Tier.md) and [`cfg.DatabasePolicy`](../../sql/01_Tables/cfg.DatabasePolicy.md)  
- Retrieves historical execution data from [`log.BackupRun`](../../sql/01_Tables/log.BackupRun.md)  
- Determines whether FULL, DIFF, or LOG backups are due  
- Applies precedence rules: **FULL > DIFF > LOG**  
- Skips databases not eligible or already in execution  

This step transforms static configuration into **runtime decisions**.

---

### 3. Backup Execution

The framework executes backups at a per-database level using [`cfg.usp_BackupDatabase`](../../docs/procedures/usp_BackupDatabase.md).

Optionally, batch execution can be performed using [`cfg.usp_BackupByTierAndType`](../../docs/procedures/usp_BackupByTierAndType.md).

Backups include:

- FULL (`.bak`)  
- DIFFERENTIAL (`.bak`)  
- TRANSACTION LOG (`.trn`)  

Execution is correlated using a shared `CorrelationID`.

---

### 4. Backup Storage

Backup files are written to logical storage paths defined by the framework:

- PRIMARY  
- SECONDARY (optional mirror)  
- RESTORE_TEST (used for validation scenarios)  

Storage paths are resolved dynamically via:

- [`cfg.usp_GetActiveBasePath`](../../docs/procedures/usp_GetActiveBasePath.md)  
- [`cfg.usp_GetRestoreTestBasePath`](../../docs/procedures/usp_GetRestoreTestBasePath.md)  

---

### 5. Metadata Collection

The framework retrieves backup and transaction metadata from SQL Server system sources:

- `msdb.dbo.backupset`  
- `msdb.dbo.backupmediafamily`  
- `msdb.dbo.logmarkhistory`  
- `sys.fn_dump_dblog`  

This metadata is used to:

- Identify valid backup chains  
- Validate LSN continuity  
- Determine recovery boundaries  
- Locate marked transactions  

---

### 6. Scenario Definition (Orchestration)

The orchestration layer defines the recovery validation scenario using [`cfg.usp_RunRestoreTests`](../../docs/procedures/usp_RunRestoreTests.md)

This step:

- Selects the source database  
- Defines recovery mode:
  - Point-in-time (`STOPAT`)  
  - Marker-based (`STOPBEFOREMARK`)  
- Inserts canary records and marked transactions  

---

### 7. Restore Chain Planning

The framework determines the correct sequence of backup files using [`cfg.usp_GetLatestBackupFiles`](../../docs/procedures/usp_GetLatestBackupFiles.md)

This includes:

- Selecting the appropriate FULL backup  
- Matching DIFFERENTIAL backup (if applicable)  
- Identifying required LOG sequence  
- Validating LSN continuity  

---

### 8. Restore Execution

The restore engine reconstructs the database state using [`cfg.usp_RestorePointInTime`](../../docs/procedures/usp_RestorePointInTime.md)

This step:

- Applies FULL → DIFF → LOG sequence  
- Uses recovery boundaries:
  - `STOPAT`  
  - `STOPBEFOREMARK`  
- Restores into an isolated target environment  

---

### 9. Data-Level Validation

The validation layer verifies recovery correctness:

- [`cfg.usp_ValidatePitrCanary`](../../docs/procedures/usp_ValidatePitrCanary.md)  
- [`dbo.PitrCanary`](../../sql/01_Tables/dbo.PitrCanary.md)

This step:

- Evaluates canary records before and after the recovery boundary  
- Confirms expected data presence or absence  
- Validates that the restore reflects the intended point in time  

---

### 10. Telemetry Capture

All execution details are recorded:

- Backup execution → [`log.BackupRun`](../../sql/01_Tables/log.BackupRun.md)  
- Restore execution (header) → [`log.RestoreTestRun`](../../sql/01_Tables/log.RestoreTestRun.md)  
- Step-level trace (detail) → [`log.RestoreStepExecution`](../../sql/01_Tables/log.RestoreStepExecution.md)  

Captured data includes:

- Execution timing  
- Success or failure status  
- Restore chain details  
- Validation results  

---

### 11. Recovery Evidence and Analysis

The framework produces actionable evidence of recoverability:

- Verified restore capability  
- Confirmed recovery boundaries  
- Measured recovery time (RTO)  
- Traceable execution history  

This enables:

- Operational confidence in backup strategies  
- Auditability and forensic analysis  
- Continuous improvement of recovery processes  

---

### Summary

The framework transforms backup operations into a **continuous validation system**.

Instead of assuming recoverability, each cycle:

- Evaluates backup needs  
- Executes protection actions  
- Validates recovery capability  
- Produces measurable evidence  

This ensures that data protection is not only implemented, but **continuously verified and trusted**.

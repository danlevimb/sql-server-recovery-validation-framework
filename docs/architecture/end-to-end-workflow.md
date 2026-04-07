<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# End-to-End Workflow

The framework executes a complete recovery validation cycle by orchestrating backup artifacts, restore logic, and data-level verification into a deterministic workflow.

---

### 1. Backup Generation

SQL Server Agent Jobs generate backup files according to the defined strategy:

- FULL backups (`.bak`)  
- DIFFERENTIAL backups (`.bak`)  
- TRANSACTION LOG backups (`.trn`)  

These backups are created using standardized procedures and stored in configured locations.

---

### 2. Backup Storage

Backup files are written to logical storage paths defined by the framework:

- PRIMARY  
- SECONDARY (optional mirror)  
- RESTORE_TEST (used for validation scenarios)  

Storage paths are resolved dynamically through the configuration layer.

---

### 3. Metadata Collection

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

### 4. Scenario Definition (Orchestration)

The orchestration layer ([`cfg.usp_RunRestoreTests`](../../docs/procedures/usp_RunRestoreTests.md)) defines the recovery scenario:

- Selects the source database  
- Defines the target restore mode:
  - Point-in-time (`STOPAT`)  
  - Marker-based (`STOPBEFOREMARK`)  
- Optionally inserts canary records and marked transactions  

This step establishes the intended recovery boundary.

---

### 5. Restore Chain Planning

The framework determines the correct sequence of backup files required for the restore:

- Selects the appropriate FULL backup  
- Optionally selects a matching DIFFERENTIAL backup  
- Identifies the required TRANSACTION LOG sequence  
- Validates LSN continuity across all files  

This ensures a deterministic and valid restore chain.

---

### 6. Restore Execution

The restore engine ([`cfg.usp_RestorePointInTime`](../../docs/procedures/usp_RestorePointInTime.md)) executes the restore process:

- Applies FULL → DIFF → LOG backups in sequence  
- Uses recovery boundaries:
  - `STOPAT` for time-based recovery  
  - `STOPBEFOREMARK` for marker-based recovery  
- Restores the database into an isolated target environment  

At this stage, the database is reconstructed to the intended state.

---

### 7. Data-Level Validation

The validation layer verifies the correctness of the restore operation:

- Evaluates canary records inserted before and after the recovery boundary  
- Confirms whether expected data is present or excluded  
- Determines if the restore reflects the intended point in time  

This step transforms restore execution into **deterministic validation**.

---

### 8. Telemetry Capture

All execution details are recorded in the telemetry layer:

- Backup execution ([`log.BackupRun`](../../sql/01_Tables/log.BackupRun.md))  
- Restore test execution ([`log.RestoreTestRun`](../../sql/01_Tables/log.RestoreTestRun.md))  
- Step-level execution trace ([`log.RestoreStepExecution`](../../sql/01_Tables/log.RestoreStepExecution.md))  

Captured data includes:

- Execution timing  
- Success or failure status  
- Restore chain details  
- Validation results  

---

### 9. Recovery Evidence and Analysis

The framework produces actionable evidence of recoverability:

- Verification of successful restore operations  
- Confirmation of correct recovery boundaries  
- Measurement of practical recovery time  
- Traceability of execution steps and errors  

This enables:

- Operational confidence in backup strategies  
- Auditability and forensic analysis  
- Continuous improvement of recovery processes  

---

### Summary

Through this workflow, the framework ensures that backup processes are not only executed, but also continuously validated.

Each execution cycle transforms backup artifacts into **verified recovery capability**, supported by traceable evidence and measurable outcomes.

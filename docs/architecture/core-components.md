<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# Core Components

The framework is composed of a set of modular components organized into functional layers. Each layer is responsible for a specific aspect of the backup and recovery validation process, enabling separation of concerns and flexible usage.

<p align="center">
  <img src="/diagrams/framework-architecture.png" width="900">
</p>

---

### Orchestration Layer

The orchestration layer coordinates both **backup scheduling** and **recovery validation workflows**, acting as the primary entry point for automated operations.

| Feature | Description |
|---------|-------------|
| Policy-driven execution | Backup behavior is controlled entirely by configuration (cfg.Tier, cfg.DatabasePolicy) |
| Dynamic adaptability | Changes in frequency or inclusion rules take effect immediately without modifying jobs |
| Deterministic behavior | Decisions are based on actual execution history (log.BackupRun), not static schedules |
| Reduced operational complexity | A single job replaces multiple scheduled backup jobs |
| Efficient execution | Backups run only when required, avoiding redundant operations |

- `[cfg].[usp_RunScheduledBackups]`  
- `[cfg].[usp_RunRestoreTests]`

This layer is responsible for:

- Evaluating backup policies and determining required operations  
- Triggering backup execution based on dynamic conditions  
- Selecting databases and defining recovery validation scenarios  
- Generating canary records and marked transactions  
- Coordinating restore execution workflows  
- Orchestrating validation and telemetry capture  

It acts as the central control plane for both **data protection** and **recoverability validation**.

---

### Backup Execution Layer

The backup execution layer is responsible for performing backup operations at both **granular** and **batch levels**.

- `[cfg].[usp_BackupDatabase]`  
- `[cfg].[usp_BackupByTierAndType]`

This layer provides:

- Execution of FULL, DIFF, and LOG backups per database  
- Batch execution of backups grouped by Tier and type  
- Support for mirrored backups (PRIMARY / SECONDARY paths)  
- Backup verification (`VERIFYONLY`) and integrity options  
- Compression and checksum support  
- Correlated execution across multiple databases  

It represents the operational layer that materializes backup decisions into physical backup artifacts.

---

### Restore Execution Layer

The restore execution layer is responsible for reconstructing and executing restore chains.

- `[cfg].[usp_RestorePointInTime]`  
- `[cfg].[usp_GetLatestBackupFiles]`

This layer provides:

- Deterministic restore chain planning (FULL / DIFF / LOG)  
- LSN-based validation of log sequence continuity  
- Support for point-in-time recovery (`STOPAT`)  
- Support for marker-based recovery (`STOPBEFOREMARK`)  
- Execution of restore commands based on computed boundaries  

It represents the core engine that transforms backup artifacts into a restored database state.

---

### Validation Layer

The validation layer verifies that the restored database state matches the intended recovery boundary.

- `[cfg].[usp_ValidatePitrCanary]`  
- `[dbo].[PitrCanary]`

This layer is responsible for:

- Inserting reference (canary) records before and after recovery boundaries  
- Associating canary records with marked transactions  
- Validating whether restored data reflects the expected point in time  
- Producing deterministic evidence of recovery correctness  

This layer ensures that restore success is evaluated not only technically, but functionally.

---

### Configuration Layer

The configuration layer defines the policies and parameters that drive framework behavior.

- `[cfg].[Tier]`  
- `[cfg].[DatabasePolicy]`  
- `[cfg].[BackupPaths]`  
- `[cfg].[usp_GetActiveBasePath]`  
- `[cfg].[usp_GetRestoreTestBasePath]`

This layer enables:

- Tier-based backup and recovery strategies (RPO / RTO driven)  
- Database-level inclusion and backup configuration  
- Dynamic resolution of storage paths  
- Centralized path abstraction for backup and restore operations  
- Policy-driven execution without hardcoded logic  

It provides the control plane for the framework.

---

### Telemetry Layer

The telemetry layer captures execution data, enabling traceability, auditing, and analysis.

- `[log].[BackupRun]`  
- `[log].[RestoreTestRun]`  
- `[log].[RestoreStepExecution]`

This layer records:

- Backup execution details and configuration  
- Restore test execution results  
- Step-by-step restore chain execution  
- Errors, timing, and validation outcomes  

It acts as the observability layer of the framework, providing evidence for recovery operations and supporting operational analysis.

---

### Component Interaction

These components operate together as a coordinated pipeline:

- The orchestration layer evaluates policies and initiates execution  
- The backup execution layer generates backup artifacts  
- The restore execution layer reconstructs and applies restore chains  
- The validation layer verifies recovery correctness at the data level  
- The telemetry layer records execution and validation evidence  
- The configuration layer governs behavior across all components  

This modular design allows the framework to function both as an integrated system and as a set of reusable capabilities.

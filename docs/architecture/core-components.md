<p align="center">
<a href="README.md">Home</a> |
<a href="../architecture.md">Back</a>
</p>

# Core Components

The framework is composed of a set of modular components organized into functional layers. Each layer is responsible for a specific aspect of the recovery validation process, enabling separation of concerns and flexible usage.

---

### Orchestration Layer

The orchestration layer coordinates end-to-end restore validation scenarios.

- `[cfg].[usp_RunRestoreTests]`

This component is responsible for:

- Selecting databases and defining recovery scenarios  
- Generating canary records and marked transactions  
- Triggering restore execution workflows  
- Coordinating validation and telemetry capture  

It acts as the central entry point for automated recovery validation and enables full pipeline execution.

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

This layer enables:

- Tier-based backup and recovery strategies (RPO / RTO driven)  
- Database-level inclusion and backup configuration  
- Dynamic resolution of storage paths  
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

- The orchestration layer initiates recovery validation scenarios  
- The restore execution layer reconstructs and applies the restore chain  
- The validation layer verifies recovery correctness at the data level  
- The telemetry layer records execution and validation evidence  
- The configuration layer governs behavior across all components  

This modular design allows the framework to function both as an integrated system and as a set of reusable capabilities.

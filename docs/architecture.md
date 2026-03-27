<p align="center">
<a href="README.md">Home</a> |
<a href="docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

---

# Architecture

## Overview
## Ecosystem Context
## Architecture Diagram
## Core Components
## End-to-End Workflow
## Modular Usage Scenarios
## Restore Chain Planning
## Recovery Validation Model
## Telemetry and Evidence
## Design Principles
## Scope and Assumptions

## Ecosystem Context

The framework operates on top of an existing SQL Server backup ecosystem and assumes the presence of a structured environment where backup generation, storage, and metadata tracking are already in place.

Rather than introducing a new backup mechanism, the solution integrates with these existing components to perform restore validation and recoverability analysis.

### SQL Server Instance

The framework is designed to work with one or more SQL Server instances hosting databases of different criticality levels, such as:

- Production databases  
- Critical business databases  
- Test or staging environments  

These databases are the source of backup generation and the origin of restore validation scenarios.

---

### Backup Generation (SQL Server Agent Jobs)

Backups are assumed to be generated automatically through scheduled jobs, typically implemented using SQL Server Agent.

These jobs execute backup procedures that produce:

- FULL backups (`.bak`)  
- DIFFERENTIAL backups (`.bak`)  
- TRANSACTION LOG backups (`.trn`)  

The framework does not depend on a specific implementation, but it can integrate seamlessly with standardized procedures such as `[cfg].[usp_BackupDatabase]` or `[cfg].[usp_BackupByTierAndType]`, which also provide execution traceability.

---

### Backup Storage

Backup files are written to predefined storage locations that are logically separated by purpose. A typical configuration includes:

- **PRIMARY** → main backup storage location  
- **SECONDARY** → optional mirrored or redundant storage  
- **RESTORE_TEST** → isolated location used for restore validation scenarios  

These paths are abstracted through the configuration layer (`cfg.BackupPaths`), allowing the framework to dynamically resolve storage locations without hardcoded dependencies.

---

### System Metadata

The framework relies heavily on SQL Server system metadata to reconstruct restore chains and determine recovery boundaries.

Key sources include:

- `msdb.dbo.backupset`  
- `msdb.dbo.backupmediafamily`  
- `msdb.dbo.logmarkhistory`  
- `sys.fn_dump_dblog`  

These components provide:

- Backup history and file locations  
- LSN continuity and chain validation  
- Marked transaction metadata  
- Transaction-level commit time boundaries  

This metadata-driven approach enables deterministic selection of backup files and precise point-in-time recovery.

---

### Execution Context

The framework is typically deployed within a dedicated database (e.g., `DBAFramework`) that contains:

- Configuration tables (`cfg.*`)  
- Stored procedures for orchestration and execution  
- Logging and telemetry tables (`log.*`)  

However, validation artifacts such as canary records (`dbo.PitrCanary`) are created within the source databases being tested, allowing the framework to validate recovery behavior directly at the data level.

---

### Summary

In this ecosystem, the framework acts as a **non-intrusive validation layer** that leverages existing backup processes, storage, and metadata to continuously verify that recovery objectives can be met in practice.

It does not generate backups by itself; instead, it ensures that existing backups are **usable, consistent, and recoverable to the desired point in time**.

## Core Components

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

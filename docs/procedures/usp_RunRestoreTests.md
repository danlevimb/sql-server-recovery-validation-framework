# cfg.usp_RunRestoreTests

> *Validation Layer - Orchestration*

## Overview

`cfg.usp_RunRestoreTests` is the orchestration engine of the framework. It coordinates automated recovery validation tests by generating logical canary evidence, creating marked transaction boundaries, executing restore workflows, and validating the resulting database state.

This procedure is designed to validate recoverability as an operational capability rather than an assumption. It enables controlled recovery tests across one or more databases and produces auditable evidence of restore correctness.

## Responsibilities

- Select databases to be tested  
- Generate `BEFORE` / `MARK` / `AFTER` canary records  
- Create marked transaction boundaries for recovery validation  
- Produce log backups required for the restore scenario  
- Invoke `[cfg].[usp_RestorePointInTime]`  
- Invoke `[cfg].[usp_ValidatePitrCanary]`  
- Persist canary validation results into `[log].[RestoreTestRun]`  
- Provide operational visibility into recovery test execution  

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @DatabaseList | NVARCHAR(MAX) | Optional comma-separated list of databases to be tested. If omitted, the procedure may resolve candidate databases from policy or scope rules. |
| @PrimaryDir | NVARCHAR(4000) | First backup directory |
| @SecondaryDir | NVARCHAR(4000) | Secondary backup directory used when mirrored log backups are generated or consumed. |
| @UseMirror | BIT | Indicates whether mirrored backup paths should be considered when resolving backup files. |
| @DoCheckDB | BIT | Indicates whether `DBCC CHECKDB` should be executed after restore completion. |
| @ReplaceTarget | BIT | Indicates whether the target database should be replaced if it already exists. |
| @KeepTargetDb | BIT | Indicates whether the restored target database should be preserved after validation. |
| @Debug | BIT | Enables runtime trace messages and additional diagnostic visibility. |

## Execution Flow

The procedure follows a deterministic validation workflow:

1. Resolve the set of databases to be tested  
2. Generate canary evidence in the source database  
3. Create a marked transaction boundary  
4. Produce log backups that define the validation window  
5. Invoke `[cfg].[usp_RestorePointInTime]` to execute the restore  
6. Invoke `[cfg].[usp_ValidatePitrCanary]` to verify logical correctness  
7. Persist validation results into restore telemetry tables  
8. Return structured execution results for operational review  

## Example Usage

```sql
EXEC cfg.usp_RunRestoreTests
    @DatabaseList = 'AdventureWorks2022,LabCriticalDB',
    @KeepTargetDb = 1,
    @DoCheckDB = 1,
    @UseMirror = 1,
    @SecondaryDir = 'D:\SQL\Backups\SECONDARY',
    @Debug = 1;
```
## Outputs

Each execution generates outputs at three levels.

### *1. Persisted telemetry*
- **Header-level** in [log].[RestoreTestRun]
- **Step-level** in [log].[RestoreStepExecution]

These tables store execution metadata, restore telemetry, canary validation status, and step-by-step restore history.

### *2. Structured result sets*

The procedure returns structured contracts intended for operational review.

|1 - Validation | 2 - Execution  |
|---|----|
| Source and Target database names| Restore run identifiers|
| Canary identifiers| Execution summary|
| Validation flags | Restore status |
| Validation message | Validation state|
| Pass / Fail status | Final error state|

### *3. Runtime execution trace*

During execution, the procedure emits operational progress messages to the console output.

These messages provide real-time visibility into:

- the database currently being processed
- canary generation steps
- marked transaction creation
- backup generation checkpoints
- restore invocation progress
- validation completion
- error visibility during execution

This runtime trace is intended for operator observability and troubleshooting, while persisted telemetry remains the authoritative execution record.

## Related Components

- `[cfg].[usp_RestorePointInTime]` → Restore execution engine
- `[cfg].[usp_ValidatePitrCanary]` → Recovery validation engine
- `[cfg].[usp_BackupDatabase]` → Log backup generation for test boundaries
- `[dbo].[PitrCanary]` → Logical validation artifact table
- `[log].[RestoreTestRun]` → Restore execution header telemetry
- `[log].[RestoreStepExecution]` → Restore chain execution detail

## Design Notes

This procedure represents the orchestration layer of the recovery validation subsystem.

Its design combines operational automation, logical validation, and telemetry generation into a repeatable testing workflow. By coordinating restore execution with canary-based evidence, it converts recoverability testing into a measurable engineering practice.

## Source Code

[View full implementation](../../sql/cfg/usp_RunRestoreTests.sql)

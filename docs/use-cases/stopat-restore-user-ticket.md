<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="../examples/examples.md">Examples</a>
</p>

# STOPAT Restore for User Incident Ticket

## Overview

This use case documents a **point-in-time restore** scenario driven by an operational incident reported by a user.

The objective is to recover a database to a known good state prior to an unintended data modification, using the framework’s deterministic restore capabilities.

This scenario represents a common real-world recovery request, such as:

- accidental `UPDATE` without proper filtering  
- unintended `DELETE` operation  
- application logic error that modified data incorrectly  
- user-reported data inconsistency at a known time window  

---

## Business Context

A support or operations team receives a user ticket reporting that data became inconsistent after a specific action or time.

The objective is not necessarily to overwrite production immediately, but to:

- restore a copy of the database to a precise point in time  
- inspect the recovered state  
- validate that the lost or corrupted data is present in the restored copy  
- use that recovered state for analysis, comparison, or controlled remediation  

---

## Problem Statement

A user reports that data became incorrect after a specific time or action.

The system needs to answer:

- **Can the database be restored to the state it had before the incident?**
- **Is the backup chain valid for that point in time?**
- **Can the restore be executed in a controlled and auditable way?**

---

## Recovery Objective

Restore the source database to a target database using a `STOPAT` value that represents the last known good point before the incident.

### Goal

- Recover data state prior to the issue  
- Avoid affecting production directly during validation  
- Produce evidence of recoverability and execution traceability  

---

## Components Involved

This use case typically involves:

- [`[cfg].[usp_RestorePointInTime]`](../procedures/usp_RestorePointInTime.md)
- [`[cfg].[usp_GetLatestBackupFiles]`](../procedures/usp_GetLatestBackupFiles.md)
- [`[cfg].[usp_GetRestoreTestBasePath]`](../procedures/usp_GetRestoreTestBasePath.md)
- [`[log].[RestoreTestRun]`](../../sql/01_Tables/log.RestoreTestRun.md)
- [`[log].[RestoreStepExecution]`](../../sql/01_Tables/log.RestoreStepExecution.md)

---

## Execution Approach

The restore is performed into an isolated target database, using the following sequence:

1. Identify the approximate incident time from the ticket  
2. Define the last known good `STOPAT` timestamp  
3. Execute restore planning and recovery through the framework  
4. Restore into a test target database  
5. Validate the recovered state  
6. Review telemetry and restore chain evidence  

---

## Example Execution

```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_StopAt',
    @StopAt = '2026-04-06 11:59:59.000',
    @DoCheckDB = 1,
    @ReplaceTarget = 1,
    @Debug = 1;
```

## Expected Result

The procedure should:

reconstruct the correct restore chain
apply FULL / DIFF / LOG backups as needed
stop recovery at the specified STOPAT boundary
restore the target database successfully
register execution telemetry for traceability
Validation

Validation in this use case may include:

checking that expected data exists in the restored database
confirming that corrupted data introduced after the incident is absent
reviewing DBCC CHECKDB outcome if enabled
inspecting step-level restore telemetry
Evidence
Suggested evidence to include

👉 [INSERT SCREENSHOT HERE]
User ticket or incident reference (optional, anonymized)

👉 [INSERT SCREENSHOT HERE]
Execution of cfg.usp_RestorePointInTime

👉 [INSERT SCREENSHOT HERE]
Restored target database visible in SSMS

👉 [INSERT SCREENSHOT HERE]
Relevant query showing recovered data state

👉 [INSERT SCREENSHOT HERE]
log.RestoreTestRun evidence

👉 [INSERT SCREENSHOT HERE]
log.RestoreStepExecution evidence

## Telemetry Queries
```sql
SELECT TOP (10) *
FROM log.RestoreTestRun
ORDER BY StartedAt DESC;
```

```sql
SELECT TOP (50) *
FROM log.RestoreStepExecution
ORDER BY RestoreRunID DESC, StepOrder ASC;
```

## Operational Considerations
  - `STOPAT` must reflect the last known good point, not just the incident report time
  - the restore should be executed into an isolated target database first
  - production overwrite should only occur after validation
  - restore chain continuity depends on valid FULL / DIFF / LOG backup history
  - this use case is especially useful for controlled incident analysis

## Why This Use Case Matters

This scenario demonstrates that the framework is not limited to theoretical DR testing.

It can also be used as a practical operational recovery tool for real support incidents, allowing teams to respond to user-reported issues with:

  - deterministic restore execution
  - controlled validation
  - audit-ready evidence

## Summary

This use case shows how the framework supports ticket-driven operational recovery through a controlled STOPAT restore.

It proves that backup artifacts can be transformed into a precise, testable recovery outcome aligned with a real business incident.


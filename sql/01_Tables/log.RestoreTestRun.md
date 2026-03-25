# log.RestoreTestRun

## Overview
The `[log].[RestoreTestRun]` table stores the execution history of restore validation tests performed by the framework. It captures the source and target databases, restore boundary, backup files used, validation settings, execution outcome, and canary verification results.

## Purpose
This table provides the **execution log for recovery validation**, allowing the framework to:

- Record each restore test run  
- Track the backup chain used for the restore operation  
- Capture CHECKDB and execution results  
- Preserve restore errors for troubleshooting  
- Store canary-based validation evidence for point-in-time recovery tests  

It acts as the **main evidence layer for restore test execution and recoverability validation**.

## Structure

| Name | Data Type | Description |
|------|----------|-------------|
| RestoreRunID | BIGINT | Unique identifier for the restore test execution record |
| CorrelationID | UNIQUEIDENTIFIER | Identifier used to correlate this restore test with related framework operations |
| StartedAt | DATETIME2(3) | Timestamp when the restore test started |
| EndedAt | DATETIME2(3) | Timestamp when the restore test finished |
| SourceDatabase | SYSNAME | Name of the source database used for the restore test |
| TargetDatabase | SYSNAME | Name of the restored test database |
| StopAt | DATETIME2(3) | Point-in-time target used for the restore operation when applicable |
| FullBackupFile | NVARCHAR(4000) | Full path of the FULL backup file used in the restore chain |
| DiffBackupFile | NVARCHAR(4000) | Full path of the DIFFERENTIAL backup file used in the restore chain, when applicable |
| LogBackupFilesCount | INT | Number of transaction log backup files applied during the restore |
| DataFileTarget | NVARCHAR(4000) | Target path used for restored data files |
| LogFileTarget | NVARCHAR(4000) | Target path used for restored log files |
| CheckDbRequested | BIT | Indicates whether DBCC CHECKDB validation was requested after restore |
| CheckDbSucceeded | BIT | Indicates whether DBCC CHECKDB completed successfully |
| Succeeded | BIT | Indicates whether the restore test completed successfully |
| ErrorNumber | INT | SQL Server error number captured during restore failure |
| ErrorMessage | NVARCHAR(4000) | Error message captured during restore failure |
| LogsBaseDate | DATETIME2(3) | Base date used to resolve the transaction log restore chain |
| DebugEnabled | BIT | Indicates whether the restore test was executed in debug mode |
| CanaryBeforeName | NVARCHAR(128) | Name of the canary record inserted before the restore boundary |
| CanaryMarkName | NVARCHAR(128) | Name of the canary record associated with the marked transaction boundary |
| CanaryAfterName | NVARCHAR(128) | Name of the canary record inserted after the restore boundary |
| CanaryValidated | BIT | Indicates whether canary validation was performed |
| CanaryPassed | BIT | Indicates whether the canary validation passed |
| CanaryMessage | NVARCHAR(4000) | Result message produced by the canary validation logic |
| MarkLogFile | NVARCHAR(4000) | Full path of the log backup file containing the mark transaction |

## Data Example

| RestoreRunID | SourceDatabase | TargetDatabase | StopAt | LogBackupFilesCount | CheckDbSucceeded | Succeeded | CanaryPassed |
|--------------|----------------|----------------|--------|---------------------|------------------|-----------|--------------|
| 201 | LabCriticalDB | LabCriticalDB_StopAt | 2026-03-24 12:17:00.000 | 3 | 1 | 1 | NULL |
| 202 | LabCriticalDB | LabCriticalDB_BeforeMark | NULL | 2 | 1 | 1 | 1 |
| 203 | ReportingDB | ReportingDB_RestoreTest | 2026-03-24 08:45:00.000 | 1 | 0 | 0 | NULL |
| 204 | LabCriticalDB | LabCriticalDB_StopAt_Fail | 2026-03-24 14:30:00.000 | 4 | NULL | 0 | NULL |
| 205 | FinanceDB | FinanceDB_BeforeMark | NULL | 5 | 1 | 1 | 1 |
| 206 | DevSandbox | DevSandbox_RestoreTest | NULL | 0 | 1 | 1 | NULL |

> ***Note:** The canary-related columns (`CanaryBeforeName`, `CanaryMarkName`, `CanaryAfterName`, `CanaryValidated`, `CanaryPassed`, `CanaryMessage`) are populated only when the restore test is executed through the orchestrator procedure `cfg.usp_RunRestoreTests`.*

## `[log].[RestoreTestRun]`
<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

---

Stores execution telemetry for restore validation tests performed by the framework.

A Master-Detail structure where each record represents the header-level execution metadata of a restore validation run, capturing information about the restore operation, backup chain used, validation steps executed, and the final outcome of the recovery test. Detail level found in [`[log].[RestoreStepExecution]`](/sql/01_Tables/log.RestoreStepExecution.md)

### **a) Structure:**
| Column | Type | Description |
|------|------|-------------|
| RestoreRunID | bigint | Unique identifier of the restore test execution. |
| CorrelationID | uniqueidentifier | Identifier used to correlate the restore test with related framework operations. |
| StartedAt | datetime2 | Timestamp indicating when the restore test started. |
| EndedAt | datetime2 | Timestamp indicating when the restore test completed. |
| SourceDatabase | sysname | Name of the source database used to generate the restore chain. |
| TargetDatabase | sysname | Name of the temporary database created during restore validation. |
| StopAt | datetime2 | Target point-in-time used during the restore operation when STOPAT recovery is applied. |
| FullBackupFile | nvarchar | Path of the FULL backup file used as the base of the restore chain. |
| DiffBackupFile | nvarchar | Path of the DIFFERENTIAL backup file applied during restore, if applicable. |
| LogBackupFilesCount | int | Number of transaction log backup files applied during the restore sequence. |
| DataFileTarget | nvarchar | Target path where restored data files were placed during the restore operation. |
| LogFileTarget | nvarchar | Target path where restored transaction log files were placed during the restore operation. |
| CheckDbRequested | bit | Indicates whether a DBCC CHECKDB operation was requested after the restore completed. |
| CheckDbSucceeded | bit | Indicates whether the DBCC CHECKDB validation succeeded. |
| Succeeded | bit | Indicates whether the restore validation operation completed successfully. |
| ErrorNumber | int | SQL Server error number recorded if the restore operation failed. |
| ErrorMessage | nvarchar | Detailed error message captured during restore failure. |
| LogsBaseDate | datetime2 | Timestamp representing the base reference point used to generate transaction log backups for the restore test. |
| DebugEnabled | bit | Indicates whether the restore test was executed in debug mode. |
| CanaryBeforeName | nvarchar | Identifier of the BEFORE canary record inserted prior to the marked transaction boundary. |
| CanaryMarkName | nvarchar | Identifier of the MARK canary record inserted within the marked transaction boundary. |
| CanaryAfterName | nvarchar | Identifier of the AFTER canary record inserted after the marked transaction boundary. |
| CanaryValidated | bit | Indicates whether the canary validation procedure was executed. |
| CanaryPassed | bit | Indicates whether the canary validation checks passed successfully. |
| CanaryMessage | nvarchar | Validation message produced by the canary verification process. |
| MarkLogFile | nvarchar | Transaction log backup file containing the marked transaction boundary used for STOPBEFOREMARK recovery. |


### **b) Expected table content:**
| RestoreRunID | SourceDatabase | TargetDatabase | StopAt | LogBackupFilesCount | CheckDbRequested | CheckDbSucceeded | CanaryValidated | CanaryPassed | Succeeded |
|--------------|---------------|---------------|--------|--------------------|------------------|------------------|----------------|--------------|-----------|
| 101 | AdventureWorks2022 | AdventureWorks2022_RestoreTest | 2026-03-06 12:45:30 | 8 | 1 | 1 | 1 | 1 | 1 |
| 102 | AdventureWorks2022 | AdventureWorks2022_RestoreTest | 2026-03-07 09:15:10 | 6 | 1 | 1 | 1 | 1 | 1 |
| 103 | LabCriticalDB | LabCriticalDB_RestoreTest | 2026-03-09 08:00:00 | 10 | 1 | 1 | 1 | 1 | 1 |
| 104 | DemoDB | DemoDB_RestoreTest | 2026-03-09 10:30:00 | 4 | 0 | NULL | 1 | 1 | 1 |
| 105 | DemoDB | DemoDB_RestoreTest | 2026-03-09 11:10:00 | 5 | 1 | 0 | 1 | 0 | 0 |

---

<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

## `[log].[RestoreStepExecution]`
<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

---

Stores detailed execution telemetry for every step involved in a restore validation run.

While the [`[log].[RestoreTestRun]`](/sql/01_Tables/log.RestoreTestRun.md) table records the header-level metadata of the restore operation, this table captures the step-by-step execution of the restore chain.

Each record represents a single restore action applied during the recovery workflow, including FULL backups, DIFFERENTIAL backups, and TRANSACTION LOG restores.

This table provides complete traceability of the restore process, enabling administrators to inspect the exact sequence of commands / backups applied to reconstruct a database state. This table is populated by [cfg].[usp_RestorePointInTime]

### **a) Structure:**
| Column | Type | Description |
|------|------|-------------|
| RestoreStepExecutionID | bigint | Unique identifier of the restore step execution record. |
| RestoreRunID | bigint | Identifier of the restore run to which this step belongs. |
| StepOrder | int | Sequential order of the restore step within the restore chain. |
| backup_set_id | int | Identifier of the backup set retrieved from SQL Server backup metadata. |
| BackupType | varchar | Type of backup being restored (`FULL`, `DIFF`, `LOG`). |
| BackupFileName | nvarchar | Full path of the backup file used in this restore step. |
| FirstLSN | numeric | First Log Sequence Number contained in the backup. |
| LastLSN | numeric | Last Log Sequence Number contained in the backup. |
| CheckpointLSN | numeric | LSN corresponding to the checkpoint recorded during the backup. |
| DatabaseBackupLSN | numeric | Base database backup LSN associated with the backup set. |
| StartDate | datetime2 | Timestamp when the backup operation originally started. |
| FinishDate | datetime2 | Timestamp when the backup operation originally finished. |
| IsStopAtDate | bit | Indicates whether the restore step applies a STOPAT recovery point. |
| StopDate | datetime2 | Target point-in-time used for STOPAT recovery. |
| MinCommitTime | datetime2 | Minimum commit time contained in the transaction log backup. |
| MaxCommitTime | datetime2 | Maximum commit time contained in the transaction log backup. |
| IsStopAtMarker | bit | Indicates whether the restore step applies STOPBEFOREMARK recovery. |
| Marker | nvarchar | Name of the marked transaction boundary used for STOPBEFOREMARK recovery. |
| MarkLSN | numeric | LSN corresponding to the marked transaction boundary. |
| TSQL | nvarchar | T-SQL restore command executed for the step. |
| Executed | bit | Indicates whether the restore step was executed successfully. |
| ExecStartedAt | datetime2 | Timestamp when execution of the restore command started. |
| ExecEndedAt | datetime2 | Timestamp when execution of the restore command finished. |
| ExecErrorNum | int | SQL Server error number captured if execution failed. |
| ExecErrorMsg | nvarchar | Detailed error message captured during restore execution failure. |

### **b) Relevant table content:**
| StepOrder | BackupType | BackupFileName | FirstLSN | LastLSN | IsStopAtDate | StopDate | Executed |
|----------|------------|---------------|----------|---------|--------------|----------|----------|
| 1 | FULL | C:\BD\Backup\PRIMARY\AdventureWorks2022_FULL_20260309_020000.bak | 32000000011000001 | 32000000012000001 | 0 | NULL | 1 |
| 2 | DIFF | C:\BD\Backup\PRIMARY\AdventureWorks2022_DIFF_20260309_090000.bak | 32000000012000001 | 32000000014000001 | 0 | NULL | 1 |
| 3 | LOG | C:\BD\Backup\PRIMARY\AdventureWorks2022_LOG_20260309_091000.trn | 32000000014000001 | 32000000015000001 | 0 | NULL | 1 |
| 4 | LOG | C:\BD\Backup\PRIMARY\AdventureWorks2022_LOG_20260309_092000.trn | 32000000015000001 | 32000000016000001 | 0 | NULL | 1 |
| 5 | LOG | C:\BD\Backup\PRIMARY\AdventureWorks2022_LOG_20260309_093000.trn | 32000000016000001 | 32000000017000001 | 1 | 2026-03-09 09:32:15 | 1 |

---

<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

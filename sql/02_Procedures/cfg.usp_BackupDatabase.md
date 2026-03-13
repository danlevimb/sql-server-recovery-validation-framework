## `[cfg].[usp_BackupDatabase]`
<p align="center">
<a href="../README.md">Home</a> |
<a href="architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

---

Executes a controlled backup operation for a specific database, applying standardized backup policies, storage routing, and telemetry capture. Stores a record in [`[dbo].[BackupRun]`](/sql/01_Tables/dbo.BackupRun.md)

### **a) Inputs**
| Parameter | Type | Description |
|----------|------|-------------|
| @DatabaseName | sysname | Name of the database to be backed up. |
| @BackupType | varchar(10) | Type of backup operation to perform. Supported values: `FULL`, `DIFF`, `LOG`. |
| @TierID | tinyint | Logical backup tier classification used to determine backup frequency, retention policy, or SLA tier. |
| @PathType | varchar(30) | Storage path classification used to determine the destination directory where the backup will be written (e.g., PRIMARY or SECONDARY). |
| @UseMirrorToSecondary | bit | Enables backup mirroring to a secondary storage location. When enabled, backups are written simultaneously to both PRIMARY and SECONDARY storage paths. |
| @WithVerify | bit | Indicates whether a `RESTORE VERIFYONLY` operation should be executed after backup completion. This increases reliability validation but adds execution time. |
| @CopyOnly | bit | Indicates whether the backup should be executed using the `COPY_ONLY` option, preventing disruption of the differential backup chain. Typically used for ad-hoc or external backups. |
| @WithChecksum | bit | Enables page-level checksum validation during the backup operation to detect potential data corruption. |
| @WithCompression | bit | Enables backup compression to reduce storage consumption and potentially improve backup throughput. |
| @StatsPercent | tinyint | Controls the `STATS` output interval during backup execution, indicating progress percentage reported by SQL Server. |
| @CorrelationID | uniqueidentifier | Unique identifier used to correlate this backup execution with other operations in the framework, enabling cross-process telemetry and traceability. |

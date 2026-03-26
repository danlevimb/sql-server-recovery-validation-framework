# Framework Stored Procedures

<p align="center">
<a href="/README.md">Home</a> |
<a href="../sql/01_Tables.md">Tables</a> |
<a href="/docs/telemetry.md">Telemetry</a> |
<a href="/docs/restore-workflow.md">Restore Workflow</a>
</p>

---

This section contains the stored procedures that implement the core logic of the Automated Backup & Recovery Framework, grouped by functional responsibility.

## Configuration
Configuration procedures provide access to framework settings, resolve dynamic values such as paths, environment-specific parameters.

- [`[cfg].[usp_GetActiveBasePath]`](../docs/procedures/usp_GetActiveBasePath.md)
- [`[cfg].[usp_GetRestoreTestBasePath]`](../docs/procedures/usp_GetRestoreTestBasePath.md)

## Backup
Backup procedures orchestrate and execute database backup operations based on policy and tier configuration.

- [`[cfg].[usp_BackupDatabase]`](../docs/procedures/usp_BackupDatabase.md)
- [`[cfg].[usp_BackupByTierAndType]`](../docs/procedures/usp_BackupByTierAndType.md)

## Restore
Restore procedures handle restore chain construction and execution for point-in-time recovery scenarios.
- [`[cfg].[usp_GetLatestBackupFiles]`](../docs/procedures/usp_GetLatestBackupFiles.md)
- [`[cfg].[usp_RestorePointInTime]`](../docs/procedures/usp_RestorePointInTime.md)

## Validation
Validation procedures execute restore tests and verify recovery boundaries using canary-based logic.
- [`[cfg].[usp_RunRestoreTests]`](../docs/procedures/usp_RunRestoreTests.md)
- [`[cfg].[usp_ValidatePitrCanary]`](../docs/procedures/usp_ValidatePitrCanary.md)

---

<p align="center">
<a href="/README.md">Home</a> |
<a href="../sql/01_Tables.md">Tables</a> |
<a href="/docs/telemetry.md">Telemetry</a> |
<a href="/docs/restore-workflow.md">Restore Workflow</a>
</p>

# Framework Tables

<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="/docs/telemetry.md">Telemetry</a> |
<a href="/docs/restore-workflow.md">Restore Workflow</a>
</p>

---

This section contains the table-level documentation for the Automated Backup & Recovery Framework, grouped by functional area.

## Configuration
Configuration tables define the policy, tiering, and storage settings used by the framework.

- [`[cfg].[Tier]`](/sql/01_Tables/cfg.Tier.md)
- [`[cfg].[DatabasePolicy]`](/sql/01_Tables/cfg.DatabasePolicy.md)
- [`[cfg].[BackupPaths]`](/sql/01_Tables/cfg.BackupPaths.md)

## Log
Log tables store execution history, telemetry, and detailed runtime evidence for backup and restore operations.

- [`[log].[BackupRun]`](/sql/01_Tables/log.BackupRun.md)
- [`[log].[RestoreTestRun]`](/sql/01_Tables/log.RestoreTestRun.md)
- [`[log].[RestoreStepExecution]`](/sql/01_Tables/log.RestoreStepExecution.md)

## Validation
Validation tables provide functional evidence that restore boundaries behaved as expected.

- [`[dbo].[PitrCanary]`](/sql/01_Tables/dbo.PitrCanary.md)

<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="/docs/telemetry.md">Telemetry</a> |
<a href="/docs/restore-workflow.md">Restore Workflow</a>
</p>

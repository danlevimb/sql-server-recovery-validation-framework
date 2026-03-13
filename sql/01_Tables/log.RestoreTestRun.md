## `[log].[RestoreTestRun]`
<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

---
Defines the backup configuration and operational policies for each database managed by the framework.

This table acts as the policy control layer of the backup system, allowing administrators to define which databases are included in automated backup operations and which backup types should be executed for each database.

### **a) Structure:**
| Column | Type | Description |
|-------|------|-------------|
| DatabaseName | sysname | Name of the database to which the backup policy applies. |
| IsIncluded | bit | Indicates whether the database is included in automated backup operations. |
| TierID | tinyint | Backup tier classification used to determine backup frequency and retention policies. |
| BackupFull | bit | Indicates whether FULL backups are enabled for the database. |
| BackupDiff | bit | Indicates whether DIFFERENTIAL backups are enabled for the database. |
| BackupLog | bit | Indicates whether TRANSACTION LOG backups are enabled for the database. |
| OverridePrimaryPath | nvarchar | Optional custom override for the primary backup storage path. |
| OverrideSecondaryPath | nvarchar | Optional custom override for the secondary backup storage path used for mirrored backups. |
| OwnerTag | varchar | Logical ownership tag used to identify the responsible team or application owner. |
| Notes | varchar | Free-text field used to document special considerations or operational notes for the database. |
| LastRefreshedAt | datetime2 | Timestamp indicating when the policy entry was last refreshed or updated. |

### **b) Expected table content:**
| DatabaseName | IsIncluded | TierID | BackupFull | BackupDiff | BackupLog | OverridePrimaryPath | OverrideSecondaryPath | OwnerTag | Notes | LastRefreshedAt |
|--------------|------------|--------|------------|------------|-----------|---------------------|-----------------------|----------|------|----------------|
| master | 1 | 1 | 1 | 0 | 1 | NULL | NULL | System | System database backup policy | 2026-03-01 10:00:00 |
| model | 1 | 1 | 1 | 0 | 1 | NULL | NULL | System | Default template database | 2026-03-01 10:00:00 |
| msdb | 1 | 1 | 1 | 0 | 1 | NULL | NULL | System | SQL Agent and job metadata | 2026-03-01 10:00:00 |
| AdventureWorks2022 | 1 | 2 | 1 | 1 | 1 | NULL | NULL | Demo | Demo database for framework validation | 2026-03-06 12:40:00 |
| LabCriticalDB | 1 | 3 | 1 | 1 | 1 | NULL | NULL | Lab | Critical recovery validation testing database | 2026-03-09 08:00:00 |

---

<p align="center">
<a href="/README.md">Home</a> |
<a href="/docs/architecture.md">Architecture</a> |
<a href="telemetry.md">Telemetry</a> |
<a href="restore-workflow.md">Restore Workflow</a>
</p>

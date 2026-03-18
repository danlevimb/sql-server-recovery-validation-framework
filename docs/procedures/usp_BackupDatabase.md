> ***This procedure is part of the backup layer of the recovery validation framework.***
> 
# cfg.usp_BackupDatabase

## Overview

`cfg.usp_BackupDatabase` is a core component of the framework responsible for executing SQL Server backups based on a configurable and policy-driven strategy.

It supports FULL, DIFF, and LOG backups, integrating compression, checksum validation, and optional mirrored destinations while generating execution telemetry for auditing and analysis.

This procedure is designed to standardize backup operations and serve as the foundation for downstream recovery validation workflows.

## Responsibilities

- Execute FULL / DIFF / LOG backups  
- Apply compression and checksum options  
- Support PRIMARY and SECONDARY (mirrored) backup paths  
- Integrate with backup telemetry (`log.BackupRun`)  
- Enforce policy-driven backup behavior via `cfg.DatabasePolicy`  

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @DatabaseName | SYSNAME | Target database to be backed up |
| @BackupType | VARCHAR(10) | Type of backup: FULL / DIFF / LOG |
| @TierID | TINYINT | Logical backup tier for path resolution |
| @PathType | VARCHAR(30) | Backup destination type (PRIMARY / SECONDARY) |
| @UseMirrorToSecondary | BIT | Enables mirrored backup to secondary path |
| @WithVerify | BIT | Executes RESTORE VERIFYONLY after backup |
| @CopyOnly | BIT | Executes COPY_ONLY backup |
| @WithChecksum | BIT | Enables backup checksum validation |
| @WithCompression | BIT | Enables backup compression |
| @StatsPercent | TINYINT | Progress reporting interval |
| @CorrelationID | UNIQUEIDENTIFIER | Correlation ID for telemetry tracking |

## Execution Flow

The procedure follows a structured execution pattern:

1. Resolve backup configuration based on input parameters and policy  
2. Determine target paths (PRIMARY / SECONDARY)  
3. Execute BACKUP command with configured options  
4. Optionally perform backup verification  
5. Persist execution results into `log.BackupRun`  

## Example Usage

```sql
EXEC cfg.usp_BackupDatabase
    @DatabaseName = 'AdventureWorks2022',
    @BackupType = 'FULL',
    @WithCompression = 1,
    @WithChecksum = 1;

```
## Outputs

Each execution generates a telemetry record in `log.BackupRun`, capturing execution timing, backup type, storage paths, verification results, and error diagnostics.



## Related Components
- `cfg.DatabasePolicy` → Backup configuration rules 
- `log.BackupRun` → Backup execution telemetry
- `cfg.usp_BackupByTierAndType` → Batch backup orchestration

## Source Code
 [View full implementation](/sql/cfg/usp_BackupDatabase.sql)


<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

---

# cfg.usp_GetLatestBackupFiles

> *Restore Layer - Planning*

## Overview

`cfg.usp_GetLatestBackupFiles` is responsible for constructing a deterministic restore chain required to perform point-in-time recovery (PITR).

It analyzes backup metadata and identifies the correct sequence of FULL, DIFF, and LOG backups needed to restore a database to a specific point in time or transaction mark.

This procedure **does not** execute restores — it defines *what must be restored and in which order*, serving as the foundation for reliable recovery execution.

## Responsibilities

- Identify the correct FULL backup baseline  
- Select the latest applicable DIFF backup (if available)  
- Resolve the required sequence of LOG backups  
- Ensure LSN continuity across the restore chain  
- Support STOPAT and STOPBEFOREMARK recovery scenarios  
- Provide deterministic restore planning output  

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @DatabaseName | SYSNAME | Source database to evaluate backup chain from. |
| @StopAt | DATETIME2 | Target point in time for recovery. |
| @StopBeforeMark | NVARCHAR(128) | Transaction mark used for marked restore scenarios. |
| @PrimaryDir | NVARCHAR | Primary backup directory. |
| @SecondaryDir | NVARCHAR | Secondary backup directory (mirror). |
| @UseMirror | BIT | Indicates whether secondary path should be considered. |
| @Debug | BIT | Enables debug output for troubleshooting and validation. |

## Execution Flow

The procedure follows a deterministic planning process:

1. Retrieve backup history metadata (msdb and/or internal tables)  
2. Identify the most recent valid FULL backup prior to target recovery point  
3. Determine whether a DIFF backup applies  
4. Build the LOG chain based on LSN continuity
5. Validate restore sequence integrity  
6. Output ordered restore steps for execution  

## Example Usage

```sql
EXEC cfg.usp_GetLatestBackupFiles
    @DatabaseName = 'AdventureWorks2022',
    @StopAt = '2026-03-01 12:15:00',
    @PrimaryDir = 'C:\SQL\Backups\PRIMARY',
    @SecondaryDir = 'D:\SQL\Backups\SECONDARY',
    @UseMirror = 1,
    @Debug = 0;
```
## Outputs

 The procedure returns a structured dataset representing the restore chain, including:
- Backup type (FULL / DIFF / LOG)
- Backup file paths
- LSN boundaries (FirstLSN, LastLSN, CheckpointLSN)
- Backup timestamps
- Execution ordering

This output is later consumed by [`[cfg].[usp_RestorePointInTime]`](../../docs/procedures/usp_RestorePointInTime.md).

## Related Components

- [`[cfg].[usp_RestorePointInTime]`](../../docs/procedures/usp_RestorePointInTime.md) → Executes restore operations
- [`[cfg].[usp_ValidatePitrCanary]`](../../docs/procedures/usp_ValidatePitrCanary.md) → Validates restore correctness
- `[msdb].[dbo].[backupset]` → Backup metadata source
- `[msdb].[dbo].[backupmediafamily]` → Backup file resolution

## Source Code
[View full implementation](../../sql/cfg/usp_GetLatestBackupFiles.sql)

--- 

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

# cfg.usp_BackupByTierAndType

> ***Backup Layer***

## Overview

`cfg.usp_BackupByTierAndType` is responsible for executing backups across multiple databases based on tier classification and policy configuration.

Instead of executing backups individually, this procedure centralizes backup execution logic, allowing environments to scale backup strategies in a controlled and consistent manner.

It acts as a dispatcher that invokes `cfg.usp_BackupDatabase` for each eligible database.

## Responsibilities

- Select databases based on `[cfg].[DatabasePolicy]`
- Filter databases by Tier and inclusion rules
- Execute FULL / DIFF / LOG backups in batch mode
- Delegate execution to `[cfg].[usp_BackupDatabase]`
- Maintain execution correlation across all processed databases
- Enable scalable and standardized backup operations

## Parameters

| Parameter | Type | Description |
|----------|------|-------------|
| @BackupType | VARCHAR(10) | Type of backup to execute: `FULL`, `DIFF`, or `LOG`. |
| @TierID | TINYINT | Tier used to filter databases according to backup policy. |
| @PathType | VARCHAR(30) | Determines the backup destination classification (`PRIMARY` / `SECONDARY`). |
| @UseMirrorToSecondary | BIT | Indicates whether backups should also be written to the secondary path. |
| @WithVerify | BIT | Indicates whether backup verification (`RESTORE VERIFYONLY`) should be performed. |
| @WithChecksum | BIT | Enables CHECKSUM during backup execution. |
| @WithCompression | BIT | Enables backup compression. |
| @StatsPercent | TINYINT | Controls progress reporting during backup execution. |
| @CorrelationID | UNIQUEIDENTIFIER | Identifier used to correlate all backup executions within the batch. |

## Execution Flow

The procedure follows a deterministic orchestration flow:

1. Read database configuration from `[cfg].[DatabasePolicy]`
2. Filter databases by `TierID` and inclusion flags
3. Iterate through eligible databases
4. Execute `[cfg].[usp_BackupDatabase]` for each database
5. Maintain correlation across all executions using `CorrelationID`

## Example Usage

```sql
EXEC cfg.usp_BackupByTierAndType
    @BackupType = 'FULL',
    @TierID = 1,
    @PathType = 'PRIMARY',
    @WithCompression = 1,
    @WithChecksum = 1,
    @WithVerify = 0;
```
## Outputs

Each database processed generates an independent telemetry record in dbo.BackupRun, enabling full visibility into batch execution behavior, performance, and outcomes.

## Related Components

- `[cfg].[DatabasePolicy]` → Defines backup inclusion and tiering rules
- `[cfg].[usp_BackupDatabase]` → Executes individual database backups
- `[dbo].[BackupRun]` → Stores execution telemetry

## Source Code
[View full implementation](../../sql/cfg/usp_BackupByTierAndType.sql)

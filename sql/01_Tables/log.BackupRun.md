<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

# log.BackupRun

## Overview
The `[log].[BackupRun]` table stores the execution history of backup operations performed by the framework. It captures timing, backup type, storage location, execution options, output files, and final status for each run.

## Purpose
This table provides the **operational log layer** for backup execution, allowing the framework to:

- Record each backup run at the database level  
- Track backup configuration used during execution  
- Capture output files and storage behavior  
- Register validation, size, and compression results  
- Preserve error details for troubleshooting and auditability  

It acts as the **main execution log for backup activity** across the platform.

## Structure

| Name | Data Type | Description |
|------|----------|-------------|
| BackupRunID | BIGINT | Unique identifier for the backup execution record |
| StartedAt | DATETIME2(3) | Timestamp when the backup operation started |
| EndedAt | DATETIME2(3) | Timestamp when the backup operation finished |
| DatabaseName | SYSNAME | Name of the database that was backed up |
| BackupType | VARCHAR(10) | Type of backup executed (e.g., FULL, DIFF, LOG) |
| TierID | TINYINT | Tier associated with the database at execution time |
| PathType | VARCHAR(30) | Logical storage path type used for the backup |
| PrimaryFile | NVARCHAR(4000) | Full path of the primary backup file generated |
| SecondaryFile | NVARCHAR(4000) | Full path of the secondary or mirrored backup file generated |
| UsedMirror | BIT | Indicates whether a secondary backup copy was created |
| WithChecksum | BIT | Indicates whether the backup was executed with CHECKSUM |
| WithCompression | BIT | Indicates whether the backup was executed with COMPRESSION |
| IsCopyOnly | BIT | Indicates whether the backup was executed as COPY_ONLY |
| VerifyRequested | BIT | Indicates whether backup verification was requested |
| VerifySucceeded | BIT | Indicates whether the verification step completed successfully |
| BackupSizeBytes | BIGINT | Size of the backup in bytes |
| CompressedSizeBytes | BIGINT | Compressed size of the backup in bytes |
| Succeeded | BIT | Indicates whether the backup completed successfully |
| ErrorNumber | INT | SQL Server error number captured during failure |
| ErrorMessage | NVARCHAR(4000) | Error message captured during failure |
| HostName | SYSNAME | Host machine where the backup process was executed |
| InstanceName | SYSNAME | SQL Server instance name where the backup was executed |
| SqlVersion | NVARCHAR(128) | SQL Server product version at execution time |
| CorrelationID | UNIQUEIDENTIFIER | Identifier used to correlate related operations across the framework |

## Data Example

| BackupRunID | DatabaseName | BackupType | StartedAt | Succeeded | PrimaryFile | VerifySucceeded |
|-------------|--------------|------------|-----------|-----------|-------------|-----------------|
| 101 | LabCriticalDB | FULL | 2026-03-24 01:00:00.000 | 1 | C:\BD\Backup\PRIMARY\LabCriticalDB_FULL_20260324_010000.bak | 1 |
| 102 | LabCriticalDB | LOG | 2026-03-24 01:05:00.000 | 1 | C:\BD\Backup\PRIMARY\LabCriticalDB_LOG_20260324_010500.trn | NULL |
| 103 | ReportingDB | DIFF | 2026-03-24 02:00:00.000 | 0 | C:\BD\Backup\PRIMARY\ReportingDB_DIFF_20260324_020000.bak | 0 |

--- 

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

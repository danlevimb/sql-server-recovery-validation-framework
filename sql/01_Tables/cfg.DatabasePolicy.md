# cfg.DatabasePolicy

## Overview
The `[cfg].[DatabasePolicy]` table defines the backup and recovery configuration at the database level. It controls which databases are included in the framework and specifies the backup strategy and storage behavior applied to each one.

## Purpose
It acts as the **central configuration layer**, enabling scalable and flexible backup orchestration without hardcoded logic to determine:

- Which databases participate in automated processes  
- What types of backups are executed (FULL, DIFF, LOG)  
- The criticality level of each database (Tier-based strategy)  
- Optional override paths for backup storage  

It acts as the **central configuration layer**, eliminating hardcoded logic and improving scalability.

## Structure

| Name  | Data Type | Description |
|------|---------|----------|
| DatabaseName | SYSNAME | Unique name of the database to which the policy applies |
| IsIncluded | BIT | Indicates whether the database is included in automation processes |
| TierID | TINYINT | Defines the criticality tier of the database |
| BackupFull | BIT | Enables or disables FULL backups |
| BackupDiff | BIT | Enables or disables DIFFERENTIAL backups |
| BackupLog | BIT | Enables or disables TRANSACTION LOG backups |
| OverridePrimaryPath | NVARCHAR(260) | Optional custom path for primary backup storage |
| OverrideSecondaryPath | NVARCHAR(260) | Optional custom path for secondary backup storage |
| OwnerTag | VARCHAR(100) | Logical owner or responsible team for the database |
| Notes | VARCHAR(400) | Additional operational or contextual information |
| LastRefreshedAt | DATETIME2(7) | Timestamp of the last update to the policy |

## Data Example

| DatabaseName | IsIncluded | TierID | BackupFull | BackupDiff | BackupLog | 
|-------|-----|------------|------------|--------|---|
| LabCriticalDB | 1 | 1 | 1 | 1 | 1 |
| ReportingDB | 1 | 2 | 1 | 1 | 0 |
| AdventureWorks | 1 | 3 | 1 | 0 | 1 |
| DevSandbox | 0 | 3 | 1 | 1 | 0 |

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

---

# cfg.Tier

## Overview
The `[cfg].[Tier]` table defines the **service level classification** for databases within the framework. It establishes the expected recovery objectives and backup frequencies based on business criticality.

## Purpose
This table enables a **tier-based strategy** for backup and recovery by defining:

- Recovery Point Objective (RPO) and Recovery Time Objective (RTO) per tier  
- Backup execution frequency (FULL, DIFF, LOG)  
- A standardized way to classify databases by criticality  

It serves as the **foundation for aligning technical operations with business continuity requirements**.

## Structure

| Name | Data Type | Description |
|------|----------|-------------|
| TierID | TINYINT | Unique identifier of the tier |
| TierName | VARCHAR(50) | Name of the tier (e.g., Critical, High, Medium) |
| Description | VARCHAR(200) | Optional description of the tier purpose or scope |
| RPO_Minutes | INT | Maximum acceptable data loss measured in minutes |
| RTO_Minutes | INT | Maximum acceptable recovery time measured in minutes |
| Full_Freq_Minutes | INT | Frequency in minutes for FULL backups |
| Diff_Freq_Minutes | INT | Frequency in minutes for DIFFERENTIAL backups |
| Log_Freq_Minutes | INT | Frequency in minutes for TRANSACTION LOG backups (nullable for non-PITR tiers) |
| IsActive | BIT | Indicates whether the tier is active and available for use |
| CreatedAt | DATETIME2(7) | Timestamp when the tier was created |

## Data Example

| TierID | TierName | RPO_Minutes | RTO_Minutes | Full_Freq_Minutes | Diff_Freq_Minutes | Log_Freq_Minutes |
|--------|----------|-------------|-------------|--------------------|--------------------|------------------|
| 1 | Critical | 5 | 15 | 1440 | 60 | 5 |
| 2 | High | 15 | 60 | 1440 | 120 | 15 |
| 3 | Medium | 60 | 240 | 1440 | 360 | NULL |
| 4 | Low | 1440 | 720 | 10080 | 1440 | NULL |

--- 

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

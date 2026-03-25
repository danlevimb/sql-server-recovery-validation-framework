<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>


---

# dbo.PitrCanary

## Overview
The `[dbo].[PitrCanary]` table stores lightweight marker records used to validate point-in-time recovery (PITR) operations. It is created within each participating database and used during restore tests to verify data consistency across recovery boundaries.

## Purpose
This table enables **data-level validation of restore operations**, allowing the framework to:

- Insert reference records before and after recovery boundaries  
- Associate canary records with marked transactions  
- Validate whether a restore operation correctly preserves or excludes data  
- Provide deterministic evidence of successful point-in-time recovery  

It acts as the **functional validation layer**, complementing technical restore execution.

## Structure

| Name | Data Type | Description |
|------|----------|-------------|
| CanaryID | BIGINT | Unique identifier for the canary record |
| CanaryName | NVARCHAR(128) | Logical name assigned to the canary record (e.g., BEFORE, MARK, AFTER) |
| MarkName | NVARCHAR(128) | Name of the marked transaction associated with the canary, when applicable |
| CreatedAt | DATETIME2(3) | Timestamp when the canary record was created |

## Data Example

| CanaryID | CanaryName | MarkName | CreatedAt |
|----------|------------|----------|------------|
| 1 | PITR_BEFORE_20260324_121500 | NULL | 2026-03-24 12:14:50.000 |
| 2 | MARK_20260324_121500 | RT_20260324_121500 | 2026-03-24 12:15:00.000 |
| 3 | PITR_AFTER_20260324_121500 | RT_20260324_121500 | 2026-03-24 12:15:10.000 |
| 4 | PITR_BEFORE_20260325_090000 | NULL | 2026-03-25 08:59:50.000 |
| 5 | MARK_20260325_090000 | RT_20260325_090000 | 2026-03-25 09:00:00.000 |
| 6 | PITR_AFTER_20260325_090000 | RT_20260325_090000 | 2026-03-25 09:00:10.000 |

--- 

<p align="center">
<a href="/README.md">Home</a> |
<a href="../../sql/01_Tables.md">Tables</a> |
<a href="../../sql/02_Procedures.md">Procedures</a>
</p>

<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="use-cases.md">Use Cases</a>
</p>

# Recover data after accidental update (STOPAT)

---

## Overview

This use case demonstrates a **real-world incident recovery scenario** involving:

- unintended bulk data modification  
- delayed incident detection  
- imprecise user-reported timing  
- continued system activity after corruption  
- point-in-time recovery using STOPAT  
- targeted data repair in production  

### The objective is to:

- identify the last known valid state  
- restore a clean reference database  
- detect corrupted records  
- repair production data without full restore  

---

## Business context

A data inconsistency was reported in the **Order Management System**, affecting financial values in the `app.Orders` table.

The issue originated from an unintended execution of a bulk update statement without a filtering condition.

The system continued normal operation after the incident, including:

- High-frequency transactional activity (continuous DML operations).
- ON-LINE Backup Job-agents (LOGs every 15 minutes by policy)

This created a mixed dataset containing:

- corrupted historical records  
- valid new records  

---

## Incident ticket
```text 
🎫
Incident ID:     INC-2026-0413-ORDERS
Date/Hour:       13-Apr-26 12:25 p.m.  
Environment:     Production  
Service:         Order Management System  
Requested by:    Business Operations  
Severity:        High  

SUMMARY:
   Unexpected data corruption detected in order amounts affecting financial reporting.

DETAILED DESCRIPTION:
   The Business Operations team reported inconsistencies in order amounts within the production system. 

   Several records in the `app.Orders` table show incorrect values, impacting downstream processes and reporting accuracy. The incident is estimated to have occurred around 11:00 AM.

SUSPECTED ROOT CAUSE:
   An unintended execution of a bulk update statement:
   sql UPDATE app.Orders SET Amount = 0;

### Detection time

The user reported:

> “The incident is estimated to have occurred around 11:00 AM.”

⚠️ This time is a nearby starting point.

### Impact
- Financial data inconsistency
- Reporting inaccuracies
- Potential downstream system impact

REQUESTED ACTIONS:
	1 - Identify last valid data state  
	2 - Restore database to pre-incident point  
	3 - Identify affected records  
	4 - Perform controlled repair in production  
	5 - Validate data consistency  
```

### Problem statement

The exact time of the incident is unknown.

The system must determine:
- when the data transitioned from valid to corrupted
- how to identify the correct recovery point
- how to restore without affecting valid post-incident data
- how to repair production safely

### Recovery strategy

A forensic, evidence-driven approach is used:

1 - Define initial incident window (10:00 am - 12:00 pm)  
2 - Perform exploratory restores  
3 - Identify GOOD vs BAD states  
4 - Narrow the time boundary  
5 - Determine optimal STOPAT  
6 - Restore clean reference database  
7 - Compare datasets  
8 - Repair affected records  
9 - Validate final state  

### Why Full-Restore was not used?

A full database restore was not considered appropriate due to:

- Presence of valid post-incident transactions
- Continuous system operation after the corruption event
- Risk of losing legitimate new data

Instead, a targeted recovery and repair approach was used to preserve valid data while correcting only the affected records.

### Validation of dataset values

Through query showing corrupted values (Amount = 0)

```sql
SELECT TOP (50) *
FROM app.Orders
ORDER BY OrderCreatedAt DESC;
```

### STOPAT - Selection methodology

The user-reported time (11:00 am) was used only as an initial reference point to define the investigation window. (10:00 am - 12:00 pm)

The actual STOPAT value will be determined through an iterative process based on data validation, not user input, by doing:

   1 - exploratory restores
   2 - GOOD vs BAD validation  
   3 - iterative narrowing (binary search approach)  

### Data State Model

After the incident, the dataset was divided into two logical states:

- Historical records → corrupted (Amount = 0)
- New records → valid (post-incident inserts)

This dual-state condition required selective repair instead of full rollback.

### Exploratory Restore Process

The recovering script used is:

```sql
DECLARE @return_value int,
		@RunID bigint;

EXEC	@return_value = [cfg].[usp_RestorePointInTime]
		@SourceDB = LabcriticalDB, 
		@TargetDB = LabCriticalDb_StopAt_T1,
		@StopAtDate =N'2026-04-13 10:25:10.750',
		@StopBeforeMark = NULL,
		@DoCheckDB = 1,
		@ReplaceTarget = 1,
		@Debug = 1,
		@RunId = @RunId OUTPUT

SELECT @RunID as N'@RunID'

SELECT 'Return Value' = @return_value
GO
```

We close the gap by testing the state GOOD vs BAD. If the result is good, we move forward in time, if result is bad, we move past in time. Always shorting the gap by the half of time. The results for this exercise are as follow:

| Sequence | StopAt | Result |
|----------|--------|--------|
|1|	10:00:00.000	|[GOOD](images/ERP_10_00.JPG)|
|2|	12:00:00.000	|[BAD](images/ERP_12_00.JPG)| 
|3|   11:00:00.000   |[BAD](images/ERP_11_00.JPG)| 
|4|	10:30:00.000	|[BAD](images/ERP_10_30.JPG)|
|5|	10:15:00.000	|[GOOD](images/ERP_10_15.JPG)|
|6|	10:20:00.000	|[GOOD](images/ERP_10_20.JPG)| 
|7|	10:25:00.000	|[GOOD](images/ERP_10_25.JPG)|
|8|	10:27:00.000	|[BAD](images/ERP_10_27.JPG)|
|9|	10:26:00.000	|[BAD](images/ERP_10_26.JPG)|
|10|	10:25:30.000	|[BAD](images/ERP_10_25_30.JPG)|
|11|	10:25:15.000	|[BAD](images/ERP_10_25_15.JPG)|
|12|	10:25:07.000	|[GOOD](images/ERP_10_25_07.JPG)|
|13|	10:25:10.000	|[GOOD](images/ERP_10_25_10.JPG)|
|14|	10:25:12.000	|[BAD](images/ERP_10_25_12.JPG)|
|15|	10:25:11.000	|[BAD](images/ERP_10_25_11.JPG)|
|16|	10:25:10.500	|[GOOD](images/ERP_10_25_10_500.JPG)|
|17|	10:25:10.750	|[BAD](images/ERP_10_25_10_750.JPG)|

### What happened?
```text
TIME  ─────────────────────────────────────────▶

GOOD STATE            INCIDENT               BAD STATE
   │                      │                      │
   │                      ▼                      │
   │             [UPDATE WITHOUT WHERE]          │
   │                                             │
   ▼                                             ▼

10:25:10.500        ← STOPAT SELECTED        10:25:10.750

       ▲
       │
       └── Last Known Valid State (Chosen for Recovery)
```
       
### Final STOPAT
`2026-04-13 10:25:10.500`

This represents the most accurate good last known valid state before corruption for `app.Orders`. Remember this is a mid-high transactional table.

### Data comparison (Production vs Restored)
```sql
SELECT 
    p.OrderID,
    p.Amount AS ProductionAmount,
    r.Amount AS RestoredAmount
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt_T1.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);
```
<p align="center">
  <img src="images/Affected_Record_Comparison.JPG" width="900">
</p>

### Backup Before Repair
```sql
EXEC cfg.usp_BackupDatabase
    @DatabaseName = 'LabCriticalDB',
    @BackupType = 'LOG',
    @WithCompression = 1,
    @WithChecksum = 1;
```

<p align="center">
  <img src="images/Backup_Execution_Evidence.JPG" width="900">
</p>

### Data repair (Production)
```sql
BEGIN TRAN;

UPDATE p
SET p.Amount = r.Amount
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt_T1.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);

SELECT @@ROWCOUNT AS RowsFixed;

COMMIT;
```

<p align="center">
  <img src="images/Rows_Affected_During_Repair.JPG" width="900">
</p>

### Final validation
```sql
SELECT COUNT(*) AS RemainingDifferences
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt_T1.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);
```

<p align="center">
  <img src="images/Final_Validation.JPG" width="900">
</p>

### Key insights
 
 - User-reported time is unreliable
 - Log backups capture events independently of perception
 - Data corruption may coexist with valid data
 - STOPAT must be determined through evidence
 - Repair should be targeted, not destructive

### Summary

This use case demonstrates a complete incident recovery workflow:

- forensic analysis
- point-in-time recovery
- data validation
- targeted repair

It proves that backup systems must be complemented with deterministic recovery validation and repair strategies.

### Final Outcome

   ✔ Incident successfully analyzed  
   ✔ STOPAT precisely identified  
   ✔ Data restored correctly  
   ✔ Production repaired safely  
   ✔ Data integrity fully restored  

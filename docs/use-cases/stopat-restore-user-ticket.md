<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="../examples/examples.md">Examples</a>
</p>

# STOPAT Restore & Targeted Data Repair for User Incident

---

## Overview

This use case demonstrates a **real-world incident recovery scenario** involving:

- unintended bulk data modification  
- delayed incident detection  
- imprecise user-reported timing  
- continued system activity after corruption  
- point-in-time recovery using STOPAT  
- targeted data repair in production  

The objective is to:

- identify the last known valid state  
- restore a clean reference database  
- detect corrupted records  
- repair production data without full restore  

---

## Business Context

A data inconsistency was reported in the **Order Management System**, affecting financial values in the `app.Orders` table.

The issue originated from an unintended execution of a bulk update statement without a filtering condition.

The system continued normal operation after the incident, including:

- DMLs ocurring in high-rate transaction table.
- ON-LINE Backup Job-agents (LOGs every 15 minutes by policy)

This created a mixed dataset containing:

- corrupted historical records  
- valid new records  

---

## Incident Ticket

### 🎫 Incident ID: INC-2026-0413-ORDERS

**Date/Hour:** 13-Abr-26 12:25 p.m.  
**Environment:** Production  
**Service:** Order Management System  
**Reported by:** Business Operations  
**Severity:** High  

---

### Summary

Unexpected data corruption detected in order amounts affecting financial reporting.

---

### Detailed Description

The Business Operations team reported inconsistencies in order amounts within the production system.

Several records in the `app.Orders` table show incorrect values, impacting downstream processes and reporting accuracy.

---

### Suspected Root Cause

An unintended execution of a bulk update statement:

```sql
UPDATE app.Orders
SET Amount = 0;
```

### Detection Time

The issue was detected approximately 30–40 minutes after the incident occurred.

The user reported:

> “The issue may have happened around 11:00 AM.”

⚠️ This time is approximate and not reliable for recovery.

### Impact
- Financial data inconsistency
- Reporting inaccuracies
- Potential downstream system impact

### Requested Actions
   
1 - Identify last valid data state  
2 - Restore database to pre-incident point  
3 - Identify affected records  
4 - Perform controlled repair in production  
5 - Validate data consistency  

### Problem Statement

The exact time of the incident is unknown.

The system must determine:
- when the data transitioned from valid to corrupted
- how to identify the correct recovery point
- how to restore without affecting valid post-incident data
- how to repair production safely

### Recovery Strategy

A forensic, evidence-driven approach is used:
1 Define initial incident window  
2 Perform exploratory restores  
3 Identify GOOD vs BAD states  
4 Narrow the time boundary  
5 Determine optimal STOPAT  
6 Restore clean reference database  
7 Compare datasets  
8 Repair affected records  
9 Validate final state  

### Validation of dataset values

Through query showing corrupted values (Amount = 0)

```sql
SELECT TOP (50) *
FROM app.Orders
ORDER BY OrderCreatedAt DESC;
```
What we see:

- corrupted historical records
- valid new inserts
- OLD DATA → Amount = 0 ❌  
- NEW DATA → Amount correct ✅

### STOPAT Selection Methodology

We have an aproximate hour of incident (~11:00 am), we use that hour as a mid time real incident happened, so we determine STOPAT by doing

1 exploratory restores.
2 GOOD vs BAD validation
3 iterative narrowing (binary search approach)

### Exploratory Restore Process

The recovering process we use is:

```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_StopAt_T1',
    @StopAt = '2026-04-13 11:00:00.000',
    @DoCheckDB = 1,
    @ReplaceTarget = 1;
```

We close the gap by testing the state GOOD vs BAD. If the result is good, we move forward in time, if result is bad, we move past in time. Always shorting the gap by the half of time. The results for this exercise are as follow:

| Sequence | StopAt | Result |
|-------|-------|--------|
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
|17|	10:25:10.250	|[GOOD](images/ERP_10_25_10_250.JPG)|

### Final STOPAT
`2026-04-13 10:25:10.250`

This represents the most accurate good last known valid state before corruption for `app.Orders` if this is a mid-high transactional table

### Data Comparison (Production vs Restored)
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

Affected records comparison

Backup Before Repair
```sql
EXEC cfg.usp_BackupDatabase
    @DatabaseName = 'LabCriticalDB',
    @BackupType = 'LOG',
    @WithCompression = 1,
    @WithChecksum = 1;
```

📸 [INSERT SCREENSHOT]
Backup execution evidence

### Data Repair (Production)
```sql
BEGIN TRAN;

UPDATE p
SET p.Amount = r.Amount
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);

SELECT @@ROWCOUNT AS RowsFixed;

COMMIT;
```

📸 [INSERT SCREENSHOT]
Rows affected during repair

### Final Validation
```sql
SELECT COUNT(*) AS RemainingDifferences
FROM LabCriticalDB.app.Orders p
JOIN LabCriticalDB_StopAt.app.Orders r
    ON p.OrderID = r.OrderID
WHERE ISNULL(p.Amount,0) <> ISNULL(r.Amount,0);
```

📸 [INSERT SCREENSHOT]
Expected result = 0

### Key Insights
    - User-reported time is unreliable
    - Log backups capture events independently of perception
    - Data corruption may coexist with valid data
    - STOPAT must be determined through evidence
    - Repair should be targeted, not destructive

### Summary

This use case demonstrates a complete incident recovery workflow:

forensic analysis
point-in-time recovery
data validation
targeted repair

It proves that backup systems must be complemented with deterministic recovery validation and repair strategies.

Final Outcome

   ✔ Incident successfully analyzed  
   ✔ STOPAT precisely identified  
   ✔ Data restored correctly  
   ✔ Production repaired safely  
   ✔ Data integrity fully restored  

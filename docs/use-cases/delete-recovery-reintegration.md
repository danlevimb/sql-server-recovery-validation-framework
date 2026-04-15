<p align="center">
<a href="../../README.md">Home</a> |
<a href="../architecture.md">Architecture</a> |
<a href="../examples/examples.md">Examples</a>
</p>

# Accidental DELETE Recovery & Selective Data Reintegration

---

## Overview

This use case demonstrates a **non-destructive data recovery strategy** for handling accidental data deletion in a production environment.

Instead of performing a full database restore, this approach:

- restores a reference database to a pre-incident state  
- identifies missing records  
- reinserts only the deleted data  
- preserves valid post-incident transactions  

---

## Business Context

The Operations team executed a maintenance operation on a high-transaction table (`app.Orders`).

Due to an incorrect filtering condition, a DELETE statement removed valid historical data.

The system continued operating normally, generating new records after the incident.

---

## Incident Ticket

```text
🎫
Incident ID:   INC-2026-0416-DATA-LOSS
Date/Hour:     16-Apr-26 11:45 am
Environment:   Production  
Service:       Order Management System  
Requested by:  Operations Team  
Severity:      High  

SUMMARY:
  Accidental deletion of historical order records.

DETAILED DESCRIPTION:
  A DELETE statement was executed with an incorrect filtering condition, removing valid data from the Orders table.

  The issue was detected approximately 30 minutes after execution.

IMPACT:
  - Loss of historical data  
  - Incomplete datasets  
  - Reporting inconsistencies  

REQUESTED ACTION:
  - Recover missing records  
  - Preserve valid new data  
  - Restore dataset integrity  
```

### Problem Statement

The system must:

- recover deleted records
- avoid restoring the entire database
- preserve valid new inserts
- ensure data integrity

### Recovery Strategy

This approach uses:

`STOPAT + selective reintegration`

### Timeline Visualization
```text 
TIME ─────────────────────────────────────────▶

VALID DATA ───▶ DELETE ───▶ DATA LOSS ───▶ NEW INSERTS

                    ▲
                    │
                  STOPAT
```
### Incident Simulation

📸 [INSERT SCREENSHOT]

```sql
DELETE FROM app.Orders
WHERE OrderCreatedAt < '2026-04-01';
Evidence — Data Loss
```

📸 [INSERT SCREENSHOT]

```sql
SELECT COUNT(*) FROM app.Orders;
```
### Restore Reference Database

```sql
EXEC cfg.usp_RestorePointInTime
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_RestoreRef',
    @StopAt = '2026-04-16 11:15:00',
    @ReplaceTarget = 1;
```

📸 [INSERT SCREENSHOT]

### Identify Missing Records
```sql
SELECT r.*
FROM LabCriticalDB_RestoreRef.app.Orders r
LEFT JOIN LabCriticalDB.app.Orders p
    ON p.OrderID = r.OrderID
WHERE p.OrderID IS NULL;
```

📸 [INSERT SCREENSHOT]

### Pre-Repair Safety Backup
```sql
EXEC cfg.usp_BackupDatabase
    @DatabaseName = 'LabCriticalDB',
    @BackupType = 'LOG',
    @WithCompression = 1,
    @WithChecksum = 1;
```

📸 [INSERT SCREENSHOT]

Controlled Reintegration

⚠️ This operation must:

- preserve identity values
- prevent concurrent inserts
- ensure data consistency
  
```sql
BEGIN TRAN;

-- Lock table to prevent concurrent inserts
SELECT 1 FROM app.Orders WITH (TABLOCKX);

SET IDENTITY_INSERT app.Orders ON;

INSERT INTO app.Orders (OrderID, CustomerName, Amount, OrderCreatedAt)
SELECT r.OrderID, r.CustomerName, r.Amount, r.OrderCreatedAt
FROM LabCriticalDB_RestoreRef.app.Orders r
LEFT JOIN app.Orders p
    ON p.OrderID = r.OrderID
WHERE p.OrderID IS NULL;

SET IDENTITY_INSERT app.Orders OFF;

SELECT @@ROWCOUNT AS RowsRecovered;

COMMIT;
```

📸 [INSERT SCREENSHOT]

### Final Validation
```sql
SELECT COUNT(*) AS MissingRecords
FROM LabCriticalDB_RestoreRef.app.Orders r
LEFT JOIN app.Orders p
    ON p.OrderID = r.OrderID
WHERE p.OrderID IS NULL;
```

📸 [INSERT SCREENSHOT]

### Why Full Restore Was Not Used

A full restore was not appropriate because:

- new valid records were created after the deletion
- restoring the entire database would cause data loss
- the objective was targeted recovery

### Key Insights
- Not all incidents require full restore
- Selective recovery minimizes risk
- Identity handling is critical in reintegration
- Table locking ensures consistency during repair

### Summary

This use case demonstrates:

- selective data recovery
- non-destructive repair
- preservation of live system activity

### Final Outcome

✔ Missing records recovered
✔ New data preserved
✔ No full restore required
✔ Data integrity restored

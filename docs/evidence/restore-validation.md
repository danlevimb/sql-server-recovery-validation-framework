<p align="center">
<a href="../../README.md">Home</a> |
<a href="../examples/examples.md">Examples</a>
</p>

# Restore Validation Evidence

This section demonstrates the framework’s ability to perform **deterministic recovery validation** using controlled restore scenarios and data-level verification.

The objective is to prove that:

- Backup chains are valid and usable  
- Restore operations reach the intended recovery boundary  
- Data state matches expected conditions after recovery  
- Recovery is not assumed, but **verified with evidence**  

---

# Scenario

## Validation Strategy

The framework uses a **canary-based validation model**:

- Insert a record BEFORE the recovery boundary  
- Insert a MARK (transaction marker)  
- Insert a record AFTER the boundary  

Then:

- Restore the database **before the mark**  
- Validate that:
  - BEFORE exists ✅  
  - MARK does not exist ❌  
  - AFTER does not exist ❌  

---

# Step 1 — Execute Restore Validation

Run the orchestration procedure:

```sql
EXEC cfg.usp_RunRestoreTests
    @SourceDatabase = 'LabCriticalDB',
    @Debug = 1;
```

Expected Behavior

The procedure:
- Inserts canary records
- Creates a marked transaction
- Generates a LOG backup capturing the mark
- Executes restore using STOPBEFOREMARK
- Validates restored data
  
🔍 Evidence: Execution Output

👉 [INSERT SCREENSHOT HERE]
SSMS output showing execution steps and debug messages

# Step 2 — Canary Generation

The framework creates controlled markers in the source database.

🔍 Evidence: Source Data
```sql
SELECT *
FROM dbo.PitrCanary
ORDER BY CreatedAt DESC;
```

👉 [INSERT SCREENSHOT HERE]

### Expected Pattern

- `PITR_BEFORE_<token>`
- `MARK_<token>`
- `PITR_AFTER_<token>`

### Interpretation

This confirms that:
- The recovery boundary is clearly defined
- The test scenario is deterministic
- The restore validation has a measurable reference

# Step 3 — Restore Execution

The framework executes a restore using:
- FULL backup
- (Optional) DIFF
- LOG backups
- `STOPBEFOREMARK`

🔍 Evidence: Restore Target Database

👉 [INSERT SCREENSHOT HERE]
Database restored (e.g. LabCriticalDB_RestoreTest)

🔍 Evidence: Restore Commands (Optional)

👉 [INSERT SCREENSHOT HERE]
Debug output showing RESTORE statements

# Step 4 — Data-Level Validation

Validate the restored database:

```sql
SELECT *
FROM LabCriticalDB_RestoreTest.dbo.PitrCanary
ORDER BY CreatedAt DESC;
```

🔍 Evidence: Restored Data

👉 [INSERT SCREENSHOT HERE]

Expected Result
|Canary Type | Expected Presence |
|------------|-------------------|
|BEFORE	|✅ Exists|
|MARK	|❌ Does not exist|
|AFTER	|❌ Does not exist|

Interpretation

This confirms that:

The restore stopped at the correct boundary
No data beyond the mark was applied
The recovery point is precise and deterministic
Step 5 — Telemetry Verification

Review restore execution records:

SELECT *
FROM log.RestoreTestRun
ORDER BY StartedAt DESC;
SELECT *
FROM log.RestoreStepExecution
ORDER BY RestoreRunID, StepOrder;
🔍 Evidence: Restore Telemetry

👉 [INSERT SCREENSHOT HERE]

Interpretation

Key observations:

Restore chain is fully recorded
Each step contains LSN and timing data
Errors (if any) are captured
Canary validation results are stored
Step 6 — Canary Validation Result

If using integrated validation:

SELECT
    CanaryBeforeName,
    CanaryMarkName,
    CanaryAfterName,
    CanaryPassed,
    CanaryMessage
FROM log.RestoreTestRun
ORDER BY StartedAt DESC;
🔍 Evidence: Validation Outcome

👉 [INSERT SCREENSHOT HERE]

Expected Result
CanaryPassed = 1
Message indicates successful validation
Step 7 — Manual Validation (Optional)

Run validation independently:

EXEC cfg.usp_ValidatePitrCanary
    @SourceDatabase = 'LabCriticalDB',
    @TargetDatabase = 'LabCriticalDB_RestoreTest',
    @MarkName = 'RT_<token>';
🔍 Evidence: Manual Validation

👉 [INSERT SCREENSHOT HERE]

Key Observations
Restore chains are correctly constructed and executed
Recovery boundaries are precisely respected
Data-level validation confirms correctness
Canary model provides deterministic verification
Telemetry captures full execution trace
Conclusion

This execution demonstrates that the framework:

Does not assume recoverability — it proves it
Validates both technical and functional correctness
Provides measurable, repeatable recovery validation
Ensures that backup strategies are not only implemented, but continuously verified

The result is a system where recovery capability is not theoretical, but tested, validated, and evidenced.

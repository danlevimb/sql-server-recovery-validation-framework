USE [DBAFramework];
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [cfg].[usp_RunScheduledBackups]
    @UseMirrorToSecondary   BIT = 1,
    @WithVerify             BIT = 0,
    @DryRun                 BIT = 0,
    @Debug                  BIT = 0
AS
/*==============================================================================
  Procedure : cfg.usp_RunScheduledBackups
  Project   : Automated Backup & Recovery Framework
  Author    : Dan Levi Menchaca Bedolla
  Role      : SQL Server DBA / Data Infrastructure & Reliability Engineering
  Created   : 2026
  Component : Backup Scheduling Engine

  Purpose   :
      Evaluates backup frequency dynamically based on metadata-driven policies
      and executes the required backup type per database.

      This procedure acts as a scheduling/orchestration engine that:
      - Reads cfg.Tier and cfg.DatabasePolicy
      - Determines the last successful FULL / DIFF / LOG backup per database
      - Evaluates whether each database is due for backup
      - Selects a single backup type per cycle using precedence:
            FULL > DIFF > LOG
      - Executes cfg.usp_BackupDatabase only for databases that are due
      - Avoids overlapping scheduler runs with sp_getapplock
      - Skips databases that already have a backup in progress

  Notes     :
      - Intended to be executed by a single SQL Server Agent Job on a frequent
        schedule (e.g. every 5 minutes).
      - cfg.usp_BackupByTierAndType remains available for explicit/manual batch
        executions by Tier + BackupType.
==============================================================================*/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    -------------------------------------------------------------------------
    -- DEBUG INPUTS
    -------------------------------------------------------------------------
    --DECLARE
    --    @UseMirrorToSecondary BIT = 1,
    --    @WithVerify           BIT = 0,
    --    @DryRun               BIT = 1,
    --    @Debug                BIT = 1;

    DECLARE
        @Now            DATETIME2(7) = SYSDATETIME(),
        @db             SYSNAME,
        @TierID         TINYINT,
        @BackupType     VARCHAR(10),
        @CorrelationID  UNIQUEIDENTIFIER = NEWID(),
        @AppLockResult  INT;

    BEGIN TRY
        ---------------------------------------------------------------------
        -- 0) PREVENT OVERLAPPING SCHEDULER RUNS
        ---------------------------------------------------------------------
        EXEC @AppLockResult = sys.sp_getapplock
            @Resource = 'cfg.usp_RunScheduledBackups',
            @LockMode = 'Exclusive',
            @LockOwner = 'Session',
            @LockTimeout = 0;

        IF @AppLockResult < 0
            BEGIN
                RAISERROR('Another execution of [cfg].[usp_RunScheduledBackups] is already running.', 10, 1);
                RETURN;
            END;
        ---------------------------------------------------------------------
        -- TEMP OBJECTS
        ---------------------------------------------------------------------
        IF OBJECT_ID('tempdb..#Universe') IS NOT NULL DROP TABLE #Universe;
        IF OBJECT_ID('tempdb..#LastRuns') IS NOT NULL DROP TABLE #LastRuns;
        IF OBJECT_ID('tempdb..#RunningBackup') IS NOT NULL DROP TABLE #RunningBackup;
        IF OBJECT_ID('tempdb..#Decision') IS NOT NULL DROP TABLE #Decision;
        IF OBJECT_ID('tempdb..#Execution') IS NOT NULL DROP TABLE #Execution;
        ---------------------------------------------------------------------
        -- 1) ELIGIBLE DATABASE UNIVERSE
        ---------------------------------------------------------------------
        SELECT
            p.DatabaseName, p.TierID, t.TierName, t.RPO_Minutes, t.RTO_Minutes,
            t.Full_Freq_Minutes, t.Diff_Freq_Minutes, t.Log_Freq_Minutes, p.BackupFull, p.BackupDiff,
            p.BackupLog, p.OverridePrimaryPath, p.OverrideSecondaryPath, d.recovery_model_desc, d.state_desc
        INTO #Universe
        FROM cfg.DatabasePolicy p
        INNER JOIN cfg.Tier t ON t.TierID = p.TierID
        INNER JOIN sys.databases d ON d.name = p.DatabaseName
        WHERE p.IsIncluded = 1
          AND t.IsActive = 1
          AND d.state_desc = 'ONLINE'
          AND p.DatabaseName <> 'tempdb';

        IF @Debug = 1 SELECT 'Eligible database universe', * FROM #Universe ORDER BY RPO_Minutes, TierID, DatabaseName;            
        ---------------------------------------------------------------------
        -- 2) LAST SUCCESSFUL BACKUPS BY DATABASE
        ---------------------------------------------------------------------
        ;WITH LastSuccessful AS (
            SELECT br.DatabaseName, br.BackupType, MAX(br.EndedAt) AS LastSucceededAt
            FROM log.BackupRun br
            WHERE br.Succeeded = 1
              AND br.EndedAt IS NOT NULL
              AND br.BackupType IN ('FULL','DIFF','LOG')
            GROUP BY
                br.DatabaseName,
                br.BackupType)
        SELECT
            u.DatabaseName,
            MAX(CASE WHEN ls.BackupType = 'FULL' THEN ls.LastSucceededAt END) AS LastFullAt,
            MAX(CASE WHEN ls.BackupType = 'DIFF' THEN ls.LastSucceededAt END) AS LastDiffAt,
            MAX(CASE WHEN ls.BackupType = 'LOG'  THEN ls.LastSucceededAt END) AS LastLogAt
        INTO #LastRuns
        FROM #Universe u
        LEFT JOIN LastSuccessful ls ON ls.DatabaseName = u.DatabaseName
        GROUP BY u.DatabaseName;

        IF @Debug = 1 SELECT 'Last successful backups', * FROM #LastRuns ORDER BY DatabaseName;
        ---------------------------------------------------------------------
        -- 3) DATABASES WITH BACKUPS CURRENTLY IN PROGRESS
        ---------------------------------------------------------------------
        SELECT DISTINCT
            br.DatabaseName
        INTO #RunningBackup
        FROM log.BackupRun br
        WHERE br.EndedAt IS NULL
          AND br.StartedAt >= DATEADD(HOUR, -2, @Now);

        IF @Debug = 1 SELECT 'Databases with backup in progress', * FROM #RunningBackup ORDER BY DatabaseName;
        ---------------------------------------------------------------------
        -- 4) DECISION MATRIX
        --    RULES:
        --      - FULL > DIFF > LOG
        --      - DIFF requires previous FULL
        --      - LOG requires previous FULL and FULL/BULK_LOGGED
        --      - If backup is already running for DB, skip
        ---------------------------------------------------------------------
        SELECT u.DatabaseName, u.TierID, u.TierName, u.RPO_Minutes, u.RTO_Minutes,
            u.Full_Freq_Minutes, u.Diff_Freq_Minutes, u.Log_Freq_Minutes, u.BackupFull, u.BackupDiff,
            u.BackupLog, u.recovery_model_desc, l.LastFullAt, l.LastDiffAt, l.LastLogAt,
            HasRunningBackup = CASE WHEN rb.DatabaseName IS NOT NULL THEN 1 ELSE 0 END,
            LastDiffEffectiveAt =
                CASE
                    WHEN l.LastFullAt IS NULL AND l.LastDiffAt IS NULL THEN NULL
                    WHEN l.LastDiffAt IS NULL THEN l.LastFullAt
                    WHEN l.LastFullAt IS NULL THEN l.LastDiffAt
                    WHEN l.LastFullAt > l.LastDiffAt THEN l.LastFullAt
                    ELSE l.LastDiffAt
                END,
            FullDue =
                CASE
                    WHEN rb.DatabaseName IS NOT NULL THEN 0
                    WHEN u.BackupFull = 1 AND (l.LastFullAt IS NULL OR DATEDIFF(MINUTE, l.LastFullAt, @Now) >= u.Full_Freq_Minutes) THEN 1 ELSE 0
                END,

            DiffDue =
                CASE
                    WHEN rb.DatabaseName IS NOT NULL THEN 0
                    WHEN u.BackupDiff = 1
                     AND u.Diff_Freq_Minutes IS NOT NULL
                     AND l.LastFullAt IS NOT NULL
                     AND DATEDIFF
                        (
                            MINUTE,
                            CASE
                                WHEN l.LastDiffAt IS NULL THEN l.LastFullAt
                                WHEN l.LastFullAt > l.LastDiffAt THEN l.LastFullAt
                                ELSE l.LastDiffAt
                            END,
                            @Now
                        ) >= u.Diff_Freq_Minutes
                    THEN 1 ELSE 0
                END,

            LogDue =
                CASE
                    WHEN rb.DatabaseName IS NOT NULL THEN 0
                    WHEN u.BackupLog = 1
                     AND u.Log_Freq_Minutes IS NOT NULL
                     AND l.LastFullAt IS NOT NULL
                     AND u.recovery_model_desc IN ('FULL','BULK_LOGGED')
                     AND (l.LastLogAt IS NULL OR DATEDIFF(MINUTE, l.LastLogAt, @Now) >= u.Log_Freq_Minutes)
                    THEN 1 ELSE 0
                END,

            SelectedBackupType =
                CASE
                    WHEN rb.DatabaseName IS NOT NULL
                        THEN NULL

                    WHEN u.BackupFull = 1
                     AND (l.LastFullAt IS NULL OR DATEDIFF(MINUTE, l.LastFullAt, @Now) >= u.Full_Freq_Minutes)
                        THEN 'FULL'

                    WHEN u.BackupDiff = 1
                     AND u.Diff_Freq_Minutes IS NOT NULL
                     AND l.LastFullAt IS NOT NULL
                     AND NOT (u.BackupFull = 1 AND (l.LastFullAt IS NULL OR DATEDIFF(MINUTE, l.LastFullAt, @Now) >= u.Full_Freq_Minutes))
                     AND DATEDIFF
                        (
                            MINUTE,
                            CASE
                                WHEN l.LastDiffAt IS NULL THEN l.LastFullAt
                                WHEN l.LastFullAt > l.LastDiffAt THEN l.LastFullAt
                                ELSE l.LastDiffAt
                            END,
                            @Now
                        ) >= u.Diff_Freq_Minutes
                        THEN 'DIFF'

                    WHEN u.BackupLog = 1
                     AND u.Log_Freq_Minutes IS NOT NULL
                     AND l.LastFullAt IS NOT NULL
                     AND u.recovery_model_desc IN ('FULL','BULK_LOGGED')
                     AND NOT (
                            u.BackupFull = 1
                            AND (
                                    l.LastFullAt IS NULL
                                    OR DATEDIFF(MINUTE, l.LastFullAt, @Now) >= u.Full_Freq_Minutes
                                )
                         )
                     AND NOT (
                            u.BackupDiff = 1
                            AND u.Diff_Freq_Minutes IS NOT NULL
                            AND l.LastFullAt IS NOT NULL
                            AND DATEDIFF
                                (
                                    MINUTE,
                                    CASE
                                        WHEN l.LastDiffAt IS NULL THEN l.LastFullAt
                                        WHEN l.LastFullAt > l.LastDiffAt THEN l.LastFullAt
                                        ELSE l.LastDiffAt
                                    END,
                                    @Now
                                ) >= u.Diff_Freq_Minutes
                         )
                     AND (
                            l.LastLogAt IS NULL
                            OR DATEDIFF(MINUTE, l.LastLogAt, @Now) >= u.Log_Freq_Minutes
                         )
                        THEN 'LOG'

                    ELSE NULL
                END,

            DecisionReason =
                CASE
                    WHEN rb.DatabaseName IS NOT NULL
                        THEN 'Skipped: backup already in progress'

                    WHEN l.LastFullAt IS NULL AND u.BackupFull = 1
                        THEN 'No previous FULL backup found'

                    WHEN u.BackupFull = 1
                     AND DATEDIFF(MINUTE, l.LastFullAt, @Now) >= u.Full_Freq_Minutes
                        THEN 'FULL frequency reached'

                    WHEN u.BackupDiff = 1
                     AND u.Diff_Freq_Minutes IS NOT NULL
                     AND l.LastFullAt IS NULL
                        THEN 'DIFF skipped: FULL baseline missing'

                    WHEN u.BackupDiff = 1
                     AND u.Diff_Freq_Minutes IS NOT NULL
                     AND l.LastFullAt IS NOT NULL
                     AND DATEDIFF
                        (
                            MINUTE,
                            CASE
                                WHEN l.LastDiffAt IS NULL THEN l.LastFullAt
                                WHEN l.LastFullAt > l.LastDiffAt THEN l.LastFullAt
                                ELSE l.LastDiffAt
                            END,
                            @Now
                        ) >= u.Diff_Freq_Minutes
                        THEN 'DIFF frequency reached'

                    WHEN u.BackupLog = 1
                     AND u.Log_Freq_Minutes IS NOT NULL
                     AND u.recovery_model_desc NOT IN ('FULL','BULK_LOGGED')
                        THEN 'LOG skipped: recovery model does not support log backups'

                    WHEN u.BackupLog = 1
                     AND u.Log_Freq_Minutes IS NOT NULL
                     AND l.LastFullAt IS NULL
                        THEN 'LOG skipped: FULL baseline missing'

                    WHEN u.BackupLog = 1
                     AND u.Log_Freq_Minutes IS NOT NULL
                     AND (
                            l.LastLogAt IS NULL
                            OR DATEDIFF(MINUTE, l.LastLogAt, @Now) >= u.Log_Freq_Minutes
                         )
                        THEN 'LOG frequency reached'

                    ELSE 'No backup due in current cycle'
                END
        INTO #Decision
        FROM #Universe u
        LEFT JOIN #LastRuns l
            ON l.DatabaseName = u.DatabaseName
        LEFT JOIN #RunningBackup rb
            ON rb.DatabaseName = u.DatabaseName;

        IF @Debug = 1
        BEGIN
            PRINT 'Decision matrix';
            SELECT *
            FROM #Decision
            ORDER BY
                RPO_Minutes ASC,
                TierID ASC,
                DatabaseName ASC;
        END;

        ---------------------------------------------------------------------
        -- 5) DRY RUN
        ---------------------------------------------------------------------
        IF @DryRun = 1
        BEGIN
            SELECT
                DatabaseName,
                TierID,
                TierName,
                recovery_model_desc,
                HasRunningBackup,
                LastFullAt,
                LastDiffAt,
                LastDiffEffectiveAt,
                LastLogAt,
                FullDue,
                DiffDue,
                LogDue,
                SelectedBackupType,
                DecisionReason
            FROM #Decision
            ORDER BY
                RPO_Minutes ASC,
                CASE SelectedBackupType
                    WHEN 'FULL' THEN 1
                    WHEN 'DIFF' THEN 2
                    WHEN 'LOG'  THEN 3
                    ELSE 4
                END,
                DatabaseName ASC;

            EXEC sys.sp_releaseapplock
                @Resource = 'cfg.usp_RunScheduledBackups',
                @LockOwner = 'Session';

            RETURN;
        END;

        ---------------------------------------------------------------------
        -- 6) EXECUTION QUEUE
        ---------------------------------------------------------------------
        SELECT
            IDENTITY(INT,1,1) AS QueueID,
            DatabaseName,
            TierID,
            SelectedBackupType
        INTO #Execution
        FROM #Decision
        WHERE SelectedBackupType IS NOT NULL
        ORDER BY
            RPO_Minutes ASC,
            CASE SelectedBackupType
                WHEN 'FULL' THEN 1
                WHEN 'DIFF' THEN 2
                WHEN 'LOG'  THEN 3
            END,
            DatabaseName ASC;

        IF NOT EXISTS (SELECT 1 FROM #Execution)
        BEGIN
            IF @Debug = 1
                PRINT 'No backups due in this cycle.';

            SELECT
                DatabaseName,
                TierID,
                TierName,
                HasRunningBackup,
                SelectedBackupType,
                DecisionReason
            FROM #Decision
            ORDER BY
                RPO_Minutes ASC,
                DatabaseName ASC;

            EXEC sys.sp_releaseapplock
                @Resource = 'cfg.usp_RunScheduledBackups',
                @LockOwner = 'Session';

            RETURN;
        END;

        ---------------------------------------------------------------------
        -- 7) EXECUTE BACKUPS INDIVIDUALLY
        ---------------------------------------------------------------------
        DECLARE exec_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT DatabaseName, TierID, SelectedBackupType
            FROM #Execution
            ORDER BY QueueID;

        OPEN exec_cursor;
        FETCH NEXT FROM exec_cursor INTO @db, @TierID, @BackupType;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                IF @Debug = 1
                BEGIN
                    PRINT CONCAT(
                        'Executing ',
                        @BackupType,
                        ' backup for database [',
                        @db,
                        '] TierID=',
                        @TierID
                    );
                END;

                EXEC cfg.usp_BackupDatabase
                    @DatabaseName =             @db,
                    @BackupType =               @BackupType,
                    @TierID =                   @TierID,
                    @PathType =                 'PRIMARY',
                    @UseMirrorToSecondary =     @UseMirrorToSecondary,
                    @WithVerify =               @WithVerify,
                    @CopyOnly =                 0,
                    @WithChecksum =             1,
                    @WithCompression =          1,
                    @StatsPercent =             10,
                    @CorrelationID =            @CorrelationID;
            END TRY
            BEGIN CATCH
                IF @Debug = 1
                BEGIN
                    PRINT CONCAT(
                        'Backup execution failed for [',
                        @db,
                        '] - ',
                        ERROR_MESSAGE()
                    );
                END;
            END CATCH;

            FETCH NEXT FROM exec_cursor INTO @db, @TierID, @BackupType;
        END;

        CLOSE exec_cursor;
        DEALLOCATE exec_cursor;

        ---------------------------------------------------------------------
        -- 8) OUTPUT / CONTRACT
        ---------------------------------------------------------------------
        SELECT d.DatabaseName, d.TierID, d.TierName, d.SelectedBackupType, d.DecisionReason,
            br.BackupRunID, br.StartedAt, br.EndedAt, br.BackupType, br.PathType,
            br.PrimaryFile, br.SecondaryFile, br.UsedMirror, br.VerifyRequested, br.VerifySucceeded,
            br.Succeeded, br.ErrorNumber, br.ErrorMessage, br.CorrelationID
        FROM #Decision d
        LEFT JOIN log.BackupRun br
            ON br.DatabaseName = d.DatabaseName
           AND br.CorrelationID = @CorrelationID
        WHERE d.SelectedBackupType IS NOT NULL
        ORDER BY
            d.RPO_Minutes ASC,
            CASE d.SelectedBackupType
                WHEN 'FULL' THEN 1
                WHEN 'DIFF' THEN 2
                WHEN 'LOG'  THEN 3
            END,
            d.DatabaseName ASC;

        EXEC sys.sp_releaseapplock
            @Resource = 'cfg.usp_RunScheduledBackups',
            @LockOwner = 'Session';
    END TRY
    BEGIN CATCH
        BEGIN TRY
            EXEC sys.sp_releaseapplock
                @Resource = 'cfg.usp_RunScheduledBackups',
                @LockOwner = 'Session';
        END TRY
        BEGIN CATCH
            -- Intentionally ignored
        END CATCH;

        DECLARE
            @ErrNum INT = ERROR_NUMBER(),
            @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();

        RAISERROR('cfg.usp_RunScheduledBackups failed. %d - %s', 16, 1, @ErrNum, @ErrMsg);
        RETURN;
    END CATCH;
END;
GO
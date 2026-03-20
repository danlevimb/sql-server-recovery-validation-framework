USE [DBAFramework];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [cfg].[usp_GetLatestBackupFiles]
    @SourceDB     SYSNAME,
    @RestoreMode  NVARCHAR(10) = 'AUTO', -- AUTO= FULL/DIFF/LOG; LOG_ONLY= FULL/LOG
    @StopAtDate   DATETIME2(3) = NULL,
    @Mark         NVARCHAR(128) = NULL
AS
/*==============================================================================
  Procedure : cfg.usp_GetLatestBackupFiles
  Project   : Automated Backup & Recovery Framework
  Author    : Dan Levi Menchaca Bedolla
  Role      : SQL Server DBA / Data Infrastructure & Reliability Engineering
  Created   : 2026
  Component : Restore Planning Engine

  Purpose   :
      Builds the restore chain required to recover a database either to a
      specific point in time (STOPAT) or to a marked transaction boundary.

      The procedure:
      - Identifies the most recent valid FULL backup
      - Optionally selects the latest valid DIFF backup
      - Builds the required LOG backup chain
      - Detects the target LOG for STOPAT or STOPBEFOREMARK scenarios
      - Returns structured metadata to be consumed by the restore engine

  Inputs    :
      @SourceDB -- Name of database to process.
      @RestoreMode -- 'AUTO' (FULL-DIFF-LOGs) / 'LOG_ONLY' (FULL-LOGs)
      @StopAtDate -- Date/Hour where restore will STOPAT
      @Mark -- Transaction Name where restore will STOPBEFOREMARK (If specified, overrides @StopAtDate)

  Outputs   :
      Restore chain metadata including:
      - backup_set_id
      - LSN boundaries
      - backup file names
      - STOPAT / MARK indicators
      - commit-time window diagnostics

  Dependencies :
      msdb.dbo.backupset
      msdb.dbo.backupmediafamily
      msdb.dbo.logmarkhistory
      sys.fn_dump_dblog

  Used By   :
      cfg.usp_RestorePointInTime

  Notes     :
      Designed as the restore-chain selection component of the framework.
      This procedure prioritizes deterministic chain construction and
      recoverability validation over simplistic backup-date selection.
==============================================================================*/
BEGIN
    -------------------------------------------------------------------------
    -- INPUT VARIABLES (FOR DEBUG-MODE DE-COMENTARIZE)
    -------------------------------------------------------------------------
    --DECLARE 
    --    @SourceDB       SYSNAME = 'AdventureWorks2022',
    --    @RestoreMode    NVARCHAR(10) = 'AUTO',
    --    -- @StopAtDate     DATETIME2(3) = N'2026-03-04 10:21:05.003',
    --    @Mark           NVARCHAR(128) = 'RT_130130899',  -- Marcador de paro; al usarse, se ignora la fecha especificada en @StopAt
    --    @StopAtDate     DATETIME2(3) = N'2026-03-04 10:00:00.000';
    --    --@Mark           NVARCHAR(128) = NULL;   -- Marcador de paro; al usarse, se ignora la fecha especificada en @StopAt

    SET NOCOUNT ON;    

    /* LOCAL VARIABLES */
    DECLARE 
        @FullFile           NVARCHAR(4000),
        @FullSetId          INT,
        @FullFinish         DATETIME2,
        @FullCheckpointLSN  NUMERIC(25,0),
        @FullDatabaseBackupLSN  NUMERIC(25,0),
    
        @NextLogSetId       INT,
        @PrevLogSetId       INT = NULL,
        @NextLogFinish      DATETIME2(3),
        @NextLogFile        NVARCHAR(4000),
        @NextLogFirstLSN    NUMERIC(25,0),
        @NextLogLastLSN     NUMERIC(25,0),
        @MinCommitTime      DATETIME2(7),
        @MaxCommitTime      DATETIME2(7),
       
        @DiffSetId          INT = NULL,
        @DiffFile           NVARCHAR(4000) = NULL,        

        @MarkLSN            NUMERIC(25,0) = NULL,        
        @PrevBaseLSN        NUMERIC(25,0),
        @BaseLastLSN        NUMERIC(25,0),        

        @StopMode           NVARCHAR(20) = CASE WHEN @Mark IS NOT NULL THEN N'MARK' ELSE N'DATE' END
        ;
    -------------------------------------------------------------------------
    -- PRIOR-VALIDATIONS
    -------------------------------------------------------------------------
    IF @RestoreMode NOT IN (N'AUTO', N'LOG_ONLY')
        BEGIN
            RAISERROR('Invalid @RestoreMode. Allowed values: AUTO (FULL+DIFF+LOG) | LOG_ONLY (FULL+LOG).', 16, 1);
            RETURN;
        END;

    IF @Mark IS NULL AND @StopAtDate IS NULL
        BEGIN
            RAISERROR('Invalid parameter setting (@StopAtDate / @Mark) cannot be both NULL', 16, 1);
            RETURN;
        END

    IF @StopMode = 'MARK'
        BEGIN                        
            /* TAKE LSN & MARKERS TIME */
            SELECT @MarkLSN = lmh.lsn, @StopAtDate = lmh.mark_time
            FROM msdb.dbo.logmarkhistory lmh
            WHERE lmh.database_name = @SourceDB
                AND lmh.mark_name = @Mark
            ORDER BY lmh.mark_time DESC;                

            IF @MarkLSN IS NULL
                BEGIN                           
                    RAISERROR('Specified marker [%s] does not exists in msdb..logmarkhistory.', 16, 1, @Mark);
                    RETURN;
                END;
        END;
       
    IF OBJECT_ID('tempdb..#FileList') IS NOT NULL DROP TABLE #FileList;

    CREATE TABLE #FileList (
          StepOrder         INT IDENTITY(1,1)
        , backup_set_id     INT
        
        , FirstLSN          NUMERIC(25,0) NULL
        , LastLSN           NUMERIC(25,0) NULL
        , CheckpointLSN     NUMERIC(25,0) NULL
        , DatabaseBackupLSN NUMERIC(25,0) NULL        

        , BackupFileName    NVARCHAR(4000)
        , BackupType        VARCHAR(10)

        , StartDate         DATETIME2
        , FinishDate        DATETIME2

        , IsStopAtDate      BIT DEFAULT (0)
        , StopDate          DATETIME2(3) NULL
        , IsStopAtMarker    BIT DEFAULT (0)        
        , Marker            NVARCHAR(128) 

        , MinCommitTime     DATETIME2(3) NULL
        , MaxCommitTime     DATETIME2(3) NULL        
        );     
    -------------------------------------------------------------------------
    -- FULL-BACKUP SECTION
    -------------------------------------------------------------------------   
    BEGIN
        INSERT INTO #FileList(backup_set_id, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupType, StartDate, FinishDate)
        SELECT TOP (1) backup_set_id, first_lsn, last_lsn, checkpoint_lsn, database_backup_lsn, 'FULL', backup_start_date, backup_finish_date
        FROM msdb.dbo.backupset
        WHERE database_name = @SourceDB
            AND type = 'D' -- MUST BE FULL-BACKUP
            AND backup_finish_date <= @StopAtDate -- MOST RECENT TO GIVEN DATE/HOUR 
        ORDER BY backup_finish_date DESC, backup_set_id DESC

        IF NOT EXISTS (SELECT 1 FROM #FileList) 
            BEGIN            
                RAISERROR('NO FULL BACKUP FOUND FOR [%s]', 16, 1, @SourceDB);
                RETURN;
            END;

        SELECT 
            @FullSetId = backup_set_id, 
            @FullFinish = FinishDate,
            @FullCheckpointLSN = CheckpointLSN,
            @FullDatabaseBackupLSN = DatabaseBackupLSN, -------
            @BaseLastLSN = LastLSN
        FROM #FileList;
    
        /* TAKE PRIMARY FILE PATH OR FIRST AVAILABLE */
        ;WITH FullSet AS (
            SELECT COALESCE(
                (SELECT TOP (1) mf.physical_device_name
                 FROM msdb.dbo.backupmediafamily mf
                 JOIN msdb.dbo.backupset bs2 ON bs2.media_set_id = mf.media_set_id             
                 WHERE bs2.backup_set_id = @FullSetId
                    AND mf.physical_device_name LIKE '%\PRIMARY\%'
                 ORDER BY mf.family_sequence_number),
                (SELECT TOP (1) mf.physical_device_name
                 FROM msdb.dbo.backupmediafamily mf
                 JOIN msdb.dbo.backupset bs2 ON bs2.media_set_id = mf.media_set_id
                 WHERE bs2.backup_set_id = @FullSetId
                 ORDER BY mf.family_sequence_number))AS BackupFile)
            UPDATE #FileList SET BackupFileName = BackupFile, @FullFile = BackupFile FROM FullSet
    END;    
    -------------------------------------------------------------------------
    -- DIFFERENTIAL-BACKUP SECTION
    -------------------------------------------------------------------------
    IF @RestoreMode = 'AUTO'
        BEGIN        
            /* 1) PICK LAST DIFF FOR THE FULL BACKUP */            
            ;WITH DiffCandidate AS (
                SELECT TOP (1)
                    bs.backup_set_id,                
                    bs.last_lsn
                FROM msdb.dbo.backupset bs
                WHERE bs.database_name = @SourceDB
                  AND bs.type = 'I'  -- MUST BE DIFF-BACKUP
                  AND bs.backup_finish_date <= @StopAtDate -- MOST RECENT TO GIVEN DATE/HOUR 
                  AND bs.database_backup_lsn = @FullCheckpointLSN -- MUST BELONG TO FULL-BACKUP
                ORDER BY bs.backup_finish_date DESC, bs.backup_set_id DESC)
            SELECT
                @DiffSetId  = backup_set_id,
                @BaseLastLSN = last_lsn -- NEW STARTING POINT FOR LOG FILES 
            FROM DiffCandidate;        

            /* 2) TAKE PRIMARY FILE PATH OR FIRST AVAILABLE */                        
            IF @DiffSetId IS NOT NULL
                BEGIN
                    SELECT @DiffFile = COALESCE(
                        (SELECT TOP (1) mf.physical_device_name FROM msdb.dbo.backupmediafamily mf JOIN msdb.dbo.backupset bs2 ON bs2.media_set_id = mf.media_set_id WHERE bs2.backup_set_id = @DiffSetId AND mf.physical_device_name LIKE '%\PRIMARY\%' ORDER BY mf.family_sequence_number),
                        (SELECT TOP (1) mf.physical_device_name FROM msdb.dbo.backupmediafamily mf JOIN msdb.dbo.backupset bs2 ON bs2.media_set_id = mf.media_set_id WHERE bs2.backup_set_id = @DiffSetId ORDER BY mf.family_sequence_number));
            
                    INSERT INTO #FileList (backup_set_id, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupFileName, BackupType, StartDate, FinishDate)
                    SELECT bs.backup_set_id, first_lsn, last_lsn, checkpoint_lsn,database_backup_lsn, @DiffFile, 'DIFF', bs.backup_start_date, bs.backup_finish_date 
                    FROM msdb.dbo.backupset bs
                    WHERE bs.backup_set_id = @DiffSetId;
                END                    
        END;
               
    SET @PrevBaseLSN = @BaseLastLSN;    
    -------------------------------------------------------------------------
    -- LOG-BACKUP SECTION
    -------------------------------------------------------------------------    
    WHILE 1 = 1
        BEGIN                                    
            SELECT TOP (1)  
                @NextLogSetId = bs.backup_set_id,
                @NextLogFinish = bs.backup_finish_date,
                @NextLogFirstLSN = bs.first_lsn,
                @NextLogLastLSN = bs.last_lsn,
                @NextLogFile = COALESCE(
                        (SELECT TOP (1) mf.physical_device_name FROM msdb.dbo.backupmediafamily mf WHERE mf.media_set_id = bs.media_set_id AND mf.physical_device_name LIKE '%\PRIMARY\%' ORDER BY mf.family_sequence_number),
                        (SELECT TOP (1) mf.physical_device_name FROM msdb.dbo.backupmediafamily mf WHERE mf.media_set_id = bs.media_set_id ORDER BY mf.family_sequence_number))
            FROM msdb.dbo.backupset bs 
            WHERE 
                bs.database_name = @SourceDB AND 
                bs.type = 'L' AND -- MUST BE LOG-BACKUP
                bs.database_backup_lsn = @FullCheckpointLSN AND -- MUST BELONG TO FULL-BACKUP
                bs.first_lsn <= @BaseLastLSN AND bs.last_lsn > @BaseLastLSN -- LSN MUST BE BETWEEN FIRST & LAST LSN OF LOG-FILE
            ORDER BY bs.first_lsn ASC, bs.backup_set_id ASC;
                
            IF @NextLogSetId IS NULL
                BEGIN                    
                    SET @DiffFile = CONVERT(NVARCHAR(40), @BaseLastLSN)
                    RAISERROR('LSN GAP: No LOG backup covers required LSN [%s]. Chain cannot be constructed.', 16, 1, @DiffFile);
                    RETURN;
                END    

            IF @NextLogSetId = @PrevLogSetId
                BEGIN
                    SET @DiffFile = CONVERT(NVARCHAR(40), @NextLogSetId)
                    RAISERROR('LSN LOOP detected: same LOG backup_set_id selected repeatedly (%d). Check ordering/filters.', 16, 1, @DiffFile);
                    RETURN;
                END

            IF @NextLogLastLSN <= @PrevBaseLSN
                BEGIN
                    RAISERROR('LSN NO-ADVANCE: Selected LOG does not advance chain. BaseLSN=%s, LogLastLSN=%s.', 16, 1, @PrevBaseLSN, @NextLogLastLSN);
                    RETURN;
                END  

            -- TAKE LOG-FILE AS VALID
            INSERT INTO #FileList (backup_set_id, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN, BackupFileName, BackupType, StartDate, FinishDate)
            SELECT bs.backup_set_id, bs.first_lsn, bs.last_lsn, bs.checkpoint_lsn, bs.database_backup_lsn, @NextLogFile, 'LOG', bs.backup_start_date, bs.backup_finish_date
            FROM msdb.dbo.backupset bs
            WHERE bs.backup_set_id = @NextLogSetId;            

            IF @StopMode = 'MARK'                
                /* FLAG LOG-FILE IF MARKER IS IN BETWEEN FIRST & LAST LSN*/               
                IF @NextLogFirstLSN <= @MarkLSN AND @NextLogLastLSN >= @MarkLSN
                    BEGIN
                        UPDATE #FileList SET IsStopAtMarker = 1, Marker = @Mark WHERE backup_set_id = @NextLogSetId;
                        BREAK;
                    END;      

            IF @StopMode = 'DATE'
                IF @NextLogFinish > @StopAtDate
                    BEGIN
                        /* DUMP LOG CONTENT TO FIND MIN & MAX TRANSACTION TIMESTAMPS */                        
                        /* THIS COMPONENT CAN BE IGNORED IF RESTORE-PERFORMANCE IS CRITICAL */
                        ;WITH LogTarget AS (
                            SELECT MIN([End Time]) AS MinCommitTime, MAX([End Time]) AS MaxCommitTime
                            FROM sys.fn_dump_dblog(NULL, NULL, N'DISK', 1, @NextLogFile,                
                                DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
                                DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
                                DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
                                DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
                                DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
                                DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
                                DEFAULT, DEFAULT, DEFAULT)
                                WHERE [Operation] = 'LOP_COMMIT_XACT' AND [End Time] IS NOT NULL)
                        UPDATE #FileList SET 
                            MinCommitTime   = DATEADD(MILLISECOND, -10, LogTarget.MinCommitTime),
                            MaxCommitTime   = DATEADD(MILLISECOND,  10, LogTarget.MaxCommitTime),

                            @MinCommitTime  = DATEADD(MILLISECOND, -10, LogTarget.MinCommitTime),
                            @MaxCommitTime  = DATEADD(MILLISECOND,  10, LogTarget.MaxCommitTime)                            
                        FROM #FileList 
                        CROSS JOIN LogTarget 
                        WHERE #FileList.backup_set_id = @NextLogSetId;

                        /* VALIDATES STOPAT EFFECTIVELY FALLS IN THIS LOG-FILE */                        
                        IF @StopAtDate >= @MinCommitTime and @StopAtDate <= @MaxCommitTime
                            BEGIN
                                UPDATE #FileList SET IsStopAtDate = 1, StopDate = @StopAtDate WHERE backup_set_id = @NextLogSetId
                                BREAK;
                            END;
                                                
                        IF @StopAtDate < @MinCommitTime
                            BEGIN
                                /* FLAG LOG-FILE AS CORRECT FOR STOPAT */
                                UPDATE #FileList SET IsStopAtDate = 1, StopDate = @StopAtDate WHERE backup_set_id = @NextLogSetId
                                BREAK;
                            END;
                    END
                
            /* TAKE NEW LSN BASE FOR NEXT ITERATION */            
            SELECT 
                @BaseLastLSN = @NextLogLastLSN,
                @PrevLogSetId = @NextLogSetId,
                @NextLogSetId = NULL;
        END;
    ---------------------------------------------------------------------
    -- SHOW CONTRACT
    ---------------------------------------------------------------------
    SELECT StepOrder, backup_set_id, FirstLSN, LastLSN, CheckpointLSN, 
        DatabaseBackupLSN, BackupFileName, BackupType, StartDate, FinishDate, 
        IsStopAtDate, StopDate, IsStopAtMarker, Marker, MinCommitTime, MaxCommitTime 
    FROM #FileList;                        
END;
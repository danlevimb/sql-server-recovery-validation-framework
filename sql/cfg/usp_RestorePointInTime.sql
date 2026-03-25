USE [DBAFramework];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [cfg].[usp_RestorePointInTime]
    @SourceDB       SYSNAME,
    @TargetDB       SYSNAME,
    @StopAtDate     DATETIME2(3) = NULL,      -- Date / Hour to StopAt; used only when @StopBeforeMark is NULL
    @StopBeforeMark NVARCHAR(128) = NULL,     -- Stop Marker to StopAt; when used, overrides @StopAt value.
    @DoCheckDB      BIT = 1,
    @ReplaceTarget  BIT = 1,
    @Debug          BIT = 0,
    @RunID          BIGINT OUTPUT
AS
/*==============================================================================
  Procedure : cfg.usp_RestorePointInTime
  Project   : Automated Backup & Recovery Framework
  Author    : Dan Levi Menchaca Bedolla
  Role      : SQL Server DBA / Data Infrastructure & Reliability Engineering
  Created   : 2026
  Component : Restore Execution Engine
  
  Purpose   :  
      Executes a full restore workflow for a target database using the
      restore chain previously resolved by cfg.usp_GetLatestBackupFiles.

      The procedure:
      - Creates the restore execution header
      - Builds and executes restore commands step by step
      - Supports STOPAT and STOPBEFOREMARK recovery modes
      - Records execution detail, timings, and per-step errors
      - Optionally runs DBCC CHECKDB after recovery
      - Persists operational evidence into framework logging tables

  Inputs    :
        @SourceDB 
        @TargetDB 
        @StopAtDate
        @StopBeforeMark
        @DoCheckDB
        @ReplaceTarget
        @Debug      

  Outputs   :
        @RunID OUTPUT

      - Restore execution detail for visual inspection
      - RestoreRunID through OUTPUT parameter
      - Header and step-level persistence into framework log tables

  Dependencies :
      cfg.usp_GetLatestBackupFiles
      log.RestoreTestRun
      log.RestoreStepExecution
      usp_GetRestoreTestBasePath

  Used By   :
      cfg.usp_RunRestoreTests

  Notes     :
      This procedure acts as the restore execution engine of the framework.
      It is designed for deterministic execution, auditability, and
      recoverability testing in controlled validation scenarios.
==============================================================================*/
BEGIN
    -------------------------------------------------------------------------
    -- INPUT VARIABLES (FOR DEBUG-MODE DE-COMENTARIZE)
    ---------------------------------------------------------------------------
    --DECLARE 
    --@SourceDB       SYSNAME = 'AdventureWorks2022',
    --@TargetDB       SYSNAME = 'AdventureWorks2022_RestoreTest',

    ---- @StopAtDate     DATETIME2(3) = N'2026-03-04 10:00:00.000',
    --@StopAtDate     DATETIME2(3) = NULL,
    ----@StopAtDate              DATETIME2(7) = N'2026-02-11 12:25:00.000',     -- Fecha y hora de paro, usado solo cuando @StopBeforeMark es NULL
    --@StopBeforeMark NVARCHAR(128) = 'RT_158202348',   -- Marcador de paro; al usarse, se ignora la fecha especificada en @StopAt
    ---- @StopBeforeMark      NVARCHAR(128) = NULL,   -- Marcador de paro; al usarse, se ignora la fecha especificada en @StopAt
    --@DoCheckDB      BIT = 1,
    --@ReplaceTarget  BIT = 1,
    --@Debug          BIT = 1,
    --@RunID          BIGINT

    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    -------------------------------------------------------------------------
    -- NORMALIZE INPUT-DATA
    -------------------------------------------------------------------------
    SET @SourceDB = LTRIM(RTRIM(@SourceDB));
    SET @TargetDB = LTRIM(RTRIM(@TargetDB));
    SET @StopBeforeMark = NULLIF(LTRIM(RTRIM(@StopBeforeMark)), N''); 
    -------------------------------------------------------------------------
    -- PRIOR-VALIDATIONS
    -------------------------------------------------------------------------
    IF DB_ID(@SourceDB) IS NULL
        BEGIN 
            RAISERROR('Specified Source-DB [%s] does not exists. ', 16, 1, @SourceDb);
            RETURN;
        END;

    IF @StopBeforeMark IS NULL AND @StopAtDate IS NULL
        BEGIN
            RAISERROR('None of the required input parameters are properly set (@StopBeforeMark / @StopAt).', 16, 1);
            RETURN;
        END
    
    IF @StopBeforeMark IS NOT NULL
        IF (SELECT lsn from msdb.dbo.logmarkhistory where database_name = @SourceDB and mark_name = @StopBeforeMark) IS NULL
            BEGIN                      
                RAISERROR('Specified marker [%s] does not exists in msdb..logmarkhistory.', 16, 1, @StopBeforeMark);
                RETURN;
            END;
  
    IF OBJECT_ID('tempdb..#RestoreChain') IS NOT NULL DROP TABLE #RestoreChain;

    /* LOCAL VARIABLES */
    DECLARE        
        @CorrID                 UNIQUEIDENTIFIER = NEWID(),
        @RestoreBase            NVARCHAR(260),
        
        @FullFile               NVARCHAR(4000),        
        @DiffFile               NVARCHAR(4000),
        
        @LogsBase               DATETIME2(3),
        @LogCount               INT = 0,
        @Sql                    NVARCHAR(MAX),
        
        @DataLogical            SYSNAME,
        @LogLogical             SYSNAME,
        @DataTarget             NVARCHAR(4000),
        @LogTarget              NVARCHAR(4000),

        @StopAtForSelection     DATETIME2(3),        
        @MarkLogFile            NVARCHAR(4000) = NULL,
        @MarkLSN                NUMERIC(25,0) = NULL,
        @StopMode               NVARCHAR(20) = CASE WHEN @StopBeforeMark IS NOT NULL THEN N'STOPBEFOREMARK' ELSE N'STOPAT' END,
        -- Cursor Variables
        @StepOrder              INT,
        @BackupType             VARCHAR(10),
        @FileName               NVARCHAR(4000),
        @FinishDate             DATETIME2(3),
        
        @IsStopAtDate           BIT,
        @StopDate               DATETIME2(3) = NULL,

        @IsStopAtMarker         BIT,       
        @Marker                 NVARCHAR(128),
        @StartedAt              DATETIME2(3) = SYSDATETIME(),
        @ErrorMsg               NVARCHAR(4000)
        ;
    -------------------------------------------------------------------------
    -- GET LOGICAL NAMES FROM SOURCE DB
    -------------------------------------------------------------------------
    SELECT TOP (1) @DataLogical = mf.name FROM sys.master_files mf WHERE mf.database_id = DB_ID(@SourceDB) AND mf.type_desc = 'ROWS' ORDER BY mf.file_id;
    SELECT TOP (1) @LogLogical = mf.name FROM sys.master_files mf WHERE mf.database_id = DB_ID(@SourceDB) AND mf.type_desc = 'LOG' ORDER BY mf.file_id;

    IF @DataLogical IS NULL OR @LogLogical IS NULL
        BEGIN
            RAISERROR('Could not resolve logical file names from [%s]', 16, 1, @SourceDB);
            RETURN;
        END
    -------------------------------------------------------------------------
    -- GET RESTORE PATH
    -------------------------------------------------------------------------
    EXEC cfg.usp_GetRestoreTestBasePath @BasePath = @RestoreBase OUTPUT;  
    -------------------------------------------------------------------------
    -- SET PHISICAL NAMES FOR TARGET FILES 
    -------------------------------------------------------------------------
    SET @DataTarget = @RestoreBase + @TargetDB + N'_DATA.mdf';
    SET @LogTarget  = @RestoreBase + @TargetDB + N'_LOG.ldf';    
    -------------------------------------------------------------------------
    -- NOTIFY EXECUTION MODE
    -------------------------------------------------------------------------
    BEGIN
        PRINT '';
        PRINT '------------------------------';
        PRINT 'DBG Procedure =[cfg].[usp_RestorePointInTime]';
        PRINT 'DBG Mode      =' + QUOTENAME(@StopMode);
        PRINT 'DBG SourceDB  =' + QUOTENAME(@SourceDB);
        PRINT 'DBG TargetDB  =' + QUOTENAME(@TargetDB);
        PRINT 'DBG Started at=' + QUOTENAME(@StartedAt);
        PRINT '';

        IF @StopMode ='STOPBEFOREMARK'
            BEGIN
                -- GET Mark LSN/Time
                SELECT @MarkLSN = lmh.lsn, @StopAtForSelection = lmh.mark_time
                FROM msdb.dbo.logmarkhistory lmh
                WHERE lmh.database_name = @SourceDB
                    AND lmh.mark_name = @StopBeforeMark
                ORDER BY lmh.mark_time DESC;
            
                PRINT 'DBG Stop Mark =' + QUOTENAME(@StopBeforeMark);
                PRINT 'DBG Mark LSN  =' + QUOTENAME(CONVERT(NVARCHAR(60), @MarkLSN));
                PRINT 'DBG Mark Time =' + QUOTENAME(CONVERT(NVARCHAR(60), @StopAtForSelection));
            END;
        ELSE
            BEGIN            
                SET @StopAtForSelection = @StopAtDate;
                PRINT 'DBG Stop At   =' + QUOTENAME(CONVERT(NVARCHAR(60), @StopAtForSelection));
            END;
        PRINT '';
    END;
    -------------------------------------------------------------------------
    -- GET RESTORE-CHAIN: (FULL-DIFF-LOGs)
    -------------------------------------------------------------------------
    CREATE TABLE #RestoreChain (
          StepOrder         INT
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

    INSERT INTO #RestoreChain 
    EXEC cfg.usp_GetLatestBackupFiles 
        @SourceDB   =   @SourceDB,
        @StopAtDate =   @StopAtForSelection,
        @Mark       =   @StopBeforeMark
        
    /* GROW RESULT BY ADDING FORENSICS */
    ALTER TABLE #RestoreChain ADD
        TSQL            NVARCHAR(MAX) NULL,
        Executed        BIT NOT NULL CONSTRAINT DF_RChain_Executed DEFAULT(0),
        ExecStartedAt   DATETIME2(3) NULL,
        ExecEndedAt     DATETIME2(3) NULL,
        ExecErrorNum    INT NULL,
        ExecErrorMsg    NVARCHAR(2048) NULL;        
    ---------------------------------------------------------------------
    -- BUILD RESTORE COMMANDS
    ---------------------------------------------------------------------
    BEGIN 
        DECLARE curBuild CURSOR LOCAL FAST_FORWARD FOR
        SELECT NULL, StepOrder, BackupType, BackupFileName, IsStopAtDate, StopDate, IsStopAtMarker, Marker, FinishDate FROM #RestoreChain ORDER BY StepOrder;

        OPEN curBuild;
        FETCH NEXT FROM curBuild INTO @Sql, @StepOrder, @BackupType, @FileName, @IsStopAtDate, @StopDate, @IsStopAtMarker, @Marker, @FinishDate;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @BackupType = 'FULL'
                SELECT 
                    @Sql =
                        N'RESTORE DATABASE ' + QUOTENAME(@TargetDB) +
                        N' FROM DISK = N''' + REPLACE(@FileNAme, '''', '''''') + N''' ' +
                        N'WITH NORECOVERY, ' +
                        CASE WHEN @ReplaceTarget = 1 THEN N'REPLACE, ' ELSE N'' END +
                        N'MOVE N''' + REPLACE(@DataLogical, '''', '''''') + N''' TO N''' + REPLACE(@DataTarget, '''', '''''') + N''', ' +
                        N'MOVE N''' + REPLACE(@LogLogical,  '''', '''''') + N''' TO N''' + REPLACE(@LogTarget,  '''', '''''') + N''';', 
                    @FullFile = @FileName, 
                    @LogsBase = @FinishDate;

            IF @BackupType = 'DIFF'
                SELECT 
                    @Sql = 
                        N'RESTORE DATABASE ' + QUOTENAME(@TargetDB) + 
                        N' FROM DISK = N''' + REPLACE(@FileName, '''', '''''') + N''' ' + 
                        N'WITH NORECOVERY;', 
                    @DiffFile = @FileName,
                    @LogsBase = @FinishDate;        
        
            IF @BackupType = 'LOG'
                IF @StopMode = N'STOPAT'
                    IF @IsStopAtDate = 1
                        SET @Sql = N'RESTORE LOG ' + QUOTENAME(@TargetDB) + N' FROM DISK = N''' + REPLACE(@FileNAme, '''', '''''') + N''' ' + N'WITH STOPAT = @pStopAt, RECOVERY;';
                    ELSE
                        SET @Sql = N'RESTORE LOG ' + QUOTENAME(@TargetDB) + N' FROM DISK = N''' + REPLACE(@FileName, '''', '''''') + N''' ' + N'WITH NORECOVERY;';
                ELSE
                    IF @IsStopAtMarker = 1
                        BEGIN
                            SELECT @Sql = N'RESTORE LOG ' + QUOTENAME(@TargetDB) + N' FROM DISK = N''' + REPLACE(@FileName,'''','''''') + N''' ' + N'WITH STOPBEFOREMARK = N''' + REPLACE(@StopBeforeMark,'''','''''') + N''', RECOVERY;', @MarkLogFile = @FileName;                

                            /* DELETE ANY FURTHER STEP, WE REACHED THE RIGHT ONE!*/
                            DELETE #RestoreChain WHERE StepOrder > @StepOrder
                        END
                    ELSE
                        SET @Sql = N'RESTORE LOG ' + QUOTENAME(@TargetDB) + N' FROM DISK = N''' + REPLACE(@FileNAme, '''', '''''') + N''' ' + N'WITH NORECOVERY;';
            
            UPDATE #RestoreChain SET TSQL = @Sql WHERE StepOrder = @StepOrder;

            FETCH NEXT FROM curBuild INTO @Sql, @StepOrder, @BackupType, @FileName, @IsStopAtDate, @StopDate, @IsStopAtMarker, @Marker, @FinishDate;
        END

        CLOSE curBuild;
        DEALLOCATE curBuild;           
       
        RAISERROR('1.0: >>> RESTORE-CHAIN SUCCESSFULLY BUILT >>> ',0,1) WITH NOWAIT;
    END 
    ---------------------------------------------------------------------
    -- EXECUTE RESTORE CHAIN
    ---------------------------------------------------------------------        
    BEGIN TRY
        -------------------------------------------------------------------------
        -- A) CLEAN TARGET ENVIRONMENT
        -------------------------------------------------------------------------
        IF DB_ID(@TargetDB) IS NOT NULL
            BEGIN
                RAISERROR('2.1: >>> SET NEW TARGET ENVIRONMENT >>> ',0,1) WITH NOWAIT;
                
                IF EXISTS (SELECT 1 FROM sys.databases WHERE name=@TargetDb AND state_desc='RESTORING')
                    BEGIN
                        SET @Sql = N'RESTORE DATABASE ' + QUOTENAME(@TargetDB) + N' WITH RECOVERY;';                                                        
                        IF @Debug = 1 PRINT @Sql;                        
                        EXEC sys.sp_executesql @Sql;                
                    END

                SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@TargetDB) + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
                IF @Debug = 1 PRINT @Sql;     
                EXEC sys.sp_executesql @Sql;
            
                SET @Sql = N'DROP DATABASE ' + QUOTENAME(@TargetDB) + N';';
                IF @Debug = 1 PRINT @Sql;
                EXEC sys.sp_executesql @Sql;            
            END;
        ---------------------------------------------------------------------
        -- B) INSERT RESTORE HEADER [log].[RestoreTestRun]
        ---------------------------------------------------------------------
        BEGIN
            SELECT @LogCount = COUNT(*) FROM #RestoreChain WHERE BackupType = 'LOG'

            INSERT INTO log.RestoreTestRun (
                CorrelationID, SourceDatabase, TargetDatabase, StopAt, FullBackupFile, 
                DiffBackupFile,DataFileTarget, LogFileTarget, CheckDbRequested, 
                DebugEnabled, StartedAt, LogsBaseDate, LogBackupFilesCount, MarkLogFile)
            VALUES (
                @CorrID, @SourceDB, @TargetDB, @StopAtForSelection, @FullFile, 
                @DiffFile, @DataTarget, @LogTarget, @DoCheckDB, 
                @Debug, SYSDATETIME(), @LogsBase, @LogCount,@MarkLogFile);

            SET @RunID = SCOPE_IDENTITY();
        END;
        ---------------------------------------------------------------------
        -- C) EXECUTE TSQL
        ---------------------------------------------------------------------        
        BEGIN
            DECLARE curExec CURSOR LOCAL FAST_FORWARD FOR SELECT StepOrder, TSQL FROM #RestoreChain ORDER BY StepOrder;

            OPEN curExec;
            FETCH NEXT FROM curExec INTO @StepOrder, @Sql

            WHILE @@FETCH_STATUS = 0
            BEGIN            
                IF @Sql IS NULL OR LTRIM(RTRIM(@Sql)) = N''
                    RAISERROR('Execution plan contains NULL/empty TSQL at StepOrder=%d.', 16, 1, @StepOrder);
            
                UPDATE #RestoreChain SET ExecStartedAt = SYSDATETIME() WHERE StepOrder = @StepOrder;
                
                SET @ErrorMsg = '3.' + CONVERT(NVARCHAR(55), @StepOrder) + ': >>> RESTORING... >>>'                 
                RAISERROR(@ErrorMsg,0,1) WITH NOWAIT;

                IF @Debug = 1 PRINT @Sql;
                BEGIN TRY                                    
                    /* LOOK HOW @pStopAt IS ALWAYS SENT AS A PARAMETER; EVEN QUERY DOES NOT USE IT */
                    EXEC sys.sp_executesql @Sql, N'@pStopAt datetime2(3)', @pStopAt = @StopAtForSelection;

                    UPDATE #RestoreChain SET Executed = 1, ExecEndedAt  = SYSDATETIME() WHERE StepOrder = @StepOrder;               
                END TRY
                BEGIN CATCH
                    UPDATE #RestoreChain SET ExecEndedAt  = SYSDATETIME(), ExecErrorNum = ERROR_NUMBER(), ExecErrorMsg = ERROR_MESSAGE() WHERE StepOrder = @StepOrder;
                    
                    DECLARE @StepErrMsg NVARCHAR(2048) =
                        N'RESTORE step failed. StepOrder=' + CONVERT(NVARCHAR(12), @StepOrder)
                        + N'. Error ' + CONVERT(NVARCHAR(12), ERROR_NUMBER()) 
                        + N': ' + ERROR_MESSAGE();
                    
                    IF CURSOR_STATUS('local', 'curExec') >=  0 CLOSE curExec;
                    IF CURSOR_STATUS('local', 'curExec') >= -1 DEALLOCATE curExec;
                                        
                    /* RAISE THE ERROR TO TRY-CATCH */
                    RAISERROR(@StepErrMsg, 16, 1);
                END CATCH

                FETCH NEXT FROM curExec INTO @StepOrder, @Sql;
            END
        
            CLOSE curExec;
            DEALLOCATE curExec;
        END;        
        ---------------------------------------------------------------------
        -- D) SET DATABASE MULTI-USER ACCESSIBLE
        ---------------------------------------------------------------------
        BEGIN
            SET @Sql = N'ALTER DATABASE ' + QUOTENAME(@TargetDB) + N' SET MULTI_USER;';
        
            RAISERROR('4.0: >>> SET DATABASE ACCES MULTI-USER >>> ',0,1) WITH NOWAIT;

            IF @Debug = 1 PRINT @Sql;            
            EXEC sys.sp_executesql @Sql;
        END        
        ---------------------------------------------------------------------
        -- E) UPDATE RESTORE HEADER IN log.RestoreTestRun / INSERT DETAIL IN log.RestoreStepExecution
        ---------------------------------------------------------------------
        UPDATE log.RestoreTestRun SET EndedAt = SYSDATETIME(), Succeeded = 1 WHERE RestoreRunID = @RunID;
                
        INSERT INTO log.RestoreStepExecution
            (RestoreRunID, StepOrder, backup_set_id, BackupType, BackupFileName, FirstLSN, LastLSN, CheckpointLSN,
            DatabaseBackupLSN, StartDate, FinishDate, IsStopAtDate, StopDate, MinCommitTime, MaxCommitTime, IsStopAtMarker,
            Marker, MarkLSN, TSQL, Executed, ExecStartedAt, ExecEndedAt, ExecErrorNum, ExecErrorMsg)
        SELECT @RunID, StepOrder, backup_set_id, BackupType, BackupFileName, FirstLSN, LastLSN, CheckpointLSN,
            DatabaseBackupLSN, StartDate, FinishDate, IsStopAtDate, StopDate, MinCommitTime, MaxCommitTime, IsStopAtMarker,
            Marker, @MarkLSN, TSQL, Executed, ExecStartedAt, ExecEndedAt, ExecErrorNum, ExecErrorMsg
        FROM #RestoreChain;
        ---------------------------------------------------------------------
        -- F) OPTIONAL DATABASE CHECK
        ---------------------------------------------------------------------
        IF @DoCheckDB = 1
            BEGIN            
                SET @Sql = N'DBCC CHECKDB(' + QUOTENAME(@TargetDB) + N') WITH NO_INFOMSGS;';
            
                RAISERROR('4.1: >>> CHECK NEWLY-RESTORED DATABASE >>> ',0,1) WITH NOWAIT;

                IF @Debug = 1 PRINT @Sql;                            
                EXEC sys.sp_executesql @Sql;
                                
                UPDATE log.RestoreTestRun SET CheckDbSucceeded = 1 WHERE RestoreRunID = @RunID;
            END
        ---------------------------------------------------------------------
        -- G) SHOW CONTRACT - EXEC HISTORY
        ---------------------------------------------------------------------
        BEGIN
            IF @StopMode = 'STOPBEFOREMARK'
                SELECT StepOrder, backup_set_id, FirstLSN, @MarkLSN MarkLSN, LastLSN, BackupType, StartDate, FinishDate, 
                    IsStopAtMarker, Marker, 
                    TSQL, Executed, ExecStartedAt, ExecEndedAt,ExecErrorNum, ExecErrorMsg
                FROM #RestoreChain
            ELSE
                SELECT StepOrder, backup_set_id, BackupType, StartDate, FinishDate, 
                    IsStopAtDate, StopDate, MinCommitTime, MaxCommitTime, 
                    TSQL, Executed, ExecStartedAt, ExecEndedAt, ExecErrorNum, ExecErrorMsg
                FROM #RestoreChain                       
        
            PRINT '';
            PRINT 'DBG Ended at     =' + QUOTENAME(SYSDATETIME());
            PRINT 'DBG Procedure    =' 
                + '[cfg].[usp_RestorePointInTime]: SUCCESSFULLY RUN! IN ' 
                + FORMAT(DATEDIFF(MILLISECOND, @StartedAt, SYSDATETIME()) / 1000.0, 'N3')
                + ' seconds.';
            PRINT '------------------------------';

            SELECT * FROM LOG.RestoreTestRun WHERE RestoreRunID = @RunID;
        END;
    END TRY
    BEGIN CATCH        
        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        DECLARE @ErrNum INT = ERROR_NUMBER();
        ---------------------------------------------------------------------
        -- H) UPDATE RESTORE UN-SUCCESSFULL 
        ---------------------------------------------------------------------                
        UPDATE log.RestoreTestRun
        SET EndedAt = SYSDATETIME(),
            Succeeded = 0,
            CheckDbSucceeded = CASE WHEN CheckDbRequested = 1 THEN 0 ELSE CheckDbSucceeded END,
            ErrorNumber = ERROR_NUMBER(),
            ErrorMessage = ERROR_MESSAGE()
        WHERE RestoreRunID = @RunID;        

        IF NOT EXISTS (SELECT 1 FROM log.RestoreStepExecution WHERE RestoreRunID = @RunID)
            INSERT INTO log.RestoreStepExecution
                (RestoreRunID, StepOrder, backup_set_id, BackupType, BackupFileName, FirstLSN, LastLSN, CheckpointLSN,
                DatabaseBackupLSN, StartDate, FinishDate, IsStopAtDate, StopDate, MinCommitTime, MaxCommitTime, IsStopAtMarker,
                Marker, MarkLSN, TSQL, Executed, ExecStartedAt, ExecEndedAt, ExecErrorNum, ExecErrorMsg)
            SELECT @RunID, StepOrder, backup_set_id, BackupType, BackupFileName, FirstLSN, LastLSN, CheckpointLSN,
                DatabaseBackupLSN, StartDate, FinishDate, IsStopAtDate, StopDate, MinCommitTime, MaxCommitTime, IsStopAtMarker,
                Marker, @MarkLSN, TSQL, Executed, ExecStartedAt, ExecEndedAt, ExecErrorNum, ExecErrorMsg
            FROM #RestoreChain;
        
        PRINT '';
        PRINT 'DBG Ended at     =' + QUOTENAME(SYSDATETIME());                
        RAISERROR('DBG Procedure    =[cfg].[usp_RestorePointInTime]: FAILED. Error %d: %s', 16, 1, @ErrNum, @ErrMsg);
        PRINT '------------------------------';

        RETURN;
    END CATCH;
END;
GO



   
CREATE PROC [dbo].[SP_T_DIM_FND_COM_MONTH_N_I] AS

BEGIN

    SET NOCOUNT ON

    BEGIN

        DECLARE @v_run_pgm          varchar(50)
               ,@v_st_date          datetime
               ,@v_load_cnt         decimal(18,0)
               ,@v_enum             int
               ,@v_err_mesg         varchar(4000)
               ,@v_pgm_status       varchar(1)
               ,@v_work_result      int
               ,@v_tgt_job_area     varchar(10)
               ,@v_parm_from        varchar(50)
               ,@v_parm_to          varchar(50)
        ;

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_MONTH_N_I'
        ;
        SET @v_st_date = DATEADD(HOUR, 9 ,GETDATE())
        ;
        SET @v_pgm_status = 'S'
        ;
        SET @v_work_result = 0
        ;
        SET @v_load_cnt = 0
        ;
        SET @v_tgt_job_area = 'FACT'
        ;

        BEGIN TRY


            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_MONTH]
            ;
            
            INSERT INTO [dbo].[T_DIM_FND_COM_MONTH]
            (
                   [YYYYMM]                                      --년월
                  ,[YYYYMM_NAME]                                 --년월명
                  ,[MONTH]                                       --월
                  ,[MONTH_NAME]                                  --월명
                  ,[YYYYQQ]                                      --년분기
                  ,[YYYYQQ_NAME]                                 --년분기명
                  ,[YYYYHH]                                      --년반기
                  ,[YYYYHH_NAME]                                 --년반기명
                  ,[YYYY]                                        --년도
                  ,[YYYY_NAME]                                   --년도명
                  ,[YYYYHH2]                                     --년반기2
                  ,[DATE_KOR_YYM]                                --년월 한글약어명
                  ,[DATE_YM_SEP_DOT]                             --년월 약어명
                  ,[ETL_DT]                                      --적재일시
            )
            SELECT [YYYYMM]                                                                                 --년월
                  ,[YYYYMM_NAME]                                                                            --년월명
                  ,[MONTH]                                                                                  --월
                  ,[MONTH_NAME]                                                                             --월명
                  ,[YYYYQQ]                                                                                 --년분기
                  ,[YYYYQQ_NAME]                                                                            --년분기명
                  ,[YYYYHH]                                                                                 --년반기
                  ,[YYYYHH_NAME]                                                                            --년반기명
                  ,[YYYY]                                                                                   --년도
                  ,[YYYY_NAME]                                                                              --년도명
                  ,REPLACE([YYYYHH],'S','H')                                     AS [YYYYHH2]               --년반기2
                  ,SUBSTRING([YYYYMM_NAME],3,10)                                 AS [DATE_KOR_YYM]          --년월 한글약어명
                  ,CONCAT(SUBSTRING([YYYYMM],1,4),'.',SUBSTRING([YYYYMM],5,2))   AS [DATE_YM_SEP_DOT]       --년월 약어명
                  ,DATEADD(HOUR, 9 ,GETDATE())                                   AS [ETL_DT]                --적재일시
              FROM dbo.DD_COM_MONTH
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_MONTH]
             WHERE ETL_DT >= @v_st_date
              ;

        END TRY

        BEGIN CATCH

            SET @v_work_result = 1
            ;
            SET @v_enum = ERROR_NUMBER()
            ;
            SET @v_err_mesg = ERROR_MESSAGE()
            ;
            SET @v_pgm_status = 'E'

            EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status

        END CATCH

        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

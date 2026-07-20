CREATE PROC [dbo].[SP_T_DIM_FND_COM_ITEM_TYPE_N_C] AS

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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_ITEM_TYPE_N_C'
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

            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_ITEM_TYPE]
            ;
            
            INSERT INTO [dbo].[T_DIM_FND_COM_ITEM_TYPE]
            (
                   [ITEM_TYPE_CODE]                                                      --품목유형코드
                  ,[ITEM_TYPE_NAME]                                                      --품목유형명
                  ,[ETL_DT]                                                              --적재일시
            )
            SELECT DISTINCT
                   RTRIM(ISNULL(ITEM_TYPE,'z{'))                                         AS ITEM_TYPE_CODE     --품목유형코드
                  ,CASE WHEN RTRIM(ITEM_TYPE) = 'SP'  THEN N'Phantom'
                        WHEN RTRIM(ITEM_TYPE) = 'PB'  THEN N'소모품'
                        WHEN RTRIM(ITEM_TYPE) = 'FG'  THEN N'완제품자작'
                        WHEN RTRIM(ITEM_TYPE) = 'SG'  THEN N'반제품자작'
                        WHEN RTRIM(ITEM_TYPE) = 'FRT' THEN N'Product Family'
                        WHEN RTRIM(ITEM_TYPE) = 'FQ'  THEN N'완제품상품'
                        WHEN RTRIM(ITEM_TYPE) = 'FS'  THEN N'완제품사급'
                        WHEN RTRIM(ITEM_TYPE) = 'SS'  THEN N'반제품사급'
                        WHEN RTRIM(ITEM_TYPE) = 'SO'  THEN N'OSP'
                        WHEN RTRIM(ITEM_TYPE) = 'PP'  THEN N'부품구매'
                        ELSE N'데이터 없음'
                   END                                                                   AS ITEM_TYPE_NAME     --품목유형명
                  ,DATEADD(HOUR, 9 ,GETDATE())                                           AS ETL_DT
              FROM ERPSYS.ERP_MTL_SYSTEM_ITEMS_B
             UNION ALL
             SELECT 'z~'
                    ,N'데이터 오류'
                    ,DATEADD(HOUR, 9 ,GETDATE())
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_ITEM_TYPE]
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

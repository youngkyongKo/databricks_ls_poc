CREATE PROC [dbo].[SP_T_DIM_FND_COM_TASK_N_C] AS
BEGIN

    SET NOCOUNT ON

    BEGIN

        DECLARE @v_run_pgm      varchar(50)
               ,@v_st_date      datetime
               ,@v_load_cnt     decimal(18,0)
               ,@v_enum         int
               ,@v_err_mesg     varchar(4000)
               ,@v_pgm_status   varchar(1) 
               ,@v_work_result  int
               ,@v_tgt_job_area varchar(10)
               ,@v_parm_from    varchar(50) 
               ,@v_parm_to      varchar(50) 
               ,@v_parm_comm_from varchar(50) 
               ,@v_parm_comm_to   varchar(50)
               ;

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_TASK_N_C' -- procedure name 
        ;
        SET @v_st_date = DATEADD(HOUR, 9 ,GETDATE())
        ;
        SET @v_pgm_status = 'S' -- 성공여부
        ;
        SET @v_work_result = 0
        ;
        SET @v_load_cnt = 0
        ;
        SET @v_tgt_job_area = 'DIM'--DIM / FACT
        ;
        
        BEGIN TRY
         
            MERGE [dbo].[T_DIM_FND_COM_TASK]  AS TRG
            USING (
                        SELECT DISTINCT PT.TASK_ID AS TASK_ID
                             , TASK_NUMBER AS TASK_NO
                             , PT.TASK_NAME AS TASK_NAME
                             , PT.DESCRIPTION AS TASK_DESC
                             , TOP_TASK_ID AS HIGH_TASK_ID   -- 상위 TASK_ID
                             , PT.PROJECT_ID                -- PROJECT_ID
                             , PPA.SEGMENT1  AS PROJECT_NO               -- PROJECT_NO
                             , CONCAT(TRIM(PPA.SEGMENT1), TRIM(TASK_NUMBER)) AS [PROJECT_TASK_NO_KEY]
                             , PPA.LONG_NAME AS PROJECT_NAME
                             , ISNULL(PSV.SEGMENT_VALUE, 'z{') AS PRODUCT_LINE_CODE
                             , ISNULL(PSV.SEGMENT_VALUE_LOOKUP, N'데이터없음') AS PRODUCT_LINE_NAME
                             , MP.ORGANIZATION_ID  AS ORGANIZATION_ID
                             , FORMAT(PT.START_DATE, 'yyyyMMdd') AS TASK_START_DATE
                             , FORMAT(PT.COMPLETION_DATE, 'yyyyMMdd') AS TASK_COMPLETION_DATE
                             , 'Y' AS USAGE_FLAG
                             , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT   
                          FROM ERPSYS.ERP_PA_TASKS PT   
                    INNER JOIN ERPSYS.ERP_PA_PROJECTS_ALL PPA
                            ON PPA.PROJECT_ID = PT.PROJECT_ID
               LEFT OUTER JOIN ERPSYS.ERP_PA_PROJECT_CLASSES PPC
                            ON PPC.PROJECT_ID = PT.PROJECT_ID 
               LEFT OUTER JOIN ERPSYS.ERP_PA_SEGMENT_VALUE PSV
                            ON PSV.SEGMENT_VALUE_LOOKUP = PPC.CLASS_CODE
               LEFT OUTER JOIN ERPSYS.ERP_MTL_PARAMETERS MP
                            ON MP.ORGANIZATION_id = PPA.CARRYING_OUT_ORGANIZATION_id
               LEFT OUTER JOIN ERPSYS.ERP_PA_SEGM_VALUE_SETS PSVS
                            ON PSVS.SEGMENT_VALUE_LOOKUP_SET_ID = PSV.SEGMENT_VALUE_LOOKUP_SET_ID
                           AND PSVS.SEGMENT_VALUE_LOOKUP_SET_NAME = 'EPA_PRODUCTLINE' 
        
                     UNION ALL SELECT -99, 'z{', N'데이터 없음', N'데이터 없음', -99, -99, N'데이터 없음', N'데이터 없음z{', N'데이터 없음', 'z{', N'데이터 없음', -99, NULL, NULL, 'Y', DATEADD(HOUR, 9 ,GETDATE()) 
                     UNION ALL SELECT -999, 'z~', N'데이터 오류', N'데이터 오류', -999, -999, N'데이터 오류', '데이터 오류z~', N'데이터 오류', 'z~', N'데이터 오류', -999, NULL, NULL, 'Y', DATEADD(HOUR, 9 ,GETDATE()) 
        
                  ) AS SRC 
               ON (TRG.TASK_ID = SRC.TASK_ID)
             WHEN MATCHED THEN
           UPDATE SET TRG.TASK_NO                = SRC.TASK_NO
                    , TRG.TASK_NAME              = SRC.TASK_NAME
                    , TRG.TASK_DESC              = SRC.TASK_DESC
                    , TRG.HIGH_TASK_ID           = SRC.HIGH_TASK_ID
                    , TRG.PROJECT_ID             = SRC.PROJECT_ID
                    , TRG.PROJECT_NO             = SRC.PROJECT_NO
                    , TRG.PROJECT_TASK_NO_KEY    = SRC.PROJECT_TASK_NO_KEY
                    , TRG.PROJECT_NAME           = SRC.PROJECT_NAME
                    , TRG.PRODUCT_LINE_CODE      = SRC.PRODUCT_LINE_CODE
                    , TRG.PRODUCT_LINE_NAME      = SRC.PRODUCT_LINE_NAME
                    , TRG.ORGANIZATION_ID        = SRC.ORGANIZATION_ID
                    , TRG.TASK_START_DATE        = SRC.TASK_START_DATE
                    , TRG.TASK_COMPLETION_DATE   = SRC.TASK_COMPLETION_DATE
                    , TRG.USAGE_FLAG             = SRC.USAGE_FLAG
                    , TRG.ETL_DT                 = SRC.ETL_DT     
             WHEN NOT MATCHED BY TARGET THEN
           INSERT ( TASK_ID
                  , TASK_NO
                  , TASK_NAME
                  , TASK_DESC
                  , HIGH_TASK_ID
                  , PROJECT_ID
                  , PROJECT_NO
                  , PROJECT_TASK_NO_KEY
                  , PROJECT_NAME
                  , PRODUCT_LINE_CODE
                  , PRODUCT_LINE_NAME
                  , ORGANIZATION_ID
                  , TASK_START_DATE
                  , TASK_COMPLETION_DATE
                  , USAGE_FLAG
                  , ETL_DT
                  )
           VALUES ( SRC.TASK_ID
                  , SRC.TASK_NO
                  , SRC.TASK_NAME
                  , SRC.TASK_DESC
                  , SRC.HIGH_TASK_ID
                  , SRC.PROJECT_ID
                  , SRC.PROJECT_NO
                  , SRC.PROJECT_TASK_NO_KEY
                  , SRC.PROJECT_NAME
                  , SRC.PRODUCT_LINE_CODE
                  , SRC.PRODUCT_LINE_NAME
                  , SRC.ORGANIZATION_ID
                  , SRC.TASK_START_DATE
                  , SRC.TASK_COMPLETION_DATE
                  , SRC.USAGE_FLAG
                  , SRC.ETL_DT
                  ) 
                  ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_TASK]
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
           
        --SELECT @v_load_cnt, @v_pgm_status, @v_err_mesg
    END

END

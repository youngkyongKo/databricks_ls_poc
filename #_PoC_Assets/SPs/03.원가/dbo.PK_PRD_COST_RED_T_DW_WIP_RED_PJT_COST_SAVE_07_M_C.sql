CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_WIP_RED_PJT_COST_SAVE_07_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
BEGIN

    SET NOCOUNT ON

    BEGIN

        DECLARE @v_run_pgm      varchar(100)
               ,@v_st_date      datetime
               ,@v_load_cnt     decimal(18,0)
               ,@v_enum         int
               ,@v_err_mesg     varchar(4000)
               ,@v_pgm_status   varchar(1) 
               ,@v_work_result  int
               ,@v_tgt_job_area varchar(10)
               ,@v_parm_from    varchar(50) = @F_YYYYMM
               ,@v_parm_to      varchar(50) = @T_YYYYMM
               ,@v_parm_comm_from varchar(50) 
               ,@v_parm_comm_to   varchar(50)
               ;

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_WIP_RED_PJT_COST_SAVE_07_M_C' -- procedure name 
        ;
        SET @v_st_date = DATEADD(HOUR, 9 ,GETDATE())
        ;
        SET @v_pgm_status = 'S' -- 성공여부
        ;
        SET @v_work_result = 0
        ;
        SET @v_load_cnt = 0
        ;
        SET @v_tgt_job_area = 'FACT'--DIM / FACT
        ;
        
        BEGIN TRY
         
                DELETE FROM [dbo].[T_DW_WIP_RED_PJT_COST_SAVE] 
                 WHERE BASE_YYYYMM  =  @v_parm_to     --파라미터
                 ; 
 
                INSERT INTO [dbo].[T_DW_WIP_RED_PJT_COST_SAVE] 
                (      [BASE_YYYYMM]
                     , [ORG_ID]
                     , [ORG_CODE]
                     , [PROJECT_ID]
                     , [TASK_ID]
                     , [PRODUCT_LINE_CODE]
                     , [CLASS_CODE]
                     , [PROJECT_TYPE]
                     , [PROJECT_NUMBER]
                     , [PROJECT_NAME]
                     , [TASK_NUMBER]
                     , [TASK_NAME]
                     , [LAST_AR_NUMBER]
                     , [LAST_FC_NUMBER]
                     , [AR_AMOUNT]
                     , [FC_AMOUNT]
                     , [FC_AMOUNT_MTL]
                     , [PM_NAME]
                     , [DEPT_CODE]
                     , [DEPT_NAME]
                     , [REVENUE_AMT]
                     , [REVENUE_BEFORE_TOT_AMT]
                     , [MATERIAL_AMT]
                     , [COGS_AMT]
                     , [REVE_TRANS_FC_AMT]
                     , [REVE_TRANS_FC_AMT_MTL]
                     , [PEGGING_AMT]
                     , [REVE_TRANS_PEGGING_AMT]
                     , [PEGGING_BEFORE_TOT_AMT]
                     , [COMMON_AMT]
                     , [SAVE_AMT]
                     , [TOT_SAVE_AMT]
                     , [ENG_SAVE_AMT]
                     , [ETL_DT]
                )
                SELECT YYYYMM                           AS BASE_YYYYMM
                     , ORGANIZATION_ID                  AS ORG_ID
                     , O.ORG_CODE
                     , PROJECT_ID
                     , TASK_ID
                     , SPG_CD                           AS PRODUCT_LINE_CODE
                     , CLASS_CODE
                     , PROJECT_TYPE
                     , PROJECT_NUMBER
                     , PROJECT_NAME
                     , TASK_NUMBER
                     , TASK_NAME
                     , LAST_AR_NUMBER
                     , LAST_FC_NUMBER
                     , AR_AMOUNT
                     , FC_AMOUNT
                     , FC_AMOUNT_MTL
                     , PM_NAME
                     , DEPT_CODE
                     , DEPT_NAME
                     , REVENUE_AMT
                     , REVENUE_BEFORE_TOT_AMT
                     , MATERIAL_AMT
                     , COGS_AMT
                     , REVE_TRANS_FC_AMT
                     , REVE_TRANS_FC_AMT_MTL
                     , PEGGING_AMT
                     , REVE_TRANS_PEGGING_AMT
                     , PEGGING_BEFORE_TOT_AMT
                     , COMMON_AMT
                     , SAVE_AMT
                     , TOT_SAVE_AMT
                     , ENG_SAVE_AMT
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_PJT_MTL_COST_SAVE T
            INNER JOIN T_DIM_FND_COM_ORG O
                    ON T.ORGANIZATION_ID = O.ORG_ID
                 WHERE T.ORG_ID = 89
                   AND YYYYMM = @v_parm_to      --파라미터
                   ; 
                   
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_WIP_RED_PJT_COST_SAVE]
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

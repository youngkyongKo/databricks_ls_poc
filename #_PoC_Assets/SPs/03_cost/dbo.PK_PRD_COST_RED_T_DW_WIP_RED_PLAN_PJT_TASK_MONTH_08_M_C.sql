CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_WIP_RED_PLAN_PJT_TASK_MONTH_08_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_WIP_RED_PLAN_PJT_TASK_MONTH_08_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_DW_WIP_RED_PLAN_PJT_TASK_MONTH] 
                 WHERE YYYYMM  =  @v_parm_to     --파라미터
                 ; 
                INSERT INTO [dbo].[T_DW_WIP_RED_PLAN_PJT_TASK_MONTH]  
                (      [YYYYMM]
                     , [ORGANIZATION_ID]
                     , [PROJECT_NO]
                     , [PROJECT_NAME]
                     , [TASK_NO]
                     , [TASK_NAME]
                     , [SPG_CODE]
                     , [CLASS_CODE]
                     , [PROJECT_TYPE]
                     , [CURRENCY]
                     , [THIS_COST_SAVE]
                     , [AR_AMOUNT]
                     , [AR_AMOUNT_ORI]
                     , [TASK_PJT_FC_COST]
                     , [TASK_MTL_COST]
                     , [REVENUE_AMT]
                     , [REVENUE_AMT_ORI]
                     , [MATERIAL_AMT]
                     , [COST_SAVE]
                     , [PRE_REVENUE_AMT]
                     , [PRE_REVENUE_AMT_ORI]
                     , [PRE_MATERIAL_AMT]
                     , [PRE_COST_SAVE]
                     , [THIS_PJT_EAC]
                     , [THIS_TASK_EAC]
                     , [PRE_PJT_EAC]
                     , [PRE_TASK_EAC]
                     , [THIS_REVENUE_AMT]
                     , [THIS_REVENUE_AMT_ORI]
                     , [THIS_MATERIAL_AMT]
                     , [SUM_TASK_COST]
                     , [PRE_SUM_TASK_COST]
                     , [THIS_TASK_COST]
                     , [PJT_FC_COST]
                     , [PJT_MTL_COST]
                     , [PO_COST_SAVE]
                     , [DEPT_CODE]
                     , [DEPT_NAME]
                     , [COMPLETE_FLAG]
                     , [ETL_DT]
                ) 
                SELECT YYYYMM
                     , ORGANIZATION_ID
                     , PROJECT_NO
                     , PROJECT_NAME
                     , TASK_NO
                     , TASK_NAME
                     , SPG_CODE
                     , CLASS_CODE
                     , PROJECT_TYPE
                     , CURRENCY
                     , THIS_COST_SAVE
                     , AR_AMOUNT
                     , AR_AMOUNT_ORI
                     , TASK_PJT_FC_COST
                     , TASK_MTL_COST
                     , REVENUE_AMT
                     , REVENUE_AMT_ORI
                     , MATERIAL_AMT
                     , COST_SAVE
                     , PRE_REVENUE_AMT
                     , PRE_REVENUE_AMT_ORI
                     , PRE_MATERIAL_AMT
                     , PRE_COST_SAVE
                     , THIS_PJT_EAC
                     , THIS_TASK_EAC
                     , PRE_PJT_EAC
                     , PRE_TASK_EAC
                     , THIS_REVENUE_AMT
                     , THIS_REVENUE_AMT_ORI
                     , THIS_MATERIAL_AMT
                     , SUM_TASK_COST
                     , PRE_SUM_TASK_COST
                     , THIS_TASK_COST
                     , PJT_FC_COST
                     , PJT_MTL_COST
                     , PO_COST_SAVE
                     , DEPT_CODE
                     , DEPT_NAME
                     , COMPLETE_FLAG
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM [ERPSYS].[ERP_EBOM_PLAN_PJT_TSK_M]
                 WHERE YYYYMM = @v_parm_to     --파라미터
                 ; 
  
                   
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_WIP_RED_PLAN_PJT_TASK_MONTH]
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

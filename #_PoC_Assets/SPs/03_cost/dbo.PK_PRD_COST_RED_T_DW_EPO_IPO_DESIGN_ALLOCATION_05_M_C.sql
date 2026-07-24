CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_DESIGN_ALLOCATION_05_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_DESIGN_ALLOCATION_05_M_C' -- procedure name 
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

                DELETE FROM [dbo].[T_DW_EPO_IPO_DESIGN_ALLOCATION] 
                 WHERE BASE_YYYY = LEFT(@v_parm_to, 4)    -- 파라미터
                 ;
 
                INSERT INTO [dbo].[T_DW_EPO_IPO_DESIGN_ALLOCATION]
                (
                       [BASE_YYYY]
                     , [ORG_CODE]
                     , [DEPARTMENT_CODE]
                     , [ITEM_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [DEPARTMENT_NAME]
                     , [ITEM_NAME]
                     , [PRODUCT_LINE_NAME]
                     , [YYYYMM]
                     , [ALLOCATION_RATE]
                     , [ETL_DT]
                )
                SELECT DISTINCT
                       A.YYYY
                     , B.ORG_CODE
                     , A.DEPT_CODE
                     , B.ITEM_CODE
                     , B.PRODUCT_LINE_CODE
                     , D.DEPARTMENT_NAME
                     , B.ITEM_NAME
                     , B.PRODUCT_LINE_NAME
                     , SUBSTRING(A.ATTRIBUTE1, 1, 6) AS YYYYMM
                     , A.ALLC_RATE / 100  AS ALLC_RATE
                     , DATEADD(HOUR, 9 ,GETDATE())  AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_DEPT_ALLOC_RATE A
            INNER JOIN T_DIM_FND_COM_ITEM B
                    ON A.ORGANIZATION_ID = B.ORG_ID
                   AND A.ITEM_ID = B.ITEM_ID
                  JOIN T_DIM_FND_COM_ORG  C
                    ON A.ORGANIZATION_ID = C.ORG_ID
                   AND C.OU_ID = 89
                  JOIN T_DIM_FND_COM_ORGANIZATION D
                    ON A.DEPT_CODE = D.DEPARTMENT_CODE
                 WHERE A.YYYY = SUBSTRING(@v_parm_to, 1, 4)     -- 파라미터 
                   AND NOT EXISTS (
                          SELECT 'X'
                            FROM T_DIM_FND_COM_ITEM MC
                           WHERE MC.ORG_ID = B.ORG_ID
                             AND MC.ITEM_CODE = CONCAT(B.ITEM_CODE, 'C')
                       )  
                       ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_DESIGN_ALLOCATION]
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

CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_OUT_IN_RED_RSLT_12_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_OUT_IN_RED_RSLT_12_M_C' -- procedure name 
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

                DELETE FROM [dbo].[T_DW_EPO_IPO_OUT_IN_RED_RSLT]
                WHERE YYYYMM =  @v_parm_to   --파라미터
                ;
                
                INSERT INTO [dbo].[T_DW_EPO_IPO_OUT_IN_RED_RSLT]
                (      [YYYYMM]
                     , [ORG_ID]
                     , [DEPARTMENT_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [ITEM_ID]
                     , [IN_ITEM_CODE]
                     , [MFG_TYPE]
                     , [QTY]
                     , [BASE_UNIT_PRICE]
                     , [RECEIVING_UNIT_PRICE]
                     , [UNIT_PRICE_VARIANCE]
                     , [MTL_COST_RED_AMOUNT]
                     , [DISTRIBUTION_RATE]
                     , [ETL_DT]
                )
                SELECT A.YYYYMM
                     , A.ORGANIZATION_ID                       AS ORG_ID               --ORG_ID
                     , CASE WHEN B.ALLC_RATE IS NOT NULL THEN
                                 B.DEPT_CODE
                            WHEN B.ALLC_RATE IS NULL AND C.LOOKUP_CODE IS NOT NULL THEN
                                 C.DESCRIPTION
                       END                                     AS DEPARTMENT_CODE      --부서코드
                     , A.SPG_CD                                AS PRODUCT_LINE_CODE    --제품류코드
                     , A.ASSEMBLY_ITEM_ID                      AS ITEM_ID              --ITEM_ID
                     , A.ATTRIBUTE6                            AS IN_ITEM_CODE         --자작품목코드
                     , N'자작화'                                AS MFG_TYPE             --생산구분
                     , CAST(A.ATTRIBUTE4 AS FLOAT)                 AS QTY                  --수량
                     , CAST(A.ATTRIBUTE1 AS FLOAT)                 AS BASE_UNIT_PRICE      --기준단가 NUMBER(20,4)
                     , CAST(A.ATTRIBUTE5 AS FLOAT)                 AS RECEIVING_UNIT_PRICE --입고단가 NUMBER(20,4)
                     , CAST(A.ATTRIBUTE1 AS FLOAT) - CAST(A.ATTRIBUTE5 AS FLOAT) AS UNIT_PRICE_VARIANCE  --단가차   NUMBER(16,4)
                     , CASE WHEN B.ALLC_RATE IS NOT NULL THEN
                                 (CAST(A.ATTRIBUTE1 AS FLOAT) - CAST(A.ATTRIBUTE5 AS FLOAT)) * CAST(A.ATTRIBUTE4 AS FLOAT) * (B.ALLC_RATE / 100)
                            WHEN B.ALLC_RATE IS NULL AND C.LOOKUP_CODE IS NOT NULL THEN
                                 (CAST(A.ATTRIBUTE1 AS FLOAT) - CAST(A.ATTRIBUTE5 AS FLOAT)) * CAST(A.ATTRIBUTE4 AS FLOAT)
                       END                                     AS MTL_COST_RED_AMOUNT  --절감금액 NUMBER(20,4)
                     , CASE WHEN B.ALLC_RATE IS NOT NULL THEN
                                 B.ALLC_RATE
                            WHEN B.ALLC_RATE IS NULL AND C.LOOKUP_CODE IS NOT NULL THEN
                                 100
                       END                                     AS DISTRIBUTION_RATE    --배분율   NUMBER(16,4)
                     , DATEADD(HOUR, 9 ,GETDATE())              AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_BOM_CHANGE_MONTHLY         A 
       LEFT OUTER JOIN (
                          SELECT DISTINCT
                                 ORGANIZATION_ID
                               , DEPT_CODE
                               , ITEM_ID
                               , ALLC_RATE
                            FROM ERPSYS.ERP_EBOM_DEPT_ALLOC_RATE
                           WHERE YYYY = SUBSTRING(@v_parm_to,1,4)
                       )  B
                    ON A.ORGANIZATION_ID = B.ORGANIZATION_ID
                   AND A.ASSEMBLY_ITEM_ID = B.ITEM_ID
                  LEFT OUTER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES    C  --배분율이 없을때 제품류에 등록된 설계부서에 100%
                    ON A.SPG_CD = C.LOOKUP_CODE
                   AND C.LOOKUP_TYPE = 'EBOM_PLAN_DEFAULT_ENG_DEPT'
                   AND C.ENABLED_FLAG = 'Y'
                 WHERE A.YYYYMM =  @v_parm_to   --파라미터
                   AND A.CHANGE_TYPE = 'BUY_MAKE_CHANGE'
                   AND A.ORGANIZATION_ID NOT IN ( 256 , 321 )
                   ;
                      
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_OUT_IN_RED_RSLT]
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
         --SELECT @v_pgm_status, @v_load_cnt
        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

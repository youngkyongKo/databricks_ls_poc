CREATE PROC [dbo].[SP_T_DW_FIN_CCT_TEAM_PL_RESULT_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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
               ,@v_parm_from    varchar(50) = @F_YYYYMM
               ,@v_parm_to      varchar(50) = @T_YYYYMM
               ,@v_parm_comm_from varchar(50) 
               ,@v_parm_comm_to   varchar(50)
               ;

        SET @v_run_pgm = 'SP_T_DW_FIN_CCT_TEAM_PL_RESULT_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_DW_FIN_CCT_TEAM_PL_RESULT] 
                 WHERE YYYYMM BETWEEN @v_parm_from AND @v_parm_to
                 ; 

                INSERT INTO [dbo].[T_DW_FIN_CCT_TEAM_PL_RESULT]
                (      [YYYYMM]
                     , [ACCUMULATION_FLAG]
                     , [ORG_CODE]
                     , [DEPARTMENT_CODE]
                     , [MARKET_TYPE_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [SALES_RECOGNITION_BASE_NAME]
                     , [ITEM_CODE]
                     , [UNIT_CODE]
                     , [CURRENCY_CODE]
                     , [QUANTITY]
                     , [SALES_AMOUNT]
                     , [OCCUR_CURR_AMOUNT]
                     , [USD_CONVERSION_AMOUNT]
                     , [TOTAL_COST]
                     , [MATERIAL_COST]
                     , [MATERIAL_OH_COST]
                     , [RESOURCE_COST]
                     , [OVERHEAD_COST]
                     , [OSP_COST]
                     , [VARIANCE_COST]
                     , [OR_LOSS_COST]
                     , [COMMISSION_PL_AMT]
                     , [FUTURES_PL_AMT]
                     , [CUSTOM_REFUND_AMT]
                     , [ETC_WRITE_DOWN]
                     , [ST_PLAN_AMOUNT]
                     , [ST_RESULT_AMOUNT]
                     , [PROD_WRITE_DOWN]
                     , [ETL_DT]
                )
                --당월 =============================================================================================
                SELECT REPLACE(B.PERIOD, '-', '')               AS YYYYMM                           --년월
                     , 'N'                                      AS ACCUMULATION_FLAG                --누계여부
                     , C.ORG_CODE                               AS ORG_CODE                         --ORG코드
                     , ISNULL(B.DEPT_CODE, 'z{')                AS DEPARTMENT_CODE                  --부서코드
                     , B.MARKET                                 AS MARKET_TYPE_CODE                 --시장구분코드
                     , D.PRODUCT_LINE_CODE                      AS PRODUCT_LINE_CODE                --제품류코드     
                     , B.TRAN_TYPE                              AS SALES_RECOGNITION_BASE_NAME      --매출인식기준명
                     , B.ITEM                                   AS ITEM_CODE                        --품목코드
                     , B.UOM                                    AS UNIT_CODE                        --단위코드
                     , B.CURRENCY                               AS CURRENCY_CODE                    --통화코드
                     , SUM(ISNULL(B.QUANTITY,0))                AS QUANTITY                         --수량
                     , SUM(ISNULL(B.AMOUNT,0))                  AS SALES_AMOUNT                     --매출금액
                     , SUM(ISNULL(B.ENTERED_AMT,0))             AS OCCUR_CURR_AMOUNT                --발생통화금액
                     , SUM(ISNULL(B.USD_AMT,0))                 AS USD_CONVERSION_AMOUNT            --USD환산금액
                     , SUM(ISNULL(B.COST_SUM,0))                AS TOTAL_COST                       --합계원가
                     , SUM(ISNULL(B.MATERIAL,0))                AS MATERIAL_COST                    --재료비
                     , SUM(ISNULL(B.MATERIAL_OVERHEAD,0))       AS MATERIAL_OH_COST                 --재료간접비
                     , SUM(ISNULL(B.RESOURCE_COST,0))           AS RESOURCE_COST                    --자원원가
                     , SUM(ISNULL(B.OVERHEAD,0))                AS OVERHEAD_COST                    --간접비
                     , SUM(ISNULL(B.OSP,0))                     AS OSP_COST                         --OSP원가
                     , SUM(ISNULL(B.VARIANCE,0))                AS VARIANCE_COST                    --VARIANCE원가
                     , SUM(ISNULL(B.OR_LOSS,0))                 AS OR_LOSS_COST                     --OR_LOSS원가
                     , SUM(ISNULL(B.SS_COGS,0))                 AS COMMISSION_PL_COST               --유상사급손익금액
                     , SUM(ISNULL(B.FUTURE_COGS,0))             AS FUTURES_PL_COST                  --선물거래손익금액
                     , SUM(ISNULL(B.CUSTOM_REFUND,0))           AS CUSTOM_REFUND_COST               --관세환급금액
                     , SUM(ISNULL(B.COGS_ADJUSTMENT,0))         AS ETC_WRITE_DOWN                   --기타평가감
                     , SUM(ISNULL(B.PLN00_OP_AMT,0))            AS ST_PLAN_AMOUNT                   --ST계획금액
                     , SUM(ISNULL(B.PLNMM_OP_AMT,0))            AS ST_RESULT_AMOUNT                 --ST실적금액
                     , SUM(ISNULL(B.INV_DEVALUAION,0))          AS PROD_WRITE_DOWN                  --제품평가감
                     , DATEADD(HOUR, 9 ,GETDATE())              AS ETL_DT
                  FROM ERPSYS.ERP_ECST_BI_MFG_COGS_DTL B     --ERP 실적테이블
            INNER JOIN T_DIM_FND_COM_ORG C
                    ON B.ORGANIZATION_ID = C.ORG_ID
                   AND C.ORG_CODE IN ('M01', 'M03', 'M09', 'M10') -- 자동화분리운영ORG추가 20201207
            INNER JOIN T_DIM_FND_COM_ITEM D
                    ON B.ITEM = D.ITEM_CODE
                   AND C.ORG_CODE = D.ORG_CODE
                 WHERE REPLACE(B.PERIOD, '-', '') BETWEEN @v_parm_from AND @v_parm_to
                   AND B.MARKET IN ('Domestic', 'Export', 'SVC')
              GROUP BY REPLACE(B.PERIOD, '-', '')
                     , C.ORG_CODE
                     , ISNULL(B.DEPT_CODE, 'z{')
                     , B.MARKET
                     , D.PRODUCT_LINE_CODE
                     , B.TRAN_TYPE
                     , B.ITEM
                     , B.UOM
                     , B.CURRENCY
                --당월 =============================================================================================
                 UNION ALL  
                --누계 =============================================================================================
                SELECT Z.YYYYMM                                 AS YYYYMM                           --년월
                     , 'Y'                                      AS ACCUMULATION_FLAG                --누계여부
                     , C.ORG_CODE                               AS ORG_CODE                         --ORG코드
                     , ISNULL(B.DEPT_CODE, 'z{')                AS DEPARTMENT_CODE                  --부서코드
                     , B.MARKET                                 AS MARKET_TYPE_CODE                 --시장구분코드
                     , D.PRODUCT_LINE_CODE                      AS PRODUCT_LINE_CODE                --제품류코드     
                     , B.TRAN_TYPE                              AS SALES_RECOGNITION_BASE_NAME      --매출인식기준명
                     , B.ITEM                                   AS ITEM_CODE                        --품목코드
                     , B.UOM                                    AS UNIT_CODE                        --단위코드
                     , B.CURRENCY                               AS CURRENCY_CODE                    --통화코드
                     , SUM(ISNULL(B.QUANTITY,0))                AS QUANTITY                         --수량
                     , SUM(ISNULL(B.AMOUNT,0))                  AS SALES_AMOUNT                     --매출금액
                     , SUM(ISNULL(B.ENTERED_AMT,0))             AS OCCUR_CURR_AMOUNT                --발생통화금액
                     , SUM(ISNULL(B.USD_AMT,0))                 AS USD_CONVERSION_AMOUNT            --USD환산금액
                     , SUM(ISNULL(B.COST_SUM,0))                AS TOTAL_COST                       --합계원가
                     , SUM(ISNULL(B.MATERIAL,0))                AS MATERIAL_COST                    --재료비
                     , SUM(ISNULL(B.MATERIAL_OVERHEAD,0))       AS MATERIAL_OH_COST                 --재료간접비
                     , SUM(ISNULL(B.RESOURCE_COST,0))           AS RESOURCE_COST                    --자원원가
                     , SUM(ISNULL(B.OVERHEAD,0))                AS OVERHEAD_COST                    --간접비
                     , SUM(ISNULL(B.OSP,0))                     AS OSP_COST                         --OSP원가
                     , SUM(ISNULL(B.VARIANCE,0))                AS VARIANCE_COST                    --VARIANCE원가
                     , SUM(ISNULL(B.OR_LOSS,0))                 AS OR_LOSS_COST                     --OR_LOSS원가
                     , SUM(ISNULL(B.SS_COGS,0))                 AS COMMISSION_PL_COST               --유상사급손익금액
                     , SUM(ISNULL(B.FUTURE_COGS,0))             AS FUTURES_PL_COST                  --선물거래손익금액
                     , SUM(ISNULL(B.CUSTOM_REFUND,0))           AS CUSTOM_REFUND_COST               --관세환급금액
                     , SUM(ISNULL(B.COGS_ADJUSTMENT,0))         AS ETC_WRITE_DOWN                   --기타평가감
                     , SUM(ISNULL(B.PLN00_OP_AMT,0))            AS ST_PLAN_AMOUNT                   --ST계획금액
                     , SUM(ISNULL(B.PLNMM_OP_AMT,0))            AS ST_RESULT_AMOUNT                 --ST실적금액
                     , SUM(ISNULL(B.INV_DEVALUAION,0))          AS PROD_WRITE_DOWN                  --제품평가감     
                     , DATEADD(HOUR, 9 ,GETDATE())              AS ETL_DT
                  FROM ERPSYS.ERP_ECST_BI_MFG_COGS_DTL B     --ERP 실적테이블
            INNER JOIN T_DIM_FND_COM_ORG C
                    ON B.ORGANIZATION_ID = C.ORG_ID
            INNER JOIN T_DIM_FND_COM_ITEM D
                    ON C.ORG_CODE = D.ORG_CODE
                   AND B.ITEM = D.ITEM_CODE
            INNER JOIN T_DIM_FND_COM_MONTH Z  
                    ON REPLACE(B.PERIOD, '-', '') BETWEEN CONCAT(Z.YYYY, '01') AND Z.YYYYMM
                 WHERE Z.YYYYMM BETWEEN @v_parm_from AND @v_parm_to
                   AND B.MARKET IN ('Domestic', 'Export', 'SVC')
                   AND C.ORG_CODE IN ('M01', 'M03','M09','M10') -- 자동화분리운영ORG추가 20201207
              GROUP BY Z.YYYYMM
                     , C.ORG_CODE
                     , ISNULL(B.DEPT_CODE, 'z{')
                     , B.MARKET
                     , D.PRODUCT_LINE_CODE
                     , B.TRAN_TYPE
                     , B.ITEM
                     , B.UOM
                     , B.CURRENCY
                --누계 ============================================================================================= 
                 ; 
  
                   
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_FIN_CCT_TEAM_PL_RESULT]
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

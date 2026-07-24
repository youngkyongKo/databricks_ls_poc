CREATE PROC [dbo].[SP_T_DW_FIN_CCT_MFG_COST_DETAIL_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS

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
               ,@v_parm_from        varchar(50) = @F_YYYYMM
               ,@v_parm_to          varchar(50) = @T_YYYYMM
               ,@v_parm_comm_from   varchar(50)
               ,@v_parm_comm_to     varchar(50)
        ;

        SET @v_run_pgm = 'SP_T_DW_FIN_CCT_MFG_COST_DETAIL_M_C'
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

            DELETE FROM [dbo].[T_DW_FIN_CCT_MFG_COST_DETAIL]
             WHERE RECEIVING_YYYYMMDD BETWEEN @v_parm_from + '01' AND FORMAT(EOMONTH(@v_parm_to + '01'),'yyyyMMdd')
            ;
            
            INSERT INTO [dbo].[T_DW_FIN_CCT_MFG_COST_DETAIL]
            (
                   [TRANSACTION_ID]                                          --트랜잭션ID
                  ,[INSIDE_OUTSIDE_TYPE_CODE]                                --자작외작구분코드
                  ,[WORK_ORDER_NO]                                           --작업지시번호
                  ,[RECEIVING_YYYYMMDD]                                      --입고년월일
                  ,[ITEM_ID]                                                 --품목ID
                  ,[ORG_ID]                                                  --ORG_ID
                  ,[PRODUCTION_QTY]                                          --생산수량
                  ,[PRODUCTION_AMOUNT]                                       --생산금액
                  ,[MFG_COST_IMP_MTL_COST]                                   --제조원가도입재료비
                  ,[MFG_COST_DOM_MTL_COST]                                   --제조원가국내재료비
                  ,[MANUFACTURING_COST_LABOR_COST]                           --제조원가노무비
                  ,[MANUFACTURING_COST_EXPENSE]                              --제조원가경비
                  ,[PRODUCTION_DEPARTMENT_CODE]                              --생산부서코드
                  ,[ACCT_BIZ_PLACE_CODE]                                     --회계사업장코드
                  ,[ETL_DT]                                                  --적재일시
            )
            SELECT DT.TRANSACTION_ID                                                                       AS TRANSACTION_ID
                  ,CASE WHEN DT.MAKE_OR_BUY = 1 THEN 'MAKE'
                        ELSE 'BUY'
                   END                                                                                     AS INSIDE_OUTSIDE_TYPE_CODE
                  ,DT.SOURCE_NUMBER                                                                        AS WORK_ORDER_NO
                  ,FORMAT(DT.TRANSACTION_DATE,'yyyyMMdd')                                                  AS RECEIVING_YYYYMMDD
                  ,DT.INVENTORY_ITEM_ID                                                                    AS ITEM_ID
                  ,DT.ORGANIZATION_ID                                                                      AS ORG_ID
                  ,DT.MFG_QTY                                                                              AS PRODUCTION_QTY
                  ,DT.MFG_AMOUNT                                                                           AS PRODUCTION_AMOUNT
                  ,DT.M_IMPORT_COST                                                                        AS MFG_COST_IMP_MTL_COST
                  ,DT.M_DOMESTIC_COST                                                                      AS MFG_COST_DOM_MTL_COST
                  ,DT.P_LABOR_COST                                                                         AS MANUFACTURING_COST_LABOR_COST
                  ,DT.P_EXPENSE_COST                                                                       AS MANUFACTURING_COST_EXPENSE
                  ,CASE WHEN DT.DEPT_CODE IS NULL THEN 'z{'
                        WHEN ORG.DEPARTMENT_CODE IS NULL THEN 'z~'
                        ELSE ORG.DEPARTMENT_CODE
                   END                                                                                     AS PRODUCTION_DEPARTMENT_CODE
                  ,DT.LOCATION_CODE                                                                        AS ACCT_BIZ_PLACE_CODE
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                             AS ETL_DT                       --적재일시
              FROM ERPSYS.ERP_ECST_BI_MFG_COST_DTL DT
              LEFT OUTER
              JOIN T_DIM_FND_COM_ORGANIZATION ORG
                ON DT.DEPT_CODE = ORG.DEPARTMENT_CODE
              LEFT OUTER
              JOIN T_DIM_FND_COM_ORG C
                ON DT.ORGANIZATION_ID = C.ORG_ID
             WHERE DT.TRANSACTION_DATE >= CAST('201101' + '01' AS DATE)
               AND DT.TRANSACTION_DATE >= CAST(@v_parm_from + '01'  AS DATE)
             --QQQ  AND DT.TRANSACTION_DATE < ADD_MONTHS(TO_DATE(@v_parm_to,'YYYYMM'),1)  -- CDC
               AND DT.TRANSACTION_DATE < DATEADD(MM,1,@v_parm_to+ '01')
               AND C.OU_ID = 89
             UNION ALL
             /* 2010년 Data Conversion */
            SELECT CAST(CONCAT(CDT.YYYYMM,ROW_NUMBER() OVER(ORDER BY (SELECT 1))) AS BIGINT)                 AS TRANSACTION_ID
                  ,CASE WHEN CDT.MFG_TYPE = '0' THEN 'MAKE'
                        ELSE 'BUY'
                   END                                                                                       AS INSIDE_OUTSIDE_TYPE_CODE
                  ,NULL                                                                                      AS WORK_ORDER_NO
                  ,CDT.YYYYMM+'01'                                                                           AS RECEIVING_YYYYMMDD
                  ,ISNULL(ITM.ITEM_ID,-99)                                                                   AS ITEM_ID
                  ,ISNULL(ITM.ORG_ID,-99)                                                                    AS ORG_ID
                  ,CDT.PRODUCTION_QTY                                                                        AS PRODUCTION_QTY
                  ,CDT.PRODUCTION_AMT                                                                        AS PRODUCTION_AMOUNT
                  ,CDT.INTRODUCTION_MTR_AMT                                                                  AS MFG_COST_IMP_MTL_COST
                  ,CDT.DOMESTIC_MTL_COST                                                                     AS MFG_COST_DOM_MTL_COST
                  ,CDT.PRODUCTION_LABOR_COST                                                                 AS MANUFACTURING_COST_LABOR_COST
                  ,CDT.PRODUCTION_EXP_COST                                                                   AS MANUFACTURING_COST_EXPENSE
                  ,NULL                                                                                      AS PRODUCTION_DEPARTMENT_CODE
                  ,ORG.ACCT_BIZ_PLACE_CODE                                                                   AS ACCT_BIZ_PLACE_CODE
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                               AS ETL_DT                       --적재일시
              --QQQ FROM OD_ENF_TPE_16M CDT
              FROM EBIZ.RP_SYSM_MFG_COST CDT          --ENF_TPE_16M
              LEFT OUTER
              JOIN T_DIM_FND_COM_ITEM ITM
                ON CDT.ORG_CODE = ITM.ORG_CODE
               AND CDT.ITEM_CODE = ITM.ITEM_CODE
              LEFT OUTER
              JOIN T_DIM_FND_COM_ORG ORG
                ON ITM.ORG_CODE = ORG.ORG_CODE
             WHERE ORG.DIVISION_CODE<> 'z{'
               AND CDT.MFG_TYPE IN ( '0','1' )
               AND CDT.YYYYMM BETWEEN '201001' AND '201012'
               AND CDT.YYYYMM BETWEEN @v_parm_from AND @v_parm_to
               AND ITM.PRODUCT_LINE_CODE NOT IN ( '700', '750', '770', '799' )
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_FIN_CCT_MFG_COST_DETAIL]
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

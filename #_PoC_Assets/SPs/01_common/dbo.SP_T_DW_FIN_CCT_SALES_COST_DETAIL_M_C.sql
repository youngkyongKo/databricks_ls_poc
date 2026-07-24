CREATE PROC [dbo].[SP_T_DW_FIN_CCT_SALES_COST_DETAIL_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'SP_T_DW_FIN_CCT_SALES_COST_DETAIL_M_C' -- procedure name 
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


            DELETE FROM [dbo].[T_DW_FIN_CCT_SALES_COST_DETAIL] 
             WHERE SHIP_APPROVAL_YYYYMMDD BETWEEN CONCAT(@v_parm_from, '01') AND FORMAT(EOMONTH(CONCAT(@v_parm_to, '01')),'yyyyMMdd')
             ;
             
            ;WITH T_MARKET AS (
                SELECT EPDM.DEPT_CODE
                     , CASE WHEN EPDM.PRJ_MARKET = 'CHINA' THEN '3'
                            WHEN EPDM.PRJ_MARKET = 'EXPORT' THEN '2'
                            ELSE '1' END AS MARKET_TYPE
                     , EPDM.PRJ_MARKET
                     , FLV.TAG
                  FROM ERPSYS.ERP_EOE_PJT_DEPT_MARKET EPDM
            INNER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES FLV
                    ON FLV.LOOKUP_CODE   = EPDM.PRJ_MARKET
                 WHERE FLV.LOOKUP_TYPE   = 'EOE_PJT_MARKET'
                   AND FLV.ENABLED_FLAG  = 'Y'
            ),T_CUST AS (
                SELECT AA.ERP_CUSTOMER_ACCOUNT_ID
                     , AA.CUSTOMER_CODE
                     , AA.COUNTRY_CODE
                  FROM T_DIM_FND_COM_CUSTOMER_MASTER AA
             UNION
                SELECT MAX(BB.ERP_CUSTOMER_ACCOUNT_ID) AS ERP_CUSTOMER_ACCOUNT_ID
                     , BB.CORPORATION_ACCOUNTING_CODE AS CUSTOMER_CODE
                     , BB.COUNTRY_CODE
                  FROM T_DIM_FND_COM_CUSTOMER_MASTER BB
              GROUP BY BB.CORPORATION_ACCOUNTING_CODE, BB.COUNTRY_CODE
            )
            
            
                INSERT INTO [dbo].[T_DW_FIN_CCT_SALES_COST_DETAIL]
                (         [ORDER_NO]
                        , [ORDER_LINE_NO]
                        , [TRANSACTION_ID]
                        , [YYYYMM]
                        , [PRODUCT_LINE_CODE]
                        , [SALES_OCCUR_TYPE_CODE]
                        , [SHIP_APPROVAL_YYYYMMDD]
                        , [MARKET_TYPE_CODE]
                        , [ITEM_ID]
                        , [ORG_ID]
                        , [ITEM_CODE]
                        , [ORG_CODE]
                        , [ORG_ITEM_ID_KEY]
                        , [SALES_QTY]
                        , [SHIP_UNIT_PRICE]
                        , [BUSINESS_SELLING_PRICE_AMOUNT]
                        , [STANDARD_SELLING_PRICE_AMOUNT]
                        , [RESULT_SELLING_PRICEAMOUNT]
                        , [OCCUR_CURRENCY_CODE]
                        , [OCCUR_CURRENCY_SALES_AMOUNT]
                        , [BASIC_CURRENCY_SALES_AMOUNT]
                        , [USD_CONVERSION_SALES_AMOUNT]
            
                        --, [BF_YEAR_RSLT_SELL_PRICE]
                        --, [CURR_YEAR_RSLT_SELL_PRICE]
                        --, [BIZ_SELL_PRICE_AT_PLN_AMOUNT]
                        --, [BF_YR_SELL_PRICE_AT_BF_YR_AMT]
            
                        , [SA_COST_IMP_MTL_COST]
                        , [SA_COST_DOM_MTL_COST]
                        , [SALES_COST_LABOR_COST]
                        , [SALES_COST_EXPENSE]
                        , [SALES_COST_VAR_COST]
                        , [VARIANCE_ALLOCATION_AMOUNT]
                        , [CURR_YEAR_XRATE_DIFF_AMOUNT]
                        , [BF_MONTH_XRATE_DIFF_AMOUNT]
                        , [BF_YEAR_XRATE_DIFF_AMOUNT]
            
                        , [TAX_CODE]
                        , [TAX_AMOUNT]
                        , [OM_TXN_TP_CODE]
                        , [AR_TXN_TP_CODE]
            
                        , [INVOICE_NO]
                        , [INVOICE_OCCUR_YYYYMMDD]
                        , [ACCT_REFLEC_YYYYMMDD]
                        , [SALE_DEPARTMENT_CODE]
                        , [SALES_AMOUNT_ACCOUNT_CODE]
                        , [SALES_COST_ACCOUNT]
                        , [SALES_EMPLOYEE_NO]
                        , [BILL_TO_SHIP_TO_TYPE_CODE]
                        , [ERP_CUSTOMER_ACCOUNT_ID]
            
                        , [ACCT_BIZ_PLACE_CODE]
                        , [COUNTRY_CODE]
                        , [SITE_ID_BILL]
                        , [SITE_ID_SHIP]
            
                        , [LOCATION_NAME_BILL]
                        , [LOCATION_NAME_SHIP]
            
                        , [GL_VARIANCE]
                        , [OR_LOSS]
                        , [WT_CHRG_OSP_COST]
                        , [FUTURES_TRANSACTION_PL]
                        , [CUSTOMS_DUTY_DRAWBACK]
                        , [SALES_COST_ADJUST]
                        , [PRODUCT_DEDUCT]
                        , [ETL_DT]
                ) 
            /* 2011년 이후 ERP로부터 Detail 정보 형성 */
            /* 기준년월은 ERP에서 발생일자(Transaction Date)기준으로 집계 됨 */
            /* e-info에서는 이월 매출이관 작업을 하나,  ERP에서 하지 않기 때문에 차이가 있을수 있음 */
                     SELECT CAST(CAST(DT.ORDER_NUMBER AS bigint) AS NVARCHAR)       AS ORDER_NO
                          , DT.LINE_NUMBER                AS ORDER_LINE_NO
                          , DT.TRANSACTION_ID             AS TRANSACTION_ID
                          , FORMAT(DT.TRANSACTION_DATE, 'yyyyMM') AS YYYYMM
                          , ITM.PRODUCT_LINE_CODE         AS PRODUCT_LINE_CODE
                          , DT.SALES_FLAG                 AS SALES_OCCUR_TYPE_CODE
                          , FORMAT(DT.TRANSACTION_DATE, 'yyyyMMdd') AS SHIP_APPROVAL_YYYYMMDD
                          , CASE WHEN DT.SALES_FLAG = 'Export' THEN ISNULL(TM.MARKET_TYPE, '2') ELSE ISNULL(TM.MARKET_TYPE, '1') END AS MARKET_TYPE_CODE
                          , DT.INVENTORY_ITEM_ID                    AS ITEM_ID
                          , DT.ORGANIZATION_ID                      AS ORG_ID
                          , ITM.ITEM_CODE                           AS ITEM_CODE
                          , ITM.ORG_CODE                            AS ORG_CODE
                          , CONCAT(CAST(DT.ORGANIZATION_ID AS INT), CAST(DT.INVENTORY_ITEM_ID AS INT)) AS [ORG_ITEM_ID_KEY]
                          , DT.SALES_QTY                            AS SALES_QTY
                          , CAST(OD.UNIT_LIST_PRICE AS decimal(21,10))                      AS SHIP_UNIT_PRICE
                          /* 2011.04.14 사업단가로 되어 있는 부분을 사업단가 * 수량으로 변경 */
                    --      , ISNULL(TO_NUMBER(BP.ATTRIBUTE6,  DT.PLAN_PRICE) * DT.SALES_QTY AS BUSINESS_SELLING_PRICE_AMOUNT
                          /* 2016.03.09 사업단가금액을 무조건 E-info에서만 가져올 수 있도록 변경 */
                          , ISNULL(CAST(BP.PLAN_PRICE AS decimal(21,4)),  0) * DT.SALES_QTY AS BUSINESS_SELLING_PRICE_AMOUNTM
                          , ISNULL(DT.STANDARD_PRICE, 0)    AS STANDARD_SELLING_PRICE_AMOUNT
                          , DT.UNIT_PRICE        AS RESULT_SELLING_PRICEAMOUNT
                          , DT.CURRENCY_CODE     AS OCCUR_CURRENCY_CODE
                          , DT.REVENUE_ENTERED   AS OCCUR_CURRENCY_SALES_AMOUNT
                          , DT.REVENUE_ACCTD     AS BASIC_CURRENCY_SALES_AMOUNT
                          , ROUND(DT.REVENUE_USD, 4)       AS USD_CONVERSION_SALES_AMOUNT
            
                          , DT.M_IMPORT_COST     AS SA_COST_IMP_MTL_COST
                          , DT.M_DOMESTIC_COST   AS SA_COST_DOM_MTL_COST
                          , DT.P_LABOR_COST      AS SALES_COST_LABOR_COST
                          , DT.P_EXPENSE_COST    AS SALES_COST_EXPENSE
                          , DT.VARIABLE_COST     AS SALES_COST_VAR_COST
                    --      , DT.GL_VARIANCE       AS VARIANCE_ALLOCATION_AMOUNT
                          /* 2017.11.06 Variance 분산배부금액 계산로직 적용하여 OD_ERP_ECST_SALES_DETAILS 테이블에서 가져오도록 변경 */
                          , ISNULL(ESD.VARIANCE, 0) + ISNULL(ESD.OR_LOSS, 0) AS VARIANCE_ALLOCATION_AMOUNT
                          , DT.T_EXCHANGE_GAP    AS CURR_YEAR_XRATE_DIFF_AMOUNT
                          , DT.M_EXCHANGE_GAP    AS BF_MONTH_XRATE_DIFF_AMOUNT
                          , DT.L_EXCHANGE_GAP    AS BF_YEAR_XRATE_DIFF_AMOUNT
                          , DT.TAX_CODE          AS TAX_CODE
                          , DT.AMT_TAX           AS TAX_AMOUNT
                          , DT.ORDER_TYPE        AS OM_TXN_TP_CODE
                          , DT.AR_TYPE           AS AR_TXN_TP_CODE
                          , DT.INVOICE_NUMBER    AS INVOICE_NO
                          , FORMAT(DT.INVOICED_DATE, 'yyyyMMdd') AS INVOICE_DRAW_YYYYMMDD
                          , FORMAT(DT.GL_DATE, 'yyyyMMdd') AS ACCT_REFLEC_YYYYMMDD
                          , ISNULL(DT.SALES_DEPT_CODE, 'z{')   AS SALE_DEPARTMENT_CODE
                          , DT.SALES_ACCOUNT     AS SALES_AMOUNT_ACCOUNT_CODE
                          , DT.COGS_ACCOUNT      AS SALES_COST_ACCOUNT
                          , SUBSTRING(DT.SALESPERSON, CHARINDEX(',', DT.SALESPERSON)+1, LEN(DT.SALESPERSON)) AS SALES_EMPLOYEE_NO
                          , DT.TRAN_TYPE         AS BILL_TO_SHIP_TO_TYPE_CODE
                    --      , ISNULL(CM.ERP_CUSTOMER_ACCOUNT_ID, ISNULL(OD.SOLD_TO_ORG_ID, -99)) AS ERP_CUSTOMER_ACCOUNT_ID -- OLD
                          , ISNULL(OH.SOLD_TO_ORG_ID, ISNULL(OD.SOLD_TO_ORG_ID, -99)) AS ERP_CUSTOMER_ACCOUNT_ID -- 기능개선 305747
                          , DT.LOCATION_CODE     AS ACCT_BIZ_PLACE_CODE
                          , DT.COUNTRY           AS COUNTRY_CODE
                    --      , TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
                          , OH.INVOICE_TO_ORG_ID AS [SITE_ID_BILL]
                          , OH.SHIP_TO_ORG_ID    AS [SITE_ID_SHIP]
                          , (SELECT LOCATION FROM ERPSYS.ERP_HZ_CUST_SITE_USES WHERE SITE_USE_ID = OH.INVOICE_TO_ORG_ID) AS [LOCATION_NAME_BILL] 
                          , (SELECT LOCATION FROM ERPSYS.ERP_HZ_CUST_SITE_USES WHERE SITE_USE_ID = OH.SHIP_TO_ORG_ID)    AS [LOCATION_NAME_SHIP]
            
                          , ISNULL(ESD.VARIANCE       , 0) AS GL_VARIANCE
                          , ISNULL(ESD.OR_LOSS        , 0) AS OR_LOSS
                          , ISNULL(ESD.SS_COGS        , 0) AS WT_CHRG_OSP_COST
                          , ISNULL(ESD.FUTURE_COGS    , 0) AS FUTURES_TRANSACTION_PL
                          , ISNULL(ESD.CUSTOM_REFUND  , 0) AS CUSTOMS_DUTY_DRAWBACK
                          , ISNULL(ESD.COGS_ADJUSTMENT, 0) AS SALES_COST_ADJUST
                          , ISNULL(ESD.INV_DEVALUAION , 0) AS PRODUCT_DEDUCT 
                          , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                       FROM ERPSYS.ERP_ECST_BI_ITEM_COGS_DTL DT
            /* 기능개선 305747 으로인해 필요없는 구문 제거
                   LEFT OUTER JOIN T_CUST CM
                                ON DT.CUSTOMER_NUMBER = CM.CUSTOMER_CODE
            */
            LEFT OUTER JOIN ERPSYS.ERP_OE_ORDER_HEADERS OH
                         ON DT.ORDER_NUMBER = OH.ORDER_NUMBER
                        AND OH.BOOKED_FLAG = 'Y'
            LEFT OUTER JOIN ERPSYS.ERP_OE_ORDER_LINES_ALL OD
                         ON OH.HEADER_ID = OD.HEADER_ID
                        AND DT.LINE_NUMBER = CONCAT(OD.LINE_NUMBER, '.', OD.SHIPMENT_NUMBER)
                        AND OD.FLOW_STATUS_CODE = 'CLOSED'
                        AND DT.INVENTORY_ITEM_ID = OD.INVENTORY_ITEM_ID 
                        AND OD.UNIT_LIST_PRICE IS NOT NULL -- 20230613 WHERE 에서 변경 
            LEFT OUTER JOIN T_MARKET TM
                         ON DT.SALES_DEPT_CODE = TM.DEPT_CODE
                        AND (CASE UPPER(DT.SALES_FLAG) WHEN 'EXPORT' THEN 'OVER' ELSE 'DOM' END) = TM.TAG
            LEFT OUTER JOIN T_DIM_FND_COM_ITEM ITM
                         ON DT.INVENTORY_ITEM_ID = ITM.ITEM_ID
                        AND DT.ORGANIZATION_ID   = ITM.ORG_ID
                         
            /* 160309 E-info 사업판가금액 월별기준에서 연간기준 max값으로 가져오게 변경 (양산매출계획) */
            LEFT OUTER JOIN (SELECT BUSINESS_YYYY
                                  , ATTRIBUTE_VALUE17     AS ORG_CODE
                                  , ATTRIBUTE_VALUE3      AS MARKET_TYPE
                                  , ATTRIBUTE_VALUE5      AS ITEM_CODE
                                  , MAX(ATTRIBUTE_VALUE6) AS PLAN_PRICE
                               FROM EBIZ.COM_BPS_BUSINESS_PLAN BP
                              WHERE REPORT_NO = 'BPS_RPT_007'
                           GROUP BY BUSINESS_YYYY,  ATTRIBUTE_VALUE17,  ATTRIBUTE_VALUE3,  ATTRIBUTE_VALUE5
                            ) BP
                         ON SUBSTRING(FORMAT(DT.TRANSACTION_DATE, 'yyyyMM'), 1, 4) = BP.BUSINESS_YYYY
                        AND CASE WHEN DT.SALES_FLAG = 'Export' AND DT.CURRENCY_CODE = 'CNY' THEN ISNULL(TM.MARKET_TYPE, '3')  
                                 WHEN DT.SALES_FLAG = 'Export' THEN ISNULL(TM.MARKET_TYPE, '2') ELSE ISNULL(TM.MARKET_TYPE, '1') END = (CASE BP.MARKET_TYPE WHEN 'D' THEN 1 WHEN 'E' THEN 2 WHEN 'C' THEN '3' END)
                        AND ITM.ITEM_CODE = BP.ITEM_CODE
                        AND ITM.ORG_CODE = BP.ORG_CODE 
            LEFT OUTER JOIN T_DIM_FND_COM_ORG Z
                         ON DT.ORGANIZATION_ID = Z.ORG_ID
            -- 20140424 조성규 추가 --
            LEFT OUTER JOIN ERPSYS.ERP_ECST_SALES_DETAILS ESD
                         ON CAST(CAST(DT.ORDER_NUMBER AS BIGINT) AS NVARCHAR) = ESD.ORDER_PROG_NO
                        AND DT.LINE_NUMBER = ESD.ORDER_LINE_NO
                        AND FORMAT(DT.TRANSACTION_DATE, 'yyyyMMdd') = FORMAT(ESD.TRANSACTION_DATE, 'yyyyMMdd')
                        AND DT.TRANSACTION_ID  = ESD.TRANSACTION_ID 
                      WHERE FORMAT(DT.TRANSACTION_DATE, 'yyyyMM') >= '201101'
                        AND FORMAT(DT.TRANSACTION_DATE, 'yyyyMM') >= @v_parm_from 
                        AND DT.TRANSACTION_DATE < DATEADD(MONTH, 1, CONCAT(@v_parm_to, '01'))  -- CDC
                     --   AND DT.UNIT_PRICE IS NOT NULL
                        --AND OD.UNIT_LIST_PRICE IS NOT NULL -- 20230613 WHERE 주석  
                        AND Z.OU_ID = 89 
            -- OD_ENF_TPE_51M 미사용으로 아래 스크립트 삭제 
            --UNION ALL
            --/* 2010년 과거 Data Conversion */
            --SELECT LT.C_ODR                      AS ORDER_NO
            --      , LT.C_LNE                      AS ORDER_LINE_NO
            --      , TO_NUMBER(LT.YYMM||ROWNUM)              AS TRANSACTION_ID
            --      , CASE WHEN LT.YYMM <> SUBSTR(TO_CHAR(LT.D_S_CFM, 'YYYYMMDD') , 1, 6) THEN TO_CHAR(LAST_DAY(TO_DATE(LT.YYMM, 'YYYYMM')), 'YYYYMM') ELSE TO_CHAR(LT.D_S_CFM, 'YYYYMM') END AS YYYYMM
            --      , ITM.PRODUCT_LINE_CODE         AS PRODUCT_LINE_CODE
            --      , CASE LT.C_SHP  WHEN '1' THEN 'Domestic'
            --                      WHEN '2' THEN 'Export'
            --                      WHEN '3' THEN 'Export'
            --                      WHEN '4' THEN 'SVC'
            --                      WHEN '5' THEN 'Free Of Charge'
            --                      WHEN '6' THEN 'Sales For Supplier'
            --                      WHEN '7' THEN 'Internal'
            --                      WHEN '8' THEN 'Internal'
            --                      WHEN '9' THEN 'Domestic ETC'
            --                      WHEN 'J' THEN 'Sales By Cust Supply'
            --                      ELSE 'z{' END AS SALES_OCCUR_TYPE_CODE
            
            --      , CASE WHEN LT.YYMM <> SUBSTR(TO_CHAR(LT.D_S_CFM, 'YYYYMMDD') , 1, 6) THEN TO_CHAR(LAST_DAY(TO_DATE(LT.YYMM, 'YYYYMM')), 'YYYYMMDD') ELSE TO_CHAR(LT.D_S_CFM, 'YYYYMMDD') END AS SHIP_APPROVAL_YYYYMMDD
            --      , CASE WHEN LT.C_SHP IN ('2', '3') THEN ISNULL(TM.MARKET_TYPE, '2')
            --            ELSE ISNULL(TM.MARKET_TYPE, '1') END AS MARKET_TYPE_CODE
            --      , ITM.ITEM_ID                             AS ITEM_ID
            --      , ITM.ORG_ID                              AS ORG_ID
            --      , ITM.ITEM_CODE                           AS ITEM_CODE
            --      , ITM.ORG_CODE                            AS ORG_CODE
            --      , LT.Q_SOLD                               AS SALES_QTY
            --      , ISNULL(LT.A_SHP, 0)                         AS SHIP_UNIT_PRICE
            --      , ISNULL(LT.A_SEL, 0) AS BUSINESS_SELLING_PRICE_AMOUNT
            --      , ISNULL(LT.A_SHP, 0)                         AS STANDARD_SELLING_PRICE_AMOUNT
            --      , ISNULL(LT.UP_SEL, 0)                        AS RESULT_SELLING_PRICEAMOUNT
            --      , LT.C_UNT                                AS OCCUR_CURRENCY_CODE
            --      , LT.A_SOLD_U                             AS OCCUR_CURRENCY_SALES_AMOUNT
            --      , LT.A_SOLD_K                             AS BASIC_CURRENCY_SALES_AMOUNT
            --      , ROUND(LT.A_USD, 4)                       AS USD_CONVERSION_SALES_AMOUNT
            --      , LT.A_MTR * ( CASE WHEN LV.A_IM_MTR + LV.A_SOLD_MTR = 0 THEN 0
            --                         ELSE LV.A_IM_MTR / (LV.A_IM_MTR + LV.A_SOLD_MTR) END)  AS SA_COST_IMP_MTL_COST
            --      , LT.A_MTR - (LT.A_MTR * ( CASE WHEN LV.A_IM_MTR + LV.A_SOLD_MTR = 0 THEN 0
            --                         ELSE LV.A_IM_MTR / (LV.A_IM_MTR + LV.A_SOLD_MTR) END)) AS SA_COST_DOM_MTL_COST
            --      , LT.A_LBR                                AS SALES_COST_LABOR_COST
            --      , LT.A_XPS                                AS SALES_COST_EXPENSE
            --      , (LT.A_LBR + LT.A_XPS) * ( CASE WHEN LV.A_SOLD_LBR + LV.A_SOLD_XPS = 0 THEN 0
            --                                      ELSE LV.A_VARI / (LV.A_SOLD_LBR + LV.A_SOLD_XPS) END ) + LT.A_MTR AS SALES_COST_VAR_COST
            --      , (LT.A_LBR + LT.A_XPS) * ( CASE WHEN LV.A_SOLD_LBR + LV.A_SOLD_XPS = 0 THEN 0
            --                                      ELSE LV.A_ABV / (LV.A_SOLD_LBR + LV.A_SOLD_XPS) END ) AS VARIANCE_ALLOCATION_AMOUNT
            --      , LT.A_MTR * ( CASE WHEN LV.A_IM_MTR + LV.A_SOLD_MTR = 0 THEN 0
            --                                      ELSE LV.A_MEX / (LV.A_IM_MTR + LV.A_SOLD_MTR) END )  AS CURR_YEAR_XRATE_DIFF_AMOUNT
            --      , 0 AS BF_MONTH_XRATE_DIFF_AMOUNT
            --      , LT.A_MTR * ( CASE WHEN LV.A_IM_MTR + LV.A_SOLD_MTR = 0 THEN 0
            --                         ELSE LV.A_MBEX / ( LV.A_IM_MTR + LV.A_SOLD_MTR ) END ) AS BF_YEAR_XRATE_DIFF_AMOUNT
            --      , LT.C_TAX                                AS TAX_CODE
            --      , LT.A_TAX                                AS TAX_AMOUNT
            --      , LT.TYP_OM                             AS OM_TXN_TP_CODE
            --      , LT.TYP_AR                              AS AR_TXN_TP_CODE
            --      , TO_CHAR(LT.N_BILL)                      AS INVOICE_NO
            --      , TO_CHAR(LT.D_INVO, 'YYYYMMDD')           AS INVOICE_DRAW_YYYYMMDD
            --      , TO_CHAR(LT.D_GL, 'YYYYMMDD')             AS ACCT_REFLEC_YYYYMMDD
            --      , ISNULL(LT.C_DPT, 'z{')                      AS SALE_DEPARTMENT_CODE
            --      , NULL      AS SALES_AMOUNT_ACCOUNT_CODE
            --      , NULL      AS SALES_COST_ACCOUNT
            --      , SUBSTR(LT.C_SLE_EMP, INSTR(LT.C_SLE_EMP, ', ')+1, LENGTH(LT.C_SLE_EMP)) AS SALES_EMPLOYEE_NO
            --      , CASE WHEN LT.N_TYP = '1' THEN 'SHIP' ELSE 'BILL' END AS BILL_TO_SHIP_TO_TYPE_CODE
            --      , ISNULL(CM.ERP_CUSTOMER_ACCOUNT_ID, -99)     AS ERP_CUSTOMER_ACCOUNT_ID
            --      , ORG.ACCT_BIZ_PLACE_CODE                 AS ACCT_BIZ_PLACE_CODE
            --      , ISNULL(CM.COUNTRY_CODE, ISNULL(SUBSTR(LT.C_TRDR,  1,  2), 'z{'))         AS COUNTRY_CODE
            ----      , TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS')
            --      , OH.INVOICE_TO_ORG_ID AS SITE_USAGE_ID_BILL_TO
            --      , OH.SHIP_TO_ORG_ID    AS SITE_USAGE_ID_SHIP_TO
            --      , (SELECT LOCATION FROM OD_ERP_HZ_CUST_SITE_USES WHERE SITE_USE_ID = OH.INVOICE_TO_ORG_ID) AS SITE_USAGE_NAME_BILL_TO
            --      , (SELECT LOCATION FROM OD_ERP_HZ_CUST_SITE_USES WHERE SITE_USE_ID = OH.SHIP_TO_ORG_ID)    AS SITE_USAGE_NAME_SHIP_TO
            --      , 0 AS GL_VARIANCE
            --      , 0 AS OR_LOSS
            --      , 0 AS WT_CHRG_OSP_COST
            --      , 0 AS FUTURES_TRANSACTION_PL
            --      , 0 AS CUSTOMS_DUTY_DRAWBACK
            --      , 0 AS SALES_COST_ADJUST
            --      , 0 AS PRODUCT_DEDUCT
            --  FROM OD_ENF_TPE_51M LT
            --       INNER JOIN OD_ENF_TPE_15M LV
            --               ON LT.C_ORG = LV.C_ORG
            --              AND LT.YYMM = LV.YYMM
            --              AND LT.C_SHP = LV.C_SHP
            --              AND LT.C_ERP = LV.C_ERP
            --       LEFT OUTER JOIN OD_ERP_OE_ORDER_HEADERS OH
            --                    ON LT.C_ODR = OH.ORDER_NUMBER
            --       LEFT OUTER JOIN T_DIM_FND_COM_ITEM ITM
            --                    ON LT.C_ORG = ITM.ORG_CODE
            --                   AND LT.C_ERP = ITM.ITEM_CODE
            --       LEFT OUTER JOIN T_DIM_FND_COM_ORG ORG
            --                    ON LT.C_ORG = ORG.ORG_CODE
            --       LEFT OUTER JOIN T_CUST CM
            --                    ON LT.C_TRDR = CM.CUSTOMER_CODE
            --       LEFT OUTER JOIN T_MARKET TM
            --                    ON LT.C_DPT = TM.DEPT_CODE
            --                   AND CASE WHEN LT.C_SHP IN ('2', '3') THEN 'OVER'
            --                            ELSE 'DOM' END = TM.TAG
            -- WHERE 1 = 1
            --    AND  LT.YYMM <= '201012'
            --    AND  LT.YYMM BETWEEN '#$F_YYYYMM#' AND '#$T_YYYYMM#'
            --    AND  ITM.PRODUCT_LINE_CODE NOT IN ( '700',  '750',  '770',  '799' ) 
                 ; 
  
                   
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_FIN_CCT_SALES_COST_DETAIL]
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

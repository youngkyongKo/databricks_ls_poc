CREATE PROC [dbo].[SP_T_DW_EOM_SCO_NEW_PRD_SA_STAT_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS

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

        SET @v_run_pgm = 'SP_T_DW_EOM_SCO_NEW_PRD_SA_STAT_M_C'
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

            DELETE  FROM [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT] WHERE YYYYMM = @v_parm_to
            ;

            WITH INPUP_COST AS (
            SELECT @v_parm_to                                                                                  AS YYYYMM
                  ,SUBSTRING(A.ITEM_ID,4,LEN(A.ITEM_ID))                                                       AS ITEM_CODE
                  ,A.ORGCODE                                                                                   AS ORG_CODE
                  ,A.PROJECT_ID                                                                                AS PROJECT_NO
                  ,A.RND_PJT_CODE                                                                              AS RND_PJT_CODE
                  ,A.GRADE_CODE                                                                                AS GRADE_CODE
                  ,A.GRADE_NAME                                                                                AS GRADE_NAME
                  ,A.TASK_ID                                                                                   AS TASK_NO
                  ,FORMAT(DATEADD(MM,1,CAST(B.ACTUAL_END_DATE AS DATE)),'yyyyMM')                              AS START_YYYYMM  --인정기간(시작)
                  ,FORMAT(DATEADD(MM,36,CAST(B.ACTUAL_END_DATE AS DATE)),'yyyyMM')                             AS END_YYYYMM    --인정기간(종료)
                  ,CASE WHEN A.ORGCODE IN ('M02','M04','M07','M08','M11')                                                       -- 수주의 경우 -- 자동화분리운영ORG추가 20201207
                             THEN (
                                   CASE WHEN B.REVENUE_START_DATE IS NOT NULL AND B.ACTUAL_END_DATE IS NOT NULL                 -- 매출인정시작일이 존재하고, 과제종료일이 존재하는 경우
                                             THEN (
                                                   CASE WHEN @v_parm_to BETWEEN SUBSTRING(B.REVENUE_START_DATE,1,6) AND FORMAT(DATEADD(MM,36,CAST(B.ACTUAL_END_DATE AS DATE)),'yyyyMM') THEN 'Y'
                                                                                                                                -- 매출 인정 시작일부터 과제 종료 후 36개월까지 집계
                                                        ELSE 'N'
                                                   END
                                                  )
                                       WHEN B.REVENUE_START_DATE IS NOT NULL AND B.ACTUAL_END_DATE IS NULL                      -- 매출인정시작일이 존재하고, 과제종료일이 존재하지않는 경우
                                            THEN (
                                                  CASE WHEN @v_parm_to BETWEEN SUBSTRING(B.REVENUE_START_DATE,1,6) AND @v_parm_to THEN 'Y'
                                                                                                                                -- 매출 인정 시작일부터 적재시점까지 집계
                                                       ELSE 'N'
                                                  END
                                                 )
                                       WHEN B.REVENUE_START_DATE IS NULL AND B.ACTUAL_END_DATE IS NOT NULL                      -- 매출인정시작일이 존재하지 않고, 과제종료일이 존재하는 경우
                                            THEN (
                                                  CASE WHEN @v_parm_to BETWEEN SUBSTRING(B.ACTUAL_END_DATE,1,6) AND FORMAT(DATEADD(MM,36,CAST(B.ACTUAL_END_DATE AS DATE)),'yyyyMM') THEN 'Y'
                                                                                                                                -- 과제종료월부터 36개월까지 집계
                                                       ELSE 'N'
                                                  END
                                                 )
                                       ELSE 'N'                                                                                 -- 매출인정시작일이 존재하지 않고, 과제종료일이 존재하지않는 경우 집계하지않음
                                   END
                                  )
                             ELSE (
                                   CASE WHEN @v_parm_to BETWEEN SUBSTRING(B.ACTUAL_END_DATE,1,6) AND FORMAT(DATEADD(MM,36,CAST(B.ACTUAL_END_DATE AS DATE)),'yyyyMM') THEN 'Y'
                                                                                                                                -- 양산의경우 과제종료월부터 36개월까지 집계
                                        ELSE 'N'
                                   END
                                  )
                   END                                                                                         AS NEW_PROD_YN            --연구개발에 기간 조건없이 보여주는 화면 때문에 과거 데이터도 적재함
                  ,ISNULL(D.END_EFFORT,0)                                                                      AS END_EFFORT             --투입공수
                  ,ISNULL(C.SLABOR_COST,0)                                                                     AS SLABOR_COST            --인건비
                  ,ISNULL(C.MATERIAL_COST + C.CON_RND_COST + C.TST_RSCH_COST + C.TECH_COST,0)                  AS TST_RSCH_COST          --시험연구비
                  ,ISNULL(C.EXPENSE - (C.SLABOR_COST + C.MATERIAL_COST + C.CON_RND_COST +
                                       C.TST_RSCH_COST + C.DEPRN_EXPENSE + C.TECH_COST),0)                     AS ETC_EXPENSE            --기타일반경비
                  ,ISNULL(C.EXPENSE - C.DEPRN_EXPENSE,0)                                                       AS DEPRN_EXPENSE_EXCLTOT  --감가삼각비제외합계
                  ,ISNULL(C.DEPRN_EXPENSE,0)                                                                   AS DEPRN_EXPENSE          --감가삼각비
                  ,ISNULL(C.EXPENSE,0)                                                                         AS TOT_EXPNS              --총비용
              FROM RMS.RMS_BI_ORDER_ITEM_SPL_V A
              JOIN T_DIM_FND_COM_RND_PJT B
                ON A.RND_PJT_CODE = B.PROJECT_NO
               AND SUBSTRING(ISNULL(B.ACTUAL_END_DATE ,B.REVENUE_START_DATE),1,4) >= '2010'                                              --2013년도 데이터부터 존재
              LEFT OUTER
              JOIN T_DW_RND_RDV_INPUT_COST C
                ON C.YYYYMM = @v_parm_to
               AND B.PROJECT_NO = C.PROJECT_NO
              LEFT OUTER
              JOIN (
                    SELECT C.PROJECT_NO
                          ,A.END_EFFORT
                      FROM ERPSYS.ERP_EDCM_TICA_BALANCE A
                      JOIN (
                            SELECT PROJECT_ID
                                  ,MAX(YYYYMM)                          AS MAX_YYYYMM
                              FROM ERPSYS.ERP_EDCM_TICA_BALANCE
                             GROUP BY PROJECT_ID
                           ) B
                        ON A.YYYYMM = B.MAX_YYYYMM
                       AND A.PROJECT_ID = B.PROJECT_ID
                      JOIN T_DIM_FND_COM_PROJECT C
                        ON A.PROJECT_ID = C.PROJECT_ID
                     WHERE A.END_EFFORT <> 0
                   ) D
                ON A.RND_PJT_CODE = D.PROJECT_NO
             WHERE A.ORGCODE <> 'CW1'
             --AND @v_parm_to BETWEEN  TO_CHAR(ADD_MONTHS(TO_DATE(B.ACTUAL_END_DATE,'YYYY-MM-DD'),1),'YYYYMM') AND TO_CHAR(ADD_MONTHS(TO_DATE(B.ACTUAL_END_DATE,'YYYY-MM-DD'),36),'YYYYMM') --20161123 이정민C 인정 기간 데이터만 추출하기로 함
             --AND  A.PROJECT_ID = '411430133'
            )
            --매출이 중국사업본부 하위 부서이고 SPG(PLC,INV) 일경우   = > 산업자동화사업본부 : 중국FOB 산업자동화(LO002)
            --매출이 중국사업본부 하위 부서이고 SPG(PLC,INV) 아닐경우 = > 전력사업본부 : 중국FOB 전력(LO001)
            INSERT INTO [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT]
            (
                   [YYYYMM]                                                 --기준년월
                  ,[PROJECT_NO]                                             --프로젝트번호
                  ,[RND_PJT_NO]                                             --RND_프로젝트번호
                  ,[DEPARTMENT_CODE]                                        --부서코드
                  ,[PRODUCT_LINE_CODE]                                      --제품류코드
                  ,[TASK_CODE]                                              --TASK_CODE
                  ,[PROJECT_TASK_NO_KEY]                                    --조합키1(프로젝트번호+TASK_CODE)
                  ,[ITEM_CODE]                                              --ITEM_CODE
                  ,[DOMESTIC_OVERSEAS_TYPE]                                 --국내/해외
                  ,[ERP_CUSTOMER_ACCOUNT_ID]                                --고개계정ID
                  ,[MP_TENDER_BIZ_TP_CODE]                                  --양산수주구분
                  ,[GRADE_CODE]                                             --등급
                  ,[GRADE_NAME]                                             --등급명
                  ,[ORG_CODE]                                               --ORG_CODE
                  ,[ORG_ITEM_CODE_KEY]                                      --조합키(조직코드+품목코드)
                  ,[START_YYYYMM]                                           --신제품인정기긴(시작)
                  ,[END_YYYYMM]                                             --신제품인정기긴(종료)
                  ,[NEW_PROD_YN]                                            --
                  ,[COUNTRY_CODE]                                           --국가코드
                  ,[ITEM_QTY]                                               --수량
                  ,[SALES_AMOUNT]                                           --매출액
                  ,[SALES_COST]                                             --매출원가
                  ,[SALES_TOTAL_PROFIT_AMOUNT]                              --매출총이익금액
                  ,[EFFORT]                                                 --투입공수
                  ,[SLABOR_COST]                                            --인건비
                  ,[TST_RSCH_COST]                                          --시험연구비
                  ,[EXPENSE]                                                --일반경비
                  ,[DEPRN_EXPENSE]                                          --감가삼각비
                  ,[DEPRN_EXPENSE_EXCLTOT]                                  --감가삼각비제외합계
                  ,[TOT_EXPNS]                                              --총비용
                  ,[ETL_DT]                                                 --적재일시
            )
            SELECT A.YYYYMM
                  ,A.PROJECT_NO
                  ,A.RND_PJT_NO
            --     ,    CASE WHEN C.COMPANY_CODE = 'KA395' THEN CASE WHEN B.SPG_CODE IN ('D01','D02') THEN 'LO002' ELSE 'LO001' END ELSE A.DEPARTMENT_CODE END AS DEPARTMENT_CODE
            -- 20200512 진혜영 글로벌사업본부가 생기면서 본부강제세팅 부분 삭제
                  ,A.DEPARTMENT_CODE                                                                           AS DEPARTMENT_CODE
                  ,A.PRODUCT_LINE_CODE
                  ,A.TASK_NO
                  ,CONCAT(TRIM(A.PROJECT_NO),TRIM(A.TASK_NO))
                  ,A.ITEM_CODE
                  ,ISNULL(A.DOMESTIC_OVERSEAS_TYPE,'z~')                                                       AS DOMESTIC_OVERSEAS_TYPE
                  ,ISNULL(A.ERP_CUSTOMER_ACCOUNT_ID,0)                                                         AS ERP_CUSTOMER_ACCOUNT_ID
                  ,A.MP_TENDER_BIZ_TP_CODE
                  ,A.GRADE_CODE
                  ,A.GRADE_NAME
                  ,A.ORG_CODE
                  ,CONCAT(TRIM(A.ORG_CODE),TRIM(A.ITEM_CODE))                                                                                 --조합키(조직코드+품목코드)
                  ,A.START_YYYYMM
                  ,A.END_YYYYMM
                  ,A.NEW_PROD_YN
                  ,A.COUNTRY_CODE
                  ,A.ITEM_QTY
                  ,A.SALES_AMOUNT
                  ,A.SALES_COST
                  ,A.SALES_TOTAL_PROFIT_AMOUNT
                  ,A.END_EFFORT
                  ,A.SLABOR_COST
                  ,A.TST_RSCH_COST
                  ,A.ETC_EXPENSE
                  ,A.DEPRN_EXPENSE
                  ,A.DEPRN_EXPENSE_EXCLTOT
                  ,A.TOT_EXPNS
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                                 AS ETL_DT                    --적재일시
              FROM (
                    --양산
                    SELECT @v_parm_to                                                                          AS YYYYMM                    --기준년월
                          ,A.PROJECT_NO                                                                        AS PROJECT_NO
                          ,A.RND_PJT_CODE                                                                      AS RND_PJT_NO
                          ,ISNULL(C.DEPARTMENT_CODE,'z~')                                                      AS DEPARTMENT_CODE           --부서코드
                          ,B.PRODUCT_LINE_CODE                                                                 AS PRODUCT_LINE_CODE         --제품류코드
                          ,'1'                                                                                 AS TASK_NO
                          ,B.ITEM_CODE                                                                         AS ITEM_CODE
                          ,'MFG'                                                                               AS MP_TENDER_BIZ_TP_CODE     --양산수주구분
                          ,C.DOMESTIC_OVERSEAS_TYPE                                                            AS DOMESTIC_OVERSEAS_TYPE    --국내해외구분코드
                          ,A.GRADE_CODE                                                                        AS GRADE_CODE
                          ,A.GRADE_NAME                                                                        AS GRADE_NAME
                          ,A.ORG_CODE                                                                          AS ORG_CODE
                          ,A.START_YYYYMM                                                                      AS START_YYYYMM              --인정기간(시작)
                          ,A.END_YYYYMM                                                                        AS END_YYYYMM                --인정기간(종료)
                          ,A.NEW_PROD_YN                                                                       AS NEW_PROD_YN               --연구개발에 기간 조건없이 보여주는 화면 때문에 과거 데이터도 적재함
                          ,MAX(C.COUNTRY_CODE)                                                                 AS COUNTRY_CODE              --국가코드
                          ,C.ERP_CUSTOMER_ACCOUNT_ID                                                           AS ERP_CUSTOMER_ACCOUNT_ID   --ERP고객계정ID
                          ,MAX(C.ITEM_QTY)                                                                     AS ITEM_QTY                  --매출수량
                          ,MAX(C.SALES_AMOUNT)                                                                 AS SALES_AMOUNT
                          ,MAX(C.SALES_COST_MATERIAL_COST + C.SALES_COST_CONVERSION_COST)                      AS SALES_COST
                          ,MAX(C.SALES_AMOUNT - (C.SALES_COST_MATERIAL_COST + C.SALES_COST_CONVERSION_COST))   AS SALES_TOTAL_PROFIT_AMOUNT --매출총이익금액
                          ,MAX(A.END_EFFORT)                                                                   AS END_EFFORT
                          ,MAX(A.SLABOR_COST)                                                                  AS SLABOR_COST
                          ,MAX(A.TST_RSCH_COST)                                                                AS TST_RSCH_COST
                          ,MAX(A.ETC_EXPENSE)                                                                  AS ETC_EXPENSE
                          ,MAX(A.DEPRN_EXPENSE)                                                                AS DEPRN_EXPENSE
                          ,MAX(A.DEPRN_EXPENSE_EXCLTOT)                                                        AS DEPRN_EXPENSE_EXCLTOT
                          ,MAX(A.TOT_EXPNS)                                                                    AS TOT_EXPNS
                      FROM INPUP_COST A
                      JOIN T_DIM_FND_COM_ITEM B
                        ON A.ITEM_CODE = B.ITEM_CODE
                       AND A.ORG_CODE = B.ORG_CODE
                      LEFT OUTER
                      JOIN (
                            SELECT SALE_DEPARTMENT_CODE                                                         AS DEPARTMENT_CODE
                                  ,CASE WHEN MARKET_TYPE_CODE = 1 THEN 'D'
                                        ELSE 'E'
                                   END                                                                          AS DOMESTIC_OVERSEAS_TYPE
                                  ,ORG_CODE                                                                     AS ORG_CODE
                                  ,ITEM_CODE                                                                    AS ITEM_CODE
                                  ,COUNTRY_CODE                                                                 AS COUNTRY_CODE
                                  ,ERP_CUSTOMER_ACCOUNT_ID                                                      AS ERP_CUSTOMER_ACCOUNT_ID
                                  ,SUM(SALES_QTY)                                                               AS ITEM_QTY
                                  ,SUM(BASIC_CURRENCY_SALES_AMOUNT)                                             AS SALES_AMOUNT
                                  ,SUM(SA_COST_IMP_MTL_COST + SA_COST_DOM_MTL_COST )                            AS SALES_COST_MATERIAL_COST
                                  ,SUM(SALES_COST_LABOR_COST + SALES_COST_EXPENSE + VARIANCE_ALLOCATION_AMOUNT) AS SALES_COST_CONVERSION_COST
                              FROM T_DW_FIN_CCT_SALES_COST_DETAIL
                             WHERE YYYYMM = @v_parm_to
                              --AND    ITEM_CODE ='60300001'
                             GROUP BY SALE_DEPARTMENT_CODE
                                  ,CASE WHEN MARKET_TYPE_CODE = 1 THEN 'D'
                                        ELSE 'E'
                                   END
                                  ,ORG_CODE
                                  ,ITEM_CODE
                                  ,COUNTRY_CODE
                                  ,ERP_CUSTOMER_ACCOUNT_ID
                           ) C
                        ON B.ORG_CODE = C.ORG_CODE
                       AND B.ITEM_CODE = C.ITEM_CODE
                     WHERE A.ORG_CODE IN ('M01','M03','M05','M06','M09','M10') -- 자동화분리운영ORG추가 20201207
                     GROUP BY A.PROJECT_NO
                          ,A.RND_PJT_CODE
                          ,ISNULL(C.DEPARTMENT_CODE,'z~')
                          ,B.PRODUCT_LINE_CODE
                          ,B.ITEM_CODE
                          ,C.DOMESTIC_OVERSEAS_TYPE
                          ,A.GRADE_CODE
                          ,A.GRADE_NAME
                          ,A.ORG_CODE
                          ,A.START_YYYYMM
                          ,A.END_YYYYMM
                          ,A.NEW_PROD_YN
                          ,C.ERP_CUSTOMER_ACCOUNT_ID
                     UNION ALL
                    --수주 ( PDM에서 넘어온 TASK 집계)
                    SELECT @v_parm_to                                                                        AS YYYYMM                    --기준년월
                          ,A.PROJECT_NO                                                                         AS PROJECT_NO
                          ,A.RND_PJT_CODE                                                                       AS RND_PJT_NO
                          ,ISNULL(B.DEPARTMENT_CODE,'z~')                                                       AS DEPARTMENT_CODE           --부서코드
                          ,ISNULL(B.PRODUCT_LINE_CODE,'z~')                                                     AS PRODUCT_LINE_CODE         --제품류코드
                          ,A.TASK_NO                                                                            AS TASK_NO
                          ,'1'                                                                                  AS ITEM_CODE
                          ,'PJT'                                                                                AS MP_TENDER_BIZ_TP_CODE     --양산수주구분
                          ,B.DOMESTIC_OVERSEAS_TYPE                                                             AS DOMESTIC_OVERSEAS_TYPE    --국내해외구분코드
                          ,A.GRADE_CODE                                                                         AS GRADE_CODE
                          ,A.GRADE_NAME                                                                         AS GRADE_NAME
                          ,A.ORG_CODE                                                                           AS ORG_CODE
                          ,A.START_YYYYMM                                                                       AS START_YYYYMM              --인정기간(시작)
                          ,A.END_YYYYMM                                                                         AS END_YYYYMM                --인정기간(종료)
                          ,A.NEW_PROD_YN                                                                        AS NEW_PROD_YN               --연구개발에 기간 조건없이 보여주는 화면 때문에 과거 데이터도 적재함
                          ,NULL                                                                                 AS COUNTRY_CODE              --국가코드
                          ,0                                                                                    AS ERP_CUSTOMER_ACCOUNT_ID   --ERP고객계정ID
                          ,0                                                                                    AS ITEM_QTY                  --매출수량
                          ,SUM(B.SALES_AMOUNT)                                                                  AS SALES_AMOUNT
                          ,SUM(B.SALES_COST)                                                                    AS SALES_COST
                          ,SUM(B.SALES_AMOUNT - B.SALES_COST)                                                   AS SALES_TOTAL_PROFIT_AMOUNT --매출총이익금액
                          ,SUM(A.END_EFFORT)                                                                    AS END_EFFORT
                          ,SUM(A.SLABOR_COST)                                                                   AS SLABOR_COST
                          ,SUM(A.TST_RSCH_COST)                                                                 AS TST_RSCH_COST
                          ,SUM(A.ETC_EXPENSE)                                                                   AS ETC_EXPENSE
                          ,SUM(A.DEPRN_EXPENSE)                                                                 AS DEPRN_EXPENSE
                          ,SUM(A.DEPRN_EXPENSE_EXCLTOT)                                                         AS DEPRN_EXPENSE_EXCLTOT
                          ,SUM(A.TOT_EXPNS)                                                                     AS TOT_EXPNS
                      FROM INPUP_COST A
                      LEFT OUTER
                      JOIN T_DW_EOM_SPJ_TENDER_BIZ_SA_STAT B
                        ON B.SALES_YYYYMM = @v_parm_to
                       AND A.ORG_CODE = B.ORG_CODE
                       AND A.PROJECT_NO = B.PROJECT_NO
                       AND A.TASK_NO = B.TASK_NO
                     WHERE A.ORG_CODE IN ('M02','M04','M07','M08','M11')                                                                     -- 자동화분리운영ORG추가 20201207
                       --AND    B.PRODUCT_LINE_CODE NOT IN ('800','850','860','875') --수주 SPG 매출액 집계방법 개선 (기능개선 321085) 20200529
                     GROUP BY A.PROJECT_NO
                          ,A.RND_PJT_CODE
                          ,B.DEPARTMENT_CODE
                          ,B.PRODUCT_LINE_CODE
                          ,A.TASK_NO
                          ,B.DOMESTIC_OVERSEAS_TYPE
                          ,A.GRADE_CODE
                          ,A.GRADE_NAME
                          ,A.ORG_CODE
                          ,A.START_YYYYMM
                          ,A.END_YYYYMM
                          ,A.NEW_PROD_YN
            
                    /* 수주 SPG 매출액 집계방법 개선 (기능개선 321085) 20200529
                     UNION ALL
                    --수주 ( PDM에서 넘어온 TASK와 상관없이 전체 프로젝트로 집계) => 프로젝트번호 , R&D 과제별 TASK를 001로 묶어서 집계한다.
                    SELECT @v_parm_to                                 AS YYYYMM  --기준년월
                          ,B.PROJECT_NO                               AS PROJECT_NO
                          ,A.RND_PJT_CODE                             AS RND_PJT_NO
                          ,MAX(NVL(B.DEPARTMENT_CODE,'z~'))           AS DEPARTMENT_CODE --부서코드
                          ,MAX(NVL(B.PRODUCT_LINE_CODE,'z~'))         AS PRODUCT_LINE_CODE --제품류코드
                          ,'001'                                      AS TASK_NO
                          ,'1'                                        AS ITEM_CODE
                          ,'PJT'                                      AS MP_TENDER_BIZ_TP_CODE  --양산수주구분
                          ,MAX(B.DOMESTIC_OVERSEAS_TYPE )             AS DOMESTIC_OVERSEAS_TYPE --국내해외구분코드
                          ,MAX(A.GRADE_CODE             )             AS GRADE_CODE
                          ,MAX(A.GRADE_NAME             )             AS GRADE_NAME
                          ,MAX(B.ORG_CODE               )             AS ORG_CODE
                          ,MAX(A.START_YYYYMM           )             AS START_YYYYMM --인정기간(시작)
                          ,MAX(A.END_YYYYMM             )             AS END_YYYYMM  --인정기간(종료)
                          ,MAX(A.NEW_PROD_YN            )             AS NEW_PROD_YN --연구개발에 기간 조건없이 보여주는 화면 때문에 과거 데이터도 적재함
                          ,NULL                                       AS COUNTRY_CODE   --국가코드
                          ,0                                          AS ERP_CUSTOMER_ACCOUNT_ID   --ERP고객계정ID
                          ,0                                          AS ITEM_QTY   --매출수량
                          ,MAX(B.SALES_AMOUNT)                        AS SALES_AMOUNT
                          ,MAX(B.SALES_COST)                          AS SALES_COST
                          ,MAX(B.SALES_TOTAL_PROFIT_AMOUNT)           AS SALES_TOTAL_PROFIT_AMOUNT --매출총이익금액
                          ,MAX(A.END_EFFORT)                          AS END_EFFORT
                          ,MAX(A.SLABOR_COST)                         AS SLABOR_COST
                          ,MAX(A.TST_RSCH_COST)                       AS TST_RSCH_COST
                          ,MAX(A.ETC_EXPENSE)                         AS ETC_EXPENSE
                          ,MAX(A.DEPRN_EXPENSE)                       AS DEPRN_EXPENSE
                          ,MAX(A.DEPRN_EXPENSE_EXCLTOT)               AS DEPRN_EXPENSE_EXCLTOT
                          ,MAX(A.TOT_EXPNS)                           AS TOT_EXPNS
                      FROM (
                            SELECT PROJECT_NO
                                  ,DEPARTMENT_CODE
                                  ,PRODUCT_LINE_CODE
                                  ,ORG_CODE
                                  ,DOMESTIC_OVERSEAS_TYPE
                                  ,SUM(SALES_AMOUNT) AS SALES_AMOUNT
                                  ,SUM(SALES_COST)   AS SALES_COST
                                  ,SUM(SALES_AMOUNT - SALES_COST) AS SALES_TOTAL_PROFIT_AMOUNT
                              FROM DW_SPJ_TENDER_BIZ_SA_STAT
                             WHERE SALES_YYYYMM = @v_parm_to
                               AND PRODUCT_LINE_CODE IN ('800','850','860','875')   --배전반 , Auto System , 철도시스템 ,스카다 4개의 제품류는 RPOJECT로 집계
                               AND PROJECT_NO IN ( SELECT DISTINCT PROJECT_NO FROM INPUP_COST)
                               AND ORG_CODE IN ('M02','M04','M07','M08')
                               --AND PROJECT_NO = '711410073'
                             GROUP BY PROJECT_NO
                                  ,DEPARTMENT_CODE
                                  ,PRODUCT_LINE_CODE
                                  ,ORG_CODE
                                  ,DOMESTIC_OVERSEAS_TYPE
                           ) B
                      LEFT OUTER 
                      JOIN INPUP_COST A
                        ON A.ORG_CODE = B.ORG_CODE
                       AND A.PROJECT_NO = B.PROJECT_NO
                     WHERE A.RND_PJT_CODE IS NOT NULL
                     GROUP BY B.PROJECT_NO
                          ,A.RND_PJT_CODE
                    */
                   ) A
              JOIN T_DIM_FND_COM_PROD_LN B
                ON A.PRODUCT_LINE_CODE = B.PRODUCT_LINE_CODE
			   AND A.ORG_CODE = B.ORG_CODE
              JOIN T_DIM_FND_COM_ORGANIZATION C
                ON A.DEPARTMENT_CODE = C.DEPARTMENT_CODE
            ;

            MERGE [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT] A
            USING (
                   SELECT A.YYYYMM
                         ,A.ITEM_CODE
                         ,A.RND_PJT_NO
                         ,A.DEPARTMENT_CODE
                         ,A.DOMESTIC_OVERSEAS_TYPE
                         ,A.ERP_CUSTOMER_ACCOUNT_ID
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.ITEM_QTY
                          END                                                                            AS ITEM_QTY
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.SALES_AMOUNT
                          END                                                                            AS SALES_AMOUNT
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.SALES_COST
                          END                                                                            AS SALES_COST
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.SALES_TOTAL_PROFIT_AMOUNT
                          END                                                                            AS SALES_TOTAL_PROFIT_AMOUNT
                         ,DATEADD(HOUR, 9 ,GETDATE())                                                    AS ETL_DT    
                     FROM [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT] A
                     JOIN (
                           SELECT YYYYMM
                                 ,ITEM_CODE
                                 ,DEPARTMENT_CODE
                                 ,DOMESTIC_OVERSEAS_TYPE
                                 ,ERP_CUSTOMER_ACCOUNT_ID
                                 ,SUM(CAST(TOT_EXPNS AS FLOAT))                                          AS TOT_EXPNS
                                 ,COUNT(DISTINCT RND_PJT_NO)                                             AS CNT
                             FROM [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT] A
                            WHERE YYYYMM = @v_parm_to
            --                  AND    NEW_PROD_YN ='Y'
                              AND MP_TENDER_BIZ_TP_CODE = 'MFG'
            --                  AND    ITEM_CODE ='67110148'
                              AND SALES_AMOUNT IS NOT NULL
                            GROUP BY YYYYMM
                                 ,ITEM_CODE
                                 ,DEPARTMENT_CODE
                                 ,DOMESTIC_OVERSEAS_TYPE
                                 ,ERP_CUSTOMER_ACCOUNT_ID
                           HAVING COUNT(DISTINCT RND_PJT_NO) > 1
                          ) B
                       ON A.YYYYMM = B.YYYYMM
                      AND A.DEPARTMENT_CODE = B.DEPARTMENT_CODE
                      AND A.ITEM_CODE = B.ITEM_CODE
                      AND A.DOMESTIC_OVERSEAS_TYPE = B.DOMESTIC_OVERSEAS_TYPE
                      AND A.ERP_CUSTOMER_ACCOUNT_ID = B.ERP_CUSTOMER_ACCOUNT_ID
                    WHERE A.YYYYMM = @v_parm_to
                  ) B
               ON (A.YYYYMM = B.YYYYMM
              AND A.ITEM_CODE = B.ITEM_CODE
              AND A.RND_PJT_NO = B.RND_PJT_NO
              AND A.DEPARTMENT_CODE = B.DEPARTMENT_CODE
              AND A.DOMESTIC_OVERSEAS_TYPE = B.DOMESTIC_OVERSEAS_TYPE
              AND A.ERP_CUSTOMER_ACCOUNT_ID = B.ERP_CUSTOMER_ACCOUNT_ID)
             WHEN MATCHED THEN
             UPDATE SET A.SALES_AMOUNT = B.SALES_AMOUNT
                       ,A.SALES_COST = B.SALES_COST
                       ,A.SALES_TOTAL_PROFIT_AMOUNT = B.SALES_TOTAL_PROFIT_AMOUNT
                       ,A.ITEM_QTY = B.ITEM_QTY
                       ,A.ETL_DT = B.ETL_DT
            ;

            --PROJECT로 집계하는 과제중에 하나의 TASK가 여러개의 R&D 프로젝트에 투입됐을때 매출액과 영업이익을 총 비용 배부률로 UPDATE
            MERGE [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT] A
            USING (
                   SELECT A.YYYYMM
                         ,A.PROJECT_NO
                         ,A.RND_PJT_NO
                         ,A.TASK_CODE
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.ITEM_QTY
                          END                                                                                           AS ITEM_QTY
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.SALES_AMOUNT
                          END                                                                                           AS SALES_AMOUNT
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.SALES_COST
                          END                                                                                           AS SALES_COST
                         ,CASE WHEN A.TOT_EXPNS = 0 THEN 0
                               ELSE CASE WHEN B.TOT_EXPNS = 0 THEN 0
                                         ELSE A.TOT_EXPNS / B.TOT_EXPNS
                                    END * A.SALES_TOTAL_PROFIT_AMOUNT
                          END                                                                                           AS SALES_TOTAL_PROFIT_AMOUNT
                         ,DATEADD(HOUR, 9 ,GETDATE())                                                                   AS ETL_DT
                     FROM [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT] A
                     JOIN (
                           SELECT YYYYMM
                                 ,PROJECT_NO
                                 ,TASK_CODE
                                 ,SUM(CAST(TOT_EXPNS AS FLOAT))                                                         AS TOT_EXPNS
                                 ,COUNT(DISTINCT RND_PJT_NO)                                                            AS CNT
                             FROM [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT]
                            WHERE YYYYMM = @v_parm_to
                              AND MP_TENDER_BIZ_TP_CODE = 'PJT'
                              AND SALES_AMOUNT <> 0
                              AND SALES_AMOUNT IS NOT NULL
                              --AND    PROJECT_NO ='421510056'
                            GROUP BY YYYYMM
                                 ,PROJECT_NO
                                 ,TASK_CODE
                           HAVING    COUNT(DISTINCT RND_PJT_NO) > 1
                          ) B
                       ON A.YYYYMM = B.YYYYMM
                      AND A.PROJECT_NO = B.PROJECT_NO
                      AND A.TASK_CODE = B.TASK_CODE
                    WHERE A.YYYYMM = @v_parm_to
                  ) B
               ON (A.YYYYMM = B.YYYYMM
              AND A.PROJECT_NO = B.PROJECT_NO
              AND A.RND_PJT_NO = B.RND_PJT_NO
              AND A.TASK_CODE = B.TASK_CODE)
             WHEN MATCHED THEN
             UPDATE SET A.SALES_AMOUNT = B.SALES_AMOUNT
                       ,A.SALES_COST = B.SALES_COST
                       ,A.SALES_TOTAL_PROFIT_AMOUNT = B.SALES_TOTAL_PROFIT_AMOUNT
                       ,A.ITEM_QTY = B.ITEM_QTY
                       ,A.ETL_DT = B.ETL_DT
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EOM_SCO_NEW_PRD_SA_STAT]
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

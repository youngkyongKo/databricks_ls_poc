CREATE PROC [dbo].[SP_T_DW_EOM_SPJ_TENDER_BIZ_SA_STAT_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS

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

        SET @v_run_pgm = 'SP_T_DW_EOM_SPJ_TENDER_BIZ_SA_STAT_M_C'
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

            DELETE FROM [dbo].[T_DW_EOM_SPJ_TENDER_BIZ_SA_STAT] WHERE SALES_YYYYMM = @v_parm_to
            ;            
            
            INSERT INTO [dbo].[T_DW_EOM_SPJ_TENDER_BIZ_SA_STAT]
            (
                   [SALES_YYYYMM]                                                --매출년월
                  ,[PROJECT_ID]                                                  --프로젝트ID
                  ,[TASK_ID]                                                     --태스크ID
                  ,[ORG_CODE]                                                    --ORG코드
                  ,[DEPARTMENT_CODE]                                             --부서코드
                  ,[EMPLOYEE_ID]                                                 --사원ID
                  ,[PROJECT_NO]                                                  --프로젝트번호
                  ,[PROJECT_NAME]                                                --프로젝트명
                  ,[TASK_NO]                                                     --태스크번호
                  ,[PRODUCT_LINE_CODE]                                           --제품류코드
                  ,[DOMESTIC_OVERSEAS_TYPE]                                      --국내해외구분코드
                  ,[PROJECT_TYPE_CODE]                                           --프로젝트유형코드
                  ,[CUSTOMER_ID]                                                 --고객ID
                  ,[CURRENCY_CODE]                                               --통화코드
                  ,[CONTRACT_YYYYMMDD]                                           --계약년월일
                  ,[DUE_YYYYMMDD]                                                --납기년월일
                  ,[PROJECT_STATUS_CODE]                                         --프로젝트상태코드
                  ,[NEW_PRODUCT_FLAG]                                            --신제품여부
                  ,[NEW_PRODUCT_START_YYYYMMDD]                                  --신제품시작년월일
                  ,[CONTRACT_TYPE_CODE]                                          --계약유형코드
                  ,[END_USER_TYPE_CODE]                                          --최종사용자유형코드
                  ,[END_USER_CONTENT]                                            --최종사용자내용
                  ,[MARKET_SEGMENT]                                              --시장세그먼트
                  ,[TENDER_BIZ_AMOUNT]                                           --수주금액
                  ,[FRN_CUR_TENDER_BIZ_AMOUNT]                                   --외화수주금액
                  ,[TENDER_BIZ_COST]                                             --수주원가
                  ,[TENDER_BIZ_MATERIAL_COST]                                    --수주재료비
                  ,[TARGET_COST]                                                 --목표원가
                  ,[ACCUMULATED_SALES_AMOUNT]                                    --누적매출금액
                  ,[SALES_AMOUNT]                                                --매출금액
                  ,[USD_CONVERSION_SALES_AMOUNT]                                 --달러환산매출금액
                  ,[USD_CONV_ACCU_SA_AMOUNT]                                     --달러환산누적매출금액
                  ,[FOREIGN_CURRENCY_SALES_AMOUNT]                               --외화매출금액
                  ,[TENDER_BIZ_BALANCE]                                          --수주잔액
                  ,[INPUT_COST]                                                  --투입원가
                  ,[MANUFACTURING_COST]                                          --제조원가
                  ,[SALES_COST]                                                  --매출원가
                  ,[ACCUMULATED_INPUT_COST]                                      --누적투입원가
                  ,[ACCU_MFG_COST]                                               --누적제조원가
                  ,[ACCUMULATED_SALES_COST]                                      --누적매출원가
                  ,[ETL_DT]                                                      --적재일시
            )
            SELECT DISTINCT K.GL_YYYYMM                                                              AS SALES_YYYYMM             --매출년월
                  ,A.PROJECT_ID                                                                      AS PROJECT_ID               --프로젝트ID
                  ,E.TASK_ID                                                                         AS TASK_ID                  --태스크ID
                  ,CASE WHEN A.CARRYING_OUT_ORGANIZATION_ID IS NULL THEN  'z{'
                        WHEN N.ORG_ID IS NULL THEN 'z~'
                        ELSE N.ORG_CODE
                   END                                                                               AS ORG_CODE                 --ORG코드
                  ,I.DEPT_CODE                                                                       AS DEPARTMENT_CODE          --부서코드
                  ,J.PERSON_ID                                                                       AS EMPLOYEE_ID              --사원ID
                  ,A.SEGMENT1                                                                        AS PROJECT_NO               --프로젝트번호
                  ,A.LONG_NAME                                                                       AS PROJECT_NAME             --프로젝트명
                  ,E.TASK_NUMBER                                                                     AS TASK_NO                  --태스크번호
                  ,ISNULL(L.SEGMENT_VALUE, 'z{')                                                     AS PRODUCT_LINE_CODE        --제품류코드
                  ,CASE WHEN A.PROJECT_TYPE = 'Local export' THEN 'E'
                        WHEN A.PROJECT_TYPE = 'Direct export' THEN 'E'
                        ELSE 'D'
                   END                                                                               AS DOMESTIC_OVERSEAS_TYPE   --국내해외구분코드
                  ,A.PROJECT_TYPE                                                                    AS PROJECT_TYPE_CODE        --프로젝트유형코드
                  ,B.CUSTOMER_ID                                                                     AS CUSTOMER_ID              --고객ID
                  ,B.INV_CURRENCY_CODE                                                               AS CURRENCY_CODE            --통화코드
                  ,FORMAT(CAST(SUBSTRING(A.SEGMENT2,1,10) AS DATE),'yyyyMMdd')                       AS CONTRACT_YYYYMMDD        --계약년월일
                  ,FORMAT(CAST(SUBSTRING(A.ATTRIBUTE5,1,10) AS DATE),'yyyyMMdd')                     AS DUE_YYYYMMDD             --납기년월일
                  ,A.PROJECT_STATUS_CODE                                                             AS PROJECT_STATUS_CODE      --프로젝트상태코드
                  ,CASE WHEN K.GL_YYYYMM BETWEEN FORMAT(F.NEW_ITEM_DATE_FROM, 'yyyyMM')
                                             AND FORMAT(F.NEW_ITEM_DATE_TO, 'yyyyMM') THEN 'Y'
                        ELSE 'N'
                   END                                                                               AS NEW_PRODUCT_FLAG              --신제품여부
                  ,FORMAT(F.NEW_ITEM_DATE_FROM, 'yyyyMMdd')                                          AS NEW_PRODUCT_START_YYYYMMDD    --신제품시작년월일
                  ,A.ATTRIBUTE2                                                                      AS CONTRACT_TYPE_CODE            --계약유형코드
                  ,A.SEGMENT4                                                                        AS END_USER_TYPE_CODE            --최종사용자유형코드
                  ,A.ATTRIBUTE8                                                                      AS END_USER_CONTENT              --최종사용자내용
                  ,A.SEGMENT5                                                                        AS MARKET_SEGMENT                --시장세그먼트
                  ,ROUND(ISNULL(G.AR_AMOUNT, 0 ) ,4)                                                 AS TENDER_BIZ_AMOUNT             --수주금액
                  ,ROUND(ISNULL(G.FRN_CUR_AR_AMOUNT, 0 ) ,4)                                         AS FRN_CUR_TENDER_BIZ_AMOUNT     --외화기준수주가
                  ,ROUND(ISNULL(G.FC_MATERIAL, 0 ) + ISNULL(G.FC_MFG, 0),4)                          AS TENDER_BIZ_COST               --수주원가
                  ,ROUND(ISNULL(G.FC_MATERIAL, 0 ) ,4)                                               AS TENDER_BIZ_MATERIAL_COST      --수주재료비
                  ,ROUND(ISNULL(G.AC_MATERIAL, 0 ) + ISNULL(G.AC_MFG, 0) ,4)                         AS TARGET_COST                   --목표원가
                  ,ROUND(ISNULL(K.REV_AMOUNT, 0),4)                                                  AS ACCUMULATED_SALES_AMOUNT      --누적매출금액
                  ,ROUND(K.REV_YYYYMM_AMOUNT,4)                                                      AS SALES_AMOUNT                  --당월매출
                  ,ROUND(K.TO_USD_REV_YYYYMM_AMOUNT ,4)                                              AS USD_CONVERSION_SALES_AMOUNT   --달러환산매출금액
                  ,ROUND(K.TO_USD_REV_AMOUNT ,4)                                                     AS USD_CONV_ACCU_SA_AMOUNT       --달러환산누계매출금액
                  ,ROUND(ISNULL( O.FN_CUR_SALES, 0) ,4)                                              AS FOREIGN_CURRENCY_SALES_AMOUNT --외화기준누계매출금액
                  ,ROUND(ISNULL( G.AR_AMOUNT, 0 )-ISNULL(K.REV_AMOUNT, 0),4)                         AS TENDER_BIZ_BALANCE            --수주잔
                  ,ROUND(H.AMOUNT1 ,4)                                                               AS INPUT_COST                    --투입원가
                  ,ROUND(H.AMOUNT2 ,4)                                                               AS MANUFACTURING_COST            --제조원가
                  ,ROUND(H.AMOUNT3+ISNULL(P.OR_LOSS,0) ,4)                                           AS SALES_COST                    --매출원가 -- 20200609 orloss값 추가(기능개선:322646)
                  ,ROUND(H.ACC_AMOUNT1,4)                                                            AS ACCUMULATED_INPUT_COST        --누계투입원가
                  ,ROUND(H.ACC_AMOUNT2,4)                                                            AS ACCU_MFG_COST                 --누계제조원가
                  ,ROUND(H.ACC_AMOUNT3,4)                                                            AS ACCUMULATED_SALES_COST        --누계매출원가
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                       AS ETL_DT                        --적재일시
              FROM ERPSYS.ERP_PA_PROJECTS_ALL A
              JOIN ERPSYS.ERP_PA_PROJ_CUSTOMERS B
                ON A.PROJECT_ID = B.PROJECT_ID
               AND A.TEMPLATE_FLAG = 'N'
               AND A.ORG_ID = 89
              JOIN ERPSYS.ERP_PA_PROJECT_CLASSES C
                ON A.PROJECT_ID = C.PROJECT_ID
              JOIN ERPSYS.ERP_PA_PROJECT_STATUSES D
                ON A.PROJECT_STATUS_CODE = D.PROJECT_STATUS_CODE
              JOIN ERPSYS.ERP_PA_TASKS E
                ON A.PROJECT_ID = E.PROJECT_ID
              LEFT OUTER
              JOIN ERPSYS.ERP_EPA_TASK_NEW_ITEMS F
                ON E.PROJECT_ID  = F.PROJECT_ID
               AND E.TASK_ID     = F.TASK_ID
              LEFT OUTER
              JOIN (
                    SELECT A1.PROJECT_ID
                          ,A1.TASK_ID
                          ,SUM(ISNULL(CASE WHEN C1.BUDGET_TYPE_CODE = 'AR' THEN B1.REVENUE
                                           ELSE NULL
                                      END,0))                                                                       AS AR_AMOUNT
            
                          ,SUM(ISNULL(CASE WHEN C1.BUDGET_TYPE_CODE = 'AR' THEN ISNULL(CAST(B1.ATTRIBUTE2 AS FLOAT),0)
                                           ELSE NULL
                                      END,0))                                                                       AS FRN_CUR_AR_AMOUNT -- 외화 기준
                          ,SUM(ISNULL(CASE WHEN C1.BUDGET_TYPE_CODE = 'FC' THEN CASE WHEN D1.ALIAS = 'M_Imported material' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'M_Domestic material' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'M_Internal material' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'M_Outsourcing material' THEN B1.RAW_COST
                                                                                     ELSE NULL
                                                                                END
                                           ELSE NULL
                                      END,0))                                                                       AS FC_MATERIAL
                          ,SUM(ISNULL(CASE WHEN C1.BUDGET_TYPE_CODE = 'FC' THEN CASE WHEN D1.ALIAS = 'Resource cost' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'Overhead cost' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'Individual cost' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'Engineering direct cost' THEN B1.RAW_COST
                                                                                     ELSE NULL
                                                                                END
                                           ELSE NULL
                                      END,0))                                                                       AS FC_MFG
                          ,SUM(ISNULL(CASE WHEN C1.BUDGET_TYPE_CODE = 'AC' THEN CASE WHEN D1.ALIAS = 'M_Imported material' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'M_Domestic material' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'M_Internal material' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'M_Outsourcing material' THEN B1.RAW_COST
                                                                                     ELSE NULL
                                                                                END
                                           ELSE NULL
                                      END,0))                                                                       AS AC_MATERIAL
                          ,SUM(ISNULL(CASE WHEN C1.BUDGET_TYPE_CODE = 'AC' THEN CASE WHEN D1.ALIAS = 'Resource cost' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'Overhead cost' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'Individual cost' THEN B1.RAW_COST
                                                                                     WHEN D1.ALIAS = 'Engineering direct cost' THEN B1.RAW_COST
                                                                                     ELSE NULL
                                                                                END
                                           ELSE NULL
                                      END,0))                                                                       AS AC_MFG
                      FROM ERPSYS.ERP_PA_RESO_ASSIGNMENTS       A1
                      JOIN ERPSYS.ERP_PA_BUDGET_LINES           B1
                        ON A1.RESOURCE_ASSIGNMENT_ID  = B1.RESOURCE_ASSIGNMENT_ID
                      JOIN ERPSYS.ERP_PA_BUDGET_VERSIONS        C1
                        ON A1.BUDGET_VERSION_ID = C1.BUDGET_VERSION_ID
                       AND C1.BUDGET_STATUS_CODE = 'B'
                       AND C1.CURRENT_FLAG       = 'Y'
                       AND C1.BUDGET_TYPE_CODE IN ( 'AR', 'FC', 'AC' )
                      JOIN ERPSYS.ERP_PA_RESO_LIST_MEMBER       D1
                        ON A1.RESOURCE_LIST_MEMBER_ID = D1.RESOURCE_LIST_MEMBER_ID
                     GROUP BY A1.PROJECT_ID
                          ,A1.TASK_ID
                   ) G
                ON E.PROJECT_ID  = G.PROJECT_ID
               AND E.TASK_ID     = G.TASK_ID
              LEFT OUTER
              JOIN (
                    SELECT D.PROJECT_ID
                          ,E.TASK_ID
                          ,SUM(CASE WHEN A.PJT_COST_TYPE = 1 THEN CASE WHEN YYYYMM = @v_parm_to THEN AMOUNT
                                                                       ELSE 0
                                                                  END
                                    ELSE 0
                               END)                                                                                          AS AMOUNT1
                          ,SUM(CASE WHEN A.PJT_COST_TYPE = 2 THEN CASE WHEN YYYYMM = @v_parm_to THEN AMOUNT
                                                                       ELSE 0
                                                                  END
                                    ELSE 0
                               END)                                                                                          AS AMOUNT2
                          ,SUM(CASE WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END IN ('A01','A08') THEN AMOUNT --재료비
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A02'       THEN AMOUNT --부대비
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A03'       THEN AMOUNT --공정중외주
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A07'       THEN AMOUNT --공용재
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A00'       THEN AMOUNT --기타재료비
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'B01'       THEN AMOUNT --제조직접비
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C01'       THEN AMOUNT --L-설계(PTE)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C03'       THEN AMOUNT --L-용역비(PTE)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C04'       THEN AMOUNT --L-A/S비(PTE)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C05'       THEN AMOUNT --L-시험운전비(PTE)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D01'       THEN AMOUNT --R-OH
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D05'       THEN AMOUNT --L-공장공통(PTE)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D07'       THEN AMOUNT --L-지원공통(PTE)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D10'       THEN AMOUNT --E-GL Variance
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D00'       THEN AMOUNT --제조간접비기타
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'E01'       THEN AMOUNT --노무비(72계정)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'E02'       THEN AMOUNT --경비(73계정)
                                    WHEN A.YYYYMM = @v_parm_to AND A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'E03'       THEN AMOUNT --관세환급비
                                    ELSE 0
                               END)                                                                                          AS AMOUNT3
                          ,SUM(CASE WHEN A.PJT_COST_TYPE = 1 THEN AMOUNT ELSE 0 END)                                         AS ACC_AMOUNT1
                          ,SUM(CASE WHEN A.PJT_COST_TYPE = 2 THEN AMOUNT ELSE 0 END)                                         AS ACC_AMOUNT2
                          ,SUM(CASE WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END IN ('A01','A08') THEN AMOUNT --재료비
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A02'       THEN AMOUNT --부대비
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A03'       THEN AMOUNT --공정중외주
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A07'       THEN AMOUNT --공용재
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'A00'       THEN AMOUNT --기타재료비
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'B01'       THEN AMOUNT --제조직접비
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C01'       THEN AMOUNT --L-설계(PTE)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C03'       THEN AMOUNT --L-용역비(PTE)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C04'       THEN AMOUNT --L-A/S비(PTE)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'C05'       THEN AMOUNT --L-시험운전비(PTE)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D01'       THEN AMOUNT --R-OH
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D05'       THEN AMOUNT --L-공장공통(PTE)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D07'       THEN AMOUNT --L-지원공통(PTE)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D10'       THEN AMOUNT --E-GL Variance
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'D00'       THEN AMOUNT --제조간접비기타
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'E01'       THEN AMOUNT --노무비(72계정)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'E02'       THEN AMOUNT --경비(73계정)
                                    WHEN A.PJT_COST_TYPE = 4 AND A.CATEGORY_DISP_ORDER + CASE WHEN A.CATEGORY_DISP_ORDER = 'A' THEN CASE WHEN A.TYPE_DISP_ORDER = '11' THEN '07' WHEN A.TYPE_DISP_ORDER = '12' THEN '08' ELSE A.TYPE_DISP_ORDER END ELSE A.TYPE_DISP_ORDER END = 'E03'       THEN AMOUNT --관세환급비
                                    ELSE 0
                               END) AS ACC_AMOUNT3
                      FROM ERPSYS.ERP_ECST_PROJECT_COSTS      A
                      JOIN ERPSYS.ERP_EORG_ORGA_DEFI_V        B
                        ON A.ORG_ID =  B.OPERATING_UNIT
                       AND A.ORGANIZATION_ID = B.ORGANIZATION_ID
                       AND B.ORGANIZATION_CODE IN ('M02','M04','M07','M08','M11') -- 자동화분리운영ORG추가 20201208
                      JOIN ERPSYS.ERP_PA_PROJECT_CLASSES          C
                        ON A.PROJECT_ID = C.PROJECT_ID
                      JOIN ERPSYS.ERP_PA_PROJECTS_ALL             D
                        ON A.PROJECT_ID = D.PROJECT_ID
                       AND D.SEGMENT1 NOT LIKE 'COM%'
                      JOIN ERPSYS.ERP_PA_TASKS                    E
                        ON A.TASK_ID = E.TASK_ID
                      LEFT OUTER
                      JOIN ERPSYS.ERP_PA_PROJ_CUSTOMERS  F
                        ON A.PROJECT_ID = F.PROJECT_ID
                     WHERE A.YYYYMM <= @v_parm_to
                       AND A.PJT_COST_TYPE IN (1,2,4)
                       AND A.YYYYMM >= '201407'
                       AND D.SEGMENT1 NOT IN (
                                              SELECT TRIM(DATA_NAME_1)
                                                FROM T_EIS_DYNA_HAND_FLAG_INPUT A           
                                               WHERE REQUEST_ITEM_CODE ='GEN053'
                                             )
                     GROUP BY D.PROJECT_ID
                          ,E.TASK_ID
                   ) H
                ON E.PROJECT_ID  = H.PROJECT_ID
               AND E.TASK_ID     = H.TASK_ID
              JOIN ERPSYS.ERP_EPA_ORG_FOR_SALES_V I
                ON 1=1
              JOIN (
                    SELECT PROJECT_ID
                          ,PERSON_ID
                      FROM (
                            SELECT RANK() OVER (PARTITION BY PROJECT_ID  ORDER BY START_DATE_ACTIVE DESC) RANK
                                  ,PROJECT_ID
                                  ,PERSON_ID
                              FROM ERPSYS.ERP_PA_PROJ_PLAYERS_V
                             WHERE PROJECT_ROLE_TYPE  = 'PROJECT MANAGER'
                               AND @v_parm_to BETWEEN ISNULL(FORMAT(CASE WHEN START_DATE_ACTIVE LIKE '1900%' THEN NULL
                                                                         ELSE START_DATE_ACTIVE
                                                                    END,'yyyyMM'), @v_parm_to)
                                                  AND ISNULL(FORMAT(CASE WHEN END_DATE_ACTIVE LIKE '1900%' THEN NULL
                                                                         ELSE END_DATE_ACTIVE
                                                                    END, 'yyyyMM'), @v_parm_to)
                           ) AA
                     WHERE RANK = 1
                   ) J
                ON I.SALES_PERSON_ID = J.PERSON_ID
               AND J.PROJECT_ID = A.PROJECT_ID
              JOIN (
                    SELECT A1.GL_YYYYMM
                          ,A1.PROJECT_ID
                          ,A1.TASK_ID
                          ,SUM(A1.REV_AMOUNT)                                                                AS REV_AMOUNT
                          ,SUM(A1.TO_USD_REV_AMOUNT )                                                        AS TO_USD_REV_AMOUNT
                          ,SUM(A1.REV_YYYYMM_AMOUNT )                                                        AS REV_YYYYMM_AMOUNT
                          ,SUM(A1.TO_USD_REV_YYYYMM_AMOUNT )                                                 AS TO_USD_REV_YYYYMM_AMOUNT
                      FROM (
                            SELECT @v_parm_to                                                                AS GL_YYYYMM
                                  ,A2.PROJECT_ID                                                             AS PROJECT_ID
                                  ,A2.TASK_ID                                                                AS TASK_ID
                                  ,0                                                                         AS DUMMY
                                  ,0                                                                         AS REV_AMOUNT
                                  ,0                                                                         AS TO_USD_REV_AMOUNT
                                  ,0                                                                         AS REV_YYYYMM_AMOUNT
                                  ,0                                                                         AS TO_USD_REV_YYYYMM_AMOUNT
                              FROM ERPSYS.ERP_PA_RESO_ASSIGNMENTS       A2
                                 , ERPSYS.ERP_PA_BUDGET_VERSIONS        B2
                             WHERE A2.BUDGET_VERSION_ID       = B2.BUDGET_VERSION_ID
                               AND B2.BUDGET_STATUS_CODE      = 'B'
                               AND B2.CURRENT_FLAG             = 'Y'
                               AND B2.BUDGET_TYPE_CODE        IN ( 'AR', 'FC', 'AC' )
                             GROUP BY A2.PROJECT_ID
                                  ,A2.TASK_ID
                             UNION ALL
                            SELECT @v_parm_to                                                                AS  GL_YYYYMM
                                  ,A2.PROJECT_ID PROJECT_ID
                                  ,A2.TASK_ID TASK_ID
                                  ,0
                                  ,SUM(ISNULL(A2.FUNCTIONAL_REV,0))
                                  ,SUM(ISNULL(A2.FUNCTIONAL_REV,0) * B2.CONVERSION_RATE)
                                  ,0
                                  ,0
                              FROM ERPSYS.ERP_EPA_PRO_REVENUE_V A2
                              LEFT OUTER
                              JOIN (
                                    SELECT CONVERSION_DATE
                                          ,CONVERSION_RATE
                                      FROM ERPSYS.ERP_GL_DAILY_RATES_V
                                     WHERE STATUS_CODE           != 'D'
                                       AND USER_CONVERSION_TYPE   = 'Corporate'
                                       AND FROM_CURRENCY         = 'KRW'
                                       AND TO_CURRENCY           = 'USD'
                                   ) B2
                                ON A2.GL_DATE = B2.CONVERSION_DATE
                             WHERE FORMAT(A2.GL_DATE,'yyyyMM' ) <= @v_parm_to
                             GROUP BY A2.PROJECT_ID
                                  ,A2.TASK_ID
                             UNION ALL
                            SELECT FORMAT( A2.GL_DATE,'yyyyMM' )                                             AS GL_YYYYMM
                                  ,A2.PROJECT_ID                                                             AS PROJECT_ID
                                  ,A2.TASK_ID                                                                AS TASK_ID
                                  ,0
                                  ,0
                                  ,0
                                  ,SUM(ISNULL(FUNCTIONAL_REV,0))
                                  ,SUM(ISNULL(FUNCTIONAL_REV,0)*B2.CONVERSION_RATE)
                              FROM ERPSYS.ERP_EPA_PRO_REVENUE_V A2
                              LEFT OUTER
                              JOIN (
                                    SELECT CONVERSION_DATE
                                          ,CONVERSION_RATE
                                      FROM ERPSYS.ERP_GL_DAILY_RATES_V
                                     WHERE STATUS_CODE          != 'D'
                                       AND USER_CONVERSION_TYPE = 'Corporate'
                                       AND FROM_CURRENCY        = 'KRW'
                                       AND TO_CURRENCY          = 'USD'
                                   ) B2
                                ON A2.GL_DATE = B2.CONVERSION_DATE
                             WHERE FORMAT(A2.GL_DATE,'yyyyMM' ) = @v_parm_to
                             GROUP BY FORMAT( A2.GL_DATE,'yyyyMM' )
                                  ,A2.PROJECT_ID
                                  ,A2.TASK_ID
                            ) A1
                      GROUP BY A1.GL_YYYYMM
                           ,A1.PROJECT_ID
                           ,A1.TASK_ID
                   ) K
                ON E.PROJECT_ID  = K.PROJECT_ID
               AND E.TASK_ID     = K.TASK_ID
              LEFT OUTER
              JOIN ERPSYS.ERP_PA_SEGMENT_VALUE L
                ON C.CLASS_CODE = L.SEGMENT_VALUE_LOOKUP
              LEFT OUTER
              JOIN T_DIM_FND_COM_ORG N
                ON A.CARRYING_OUT_ORGANIZATION_ID = N.ORG_ID
            --     ,    BIS_MGR.OD_ERP_PA_PROJECT_TYPES  M
              LEFT OUTER
              JOIN (
                    SELECT PROJECT_ID
                          ,TASK_ID
                          ,SUM( ISNULL( FN_CUR_SALES, 0 ) )                                                  AS FN_CUR_SALES
                      FROM (
                            SELECT A2.PROJECT_ID                                                             AS PROJECT_ID
                                  ,A2.TASK_ID                                                                AS TASK_ID
                                  ,0                                                                         AS DUMMY
                                  ,0                                                                         AS FN_CUR_SALES
                              FROM ERPSYS.ERP_PA_RESO_ASSIGNMENTS A2
                              JOIN ERPSYS.ERP_PA_BUDGET_VERSIONS  B2
                                ON A2.BUDGET_VERSION_ID       = B2.BUDGET_VERSION_ID
                               AND B2.BUDGET_STATUS_CODE      = 'B'
                               AND B2.CURRENT_FLAG            = 'Y'
                               AND B2.BUDGET_TYPE_CODE        IN ( 'AR', 'FC', 'AC' )
                             GROUP BY A2.PROJECT_ID
                                  ,A2.TASK_ID
                             UNION ALL
                            SELECT A2.PROJECT_ID
                                  ,A2.TASK_ID
                                  ,0
                                  ,ISNULL(SUM(CAST(A2.ATTRIBUTE1 AS FLOAT)),0)                               AS FN_CUR_SALES
                              FROM ERPSYS.ERP_PA_EVENTS           A2
                              JOIN ERPSYS.ERP_PA_CUST_EVENT_RDL   C2
                                ON A2.EVENT_NUM  = C2.EVENT_NUM
                               AND A2.PROJECT_ID = C2.PROJECT_ID
                               AND A2.TASK_ID    = C2.TASK_ID
                               AND A2.REVENUE_DISTRIBUTED_FLAG = 'Y'
                              JOIN ERPSYS.ERP_PA_DRAFT_REVENUES   B2
                                ON B2.PROJECT_ID        = C2.PROJECT_ID
                               AND B2.DRAFT_REVENUE_NUM = C2.DRAFT_REVENUE_NUM
                               AND B2.TRANSFER_STATUS_CODE   = 'A'
                               AND FORMAT( B2.GL_DATE , 'yyyyMM' ) <= @v_parm_to
                             GROUP BY A2.PROJECT_ID
                                  ,A2.TASK_ID
                           ) AA
                     GROUP BY PROJECT_ID
                          ,TASK_ID
                   ) O
                ON E.PROJECT_ID  = O.PROJECT_ID
               AND E.TASK_ID     = O.TASK_ID
              LEFT OUTER
              JOIN (
                    SELECT PROJECT_ID
                          ,TASK_ID
                          ,SUM(ISNULL(OR_LOSS,0))                AS OR_LOSS
                      FROM ERPSYS.ERP_ECST_PJT_COGS_ALO_V
                     WHERE YYYYMM = @v_parm_to
                     GROUP BY PROJECT_ID
                          ,TASK_ID
                   ) P  -- 20200609 orloss값 추가(기능개선:322646)
                ON E.PROJECT_ID = P.PROJECT_ID
               AND E.TASK_ID    = P.TASK_ID
              /* 2011.04.11. 신제품여부 추가 */
             WHERE N.DIVISION_CODE <> 'z{'
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EOM_SPJ_TENDER_BIZ_SA_STAT]
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

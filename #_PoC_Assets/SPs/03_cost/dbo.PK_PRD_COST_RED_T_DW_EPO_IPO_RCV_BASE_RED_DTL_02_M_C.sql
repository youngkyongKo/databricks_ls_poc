CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_RCV_BASE_RED_DTL_02_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_RCV_BASE_RED_DTL_02_M_C' -- procedure name 
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

                DELETE FROM [dbo].[T_DW_EPO_IPO_RCV_BASE_RED_DTL] 
                 WHERE BASE_YYYYMM = @v_parm_to   --파라미타 
                 ;
                
                INSERT INTO [dbo].[T_DW_EPO_IPO_RCV_BASE_RED_DTL]
                (      [BASE_YYYYMM]
                     , [ORG_CODE]
                     , [ITEM_CODE]
                     , [DEPARTMENT_CODE]
                     , [INCR_DECR_TYPE_CODE]
                     , [AGGR_STATUS_TYPE_CODE]
                     , [SERIAL_NO]
                     , [PRODUCT_LINE_CODE]
                     , [RECEIVING_TYPE_CODE]
                     , [PROCUREMENT_TYPE_CODE]
                     , [INVENTORY_TYPE_CODE]
                     , [ITEM_UNIT_CODE]
                     , [MONETARY_UNIT_CODE]
                     , [BASE_BPA_NO]
                     , [BASE_BPA_MNY_UNIT_CODE]
                     , [BASE_BPA_FRN_CUR_UNIT_PRICE]
                     , [BASE_BPA_KRW_UNIT_PRICE]
                     , [PREVIOUS_BPA_NO]
                     , [PRE_BPA_MNY_UNIT_CODE]
                     , [PRE_BPA_FRN_CUR_UNIT_PRICE]
                     , [PREVIOUS_BPA_KRW_UNIT_PRICE]
                     , [RECEIVING_BPA_NO]
                     , [RCV_BPA_MNY_UNIT_CODE]
                     , [RCV_BPA_FRN_CUR_UNIT_PRICE]
                     , [RECEIVING_BPA_KRW_UNIT_PRICE]
                     , [RECEIVING_QTY]
                     , [UNIT_PRICE_DEDUCTION_AMOUNT]
                     , [REDUCTION_AMOUNT]
                     , [PURCHASE_BPA_CONTACT]
                     , [VENDOR_CONTACT]
                     , [DISTRIBUTION_RATE]
                     , [UNIT_PRICE_REG_RSN_CODE]
                     , [UNIT_PRICE_REG_RSN_NAME]
                     , [ACTIVITY_TYPE_NAME]
                     , [PURCHASE_TOOL_NAME]
                     , [SALES_TYPE_NAME]
                     , [RECEIVING_VENDOR_NAME]
                     , [PRE_UNIT_PRICE_VNDR_NAME]
                     , [PLAN_VENDOR_NAME]
                     , [BASE_DATE]
                     , [RECEIVING_BPA_START_DATE]
                     , [PROJECT_NO]
                     , [TASK_NO]
                     , [PRODUCTION_QTY]
                     , [SALES_QTY]
                     , [ETL_DT]

                )
                SELECT A.TARGET_MONTH                                        AS BASE_YYYYMM                     -- 기준년월
                     , C.ORG_CODE                                            AS ORG_CODE                        -- ORG코드
                     , C.ITEM_CODE                                           AS ITEM_CODE                       -- 품목코드
                     , CASE WHEN C.ITEM_CODE IN ('64623586001','72313586001') THEN 'KB005' ELSE TRIM(A.TEAM) END AS DEPARTMENT_CODE --부서코드 --20160203 서광석B 요청 (원 요청자 윤상협) ODM솔루션팀(KB010) -> 고압계통솔루션팀(KB005) 사유 : 담당자 부서 이동
                     , A.UP_DAWN_GUBUN                                       AS INCR_DECR_TYPE_CODE             -- 인상인하구분코드
                     , A.C_GUBUN                                             AS AGGR_STATUS_TYPE_CODE           -- 집계상태구분코드
                     , ROW_NUMBER() OVER(ORDER BY (SELECT 1))                AS SERIAL_NO                       -- 일련번호
                     , C.PRODUCT_LINE_CODE                                   AS PRODUCT_LINE_CODE               -- 제품류코드
                     , (CASE WHEN A.RECIEPT_CURRENCY_CODE = 'KRW' THEN 'D' ELSE 'I' END) AS RECEIVING_TYPE_CODE -- 입고구분코드
                     , C.PURCHASE_TYPE_NAME                                  AS PROCUREMENT_TYPE_CODE           -- 조달구분코드
                     , C.INVENTORY_TYPE_CODE                                 AS INVENTORY_TYPE_CODE             -- 재고구분코드
                     , C.ITEM_UNIT_CODE                                      AS ITEM_UNIT_CODE                  -- 품목단위코드
                     , A.CURRENCY_CODE                                       AS MONETARY_UNIT_CODE              -- 화폐단위코드
                     , A.PLAN_BPA                                            AS BASE_BPA_NO                     -- 기준BPA번호
                     , A.PLAN_CURRENCY_CODE                                  AS BASE_BPA_MNY_UNIT_CODE          -- 기준BPA화폐단위코드
                     , A.PLAN_UNIT_PRICE                                     AS BASE_BPA_FRN_CUR_UNIT_CODE      -- 기준BPA외화단가
                     , A.PLAN_KRW_PRICE                                      AS BASE_BPA_KRW_UNIT_PRICE         -- 기준BPA원화단가
                     , A.BEFORE_BPA                                          AS PREVIOUS_BPA_NO                 -- 이전BPA번호
                     , A.BEFORE_CURRENCY_CODE                                AS PRE_BPA_MNY_UNIT_CODE           -- 이전BPA화폐단위코드
                     , A.BEFORE_UNIT_PRICE                                   AS PRE_BPA_FRN_CUR_UNIT_PRICE      -- 이전BPA외화단가
                     , A.BEFORE_KRW_PRICE                                    AS PREVIOUS_BPA_KRW_UNIT_PRICE     -- 이전BPA원화단가
                     , A.BPA                                                 AS RECEIVING_BPA_NO                -- 입고BPA번호
                     , A.RECIEPT_CURRENCY_CODE                               AS RCV_BPA_MNY_UNIT_CODE           -- 입고BPA화폐단위코드
                     , A.UNIT_PRICE                                          AS RCV_BPA_FRN_CUR_UNIT_PRICE      -- 입고BPA외화단가
                     , A.KRW_PRICE                                           AS RECEIVING_BPA_KRW_UNIT_PRICE    -- 입고BPA원화단가
                     , A.QUANTITY                                            AS RECEIVING_QTY                   -- 입고수량
                     , A.UNIT_PRICE_DIFF                                     AS UNIT_PRICE_DEDUCTION_AMOUNT     -- 단가차감금액
                     , A.AMOUNT_DIFF                                         AS REDUCTION_AMOUNT                -- 절감금액
                     , A.BUYER                                               AS PURCHASE_BPA_CONTACT            -- 구매BPA담당자
                     , A.SUPPLY_BUYER                                        AS VENDOR_CONTACT                  -- 구매처담당자
                     , A.ALLC_RATE                                           AS DISTRIBUTION_RATE               -- 배분율
                     , A.TXN_NATURE                                          AS UNIT_PRICE_REG_RSN_CODE         -- 단가등록사유코드
                     , B.DESCRIPTION                                         AS UNIT_PRICE_REG_RSN_NAME         -- 단가등록사유명
                     , B.REASON_CD                                           AS ACTIVITY_TYPE_NAME              -- 활동유형명
                     , A.PURCHASE_TOOL                                       AS PURCHASE_TOOL_NAME              -- 구매TOOL명
                     , A.SALES_TYPE                                          AS SALES_TYPE_NAME                 -- 영업형태명
                     , A.VENDOR                                              AS RECEIVING_VENDOR_NAME           -- 입고구매처명
                     , A.BEFORE_VENDOR                                       AS PRE_UNIT_PRICE_VNDR_NAME        -- 이전단가구매처명
                     , A.PLAN_VENDOR                                         AS PLAN_VENDOR_NAME                -- 계획구매처명
                     , E.LOOKUP_CODE                                         AS BASE_DATE                       -- 기준일자
                     , FORMAT(A.START_DATE,'yyyyMMdd')                       AS RECEIVING_BPA_START_DATE        -- 입고BPA시작일자
                     , NULL                                                  AS PROJECT_NO                      -- 프로젝트번호
                     , NULL                                                  AS TASK_NO                         -- 태스크번호
                     , 0                                                     AS PRODUCTION_QTY                  -- 생산수량
                     , 0                                                     AS SALES_QTY                       -- 매출수량
                     , DATEADD(HOUR, 9 ,GETDATE())                           AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V   A
            INNER JOIN (SELECT LOOKUP_CODE REASON_CD
                             , MEANING DESCRIPTION
                          FROM ERPSYS.ERP_FND_LOOKUP_VALUES
                         WHERE LOOKUP_TYPE = 'TRANSACTION REASON'
                       ) B
                    ON A.TXN_NATURE = CAST( RIGHT(B.REASON_CD, 2) AS INT )
            INNER JOIN T_DIM_FND_COM_ITEM      C
                    ON A.ORGANIZATION_CODE =  C.ORG_CODE
                   AND A.ITEM =  C.ITEM_CODE
            INNER JOIN T_DIM_FND_COM_ORG       D
                    ON A.ORGANIZATION_CODE =  D.ORG_CODE
                   AND D.OU_ID = 89
            INNER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES E
                    ON E.LOOKUP_TYPE = 'LSIS_BUSINESS_PLAN_DATE'
                   AND E.ENABLED_FLAG = 'Y'
                   AND E.MEANING = SUBSTRING(A.TARGET_MONTH,1,4)
                 WHERE A.TARGET_MONTH = @v_parm_to   --파라미타 
                 ;
                 

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_RCV_BASE_RED_DTL]
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

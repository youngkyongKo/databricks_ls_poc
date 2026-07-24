CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_MTL_USAGE_STATUS_DTL_15_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_MTL_USAGE_STATUS_DTL_15_M_C' -- procedure name 
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


               DELETE FROM [dbo].[T_DW_EPO_IPO_MTL_USAGE_STATUS_DTL] 
                WHERE BASE_YYYYMM = @v_parm_to     --파라미터
                ;
               
               INSERT INTO [dbo].[T_DW_EPO_IPO_MTL_USAGE_STATUS_DTL]
               (      [BASE_YYYYMM]
                    , [ORG_CODE]
                    , [ITEM_CODE]
                    , [RECEIVING_YYYYMM]
                    , [SERIAL_NO]
                    , [RED_SEQ_NO]
                    , [RAISE_TYPE]
                    , [CURRENCY_TYPE]
                    , [PRODUCT_LINE_CODE]
                    , [BASE_BPA_NO]
                    , [BPA_CURRENCY_TYPE]
                    , [BPA_UNIT_PRICE]
                    , [BASE_UNIT_PRICE]
                    , [OLD_BPA_NO]
                    , [OLD_BPA_CURRENCY_TYPE]
                    , [OLD_BPA_UNIT_PRICE]
                    , [OLD_UNIT_PRICE]
                    , [RCV_BPA_NO]
                    , [RCV_BPA_CURRENCY_TYPE]
                    , [RCV_BPA_UNIT_PRICE]
                    , [PURCHASE_TYPE]
                    , [RECEIVING_QTY]
                    , [RECEIVING_UNIT_PRICE]
                    , [USAGE_QTY]
                    , [UNIT_PRICE_DIFF]
                    , [CUST_DUTY_RATE]
                    , [INCD_COST_RATE]
                    , [BPA_BUYER_NAME]
                    , [SUPPLIER_BUYER_NAME]
                    , [DEPARTMENT_CODE]
                    , [ALLOCATION_RATE]
                    , [UNIT_PRICE_REG_REASON]
                    , [PURCHASE_TOOL]
                    , [SALES_TYPE]
                    , [VENDOR_NAME]
                    , [OLD_VENDOR_NAME]
                    , [PLAN_VENDOR_SITE_NAME]
                    , [BASE_DATE]
                    , [RCV_BPA_START_DATE]
                    , [MFG_ITEM_CODE]
                    , [MFG_TYPE]
                    , [ETL_DT]
               ) 
               SELECT /*+ LEADING(B A)  FULL(B) FULL(A)  */
                      A.BASE_YYYYMM                                                                AS BASE_YYYYMM                      --기준년월
                    , A.ORG_CODE                                                                   AS ORG_CODE                         --ORG코드
                    , A.ITEM_CODE                                                                  AS ITEM_CODE                        --품목코드
                    , A.RECEIPT_YYYYMM                                                             AS RECEIVING_YYYYMM                 --입고년월
                    , ROW_NUMBER() OVER(ORDER BY (SELECT 1))                                       AS SERIAL_NO                        --일련번호
                    , 1                                                                            AS RED_SEQ_NO                       --절감순번
                    , A.UP_DOWN                                                                    AS RAISE_TYPE                       --인상구분
                    , A.CURRENCY_CODE                                                              AS CURRENCY_TYPE                    --통화종류
                    , A.PRODUCT_LINE_CODE                                                          AS PRODUCT_LINE_CODE                --제품류코드
                    , A.PLAN_BPA                                                                   AS BASE_BPA_NO                      --기준BPA번호
                    , A.PLAN_CURRENCY                                                              AS BPA_CURRENCY_TYPE                --BPA통화종류
                    , A.PLAN_UNIT_PRICE                                                            AS BPA_UNIT_PRICE                   --BPA단가
                    , A.PLAN_UNIT_PRICE_KRW                                                        AS BASE_UNIT_PRICE                  --기준단가
                    , A.BEFORE_BPA                                                                 AS OLD_BPA_NO                       --전BPA번호
                    , A.BEFORE_CURRENCY                                                            AS OLD_BPA_CURRENCY_TYPE            --전BPA통화종류
                    , A.BEFORE_UNIT_PRICE                                                          AS OLD_BPA_UNIT_PRICE               --전BPA단가
                    , A.BEFORE_UNIT_PRICE_KRW                                                      AS OLD_UNIT_PRICE                   --전원화단가
                    , A.BPA                                                                        AS RCV_BPA_NO                       --입고BPA번호
                    , A.CURRENCY_CODE                                                              AS RCV_BPA_CURRENCY_TYPE            --입고BPA통화종류
                    , A.UNIT_PRICE                                                                 AS RCV_BPA_UNIT_PRICE               --입고_BPA단가
                    , CASE WHEN ISNULL(A.CURRENCY_CODE, 'KRW') = 'KRW' THEN N'국내' ELSE N'도입' END AS PURCHASE_TYPE                    --구매구분
                    , A.RECEIPT_QTY                                                                AS RECEIVING_QTY                    --입고량
                    , A.UNIT_PRICE_KRW                                                             AS RECEIVING_UNIT_PRICE             --입고단가
                    , A.USED_QTY                                                                   AS USAGE_QTY                        --사용량
                    , A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW                                   AS UNIT_PRICE_DIFF                  --단가차이
                    , 0                                                                            AS CUST_DUTY_RATE                   --관세율
                    , 0                                                                            AS INCD_COST_RATE                   --부대비용율
                    , (
                         SELECT /*+ LEADING(B) */
                                TOP 1 B1.FULL_NAME
                           FROM ERPSYS.ERP_PO_HEADERS_ALL A1  --96302
                     INNER JOIN ERPSYS.ERP_PER_ALL_PEOPLE_F B1  --10372
                             ON A1.AGENT_ID = B1.PERSON_ID
                            AND A1.SEGMENT1 = A.BPA 
                       )                                                                            AS BPA_BUYER_NAME                  --BPA바이어명
                    , A.BUYER                                                                       AS SUPPLIER_BUYER_NAME             --공급자바이어명
                    , A.TEAM                                                                        AS DEPARTMENT_CODE                 --부서코드
                    , A.ALLC                                                                        AS ALLOCATION_RATE                 --배부율
                    , A.REASON_DESCR                                                                AS UNIT_PRICE_REG_REASON           --단가등록사유
                    , NULL                                                                          AS PURCHASE_TOOL                   --구매TOOL
                    , NULL                                                                          AS SALES_TYPE                      --영업구분
                    , A.VENDOR                                                                      AS VENDOR_NAME                     --입고업체명
                    , A.BEFORE_VENDOR                                                               AS OLD_VENDOR_NAME                 --전임고업체명
                    , NULL                                                                          AS PLAN_VENDOR_SITE_NAME           --계획거래선명
                    , CAST(B.LOOKUP_CODE AS DATETIME)                                               AS BASE_DATE                       --기준일자
                    , C.START_DATE                                                                  AS RCV_BPA_START_DATE              --입고BPA시작일자
                    , A.END_ITEM_CODE                                                               AS MFG_ITEM_CODE                   --생산품목코드
                    , A.END_FLAG_NAME                                                               AS MFG_TYPE                        --생산구분
                    , DATEADD(HOUR, 9 ,GETDATE())                                                   AS ETL_DT                          --적재일시
                 FROM T_DW_EPO_MP_COST_RED_DETAIL A
           INNER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES B
                   ON B.MEANING = SUBSTRING(A.BASE_YYYYMM,1,4)
           INNER JOIN (
                         SELECT BPA
                              , MAX(START_DATE) AS START_DATE
                           FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V --132056
                       GROUP BY BPA
                      ) C
                   ON A.BPA = C.BPA
                WHERE A.BASE_YYYYMM  = @v_parm_to     --파라미터
                  AND B.LOOKUP_TYPE = 'LSIS_BUSINESS_PLAN_DATE'
                  AND B.ENABLED_FLAG = 'Y'
                  ;
                   
                        
           SELECT @v_load_cnt = COUNT(1)
             FROM [dbo].[T_DW_EPO_IPO_MTL_USAGE_STATUS_DTL]
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
         --SELECT @v_pgm_status, @v_load_cnt, @v_err_mesg
        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

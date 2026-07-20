CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_MP_COST_RED_DETAIL_06_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
BEGIN

    SET NOCOUNT ON

    BEGIN
        /*******************************************************************************************************
        *  PROGRAM ID    :  PK_PRD_COST_RED_T_DW_EPO_MP_COST_RED_DETAIL_06_M_C
        *  DESCRIPTION   :  부서비 절감 중 구매입고 관련 내역 적재 SP 
        *
        ********************************************************************************************************
        *  CHANGE HISTORY
        *-------------  ---------------  ---------------------  --------------------------------------------------------
        *  DATE         AUTHOR           CSR_NO                 DESCRIPTION
        *-------------  ---------------  ---------------------  --------------------------------------------------------
        *  2025-06-19   COMKDHC          SRM2505-03034          중국 법인의 사업장 데이터 추가
        ********************************************************************************************************/
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_MP_COST_RED_DETAIL_06_M_C' -- procedure name 
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

                DELETE FROM [dbo].[T_DW_EPO_MP_COST_RED_DETAIL]
                 WHERE BASE_YYYYMM  =  @v_parm_to      --파라미터
                ; 
                  
                INSERT INTO [dbo].[T_DW_EPO_MP_COST_RED_DETAIL]
                (      [BASE_YYYYMM]
                     , [ORG_ID]
                     , [ITEM_ID]
                     , [SEQ]
                     , [ORG_CODE]
                     , [ITEM_CODE]
                     , [INVENTORY_TYPE_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [END_ITEM_ID]
                     , [END_ITEM_CODE]
                     , [END_FLAG_NAME]
                     , [END_INV_TYPE_CODE]
                     , [END_PROD_LINE_CODE]
                     , [END_USED_QTY]
                     , [END_MATERIAL_COST]
                     , [RECEIPT_YYYYMM]
                     , [PLAN_BPA]
                     , [PLAN_CURRENCY]
                     , [PLAN_UNIT_PRICE]
                     , [PLAN_UNIT_PRICE_KRW]
                     , [BEFORE_BPA]
                     , [BEFORE_CURRENCY]
                     , [BEFORE_UNIT_PRICE]
                     , [BEFORE_UNIT_PRICE_KRW]
                     , [BPA]
                     , [CURRENCY_CODE]
                     , [UNIT_PRICE]
                     , [UNIT_PRICE_KRW]
                     , [RECEIPT_QTY]
                     , [USED_QTY]
                     , [ALLC_AMOUNT]
                     , [BUYER]
                     , [TEAM]
                     , [TEAM_NAME]
                     , [ALLC]
                     , [GROUP_BPA]
                     , [SEQ_NO]
                     , [CURRENCY_DF]
                     , [TRANSACTION_NATURE]
                     , [UP_DOWN]
                     , [FX_DECREASE_AMT]
                     , [FX_INCREASE_AMT]
                     , [IMP_MTL_DECR_AMOUNT]
                     , [IMP_MTL_INCR_AMOUNT]
                     , [PURCHASE_IMP_MTL_DECR_AMOUNT]
                     , [PURCHASE_IMP_MTL_INCR_AMOUNT]
                     , [DESIGN_IMP_MTL_DECR_AMOUNT]
                     , [DESIGN_IMP_MTL_INCR_AMOUNT]
                     , [DOM_MTL_DECR_AMOUNT]
                     , [DOM_MTL_INCR_AMOUNT]
                     , [PURCHAS_DOM_MTL_DECR_AMOUNT]
                     , [PURCHAS_DOM_MTL_INCR_AMOUNT]
                     , [DESIGN_DOM_MTL_DECR_AMOUNT]
                     , [DESIGN_DOM_MTL_INCR_AMOUNT]
                     , [PURCHASE_DECREASE_AMOUNT]
                     , [PURCHASE_INCREASE_AMOUNT]
                     , [DESIGN_DECREASE_AMOUNT]
                     , [DESIGN_INCREASE_AMOUNT]
                     , [LME_AFFC_AMOUNT]
                     , [VENDOR]
                     , [BEFORE_VENDOR]
                     , [REASON_DESCR]
                     , [BPA_COMMENTS]
                     , [ETL_DT]
                )
                SELECT A.YYYYMM                                                                          -- 기준년월
                     , A.ORGANIZATION_ID                                                                 -- ORG_ID
                     , A.ITEM_ID                                                                         -- 품목_ID
                     , ROW_NUMBER() OVER(ORDER BY (SELECT 1))                                            
                     , C.ORG_CODE                                                                        -- ORG코드
                     , D.ITEM_CODE                                                                       -- 품목코드
                     , D.INVENTORY_TYPE_CODE                                                             -- 재고타입코드
                     , D.PRODUCT_LINE_CODE                                                               -- 제품류코드
                     , A.END_ITEM_ID                                                                     -- 생산품목ID
                     , C.ITEM_CODE                                                AS END_ITEM_CODE                                           -- 생산품목코드
                     , CASE A.MAKE_BUY WHEN 2 THEN N'부품' WHEN 0 THEN N'자작' WHEN 1 THEN N'부품' ELSE N'부품' END       AS END_FLAG_NAME   -- 생산구분명
                     , C.INVENTORY_TYPE_CODE                                      AS END_INV_TYPE_CODE                                       -- 생산품목재고타입코드
                     , C.PRODUCT_LINE_CODE                                        AS END_PROD_LINE_CODE                                      -- 생산품목제품류코드
                     , CASE WHEN C.INVENTORY_TYPE_CODE = 'Finished Goods' THEN ROUND(E.PRODUCTION_QTY, 0) ELSE ROUND(H.SALES_QTY, 0) END AS END_USED_QTY -- 생산품목사용량
                     , 0                                                          AS END_MATERIAL_COST   -- 생산품목재료비
                     , A.RECEIPT_YYYYMM                                                                  -- 입고년월
                     , A.PLAN_BPA                                                                        -- 계획BPA
                     , A.PLAN_CURRENCY                                                                   -- 계획통화
                     , A.PLAN_UNIT_PRICE                                                                 -- 계획단가
                     , A.PLAN_UNIT_PRICE_KRW                                                             -- 계획원화단가
                     , A.BEFORE_BPA                                                                      -- 이전BPA
                     , A.BEFORE_CURRENCY                                                                 -- 이전통화
                     , A.BEFORE_UNIT_PRICE                                                               -- 이전단가
                     , A.BEFORE_UNIT_PRICE_KRW                                                           -- 이전원화단가
                     , A.BPA                                                                             -- BPA
                     , A.CURRENCY_CODE                                                                   -- 통화코드
                     , A.UNIT_PRICE                                                                      -- 단가
                     , A.UNIT_PRICE_KRW                                                                  -- 원화단가
                     , A.RECEIPT_QTY                                                                     -- 입고수량
                     , A.USED_QTY                                                                        -- 사용수량
                     , A.UNIT_PRICE_KRW * A.ALLC / 100 * A.USED_QTY               AS ALLC_AMOUNT         -- 배부된금액
                     , A.BUYER                                                    
                     , CASE WHEN D.ITEM_CODE IN ('25170057','25170058','47013114090','54623172065','54623172156'
                                                 ,'62673172105','62673172107','74663713020','77123171203','79513923001'
                                                 ,'47013460503','63883461003','72313461262','72313461263','72313461264'
                                                 ,'72313461425','72313461457','72313461475','72313461478','72313461491'
                                                 ,'72313461557','72313461580','72313461624','72313462425','72313462475'
                                                 ,'72313462476','72313462478','72313462479','72313463426','72313463458'
                                                 ,'72313463491','72313463574','72313463611','72313463613','72313463613'
                                                 ,'72313463819','72313463827','72313463835','72313464426','72313464458'
                                                 ,'72313464491','72313464496','72313464535','72313464580','72313465434'
                                                 ,'72313465434','72313465451','72313465451','72313465638','72313465638'
                                                 ,'72313465801','72313465801','77123460203','77123460208','77123460233'
                                                 ,'64623586001','72313586001') AND A.TEAM ='KB010' THEN
                            'KB005'
                       ELSE
                            A.TEAM
                       END                                                        AS TEAM                -- 팀코드
                     , F.DEPARTMENT_NAME                                          AS TEAM_NAME           -- 팀명
                     , A.ALLC                                                                            -- 배부율
                     , A.GROUP_BPA                                                                       -- 그룹BPA
                     , A.SEQ_NO                                                                          -- 시퀀스번호
                     , A.CURRENCY_DF                                                                     -- 환율차이
                     , A.TRANSACTION_NATURE                                                              -- 변경사유코드
                     , CASE WHEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 THEN N'인하' WHEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 THEN N'인상' ELSE N'-' END                                                             AS UP_DOWN  -- 인상인하구분
                     , CASE WHEN A.CURRENCY_DF IS NULL THEN 0 WHEN A.CURRENCY_DF > 0 THEN ABS(UNIT_PRICE * USED_QTY * (A.ALLC / 100 ) * CASE WHEN A.CURRENCY_CODE = 'KRW' THEN 1 ELSE A.CURRENCY_DF END) ELSE 0 END                      AS FX_DECREASE_AMT  -- 환율인하금액
                     , CASE WHEN A.CURRENCY_DF IS NULL THEN 0 WHEN A.CURRENCY_DF < 0 THEN ABS(UNIT_PRICE * USED_QTY * (A.ALLC / 100 ) * CASE WHEN A.CURRENCY_CODE = 'KRW' THEN 1 ELSE A.CURRENCY_DF END) ELSE 0 END                      AS FX_INCREASE_AMT  -- 환율인상금액
                     , CASE WHEN A.CURRENCY_CODE <> 'KRW' AND (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                                AS IMP_MTL_DECR_AMOUNT  -- 도입인하금액
                     , CASE WHEN A.CURRENCY_CODE <> 'KRW' AND (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                                AS IMP_MTL_INCR_AMOUNT  -- 도입인상금액
                     , CASE WHEN A.CURRENCY_CODE <> 'KRW' AND (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 AND G.COMMON_CODE IS NOT NULL THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS PURCHASE_IMP_MTL_DECR_AMOUNT -- 구매도입인하금액
                     , CASE WHEN A.CURRENCY_CODE <> 'KRW' AND (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 AND G.COMMON_CODE IS NOT NULL THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS PURCHASE_IMP_MTL_INCR_AMOUNT -- 구매도입인상금액
                     , CASE WHEN A.CURRENCY_CODE <> 'KRW' AND (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 AND G.COMMON_CODE IS NULL     THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS DESIGN_IMP_MTL_DECR_AMOUNT   -- 설계도입인하금액
                     , CASE WHEN A.CURRENCY_CODE <> 'KRW' AND (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 AND G.COMMON_CODE IS NULL     THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS DESIGN_IMP_MTL_INCR_AMOUNT   -- 설계도입인상금액
                     , CASE WHEN A.CURRENCY_CODE = 'KRW' AND  (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                                AS DOM_MTL_DECR_AMOUNT  -- 국내인하금액
                     , CASE WHEN A.CURRENCY_CODE = 'KRW' AND  (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                                AS DOM_MTL_INCR_AMOUNT  -- 국내인상금액
                     , CASE WHEN A.CURRENCY_CODE = 'KRW' AND  (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 AND G.COMMON_CODE IS NOT NULL THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS PURCHAS_DOM_MTL_DECR_AMOUNT  -- 구매국내인하금액
                     , CASE WHEN A.CURRENCY_CODE = 'KRW' AND  (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 AND G.COMMON_CODE IS NOT NULL THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS PURCHAS_DOM_MTL_INCR_AMOUNT  -- 구매국내인상금액
                     , CASE WHEN A.CURRENCY_CODE = 'KRW' AND  (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 AND G.COMMON_CODE IS NULL     THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS DESIGN_DOM_MTL_DECR_AMOUNT   -- 설계국내인하금액
                     , CASE WHEN A.CURRENCY_CODE = 'KRW' AND  (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 AND G.COMMON_CODE IS NULL     THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END  AS DESIGN_DOM_MTL_INCR_AMOUNT   -- 설계국내인상금액
                     , CASE WHEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 AND G.COMMON_CODE IS NOT NULL THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                               AS PURCHASE_DECREASE_AMOUNT -- 구매인하금액
                     , CASE WHEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 AND G.COMMON_CODE IS NOT NULL THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                               AS PURCHASE_INCREASE_AMOUNT -- 구매인상금액
                     , CASE WHEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) > 0 AND G.COMMON_CODE IS NULL     THEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                               AS DESIGN_DECREASE_AMOUNT   -- 설계인하금액
                     , CASE WHEN (A.BEFORE_UNIT_PRICE_KRW - A.UNIT_PRICE_KRW) < 0 AND G.COMMON_CODE IS NULL     THEN (A.UNIT_PRICE_KRW - A.BEFORE_UNIT_PRICE_KRW) * (A.ALLC / 100) * A.USED_QTY ELSE 0 END                               AS DESIGN_INCREASE_AMOUNT   -- 설계인상금액
                     , 0                                                          AS LME_AFFC_AMOUNT
                     , A.VENDOR                                                                          -- 공급자
                     , A.BEFORE_VENDOR                                                                   -- 이전공급자
                     , B.DESCRIPTION                                              AS REASON_DESCR        -- 변경사유설명
                     , A.BPA_COMMENTS                                                                    -- BPADESC -- 기능개선 252696 (진혜영K) 
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_MTL_USED_QTY A
            INNER JOIN (SELECT ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS SEQ_NO
                             , LOOKUP_CODE REASON_CD
                             , MEANING DESCRIPTION
                          FROM ERPSYS.ERP_FND_LOOKUP_VALUES
                         WHERE LOOKUP_TYPE = 'TRANSACTION REASON'
                       ) B
                    ON A.TRANSACTION_NATURE = B.REASON_CD
            INNER JOIN T_DIM_FND_COM_ITEM C
                    ON A.END_ITEM_ID = C.ITEM_ID
                   AND A.ORGANIZATION_ID = C.ORG_ID
            INNER JOIN T_DIM_FND_COM_ITEM D
                    ON A.ITEM_ID = D.ITEM_ID
                   AND A.ORGANIZATION_ID = D.ORG_ID
       LEFT OUTER JOIN (
                          SELECT SUBSTRING(RECEIVING_YYYYMMDD,1,6) AS YYYYMM
                               , ORG_ID
                               , ITEM_ID
                               , SUM(PRODUCTION_QTY) AS PRODUCTION_QTY
                            FROM T_DW_FIN_CCT_MFG_COST_DETAIL
                           WHERE SUBSTRING(RECEIVING_YYYYMMDD,1,6) = @v_parm_to      --파라미터
                        GROUP BY SUBSTRING(RECEIVING_YYYYMMDD,1,6)
                               , ORG_ID
                               , ITEM_ID
                       ) E
                    ON A.YYYYMM = E.YYYYMM
                   AND A.ORGANIZATION_ID = E.ORG_ID
                   AND A.END_ITEM_ID = E.ITEM_ID
            INNER JOIN T_DIM_FND_COM_ORGANIZATION F
                    ON CASE WHEN D.ITEM_CODE IN ('25170057','25170058','47013114090','54623172065','54623172156'
                                                 ,'62673172105','62673172107','74663713020','77123171203','79513923001'
                                                 ,'47013460503','63883461003','72313461262','72313461263','72313461264'
                                                 ,'72313461425','72313461457','72313461475','72313461478','72313461491'
                                                 ,'72313461557','72313461580','72313461624','72313462425','72313462475'
                                                 ,'72313462476','72313462478','72313462479','72313463426','72313463458'
                                                 ,'72313463491','72313463574','72313463611','72313463613','72313463613'
                                                 ,'72313463819','72313463827','72313463835','72313464426','72313464458'
                                                 ,'72313464491','72313464496','72313464535','72313464580','72313465434'
                                                 ,'72313465434','72313465451','72313465451','72313465638','72313465638'
                                                 ,'72313465801','72313465801','77123460203','77123460208','77123460233'
                                                 ,'64623586001','72313586001') AND A.TEAM ='KB010' THEN
                            'KB005'
                       ELSE
                            A.TEAM
                       END = F.DEPARTMENT_CODE  --20160307 윤상협 C 요청 , 윤태호 과장님과 상의 후 처리 => 추후 프로그램 수정 후 하드코딩 제거
       LEFT OUTER JOIN T_DIM_FND_COM_CODE G
                    ON A.TEAM = G.COMMON_CODE
                   AND G.LOOKUP_CODE = 'RED_PUR'
       LEFT OUTER JOIN (
                          SELECT BASE_YYYYMM AS YYYYMM
                               , ORG_ID
                               , ITEM_ID
                               , SUM(SALES_QTY) AS SALES_QTY
                            FROM T_FACT_FIN_CCT_ITEM_SALES_COST
                           WHERE BASE_YYYYMM = @v_parm_to      --파라미터
                             AND INVENTORY_TYPE_CODE NOT IN ('Finished Goods')  --20150527 서광석 부장님 요청으로 상품 조건 제외
                        GROUP BY BASE_YYYYMM
                               , ORG_ID
                               , ITEM_ID
                       ) H
                    ON A.YYYYMM = H.YYYYMM
                   AND A.ORGANIZATION_ID = H.ORG_ID
                   AND A.END_ITEM_ID = H.ITEM_ID
                 WHERE A.YYYYMM  = @v_parm_to      --파라미터
                   AND A.ORG_ID = 89
                   AND A.TRANSACTION_NATURE NOT IN ('REASON_24','REASON_26','REASON_27') --20150331 수주성개발구매 제외  CPO)Global Sourcing팀 김재훈 사원 요청 , 20170331 남기섭K REASON_27 제외 요청
                   --AND    A.ITEM_ID <>  A.END_ITEM_ID       --상품제외 20150527 서광석 부장님 요청으로 상품 제외 조건 주석 처리함
                   ;
                   
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_MP_COST_RED_DETAIL]
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

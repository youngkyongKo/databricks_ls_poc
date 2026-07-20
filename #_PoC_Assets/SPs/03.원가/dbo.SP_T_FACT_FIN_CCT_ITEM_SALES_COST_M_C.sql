CREATE PROC [dbo].[SP_T_FACT_FIN_CCT_ITEM_SALES_COST_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'SP_T_FACT_FIN_CCT_ITEM_SALES_COST_M_C' -- procedure name 
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

                DELETE FROM [dbo].[T_FACT_FIN_CCT_ITEM_SALES_COST] 
                 WHERE BASE_YYYYMM BETWEEN @v_parm_from AND @v_parm_to
                 ;
                INSERT INTO [dbo].[T_FACT_FIN_CCT_ITEM_SALES_COST]
                (      [BASE_YYYYMM]
                      ,[ORG_ID]
                      ,[ITEM_ID]
                      ,[SALES_OCCUR_TYPE_CODE]
                      ,[INVENTORY_TYPE_CODE]
                      ,[ERP_CUSTOMER_ACCOUNT_ID]
                      ,[SALE_DEPARTMENT_CODE]
                      ,[TERRITORY_ID]
                      ,[COUNTRY_CODE]
                      ,[MARKET_TYPE_CODE]
                      ,[ORG_ITEM_ID_KEY]
                      ,[ORG_CODE]
                      ,[ITEM_CODE]
                      ,[SALES_QTY]
                      ,[BUSINESS_SELLING_PRICE_AMOUNT]
                      ,[SALES_AMOUNT]
                      ,[USD_CONVERSION_SALES_AMOUNT]
                      ,[IMPORT_MATERIAL_COST]
                      ,[DOMESTIC_MATERIAL_COST]
                      ,[LABOR_COST]
                      ,[EXPENSE]
                      ,[VAR_COST]
                      ,[VARIANCE_ALLOCATION_AMOUNT]
                      ,[IMPORTED_MATERIALS_FX_AMOUNT]
                      ,[GL_VARIANCE]
                      ,[OR_LOSS]
                      ,[WT_CHRG_OSP_COST]
                      ,[FUTURES_TRANSACTION_PL]
                      ,[CUSTOMS_DUTY_DRAWBACK]
                      ,[SALES_COST_ADJUST]
                      ,[PRODUCT_DEDUCT]
                      ,[ETL_DT]
                )
                SELECT
                      SUBSTRING(DWC.SHIP_APPROVAL_YYYYMMDD,1,6)     AS BASE_YYYYMM -- 출하승인년월
                    , DWC.ORG_ID                                    -- ORG_ID
                    , DWC.ITEM_ID                                   -- 품목ID
                    , DWC.SALES_OCCUR_TYPE_CODE                     -- 매출발생유형코드
                    , DDI.INVENTORY_TYPE_CODE                       -- 재고구군코드(차후 칼럼명 변경??코드로)
                    , DWC.ERP_CUSTOMER_ACCOUNT_ID                   -- ERP고객계정ID
                    , DWC.SALE_DEPARTMENT_CODE                      -- 판매부서코드
                    , DDC.TERRITORY_ID
                    , DWC.COUNTRY_CODE                              -- 국가코드
                    , DWC.MARKET_TYPE_CODE
                    , CONCAT(CAST(DWC.ORG_ID AS INT), CAST(DWC.ITEM_ID AS INT)) AS ORG_ITEM_ID_KEY
                    , DDO.ORG_CODE
                    , DDI.ITEM_CODE
                    , ROUND(sum(DWC.SALES_QTY                    ) , 4)     AS SALES_QTY-- 판매수량
                    , ROUND(sum(DWC.BUSINESS_SELLING_PRICE_AMOUNT) , 4)     AS BUSINESS_SELLING_PRICE_AMOUNT-- 사업판가
                    , ROUND(sum(DWC.BASIC_CURRENCY_SALES_AMOUNT  ) , 4)     AS SALES_AMOUNT-- 기준통화매출금액(KRW)
                    , ROUND(sum(DWC.USD_CONVERSION_SALES_AMOUNT  ) , 4)     AS USD_CONVERSION_SALES_AMOUNT-- 달러환산매출금액
                    , ROUND(sum(DWC.SA_COST_IMP_MTL_COST         ) , 4)     AS IMPORT_MATERIAL_COST-- 매출원가도입재료비
                    , ROUND(sum(DWC.SA_COST_DOM_MTL_COST         ) , 4)     AS DOMESTIC_MATERIAL_COST-- 매출원가국내재료비
                    , ROUND(sum(DWC.SALES_COST_LABOR_COST        ) , 4)     AS LABOR_COST-- 매출원가노무비
                    , ROUND(sum(DWC.SALES_COST_EXPENSE           ) , 4)     AS EXPENSE-- 매출원가경비
                    , ROUND(sum(DWC.SALES_COST_VAR_COST          ) , 4)     AS VAR_COST-- 매출원가변동비
                    , ROUND(sum(DWC.VARIANCE_ALLOCATION_AMOUNT   ) , 4)     AS VARIANCE_ALLOCATION_AMOUNT-- 분산배부금액
                    , ROUND(sum(DWC.BF_YEAR_XRATE_DIFF_AMOUNT    ) , 4)     AS IMPORTED_MATERIALS_FX_AMOUNT-- 도입재환차금액
                    , ROUND(SUM(DWC.GL_VARIANCE                  ) , 4)     AS GL_VARIANCE-- GLVariance
                    , ROUND(SUM(DWC.OR_LOSS                      ) , 4)     AS OR_LOSS-- 조업도손실 
                    , ROUND(SUM(DWC.WT_CHRG_OSP_COST             ) , 4)     AS WT_CHRG_OSP_COST-- 유상사급원가
                    , ROUND(SUM(DWC.FUTURES_TRANSACTION_PL       ) , 4)     AS FUTURES_TRANSACTION_PL-- 선물거래손익
                    , ROUND(SUM(DWC.CUSTOMS_DUTY_DRAWBACK        ) , 4)     AS CUSTOMS_DUTY_DRAWBACK-- 관세환급
                    , ROUND(SUM(DWC.SALES_COST_ADJUST            ) , 4)     AS SALES_COST_ADJUST-- 매출원가조정
                    , ROUND(SUM(DWC.PRODUCT_DEDUCT               ) , 4)     AS PRODUCT_DEDUCT-- 제품평가감
                    , DATEADD(HOUR, 9 ,GETDATE())                           AS ETL_DT
                FROM T_DW_FIN_CCT_SALES_COST_DETAIL DWC
          INNER JOIN T_DIM_FND_COM_ITEM              DDI
                  ON DWC.ITEM_ID = DDI.ITEM_ID
                 AND DWC.ORG_ID  = DDI.ORG_ID
                 AND DDI.PRODUCT_LINE_CODE NOT IN ('700', '750', '770', '799')   -- 2011-03-03 관리결산 금속사업관련 계정 논의 결과:DM의 Data에서는 금속사업부의 Data를 제외시킴
          INNER JOIN T_DIM_FND_COM_COUNTRY           DDC
                  ON DWC.COUNTRY_CODE = DDC.COUNTRY_CODE
          INNER JOIN T_DIM_FND_COM_ORG               DDO
                  ON DWC.ORG_ID  = DDO.ORG_ID
               WHERE SUBSTRING(DWC.SHIP_APPROVAL_YYYYMMDD,1,6) BETWEEN @v_parm_from AND @v_parm_to
            GROUP BY SUBSTRING(DWC.SHIP_APPROVAL_YYYYMMDD,1,6)      -- 출하승인년월일
                    , DWC.ORG_ID                                    -- ORG_ID
                    , DWC.ITEM_ID                                   -- 품목ID
                    , DWC.SALES_OCCUR_TYPE_CODE                     -- 매출발생유형코드
                    , DDI.INVENTORY_TYPE_CODE                       -- 재고구군코드
                    , DWC.ERP_CUSTOMER_ACCOUNT_ID                   -- ERP고객계정ID
                    , DWC.SALE_DEPARTMENT_CODE                      -- 판매부서코드
                    , DDC.TERRITORY_ID
                    , DWC.COUNTRY_CODE
                    , DDO.ORG_CODE
                    , DDI.ITEM_CODE
                    , DWC.MARKET_TYPE_CODE
                    ; 
                   
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_FACT_FIN_CCT_ITEM_SALES_COST]
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

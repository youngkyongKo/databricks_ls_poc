CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_MP_COST_RED_RSLT_09_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_MP_COST_RED_RSLT_09_M_C' -- procedure name 
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
         
         
                DELETE FROM [dbo].[T_DW_EPO_IPO_MP_COST_RED_RSLT] 
                 WHERE BASE_YYYYMM  =  @v_parm_to     --파라미터
                 ; 
                 
                INSERT INTO [dbo].[T_DW_EPO_IPO_MP_COST_RED_RSLT] 
                (      [BASE_YYYYMM]
                     , [ORG_CODE]
                     , [ITEM_CODE]
                     , [PROD_TYPE_CODE]
                     , [INVENTORY_TYPE_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [USAGE_QTY]
                     , [RESULT_MATERIAL_COST]
                     , [IMP_MATERIAL_COST]
                     , [DOM_MATERIAL_COST]
                     , [OUTSIDE_MATERIAL_COST]
                     , [IMPORT_INCIDENTAL_COST]
                     , [FX_DECREASE_AMOUNT]
                     , [FX_INCREASE_AMOUNT]
                     , [OUTSIDE_DECREASE_AMOUNT]
                     , [OUTSIDE_INCREASE_AMOUNT]
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
                     , [OVERLAP_DECREASE_AMOUNT]
                     , [OVERLAP_INCREASE_AMOUNT]
                     , [PUR_BOM_DECREASE_AMOUNT]
                     , [PUR_BOM_INCREASE_AMOUNT]
                     , [DGN_BOM_DECREASE_AMOUNT]
                     , [DGN_BOM_INCREASE_AMOUNT]
                     , [NEW_PRODUCT_DECREASE_AMOUNT]
                     , [ETL_DT]
                )
                SELECT A.BASE_YYYYMM                                                                             -- 기준년월
                     , A.ORG_CODE                                                                                -- ORG코드
                     , A.ITEM_CODE                                                                               -- 품목코드
                     , CASE A.END_FLAG_NAME WHEN N'자작' THEN '0' WHEN N'외주' THEN '1' ELSE '2' END AS PROD_TYPE_CODE  -- 생산구분코드
                     , A.INVENTORY_TYPE_CODE                                                                     -- 재고구분코드
                     , A.PRODUCT_LINE_CODE                                                                       -- 제품류코드
                     , A.USED_QTY                                          AS USAGE_QTY                          -- 사용수량
                     , ISNULL(B.MANUFACTURE_COST, B.SALES_COST)            AS RESULT_MATERIAL_COST               -- 실적재료비
                     , ISNULL(B.M_IMPORT_COST, B.IMPORT_MATERIAL_COST)     AS IMP_MATERIAL_COST                  -- 도입재재료비
                     , ISNULL(B.M_DOMESTIC_COST, B.DOMESTIC_MATERIAL_COST) AS DOM_MATERIAL_COST                  -- 국내재재료비
                     , 0 * A.USED_QTY                                      AS OUTSIDE_MATERIAL_COST              -- 외주재료비
                     , 0                                                   AS IMPORT_INCIDENTAL_COST             -- 도입부대비
                     , A.FX_DECREASE_AMT                                   AS FX_DECREASE_AMOUNT                 -- 환차인하금액
                     , A.FX_INCREASE_AMT                                   AS FX_INCREASE_AMOUNT                 -- 환차인상금액
                     , 0                                                   AS OUTSIDE_DECREASE_AMOUNT            -- 외주인하금액
                     , 0                                                   AS OUTSIDE_INCREASE_AMOUNT            -- 외주인상금액
                     , IMP_MTL_DECR_AMOUNT                                                                       -- 도입재인하금액
                     , IMP_MTL_INCR_AMOUNT                                                                       -- 도입재인상금액
                     , PURCHASE_IMP_MTL_DECR_AMOUNT                                                              -- 구매도입재인하금액
                     , PURCHASE_IMP_MTL_INCR_AMOUNT                                                              -- 구매도입재인상금액
                     , DESIGN_IMP_MTL_DECR_AMOUNT                                                                -- 설계도입재인하금액
                     , DESIGN_IMP_MTL_INCR_AMOUNT                                                                -- 설계도입재인상금액
                     , DOM_MTL_DECR_AMOUNT                                                                       -- 국내재인하금액
                     , DOM_MTL_INCR_AMOUNT                                                                       -- 국내재인상금액
                     , PURCHAS_DOM_MTL_DECR_AMOUNT                                                               -- 구매국내재인하금액
                     , PURCHAS_DOM_MTL_INCR_AMOUNT                                                               -- 구매국내재인상금액
                     , DESIGN_DOM_MTL_DECR_AMOUNT                                                                -- 설계국내재인하금액
                     , DESIGN_DOM_MTL_INCR_AMOUNT                                                                -- 설계국내재인상금액
                     , PURCHASE_DECREASE_AMOUNT                                                                  -- 구매인하금액
                     , PURCHASE_INCREASE_AMOUNT                                                                  -- 구매인상금액
                     , DESIGN_DECREASE_AMOUNT                                                                    -- 설계인하금액
                     , DESIGN_INCREASE_AMOUNT                                                                    -- 설계인상금액
                     , OVERLAP_DECREASE_AMOUNT                                                                   -- 신제품오버랩인하금액
                     , OVERLAP_INCREASE_AMOUNT                                                                   -- 신제품오버랩인상금액
                     , PUR_BOM_DECREASE_AMOUNT                                                                   -- 구매BOM인하금액
                     , PUR_BOM_INCREASE_AMOUNT                                                                   -- 구매BOM인상금액
                     , DGN_BOM_DECREASE_AMOUNT                                                                   -- 설계BOM인하금액
                     , DGN_BOM_INCREASE_AMOUNT                                                                   -- 설계BOM인상금액
                     , NEW_PRODUCT_DECREASE_AMOUNT                                                               -- 신제품인하금액
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM (
                        SELECT BASE_YYYYMM
                             , TB.ORG_CODE
                             , TB.ORG_ID
                             , TB.ITEM_CODE
                             , TB.ITEM_ID
                             , END_FLAG_NAME
                             , MAX(M.INVENTORY_TYPE_CODE)               AS INVENTORY_TYPE_CODE
                             , MAX(M.PRODUCT_LINE_CODE)                 AS PRODUCT_LINE_CODE
                             , MAX(USED_QTY)                            AS USED_QTY
                             , SUM(FX_DECREASE_AMT)                     AS FX_DECREASE_AMT
                             , SUM(FX_INCREASE_AMT)                     AS FX_INCREASE_AMT
                             , ISNULL(SUM(IMP_MTL_DECR_AMOUNT),0)          AS IMP_MTL_DECR_AMOUNT
                             , ISNULL(SUM(IMP_MTL_INCR_AMOUNT),0)          AS IMP_MTL_INCR_AMOUNT
                             , ISNULL(SUM(PURCHASE_IMP_MTL_DECR_AMOUNT),0) AS PURCHASE_IMP_MTL_DECR_AMOUNT
                             , ISNULL(SUM(PURCHASE_IMP_MTL_INCR_AMOUNT),0) AS PURCHASE_IMP_MTL_INCR_AMOUNT
                             , ISNULL(SUM(DESIGN_IMP_MTL_DECR_AMOUNT),0)   AS DESIGN_IMP_MTL_DECR_AMOUNT
                             , ISNULL(SUM(DESIGN_IMP_MTL_INCR_AMOUNT),0)   AS DESIGN_IMP_MTL_INCR_AMOUNT
                             , ISNULL(SUM(DOM_MTL_DECR_AMOUNT),0)          AS DOM_MTL_DECR_AMOUNT
                             , ISNULL(SUM(DOM_MTL_INCR_AMOUNT),0)          AS DOM_MTL_INCR_AMOUNT
                             , ISNULL(SUM(PURCHAS_DOM_MTL_DECR_AMOUNT),0)  AS PURCHAS_DOM_MTL_DECR_AMOUNT
                             , ISNULL(SUM(PURCHAS_DOM_MTL_INCR_AMOUNT),0)  AS PURCHAS_DOM_MTL_INCR_AMOUNT
                             , ISNULL(SUM(DESIGN_DOM_MTL_DECR_AMOUNT),0)   AS DESIGN_DOM_MTL_DECR_AMOUNT
                             , ISNULL(SUM(DESIGN_DOM_MTL_INCR_AMOUNT),0)   AS DESIGN_DOM_MTL_INCR_AMOUNT
                             , ISNULL(SUM(PURCHASE_DECREASE_AMOUNT),0)     AS PURCHASE_DECREASE_AMOUNT
                             , ISNULL(SUM(PURCHASE_INCREASE_AMOUNT),0)     AS PURCHASE_INCREASE_AMOUNT
                             , ISNULL(SUM(DESIGN_DECREASE_AMOUNT) ,0)      AS DESIGN_DECREASE_AMOUNT
                             , ISNULL(SUM(DESIGN_INCREASE_AMOUNT) ,0)      AS DESIGN_INCREASE_AMOUNT
                             , ISNULL(SUM(OVERLAP_DECREASE_AMOUNT),0)      AS OVERLAP_DECREASE_AMOUNT
                             , ISNULL(SUM(OVERLAP_INCREASE_AMOUNT),0)      AS OVERLAP_INCREASE_AMOUNT
                             , ISNULL(SUM(PUR_BOM_DECREASE_AMOUNT),0)      AS PUR_BOM_DECREASE_AMOUNT
                             , ISNULL(SUM(PUR_BOM_INCREASE_AMOUNT),0)      AS PUR_BOM_INCREASE_AMOUNT
                             , ISNULL(SUM(DGN_BOM_DECREASE_AMOUNT),0)      AS DGN_BOM_DECREASE_AMOUNT
                             , ISNULL(SUM(DGN_BOM_INCREASE_AMOUNT),0)      AS DGN_BOM_INCREASE_AMOUNT
                             , ISNULL(SUM(NEW_PRODUCT_DECREASE_AMOUNT),0)  AS NEW_PRODUCT_DECREASE_AMOUNT
                          FROM (
                                SELECT BASE_YYYYMM
                                     , ORG_CODE
                                     , ORG_ID
                                     , END_ITEM_CODE                        AS ITEM_CODE
                                     , END_ITEM_ID                          AS ITEM_ID
                                     , END_FLAG_NAME                        AS END_FLAG_NAME
                                     , MAX(END_USED_QTY)                    AS USED_QTY
                                     , MAX(END_MATERIAL_COST)               AS M_COST
                                     , SUM(T.FX_DECREASE_AMT)               AS FX_DECREASE_AMT
                                     , SUM(T.FX_INCREASE_AMT)               AS FX_INCREASE_AMT
                                     , SUM(T.IMP_MTL_DECR_AMOUNT)           AS IMP_MTL_DECR_AMOUNT
                                     , SUM(T.IMP_MTL_INCR_AMOUNT)           AS IMP_MTL_INCR_AMOUNT
                                     , SUM(T.PURCHASE_IMP_MTL_DECR_AMOUNT)  AS PURCHASE_IMP_MTL_DECR_AMOUNT
                                     , SUM(T.PURCHASE_IMP_MTL_INCR_AMOUNT)  AS PURCHASE_IMP_MTL_INCR_AMOUNT
                                     , SUM(T.DESIGN_IMP_MTL_DECR_AMOUNT)    AS DESIGN_IMP_MTL_DECR_AMOUNT
                                     , SUM(T.DESIGN_IMP_MTL_INCR_AMOUNT)    AS DESIGN_IMP_MTL_INCR_AMOUNT
                                     , SUM(T.DOM_MTL_DECR_AMOUNT)           AS DOM_MTL_DECR_AMOUNT
                                     , SUM(T.DOM_MTL_INCR_AMOUNT)           AS DOM_MTL_INCR_AMOUNT
                                     , SUM(T.PURCHAS_DOM_MTL_DECR_AMOUNT)   AS PURCHAS_DOM_MTL_DECR_AMOUNT
                                     , SUM(T.PURCHAS_DOM_MTL_INCR_AMOUNT)   AS PURCHAS_DOM_MTL_INCR_AMOUNT
                                     , SUM(T.DESIGN_DOM_MTL_DECR_AMOUNT)    AS DESIGN_DOM_MTL_DECR_AMOUNT
                                     , SUM(T.DESIGN_DOM_MTL_INCR_AMOUNT)    AS DESIGN_DOM_MTL_INCR_AMOUNT
                                     , SUM(T.PURCHASE_DECREASE_AMOUNT)      AS PURCHASE_DECREASE_AMOUNT
                                     , SUM(T.PURCHASE_INCREASE_AMOUNT)      AS PURCHASE_INCREASE_AMOUNT
                                     , SUM(T.DESIGN_DECREASE_AMOUNT)        AS DESIGN_DECREASE_AMOUNT
                                     , SUM(T.DESIGN_INCREASE_AMOUNT)        AS DESIGN_INCREASE_AMOUNT
                                     , 0                                    AS OVERLAP_DECREASE_AMOUNT
                                     , 0                                    AS OVERLAP_INCREASE_AMOUNT
                                     , 0                                    AS PUR_BOM_DECREASE_AMOUNT
                                     , 0                                    AS PUR_BOM_INCREASE_AMOUNT
                                     , 0                                    AS DGN_BOM_DECREASE_AMOUNT
                                     , 0                                    AS DGN_BOM_INCREASE_AMOUNT
                                     , 0                                    AS NEW_PRODUCT_DECREASE_AMOUNT
                                  FROM T_DW_EPO_MP_COST_RED_DETAIL T
                                 WHERE BASE_YYYYMM = @v_parm_to   --파라미터
                              GROUP BY BASE_YYYYMM
                                     , ORG_CODE
                                     , ORG_ID
                                     , END_ITEM_CODE
                                     , END_ITEM_ID
                                     , END_FLAG_NAME
                            
                                 UNION ALL
                            
                                SELECT BASE_YYYYMM
                                     , ORG_CODE
                                     , ORG_ID
                                     , END_ITEM_CODE
                                     , END_ITEM_ID
                                     , MFG_TYPE
                                     , MFG_QTY
                                     , 0
                                     , 0
                                     , 0
                                     , 0
                                     , 0
                                     , 0
                                     , 0
                                     , 0
                                     , 0
                                     , CASE WHEN RED_TYPE = 'PUR' THEN DECR ELSE 0 END + CASE WHEN RED_TYPE = 'DGN' THEN DECR ELSE 0 END AS DOM_MTL_DECR_AMOUNT
                                     , CASE WHEN RED_TYPE = 'PUR' THEN INCR ELSE 0 END + CASE WHEN RED_TYPE = 'DGN' THEN INCR ELSE 0 END AS DOM_MTL_INCR_AMOUNT
                                     , CASE WHEN RED_TYPE = 'PUR' THEN DECR ELSE 0 END AS PURCHAS_DOM_MTL_DECR_AMOUNT
                                     , CASE WHEN RED_TYPE = 'PUR' THEN INCR ELSE 0 END AS PURCHAS_DOM_MTL_INCR_AMOUNT
                                     , CASE WHEN RED_TYPE = 'DGN' THEN DECR ELSE 0 END AS DESIGN_DOM_MTL_DECR_AMOUNT
                                     , CASE WHEN RED_TYPE = 'DGN' THEN INCR ELSE 0 END AS DESIGN_DOM_MTL_INCR_AMOUNT
                                     , CASE WHEN RED_TYPE = 'PUR' THEN DECR ELSE 0 END AS PURCHASE_DECREASE_AMOUNT
                                     , CASE WHEN RED_TYPE = 'PUR' THEN INCR ELSE 0 END AS PURCHASE_INCREASE_AMOUNT
                                     , CASE WHEN RED_TYPE = 'DGN' THEN DECR ELSE 0 END AS DESIGN_DECREASE_AMOUNT
                                     , CASE WHEN RED_TYPE = 'DGN' THEN INCR ELSE 0 END AS DESIGN_INCREASE_AMOUNT
                                     , 0
                                     , 0
                                     , CASE WHEN RED_TYPE = 'PUR' THEN DECR ELSE 0 END
                                     , CASE WHEN RED_TYPE = 'PUR' THEN INCR ELSE 0 END
                                     , CASE WHEN RED_TYPE = 'DGN' THEN DECR ELSE 0 END
                                     , CASE WHEN RED_TYPE = 'DGN' THEN INCR ELSE 0 END
                                     , 0
                                  FROM V_DW_WIP_RED_BOM_CHANGE
                                 WHERE BASE_YYYYMM = @v_parm_to   --파라미터
                                   AND MFG_QTY > 0
                  
                               ) TB
                    INNER JOIN T_DIM_FND_COM_ITEM M
                            ON M.ORG_ID = TB.ORG_ID
                           AND M.ITEM_ID = TB.ITEM_ID
                    INNER JOIN T_DIM_FND_COM_ORG  Z
                            ON TB.ORG_ID = Z.ORG_ID
                         WHERE Z.OU_ID = 89
                      GROUP BY BASE_YYYYMM
                             , TB.ORG_CODE
                             , TB.ORG_ID
                             , TB.ITEM_CODE
                             , TB.ITEM_ID
                             , END_FLAG_NAME
                       ) A
       LEFT OUTER JOIN (
                        SELECT YYYYMM
                             , ORGANIZATION_ID
                             , ITEM_ID
                             , MAKE_BUY
                             , MAX(MANUFACTURE_COST)        AS MANUFACTURE_COST         --제조원가
                             , MAX(SALES_COST)              AS SALES_COST               --매출원가
                             , MAX(M_DOMESTIC_COST)         AS M_DOMESTIC_COST          --제조국내재
                             , MAX(M_IMPORT_COST)           AS M_IMPORT_COST            --제조도입재
                             , MAX(DOMESTIC_MATERIAL_COST)  AS DOMESTIC_MATERIAL_COST   --매출국내재
                             , MAX(IMPORT_MATERIAL_COST)    AS IMPORT_MATERIAL_COST     --매출도입재
                          FROM ( 
                                SELECT YYYYMM
                                     , ORGANIZATION_ID
                                     , INVENTORY_ITEM_ID                    AS ITEM_ID
                                     , CAST(MAKE_OR_BUY AS NVARCHAR(1))     AS MAKE_BUY
                                     , SUM(M_IMPORT_COST + M_DOMESTIC_COST) AS MANUFACTURE_COST         --제조원가
                                     , NULL                                 AS SALES_COST               --매출원가
                                     , SUM(M_DOMESTIC_COST)                 AS M_DOMESTIC_COST          --제조국내재
                                     , SUM(M_IMPORT_COST)                   AS M_IMPORT_COST            --제조도입재
                                     , NULL                                 AS DOMESTIC_MATERIAL_COST   --매출국내재
                                     , NULL                                 AS IMPORT_MATERIAL_COST     --매출도입재
                                  FROM ERPSYS.ERP_ECST_BI_MFG_COST_DTL 
                                 WHERE YYYYMM = @v_parm_to   --파라미터
                              GROUP BY YYYYMM
                                     , ORGANIZATION_ID
                                     , INVENTORY_ITEM_ID
                                     , MAKE_OR_BUY
                          
                                 UNION ALL
                          
                                SELECT BASE_YYYYMM
                                     , ORG_ID
                                     , ITEM_ID
                                     , CASE INVENTORY_TYPE_CODE WHEN 'Merchandise' THEN '2' ELSE '3' END  AS MAKE_BUY
                                     , NULL                                                     AS MANUFACTURE_COST         --제조원가
                                     , SUM(IMPORT_MATERIAL_COST) + SUM(DOMESTIC_MATERIAL_COST)  AS SALES_COST               --매출원가
                                     , NULL                                                     AS M_DOMESTIC_COST          --제조국내재
                                     , NULL                                                     AS M_IMPORT_COST            --제조도입재
                                     , SUM(DOMESTIC_MATERIAL_COST)                              AS DOMESTIC_MATERIAL_COST   --매출국내재
                                     , SUM(IMPORT_MATERIAL_COST)                                AS IMPORT_MATERIAL_COST     --매출도입재
                                  FROM T_FACT_FIN_CCT_ITEM_SALES_COST
                                 WHERE BASE_YYYYMM = @v_parm_to   --파라미터
                                   AND SALES_OCCUR_TYPE_CODE IN ('Domestic', 'Export', 'SVC','Free Of Charge')
                              GROUP BY BASE_YYYYMM
                                     , ORG_ID
                                     , ITEM_ID
                                     , CASE INVENTORY_TYPE_CODE WHEN 'Merchandise' THEN '2' ELSE '3' END
                               ) T
                      GROUP BY YYYYMM
                             , ORGANIZATION_ID
                             , ITEM_ID
                             , MAKE_BUY
                       ) B
                    ON A.BASE_YYYYMM = B.YYYYMM
                   AND A.ORG_ID = B.ORGANIZATION_ID
                   AND A.ITEM_ID = B.ITEM_ID
                   AND (CASE A.END_FLAG_NAME WHEN N'자작' THEN '1' WHEN N'부품' THEN (CASE A.INVENTORY_TYPE_CODE WHEN 'Merchandise' THEN '2' ELSE '3' END) END) = B.MAKE_BUY
                   ;
                      
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_MP_COST_RED_RSLT]
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

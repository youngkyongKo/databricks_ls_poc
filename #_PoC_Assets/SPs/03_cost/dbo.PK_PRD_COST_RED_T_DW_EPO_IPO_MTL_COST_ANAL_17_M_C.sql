CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_MTL_COST_ANAL_17_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_MTL_COST_ANAL_17_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_DW_EPO_IPO_MTL_COST_ANAL] 
                 WHERE BASE_YYYYMM = @v_parm_to         --파라미타
                 ;  
                
                INSERT INTO [dbo].[T_DW_EPO_IPO_MTL_COST_ANAL]   
                (      [BASE_YYYYMM]
                     , [ORG_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [PLAN_PRODUCTION_AMOUNT]
                     , [PLAN_MATERIAL_COST]
                     , [PRODUCTION_AMOUNT]
                     , [BASE_MATERIAL_COST]
                     , [WORSE_FACTOR_AMOUNT]
                     , [PUR_UNIT_PRICE_INCR_AMOUNT]
                     , [IMP_MTL_INCR_AMOUNT]
                     , [RAW_MATERIAL_INCREASE_AMOUNT]
                     , [DOM_MTL_INCR_AMOUNT]
                     , [VARIABLE_LME_INCREASE_AMOUNT]
                     , [FX_INCREASE_AMOUNT]
                     , [ETC_MTL_COST_INCR_AMOUNT]
                     , [IMPRV_FACTOR_AMOUNT]
                     , [DSGN_RATAL_AMOUNT]
                     , [PUR_UNIT_PRICE_DECR_AMOUNT]
                     , [IMP_MTL_DECR_AMOUNT]
                     , [RAW_MATERIAL_DECREASE_AMOUNT]
                     , [DOM_PARTS_DECR_AMOUNT]
                     , [VARIABLE_LME_DECREASE_AMOUNT]
                     , [FX_DECREASE_AMOUNT]
                     , [ETC_MTL_COST_DECR_AMOUNT]
                     , [MATERIAL_COST]
                     , [FCTRY_NET_RED_AMOUNT]
                     , [PUR_NET_RED_AMOUNT]
                     , [NET_RED_AMOUNT]
                     , [LME_AFFC_AMOUNT]
                     , [XRATE_AFFC_AMOUNT]
                     , [LME_XRATE_AFFC_AMOUNT]
                     , [ETL_DT]
                )
                ----20180228 남기섭k 요청으로 M02 , 800 , 810 제품류에서 경이 넘는 숫자가 들어와 9조까지 입력되게 수정함 
                SELECT BASE_YYYYMM                              --기준년월
                     , ORG_CODE                                 --ORG코드
                     , PRODUCT_LINE_CODE                        --제품류코드
                     , PLAN_PRODUCTION_AMOUNT                   --계획생산금액
                     , PLAN_MATERIAL_COST                       --계획재료비
                     , PRODUCTION_AMOUNT                        --생산금액
                     , CASE WHEN BASE_MATERIAL_COST >= 9999999999999 THEN 0 ELSE BASE_MATERIAL_COST END AS BASE_MATERIAL_COST                                                                                   --기준재료비
                     , CASE WHEN WORSE_FACTOR_AMOUNT >= 9999999999999 THEN 0 WHEN WORSE_FACTOR_AMOUNT <= -9999999999999 THEN 0 ELSE WORSE_FACTOR_AMOUNT END AS WORSE_FACTOR_AMOUNT                              --악화요인금액
                     , CASE WHEN PUR_UNIT_PRICE_INCR_AMOUNT >= 9999999999999 THEN 0 WHEN PUR_UNIT_PRICE_INCR_AMOUNT <= -9999999999999 THEN 0 ELSE PUR_UNIT_PRICE_INCR_AMOUNT END AS PUR_UNIT_PRICE_INCR_AMOUNT  -- 구매단가인상금액
                     , CASE WHEN PUR_UNIT_PRICE_INCR_AMOUNT >= 9999999999999 THEN 0 WHEN PUR_UNIT_PRICE_INCR_AMOUNT <= -9999999999999 THEN 0 ELSE PUR_UNIT_PRICE_INCR_AMOUNT END AS IMP_MTL_INCR_AMOUNT         --구매도입재인상금액
                     , RAW_MATERIAL_INCREASE_AMOUNT             --구매원재료인상금액
                     , CASE WHEN DOM_MTL_INCR_AMOUNT >= 9999999999999 THEN 0 WHEN DOM_MTL_INCR_AMOUNT <= -9999999999999 THEN 0 ELSE DOM_MTL_INCR_AMOUNT END AS DOM_MTL_INCR_AMOUNT                              --구매국내재인상금액
                     , VARIABLE_LME_INCREASE_AMOUNT             --변동LME인상금액
                     , FX_INCREASE_AMOUNT                       --환차인상금액
                     , ETC_MTL_COST_INCR_AMOUNT                 --기타재료비인상금액
                     , CASE WHEN IMPRV_FACTOR_AMOUNT >= 9999999999999 THEN 0 WHEN IMPRV_FACTOR_AMOUNT <= -9999999999999 THEN 0 ELSE IMPRV_FACTOR_AMOUNT END AS IMPRV_FACTOR_AMOUNT                              --개선요인금액
                     , DSGN_RATAL_AMOUNT                        --설계합리화금액
                     , CASE WHEN PUR_UNIT_PRICE_DECR_AMOUNT >= 9999999999999 THEN 0 WHEN PUR_UNIT_PRICE_DECR_AMOUNT <= -9999999999999 THEN 0 ELSE PUR_UNIT_PRICE_DECR_AMOUNT END AS PUR_UNIT_PRICE_DECR_AMOUNT  --구매단가인하금액
                     , CASE WHEN IMP_MTL_DECR_AMOUNT >= 9999999999999 THEN 0 WHEN IMP_MTL_DECR_AMOUNT <= -9999999999999 THEN 0 ELSE IMP_MTL_DECR_AMOUNT END AS IMP_MTL_DECR_AMOUNT                              --구매도입재인하금액
                     , RAW_MATERIAL_DECREASE_AMOUNT             --구매원재료인하금액
                     , CASE WHEN DOM_PARTS_DECR_AMOUNT >= 9999999999999 THEN 0 WHEN DOM_PARTS_DECR_AMOUNT <= -9999999999999 THEN 0 ELSE DOM_PARTS_DECR_AMOUNT END AS DOM_PARTS_DECR_AMOUNT                      --구매국내재인하금액
                     , VARIABLE_LME_DECREASE_AMOUNT             --변동LME인하금액
                     , FX_DECREASE_AMOUNT                       --환차인하금액
                     , ETC_MTL_COST_DECR_AMOUNT                 --기타재료비인하금액
                     , MATERIAL_COST                            --재료비
                     , FCTRY_NET_RED_AMOUNT                     --공장NET절감금액
                     , CASE WHEN PUR_NET_RED_AMOUNT >= 9999999999999 THEN 0 WHEN PUR_NET_RED_AMOUNT <= -9999999999999 THEN 0 ELSE PUR_NET_RED_AMOUNT END AS PUR_NET_RED_AMOUNT                                  --구매NET절감금액
                     , CASE WHEN NET_RED_AMOUNT >= 9999999999999 THEN 0 WHEN NET_RED_AMOUNT <= -9999999999999 THEN 0 ELSE NET_RED_AMOUNT END AS NET_RED_AMOUNT                                                  --NET절감금액
                     , LME_AFFC_AMOUNT                          --LME영향금액
                     , XRATE_AFFC_AMOUNT                        --환율영향금액
                     , LME_XRATE_AFFC_AMOUNT                    --LME및환율영향금액
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM ( 
                          SELECT A.BASE_YYYYMM                                                                                AS BASE_YYYYMM                    --기준년월
                               , A.ORG_CODE                                                                                   AS ORG_CODE                       --ORG코드
                               , A.PRODUCT_LINE_CODE                                                                          AS PRODUCT_LINE_CODE              --제품류코드
                               , ROUND(SUM(B.PLAN_PROD_AMOUNT)   ,4)                                                          AS PLAN_PRODUCTION_AMOUNT         --계획생산금액
                               , ROUND(SUM(B.PLAN_MFG_MTL_COST)  ,4)                                                          AS PLAN_MATERIAL_COST             --계획재료비
                               , ROUND(SUM(B.PRODUCTION_AMOUNT)  ,4)                                                          AS PRODUCTION_AMOUNT              --생산금액
                               , ROUND(SUM(B.MFG_COST_VAR_MTL_COST) + SUM(A.DGN_IMP_DEC) - SUM(A.DGN_IMP_INC) 
                                     + SUM(A.DGN_DOM_DEC) - SUM(A.DGN_DOM_INC) + SUM(A.DGN_RAW_DEC) - SUM(A.DGN_RAW_INC) 
                                     + SUM(A.NEW_DEC) + SUM(A.PUR_IMP_DEC) + SUM(A.PUR_RAW_DEC) + SUM(A.PUR_DOM_DEC) 
                                     - SUM(A.PUR_IMP_INC) - SUM(A.PUR_RAW_INC) - SUM(A.PUR_DOM_INC) ,4)                       AS BASE_MATERIAL_COST             --기준재료비
                               , ROUND(SUM(A.PUR_IMP_INC) + SUM(A.PUR_RAW_INC) + SUM(A.PUR_DOM_INC),4)                        AS WORSE_FACTOR_AMOUNT            --악화요인금액
                               , ROUND(SUM(A.PUR_IMP_INC) + SUM(A.PUR_RAW_INC) + SUM(A.PUR_DOM_INC),4)                        AS PUR_UNIT_PRICE_INCR_AMOUNT     --구매단가인상금액
                               , ROUND(SUM(A.PUR_IMP_INC),4)                                                                  AS IMP_MTL_INCR_AMOUNT            --구매도입재인상금액
                               , ROUND(SUM(A.PUR_RAW_INC),4)                                                                  AS RAW_MATERIAL_INCREASE_AMOUNT   --구매원재료인상금액
                               , ROUND(SUM(A.PUR_DOM_INC),4)                                                                  AS DOM_MTL_INCR_AMOUNT            --구매국내재인상금액
                               , ROUND(SUM(A.LME_INC),4)                                                                      AS VARIABLE_LME_INCREASE_AMOUNT   --변동LME인상금액
                               , ROUND(SUM(A.FX_INC),4)                                                                       AS FX_INCREASE_AMOUNT             --환차인상금액
                               , ROUND(SUM(A.ETC_INC),4)                                                                      AS ETC_MTL_COST_INCR_AMOUNT       --기타재료비인상금액
                               , ROUND(SUM(A.DGN_IMP_DEC) - SUM(A.DGN_IMP_INC) + SUM(A.DGN_DOM_DEC) - SUM(A.DGN_DOM_INC) 
                                     + SUM(A.DGN_RAW_DEC) - SUM(A.DGN_RAW_INC) + SUM(A.NEW_DEC) + SUM(A.PUR_IMP_DEC) 
                                     + SUM(A.PUR_RAW_DEC) + SUM(A.PUR_DOM_DEC),4)                                             AS IMPRV_FACTOR_AMOUNT            --개선요인금액
                               , ROUND(SUM(A.DGN_IMP_DEC) - SUM(A.DGN_IMP_INC) + SUM(A.DGN_DOM_DEC) - SUM(A.DGN_DOM_INC) 
                                     + SUM(A.DGN_RAW_DEC) - SUM(A.DGN_RAW_INC) + SUM(A.NEW_DEC),4)                            AS DSGN_RATAL_AMOUNT              --설계합리화금액
                               , ROUND(SUM(A.PUR_IMP_DEC) + SUM(A.PUR_RAW_DEC) + SUM(A.PUR_DOM_DEC),4)                        AS PUR_UNIT_PRICE_DECR_AMOUNT     --구매단가인하금액
                               , ROUND(SUM(A.PUR_IMP_DEC),4)                                                                  AS IMP_MTL_DECR_AMOUNT            --구매도입재인하금액
                               , ROUND(SUM(A.PUR_RAW_DEC),4)                                                                  AS RAW_MATERIAL_DECREASE_AMOUNT   --구매원재료인하금액
                               , ROUND(SUM(A.PUR_DOM_DEC),4)                                                                  AS DOM_PARTS_DECR_AMOUNT          --구매국내재인하금액
                               , ROUND(SUM(A.LME_DEC) ,4)                                                                     AS VARIABLE_LME_DECREASE_AMOUNT   --변동LME인하금액
                               , ROUND(SUM(A.FX_DEC) ,4)                                                                      AS FX_DECREASE_AMOUNT             --환차인하금액
                               , ROUND(SUM(A.ETC_DEC) ,4)                                                                     AS ETC_MTL_COST_DECR_AMOUNT       --기타재료비인하금액
                               , ROUND(SUM(B.MFG_COST_VAR_MTL_COST) ,4)                                                       AS MATERIAL_COST                  --재료비
                               , ROUND(SUM(A.DGN_IMP_DEC) - SUM(A.DGN_IMP_INC) + SUM(A.DGN_DOM_DEC) - SUM(A.DGN_DOM_INC) 
                                     + SUM(A.DGN_RAW_DEC) - SUM(A.DGN_RAW_INC) + SUM(A.NEW_DEC),4)                            AS FCTRY_NET_RED_AMOUNT           --공장NET절감금액 --(설계도입재인하 - 설계도입재인상 + 설계국내재인하 - 설계국내재인상 + 설계원재료인하 - 설계원재료인상 + 신제품인하)
                               , ROUND(SUM(A.PUR_IMP_DEC) - SUM(A.PUR_IMP_INC) + SUM(A.PUR_DOM_DEC) 
                                     - SUM(A.PUR_DOM_INC) + SUM(A.PUR_RAW_DEC) - SUM(A.PUR_RAW_INC),4)                        AS PUR_NET_RED_AMOUNT             --구매NET절감금액             --(구매도입재인하 - 구매도입재인상 + 구매국내재인하 - 구매국내재인상 + 구매원재료인하 - 구매원재료인상)
                               , ROUND(SUM(A.DGN_IMP_DEC) - SUM(A.DGN_IMP_INC) + SUM(A.DGN_DOM_DEC) 
                                     - SUM(A.DGN_DOM_INC) + SUM(A.DGN_RAW_DEC) - SUM(A.DGN_RAW_INC) 
                                     + SUM(A.NEW_DEC) + SUM(A.PUR_IMP_DEC) - SUM(A.PUR_IMP_INC) 
                                     + SUM(A.PUR_DOM_DEC) - SUM(A.PUR_DOM_INC) + SUM(A.PUR_RAW_DEC) - SUM(A.PUR_RAW_INC),4)   AS NET_RED_AMOUNT                 --NET절감금액
                               , ROUND(SUM(A.LME_DEC) - SUM(A.LME_INC),4)                                                     AS LME_AFFC_AMOUNT                --LME영향금액
                               , ROUND(SUM(A.FX_DEC) - SUM(A.FX_INC),4)                                                       AS XRATE_AFFC_AMOUNT              --환율영향금액
                               , ROUND(SUM(A.LME_DEC) - SUM(A.LME_INC) + SUM(A.FX_DEC) - SUM(A.FX_INC),4)                     AS LME_XRATE_AFFC_AMOUNT          --LME및환율영향금액4
                            FROM V_DW_WIP_RED_COST_ANALYSIS  A
                 LEFT OUTER JOIN (
                                    SELECT BASE_YYYYMM
                                         , ORG_CODE
                                         , PRODUCT_LINE_CODE
                                         , SUM(PLAN_PROD_AMOUNNT) PLAN_PROD_AMOUNT
                                         , SUM(PRODUCTION_AMOUNT) PRODUCTION_AMOUNT
                                         , SUM(PLAN_MFG_MTL_COST) PLAN_MFG_MTL_COST
                                         , SUM(MFG_COST_VAR_MTL_COST) MFG_COST_VAR_MTL_COST
                                      FROM (
                                              SELECT BASE_YYYYMM
                                                   , ORG_CODE
                                                   , PRODUCT_LINE_CODE
                                                   , CASE WHEN SCENARIO_CODE = 'BP' THEN PRODUCTION_AMOUNT ELSE 0 END     AS PLAN_PROD_AMOUNNT
                                                   , CASE WHEN SCENARIO_CODE = 'AC' THEN PRODUCTION_AMOUNT ELSE 0 END     AS PRODUCTION_AMOUNT
                                                   , CASE WHEN SCENARIO_CODE = 'BP' THEN MFG_COST_VAR_MTL_COST ELSE 0 END AS PLAN_MFG_MTL_COST
                                                   , CASE WHEN SCENARIO_CODE = 'AC' THEN MFG_COST_VAR_MTL_COST ELSE 0 END AS MFG_COST_VAR_MTL_COST  --재조원가변동재료비
                                                FROM T_FACT_FIN_CCT_MFG_COST_STATUS
                                               WHERE BASE_YYYYMM = @v_parm_to       --파라미타
                                                 AND ACCUMULATION_FLAG = 'N'
                                                 AND SALES_RECOGNITION_BASE_CODE IN ('PG','ZZ')
                                           ) T
                                  GROUP BY BASE_YYYYMM
                                         , ORG_CODE
                                         , PRODUCT_LINE_CODE
                                 ) B       
                              ON A.BASE_YYYYMM = B.BASE_YYYYMM
                             AND A.PRODUCT_LINE_CODE = B.PRODUCT_LINE_CODE
                           WHERE A.BASE_YYYYMM   = @v_parm_to         --파라미타
                             AND A.ORG_CODE LIKE 'M%'
                        GROUP BY A.BASE_YYYYMM
                               , A.ORG_CODE
                               , A.PRODUCT_LINE_CODE
                       ) A
                       ; 

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_MTL_COST_ANAL]
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
        
        --SELECT @v_load_cnt, @v_pgm_status, @v_err_mesg
        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

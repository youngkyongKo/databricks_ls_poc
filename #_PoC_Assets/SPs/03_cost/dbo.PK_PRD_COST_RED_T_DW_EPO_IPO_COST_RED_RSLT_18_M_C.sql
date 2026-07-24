CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_COST_RED_RSLT_18_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_COST_RED_RSLT_18_M_C' -- procedure name 
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

                DELETE FROM [dbo].[T_DW_EPO_IPO_COST_RED_RSLT]
                WHERE BASE_YYYYMM =  @v_parm_to   --파라미터
                ;
                
                INSERT INTO [dbo].[T_DW_EPO_IPO_COST_RED_RSLT]
                (      [BASE_YYYYMM]
                     , [ORG_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [IMP_MTL_DECR_AMOUNT]
                     , [IMP_MTL_INCR_AMOUNT]
                     , [DOM_MTL_DECR_AMOUNT]
                     , [DOM_MTL_INCR_AMOUNT]
                     , [FX_DECREASE_AMOUNT]
                     , [FX_INCREASE_AMOUNT]
                     , [OUTSIDE_DECREASE_AMOUNT]
                     , [OUTSIDE_INCREASE_AMOUNT]
                     , [PURCHASE_DECREASE_AMOUNT]
                     , [PURCHASE_INCREASE_AMOUNT]
                     , [DESIGN_DECREASE_AMOUNT]
                     , [DESIGN_INCREASE_AMOUNT]
                     , [NEW_PRODUCT_DECREASE_AMOUNT]
                     , [ETC_MTL_COST_DECR_AMOUNT]
                     , [ETC_MTL_COST_INCR_AMOUNT]
                     , [RAW_MATERIAL_DECREASE_AMOUNT]
                     , [RAW_MATERIAL_INCREASE_AMOUNT]
                     , [VARIABLE_LME_DECREASE_AMOUNT]
                     , [VARIABLE_LME_INCREASE_AMOUNT]
                     , [ETL_DT] 
                )
                SELECT A.BASE_YYYYMM                                                                --기준년월
                     , A.ORG_CODE                                                                   --ORG코드
                     , A.PRODUCT_LINE_CODE                                                          --제품류코드
                     , SUM(A.IMP_MTL_DECR_AMOUNT)               AS IMP_MTL_DECR_AMOUNT              --도입재인하금액
                     , SUM(A.IMP_MTL_INCR_AMOUNT)               AS IMP_MTL_INCR_AMOUNT              --도입재인상금액
                     , SUM(A.DOM_MTL_DECR_AMOUNT)               AS DOM_MTL_DECR_AMOUNT              --국내재인하금액
                     , SUM(A.DOM_MTL_INCR_AMOUNT)               AS DOM_MTL_INCR_AMOUNT              --국내재인상금액
                     , SUM(A.FX_DECREASE_AMOUNT)                AS FX_DECREASE_AMOUNT               --환차인하금액
                     , SUM(A.FX_INCREASE_AMOUNT)                AS FX_INCREASE_AMOUNT               --환차인상금액
                     , SUM(A.OUTSIDE_DECREASE_AMOUNT)           AS OUTSIDE_DECREASE_AMOUNT          --외주인하금액
                     , SUM(A.OUTSIDE_INCREASE_AMOUNT)           AS OUTSIDE_INCREASE_AMOUNT          --외주인상금액
                     , SUM(A.PURCHASE_DECREASE_AMOUNT)          AS PURCHASE_DECREASE_AMOUNT         --구매인하금액
                     , SUM(A.PURCHASE_INCREASE_AMOUNT)          AS PURCHASE_INCREASE_AMOUNT         --구매인상금액
                     , SUM(A.DESIGN_DECREASE_AMOUNT)            AS DESIGN_DECREASE_AMOUNT           --설계인하금액
                     , SUM(A.DESIGN_INCREASE_AMOUNT)            AS DESIGN_INCREASE_AMOUNT           --설계인상금액
                     , SUM(A.NEW_PRODUCT_DECREASE_AMOUNT)       AS NEW_PRODUCT_DECREASE_AMOUNT      --신제품인하금액
                     , SUM(A.ETC_MTL_COST_DECR_AMOUNT)          AS ETC_MTL_COST_DECR_AMOUNT         --기타재료비인하금액
                     , SUM(A.ETC_MTL_COST_INCR_AMOUNT)          AS ETC_MTL_COST_INCR_AMOUNT         --기타재료비인상금액
                     , SUM(A.RAW_MATERIAL_DECREASE_AMOUNT)      AS RAW_MATERIAL_DECREASE_AMOUNT     --원재료인하금액
                     , SUM(A.RAW_MATERIAL_INCREASE_AMOUNT)      AS RAW_MATERIAL_INCREASE_AMOUNT     --원재료인상금액
                     , SUM(A.VARIABLE_LME_DECREASE_AMOUNT)      AS VARIABLE_LME_DECREASE_AMOUNT     --변동LME인하금액
                     , SUM(A.VARIABLE_LME_INCREASE_AMOUNT)      AS VARIABLE_LME_INCREASE_AMOUNT     --변동LME인상금액
                     , DATEADD(HOUR, 9 ,GETDATE())              AS ETL_DT                           --적재일시
                  FROM (
                          SELECT BASE_YYYYMM                 AS  BASE_YYYYMM                    --기준년월
                               , ORG_CODE                    AS  ORG_CODE                       --ORG코드
                               , PRODUCT_LINE_CODE           AS  PRODUCT_LINE_CODE              --제품류코드
                               , ROUND(SUM(ABS(CASE WHEN IMP_DEC >= 9999999999999 THEN 0 WHEN IMP_DEC <= -9999999999999 THEN 0 ELSE IMP_DEC END)),4) AS IMP_MTL_DECR_AMOUNT --도입재인하금액
                               , ROUND(SUM(CASE WHEN IMP_INC >= 9999999999999 THEN 0 WHEN IMP_INC <= -9999999999999 THEN 0 ELSE IMP_INC END),4)      AS IMP_MTL_INCR_AMOUNT --도입재인상금액
                               , ROUND(SUM(ABS(CASE WHEN DOM_DEC >= 9999999999999 THEN 0 WHEN DOM_DEC <= -9999999999999 THEN 0 ELSE DOM_DEC END)),4) AS DOM_MTL_DECR_AMOUNT --국내재인하금액
                               , ROUND(SUM(CASE WHEN DOM_INC >= 9999999999999 THEN 0 WHEN DOM_INC <= -9999999999999 THEN 0 ELSE DOM_INC END),4)      AS DOM_MTL_INCR_AMOUNT --국내재인상금액
                               , ROUND(SUM(ABS(FX_DEC)) ,4)  AS  FX_DECREASE_AMOUNT             --환차인하금액
                               , ROUND(SUM(FX_INC)      ,4)  AS  FX_INCREASE_AMOUNT             --환차인상금액
                               , 0                           AS  OUTSIDE_DECREASE_AMOUNT        --외주인하금액
                               , 0                           AS  OUTSIDE_INCREASE_AMOUNT        --외주인상금액
                               , ROUND(SUM(ABS(CASE WHEN PUR_DEC >= 9999999999999 THEN 0 WHEN PUR_DEC <= -9999999999999 THEN 0 ELSE PUR_DEC END)),4) AS  PURCHASE_DECREASE_AMOUNT       --구매인하금액
                               , ROUND(SUM(ABS(CASE WHEN PUR_INC >= 9999999999999 THEN 0 WHEN PUR_INC <= -9999999999999 THEN 0 ELSE PUR_INC END)),4) AS  PURCHASE_INCREASE_AMOUNT       --구매인상금액
                               , ROUND(SUM(ABS(CASE WHEN DGN_DEC >= 9999999999999 THEN 0 WHEN DGN_DEC <= -9999999999999 THEN 0 ELSE DGN_DEC END)),4) AS  DESIGN_DECREASE_AMOUNT       --설계인하금액
                               , ROUND(SUM(ABS(CASE WHEN DGN_INC >= 9999999999999 THEN 0 WHEN DGN_INC <= -9999999999999 THEN 0 ELSE DGN_INC END)),4) AS  DESIGN_INCREASE_AMOUNT        --설계인상금액
                               , ROUND(SUM(ABS(NEW_DEC)),4)  AS  NEW_PRODUCT_DECREASE_AMOUNT    --신제품인하금액
                               , ROUND(SUM(ABS(ETC_DEC)),4)  AS  ETC_MTL_COST_DECR_AMOUNT       --기타재료비인하금액
                               , ROUND(SUM(ABS(ETC_INC)),4)  AS  ETC_MTL_COST_INCR_AMOUNT       --기타재료비인상금액
                               , ROUND(SUM(ABS(RAW_DEC)),4)  AS  RAW_MATERIAL_DECREASE_AMOUNT   --원재료인하금액
                               , ROUND(SUM(ABS(RAW_INC)),4)  AS  RAW_MATERIAL_INCREASE_AMOUNT   --원재료인상금액
                               , ROUND(SUM(ABS(CASE WHEN LME_DEC >= 9999999999999 THEN 0 WHEN LME_DEC <= -9999999999999 THEN 0 ELSE LME_DEC END)),4) AS  VARIABLE_LME_DECREASE_AMOUNT       --변동LME인하금액
                               , ROUND(SUM(ABS(CASE WHEN LME_INC >= 9999999999999 THEN 0 WHEN LME_INC <= -9999999999999 THEN 0 ELSE LME_INC END)),4) AS  VARIABLE_LME_INCREASE_AMOUNT        --변동LME인상금액
                            FROM V_DW_WIP_RED_COST_ANALYSIS
                           WHERE BASE_YYYYMM   = @v_parm_to  --파라미터
                             AND PRODUCT_LINE_CODE IS NOT NULL
                        GROUP BY BASE_YYYYMM
                               , ORG_CODE
                               , PRODUCT_LINE_CODE
                       ) A
            INNER JOIN T_DIM_FND_COM_ORG B
                    ON A.ORG_CODE = B.ORG_CODE
                   AND B.OU_ID = 89
                 WHERE A.BASE_YYYYMM = @v_parm_to  --파라미터
              GROUP BY A.BASE_YYYYMM
                     , A.ORG_CODE
                     , A.PRODUCT_LINE_CODE
                     ; 
                      
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_COST_RED_RSLT]
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
         --SELECT @v_pgm_status, @v_load_cnt
        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

CREATE PROC [dbo].[PK_PRD_COST_RED_T_FACT_FIN_MP_COST_RED_CIRC_21_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_FACT_FIN_MP_COST_RED_CIRC_21_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_FACT_FIN_MP_COST_RED_CIRC]
                 WHERE BASE_YYYYMM = @v_parm_to         --파라미타
                 ;

                INSERT INTO [dbo].[T_FACT_FIN_MP_COST_RED_CIRC]
                (      [BASE_YYYYMM]
                     , [ORG_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [DEPARTMENT_CODE]
                     , [CIRCULATE_RATE]
                     , [PURCHASE_RED_COST]
                     , [DESIGN_RED_COST]
                     , [LME_RED_COST]
                     , [ETL_DT]
                )
                SELECT A.BASE_YYYYMM
                     , A.ORG_CODE
                     , A.PRODUCT_LINE_CODE
                     , ISNULL(B.DEPARTMENT_CODE,'KA249')    AS DEPT_CODE
                     , ISNULL(ROUND(B.RR*100,2),100)        AS R_RATE
                     , ROUND(A.PUR * ISNULL(B.RR,1) ,4)     AS PUR_RED_COST
                     , ROUND(A.DGN * ISNULL(B.RR,1) ,4)     AS DGN_RED_COST
                     , ROUND(A.LME * ISNULL(B.RR,1) ,4)     AS LME_RED_COST
                     , DATEADD(HOUR, 9 ,GETDATE())          AS ETL_DT
                  FROM (
                          SELECT A2.BASE_YYYYMM
                               , A2.ORG_CODE
                               , A2.PRODUCT_LINE_CODE
                               , SUM(A2.PUR) PUR
                               , SUM(A2.DGN) DGN
                               , SUM(A2.LME) LME
                            FROM (
                                    SELECT BASE_YYYYMM
                                         , ORG_CODE
                                         , PRODUCT_LINE_CODE
                                         , ROUND(SUM(PURCHASE_INCREASE_AMOUNT - PURCHASE_DECREASE_AMOUNT + PUR_BOM_INCREASE_AMOUNT - PUR_BOM_DECREASE_AMOUNT), 0) PUR
                                         , ROUND(SUM(DESIGN_INCREASE_AMOUNT - DESIGN_DECREASE_AMOUNT + DGN_BOM_INCREASE_AMOUNT - DGN_BOM_DECREASE_AMOUNT + OVERLAP_INCREASE_AMOUNT - OVERLAP_DECREASE_AMOUNT), 0) DGN
                                         , 0 LME
                                      FROM T_DW_EPO_IPO_MP_COST_RED_RSLT
                                     WHERE BASE_YYYYMM = @v_parm_to         --파라미타
                                     GROUP BY BASE_YYYYMM
                                         , ORG_CODE
                                         , PRODUCT_LINE_CODE
                                           
                                     UNION ALL
                                           
                                    SELECT TARGET_MONTH
                                         , ORGANIZATION_CODE
                                         , SPG
                                         , 0
                                         , 0
                                         , SUM((KRW_PRICE - BEFORE_KRW_PRICE) *  (ALLC_RATE * QUANTITY)) LME
                                      FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V
                                     WHERE TARGET_MONTH = @v_parm_to         --파라미타
                                       AND C_GUBUN = 'L'
                                     GROUP BY TARGET_MONTH
                                         , ORGANIZATION_CODE
                                         , SPG
                                 ) A2
                      INNER JOIN T_DIM_FND_COM_ORG B2
                              ON A2.ORG_CODE = B2.ORG_CODE
                             AND B2.OU_ID = 89
                           GROUP BY A2.BASE_YYYYMM
                               , A2.ORG_CODE
                               , A2.PRODUCT_LINE_CODE
                       ) A       
       LEFT OUTER JOIN (  
                          SELECT YYYYMM
                               , ORG_CODE
                               , DEPARTMENT_CODE
                               , PRODUCT_LINE_CODE
                               , MATERIAL_COST_SUM
                               , CAST(MATERIAL_COST_SUM / NULLIF(SUM(MATERIAL_COST_SUM) OVER(PARTITION BY PRODUCT_LINE_CODE) , 0) AS FLOAT) AS RR  
                            FROM (
                                   SELECT YYYYMM
                                        , ORG_CODE
                                        , DEPARTMENT_CODE
                                        , PRODUCT_LINE_CODE
                                        , SUM(MATERIAL_COST)  AS MATERIAL_COST_SUM
                                     FROM T_DW_FIN_CCT_TEAM_PL_RESULT
                                    WHERE ACCUMULATION_FLAG = 'N'
                                      AND YYYYMM = @v_parm_to         --파라미타
                                    GROUP BY YYYYMM,ORG_CODE
                                        , DEPARTMENT_CODE
                                        , PRODUCT_LINE_CODE   
                                 ) A
                          --SELECT YYYYMM
                          --     , ORG_CODE
                          --     , DEPARTMENT_CODE
                          --     , PRODUCT_LINE_CODE
                          --     , SUM(MATERIAL_COST)
                          --     --, RATIO_TO_REPORT(SUM(MATERIAL_COST)) OVER (PARTITION BY PRODUCT_LINE_CODE) AS RR 
                          --     , (MATERIAL_COST / SUM(MATERIAL_COST) OVER (PARTITION BY PRODUCT_LINE_CODE) ) AS RR 
                          --     , MATERIAL_COST/ SUM(MATERIAL_COST) OVER (PARTITION BY PRODUCT_LINE_CODE) as ratio
                          --  FROM T_DW_FIN_CCT_TEAM_PL_RESULT
                          -- WHERE ACCUMULATION_FLAG = 'N'
                          --   AND YYYYMM = @v_parm_to         --파라미타
                          -- GROUP BY YYYYMM,ORG_CODE
                          --     , DEPARTMENT_CODE
                          --     , PRODUCT_LINE_CODE
                       ) B       
                    ON A.BASE_YYYYMM = B.YYYYMM
                   AND A.ORG_CODE = B.ORG_CODE
                   AND A.PRODUCT_LINE_CODE = B.PRODUCT_LINE_CODE
                   ;


            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_FACT_FIN_MP_COST_RED_CIRC]
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

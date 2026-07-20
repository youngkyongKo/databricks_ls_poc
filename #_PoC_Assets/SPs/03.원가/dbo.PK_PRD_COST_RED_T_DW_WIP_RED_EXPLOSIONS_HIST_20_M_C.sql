CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_WIP_RED_EXPLOSIONS_HIST_20_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_WIP_RED_EXPLOSIONS_HIST_20_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_DW_WIP_RED_EXPLOSIONS_HIST]
                 WHERE BASE_YYYYMM  =  @v_parm_to         --파라미타
                 ; 

                INSERT INTO [dbo].[T_DW_WIP_RED_EXPLOSIONS_HIST]
                (      [BASE_YYYYMM]
                     , [ORG_ID]
                     , [ORG_CODE]
                     , [END_ITEM_ID]
                     , [END_ITEM_CODE]
                     , [END_ITEM_TYPE_NAME]
                     , [PRODUCT_LINE_CODE]
                     , [PARENTS_ITEM_ID]
                     , [PARENT_ITEM_CODE]
                     , [ROW_NUM]
                     , [BOM_LEVEL]
                     , [COMPONENT_SEQUENCE_ID]
                     , [COMPONENT_ITEM_ID]
                     , [COMPONENT_ITEM_CODE]
                     , [WIP_SUPPLY_TYPE]
                     , [COMPONENT_QTY]
                     , [EXTENDED_QTY]
                     , [END_USED_QTY]
                     , [PLN_MTL_COST]
                     , [BASE_MTL_COST]
                     , [PUR_RED_AMOUNT]
                     , [DGN_RED_AMOUNT]
                     , [PROJECT_ID]
                     , [TASK_ID]
                     , [ETL_DT]
                )
                SELECT A.BASE_YYYYMM                                                                                 AS BASE_YYYYMM
                     , B.ORG_ID                                                                                      AS ORG_ID
                     , A.ORG_CODE                                                                                    AS ORG_CODE
                     , B.ITEM_ID                                                                                     AS END_ITEM_ID
                     , A.ITEM_CODE                                                                                   AS END_ITEM_CODE
                     , CONCAT(B.ITEM_TYPE_CODE,' ',C.ITEM_TYPE_NAME)                                                 AS END_ITEM_TYPE_NAME
                     , A.PRODUCT_LINE_CODE                                                                           AS PRODUCT_LINE_CODE
                     , B.ITEM_ID                                                                                     AS PARENTS_ITEM_ID
                     , A.ITEM_CODE                                                                                   AS PARENT_ITEM_CODE
                     , 0                                                                                             AS ROW_NUM
                     , 0                                                                                             AS BOM_LEVEL
                     , 0                                                                                             AS COMPONENT_SEQUENCE_ID
                     , B.ITEM_ID                                                                                     AS COMPONENT_ITEM_ID
                     , A.ITEM_CODE                                                                                   AS COMPONENT_ITEM_CODE
                     , NULL                                                                                          AS WIP_SUPPLY_TYPE
                     , A.USAGE_QTY                                                                                   AS COMPONENT_QTY
                     , A.USAGE_QTY                                                                                   AS EXTENDED_QTY
                     , A.USAGE_QTY                                                                                   AS END_USED_QTY
                     , CASE WHEN A.USAGE_QTY = 0 THEN 0 ELSE ROUND((A.IMP_MATERIAL_COST + A.DOM_MATERIAL_COST + A.OUTSIDE_MATERIAL_COST) / A.USAGE_QTY,4) END AS PLN_MTL_COST
                     , CASE WHEN A.USAGE_QTY = 0 THEN 0 ELSE ROUND((A.IMP_MATERIAL_COST + A.DOM_MATERIAL_COST + A.OUTSIDE_MATERIAL_COST) / A.USAGE_QTY,4) END AS BASE_MTL_COST
                     , A.PURCHASE_DECREASE_AMOUNT - A.PURCHASE_INCREASE_AMOUNT                                       AS PUR_RED_AMOUNT
                     , A.DESIGN_DECREASE_AMOUNT - A.DESIGN_INCREASE_AMOUNT                                           AS DGN_RED_AMOUNT
                     , 0                                                                                             AS PROJECT_ID
                     , 0                                                                                             AS TASK_ID
                     , DATEADD(HOUR, 9 ,GETDATE())                                                                   AS ETL_DT
                  FROM T_DW_EPO_IPO_MP_COST_RED_RSLT A
            INNER JOIN T_DIM_FND_COM_ITEM             B
                    ON A.ORG_CODE = B.ORG_CODE
                   AND A.ITEM_CODE = B.ITEM_CODE
            INNER JOIN T_DIM_FND_COM_ITEM_TYPE        C
                    ON B.ITEM_TYPE_CODE = C.ITEM_TYPE_CODE
                 WHERE A.BASE_YYYYMM = @v_parm_to         --파라미타
       
       
                 UNION ALL
       
                SELECT A.YYYYMM
                     , A.ORGANIZATION_ID
                     , E.ORG_CODE
                     , A.ASSEMBLY_ITEM_ID
                     , E.ITEM_CODE
                     , CONCAT(E.ITEM_TYPE_CODE,' ',H.ITEM_TYPE_NAME)  AS ITEM_TYPE_NAME
                     , E.PRODUCT_LINE_CODE
                     , A.PARENTS_ITEM_ID
                     , F.ITEM_CODE            AS PARENT_ITEM_CODE
                     , A.ROW_NUM
                     , A.BOM_LEVEL
                     , A.COMPONENT_SEQUENCE_ID
                     , A.COMPONENT_ITEM_ID
                     , G.ITEM_CODE            AS COMPONENT_ITEM_CODE
                     , A.WIP_SUPPLY_TYPE
                     , A.COMPONENT_QUANTITY
                     , A.EXTENDED_QUANTITY
                     , A.USAGE_QTY
                     , CASE WHEN B.NEW_MM IS NULL THEN ISNULL(B.I_ITEM_COST,0) + ISNULL(B.O_ITEM_COST,0) + ISNULL(B.D_ITEM_COST,0) ELSE 0 END AS PLN_MTL_COST
                     , ISNULL(B.I_ITEM_COST,0) + ISNULL(B.O_ITEM_COST,0) + ISNULL(B.D_ITEM_COST,0) AS BASE_MTL_COST
                     , (ISNULL(C.PURCHASE_DECREASE_AMOUNT,0) - ISNULL(C.PURCHASE_INCREASE_AMOUNT,0)) + CASE WHEN D.RED_TYPE = 'PUR' THEN ISNULL(D.DECR - D.INCR,0) ELSE 0 END PUR_RED_AMT
                     , (ISNULL(C.DESIGN_DECREASE_AMOUNT,0)  - ISNULL(C.DESIGN_INCREASE_AMOUNT,0)) + CASE WHEN D.RED_TYPE = 'DGN' THEN ISNULL(D.DECR - D.INCR,0) ELSE 0 END DGN_RED_AMT
                     , A.PROJECT_ID
                     , A.TASK_ID
                     , DATEADD(HOUR, 9 ,GETDATE())                                                                   AS ETL_DT
                  FROM (
                          SELECT A2.YYYYMM
                               , A2.ORGANIZATION_ID
                               , A2.ASSEMBLY_ITEM_ID
                               , A2.PARENTS_ITEM_ID
                               , A2.ROW_NUM
                               , A2.BOM_LEVEL
                               , A2.COMPONENT_SEQUENCE_ID
                               , A2.COMPONENT_ITEM_ID
                               , A2.WIP_SUPPLY_TYPE
                               , A2.COMPONENT_QUANTITY
                               , A2.EXTENDED_QUANTITY
                               , A2.PROJECT_ID
                               , A2.TASK_ID
                               , B2.USAGE_QTY
                            FROM ERPSYS.ERP_EBOM_EXPLOSIONS_HIST A2
                      INNER JOIN (
                                    SELECT A3.BASE_YYYYMM
                                         , A3.ITEM_CODE
                                         , B3.ITEM_ID
                                         , A3.USAGE_QTY
                                      FROM T_DW_EPO_IPO_MP_COST_RED_RSLT A3
                                INNER JOIN T_DIM_FND_COM_ITEM B3
                                        ON A3.ORG_CODE = B3.ORG_CODE
                                       AND A3.ITEM_CODE = B3.ITEM_CODE
                                     WHERE A3.BASE_YYYYMM = @v_parm_to         --파라미타
                                 ) B2
                              ON A2.YYYYMM = B2.BASE_YYYYMM
                             AND A2.ASSEMBLY_ITEM_ID = B2.ITEM_ID
                           WHERE A2.YYYYMM = @v_parm_to         --파라미타
                       ) A       
       LEFT OUTER JOIN ERPSYS.ERP_EBOM_BI_MTL_ITEM_COST_V B
                    ON A.ORGANIZATION_ID = B.ORGANIZATION_ID
                   AND A.COMPONENT_ITEM_ID = B.ITEM_ID
                   AND SUBSTRING(A.YYYYMM,1,4) = B.YYYY
                  LEFT OUTER JOIN (
                          SELECT BASE_YYYYMM
                               , ORG_ID
                               , END_ITEM_ID
                               , ITEM_ID
                               , SUM(PURCHASE_DECREASE_AMOUNT) PURCHASE_DECREASE_AMOUNT
                               , SUM(PURCHASE_INCREASE_AMOUNT) PURCHASE_INCREASE_AMOUNT
                               , SUM(DESIGN_DECREASE_AMOUNT) DESIGN_DECREASE_AMOUNT
                               , SUM(DESIGN_INCREASE_AMOUNT) DESIGN_INCREASE_AMOUNT
                            FROM T_DW_EPO_MP_COST_RED_DETAIL
                           WHERE BASE_YYYYMM = @v_parm_to         --파라미타
                           GROUP BY BASE_YYYYMM
                               , ORG_ID
                               , END_ITEM_ID
                               , ITEM_ID
                       ) C       
                    ON A.ORGANIZATION_ID = C.ORG_ID
                   AND A.ASSEMBLY_ITEM_ID = C.END_ITEM_ID
                   AND A.COMPONENT_ITEM_ID = C.ITEM_ID
                   AND A.YYYYMM = C.BASE_YYYYMM
       LEFT OUTER JOIN V_DW_WIP_RED_BOM_CHANGE D
                    ON A.ORGANIZATION_ID = D.ORG_ID
                   AND A.ASSEMBLY_ITEM_ID = D.END_ITEM_ID
                   AND A.COMPONENT_ITEM_ID = D.ITEM_ID
                   AND A.YYYYMM = D.BASE_YYYYMM
            INNER JOIN T_DIM_FND_COM_ITEM E
                    ON A.ORGANIZATION_ID = E.ORG_ID
                   AND A.ASSEMBLY_ITEM_ID = E.ITEM_ID
            INNER JOIN T_DIM_FND_COM_ITEM F
                    ON A.ORGANIZATION_ID = F.ORG_ID
                   AND A.PARENTS_ITEM_ID = F.ITEM_ID
            INNER JOIN T_DIM_FND_COM_ITEM G
                    ON A.ORGANIZATION_ID = G.ORG_ID
                   AND A.COMPONENT_ITEM_ID = G.ITEM_ID
            INNER JOIN T_DIM_FND_COM_ITEM_TYPE H
                    ON H.ITEM_TYPE_CODE = E.ITEM_TYPE_CODE 
                    ;


            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_WIP_RED_EXPLOSIONS_HIST]
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

CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_WIP_RED_BOM_CHANGE_01_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_WIP_RED_BOM_CHANGE_01_M_C' -- procedure name 
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
            
            DELETE FROM [dbo].[T_DW_WIP_RED_BOM_CHANGE]  
             WHERE BASE_YYYYMM = @v_parm_to --파라미타
            ;
             
            ;WITH BOM_CHANGE  AS (
                 SELECT A.YYYYMM  
                      , B.ORG_CODE
                      , B.ORG_ID
                      , A.SPG_CD                    AS PRODUCT_LINE_CODE
                      , A.END_ITEM    
                      , D.ITEM_ID                   AS END_ITEM_ID
                      , A.PARENT_ITEM 
                      , C.ITEM_ID                   AS PARENT_ITEM_ID
                      , A.COMP_ITEM   
                      , B.ITEM_ID
                      , CONCAT(CAST(B.ORG_ID AS INT), CAST(B.ITEM_ID AS INT))     AS ORG_ITEM_ID_KEY
                      , B.INVENTORY_TYPE_CODE
                      , B.ITEM_TYPE_CODE
                      , A.CHANGE_TYPE
                      , A.MFG_QUANTITY                  AS MFG_QTY       --생산수량
                      , A.SHIP_QUANTITY                 AS SHIP_QTY      --출하수량
                      , A.ACT_QTY                       AS ACT_QTY       --소요수량
                      , A.STANDARD_QUANTITY             AS STD_QTY       --계획단위수량
                      , A.STD_AMT                       AS STD_AMT       --계획단위가격
                      , A.COMPONENT_QUANTITY            AS COMPONENT_QTY --기준단위수량
                      , A.ACT_AMT                       AS ACT_AMT       --기준단위금액
                      , A.ITEM_COST                     AS ITEM_COST     --품목단가
                      , A.DIFF_AMT                      AS DIFF_AMT      --생산수량 * 계획단위수량 * 품목단가 - (생산수량 * 기준단위수량 * 품목단가)
                      , A.OLD_YYYYMM                    AS OLD_YYYYMM    --발생년월
                      , DATEADD(HOUR, 9 ,GETDATE())     AS ETL_DT
                   FROM ERPSYS.ERP_EBOM_BI_BOM_CHANGE_V A
             INNER JOIN T_DIM_FND_COM_ITEM B
                     ON A.ORGANIZATION_CODE = B.ORG_CODE
                    AND A.COMP_ITEM = B.ITEM_CODE
             INNER JOIN T_DIM_FND_COM_ITEM C
                     ON A.ORGANIZATION_CODE = C.ORG_CODE
                    AND A.PARENT_ITEM = C.ITEM_CODE
             INNER JOIN T_DIM_FND_COM_ITEM D
                     ON A.ORGANIZATION_CODE = D.ORG_CODE
                    AND A.END_ITEM = D.ITEM_CODE
             INNER JOIN T_DIM_FND_COM_ORG  E
                     ON A.ORGANIZATION_CODE = E.ORG_CODE
                  WHERE E.OU_ID = 89
                    AND A.CHANGE_TYPE IN ('Deleted','Added','Changed')
                    AND A.YYYYMM = @v_parm_to                                         -- 파라미터 
                    AND A.PARENT_ITEM NOT IN ('72312731201','72312731202') --20150707 노용범C 요청
              )
              INSERT INTO [dbo].[T_DW_WIP_RED_BOM_CHANGE]
              (
                     BASE_YYYYMM
                   , ORG_CODE
                   , ORG_ID
                   , PRODUCT_LINE_CODE
                   , END_ITEM_CODE
                   , END_ITEM_ID
                   , PARENT_ITEM_CODE
                   , PARENT_ITEM_ID
                   , ITEM_CODE
                   , ITEM_ID
                   , ORG_ITEM_ID_KEY
                   , INVENTORY_TYPE_CODE
                   , ITEM_TYPE_CODE
                   , CHANGE_TYPE
                   , MFG_QTY
                   , SHIP_QTY
                   , ACT_QTY
                   , STD_QTY
                   , STD_AMT
                   , COMPONENT_QTY
                   , ACT_AMT
                   , ITEM_COST
                   , DIFF_AMT
                   , OLD_YYYYMM
                   , ETL_DT
              )
              SELECT B.YYYYMM AS BASE_YYYYMM
                   , B.ORG_CODE
                   , B.ORG_ID
                   , B.PRODUCT_LINE_CODE
                   , B.END_ITEM AS END_ITEM_CODE    
                   , B.END_ITEM_ID
                   , B.PARENT_ITEM AS PARENT_ITEM_CODE
                   , B.PARENT_ITEM_ID
                   , B.COMP_ITEM AS ITEM_CODE
                   , B.ITEM_ID
                   , B.ORG_ITEM_ID_KEY
                   , B.INVENTORY_TYPE_CODE
                   , B.ITEM_TYPE_CODE
                   , B.CHANGE_TYPE
                   , B.MFG_QTY
                   , B.SHIP_QTY
                   , B.ACT_QTY
                   , B.STD_QTY
                   , B.STD_AMT
                   , B.COMPONENT_QTY
                   , B.ACT_AMT
                   , B.ITEM_COST
                   , B.DIFF_AMT
                   , B.OLD_YYYYMM
                   , B.ETL_DT
                FROM (
                        SELECT YYYYMM
                             , END_ITEM
                             , PARENT_ITEM
                             , COMP_ITEM
                          FROM BOM_CHANGE 
                         
                         EXCEPT 
                               
                        --ITEM_CODE 상위 PARENT_ITEM_CODE 반제품이 존재할 경우 ITEM_CODE(반제품) 제외
                        --20150415 서광석 부장님님 요청 자재코드가 상위 반제품에 존재하면 제외 하기로 함
                     --20150512 BOM변경이력 화면에서 나오는 데이터와 부서별절감실적에서 나오는 데이터와 일치하기 위해서 상위 자재코드를 실적에서 제외
                           SELECT DISTINCT
                                  A.YYYYMM
                                , B.END_ITEM
                                , B.PARENT_ITEM
                                , B.COMP_ITEM
                             FROM BOM_CHANGE A
                       INNER JOIN (
                                    SELECT END_ITEM
                                         , PARENT_ITEM
                                         , COMP_ITEM
                                      FROM BOM_CHANGE
                                  ) B
                               ON A.END_ITEM = B.END_ITEM
                              AND A.PARENT_ITEM = B.COMP_ITEM
                        ) A
          INNER JOIN BOM_CHANGE B
                  ON A.YYYYMM = B.YYYYMM
                 AND A.END_ITEM = B.END_ITEM
                 AND A.PARENT_ITEM = B.PARENT_ITEM
                 AND A.COMP_ITEM = B.COMP_ITEM
                 --AND    A.END_ITEM <> '70421636008'; --20140902 노동채 과장님 요청 20150511서광석 부장님 요청으로 제외 
             ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_WIP_RED_BOM_CHANGE]
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

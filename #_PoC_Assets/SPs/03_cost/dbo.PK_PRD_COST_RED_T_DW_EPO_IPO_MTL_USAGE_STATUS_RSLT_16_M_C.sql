CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_MTL_USAGE_STATUS_RSLT_16_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_MTL_USAGE_STATUS_RSLT_16_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_DW_EPO_IPO_MTL_USAGE_STATUS_RSLT]  
                 WHERE BASE_YYYYMM = @v_parm_to --파라미타 
                 ; 

                INSERT INTO [dbo].[T_DW_EPO_IPO_MTL_USAGE_STATUS_RSLT]
                (      [BASE_YYYYMM]
                     , [ORG_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [ITEM_CODE]
                     , [SERIAL_NO]
                     , [RECEIVING_YYYYMM]
                     , [RECEIVING_QTY]
                     , [USAGE_QTY]
                     , [MFG_ITEM_CODE]
                     , [MFG_TYPE]
                     , [ETL_DT]
                )
                SELECT A.BASE_YYYYMM                            AS BASE_YYYYMM           --기준년월
                     , A.ORG_CODE                               AS ORG_CODE              --ORG코드
                     , A.PRODUCT_LINE_CODE                      AS PRODUCT_LINE_CODE     --제품류코드
                     , A.ITEM_CODE                              AS ITEM_CODE             --품목코드
                     , ROW_NUMBER() OVER(ORDER BY (SELECT 1))   AS SERIAL_NO             --일련번호
                     , A.RECEIPT_YYYYMM                         AS RECEIVING_YYYYMM      --입고년월
                     , A.RECEIPT_QTY                            AS RECEIVING_QTY         --입고수량
                     , A.USED_QTY                               AS USAGE_QTY             --사용수량
                     , A.END_ITEM_CODE                          AS MFG_ITEM_CODE         --생산품목코드
                     , CASE WHEN B.INVENTORY_TYPE_CODE IN ('Parts','Raw Material') THEN B.INVENTORY_TYPE_CODE ELSE B.PURCHASE_TYPE_NAME END AS MFG_TYPE
                     , DATEADD(HOUR, 9 ,GETDATE())              AS ETL_DT
                  FROM T_DW_EPO_MP_COST_RED_DETAIL A
            INNER JOIN T_DIM_FND_COM_ITEM B
                    ON A.ITEM_ID = B.ITEM_ID
                   AND A.ORG_ID = B.ORG_ID
                 WHERE A.BASE_YYYYMM = @v_parm_to     --파라미터
                   AND A.UP_DOWN <> '-'
                   ; 

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_MTL_USAGE_STATUS_RSLT]
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
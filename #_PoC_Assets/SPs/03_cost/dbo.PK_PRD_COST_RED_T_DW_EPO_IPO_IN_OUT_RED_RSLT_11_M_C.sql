CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_IN_OUT_RED_RSLT_11_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_IN_OUT_RED_RSLT_11_M_C' -- procedure name 
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

                DELETE FROM [dbo].[T_DW_EPO_IPO_IN_OUT_RED_RSLT]
                WHERE YYYYMM = @v_parm_to   --파라미터 
                ; 
                INSERT INTO [dbo].[T_DW_EPO_IPO_IN_OUT_RED_RSLT] 
                (      [YYYYMM]
                     , [ORG_ID]
                     , [DEPARTMENT_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [ITEM_ID]
                     , [OUT_ITEM_CODE]
                     , [BPA_NO]
                     , [BUYER_NM]
                     , [VENDOR]
                     , [MFG_TYPE]
                     , [QTY]
                     , [BASE_UNIT_PRICE]
                     , [RECEIVING_UNIT_PRICE]
                     , [UNIT_PRICE_VARIANCE]
                     , [MTL_COST_RED_AMOUNT]
                     , [DISTRIBUTION_RATE]
                     , [ETL_DT]
                )
                SELECT YYYYMM
                     , ORGANIZATION_ID                        AS ORG_ID
                     , TRIM(ATTRIBUTE8)                       AS DEPARTMENT_CODE      --부서코드
                     , SPG_CD                                 AS PRODUCT_LINE_CODE    --제품류코드
                     , ASSEMBLY_ITEM_ID                       AS ITEM_ID              --ITEM_ID
                     , ATTRIBUTE5                             AS OUT_ITEM_CODE        --외작품목코드
                     , ATTRIBUTE2                             AS BPA_NO               --BPA_NO
                     , ATTRIBUTE10                            AS BUYER_NM             --바이어명
                     , ATTRIBUTE6                             AS VENDOR               --공급업체
                     , N'외작화'                              AS MFG_TYPE             --생산구분
                     , CAST(ATTRIBUTE4 AS DECIMAL(21,4))                 AS QTY                  --입고수량
                     , CAST(ATTRIBUTE1 AS DECIMAL(21,4))                 AS BASE_UNIT_PRICE      --기준단가 NUMBER(20,4)
                     , CAST(ATTRIBUTE3 AS DECIMAL(21,4))                 AS RECEIVING_UNIT_PRICE --입고단가 NUMBER(20,4)
                     , CAST(ATTRIBUTE1 AS DECIMAL(21,4))  - CAST(ATTRIBUTE3 AS DECIMAL(21,4)) AS UNIT_PRICE_VARIANCE  --단가차 NUMBER(16,4)
                     , (CAST(ATTRIBUTE1 AS DECIMAL(21,4)) - CAST(ATTRIBUTE3 AS DECIMAL(21,4))) * CAST(ATTRIBUTE4 AS DECIMAL(21,4)) * (CAST(ATTRIBUTE9 AS DECIMAL(21,4)) / 100) AS MTL_COST_RED_AMOUNT  --절감금액 NUMBER(20,4)
                     , CAST(ATTRIBUTE9 AS DECIMAL(21,4))                 AS DISTRIBUTION_RATE    --배분율   NUMBER(16,4)
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_BOM_CHANGE_MONTHLY
                 WHERE YYYYMM = @v_parm_to   --파라미터
                   AND CHANGE_TYPE = 'MAKE_BUY_CHANGE'
                   AND ISNUMERIC(ATTRIBUTE1) = 1 
                   AND CAST(ATTRIBUTE1 AS DECIMAL(21,4)) > 0                                           --사업 계획 시점 제조원가 0 제외
                   AND ATTRIBUTE7 NOT IN ('REASON_16','REASON_17','REASON_17','REASON_18') --단가 변경 사유 통제불가 제외
                   AND ASSEMBLY_ITEM_ID <> 2433986                                         --20140811 김영근, 조영기 , 노동채 신제품 관련 아이템 제외 해달라고 요청함
                   AND ORGANIZATION_ID <> 256
                   AND ASSEMBLY_ITEM_ID NOT IN (2470703,2470696) --20150707 노용범C 요청
                   ;
                   
                      
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_IN_OUT_RED_RSLT]
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
        --SELECT @v_pgm_status, @v_err_mesg, @v_load_cnt
           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

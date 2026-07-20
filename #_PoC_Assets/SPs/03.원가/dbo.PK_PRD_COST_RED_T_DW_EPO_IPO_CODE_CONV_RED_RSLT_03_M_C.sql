CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_CODE_CONV_RED_RSLT_03_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_CODE_CONV_RED_RSLT_03_M_C' -- procedure name 
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
         
                DELETE FROM T_DW_EPO_IPO_CODE_CONV_RED_RSLT 
                 WHERE BASE_YYYYMM = @v_parm_to   --파라미타 
                 ;
                
                INSERT INTO [dbo].[T_DW_EPO_IPO_CODE_CONV_RED_RSLT]
                (      BASE_YYYYMM
                     , ORG_CODE
                     , ITEM_CODE
                     , ITEM_NAME
                     , PRODUCT_LINE_CODE
                     , PRODUCT_LINE_NAME
                     , DEPARTMENT_CODE
                     , CODE_CONVERSION_QTY
                     , CODE_CONV_UNIT_PRICE
                     , OLD_UNIT_PRICE
                     , ALLOCATION_RATE
                     , ETL_DT
                )
                SELECT BASE_YYYYMM                                               -- 기준년월
                     , ORG_CODE                                                  -- ORG_코드
                     , ITEM_CODE                                                 -- 품목코드
                     , ITEM_NAME                                                 -- 품명
                     , PRODUCT_LINE_CODE                                         -- 제품류코드
                     , PRODUCT_LINE_NAME                                         -- 제품류명
                     , CASE WHEN B.DEPT_CODE IS NOT NULL THEN B.DEPT_CODE ELSE C.DESCRIPTION END    AS DEPARTMENT_CODE -- 부서코드
                     , CODE_CONVERSION_QTY                                       --코드변환수량
                     , CODE_CONV_UNIT_PRICE                                      --코드변환단가
                     , OLD_UNIT_PRICE                                            --과거단가
                     , CASE WHEN B.ALLC_RATE IS NOT NULL THEN B.ALLC_RATE / 100 ELSE 1 END          AS ALLOCATION_RATE -- 배부율
                     , DATEADD(HOUR, 9 ,GETDATE())                                                  AS ETL_DT
                  FROM (
                              SELECT BASE_YYYYMM                                             -- 기준년월
                                   , ORG_ID                                                  -- ORG_ID
                                   , ORG_CODE                                                -- ORG_코드
                                   , ITEM_CODE                                               -- 품목코드
                                   , ITEM_ID                                                 -- ITEM_ID
                                   , ITEM_NAME                                               -- 품명
                                   , PRODUCT_LINE_CODE                                       -- 제품류코드
                                   , PRODUCT_LINE_NAME                                       -- 제품류명
                                   , MAX(CODE_CONVERSION_QTY)     AS CODE_CONVERSION_QTY     -- 코드변환수량
                                   , SUM(CODE_CONV_UNIT_PRICE)    AS CODE_CONV_UNIT_PRICE    -- 코드변환단가
                                   , SUM(OLD_UNIT_PRICE)          AS OLD_UNIT_PRICE          -- 과거단가
                                FROM (
                                        SELECT A.YYYYMM                        AS BASE_YYYYMM          -- 기준년월
                                             , A.ORGANIZATION_ID               AS ORG_ID               -- ORG_ID
                                             , C.ORG_CODE                      AS ORG_CODE             -- ORG_코드
                                             , C.ITEM_CODE                     AS ITEM_CODE            -- 품목코드
                                             , C.ITEM_ID                       AS ITEM_ID
                                             , C.ITEM_NAME                     AS ITEM_NAME            -- 품명
                                             , C.PRODUCT_LINE_CODE             AS PRODUCT_LINE_CODE    -- 제품류코드
                                             , C.PRODUCT_LINE_NAME             AS PRODUCT_LINE_NAME    -- 제품류명
                                             , A.TRANSFER_QTY                  AS CODE_CONVERSION_QTY  -- 코드변환수량
                                             , H.KRW_PRICE                     AS CODE_CONV_UNIT_PRICE -- 코드변환단가
                                             , D.KRW_PRICE                     AS OLD_UNIT_PRICE       -- 과거단가
                                          FROM ERPSYS.ERP_EBOM_CODE_TRANSFER_MON A
                                    INNER JOIN T_DIM_FND_COM_ITEM B
                                            ON A.ORGANIZATION_ID = B.ORG_ID
                                           AND A.ITEM_ID = B.ITEM_ID
                                    INNER JOIN T_DIM_FND_COM_ITEM C
                                            ON A.ORGANIZATION_ID = C.ORG_ID
                                           AND A.C_ITEM_ID = C.ITEM_ID
                                    INNER JOIN ERPSYS.ERP_EBOM_BI_PLAN_BPA_V D
                                            ON D.YYYY = LEFT(@v_parm_to, 4)
                                           AND D.ORGANIZATION_CODE = B.ORG_CODE
                                           AND D.ITEM_CODE = B.ITEM_CODE
                                    INNER JOIN T_DIM_FND_COM_ORG F
                                            ON A.ORGANIZATION_ID = F.ORG_ID
                                           AND F.OU_ID = 89
                               LEFT OUTER JOIN ERPSYS.ERP_EBOM_BI_PLAN_BPA_V H
                                            ON H.ORGANIZATION_CODE = C.ORG_CODE
                                           AND H.ITEM_CODE = C.ITEM_CODE
                                           AND H.YYYY = LEFT(@v_parm_to, 4)
                                         WHERE A.YYYYMM = @v_parm_to
       
                                         UNION ALL
       
                                        SELECT A.BASE_YYYYMM                       -- 기준년월
                                             , B.ORG_ID                            -- ORG_ID
                                             , A.ORG_CODE                          -- ORG_코드
                                             , A.ITEM_CODE                         -- 품목코드
                                             , B.ITEM_ID                           -- ITEM_ID
                                             , B.ITEM_NAME                         -- 품명
                                             , A.PRODUCT_LINE_CODE                 -- 제품류코드
                                             , C.PRODUCT_LINE_NAME                 -- 제품류명
                                             , A.RECEIVING_QTY                     AS CODE_CONVERSION_QTY -- 코드변환수량
                                             , A.RECEIVING_BPA_KRW_UNIT_PRICE      AS CODE_CONV_UNIT_PRICE -- 코드변환단가
                                             , A.PREVIOUS_BPA_KRW_UNIT_PRICE       AS OLD_UNIT_PRICE -- 과거단가
                                          FROM T_DW_EPO_IPO_RCV_BASE_RED_DTL A
                                    INNER JOIN T_DIM_FND_COM_ITEM B
                                            ON A.ORG_CODE = B.ORG_CODE
                                           AND A.ITEM_CODE = B.ITEM_CODE
                                    INNER JOIN T_DIM_FND_COM_PROD_LN C
                                            ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                         WHERE A.BASE_YYYYMM = @v_parm_to
                                           AND A.AGGR_STATUS_TYPE_CODE NOT IN ('E','7','L')  --통제불가 사유 제외
                                           AND A.ITEM_CODE LIKE '%C'
                                           AND SUBSTRING(A.ITEM_CODE,LEN(A.ITEM_CODE) -1,2) <> 'CC'
                                     ) A 
                            GROUP BY BASE_YYYYMM
                                   , ORG_ID
                                   , ORG_CODE
                                   , ITEM_CODE
                                   , ITEM_ID
                                   , ITEM_NAME
                                   , PRODUCT_LINE_CODE
                                   , PRODUCT_LINE_NAME 
                       ) A
       LEFT OUTER JOIN ERPSYS.ERP_EBOM_DEPT_ALLOC_RATE B
                    ON A.ORG_ID = B.ORGANIZATION_ID
                   AND A.ITEM_ID = B.ITEM_ID
       LEFT OUTER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES C
                    ON A.PRODUCT_LINE_CODE = C.LOOKUP_CODE
                   AND C.LOOKUP_TYPE = 'EBOM_PLAN_DEFAULT_ENG_DEPT'
                   ; 

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_CODE_CONV_RED_RSLT]
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

CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_CODE_CONV_RED_RSLT_DTL_04_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_CODE_CONV_RED_RSLT_DTL_04_M_C' -- procedure name 
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

        /* Parameter Setting */ 
                DELETE FROM [dbo].[T_DW_EPO_IPO_CODE_CONV_RED_RSLT_DTL] 
                 WHERE BASE_YYYYMM = @v_parm_to
                 ;

                INSERT INTO [dbo].[T_DW_EPO_IPO_CODE_CONV_RED_RSLT_DTL]
                (
                       BASE_YYYYMM
                     , ORG_CODE
                     , ITEM_CODE
                     , SEQ_NO
                     , PRODUCT_LINE_CODE
                     , DEPARTMENT_CODE
                     , ITEM_NAME
                     , PRODUCT_LINE_NAME
                     , DEPARTMENT_NAME
                     , GUBUN
                     , BPA_NO
                     , BUYER_NM
                     , CODE_CONVERSION_QTY
                     , CODE_CONV_UNIT_PRICE
                     , OLD_UNIT_PRICE
                     , ALLOCATION_RATE
                     , DECR_AMOUNT
                     , INCR_AMOUNT
                     , MTL_COST_RED_AMOUNT
                     , ETL_DT
                )
                SELECT A.BASE_YYYYMM        -- 기준년월
                     , A.ORG_CODE           -- ORG_코드
                     , A.ITEM_CODE          -- 품목코드
                     , ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS SEQ_NO
                     , A.PRODUCT_LINE_CODE          -- 제품류코드
                     , A.DEPARTMENT_CODE            -- 부서코드
                     , A.ITEM_NAME                  -- 품명
                     , A.PRODUCT_LINE_NAME          -- 제품류명
                     , B.DEPARTMENT_NAME            -- 부서명
                     , A.GUBUN                      -- 구분
                     , A.BPA_NO                     -- BPA
                     , A.BUYER_NM                   -- 담당자
                     , A.CODE_CONVERSION_QTY        -- 코드변환수량
                     , A.CODE_CONV_UNIT_PRICE       -- 코드변환단가
                     , A.OLD_UNIT_PRICE             -- 과거단가
                     , A.ALLOCATION_RATE            -- 배부율
                     , CASE WHEN OLD_UNIT_PRICE - CODE_CONV_UNIT_PRICE > 0 THEN (OLD_UNIT_PRICE - CODE_CONV_UNIT_PRICE) * CODE_CONVERSION_QTY * ALLOCATION_RATE ELSE 0 END AS DECR_AMOUNT --인하금액
                     , CASE WHEN OLD_UNIT_PRICE - CODE_CONV_UNIT_PRICE < 0 THEN (CODE_CONV_UNIT_PRICE - OLD_UNIT_PRICE) * CODE_CONVERSION_QTY * ALLOCATION_RATE ELSE 0 END AS INCR_AMOUNT --인상금액
                     , CASE WHEN OLD_UNIT_PRICE - CODE_CONV_UNIT_PRICE > 0 THEN (OLD_UNIT_PRICE - CODE_CONV_UNIT_PRICE) * CODE_CONVERSION_QTY * ALLOCATION_RATE ELSE 0 END - CASE WHEN OLD_UNIT_PRICE - CODE_CONV_UNIT_PRICE < 0 THEN (CODE_CONV_UNIT_PRICE - OLD_UNIT_PRICE) * CODE_CONVERSION_QTY * ALLOCATION_RATE ELSE 0 END AS MTL_COST_RED_AMOUNT -- 절감금액
                     , DATEADD(HOUR, 9 ,GETDATE())     AS ETL_DT
                  FROM    (
                             SELECT A.YYYYMM              AS BASE_YYYYMM    -- 기준년월
                                  , E.ORG_CODE         
                                  , E.ITEM_CODE        
                                  , E.ITEM_NAME        
                                  , E.PRODUCT_LINE_CODE
                                  , E.PRODUCT_LINE_NAME
                                  , CASE WHEN C.DEPT_CODE IS NOT NULL THEN C.DEPT_CODE ELSE G.DESCRIPTION END AS DEPARTMENT_CODE     -- 부서코드
                                  , N'코드변환'            AS GUBUN                         -- 구분
                                  , ''                    AS BPA_NO                         -- BPA
                                  , ''                    AS BUYER_NM                       -- 담당자
                                  , A.TRANSFER_QTY        AS CODE_CONVERSION_QTY            -- 코드변환수량
                                  , H.KRW_PRICE           AS CODE_CONV_UNIT_PRICE           -- 코드변환단가
                                  , B.KRW_PRICE           AS OLD_UNIT_PRICE                 -- 과거단가
                                  , CASE WHEN C.ALLC_RATE IS NOT NULL THEN C.ALLC_RATE/100 ELSE 1 END AS ALLOCATION_RATE -- 배부율
                               FROM ERPSYS.ERP_EBOM_CODE_TRANSFER_MON A
                         INNER JOIN T_DIM_FND_COM_ITEM D
                                 ON A.ORGANIZATION_ID = D.ORG_ID
                                AND A.ITEM_ID = D.ITEM_ID
                         INNER JOIN T_DIM_FND_COM_ITEM E
                                 ON A.ORGANIZATION_ID = E.ORG_ID
                                AND A.C_ITEM_ID = E.ITEM_ID
                         INNER JOIN ERPSYS.ERP_EBOM_BI_PLAN_BPA_V B
                                 ON B.YYYY = LEFT(@v_parm_to, 4)           --파라미터
                                AND B.ORGANIZATION_CODE = D.ORG_CODE
                                AND B.ITEM_CODE = D.ITEM_CODE
                   LEFT OUTER  JOIN ERPSYS.ERP_EBOM_DEPT_ALLOC_RATE C
                                 ON C.ORGANIZATION_ID = E.ORG_ID
                                AND C.ITEM_ID = E.ITEM_ID
                         INNER JOIN T_DIM_FND_COM_ORG F
                                 ON A.ORGANIZATION_ID = F.ORG_ID
                                AND F.OU_ID = 89
                    LEFT OUTER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES G
                                 ON E.PRODUCT_LINE_CODE = G.LOOKUP_CODE
                                AND G.LOOKUP_TYPE = 'EBOM_PLAN_DEFAULT_ENG_DEPT'
                    LEFT OUTER JOIN ERPSYS.ERP_EBOM_BI_PLAN_BPA_V H
                                 ON H.ORGANIZATION_CODE = E.ORG_CODE
                                AND H.ITEM_CODE = E.ITEM_CODE
                                AND H.YYYY = LEFT(@v_parm_to, 4)        --파라미터
                              WHERE A.YYYYMM = @v_parm_to               --파라미터

                              UNION ALL

                             SELECT A.BASE_YYYYMM                                           -- 기준년월
                                  , A.ORG_CODE                                              -- ORG_코드
                                  , A.ITEM_CODE                                             -- 품목코드
                                  , B.ITEM_NAME                                             -- 품명
                                  , A.PRODUCT_LINE_CODE                                     -- 제품류코드
                                  , C.PRODUCT_LINE_NAME                                     -- 제품류명
                                  , A.DEPARTMENT_CODE                                       -- 부서코드
                                  , N'단가변경'                     AS GUBUN                -- 구분
                                  , A.RECEIVING_BPA_NO              AS BPA_NO               -- BPA
                                  , A.PURCHASE_BPA_CONTACT          AS BUYER_NM             -- 담당자
                                  , A.RECEIVING_QTY                 AS CODE_CONVERSION_QTY  -- 입고수량
                                  , A.RECEIVING_BPA_KRW_UNIT_PRICE  AS CODE_CONV_UNIT_PRICE -- 입고BPA원화단가
                                  , A.PREVIOUS_BPA_KRW_UNIT_PRICE   AS OLD_UNIT_PRICE       -- 이전BPA원화단가
                                  , A.DISTRIBUTION_RATE             AS ALLOCATION_RATE      -- 배부율
                               FROM T_DW_EPO_IPO_RCV_BASE_RED_DTL A
                         INNER JOIN T_DIM_FND_COM_ITEM B
                                 ON A.ORG_CODE = B.ORG_CODE
                                AND A.ITEM_CODE = B.ITEM_CODE
                         INNER JOIN T_DIM_FND_COM_PROD_LN C
                                 ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                              WHERE A.BASE_YYYYMM = @v_parm_to          --파라미터
                                AND A.AGGR_STATUS_TYPE_CODE NOT IN ('E','7','L')  --통제불가 사유 제외
                                AND A.ITEM_CODE LIKE '%C'
                                AND SUBSTRING(A.ITEM_CODE,LEN(A.ITEM_CODE) -1,2) <> 'CC'
                          ) A
            INNER JOIN T_DIM_FND_COM_DEPARTMENT B
                    ON A.DEPARTMENT_CODE = B.DEPARTMENT_CODE  
                 ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_CODE_CONV_RED_RSLT_DTL]
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

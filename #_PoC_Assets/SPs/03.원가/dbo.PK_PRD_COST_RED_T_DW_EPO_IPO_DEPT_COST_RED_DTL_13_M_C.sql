CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_DEPT_COST_RED_DTL_13_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_DEPT_COST_RED_DTL_13_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_DW_EPO_IPO_DEPT_COST_RED_DTL] 
                 WHERE BASE_YYYYMM = @v_parm_to     --파라미터
                 ;

                INSERT INTO [dbo].[T_DW_EPO_IPO_DEPT_COST_RED_DTL]
                (
                       [BASE_YYYYMM]
                     , [ORG_CODE]
                     , [ITEM_CODE] 
                     , [ORG_ITEM_CODE_KEY]
                     , [PRODUCT_LINE_CODE]
                     , [PRODUCT_LINE_NAME]
                     , [DEPARTMENT_CODE]
                     , [SERIAL_NO]
                     , [MFG_TYPE]
                     , [GUBUN]
                     , [BPA_NO]
                     , [BPA_BUYER]
                     , [SUPPLIER_BUYER]
                     , [VENDOR]
                     , [IMP_MTL_CUT]
                     , [IMP_MTL_RAISE]
                     , [DOM_MTL_CUT]
                     , [DOM_MTL_RAISE]
                     , [RAW_MTL_CUT]
                     , [RAW_MTL_RAISE]
                     , [BPA_COMMENTS]
                     , [REASON_DESCR]
                     , [BPA_START_DATE]
                     , [ETL_DT]
                )
                SELECT A.BASE_YYYYMM                            AS BASE_YYYYMM          --기준년월
                     , A.ORG_CODE                               AS ORG_CODE             --ORG_CODE
                     , A.ITEM_CODE                              AS ITEM_CODE            --품목코드
                     , CONCAT(A.ORG_CODE, A.ITEM_CODE)
                     , A.PRODUCT_LINE_CODE                      AS PRODUCT_LINE_CODE    --제품류코드
                     , MAX(A.PRODUCT_LINE_NAME)                 AS PRODUCT_LINE_NAME    --제품류명
                     , A.DEPARTMENT_CODE                        AS DEPARTMENT_CODE      --부서코드
                     , SERIAL_NO   AS SERIAL_NO               
                     , MAX(A.MFG_TYPE)                          AS MFG_TYPE             --생산구분
                     , GUBUN                                    AS GUBUN                --실적구분
                     , A.BPA                                    AS BPA                  --BPA 
                     , C.FULL_NAME                              AS BPA_Buyer            --BPA 바이어명 
                     , A.Supplier_Buyer                         AS Supplier_Buyer       --바이어명
                     , A.VENDOR                                 AS VENDOR               --공급업체
                     , SUM(A.IMP_MTL_CUT)                       AS IMP_MTL_CUT          --도입재인하
                     , SUM(A.IMP_MTL_RAISE)                     AS IMP_MTL_RAISE        --도입재인상
                     , SUM(A.DOM_MTL_CUT)                       AS DOM_MTL_CUT          --국내재인하
                     , SUM(A.DOM_MTL_RAISE)                     AS DOM_MTL_RAISE        --국내재인상
                     , SUM(A.RAW_MTL_CUT)                       AS RAW_MTL_CUT          --원재료인하
                     , SUM(A.RAW_MTL_RAISE)                     AS RAW_MTL_RAISE        --원재료인상
                     , A.BPA_COMMENTS                           AS BPA_COMMENTS         --BPA_DESC
                     , A.REASON_DESCR                           AS REASON_DESCR         --TRAN_REAS
                     , D.START_DATE BPA_START_DATE  -- 20211116 기능개선 SRM2110-07571 BPA유효시작일 추가
                     , DATEADD(HOUR, 9 ,GETDATE())              AS ETL_DT                       
                  FROM (   
                         SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS SERIAL_NO
                           FROM ( 
                                    --구매
                                     SELECT A.BASE_YYYYMM                                       --기준년월
                                          , A.ORG_CODE                                          --ORG_CODE
                                          , A.ITEM_CODE                                         --품목코드
                                          , C.PRODUCT_LINE_CODE                                 --제품류코드
                                          , C.PRODUCT_LINE_NAME                                 --제품류명
                                          , TRIM(A.TEAM)                AS DEPARTMENT_CODE      --부서코드
                                          , A.END_FLAG_NAME             AS MFG_TYPE             --생산구분
                                          , N'1.생산에투입된자재(입고)' AS GUBUN                --실적구분
                                          , A.BPA                       AS BPA                  --BPA
                                          , A.BUYER                     AS Supplier_Buyer       --바이어명
                                          , A.VENDOR                    AS VENDOR               --공급업체
                                          , SUM(A.IMP_MTL_DECR_AMOUNT)  AS IMP_MTL_CUT          --도입재인하
                                          , SUM(A.IMP_MTL_INCR_AMOUNT)  AS IMP_MTL_RAISE        --도입재인상
                                          , SUM(A.DOM_MTL_DECR_AMOUNT)  AS DOM_MTL_CUT          --국내재인하
                                          , SUM(A.DOM_MTL_INCR_AMOUNT)  AS DOM_MTL_RAISE        --국내재인상
                                          , 0                           AS RAW_MTL_CUT          --원재료인하
                                          , 0                           AS RAW_MTL_RAISE        --원재료인상
                                          , A.BPA_COMMENTS                                      --BPA_DESC
                                          , A.REASON_DESCR                                      --TRAN_REAS
                                       FROM T_DW_EPO_MP_COST_RED_DETAIL A
                                 INNER JOIN T_DIM_FND_COM_ITEM I
                                         ON I.ORG_CODE = A.ORG_CODE
                                        AND I.ITEM_CODE = A.ITEM_CODE
                                 INNER JOIN T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP C
                                         ON I.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                      WHERE A.BASE_YYYYMM = @v_parm_to     --파라미터
                                   GROUP BY A.BASE_YYYYMM
                                          , A.ORG_CODE
                                          , A.ITEM_CODE
                                          , C.PRODUCT_LINE_CODE
                                          , C.PRODUCT_LINE_NAME
                                          , TRIM(A.TEAM)
                                          , A.END_FLAG_NAME
                                          , A.BPA
                                          , A.BUYER
                                          , A.VENDOR
                                          , A.BPA_COMMENTS
                                          , A.REASON_DESCR
                                            
                                      UNION ALL --BOM
                                            
                                     SELECT BC.BASE_YYYYMM                                      --기준년월
                                          , BC.ORG_CODE                                         --ORG_CODE
                                          , BC.END_ITEM_CODE                                    --품목코드
                                          , BC.PRODUCT_LINE_CODE                                --제품류코드
                                          , BC.PRODUCT_LINE_NAME                                --제품류명
                                          , TRIM(BC.DEPT_CODE)         AS DEPARTMENT_CODE       --부서코드
                                          , BC.MFG_TYPE                AS MFG_TYPE              --생산구분
                                          , N'2.BOM변경'               AS GUBUN                 --실적구분
                                          , NULL                       AS BPA                   --BPA
                                          , NULL                       AS Supplier_Buyer        --바이어명
                                          , NULL                       AS VENDOR                --공급업체
                                          , 0                          AS IMP_MTL_CUT           --도입재인하
                                          , 0                          AS IMP_MTL_RAISE         --도입재인상
                                          , SUM(BC.DECR)               AS DOM_MTL_CUT           --국내재인하
                                          , SUM(BC.INCR)               AS DOM_MTL_RAISE         --국내재인상
                                          , 0                          AS RAW_MTL_CUT           --원재료인하
                                          , 0                          AS RAW_MTL_RAISE         --원재료인상
                                          , NULL                       AS BPA_COMMENTS          --BPA_DESC
                                          , NULL                       AS REASON_DESCR          --TRAN_REAS
                                       FROM V_DW_WIP_RED_BOM_CHANGE BC
                                      WHERE BC.BASE_YYYYMM = @v_parm_to     --파라미터
                                   GROUP BY BC.BASE_YYYYMM
                                          , BC.ORG_CODE
                                          , BC.END_ITEM_CODE
                                          , BC.PRODUCT_LINE_CODE
                                          , BC.PRODUCT_LINE_NAME
                                          , TRIM(BC.DEPT_CODE)
                                          , BC.MFG_TYPE
                                            
                                      UNION ALL
                                            
                                     SELECT A.TARGET_MONTH             AS BASE_YYYYMM           --기준년월
                                          , A.ORGANIZATION_CODE        AS ORG_CODE              --ORG_CODE
                                          , A.ITEM                     AS ITEM_CODE             --품목코드
                                          , I3.PRODUCT_LINE_CODE       AS PRODUCT_LINE_CODE     --제품류코드
                                          , I3.PRODUCT_LINE_NAME       AS PRODUCT_LINE_NAME     --제품류명
                                          , TRIM(A.TEAM)               AS DEPARTMENT_CODE       --부서코드
                                          , N'원재료'                  AS MFG_TYPE              --생산구분
                                          , N'3.원재료'                AS GUBUN                 --실적구분
                                          , MAX(BPA)                   AS BPA                   --BPA
                        --                    MAX(BUYER)                 AS 바이어명
                                          , MAX(SUPPLY_BUYER)          AS Supplier_Buyer        --바이어명     --Supplier Buyer 로 표시 해야 함. 20220511
                                          , MAX(VENDOR)                                                              AS VENDOR           --공급업체
                                          , 0                                                                        AS IMP_MTL_CUT      --도입재인하
                                          , 0                                                                        AS IMP_MTL_RAISE    --도입재인상
                                          , 0                                                                        AS DOM_MTL_CUT      --국내재인하
                                          , 0                                                                        AS DOM_MTL_RAISE    --국내재인상
                                          , SUM(CASE WHEN A.UP_DAWN_GUBUN = '0' THEN ABS(A.AMOUNT_DIFF) ELSE 0 END)  AS RAW_MTL_CUT      --원재료인하
                                          , SUM(CASE WHEN A.UP_DAWN_GUBUN = '1' THEN ABS(A.AMOUNT_DIFF) ELSE 0 END)  AS RAW_MTL_RAISE    --원재료인상
                                          , NULL                       AS BPA_COMMENTS          --BPA_DESC
                                          , NULL                       AS REASON_DESCR          --TRAN_REAS
                                       FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V A
                                 INNER JOIN T_DIM_FND_COM_ITEM I3
                                         ON A.ORGANIZATION_CODE = I3.ORG_CODE
                                        AND A.ITEM = I3.ITEM_CODE
                                      WHERE TARGET_MONTH = @v_parm_to     --파라미터
                                        AND A.C_GUBUN ='R'
                                   GROUP BY A.TARGET_MONTH
                                          , A.ORGANIZATION_CODE
                                          , A.ITEM
                                          , I3.PRODUCT_LINE_CODE
                                          , I3.PRODUCT_LINE_NAME
                                          , TRIM(A.TEAM)
                                            
                                            
                                      UNION ALL -- RAW MATERIAL이 아닌 품목중에 재료비 절감에 포함되어야 하는 품목(은)
                                            
                                     SELECT A.TARGET_MONTH              AS BASE_YYYYMM          --기준년월
                                          , A.ORGANIZATION_CODE         AS ORG_CODE             --ORG_CODE
                                          , A.ITEM                      AS ITEM_CODE            --품목코드
                                          , I3.PRODUCT_LINE_CODE        AS PRODUCT_LINE_CODE    --제품류코드
                                          , I3.PRODUCT_LINE_NAME        AS PRODUCT_LINE_NAME    --제품류명
                                          , TRIM(A.TEAM)                AS DEPARTMENT_CODE      --부서코드
                                          , N'원재료'                   AS MFG_TYPE             --생산구분
                                          , N'4.제조에서만 사용된 자재' AS GUBUN                --실적구분
                                          , MAX(BPA)                    AS BPA                   --BPA
                        --                  ,    MAX(BUYER)                 AS 바이어명
                                          , MAX(SUPPLY_BUYER)           AS Supplier_Buyer       --바이어명     --Supplier Buyer 로 표시 해야 함. 20220511
                                          , MAX(VENDOR)                                                             AS VENDOR           --공급업체
                                          , 0                                                                       AS IMP_MTL_CUT      --도입재인하
                                          , 0                                                                       AS IMP_MTL_RAISE    --도입재인상
                                          , 0                                                                       AS DOM_MTL_CUT      --국내재인하
                                          , 0                                                                       AS DOM_MTL_RAISE    --국내재인상
                                          , SUM(CASE WHEN A.UP_DAWN_GUBUN = '0' THEN ABS(A.AMOUNT_DIFF) ELSE 0 END) AS RAW_MTL_CUT      --원재료인하
                                          , SUM(CASE WHEN A.UP_DAWN_GUBUN = '1' THEN ABS(A.AMOUNT_DIFF) ELSE 0 END) AS RAW_MTL_RAISE    --원재료인상
                                          , NULL                       AS BPA_COMMENTS          --BPA_DESC
                                          , NULL                       AS REASON_DESCR          --TRAN_REAS
                                       FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V A
                                 INNER JOIN T_DIM_FND_COM_ITEM I3
                                         ON A.ORGANIZATION_CODE = I3.ORG_CODE
                                        AND A.ITEM = I3.ITEM_CODE
                                      WHERE TARGET_MONTH = @v_parm_to     --파라미터
                                        AND A.C_GUBUN <> 'R'
                                        AND A.ITEM LIKE '7101%'
                                        AND A.TXN_NATURE IN (7,8,9,10,22)  --단가사유가 Cost Analysis
                                   GROUP BY A.TARGET_MONTH
                                          , A.ORGANIZATION_CODE
                                          , A.ITEM
                                          , I3.PRODUCT_LINE_CODE
                                          , I3.PRODUCT_LINE_NAME
                                          , TRIM(A.TEAM)
                                            
                                      UNION ALL
                                            
                                     SELECT BASE_YYYYMM                             AS BASE_YYYYMM           --기준년월
                                          , ORG_CODE                                AS ORG_CODE              --ORG_CODE
                                          , ITEM_CODE                               AS ITEM_CODE             --품목코드
                                          , T.PRODUCT_LINE_CODE                     AS PRODUCT_LINE_CODE     --제품류코드
                                          , T.PRODUCT_LINE_NAME                     AS PRODUCT_LINE_NAME     --제품류명
                                          , TRIM(T.DEPARTMENT_CODE)                 AS DEPARTMENT_CODE       --부서코드
                                          , N'글로벌소싱'                           AS MFG_TYPE              --생산구분
                                          , CONCAT(N'5.글로벌소싱(', T.GUBUN, ')')  AS GUBUN                 --실적구분
                                          , NULL                                    AS BPA                   --BPA
                                          , NULL                                    AS Supplier_Buyer        --바이어명
                                          , NULL                                    AS VENDOR                --공급업체
                                          , 0                                       AS IMP_MTL_CUT           --도입재인하
                                          , 0                                       AS IMP_MTL_RAISE         --도입재인상
                                          , CASE WHEN T.OLD_UNIT_PRICE - T.CODE_CONV_UNIT_PRICE > 0 THEN (T.OLD_UNIT_PRICE - T.CODE_CONV_UNIT_PRICE) * T.CODE_CONVERSION_QTY * T.ALLOCATION_RATE ELSE 0 END AS DOM_MTL_CUT      --국내재인하
                                          , CASE WHEN T.OLD_UNIT_PRICE - T.CODE_CONV_UNIT_PRICE < 0 THEN (T.CODE_CONV_UNIT_PRICE - T.OLD_UNIT_PRICE) * T.CODE_CONVERSION_QTY * T.ALLOCATION_RATE ELSE 0 END AS DOM_MTL_RAISE    --국내재인상
                                          , 0                                       AS RAW_MTL_CUT           --원재료인하
                                          , 0                                       AS RAW_MTL_RAISE         --원재료인상
                                          , NULL                                    AS BPA_COMMENTS          --BPA_DESC
                                          , NULL                                    AS REASON_DESCR          --TRAN_REAS
                                       FROM T_DW_EPO_IPO_CODE_CONV_RED_RSLT_DTL T
                                      WHERE T.BASE_YYYYMM = @v_parm_to     --파라미터
                                            
                        --              UNION    ALL --자작(MPI)
                        
                        -- 20151102 서광서B 요청으로 삭제
                        --             SELECT    A.YYYYMM                   AS 기준년월
                        --                  ,    B.ORG_CODE                 AS ORG_CODE
                        --                  ,    D.ITEM_CODE                AS 품목코드
                        --                  ,    A.PRODUCT_LINE_CODE        AS 제품류코드
                        --                  ,    C.PRODUCT_LINE_NAME        AS 제품류명
                        --                  ,    TRIM(A.DEPARTMENT_CODE)    AS 부서코드
                        --                  ,    '부품'                     AS 생산구분
                        --                  ,    '6.자작(MPI)'              AS 실적구분
                        --                  ,    NULL                       AS BPA
                        --                  ,    NULL                       AS 바이어명
                        --                  ,    NULL                       AS 공급업체
                        --                  ,    0                          AS 도입재인하
                        --                  ,    0                          AS 도입재인상
                        --                  ,    SUM(CASE WHEN A.BASE_UNIT_PRICE > A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인하
                        --                  ,    SUM(CASE WHEN A.BASE_UNIT_PRICE < A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인상
                        --                  ,    0                          AS 원재료인하
                        --                  ,    0                          AS 원재료인상
                        --               FROM    DW_RED_MPI_RED_RSLT A
                        --                  ,    T_DIM_FND_COM_ORG B
                        --                  ,    T_DIM_FND_COM_PROD_LN C
                        --                  ,    T_DIM_FND_COM_ITEM D
                        --              WHERE    YYYYMM = @v_parm_to     --파라미터
                        --                AND    A.ORG_ID = B.ORG_ID
                        --                AND    A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                        --                AND    A.ITEM_ID = D.ITEM_ID
                        --                AND    A.ORG_ID = D.ORG_ID
                        --                AND    A.CHANGE_TYPE = 'Buy_Make'
                        --              GROUP BY A.YYYYMM
                        --                  ,    B.ORG_CODE
                        --                  ,    D.ITEM_CODE
                        --                  ,    A.PRODUCT_LINE_CODE
                        --                  ,    C.PRODUCT_LINE_NAME
                        --                  ,    TRIM(A.DEPARTMENT_CODE)
                        
                        --              UNION    ALL --반제품 자작 재료비
                        --
                        --             SELECT    A.YYYYMM                   AS 기준년월
                        --                  ,    B.ORG_CODE                 AS ORG_CODE
                        --                  ,    D.ITEM_CODE                AS 품목코드
                        --                  ,    A.PRODUCT_LINE_CODE        AS 제품류코드
                        --                  ,    C.PRODUCT_LINE_NAME        AS 제품류명
                        --                  ,    A.DEPARTMENT_CODE          AS 부서코드
                        --                  ,    '부품'                     AS 생산구분
                        --                  ,    NULL                       AS BPA
                        --                  ,    NULL                       AS 바이어명
                        --                  ,    NULL                       AS 공급업체
                        --                  ,    0                          AS 도입재인하
                        --                  ,    0                          AS 도입재인상
                        --                  ,    SUM(CASE WHEN A.BASE_UNIT_PRICE > A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인하
                        --                  ,    SUM(CASE WHEN A.BASE_UNIT_PRICE < A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인상
                        --                  ,    0                          AS 원재료인하
                        --                  ,    0                          AS 원재료인상
                        --               FROM    DW_RED_MPI_RED_RSLT A
                        --                  ,    T_DIM_FND_COM_ORG B
                        --                  ,    T_DIM_FND_COM_PROD_LN C
                        --                  ,    T_DIM_FND_COM_ITEM D
                        --              WHERE    YYYYMM = @v_parm_to     --파라미터
                        --                AND    A.ORG_ID = B.ORG_ID
                        --                AND    A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                        --                AND    A.ITEM_ID = D.ITEM_ID
                        --                AND    A.ORG_ID = D.ORG_ID
                        --                AND    A.CHANGE_TYPE = 'SG_MTL_SAVE'
                        --              GROUP BY A.YYYYMM
                        --                  ,    B.ORG_CODE
                        --                  ,    D.ITEM_CODE
                        --                  ,    A.PRODUCT_LINE_CODE
                        --                  ,    C.PRODUCT_LINE_NAME
                        --                  ,    A.DEPARTMENT_CODE
                        --
                                      UNION ALL --설계 BOM 없는 제조 BOM의 자재 재료비
                                            
                                     SELECT A.YYYYMM                   AS BASE_YYYYMM           --기준년월
                                          , B.ORG_CODE                 AS ORG_CODE              --ORG_CODE
                                          , D.ITEM_CODE                AS ITEM_CODE             --품목코드
                                          , A.PRODUCT_LINE_CODE        AS PRODUCT_LINE_CODE     --제품류코드
                                          , C.PRODUCT_LINE_NAME        AS PRODUCT_LINE_NAME     --제품류명
                                          , TRIM(A.DEPARTMENT_CODE)    AS DEPARTMENT_CODE       --부서코드
                                          , N'부품'                    AS MFG_TYPE              --생산구분
                                          , N'7.WIP_BOM'               AS GUBUN                 --실적구분
                                          , MAX(BPA_NO)                AS BPA                   --BPA
                                          , MAX(BUYER_NM)              AS Supplier_Buyer        --바이어명
                                          , MAX(VENDOR)                AS VENDOR                --공급업체
                                          , 0                          AS IMP_MTL_CUT           --도입재인하
                                          , 0                          AS IMP_MTL_RAISE         --도입재인상
                                          , SUM(CASE WHEN A.BASE_UNIT_PRICE > A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_CUT      --국내재인하
                                          , SUM(CASE WHEN A.BASE_UNIT_PRICE < A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_RAISE    --국내재인상
                                          , 0                          AS RAW_MTL_CUT           --원재료인하
                                          , 0                          AS RAW_MTL_RAISE         --원재료인상
                                          , NULL                       AS BPA_COMMENTS          --BPA_DESC
                                          , NULL                       AS REASON_DESCR          --TRAN_REAS
                                       FROM T_DW_WIP_RED_MPI_RED_RSLT A  
                                 INNER JOIN T_DIM_FND_COM_ORG B
                                         ON A.ORG_ID = B.ORG_ID
                                 INNER JOIN T_DIM_FND_COM_PROD_LN C
                                         ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                 INNER JOIN T_DIM_FND_COM_ITEM D
                                         ON A.ITEM_ID = D.ITEM_ID
                                        AND A.ORG_ID = D.ORG_ID
                                      WHERE YYYYMM = @v_parm_to     --파라미터
                                        AND A.CHANGE_TYPE = 'WIP_BOM_MTL_SAVE'
                                   GROUP BY A.YYYYMM
                                          , B.ORG_CODE
                                          , D.ITEM_CODE
                                          , A.PRODUCT_LINE_CODE
                                          , C.PRODUCT_LINE_NAME
                                          , TRIM(A.DEPARTMENT_CODE)
                                            
                                      UNION ALL --자작=>외작
                                            
                                     SELECT A.YYYYMM                   AS BASE_YYYYMM           --기준년월
                                          , B.ORG_CODE                 AS ORG_CODE              --ORG_CODE
                                          , D.ITEM_CODE                AS ITEM_CODE             --품목코드
                                          , A.PRODUCT_LINE_CODE        AS PRODUCT_LINE_CODE     --제품류코드
                                          , C.PRODUCT_LINE_NAME        AS PRODUCT_LINE_NAME     --제품류명
                                          , TRIM(A.DEPARTMENT_CODE)    AS DEPARTMENT_CODE       --부서코드
                                          , N'외주화'                  AS MFG_TYPE              --생산구분
                                          , N'8.MAKE=>BUY'             AS GUBUN                 --실적구분
                                          , BPA_NO                     AS BPA                   --BPA
                                          , BUYER_NM                   AS Supplier_Buyer        --바이어명
                                          , VENDOR                     AS VENDOR                --공급업체
                                          , 0                          AS IMP_MTL_CUT           --도입재인하
                                          , 0                          AS IMP_MTL_RAISE         --도입재인상
                                          , SUM(CASE WHEN A.BASE_UNIT_PRICE > A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_CUT      --국내재인하
                                          , SUM(CASE WHEN A.BASE_UNIT_PRICE < A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_RAISE    --국내재인상
                                          , 0                          AS RAW_MTL_CUT           --원재료인하
                                          , 0                          AS RAW_MTL_RAISE         --원재료인상
                                          , NULL                       AS BPA_COMMENTS          --BPA_DESC
                                          , NULL                       AS REASON_DESCR          --TRAN_REAS
                                       FROM T_DW_EPO_IPO_IN_OUT_RED_RSLT A
                                 INNER JOIN T_DIM_FND_COM_ORG B
                                         ON A.ORG_ID = B.ORG_ID
                                 INNER JOIN T_DIM_FND_COM_PROD_LN C
                                         ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                 INNER JOIN T_DIM_FND_COM_ITEM D
                                         ON A.ITEM_ID = D.ITEM_ID
                                        AND A.ORG_ID = D.ORG_ID
                                      WHERE YYYYMM = @v_parm_to     --파라미터
                                   GROUP BY A.YYYYMM
                                          , B.ORG_CODE
                                          , D.ITEM_CODE
                                          , A.PRODUCT_LINE_CODE
                                          , C.PRODUCT_LINE_NAME
                                          , TRIM(A.DEPARTMENT_CODE)
                                          , A.BPA_NO
                                          , A.BUYER_NM
                                          , A.VENDOR
                                            
                                      UNION ALL --외작=>자작
                                            
                                     SELECT A.YYYYMM                   AS BASE_YYYYMM           --기준년월
                                          , B.ORG_CODE                 AS ORG_CODE              --ORG_CODE
                                          , D.ITEM_CODE                AS ITEM_CODE             --품목코드
                                          , A.PRODUCT_LINE_CODE        AS PRODUCT_LINE_CODE     --제품류코드
                                          , C.PRODUCT_LINE_NAME        AS PRODUCT_LINE_NAME     --제품류명
                                          , TRIM(A.DEPARTMENT_CODE)    AS DEPARTMENT_CODE       --부서코드
                                          , N'자작화'                  AS MFG_TYPE              --생산구분
                                          , N'9.BUY=>MAKE'             AS GUBUN                 --실적구분
                                          , NULL                       AS BPA                   --BPA
                                          , NULL                       AS Supplier_Buyer        --바이어명
                                          , NULL                       AS VENDOR                --공급업체
                                          , 0                          AS IMP_MTL_CUT           --도입재인하
                                          , 0                          AS IMP_MTL_RAISE         --도입재인상
                                          , SUM(CASE WHEN A.BASE_UNIT_PRICE > A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_CUT      --국내재인하
                                          , SUM(CASE WHEN A.BASE_UNIT_PRICE < A.RECEIVING_UNIT_PRICE THEN ABS(A.MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_RAISE    --국내재인상
                                          , 0                          AS RAW_MTL_CUT           --원재료인하
                                          , 0                          AS RAW_MTL_RAISE         --원재료인상
                                          , NULL                       AS BPA_COMMENTS          --BPA_DESC
                                          , NULL                       AS REASON_DESCR          --TRAN_REAS
                                       FROM T_DW_EPO_IPO_OUT_IN_RED_RSLT A 
                                 INNER JOIN T_DIM_FND_COM_ORG B
                                         ON A.ORG_ID = B.ORG_ID
                                 INNER JOIN T_DIM_FND_COM_PROD_LN C
                                         ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                 INNER JOIN T_DIM_FND_COM_ITEM D
                                         ON A.ITEM_ID = D.ITEM_ID
                                        AND A.ORG_ID = D.ORG_ID
                                      WHERE YYYYMM = @v_parm_to     --파라미터
                                   GROUP BY A.YYYYMM
                                          , B.ORG_CODE
                                          , D.ITEM_CODE
                                          , A.PRODUCT_LINE_CODE
                                          , C.PRODUCT_LINE_NAME
                                          , TRIM(A.DEPARTMENT_CODE)
                                ) ST
                       ) A       
            INNER JOIN T_DIM_FND_COM_ORG B
                    ON A.ORG_CODE = B.ORG_CODE
                   AND B.OU_ID = 89
       LEFT OUTER JOIN (
                          SELECT /*+ LEADING(B) */
                                 DISTINCT A1.SEGMENT1 AS BPA_NO
                               , B1.FULL_NAME
                            FROM ERPSYS.ERP_PO_HEADERS_ALL A1  --96302
                      INNER JOIN ERPSYS.ERP_PER_ALL_PEOPLE_F B1  --10372
                              ON A1.AGENT_ID = B1.PERSON_ID
                       ) C
                    ON A.BPA = C.BPA_NO
       LEFT OUTER JOIN ERPSYS.ERP_PO_HEADERS_ALL D -- 20211116 기능개선 SRM2110-07571 BPA유효시작일 추가
                    ON A.BPA = D.SEGMENT1
                   AND D.ORG_ID = 89
              GROUP BY A.BASE_YYYYMM
                     , A.ORG_CODE
                     , A.ITEM_CODE
                     , A.PRODUCT_LINE_CODE
                     , A.DEPARTMENT_CODE
                     , SERIAL_NO
                     , A.BPA
                     , C.FULL_NAME
                     , A.Supplier_Buyer
                     , A.VENDOR
                     , A.GUBUN
                     , A.BPA_COMMENTS
                     , A.REASON_DESCR
                     , D.START_DATE
                     ;


            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_DEPT_COST_RED_DTL]
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
         
         --SELECT @v_load_cnt,@v_err_mesg, @v_pgm_status

        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_EPO_IPO_ITEM_RED_RSLT_14_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_EPO_IPO_ITEM_RED_RSLT_14_M_C' -- procedure name 
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


                    DELETE FROM [dbo].[T_DW_EPO_IPO_ITEM_RED_RSLT] 
                     WHERE BASE_YYYYMM = @v_parm_to   --파라미터
                     ;

                    INSERT INTO [dbo].[T_DW_EPO_IPO_ITEM_RED_RSLT]
                    (
                           [BASE_YYYYMM]
                         , [ORG_CODE]
                         , [ITEM_CODE]
                         , [DEPARTMENT_CODE]
                         , [PRODUCT_LINE_CODE]
                         , [SERIAL_NO]
                         , [ORG_ID]
                         , [ITEM_ID]
                         , [ORG_ITEM_ID_KEY]
                         , [ORG_ITEM_CODE_KEY]
                         , [ORG_PRODUCT_LINE_CODE_KEY]
                         , [BPA_NO]
                         , [BPA_BUYER]
                         , [SUPPLIER_BUYER]
                         , [GUBUN]
                         , [IMP_MTL_DECR_AMOUNT]
                         , [IMP_MTL_INCR_AMOUNT]
                         , [DOM_MTL_DECR_AMOUNT]
                         , [DOM_MTL_INCR_AMOUNT]
                         , [REDUCTION_AMOUNT]
                         , [ETL_DT]
                    )
                    SELECT A.BASE_YYYYMM                                                    AS BASE_YYYYMM                  --기준년월
                         , A.ORG_CODE                                                       AS ORG_CODE                     --ORG_코드
                         , A.ITEM_CODE                                                      AS ITEM_CODE                    --품목코드
                         , A.DEPARTMENT_CODE                                                AS DEPARTMENT_CODE              --부서코드
                         , A.PRODUCT_LINE_CODE                                              AS PRODUCT_LINE_CODE            --제품류코드
                         , A.SERIAL_NO
                         , MAX(A.ORG_ID)                                                    AS ORG_ID                       --ORG_ID
                         , MAX(A.ITEM_ID)                                                   AS ITEM_ID                      --품목ID
                         , CONCAT(CAST(MAX(A.ORG_ID)  AS INT), CAST(MAX(A.ITEM_ID) AS INT)) AS ORG_ITEM_ID_KEY
                         , CONCAT(A.ORG_CODE, A.ITEM_CODE)                                  AS ORG_ITEM_CODE_KEY
                         , CONCAT(A.ORG_CODE, A.PRODUCT_LINE_CODE)                          AS ORG_PRODUCT_LINE_CODE_KEY 
                         , A.BPA_NO                                                         AS BPA_NO                       --BPA
                         , C.FULL_NAME                                                      AS BPA_BUYER                    --BPA_Buyer
                         , A.SUPPLIER_BUYER                                                 AS SUPPLIER_BUYER               --Supplier_Buyer
                         , A.GUBUN                                                          AS GUBUN                        --실적구분
                         , SUM(A.IMP_MTL_DECR_AMOUNT)                                       AS IMP_MTL_DECR_AMOUNT          --도입재인하금액
                         , SUM(A.IMP_MTL_INCR_AMOUNT)                                       AS IMP_MTL_INCR_AMOUNT          --도입재인상금액
                         , SUM(A.DOM_MTL_DECR_AMOUNT)                                       AS DOM_MTL_DECR_AMOUNT          --국내재인하금액
                         , SUM(A.DOM_MTL_INCR_AMOUNT)                                       AS DOM_MTL_INCR_AMOUNT          --국내재인상금액
                         , SUM(A.IMP_MTL_DECR_AMOUNT) - SUM(IMP_MTL_INCR_AMOUNT) + SUM(DOM_MTL_DECR_AMOUNT) - SUM(DOM_MTL_INCR_AMOUNT) AS REDUCTION_AMOUNT  --절감금액
                         , DATEADD(HOUR, 9 ,GETDATE())                                      AS ETL_DT
                      FROM (
                             SELECT BASE_YYYYMM         
                                  , ORG_CODE            
                                  , ITEM_CODE           
                                  , DEPARTMENT_CODE     
                                  , PRODUCT_LINE_CODE   
                                  , ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS SERIAL_NO
                                  , ORG_ID              
                                  , ITEM_ID             
                                  , BPA_NO                
                                  , SUPPLIER_BUYER      
                                  , GUBUN               
                                  , IMP_MTL_DECR_AMOUNT 
                                  , IMP_MTL_INCR_AMOUNT 
                                  , DOM_MTL_DECR_AMOUNT 
                                  , DOM_MTL_INCR_AMOUNT  
                               FROM (
                                       --구매
                                        SELECT T.BASE_YYYYMM                           AS BASE_YYYYMM           --기준년월
                                             , T.ORG_CODE                              AS ORG_CODE              --ORG_코드
                                             , T.ITEM_CODE                             AS ITEM_CODE             --품목코드
                                             , TRIM(T.TEAM)                            AS DEPARTMENT_CODE       --부서코드
                                             , T.ORG_ID                                AS ORG_ID                --ORG_ID
                                             , T.ITEM_ID                               AS ITEM_ID               --품목ID
                                             , C.PRODUCT_LINE_CODE                     AS PRODUCT_LINE_CODE     --제품류코드
                                             , T.BPA                                   AS BPA_NO                --BPA
                                             , T.BUYER                                 AS SUPPLIER_BUYER        --바이어명
                                             , N'1.생산에투입된자재(입고)'             AS GUBUN                 --실적구분
                                             , ISNULL(SUM(T.IMP_MTL_DECR_AMOUNT),0)    AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , ISNULL(SUM(T.IMP_MTL_INCR_AMOUNT),0)    AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , ISNULL(SUM(T.DOM_MTL_DECR_AMOUNT),0)    AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , ISNULL(SUM(T.DOM_MTL_INCR_AMOUNT),0)    AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM T_DW_EPO_MP_COST_RED_DETAIL T
                                    INNER JOIN T_DIM_FND_COM_ITEM M
                                            ON T.ITEM_ID = M.ITEM_ID
                                           AND T.ORG_ID = M.ORG_ID
                                    INNER JOIN T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP C
                                            ON T.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                         WHERE BASE_YYYYMM  = @v_parm_to     --파라미터
                                      GROUP BY T.BASE_YYYYMM
                                             , T.ORG_CODE
                                             , T.ITEM_CODE
                                             , TRIM(T.TEAM)
                                             , T.ORG_ID
                                             , T.ITEM_ID
                                             , C.PRODUCT_LINE_CODE
                                             , T.BPA
                                             , T.BUYER

                                         UNION ALL -- BOM변경
                                               
                                        SELECT A.BASE_YYYYMM                           AS BASE_YYYYMM           --기준년월      
                                             , A.ORG_CODE                              AS ORG_CODE              --ORG_코드      
                                             , A.END_ITEM_CODE                         AS ITEM_CODE             --품목코드      
                                             , TRIM(A.DEPT_CODE)                       AS DEPARTMENT_CODE       --부서코드      
                                             , A.ORG_ID                                AS ORG_ID                --ORG_ID        
                                             , A.END_ITEM_ID                           AS ITEM_ID               --품목ID        
                                             , J.PRODUCT_LINE_CODE                     AS PRODUCT_LINE_CODE     --제품류코드    
                                             , NULL                                    AS BPA_NO                --BPA           
                                             , NULL                                    AS SUPPLIER_BUYER        --바이어명      
                                             , N'2.BOM변경'                             AS GUBUN                 --실적구분      
                                             , 0                                       AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , 0                                       AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , ISNULL(SUM(DECR),0)                     AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , ISNULL(SUM(INCR),0)                     AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM V_DW_WIP_RED_BOM_CHANGE A
                                    INNER JOIN T_DIM_FND_COM_ITEM J
                                            ON A.END_ITEM_ID = J.ITEM_ID
                                           AND A.ORG_ID = J.ORG_ID
                                         WHERE A.BASE_YYYYMM = @v_parm_to     --파라미터
                                      GROUP BY A.BASE_YYYYMM
                                             , A.ORG_CODE
                                             , A.END_ITEM_CODE
                                             , TRIM(A.DEPT_CODE)
                                             , A.ORG_ID
                                             , A.END_ITEM_ID
                                             , J.PRODUCT_LINE_CODE

                                         UNION    ALL -- 원재료

                                        SELECT TARGET_MONTH                             AS BASE_YYYYMM           --기준년월      
                                             , ORGANIZATION_CODE                        AS ORG_CODE              --ORG_코드      
                                             , ITEM                                     AS ITEM_CODE             --품목코드      
                                             , TRIM(TEAM)                               AS DEPARTMENT_CODE       --부서코드      
                                             , I3.ORG_ID                                AS ORG_ID                --ORG_ID        
                                             , I3.ITEM_ID                               AS ITEM_ID               --품목ID        
                                             , I3.PRODUCT_LINE_CODE                     AS PRODUCT_LINE_CODE     --제품류코드    
                                             , MAX(BPA)                                 AS BPA_NO                --BPA           
                                             , MAX(BUYER)                               AS SUPPLIER_BUYER        --바이어명      
                                             , N'3.원재료'                              AS GUBUN                 --실적구분      
                                             , 0                                        AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , 0                                        AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , ISNULL(SUM(CASE WHEN UP_DAWN_GUBUN = '0' THEN ABS(AMOUNT_DIFF) ELSE 0 END),0) AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , ISNULL(SUM(CASE WHEN UP_DAWN_GUBUN = '1' THEN ABS(AMOUNT_DIFF) ELSE 0 END),0) AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V A
                                    INNER JOIN T_DIM_FND_COM_ITEM I3
                                            ON ORGANIZATION_CODE = I3.ORG_CODE
                                           AND ITEM = I3.ITEM_CODE
                                         WHERE TARGET_MONTH = @v_parm_to     --파라미터
                                           AND C_GUBUN = 'R'
                                      GROUP BY TARGET_MONTH
                                             , ORGANIZATION_CODE
                                             , ITEM
                                             , TRIM(TEAM)
                                             , I3.ORG_ID
                                             , I3.ITEM_ID
                                             , I3.PRODUCT_LINE_CODE

                                         UNION ALL -- 원재료

                                        -- RAW MATERIAL이 아닌 품목중에 재료비 절감에 포함되어야 하는 품목(은)
                                        SELECT TARGET_MONTH                             AS BASE_YYYYMM           --기준년월      
                                             , ORGANIZATION_CODE                        AS ORG_CODE              --ORG_코드      
                                             , ITEM                                     AS ITEM_CODE             --품목코드      
                                             , TRIM(TEAM)                               AS DEPARTMENT_CODE       --부서코드      
                                             , I3.ORG_ID                                AS ORG_ID                --ORG_ID        
                                             , I3.ITEM_ID                               AS ITEM_ID               --품목ID        
                                             , I3.PRODUCT_LINE_CODE                     AS PRODUCT_LINE_CODE     --제품류코드    
                                             , MAX(BPA)                                 AS BPA_NO                --BPA           
                                             , MAX(BUYER)                               AS SUPPLIER_BUYER        --바이어명      
                                             , N'4.제조에서만 사용된 자재'               AS GUBUN                 --실적구분      
                                             , 0                                        AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , 0                                        AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , ISNULL(SUM(CASE WHEN UP_DAWN_GUBUN = '0' THEN ABS(AMOUNT_DIFF) ELSE 0 END),0) AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , ISNULL(SUM(CASE WHEN UP_DAWN_GUBUN = '1' THEN ABS(AMOUNT_DIFF) ELSE 0 END),0) AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V A
                                    INNER JOIN T_DIM_FND_COM_ITEM I3
                                            ON ORGANIZATION_CODE = I3.ORG_CODE
                                           AND ITEM = I3.ITEM_CODE
                                         WHERE TARGET_MONTH = @v_parm_to     --파라미터
                                           AND C_GUBUN <> 'R'
                                           AND ITEM LIKE '7101%'
                                           AND A.TXN_NATURE IN (7,8,9,10,22)  --단가사유가 Cost Analysis
                                      GROUP BY TARGET_MONTH
                                             , ORGANIZATION_CODE
                                             , ITEM
                                             , TRIM(TEAM)
                                             , I3.ORG_ID
                                             , I3.ITEM_ID
                                             , I3.PRODUCT_LINE_CODE

                                         UNION ALL -- 코드변환
                                               
                                        SELECT T.BASE_YYYYMM                            AS BASE_YYYYMM           --기준년월      
                                             , T.ORG_CODE                               AS ORG_CODE              --ORG_코드      
                                             , T.ITEM_CODE                              AS ITEM_CODE             --품목코드      
                                             , TRIM(T.DEPARTMENT_CODE)                  AS DEPARTMENT_CODE       --부서코드      
                                             , MC.ORG_ID                                AS ORG_ID                --ORG_ID        
                                             , MC.ITEM_ID                               AS ITEM_ID               --품목ID        
                                             , T.PRODUCT_LINE_CODE                      AS PRODUCT_LINE_CODE     --제품류코드    
                                             , NULL                                     AS BPA_NO                --BPA           
                                             , NULL                                     AS SUPPLIER_BUYER        --바이어명      
                                             , CONCAT(N'5.글로벌소싱(', T.GUBUN, ')')   AS GUBUN                 --실적구분      
                                             , 0                                        AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , 0                                        AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , ISNULL(SUM(CASE WHEN T.OLD_UNIT_PRICE - T.CODE_CONV_UNIT_PRICE > 0 THEN (T.OLD_UNIT_PRICE - T.CODE_CONV_UNIT_PRICE) * T.CODE_CONVERSION_QTY * T.ALLOCATION_RATE ELSE 0 END),0) AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , ISNULL(SUM(CASE WHEN T.OLD_UNIT_PRICE - T.CODE_CONV_UNIT_PRICE < 0 THEN (T.CODE_CONV_UNIT_PRICE - T.OLD_UNIT_PRICE) * T.CODE_CONVERSION_QTY * T.ALLOCATION_RATE ELSE 0 END),0) AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM T_DW_EPO_IPO_CODE_CONV_RED_RSLT_DTL T
                                    INNER JOIN T_DIM_FND_COM_ITEM MC
                                            ON T.ORG_CODE = MC.ORG_CODE
                                           AND T.ITEM_CODE = MC.ITEM_CODE
                                         WHERE T.BASE_YYYYMM = @v_parm_to     --파라미터
                                      GROUP BY T.BASE_YYYYMM
                                             , T.ORG_CODE
                                             , T.ITEM_CODE
                                             , TRIM(T.DEPARTMENT_CODE)
                                             , MC.ORG_ID
                                             , MC.ITEM_ID
                                             , T.PRODUCT_LINE_CODE
                                             , T.GUBUN

                       --                  UNION    ALL --자작(MPI) 구매품(BUY)에서 자작(MAKE_BUY)으로 변경된 품목

                       --20151102 서광석B 요청으로 제거
                       --                 SELECT    A.YYYYMM                           AS 기준년월
                       --                      ,    B.ORG_CODE                         AS ORG_코드
                       --                      ,    D.ITEM_CODE                        AS 품목코드
                       --                      ,    TRIM(A.DEPARTMENT_CODE)            AS 부서코드
                       --                      ,    A.ORG_ID                           AS ORG_ID
                       --                      ,    A.ITEM_ID                          AS 품목ID
                       --                      ,    A.PRODUCT_LINE_CODE                AS 제품류코드
                       --                      ,    NULL                               AS BPA
                       --                      ,    NULL                               AS 바이어명
                       --                      ,    '6.자작(MPI)'                      AS 실적구분
                       --                      ,    0                                  AS 도입재인하금액
                       --                      ,    0                                  AS 도입재인상금액
                       --                      ,    SUM(CASE WHEN BASE_UNIT_PRICE > RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인하금액
                       --                      ,    SUM(CASE WHEN BASE_UNIT_PRICE < RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인상금액
                       --                   FROM    DW_RED_MPI_RED_RSLT A
                       --                      ,    T_DIM_FND_COM_ORG B
                       --                      ,    T_DIM_FND_COM_PROD_LN C
                       --                      ,    T_DIM_FND_COM_ITEM D
                       --                  WHERE    A.YYYYMM = I_TARGET_YYYYMM
                       --                    AND    A.ORG_ID = B.ORG_ID
                       --                    AND    A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                       --                    AND    A.ITEM_ID = D.ITEM_ID
                       --                    AND    A.ORG_ID = D.ORG_ID
                       --                    AND    A.CHANGE_TYPE = 'Buy_Make'
                       --                  GROUP BY A.YYYYMM
                       --                      ,    B.ORG_CODE
                       --                      ,    D.ITEM_CODE
                       --                      ,    TRIM(A.DEPARTMENT_CODE)
                       --                      ,    A.ORG_ID
                       --                      ,    A.ITEM_ID
                       --                      ,    A.PRODUCT_LINE_CODE

                       --                  UNION    ALL --반제품 자작 재료비
                       --
                       --                 SELECT    A.YYYYMM                           AS 기준년월
                       --                      ,    B.ORG_CODE                         AS ORG_코드
                       --                      ,    D.ITEM_CODE                        AS 품목코드
                       --                      ,    A.DEPARTMENT_CODE                  AS 부서코드
                       --                      ,    A.ORG_ID                           AS ORG_ID
                       --                      ,    A.ITEM_ID                          AS 품목ID
                       --                      ,    A.PRODUCT_LINE_CODE                AS 제품류코드
                       --                      ,    NULL                               AS BPA
                       --                      ,    NULL                               AS 바이어명
                       --                      ,    0                                  AS 도입재인하금액
                       --                      ,    0                                  AS 도입재인상금액
                       --                      ,    SUM(CASE WHEN BASE_UNIT_PRICE > RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인하금액
                       --                      ,    SUM(CASE WHEN BASE_UNIT_PRICE < RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS 국내재인상금액
                       --                   FROM    DW_RED_MPI_RED_RSLT A
                       --                      ,    T_DIM_FND_COM_ORG B
                       --                      ,    T_DIM_FND_COM_PROD_LN C
                       --                      ,    T_DIM_FND_COM_ITEM D
                       --                  WHERE    A.YYYYMM = I_TARGET_YYYYMM
                       --                    AND    A.ORG_ID = B.ORG_ID
                       --                    AND    A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                       --                    AND    A.ITEM_ID = D.ITEM_ID
                       --                    AND    A.ORG_ID = D.ORG_ID
                       --                    AND    A.CHANGE_TYPE = 'SG_MTL_SAVE'
                       --                  GROUP BY A.YYYYMM
                       --                      ,    B.ORG_CODE
                       --                      ,    D.ITEM_CODE
                       --                      ,    A.DEPARTMENT_CODE
                       --                      ,    A.ORG_ID
                       --                      ,    A.ITEM_ID
                       --                      ,    A.PRODUCT_LINE_CODE
                       --
                                         UNION ALL --설계 BOM 없는 제조 BOM의 자재 재료비

                                        SELECT A.YYYYMM                           AS BASE_YYYYMM           --기준년월      
                                             , B.ORG_CODE                         AS ORG_CODE              --ORG_코드      
                                             , D.ITEM_CODE                        AS ITEM_CODE             --품목코드      
                                             , TRIM(A.DEPARTMENT_CODE)            AS DEPARTMENT_CODE       --부서코드      
                                             , A.ORG_ID                           AS ORG_ID                --ORG_ID        
                                             , A.ITEM_ID                          AS ITEM_ID               --품목ID        
                                             , A.PRODUCT_LINE_CODE                AS PRODUCT_LINE_CODE     --제품류코드    
                                             , MAX(BPA_NO)                        AS BPA_NO                --BPA           
                                             , MAX(BUYER_NM)                      AS SUPPLIER_BUYER        --바이어명      
                                             , N'7.WIP_BOM'                       AS GUBUN                 --실적구분      
                                             , 0                                  AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , 0                                  AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , SUM(CASE WHEN BASE_UNIT_PRICE > RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , SUM(CASE WHEN BASE_UNIT_PRICE < RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM T_DW_WIP_RED_MPI_RED_RSLT A
                                    INNER JOIN T_DIM_FND_COM_ORG B
                                            ON A.ORG_ID = B.ORG_ID
                                    INNER JOIN T_DIM_FND_COM_PROD_LN C
                                            ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                    INNER JOIN T_DIM_FND_COM_ITEM D
                                            ON A.ITEM_ID = D.ITEM_ID
                                           AND A.ORG_ID = D.ORG_ID
                                         WHERE A.YYYYMM = @v_parm_to     --파라미터
                                           AND A.CHANGE_TYPE = 'WIP_BOM_MTL_SAVE'
                                      GROUP BY A.YYYYMM
                                             , B.ORG_CODE
                                             , D.ITEM_CODE
                                             , TRIM(A.DEPARTMENT_CODE)
                                             , A.ORG_ID
                                             , A.ITEM_ID
                                             , A.PRODUCT_LINE_CODE

                                         UNION ALL --자작 => 외작

                                        SELECT A.YYYYMM                           AS BASE_YYYYMM           --기준년월      
                                             , B.ORG_CODE                         AS ORG_CODE              --ORG_코드      
                                             , D.ITEM_CODE                        AS ITEM_CODE             --품목코드      
                                             , TRIM(A.DEPARTMENT_CODE)            AS DEPARTMENT_CODE       --부서코드      
                                             , A.ORG_ID                           AS ORG_ID                --ORG_ID        
                                             , A.ITEM_ID                          AS ITEM_ID               --품목ID        
                                             , A.PRODUCT_LINE_CODE                AS PRODUCT_LINE_CODE     --제품류코드    
                                             , A.BPA_NO                           AS BPA_NO                --BPA           
                                             , A.BUYER_NM                         AS SUPPLIER_BUYER        --바이어명      
                                             , N'8.MAKE=>BUY'                     AS GUBUN                 --실적구분      
                                             , 0                                  AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , 0                                  AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , SUM(CASE WHEN BASE_UNIT_PRICE > RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , SUM(CASE WHEN BASE_UNIT_PRICE < RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM T_DW_EPO_IPO_IN_OUT_RED_RSLT A
                                    INNER JOIN T_DIM_FND_COM_ORG B
                                            ON A.ORG_ID = B.ORG_ID
                                    INNER JOIN T_DIM_FND_COM_PROD_LN C
                                            ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                    INNER JOIN T_DIM_FND_COM_ITEM D
                                            ON A.ITEM_ID = D.ITEM_ID
                                           AND A.ORG_ID = D.ORG_ID
                                         WHERE A.YYYYMM = @v_parm_to     --파라미터
                                      GROUP BY A.YYYYMM
                                             , B.ORG_CODE
                                             , D.ITEM_CODE
                                             , TRIM(A.DEPARTMENT_CODE)
                                             , A.ORG_ID
                                             , A.ITEM_ID
                                             , A.PRODUCT_LINE_CODE
                                             , A.BPA_NO
                                             , A.BUYER_NM

                                         UNION ALL --외작 => 자작

                                        SELECT A.YYYYMM                           AS BASE_YYYYMM           --기준년월      
                                             , B.ORG_CODE                         AS ORG_CODE              --ORG_코드      
                                             , D.ITEM_CODE                        AS ITEM_CODE             --품목코드      
                                             , TRIM(A.DEPARTMENT_CODE)            AS DEPARTMENT_CODE       --부서코드      
                                             , A.ORG_ID                           AS ORG_ID                --ORG_ID        
                                             , A.ITEM_ID                          AS ITEM_ID               --품목ID        
                                             , A.PRODUCT_LINE_CODE                AS PRODUCT_LINE_CODE     --제품류코드    
                                             , ''                                 AS BPA_NO                --BPA           
                                             , ''                                 AS SUPPLIER_BUYER        --바이어명      
                                             , N'9.BUY=>MAKE'                     AS GUBUN                 --실적구분      
                                             , 0                                  AS IMP_MTL_DECR_AMOUNT   --도입재인하금액
                                             , 0                                  AS IMP_MTL_INCR_AMOUNT   --도입재인상금액
                                             , SUM(CASE WHEN BASE_UNIT_PRICE > RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_DECR_AMOUNT   --국내재인하금액
                                             , SUM(CASE WHEN BASE_UNIT_PRICE < RECEIVING_UNIT_PRICE THEN ABS(MTL_COST_RED_AMOUNT) ELSE 0 END) AS DOM_MTL_INCR_AMOUNT   --국내재인상금액
                                          FROM T_DW_EPO_IPO_OUT_IN_RED_RSLT A
                                    INNER JOIN T_DIM_FND_COM_ORG B
                                            ON A.ORG_ID = B.ORG_ID
                                    INNER JOIN T_DIM_FND_COM_PROD_LN C
                                            ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
                                    INNER JOIN T_DIM_FND_COM_ITEM D
                                            ON A.ITEM_ID = D.ITEM_ID
                                           AND A.ORG_ID = D.ORG_ID
                                         WHERE A.YYYYMM = @v_parm_to     --파라미터
                                      GROUP BY A.YYYYMM
                                             , B.ORG_CODE
                                             , D.ITEM_CODE
                                             , TRIM(A.DEPARTMENT_CODE)
                                             , A.ORG_ID
                                             , A.ITEM_ID
                                             , A.PRODUCT_LINE_CODE 
                                    ) ST
                           ) A
                      JOIN T_DIM_FND_COM_ORG B
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
                        ON A.BPA_NO = C.BPA_NO
                  GROUP BY A.BASE_YYYYMM
                         , A.ORG_CODE
                         , A.ITEM_CODE
                         , A.DEPARTMENT_CODE
                         , A.PRODUCT_LINE_CODE
                         , SERIAL_NO
                         , A.BPA_NO
                         , C.FULL_NAME
                         , A.SUPPLIER_BUYER
                         , A.GUBUN
                         ;

                         
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_EPO_IPO_ITEM_RED_RSLT]
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
         --SELECT @v_pgm_status, @v_load_cnt, @v_err_mesg
        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

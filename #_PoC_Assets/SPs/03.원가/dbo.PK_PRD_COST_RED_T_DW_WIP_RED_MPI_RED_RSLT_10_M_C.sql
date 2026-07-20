CREATE PROC [dbo].[PK_PRD_COST_RED_T_DW_WIP_RED_MPI_RED_RSLT_10_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS
BEGIN
/*******************************************************************************************************
*  PROGRAM ID    :  PK_PRD_COST_RED_T_DW_WIP_RED_MPI_RED_RSLT_10_M_C
*  DESCRIPTION   :  부서별 원가절감실적 상세 보고서용 데이터
*
********************************************************************************************************
*  CHANGE HISTORY
*-------------  ---------------  ---------------------  --------------------------------------------------------
*  DATE         AUTHOR           CSR_NO                 DESCRIPTION
*-------------  ---------------  ---------------------  --------------------------------------------------------
*  2025-02-25   COMKDHC          SRM2502-01461          BPA 342504 건 25년 1,2월 실적 집계를 위해 하드코딩 추가 (김강현M 요청)
********************************************************************************************************/
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

        SET @v_run_pgm = 'PK_PRD_COST_RED_T_DW_WIP_RED_MPI_RED_RSLT_10_M_C' -- procedure name 
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
         
                DELETE FROM [dbo].[T_DW_WIP_RED_MPI_RED_RSLT] 
                 WHERE YYYYMM  =  @v_parm_to     --파라미터
                ;
                INSERT INTO [dbo].[T_DW_WIP_RED_MPI_RED_RSLT]
                (      [YYYYMM]
                     , [ORG_ID]
                     , [DEPARTMENT_CODE]
                     , [PRODUCT_LINE_CODE]
                     , [ITEM_ID]
                     , [CHANGE_TYPE]
                     , [BPA_NO]
                     , [BUYER_NM]
                     , [VENDOR]
                     , [QTY]
                     , [BASE_UNIT_PRICE]
                     , [RECEIVING_UNIT_PRICE]
                     , [UNIT_PRICE_VARIANCE]
                     , [MTL_COST_RED_AMOUNT]
                     , [DISTRIBUTION_RATE]
                     , [ETL_DT]
                )  
                SELECT A.YYYYMM
                     , A.ORGANIZATION_ID                       AS ORG_ID               --ORG_ID
                     , TRIM(CASE WHEN B.ALLC_RATE IS NOT NULL THEN
                                 B.DEPT_CODE
                            WHEN B.ALLC_RATE IS NULL AND C.LOOKUP_CODE IS NOT NULL THEN
                                 C.DESCRIPTION
                       END)                                    AS DEPARTMENT_CODE      --부서코드
                     , A.SPG_CD                                AS PRODUCT_LINE_CODE    --제품류코드
                     , A.ASSEMBLY_ITEM_ID                      AS ITEM_ID              --ITEM_ID
                     , A.CHANGE_TYPE                           AS CHANGE_TYPE          --변경구분
                     , NULL                                    AS BPA_NO               --BPA_NO
                     , NULL                                    AS BUYER_NM             --바이어명
                     , NULL                                    AS VENDOR               --공급업체
                     , D.USED_QTY                              AS QTY                  --수량
                     , CAST(A.ATTRIBUTE1 AS DECIMAL(21,4))                 AS BASE_UNIT_PRICE      --기준단가 NUMBER(20,4)
                     , CAST(A.ATTRIBUTE4 AS DECIMAL(21,4))                 AS RECEIVING_UNIT_PRICE --입고단가 NUMBER(20,4)
                     , CAST(A.ATTRIBUTE1 AS DECIMAL(21,4)) - CAST(A.ATTRIBUTE4 AS DECIMAL(21,4)) AS UNIT_PRICE_VARIANCE  --단가차   NUMBER(16,4)
                     , CASE WHEN B.ALLC_RATE IS NOT NULL THEN
                                 (CAST(A.ATTRIBUTE1 AS DECIMAL(21,4)) - CAST(A.ATTRIBUTE4 AS DECIMAL(21,4))) * D.USED_QTY * (B.ALLC_RATE / 100)
                            WHEN B.ALLC_RATE IS NULL AND C.LOOKUP_CODE IS NOT NULL THEN
                                 (CAST(A.ATTRIBUTE1 AS DECIMAL(21,4)) - CAST(A.ATTRIBUTE4 AS DECIMAL(21,4))) * D.USED_QTY
                       END                                     AS MTL_COST_RED_AMOUNT  --절감금액 NUMBER(20,4)
                     , CASE WHEN B.ALLC_RATE IS NOT NULL THEN
                                 B.ALLC_RATE
                            WHEN B.ALLC_RATE IS NULL AND C.LOOKUP_CODE IS NOT NULL THEN
                                 100
                       END                                     AS DISTRIBUTION_RATE    --배분율   NUMBER(16,4)
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT 
                  FROM ERPSYS.ERP_EBOM_BOM_CHANGE_MONTHLY         A
       LEFT OUTER JOIN (
                        SELECT DISTINCT
                               ORGANIZATION_ID
                             , DEPT_CODE
                             , ITEM_ID
                             , ALLC_RATE
                          FROM ERPSYS.ERP_EBOM_DEPT_ALLOC_RATE
                         WHERE YYYY = SUBSTRING(@v_parm_to,1,4)     --파라미터
                       )  B
                    ON A.ORGANIZATION_ID = B.ORGANIZATION_ID
                   AND A.ASSEMBLY_ITEM_ID = B.ITEM_ID
       LEFT OUTER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES    C  --배분율이 없을때 제품류에 등록된 설계부서에 100%
                    ON A.SPG_CD = C.LOOKUP_CODE
                   AND C.LOOKUP_TYPE = 'EBOM_PLAN_DEFAULT_ENG_DEPT'
                   AND C.ENABLED_FLAG = 'Y'
       LEFT OUTER JOIN (
                        SELECT YYYYMM
                             , ORGANIZATION_ID
                             , COMPONENT_ITEM_ID
                             , SUM(COMPONENT_QUANTITY * (ISNULL(MFG_QUANTITY, 0) + ISNULL(SHIP_QUANTITY, 0))) USED_QTY
                          FROM ERPSYS.ERP_EBOM_ITEM_REQ_QTY_MON
                         WHERE YYYYMM = @v_parm_to      --파라미터 --대상년월에 생산 실적이 있거나, 생산 실적은 없으나 판매 된 제품의 자재에 대해 설계 BOM 기준으로  자재 총소요량 * (제품 생산 실적 수량 + 제품 판매 수량)
                      GROUP BY YYYYMM
                             , ORGANIZATION_ID
                             , COMPONENT_ITEM_ID
                       )                                      D
                    ON A.YYYYMM = D.YYYYMM
                   AND A.ORGANIZATION_ID = D.ORGANIZATION_ID
                   AND A.ASSEMBLY_ITEM_ID = D.COMPONENT_ITEM_ID
                 WHERE A.YYYYMM = @v_parm_to     --파라미터
                   AND A.CHANGE_TYPE = N'Buy_Make'
                   AND D.YYYYMM IS NOT NULL
                   AND A.ATTRIBUTE2 = 'KRW'
       
                 UNION ALL
       
                --반제품 자작 재료비
                --ATTRIBUTE1  사업계획 시점 Material Cost(재료비)/단가
                --ATTRIBUTE2  단가의 Currency code
                --ATTRIBUTE3  단가의 사업계획 시점 환율
                --ATTRIBUTE4  당월 Material Cost(재료비)
                --ATTRIBUTE5  반제품 Item Code
                --ATTRIBUTE6  반제품 Item Desc
                --ATTRIBUTE7  해당 사업장 Org Code
                --ATTRIBUTE8  해당월 생산 수량
                --ATTRIBUTE9  item category
                --ATTRIBUTE10 사업계획 시점에 buy품 이었는지 구분 : 0 이면 make , 0이 아니면 buy
                SELECT A.YYYYMM
                     , A.ORGANIZATION_ID                       AS ORG_ID               --ORG_ID
                     , TRIM(B.DESCRIPTION)                     AS DEPARTMENT_CODE      --부서코드
                     , A.SPG_CD                                AS PRODUCT_LINE_CODE    --제품류코드
                     , A.ASSEMBLY_ITEM_ID                      AS ITEM_ID              --ITEM_ID
                     , A.CHANGE_TYPE                           AS CHANGE_TYPE          --변경구분
                     , NULL                                    AS BPA_NO               --BPA_NO
                     , NULL                                    AS BUYER_NM             --바이어명
                     , NULL                                    AS VENDOR               --공급업체
                     , CAST(A.ATTRIBUTE8 AS DECIMAL(21,4))                 AS QTY                  --수량
                     , CAST(A.ATTRIBUTE1 AS DECIMAL(21,4))                 AS BASE_UNIT_PRICE      --기준단가
                     , CAST(A.ATTRIBUTE4 AS DECIMAL(21,4))                 AS RECEIVING_UNIT_PRICE --입고단가
                     , CAST(A.ATTRIBUTE1 AS DECIMAL(21,4)) - CAST(A.ATTRIBUTE4 AS DECIMAL(21,4)) AS UNIT_PRICE_VARIANCE  --단가차
                     , CASE WHEN A.ATTRIBUTE10 = '0' THEN
                                 CAST(A.ATTRIBUTE1 AS DECIMAL(21,4)) * CAST(A.ATTRIBUTE8 AS DECIMAL(21,4))
                            WHEN A.ATTRIBUTE10 <> '0' AND  A.ATTRIBUTE2 = 'KRW' THEN
                                 CAST(A.ATTRIBUTE1 AS DECIMAL(21,4)) * CAST(A.ATTRIBUTE8 AS DECIMAL(21,4))
                            WHEN A.ATTRIBUTE10 <> '0' AND A.ATTRIBUTE2 <> 'KRW' THEN
                                 CAST(A.ATTRIBUTE1 AS DECIMAL(21,4)) * CAST(A.ATTRIBUTE8 AS DECIMAL(21,4)) * CAST(A.ATTRIBUTE3 AS DECIMAL(21,4))
                       END                                     AS MTL_COST_RED_AMOUNT  --절감금액
                     , 100                                     AS DISTRIBUTION_RATE    --배분율
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_BOM_CHANGE_MONTHLY         A
       LEFT OUTER JOIN ERPSYS.ERP_FND_LOOKUP_VALUES    B  --배분율이 없을때 제품류에 등록된 설계부서에 100%
                    ON A.SPG_CD = B.LOOKUP_CODE
                   AND B.LOOKUP_TYPE = 'EBOM_PLAN_DEFAULT_ENG_DEPT'
                   AND B.ENABLED_FLAG = 'Y'
                 WHERE A.YYYYMM = @v_parm_to     --파라미터
                   AND A.CHANGE_TYPE = 'SG_MTL_SAVE'
       
                 UNION ALL
       
                --설계 BOM 없는 제조 BOM의 자재 재료비
                --ATTRIBUTE1  마지막 입고 BPA No
                --ATTRIBUTE2  마지막 입고 BPA No의 Unit Price
                --ATTRIBUTE3  마지막 입고 BPA No의 Currency code
                --ATTRIBUTE4  마지막 입고 BPA No의 목표 단가
                --ATTRIBUTE5  단가 변경 사유
                --ATTRIBUTE6  item desc
                --ATTRIBUTE7  해당 사업장 org ocde
                --ATTRIBUTE8  당월 총 출고 수량
                --ATTRIBUTE9  당월 총 불량 수량
                --ATTRIBUTE10 당월 총 투입 수량
                --ATTRIBUTE11 BPA NO의 부서별 배분율 부서 1
                --ATTRIBUTE12 BPA NO의 부서별 배분율 부서 1의 배분율
                --ATTRIBUTE13 BPA NO의 사업계획 시점 단가
                --ATTRIBUTE14 사업계획 시점 단가 currency code
                --ATTRIBUTE15 사업계획 시점 환율
                SELECT A.YYYYMM
                     , A.ORGANIZATION_ID                       AS ORG_ID               --ORG_ID
                     , TRIM(A.ATTRIBUTE11)                     AS DEPARTMENT_CODE      --부서코드
                     , A.SPG_CD                                AS PRODUCT_LINE_CODE    --제품류코드
                     , A.ASSEMBLY_ITEM_ID                      AS ITEM_ID              --ITEM_ID
                     , A.CHANGE_TYPE                           AS CHANGE_TYPE          --변경구분
                     , A.ATTRIBUTE1                            AS BPA_NO               --BPA_NO
                     , E.FULL_NAME                             AS BUYER_NM             --바이어명
                     , F.VENDOR                                AS VENDOR               --공급업체
                     , CAST(A.ATTRIBUTE10 AS DECIMAL(21,4))                AS QTY                  --수량
                     , CAST(A.ATTRIBUTE4 AS DECIMAL(21,4))                 AS BASE_UNIT_PRICE      --기준단가
                     , CAST(A.ATTRIBUTE2 AS DECIMAL(21,4))                 AS RECEIVING_UNIT_PRICE --입고단가
                     , CAST(A.ATTRIBUTE4 AS DECIMAL(21,4)) - CAST(A.ATTRIBUTE2 AS DECIMAL(21,4)) AS UNIT_PRICE_VARIANCE  --단가차
                     , (CAST(A.ATTRIBUTE4 AS DECIMAL(21,4)) - CAST(A.ATTRIBUTE2 AS DECIMAL(21,4))) * CAST(A.ATTRIBUTE10 AS DECIMAL(21,4)) * (CAST(A.ATTRIBUTE12 AS DECIMAL(21,4)) / 100) * CAST(A.ATTRIBUTE15 AS DECIMAL(21,4)) AS MTL_COST_RED_AMOUNT  --절감금액
                     , CAST(A.ATTRIBUTE12 AS DECIMAL(21,4))                AS DISTRIBUTION_RATE    --배분율   NUMBER(16,4)
                     , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT
                  FROM ERPSYS.ERP_EBOM_BOM_CHANGE_MONTHLY  A
            INNER JOIN ERPSYS.ERP_PO_HEADERS_ALL           B
                    ON A.ATTRIBUTE1 = B.SEGMENT1
            INNER JOIN ERPSYS.ERP_ORG_ORGA_DEFI_V          C
                    ON B.ORG_ID =  C.ORGANIZATION_ID
            INNER JOIN (
                        SELECT FORMAT(CAST(LOOKUP_CODE AS DATE), 'yyyyMMdd') AS PLAN_DATE
                          FROM ERPSYS.ERP_FND_LOOKUP_VALUES
                         WHERE LOOKUP_TYPE = 'LSIS_BUSINESS_PLAN_DATE'
                           AND ENABLED_FLAG = 'Y'
                           AND MEANING = LEFT(@v_parm_to,4)--FORMAT(DATEADD(HOUR, 9 ,GETDATE()),'yyyy')
                       )                               D
                    --ON B.START_DATE > D.PLAN_DATE SRM2502-01461
					ON B.START_DATE > CASE WHEN B.SEGMENT1 = '342504' THEN '20230101' ELSE D.PLAN_DATE END -- SRM2502-01461, COMKDHC, 김강현M 요청으로 특정 BPA 건 제외 처리 
       LEFT OUTER JOIN ERPSYS.ERP_PER_ALL_PEOPLE_F         E
                    ON B.AGENT_ID = E.PERSON_ID
       LEFT OUTER JOIN (
                        SELECT BPA
                             , MAX(VENDOR) AS VENDOR
                          FROM ERPSYS.ERP_EBOM_BI_PO_DTL_SAVE_V
                         --WHERE    TARGET_MONTH = @v_parm_to     --파라미터
                      GROUP BY BPA
                       )                                F
                    ON A.ATTRIBUTE1 = F.BPA
                 WHERE A.YYYYMM          = @v_parm_to     --파라미터
                   AND A.CHANGE_TYPE     = 'WIP_BOM_MTL_SAVE'
                   AND A.ATTRIBUTE5 NOT IN ('REASON_16','REASON_17','REASON_18','REASON_19')  --통제불가
                   AND CAST(A.ATTRIBUTE4 AS DECIMAL(21,4)) <> 0
                   ;   
               
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_WIP_RED_MPI_RED_RSLT]
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
         --SELECT @v_pgm_status, @v_err_mesg, @v_load_cnt
        IF @v_work_result = 0

           BEGIN
               EXEC [dbo].[SP_ETL_DATA_INSERT_LOG] @v_run_pgm, @v_tgt_job_area, @v_parm_from, @v_parm_to, @v_st_date, @v_load_cnt, @v_err_mesg, @v_pgm_status
           END

    END

END

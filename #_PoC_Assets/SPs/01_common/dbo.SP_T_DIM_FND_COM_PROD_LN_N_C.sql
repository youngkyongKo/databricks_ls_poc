CREATE PROC [dbo].[SP_T_DIM_FND_COM_PROD_LN_N_C] AS
BEGIN

    SET NOCOUNT ON

    BEGIN

        DECLARE @v_run_pgm      varchar(50)
               ,@v_st_date      datetime
               ,@v_load_cnt     decimal(18,0)
               ,@v_enum         int
               ,@v_err_mesg     varchar(4000)
               ,@v_pgm_status   varchar(1) 
               ,@v_work_result  int
               ,@v_tgt_job_area varchar(10)
               ,@v_parm_from    varchar(50) 
               ,@v_parm_to      varchar(50) 
               ,@v_parm_comm_from varchar(50) 
               ,@v_parm_comm_to   varchar(50)
               ;

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_PROD_LN_N_C' -- procedure name 
        ;
        SET @v_st_date = DATEADD(HOUR, 9 ,GETDATE())
        ;
        SET @v_pgm_status = 'S' -- 성공여부
        ;
        SET @v_work_result = 0
        ;
        SET @v_load_cnt = 0
        ;
        SET @v_tgt_job_area = 'DIM'--DIM / FACT
        ;
        
        BEGIN TRY

                -- 1. BEFORE SQL : INSERT T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP
                INSERT INTO [dbo].[T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP]
                ( 
                       [PRODUCT_LINE_CODE]
                     , [PRODUCT_LINE_NAME]
                     , [CONVERSION_PRODUCT_LINE_CODE]
                     , [CONVERSION_PRODUCT_LINE_NAME]
                     , [SPG_CODE]
                     , [SPG_NAME]
                     , [CONVERSION_SPG_CODE]
                     , [CONVERSION_SPG_NAME]
                     , [SPG_ALIGNMENT_SEQUENCE_NO]
                     , [BUSINESS_CODE]
                     , [BUSINESS_NAME]
                     , [CONVERSION_BUSINESS_CODE]
                     , [CONVERSION_BUSINESS_NAME]
                     , [BIZ_ALIGN_SEQ_NO]
                     , [ORG_CODE]
                     , [SALES_TYPE_NAME]
                     , [CONVERSION_ORG_CODE]
                     , [CREATION_DATE]
                     , [USAGE_FLAG]
                     , [DIVISION_CODE]
                     , [ETL_DT]
                )
                SELECT FFV.FLEX_VALUE                                       AS PRODUCT_LINE_CODE
                     , FFVT.DESCRIPTION                                     AS PRODUCT_LINE_NAME
                     ,  FFV.FLEX_VALUE                                      AS CONVERSION_PRODUCT_LINE_CODE
                     , FFVT.DESCRIPTION                                     AS CONVERSION_PRODUCT_LINE_NAME     
                     , '999'                                                AS SPG_CODE
                     , N'공통제품류'                                        AS SPG_NAME
                     , '999'                                                AS CONVERSION_SPG_CODE
                     , N'공통제품류'                                        AS CONVERSION_SPG_NAME
                     , (SELECT MAX(SPG_ALIGNMENT_SEQUENCE_NO)+1 FROM T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP WHERE SPG_CODE = '999')  AS SPG_ALIGNMENT_SEQUENCE_NO
                     , '999'                                                AS BUSINESS_CODE
                     , N'공통제품류'                                        AS BUSINESS_NAME
                     , '999'                                                AS CONVERSION_BUSINESS_CODE
                     , N'공통제품류'                                        AS CONVERSION_BUSINESS_NAME
                     , (SELECT MAX(BIZ_ALIGN_SEQ_NO)+1 FROM T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP WHERE BUSINESS_CODE = '999')      AS BIZ_ALIGN_SEQ_NO
                     , CASE WHEN FFV.FLEX_VALUE='041' THEN 'M01'
                            WHEN FFV.FLEX_VALUE='042' THEN 'M01'
                            WHEN INV_ORG.INV_ORG_CODE IS NULL THEN 'z{'
                            ELSE INV_ORG.INV_ORG_CODE
                       END                                                  AS ORG_CODE
                     , N'데이터 없음'                                       AS SAELSTYPE_NAME 
                     , CASE WHEN FFV.FLEX_VALUE='041' THEN 'M01'
                            WHEN FFV.FLEX_VALUE='042' THEN 'M01'
                            WHEN INV_ORG.INV_ORG_CODE IS NULL THEN 'z{'
                            ELSE INV_ORG.INV_ORG_CODE
                       END                                                  AS CONVERSION_ORG_CODE  
                     , FORMAT(DATEADD(HOUR, 9 ,GETDATE()),'yyyyMMdd')       AS CREATION_DATE      
                     , 'Y'                                                   AS USAGE_FLAG
                     , DCO.DIVISION_CODE
                     , DATEADD(HOUR, 9 ,GETDATE())                          AS ETL_DT
                  FROM ERPSYS.ERP_GL_LEDGERS LEG
            INNER JOIN ERPSYS.ERP_FND_ID_FLEX_SEGM SEG
                    ON LEG.CHART_OF_ACCOUNTS_ID = SEG.ID_FLEX_NUM  
            INNER JOIN ERPSYS.ERP_FND_FLEX_VALUE_SETS FFVS
                    ON FFVS.FLEX_VALUE_SET_ID = SEG.FLEX_VALUE_SET_ID   
            INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V FFV
                    ON SEG.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID  
                   AND FFVS.FLEX_VALUE_SET_ID   = FFV.FLEX_VALUE_SET_ID  
            INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V FFVT
                    ON FFVT.FLEX_VALUE_ID = FFV.FLEX_VALUE_ID 
       LEFT OUTER JOIN (SELECT FFV.FLEX_VALUE AS PROD_CODE
                --             FFV.ATTRIBUTE1 AS INV_ORG_CODE -- 20210331
                             , FFV.PARENT_FLEX_VALUE_LOW AS INV_ORG_CODE
                          FROM ERPSYS.ERP_FND_FLEX_VALU_VL_V FFVT
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V FFV
                            ON FFV.FLEX_VALUE_ID = FFVT.FLEX_VALUE_ID
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALUE_SETS FFVS
                            ON FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                    INNER JOIN ERPSYS.ERP_ORG_ORGA_DEFI_V OOD -- 20210331
                            ON FFV.PARENT_FLEX_VALUE_LOW = OOD.ORGANIZATION_CODE -- 20210331
                         WHERE FFVS.FLEX_VALUE_SET_NAME = 'LSIS_ORG_SPG'  -- 20210331
                           AND FFV.ENABLED_FLAG  = 'Y' -- 20210331
                           AND OOD.SET_OF_BOOKS_ID = 2022 -- 20210331
                           AND ISNULL(FFV.END_DATE_ACTIVE, GETDATE()) >= GETDATE()  -- 20210331
                           AND OOD.ORGANIZATION_CODE LIKE (CASE WHEN SUBSTRING(FFV.FLEX_VALUE,1,1) = '9' THEN OOD.ORGANIZATION_CODE
                                                            ELSE 'M%'
                                                       END) -- 20210331
                        -- AND FFVS.FLEX_VALUE_SET_NAME = 'LSIS_CATEGORY_SPG_VS' -- 20210331
                    ) INV_ORG  
                    ON FFV.FLEX_VALUE= INV_ORG.PROD_CODE
       LEFT OUTER JOIN T_DIM_FND_COM_ORG DCO
                    ON INV_ORG.INV_ORG_CODE= DCO.ORG_CODE
       --LEFT OUTER JOIN T_DIM_FND_COM_ORG DCO
       --             ON INV_ORG.INV_ORG_CODE= DCO.ORG_CODE
                 WHERE SEG.APPLICATION_ID = 101  
                   AND SEG.ID_FLEX_CODE = 'GL#'  
                   AND SEG.APPLICATION_COLUMN_NAME = 'SEGMENT1'  
                   AND FFV.ENABLED_FLAG ='Y'  
                   AND FFV.SUMMARY_FLAG <> 'Y'
                   AND SUBSTRING(FFVT.DESCRIPTION,-2,2) = N'공통'
                   AND NOT EXISTS (SELECT 'X' FROM T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP WHERE PRODUCT_LINE_CODE = FFV.FLEX_VALUE)
                   ;  


                -- 2. T_DIM_FND_COM_PROD_LN 변경적재
                MERGE [dbo].[T_DIM_FND_COM_PROD_LN] AS TRG
                USING ( 
                        SELECT FFV.FLEX_VALUE     AS PRODUCT_LINE_CODE
                             , FFV.FLEX_VALUE_ID  AS PRODUCT_LINE_ID
                             , ISNULL(DCPLSBM.PRODUCT_LINE_NAME, ISNULL(FFVT.DESCRIPTION,N'데이터 없음'))   AS PRODUCT_LINE_NAME
                             , CASE WHEN FFV.FLEX_VALUE='041' THEN 'M01'
                                    WHEN FFV.FLEX_VALUE='042' THEN 'M01'
                                  --WHEN FFV.FLEX_VALUE='640' THEN 'M03'  -- 20140417 자동차전장 관련..  5월이 되어 청주(M01)로 변경
                                    WHEN INV_ORG.INV_ORG_CODE IS NULL THEN ISNULL(DCPLSBM.ORG_CODE,'z{')
                                    ELSE INV_ORG.INV_ORG_CODE
                               END AS ORG_CODE --청주1공장 담당자 요청으로 해당 조건 추가함
                             , ISNULL(DCPLSBM.SPG_CODE, 'z{')                   AS SPG_CODE
                             , ISNULL(DCPLSBM.SPG_NAME, N'데이터 없음')          AS SPG_NAME 
                             , ISNULL(DCPLSBM.SPG_ALIGNMENT_SEQUENCE_NO,'99') AS SPG_ALIGNMENT_SEQUENCE_NO
                             , ISNULL(DCPLSBM.BUSINESS_CODE, 'z{')              AS BUSINESS_CODE
                             , ISNULL(DCPLSBM.BUSINESS_NAME, N'데이터 없음')     AS BUSINESS_NAME
                             , ISNULL(DCPLSBM.SALES_TYPE_NAME, N'데이터 없음')   AS SALES_TYPE_NAME
                             , ISNULL(DCPLSBM.USAGE_FLAG,FFV.ENABLED_FLAG)     AS USAGE_FLAG
                             , NULL AS [COMPANY_CODE]
                             , NULL AS [COMPANY_NAME]
                             , DATEADD(HOUR, 9 ,GETDATE()) AS [ETL_DT]
                          FROM ERPSYS.ERP_GL_LEDGERS LEG
                    INNER JOIN ERPSYS.ERP_FND_ID_FLEX_SEGM SEG
                            ON LEG.CHART_OF_ACCOUNTS_ID = SEG.ID_FLEX_NUM
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALUE_SETS FFVS
                            ON FFVS.FLEX_VALUE_SET_ID = SEG.FLEX_VALUE_SET_ID  
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V FFV
                            ON SEG.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID  
                            AND FFVS.FLEX_VALUE_SET_ID   = FFV.FLEX_VALUE_SET_ID  
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V FFVT
                            ON FFVT.FLEX_VALUE_ID = FFV.FLEX_VALUE_ID  
                LEFT OUTER JOIN T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP DCPLSBM 
                            ON FFV.FLEX_VALUE = DCPLSBM.PRODUCT_LINE_CODE
                LEFT OUTER JOIN (SELECT FFV.FLEX_VALUE AS PROD_CODE,
                        --             FFV.ATTRIBUTE1 AS INV_ORG_CODE -- 20210331
                                        FFV.PARENT_FLEX_VALUE_LOW AS INV_ORG_CODE
                                    FROM ERPSYS.ERP_FND_FLEX_VALU_VL_V FFVT
                              INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V FFV
                                      ON FFV.FLEX_VALUE_ID = FFVT.FLEX_VALUE_ID
                              INNER JOIN ERPSYS.ERP_FND_FLEX_VALUE_SETS FFVS
                                      ON FFVS.FLEX_VALUE_SET_ID = FFV.FLEX_VALUE_SET_ID
                              INNER JOIN ERPSYS.ERP_ORG_ORGA_DEFI_V OOD -- 20210331 
                                      ON FFV.PARENT_FLEX_VALUE_LOW = OOD.ORGANIZATION_CODE -- 20210331
                                   WHERE 1=1
                        --       AND FFVS.FLEX_VALUE_SET_NAME = 'LSIS_CATEGORY_SPG_VS' -- 20210331
                                     AND FFVS.FLEX_VALUE_SET_NAME = 'LSIS_ORG_SPG'  -- 20210331
                                     AND FFV.ENABLED_FLAG  = 'Y' -- 20210331
                                     AND OOD.SET_OF_BOOKS_ID = 2022 -- 20210331
                                     AND ISNULL(FFV.END_DATE_ACTIVE,FORMAT(GETDATE(), 'yyyy-MM-dd')) >= FORMAT(GETDATE(), 'yyyy-MM-dd') -- 20210331
                                     AND OOD.ORGANIZATION_CODE LIKE (CASE WHEN SUBSTRING(FFV.FLEX_VALUE,1,1) = '9' THEN OOD.ORGANIZATION_CODE
                                                                    ELSE 'M%' END) -- 20210331
                                ) INV_ORG  
                            ON  FFV.FLEX_VALUE= INV_ORG.PROD_CODE
               LEFT OUTER JOIN T_DIM_FND_COM_ORG DCO
                            ON INV_ORG.INV_ORG_CODE= DCO.ORG_CODE
                         WHERE SEG.APPLICATION_ID = 101  
                           AND SEG.ID_FLEX_CODE = 'GL#'   
                           AND SEG.APPLICATION_COLUMN_NAME = 'SEGMENT1'  
                           AND FFV.ENABLED_FLAG = 'Y'  
                           AND FFV.SUMMARY_FLAG <> 'Y' 
                           AND LEG.LEDGER_ID = 2022
              UNION ALL SELECT 'z{',-99,N'데이터 없음','z{','z{',N'데이터 없음',99,'z{',N'데이터 없음',N'데이터 없음','Y', NULL, NULL, DATEADD(HOUR, 9 ,GETDATE())
              UNION ALL SELECT 'z~',-999,N'데이터 오류','z~','z~',N'데이터 오류',99,'z~',N'데이터 오류',N'데이터 오류','Y', NULL, NULL, DATEADD(HOUR, 9 ,GETDATE()) 
			  UNION ALL SELECT 'XXX',-9999,N'기타 공통제품류','z{','999',N'공통제품류',108,'999',N'공통제품류',N'데이터 없음','Y',NULL,NULL,DATEADD(HOUR, 9 ,GETDATE())) AS SRC 
                   ON (TRG.PRODUCT_LINE_CODE = SRC.PRODUCT_LINE_CODE)
                 WHEN MATCHED THEN
               UPDATE SET TRG.[PRODUCT_LINE_ID]             = SRC.[PRODUCT_LINE_ID]
                        , TRG.[PRODUCT_LINE_NAME]           = SRC.[PRODUCT_LINE_NAME]
                        , TRG.[ORG_CODE]                    = SRC.[ORG_CODE]
                        , TRG.[SPG_CODE]                    = SRC.[SPG_CODE]
                        , TRG.[SPG_NAME]                    = SRC.[SPG_NAME]
                        , TRG.ORG_PRODUCT_LINE_CODE_KEY     = CONCAT(SRC.[ORG_CODE], SRC.[PRODUCT_LINE_CODE])
                        , TRG.[SPG_ALIGNMENT_SEQUENCE_NO]   = SRC.[SPG_ALIGNMENT_SEQUENCE_NO]
                        , TRG.[BUSINESS_CODE]               = SRC.[BUSINESS_CODE]
                        , TRG.[BUSINESS_NAME]               = SRC.[BUSINESS_NAME]
                        , TRG.[SALES_TYPE_NAME]             = SRC.[SALES_TYPE_NAME]
                        , TRG.[USAGE_FLAG]                  = SRC.[USAGE_FLAG] 
                        , TRG.[ETL_DT]                      = SRC.[ETL_DT]
                 WHEN NOT MATCHED BY TARGET THEN
               INSERT ( [PRODUCT_LINE_CODE]
                      , [PRODUCT_LINE_ID]
                      , [PRODUCT_LINE_NAME]
                      , [ORG_CODE]
                      , [SPG_CODE]
                      , [SPG_NAME]
                      , ORG_PRODUCT_LINE_CODE_KEY
                      , [SPG_ALIGNMENT_SEQUENCE_NO]
                      , [BUSINESS_CODE]
                      , [BUSINESS_NAME]
                      , [SALES_TYPE_NAME]
                      , [USAGE_FLAG]
                      , [COMPANY_CODE]
                      , [COMPANY_NAME]
                      , [ETL_DT]
                      )
               VALUES ( [PRODUCT_LINE_CODE]
                      , [PRODUCT_LINE_ID]
                      , [PRODUCT_LINE_NAME]
                      , [ORG_CODE]
                      , [SPG_CODE]
                      , [SPG_NAME]
                      , CONCAT(ORG_CODE, PRODUCT_LINE_CODE)
                      , [SPG_ALIGNMENT_SEQUENCE_NO]
                      , [BUSINESS_CODE]
                      , [BUSINESS_NAME]
                      , [SALES_TYPE_NAME]
                      , [USAGE_FLAG]
                      , [COMPANY_CODE]
                      , [COMPANY_NAME]
                      , [ETL_DT]
                      ) 
                      ; 
                       

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_PROD_LN]
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

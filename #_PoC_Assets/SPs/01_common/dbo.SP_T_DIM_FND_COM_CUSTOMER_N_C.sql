CREATE PROC [dbo].[SP_T_DIM_FND_COM_CUSTOMER_N_C] AS

BEGIN

    SET NOCOUNT ON

    BEGIN

        DECLARE @v_run_pgm          varchar(50)
               ,@v_st_date          datetime
               ,@v_load_cnt         decimal(18,0)
               ,@v_enum             int
               ,@v_err_mesg         varchar(4000)
               ,@v_pgm_status       varchar(1)
               ,@v_work_result      int
               ,@v_tgt_job_area     varchar(10)
               ,@v_parm_from        varchar(50)
               ,@v_parm_to          varchar(50)
        ;

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_CUSTOMER_N_C'
        ;
        SET @v_st_date = DATEADD(HOUR, 9 ,GETDATE())
        ;
        SET @v_pgm_status = 'S'
        ;
        SET @v_work_result = 0
        ;
        SET @v_load_cnt = 0
        ;
        SET @v_tgt_job_area = 'FACT'
        ;

        BEGIN TRY

            MERGE [dbo].[T_DIM_FND_COM_CUSTOMER]                                 AS Target
            USING (
                   SELECT HCA.CUST_ACCOUNT_ID                                                AS ERP_CUSTOMER_ACCOUNT_ID                --ERP고객계정ID
                         ,HCASA.CUST_ACCT_SITE_ID                                            AS CUSTOMER_ACCOUNT_SITE_ID               --고객계정사이트ID
                         ,HCSUA.SITE_USE_ID                                                  AS SITE_USAGE_ID                          --SITEUSEID
                         ,HCP.CUST_ACCOUNT_PROFILE_ID                                        AS CUSTOMER_ACCOUNT_PROFILE_ID            --고객계정프로파일ID
                         ,HCPC.PROFILE_CLASS_ID                                              AS CUSTOMER_PROFILE_CLASS_ID              --프로파일분류ID
                         ,HP.PARTY_ID                                                        AS CUSTOMER_PARTY_ID                      --고객당사자ID
                         ,HCSUA.BILL_TO_SITE_USE_ID                                          AS BILL_TO_SHIP_TO_USAGE_ID
                         ,ISNULL(HCA.ACCOUNT_NUMBER ,'z{')                                   AS CUSTOMER_CODE                          --고객코드
                         ,ISNULL(SUBSTRING(HP.PARTY_NAME, 1, 50) ,N'데이타없음')                AS CUSTOMER_NAME                          --고객명
                         ,HCSUA.SITE_USE_CODE                                                AS BILL_TO_SHIP_TO_TYPE_CODE
                         ,HL.ADDRESS1                                                        AS CUSTOMER_ADDRESS1                      --고객주소1
                         ,HL.ADDRESS2                                                        AS CUSTOMER_ADDRESS2                      --고객주소2
                         ,ISNULL(HL.COUNTRY,'z{')                                            AS COUNTRY_CODE                           --국가코드
                         ,HCASA.TERRITORY_ID                                                 AS TERRITORY_ID                           --권역ID
                         ,HCA.GLOBAL_ATTRIBUTE1                                              AS REPRESENTATIVE_NAME                    --대표자명
                         ,HCASA.GLOBAL_ATTRIBUTE8                                            AS BUSINESS_TYPE_NAME                     --업종명
                         ,HP.GLOBAL_ATTRIBUTE3                                               AS BUSINESS_CONDITION_NAME                --업태명
                         ,HP.JGZZ_FISCAL_CODE                                                AS CORPORATION_ACCOUNTING_CODE            --법인회계코드
                         ,NULL                                                               AS ENTERPRISE_TYPE_NAME
                         ,NULL                                                               AS ENTERPRISE_TYPE_DESC
                         ,HCSUA.LOCATION                                                     AS CUSTOMER_LOCATION_NAME                 --고객위치명
                         ,ISNULL(SUBSTRING(ACCOUNT_NUMBER,1,3) ,'z{')                        AS MARKET_TYPE_CODE                       --시장구분코드ISNULL
                         ,CASE WHEN ACCOUNT_NUMBER IS NULL THEN N'데이타없음'
                               WHEN SUBSTRING(ACCOUNT_NUMBER, 1, 3) = 'ORG' THEN N'국내'
                               WHEN SUBSTRING(ACCOUNT_NUMBER, 1, 3) = 'OVC' THEN N'해외'
                               ELSE N'기타'
                          END                                                                AS MARKET_TYPE_NAME                       --시장구분코드명 ISNULL
                         ,HCSUA.PAYMENT_TERM_ID                                              AS PAYMENT_TERMS_ID                       --지급조건ID
                         ,HP.PARTY_TYPE                                                      AS PARTY_TYPE_NAME                        --당사자유형코드명
                         ,(SELECT SPECIAL_RELATIVE
                             FROM ERPSYS.ERP_EAR_CUSTOMER_SITES_V
                             WHERE customer_id = hca.cust_account_id
                               AND SITE_USE_ID = hcsua.site_use_id)                          AS RELATIVE_COMPANY_CODE                  --관계사코드
                        /* 2010.12.23. 생성일 추가 */
                         ,FORMAT(HCA.CREATION_DATE,'yyyyMMdd')                               AS CUSTOMER_CREATION_DATE
                         ,CASE WHEN HP.STATUS= 'A' THEN 'Y'
                               WHEN HP.STATUS ='I' THEN 'N'
                               ELSE  'z'
                          END                                                                AS USAGE_FLAG
                         ,DATEADD(HOUR, 9 ,GETDATE())                                        AS ETL_DT
                     FROM ERPSYS.ERP_HZ_CUST_ACCOUNTS HCA
                     JOIN ERPSYS.ERP_HZ_PARTIES HP
                       ON HCA.PARTY_ID = HP.PARTY_ID
                     JOIN ERPSYS.ERP_HZ_PARTY_SITES HPS
                       ON HP.PARTY_ID = HPS.PARTY_ID
                     JOIN ERPSYS.ERP_HZ_LOCATIONS HL
                       ON HPS.LOCATION_ID = HL.LOCATION_ID
                     JOIN ERPSYS.ERP_HZ_CUST_ACCT_SITES HCASA
                       ON HCA.CUST_ACCOUNT_ID = HCASA.CUST_ACCOUNT_ID
                      AND HPS.PARTY_SITE_ID   = HCASA.PARTY_SITE_ID
                     JOIN ERPSYS.ERP_HZ_CUST_SITE_USES HCSUA
                       ON HCASA.CUST_ACCT_SITE_ID = HCSUA.CUST_ACCT_SITE_ID
                     JOIN (
                           SELECT DISTINCT PROFILE_CLASS_ID,CUST_ACCOUNT_ID
                                 ,PARTY_ID
                                 ,CUST_ACCOUNT_PROFILE_ID
                             FROM ERPSYS.ERP_HZ_CUST_PROFILES
                           ) HCP
                       ON HCA.CUST_ACCOUNT_ID = HCP.CUST_ACCOUNT_ID
                      AND HP.PARTY_ID         = HCP.PARTY_ID
                     LEFT OUTER
                     JOIN ERPSYS.ERP_HZ_CUST_PROF_CLAS  HCPC
                       ON HCP.PROFILE_CLASS_ID  = HCPC.PROFILE_CLASS_ID
                    WHERE HPS.IDENTIFYING_ADDRESS_FLAG = 'Y'
                      AND ISNULL(hp.party_type       ,'AR') <> 'PARTY_RELATIONSHIP'   -- 조건추가 (T_AIM00000918 : ERP 개선과제 이행 TFT)
                      AND ISNULL(hp.created_by_module,'AR') <> 'HR API'               -- 조건추가 (T_AIM00000918 : ERP 개선과제 이행 TFT)
                    UNION ALL
                   SELECT CASE WHEN T.SEQNUM = 1 THEN -99
                               ELSE -999
                          END                                                    AS ERP_CUSTOMER_ACCOUNT_ID
                         ,CASE WHEN T.SEQNUM = 1 THEN -99
                               ELSE -999
                          END                                                    AS CUSTOMER_ACCOUNT_SITE_ID
                         ,CASE WHEN T.SEQNUM = 1 THEN -99
                               ELSE -999
                          END                                                    AS SITE_USAGE_ID
                         ,CASE WHEN T.SEQNUM = 1 THEN -99
                               ELSE -999
                          END                                                    AS CUSTOMER_ACCOUNT_PROFILE_ID
                         ,CASE WHEN T.SEQNUM = 1 THEN -99
                               ELSE -999
                          END                                                    AS CUSTOMER_PROFILE_CLASS_ID
                         ,CASE WHEN T.SEQNUM = 1 THEN -99
                               ELSE -999
                          END                                                    AS CUSTOMER_PARTY_ID
                         ,NULL                                                   AS BILL_TO_SHIP_TO_USAGE_ID
                         ,NULL                                                   AS CUSTOMER_CODE
                         ,CASE WHEN T.SEQNUM = 1 THEN N'데이터 없음'
                               ELSE N'데이터 오류'
                          END                                                    AS CUSTOMER_NAME
                         ,NULL                                                   AS BILL_TO_SHIP_TO_TYPE_CODE
                         ,NULL                                                   AS CUSTOMER_ADDRESS1
                         ,NULL                                                   AS CUSTOMER_ADDRESS2
                         ,NULL                                                   AS COUNTRY_CODE
                         ,NULL                                                   AS TERRITORY_ID
                         ,NULL                                                   AS REPRESENTATIVE_NAME
                         ,NULL                                                   AS BUSINESS_TYPE_NAME
                         ,NULL                                                   AS BUSINESS_CONDITION_NAME
                         ,NULL                                                   AS CORPORATION_ACCOUNTING_CODE
                         ,NULL                                                   AS ENTERPRISE_TYPE_NAME
                         ,NULL                                                   AS ENTERPRISE_TYPE_DESC
                         ,NULL                                                   AS CUSTOMER_LOCATION_NAME
                         ,NULL                                                   AS MARKET_TYPE_CODE
                         ,NULL                                                   AS MARKET_TYPE_NAME
                         ,NULL                                                   AS PAYMENT_TERMS_ID
                         ,NULL                                                   AS PARTY_TYPE_NAME
                         ,NULL                                                   AS RELATIVE_COMPANY_CODE
                         ,NULL                                                   AS CUSTOMER_CREATION_DATE
                         ,'Y'                                                    AS USAGE_FLAG
                         ,DATEADD(HOUR, 9 ,GETDATE())                            AS ETL_DT
                     FROM (
                           SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))     AS SEQNUM
                             FROM (
                                   SELECT 1 AS NN
                                     FROM INFORMATION_SCHEMA.COLUMNS A1
                                  ) A
                          ) T
                    WHERE SEQNUM <= 2
                  ) AS Source
                ON (Target.[ERP_CUSTOMER_ACCOUNT_ID]    = Source.ERP_CUSTOMER_ACCOUNT_ID
               AND Target.[CUSTOMER_ACCOUNT_SITE_ID]    = Source.CUSTOMER_ACCOUNT_SITE_ID
               AND Target.[SITE_USAGE_ID]               = Source.SITE_USAGE_ID
               AND Target.[CUSTOMER_ACCOUNT_PROFILE_ID] = Source.CUSTOMER_ACCOUNT_PROFILE_ID
               AND Target.[CUSTOMER_PROFILE_CLASS_ID]   = Source.CUSTOMER_PROFILE_CLASS_ID )
             WHEN MATCHED THEN
             UPDATE SET
                          Target.[CUSTOMER_PARTY_ID]             = Source.CUSTOMER_PARTY_ID
                         ,Target.[BILL_TO_SHIP_TO_USAGE_ID]      = Source.BILL_TO_SHIP_TO_USAGE_ID
                         ,Target.[CUSTOMER_CODE]                 = Source.CUSTOMER_CODE
                         ,Target.[CUSTOMER_NAME]                 = Source.CUSTOMER_NAME
                         ,Target.[BILL_TO_SHIP_TO_TYPE_CODE]     = Source.BILL_TO_SHIP_TO_TYPE_CODE
                         ,Target.[CUSTOMER_ADDRESS1]             = Source.CUSTOMER_ADDRESS1
                         ,Target.[CUSTOMER_ADDRESS2]             = Source.CUSTOMER_ADDRESS2
                         ,Target.[COUNTRY_CODE]                  = Source.COUNTRY_CODE
                         ,Target.[TERRITORY_ID]                  = Source.TERRITORY_ID
                         ,Target.[REPRESENTATIVE_NAME]           = Source.REPRESENTATIVE_NAME
                         ,Target.[BUSINESS_TYPE_NAME]            = Source.BUSINESS_TYPE_NAME
                         ,Target.[BUSINESS_CONDITION_NAME]       = Source.BUSINESS_CONDITION_NAME
                         ,Target.[CORPORATION_ACCOUNTING_CODE]   = Source.CORPORATION_ACCOUNTING_CODE
                         ,Target.[ENTERPRISE_TYPE_NAME]          = Source.ENTERPRISE_TYPE_NAME
                         ,Target.[ENTERPRISE_TYPE_DESC]          = Source.ENTERPRISE_TYPE_DESC
                         ,Target.[CUSTOMER_LOCATION_NAME]        = Source.CUSTOMER_LOCATION_NAME
                         ,Target.[MARKET_TYPE_CODE]              = Source.MARKET_TYPE_CODE
                         ,Target.[MARKET_TYPE_NAME]              = Source.MARKET_TYPE_NAME
                         ,Target.[PAYMENT_TERMS_ID]              = Source.PAYMENT_TERMS_ID
                         ,Target.[PARTY_TYPE_NAME]               = Source.PARTY_TYPE_NAME
                         ,Target.[RELATIVE_COMPANY_CODE]         = Source.RELATIVE_COMPANY_CODE
                         ,Target.[CUSTOMER_CREATION_DATE]        = Source.CUSTOMER_CREATION_DATE
                         ,Target.[USAGE_FLAG]                    = Source.USAGE_FLAG
                         ,Target.[ETL_DT]                        = Source.ETL_DT
             WHEN NOT MATCHED BY TARGET THEN
             INSERT (  [ERP_CUSTOMER_ACCOUNT_ID]
                      ,[CUSTOMER_ACCOUNT_SITE_ID]
                      ,[SITE_USAGE_ID]
                      ,[CUSTOMER_ACCOUNT_PROFILE_ID]
                      ,[CUSTOMER_PROFILE_CLASS_ID]
                      ,[CUSTOMER_PARTY_ID]
                      ,[BILL_TO_SHIP_TO_USAGE_ID]
                      ,[CUSTOMER_CODE]
                      ,[CUSTOMER_NAME]
                      ,[BILL_TO_SHIP_TO_TYPE_CODE]
                      ,[CUSTOMER_ADDRESS1]
                      ,[CUSTOMER_ADDRESS2]
                      ,[COUNTRY_CODE]
                      ,[TERRITORY_ID]
                      ,[REPRESENTATIVE_NAME]
                      ,[BUSINESS_TYPE_NAME]
                      ,[BUSINESS_CONDITION_NAME]
                      ,[CORPORATION_ACCOUNTING_CODE]
                      ,[ENTERPRISE_TYPE_NAME]
                      ,[ENTERPRISE_TYPE_DESC]
                      ,[CUSTOMER_LOCATION_NAME]
                      ,[MARKET_TYPE_CODE]
                      ,[MARKET_TYPE_NAME]
                      ,[PAYMENT_TERMS_ID]
                      ,[PARTY_TYPE_NAME]
                      ,[RELATIVE_COMPANY_CODE]
                      ,[CUSTOMER_CREATION_DATE]
                      ,[USAGE_FLAG]
                      ,[ETL_DT]
                    )
             VALUES (  Source.ERP_CUSTOMER_ACCOUNT_ID
                      ,Source.CUSTOMER_ACCOUNT_SITE_ID
                      ,Source.SITE_USAGE_ID
                      ,Source.CUSTOMER_ACCOUNT_PROFILE_ID
                      ,Source.CUSTOMER_PROFILE_CLASS_ID
                      ,Source.CUSTOMER_PARTY_ID
                      ,Source.BILL_TO_SHIP_TO_USAGE_ID
                      ,Source.CUSTOMER_CODE
                      ,Source.CUSTOMER_NAME
                      ,Source.BILL_TO_SHIP_TO_TYPE_CODE
                      ,Source.CUSTOMER_ADDRESS1
                      ,Source.CUSTOMER_ADDRESS2
                      ,Source.COUNTRY_CODE
                      ,Source.TERRITORY_ID
                      ,Source.REPRESENTATIVE_NAME
                      ,Source.BUSINESS_TYPE_NAME
                      ,Source.BUSINESS_CONDITION_NAME
                      ,Source.CORPORATION_ACCOUNTING_CODE
                      ,Source.ENTERPRISE_TYPE_NAME
                      ,Source.ENTERPRISE_TYPE_DESC
                      ,Source.CUSTOMER_LOCATION_NAME
                      ,Source.MARKET_TYPE_CODE
                      ,Source.MARKET_TYPE_NAME
                      ,Source.PAYMENT_TERMS_ID
                      ,Source.PARTY_TYPE_NAME
                      ,Source.RELATIVE_COMPANY_CODE
                      ,Source.CUSTOMER_CREATION_DATE
                      ,Source.USAGE_FLAG
                      ,Source.ETL_DT
                    )
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_CUSTOMER]
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

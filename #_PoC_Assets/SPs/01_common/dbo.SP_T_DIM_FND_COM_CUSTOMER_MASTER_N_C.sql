CREATE PROC [dbo].[SP_T_DIM_FND_COM_CUSTOMER_MASTER_N_C] AS

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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_CUSTOMER_MASTER_N_C'
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

            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_CUSTOMER_MASTER]
            ;
            
            INSERT INTO [dbo].[T_DIM_FND_COM_CUSTOMER_MASTER]
            (
                   [ERP_CUSTOMER_ACCOUNT_ID]                                       --ERP고객계정ID
                  ,[CUSTOMER_PARTY_ID]                                             --고객당사자ID
                  ,[CUSTOMER_CODE]                                                 --고객코드
                  ,[CUSTOMER_NAME]                                                 --고객명
                  ,[CORPORATION_ACCOUNTING_CODE]                                   --법인회계코드
                  ,[MARKET_TYPE_CODE]                                              --시장구분코드
                  ,[MARKET_TYPE_NAME]                                              --시장구분명
                  ,[COUNTRY_CODE]                                                  --국가코드
                  ,[RELATIVE_COMPANY_CODE]
                  ,[SUBSIDIARY_FLAG]                                               --자회사여부
                  ,[USAGE_FLAG]                                                    --사용여부
                  ,[ETL_DT]                                                        --적재일시
            )
            SELECT C.ERP_CUSTOMER_ACCOUNT_ID                                                                                 --ERP고객계정ID
                  ,MAX(C.CUSTOMER_PARTY_ID)                                                   AS CUSTOMER_PARTY_ID           --고객당사자ID
                  ,MAX(ISNULL(C.CUSTOMER_CODE, ''))                                           AS CUSTOMER_CODE               --고객코드
                  ,MAX(C.CUSTOMER_NAME)                                                       AS CUSTOMER_NAME               --고객명 -- 20181105 진혜영 (김동우S요청)
                  ,MAX(CASE WHEN LEN(TRIM(C.CORPORATION_ACCOUNTING_CODE)) = 14 AND SUBSTRING(C.CORPORATION_ACCOUNTING_CODE,7,1) = '-'
                                 AND ISNUMERIC(REPLACE(C.CORPORATION_ACCOUNTING_CODE,'-','0')) = 1
                                 AND SUBSTRING(C.CORPORATION_ACCOUNTING_CODE,8,1) IN ('1','2','3','4','5','6') THEN CONCAT(SUBSTRING(C.CORPORATION_ACCOUNTING_CODE,1,7),'*******')
                            ELSE C.CORPORATION_ACCOUNTING_CODE
                       END)                                                                   AS CORPORATION_ACCOUNTING_CODE   --법인회계코드 -- 20181105 진혜영 (김동우S요청) -- 개인정보관련해 법인회계코드가 주민등록번호형태로 들어오는경우 마스킹처리하여 표시
                  ,'0'                                                                        AS MARKET_TYPE_CODE              --시장구분코드
                  ,'0'                                                                        AS MARKET_TYPE_NAME              --시장구분명
                  ,MAX(C.COUNTRY_CODE)                                                        AS COUNTRY_CODE                  --20181019 진혜영 (이승준D요청)
                  ,'0'                                                                        AS RELATIVE_COMPANY_CODE
                  ,MAX(CASE C.CUSTOMER_PROFILE_CLASS_ID
                            WHEN 2040 THEN 'Y'
                            ELSE 'N'
                       END )                                                                  AS SUBSIDIARY_FLAG               --자회사여부
                  ,'0'                                                                        AS USAGE_FLAG                    --사용여부
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                AS ETL_DT
              FROM [dbo].[T_DIM_FND_COM_CUSTOMER] C
              JOIN (
                    SELECT ERP_CUSTOMER_ACCOUNT_ID
                          ,MAX(FORMAT(ETL_DT,'yyyyMMdd'))                                     AS ETL_DT
                      FROM [dbo].[T_DIM_FND_COM_CUSTOMER]
                     GROUP BY ERP_CUSTOMER_ACCOUNT_ID
                   ) T
                ON C.ERP_CUSTOMER_ACCOUNT_ID = T.ERP_CUSTOMER_ACCOUNT_ID
               AND FORMAT(C.ETL_DT,'yyyyMMdd') = T.ETL_DT
            -- WHERE  1=1--C.CUSTOMER_CODE != 'OVC_0000550'-- 2011.03.22 제외해제 : 송정호 부장
             GROUP BY C.ERP_CUSTOMER_ACCOUNT_ID
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_CUSTOMER_MASTER]
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

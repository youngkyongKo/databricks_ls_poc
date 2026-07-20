CREATE PROC [dbo].[SP_T_DIM_FND_COM_ORG_N_C] AS

BEGIN

    SET NOCOUNT ON

    BEGIN
	/*******************************************************************************************************
    *  PROGRAM ID    :  SP_T_DIM_FND_COM_ORG_N_C
    *  DESCRIPTION   :  사업장 기준정보 SP
    *
    ********************************************************************************************************
    *  CHANGE HISTORY
    *-------------  ---------------  ---------------------  --------------------------------------------------------
    *  DATE         AUTHOR           CSR_NO                 DESCRIPTION
    *-------------  ---------------  ---------------------  --------------------------------------------------------
    *  2025-03-18   COMKDHC          SRM2502-08538          중국법인(대련,무석,상해) 사업장 추가
    ********************************************************************************************************/
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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_ORG_N_C'
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

            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_ORG]
            ;
            
            INSERT INTO [dbo].[T_DIM_FND_COM_ORG]
            (
                   [ORG_CODE]                                                          --ORG코드
                  ,[ORG_NAME]                                                          --ORG명
                  ,[DIVISION_CODE]                                                     --사업부코드
                  ,[DIVISION_NAME]                                                     --사업부명
                  ,[COMPANY_CODE]                                                      --본부코드
                  ,[COMPANY_NAME]                                                      --본부명
                  ,[ORG_ID]                                                            --ORG_ID
                  ,[MP_TENDER_BIZ_TP_CODE]                                             --양산수주구분코드
                  ,[DELETE_FLAG]                                                       --삭제여부
                  ,[REGISTER_DATE]                                                     --등록일자
                  ,[ACCT_BIZ_PLACE_CODE]                                               --회계사업장코드
                  ,[LEDGER_ID]                                                         --원장ID
                  ,[OU_ID]                                                             --OU_ID
                  ,[OPERATING_UNIT_NAME]                                               --OU명
                  ,[BIZ_GROUP_ID]                                                      --사업그룹아이디
                  ,[LEGAL_ENTITY_ID]                                                   --법인아이디
                  ,[COA_ID]                                                            --회계계정아이디
                  ,[ETL_DT]                                                            --적재일시
            )
            SELECT N30.ORG_CODE                                                                                    --ORG코드
                  ,N30.ORG_NAME                                                                                    --ORG명
                  ,N30.DIVISION_CODE                                                                               --사업부코드
                  ,ISNULL(CASE WHEN N30.DIVISION_CODE  = 'KC001' THEN N'청주2사업장'
                               WHEN N30.DIVISION_CODE  = 'KB011' THEN N'청주1사업장'                                  -- 20180807 윤성업D 요청. 진혜영 수정
                               ELSE N32.DIVISION_NAME
                          END,N'데이터 없음')                                                     AS DIVISION_NAME    --사업부명
                  ,ISNULL(N32.COMPANY_CODE,'z{')                                               AS COMPANY_CODE     --본부코드
                  ,ISNULL(N32.COMPANY_NAME,N'데이터 없음')                                        AS COMPANY_NAME     --본부명
                  ,N30.ORG_ID                                                                                      --ORG_ID
                  ,N30.MP_TENDER_BIZ_TP_CODE                                                                       --양산수주구분코드
                  ,N30.DELETE_FLAG                                                                                 --삭제여부
                  ,N30.REGISTER_DATE                                                                               --등록일자
                  ,N30.ACCT_BIZ_PLACE_CODE                                                                         --회계사업장코드
                  ,N30.LEDGER_ID
                  ,N30.OU_ID
                  ,N33.OPERATING_UNIT_NAME                                                                         --OU명
                  ,N33.BUSINESS_GROUP_ID                                                                           --사업그룹아이디
                  ,N33.LEGAL_ENTITY                                                                                --법인아이디
                  ,N33.CHART_OF_ACCOUNTS_ID                                                                        --회계계정아이디
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                 AS ETL_DT           --적재일시
              FROM (
                    SELECT N10.ORGANIZATION_CODE                                                                   AS ORG_CODE
                          ,N10.ORGANIZATION_NAME                                                                   AS ORG_NAME
                          ,CASE --WHEN N10.ORGANIZATION_CODE  IN ('M06','M07') THEN 'KB199'                                            --부산(양산/수주/R&D)
                                WHEN N10.ORGANIZATION_CODE  IN ('M06','M07') THEN 'KF002'                                            --부산(양산/수주/R&D) 2026, 생산본부)부산생산/설계부문
                                --WHEN N10.ORGANIZATION_CODE  IN ('M01','M02','M08','M09', 'M10', 'M11') THEN 'KB199'                  --청주사업장. 20220302 M10, M11 추가
                                WHEN N10.ORGANIZATION_CODE  IN ('M01','M02','M08','M09', 'M10', 'M11') THEN 'KB203'                  --청주사업장. 2026, 생산본부)청주생산/설계부문
                                --WHEN N10.ORGANIZATION_CODE  IN ('M01','M08') THEN 'KB011'                                            --청주1(양산/수주)
                                --WHEN N10.ORGANIZATION_CODE  IN ('M02','M09') THEN 'KC001'                                            --청주2(양산/수주)
                                WHEN N10.ORGANIZATION_CODE  IN ('M03','M04') THEN 'KD003'                                            --천안(양산/수주). 20220302 M10, M11 삭제
                                --WHEN N10.ORGANIZATION_CODE  IN ('R01')       THEN 'KH001'                                            --청주(R&D)
                                --WHEN N10.ORGANIZATION_CODE  IN ('R02')       THEN 'KI001'                                            --천안(R&D)
                                WHEN N10.ORGANIZATION_CODE  IN ('R01')       THEN 'KH037'                                            --청주(R&D)
                                WHEN N10.ORGANIZATION_CODE  IN ('R02')       THEN 'KI009'                                            --천안(R&D)
                                WHEN N10.ORGANIZATION_CODE  IN ('R03')       THEN 'KG116'                                            --안양(R&D)
                                WHEN N10.ORGANIZATION_CODE  IN ('R05')       THEN 'KJ003'                                            --부산(R&D)
                                WHEN N10.ORGANIZATION_CODE  IN ('R06')       THEN 'KG092'                                            --안양(자동화R&D)
								ELSE 'z{'
                           END                                                                                     AS DIVISION_CODE
                          ,N10.ORGANIZATION_ID                                                                     AS ORG_ID
                          ,ISNULL(N11.TYPE,'z{')                                                                   AS MP_TENDER_BIZ_TP_CODE
                          ,'N'                                                                                     AS DELETE_FLAG
                          ,FORMAT(N11.DATE_FROM,'yyyyMMdd')                                                        AS REGISTER_DATE
                          ,ISNULL(N12.ATTRIBUTE6,'z{')                                                             AS ACCT_BIZ_PLACE_CODE
                          ,N10.SET_OF_BOOKS_ID                                                                     AS LEDGER_ID
                          ,N10.OPERATING_UNIT                                                                      AS OU_ID
                         FROM ERPSYS.ERP_ORG_ORGA_DEFI_V N10
                         JOIN ERPSYS.ERP_HR_ALL_ORGA_UNITS N11
                           ON N10.ORGANIZATION_ID  = N11.ORGANIZATION_ID
                         JOIN ERPSYS.ERP_MTL_PARAMETERS N12
                           ON N10.ORGANIZATION_ID  = N12.ORGANIZATION_ID
                        WHERE N10.SET_OF_BOOKS_ID  = 2022
                   ) N30
              JOIN T_DIM_FND_COM_ORGANIZATION N31
                ON N30.DIVISION_CODE = N31.DEPARTMENT_CODE
              JOIN T_DIM_FND_COM_ORGANIZATION N32
                ON N31.CONVERSION_DEPARTMENT_CODE = N32.DEPARTMENT_CODE
              JOIN ERP.EXT_EINV_PROD_ORG_MSTT N33
                ON N30.ORG_ID = N33.ORGANIZATION_ID
             UNION ALL
            SELECT CASE WHEN T.SEQNUM = 1 THEN 'z{'
                        ELSE 'z~'
                   END                                                    AS ORG_CODE
                  ,CASE WHEN T.SEQNUM = 1 THEN N'데이터 없음'
                        ELSE N'데이터 오류'
                   END                                                    AS ORG_NAME
                  ,CASE WHEN T.SEQNUM = 1 THEN 'z{'
                        ELSE 'z~'
                   END                                                    AS DIVISION_CODE
                  ,CASE WHEN T.SEQNUM = 1 THEN N'데이터 없음'
                        ELSE N'데이터 오류'
                   END                                                    AS DIVISION_NAME
                  ,CASE WHEN T.SEQNUM = 1 THEN 'z{'
                        ELSE 'z~'
                   END                                                    AS COMPANY_CODE
                  ,CASE WHEN T.SEQNUM = 1 THEN N'데이터 없음'
                        ELSE N'데이터 오류'
                   END                                                    AS COMPANY_NAME
                  ,CASE WHEN T.SEQNUM = 1 THEN -99
                        ELSE -999
                   END                                                    AS ORG_ID
                  ,CASE WHEN T.SEQNUM = 1 THEN 'z{'
                        ELSE 'z~'
                   END                                                    AS MP_TENDER_BIZ_TP_CODE
                  ,'N'                                                    AS DELETE_FLAG
                  ,'20110408'                                             AS REGISTER_DATE
                  ,CASE WHEN T.SEQNUM = 1 THEN 'z{'
                        ELSE 'z~'
                   END                                                    AS ACCT_BIZ_PLACE_CODE
                  ,CASE WHEN T.SEQNUM = 1 THEN -99
                        ELSE -999
                   END                                                    AS LEDGER_ID
                  ,CASE WHEN T.SEQNUM = 1 THEN -99
                        ELSE -999
                   END                                                    AS OU_ID
                  ,CASE WHEN T.SEQNUM = 1 THEN N'데이터 없음'
                        ELSE N'데이터 오류'
                   END                                                    AS OPERATING_UNIT_NAME
                  ,CASE WHEN T.SEQNUM = 1 THEN -99
                        ELSE -999
                   END                                                    AS BIZ_GROUP_ID
                  ,CASE WHEN T.SEQNUM = 1 THEN -99
                        ELSE -999
                   END                                                    AS LEGAL_ENTITY_ID
                  ,CASE WHEN T.SEQNUM = 1 THEN -99
                        ELSE -999
                   END                                                    AS COA_ID
                  ,DATEADD(HOUR, 9 ,GETDATE())                            AS ETL_DT
              FROM (
                    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))     AS SEQNUM
                      FROM (
                            SELECT 1 AS NN
                              FROM INFORMATION_SCHEMA.COLUMNS A1
                           ) A
                   ) T
             WHERE SEQNUM <= 2
			 -- 모법인 외 해외법인 사업장 정보 추가
			 UNION ALL
			 SELECT N30.ORG_CODE                                                                                    --ORG코드
                  ,N30.ORG_NAME                                                                                    --ORG명
                  ,N30.DIVISION_CODE                                                                               --사업부코드
                  ,ISNULL(CASE WHEN N30.DIVISION_CODE  = 'KC001' THEN N'청주2사업장'
                               WHEN N30.DIVISION_CODE  = 'KB011' THEN N'청주1사업장'                                  -- 20180807 윤성업D 요청. 진혜영 수정
                               ELSE N32.DIVISION_NAME
                          END,N'데이터 없음')                                                     AS DIVISION_NAME    --사업부명
                  ,ISNULL(N32.COMPANY_CODE,'z{')                                               AS COMPANY_CODE     --본부코드
                  ,ISNULL(N32.COMPANY_NAME,N'데이터 없음')                                        AS COMPANY_NAME     --본부명
                  ,N30.ORG_ID                                                                                      --ORG_ID
                  ,N30.MP_TENDER_BIZ_TP_CODE                                                                       --양산수주구분코드
                  ,N30.DELETE_FLAG                                                                                 --삭제여부
                  ,N30.REGISTER_DATE                                                                               --등록일자
                  ,N30.ACCT_BIZ_PLACE_CODE                                                                         --회계사업장코드
                  ,N30.LEDGER_ID
                  ,N30.OU_ID
                  ,N33.OPERATING_UNIT_NAME                                                                         --OU명
                  ,N33.BUSINESS_GROUP_ID                                                                           --사업그룹아이디
                  ,N33.LEGAL_ENTITY                                                                                --법인아이디
                  ,N33.CHART_OF_ACCOUNTS_ID                                                                        --회계계정아이디
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                 AS ETL_DT           --적재일시
              FROM (
                    SELECT N10.ORGANIZATION_CODE                                                                   AS ORG_CODE
                          ,N10.ORGANIZATION_NAME                                                                   AS ORG_NAME
                          ,CASE WHEN N10.ORGANIZATION_CODE  IN ('CW1','CW9') THEN 'KA055'                                            --무석
								WHEN N10.ORGANIZATION_CODE  IN ('CD1','CD2') THEN 'KA056'                                            --대련
								WHEN N10.ORGANIZATION_CODE  IN ('CS1')       THEN 'KA537'                                            --상해
                                ELSE 'z{'
                           END                                                                                     AS DIVISION_CODE
                          ,N10.ORGANIZATION_ID                                                                     AS ORG_ID
                          ,ISNULL(N11.TYPE,'z{')                                                                   AS MP_TENDER_BIZ_TP_CODE
                          ,'N'                                                                                     AS DELETE_FLAG
                          ,FORMAT(N11.DATE_FROM,'yyyyMMdd')                                                        AS REGISTER_DATE
                          ,ISNULL(N12.ATTRIBUTE6,'z{')                                                             AS ACCT_BIZ_PLACE_CODE
                          ,N10.SET_OF_BOOKS_ID                                                                     AS LEDGER_ID
                          ,N10.OPERATING_UNIT                                                                      AS OU_ID
                         FROM ERPSYS.ERP_ORG_ORGA_DEFI_V N10
                         JOIN ERPSYS.ERP_HR_ALL_ORGA_UNITS N11
                           ON N10.ORGANIZATION_ID  = N11.ORGANIZATION_ID
                         JOIN ERPSYS.ERP_MTL_PARAMETERS N12
                           ON N10.ORGANIZATION_ID  = N12.ORGANIZATION_ID
                        WHERE N10.SET_OF_BOOKS_ID  IN (2041,2045,2081) -- 대련,무석,상해 추가
                   ) N30
              JOIN T_DIM_FND_COM_ORGANIZATION N31
                ON N30.DIVISION_CODE = N31.DEPARTMENT_CODE
              JOIN T_DIM_FND_COM_ORGANIZATION N32
                ON N31.CONVERSION_DEPARTMENT_CODE = N32.DEPARTMENT_CODE
              JOIN ERP.EXT_EINV_PROD_ORG_MSTT N33
                ON N30.ORG_ID = N33.ORGANIZATION_ID
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_ORG]
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

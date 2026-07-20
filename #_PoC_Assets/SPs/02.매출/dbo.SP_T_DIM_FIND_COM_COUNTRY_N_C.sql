CREATE PROC [dbo].[SP_T_DIM_FND_COM_COUNTRY_N_C] AS

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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_COUNTRY_N_C'
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

            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_COUNTRY]
            ;
            
            INSERT INTO [dbo].[T_DIM_FND_COM_COUNTRY]
            (
            	   [COUNTRY_CODE]                                          --국가코드
            	  ,[COUNTRY_NAME]                                          --국가명
            	  ,[COUNTRY_CODE_DESC]                                     --국가코드설명
            	  ,[TERRITORY_ID]                                          --권역ID
            	  ,[TERRITORY_ENGLISH_NAME]                                --권역영문명
            	  ,[DOMESTIC_OVERSEAS_TYPE]                                --국내해외구분코드
            	  ,[USAGE_FLAG]                                            --사용여부
            	  ,[MERGED_NAME]                                           --권역국가명
            	  ,[ETL_DT]                                                --적재일시
            )
            SELECT ISNULL(FTS.TERRITORY_CODE,'z{')                        AS COUNTRY_CODE
                  ,ISNULL(FTT.TERRITORY_SHORT_NAME, N'데이타 없음')          AS COUNTRY_NAME
                  ,FTT.DESCRIPTION                                        AS COUNTRY_CODE_DESC
                  ,ISNULL(RT.TERRITORY_ID,-99)                            AS TERRITORY_ID
                  ,RT.SEGMENT1                                            AS TERRITORY_ENGLISH_NAME
                  ,CASE WHEN TERRITORY_ID = 1211 THEN 'D'
                        ELSE 'E'
                   END                                                    AS DOMESTIC_OVERSEAS_TYPE
                  ,RT.ENABLED_FLAG                                        AS USAGE_FLAG
                  ,RT.DESCRIPTION                                         AS MERGED_NAME --EC.MERGED_NAME
                  ,DATEADD(HOUR, 9 ,GETDATE())                            AS ETL_DT
              FROM ERPSYS.ERP_FND_TERRITORIES_TL  FTT
              JOIN ERPSYS.ERP_FND_TERRITORIES   FTS
                ON FTT.TERRITORY_CODE = FTS.TERRITORY_CODE
              LEFT OUTER
              JOIN ERPSYS.ERP_RA_TERRITORIES RT
                ON FTT.TERRITORY_CODE = RT.SEGMENT2
			   AND RT.STATUS = 'A' -- ERP 기준 유효한 것 체크, 코드가 중복됨.
             UNION ALL
            SELECT CASE WHEN T.SEQNUM = 1 THEN 'z{'
                        ELSE 'z~'
                   END                                                    AS COUNTRY_CODE
                  ,CASE WHEN T.SEQNUM = 1 THEN N'데이터 없음'
                        ELSE N'데이터 오류'
                   END                                                    AS COUNTRY_NAME
                  ,CASE WHEN T.SEQNUM = 1 THEN N'데이터 없음'
                        ELSE N'데이터 오류'
                   END                                                    AS COUNTRY_CODE_DESC
                  ,CASE WHEN T.SEQNUM = 1 THEN -99
                        ELSE -999
                   END                                                    AS TERRITORY_ID
                  ,NULL                                                   AS TERRITORY_ENGLISH_NAME
                  ,NULL                                                   AS DOMESTIC_OVERSEAS_TYPE
                  ,'Y'                                                    AS USAGE_FLAG
                  ,NULL                                                   AS MERGED_NAME
                  ,DATEADD(HOUR, 9 ,GETDATE())                            AS ETL_DT
              FROM (
                    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))     AS SEQNUM
                      FROM (
                            SELECT 1 AS NN
                              FROM INFORMATION_SCHEMA.COLUMNS A1
                           ) A
                   ) T
             WHERE SEQNUM <= 2
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_COUNTRY]
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

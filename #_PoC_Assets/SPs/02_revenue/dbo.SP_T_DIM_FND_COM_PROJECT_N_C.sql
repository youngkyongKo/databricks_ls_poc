CREATE PROC [dbo].[SP_T_DIM_FND_COM_PROJECT_N_C] AS

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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_PROJECT_N_C'
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

            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_PROJECT]
            ;
            
            INSERT INTO [dbo].[T_DIM_FND_COM_PROJECT]
            (
            	   [PROJECT_ID]
            	  ,[PROJECT_NO]
            	  ,[PROJECT_NAME]
            	  ,[PROJECT_TYPE_NAME]
            	  ,[PROJECT_STATUS_CODE]
            	  ,[PROJECT_START_DATE]
            	  ,[PROJECT_COMPLETION_DATE]
            	  ,[PRODUCT_LINE_CODE]
            	  ,[PRODUCT_LINE_NAME]
            	  ,[CONVERSION_PRODUCT_LINE_CODE]
            	  ,[CONVERSION_PRODUCT_LINE_NAME]
            	  ,[USAGE_FLAG]
            	  ,[ORG_ID]
            	  ,[ETL_DT]
            )
            SELECT PPA.PROJECT_ID                                                                 AS PROJECT_ID                   --프로젝트ID
                  ,ISNULL(PPA.SEGMENT1 ,'z{')                                                     AS PROJECT_NO                   --프로젝트번호
                  ,ISNULL(PPA.LONG_NAME ,N'데이타 없음')                                           AS PROJECT_NAME                 --프로젝트명
                  ,ISNULL(PPA.PROJECT_TYPE,'z{')                                                  AS PROJECT_TYPE_NAME            --프로젝트유형
                  ,ISNULL(PPA.PROJECT_STATUS_CODE,'z{')                                           AS PROJECT_STATUS_CODE          --프로젝트상태코드
                  ,FORMAT(PPA.START_DATE     , 'yyyyMMdd')                                        AS PROJECT_START_DATE           --프로젝트시작일자
                  ,FORMAT(PPA.COMPLETION_DATE, 'yyyyMMdd')                                        AS PROJECT_COMPLETION_DATE      --프로젝트완료일자
                  ,CASE WHEN PSVL.SEGMENT_VALUE IS NULL THEN 'z{'
                        WHEN A.PRODUCT_LINE_CODE IS NULL THEN 'z~'
                        ELSE A.PRODUCT_LINE_CODE
                   END                                                                            AS PRODUCT_LINE_CODE            --제품류코드
                  ,CASE WHEN PSVL.SEGMENT_VALUE_LOOKUP IS NULL THEN N'데이터 없음'
                        WHEN A.PRODUCT_LINE_NAME IS NULL THEN N'데이터 오류'
                        ELSE A.PRODUCT_LINE_NAME
                   END                                                                            AS PRODUCT_LINE_NAME            --제품류명
                  ,CASE WHEN PSVL.SEGMENT_VALUE IS NULL THEN 'z{'
                        WHEN A.PRODUCT_LINE_CODE IS NULL THEN 'z~'
                        ELSE A.CONVERSION_PRODUCT_LINE_CODE
                   END                                                                            AS CONVERSION_PRODUCT_LINE_CODE --변환제품류코드
                  ,CASE WHEN PSVL.SEGMENT_VALUE_LOOKUP IS NULL THEN N'데이터 없음'
                        WHEN A.PRODUCT_LINE_NAME IS NULL THEN N'데이터 오류'
                        ELSE A.CONVERSION_PRODUCT_LINE_NAME
                   END                                                                            AS CONVERSION_PRODUCT_LINE_NAME --변환제품류명
                  ,'Y'                                                                            AS USAGE_FLAG                   --사용여부
                  ,PPA.CARRYING_OUT_ORGANIZATION_ID                                               AS ORG_ID                       --사업장ID(의미없음) 20230621 추가
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                    AS ETL_DT                       --적재일시
              FROM ERPSYS.ERP_PA_PROJECTS_ALL        PPA
              LEFT OUTER
              JOIN ERPSYS.ERP_PA_PROJECT_CLASSES     PPC
                ON PPA.PROJECT_ID = PPC.PROJECT_ID
              LEFT OUTER
              JOIN ERPSYS.ERP_PA_SEGMENT_VALUE   PSVL
                ON PPC.CLASS_CODE = PSVL.SEGMENT_VALUE_LOOKUP
              LEFT OUTER
              JOIN T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP A
                ON PSVL.SEGMENT_VALUE = A.PRODUCT_LINE_CODE
            -- WHERE PPA.ORG_ID = 89
             UNION ALL -- RMS에만 존재하는 프로젝트no, name 추가 2011.09.07 by jskim
            SELECT CAST(PJT.PROJECT_NO AS BIGINT) * 100                                           AS PROJECT_ID                   --의미없음 pk 때문에 할수없이 입력
                  ,ISNULL(PJT.PROJECT_NO, 'z{')                                                   AS PROJECT_NO
                  ,ISNULL(PJT.PROJECT_NAME, 'z{')                                                 AS PROJECT_NAME
                  ,NULL                                                                           AS PROJECT_TYPE_NAME            --프로젝트유형
                  ,NULL                                                                           AS PROJECT_STATUS_CODE          --프로젝트상태코드
                  ,NULL                                                                           AS PROJECT_START_DATE           --프로젝트시작일자
                  ,NULL                                                                           AS PROJECT_COMPLETION_DATE      --프로젝트완료일자
                  ,NULL                                                                           AS PRODUCT_LINE_CODE            --제품류코드
                  ,NULL                                                                           AS PRODUCT_LINE_NAME            --제품류명
                  ,NULL                                                                           AS CONVERSION_PRODUCT_LINE_CODE --변환제품류코드
                  ,NULL                                                                           AS CONVERSION_PRODUCT_LINE_NAME --변환제품류명
                  ,'Y'                                                                            AS USAGE_FLAG                   --사용여부
                  ,NULL                                                                           AS ORG_ID                       --사업장ID(의미없음) 20230621 추가
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                    AS ETL_DT                       --적재일시
              FROM T_DIM_FND_COM_RND_PJT PJT
             WHERE PJT.PROJECT_NO NOT IN (SELECT DISTINCT ISNULL(PPA.SEGMENT1 ,'z{')      --프로젝트번호
                                            FROM ERPSYS.ERP_PA_PROJECTS_ALL        PPA
                                            LEFT OUTER
                                            JOIN ERPSYS.ERP_PA_PROJECT_CLASSES     PPC
                                              ON PPA.PROJECT_ID = PPC.PROJECT_ID
                                            LEFT OUTER
                                            JOIN ERPSYS.ERP_PA_SEGMENT_VALUE   PSVL
                                              ON PPC.CLASS_CODE = PSVL.SEGMENT_VALUE_LOOKUP
                                            LEFT OUTER
                                            JOIN T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP A
                                              ON PSVL.SEGMENT_VALUE = A.PRODUCT_LINE_CODE
                                          )
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_PROJECT]
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

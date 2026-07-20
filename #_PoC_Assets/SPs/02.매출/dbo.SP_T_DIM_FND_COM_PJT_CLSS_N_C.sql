CREATE PROC [dbo].[SP_T_DIM_FND_COM_PJT_CLSS_N_C] AS
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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_PJT_CLSS_N_C' -- procedure name 
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

            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_PJT_CLSS];
            INSERT INTO [dbo].[T_DIM_FND_COM_PJT_CLSS] 
            (
                   [PROJECT_CLASS_CODE]
                 , [PROJECT_CLASS_NAME]
                 , [PROJECT_LARGE_CLASS_CODE]
                 , [PROJECT_LARGE_CLASS_NAME]
                 , [ETL_DT]
            )
            SELECT ACCOUNTCODE                  AS PROJECT_CLASS_CODE 
                 , MAX(STRINGVALUE)             AS PROJECT_CLASS_NAME 
                 , CASE --WHEN MAX(ACCOUNTCODE) IN ('B00001', 'B00002', 'B00003', 'B00004', 'B00005', 'B00006') THEN '100'     -- 제품개발과제
				        WHEN MAX(ACCOUNTCODE) IN ('B00001', 'B00002', 'B00003', 'B00004', 'B00005', 'B00006','004006','004007') THEN '100'     -- 제품개발과제, 2023-06-21, COMKDH, ODM-A / ODM-B 추가, 차승우M 요청
                        WHEN MAX(ACCOUNTCODE) IN ('B00007') THEN '200'   -- 기술개발과제
                        WHEN MAX(ACCOUNTCODE) IN ('B00008') THEN '300'   -- 기술지원과제
                        WHEN MAX(ACCOUNTCODE) IN ('B00009') THEN '400'   -- 탐색연구과제
                        ELSE N'오류' END          AS PROJECT_LARGE_CLASS_CODE 
                 , CASE --WHEN MAX(ACCOUNTCODE) IN ('B00001', 'B00002', 'B00003', 'B00004', 'B00005', 'B00006') THEN N'제품개발과제'
				        WHEN MAX(ACCOUNTCODE) IN ('B00001', 'B00002', 'B00003', 'B00004', 'B00005', 'B00006','004006','004007') THEN N'제품개발과제' -- 2023-06-21, COMKDH, ODM-A / ODM-B 추가, 차승우M 요청
                        WHEN MAX(ACCOUNTCODE) IN ('B00007') THEN N'기술개발과제'
                        WHEN MAX(ACCOUNTCODE) IN ('B00008') THEN N'기술지원과제'
                        WHEN MAX(ACCOUNTCODE) IN ('B00009') THEN N'탐색연구과제'
                        ELSE N'오류' END          AS PROJECT_LARGE_CLASS_NAME                   --정렬코드
                 , DATEADD(HOUR, 9 ,GETDATE())      AS ETL_DT   
              FROM RMS.RMS_TR_CHARACVALUE
             WHERE --PARENTVALUEID   = 116
			       PARENTVALUEID   in (116, 418) -- 2023-06-21, comkdh, 차승우M 요청
          GROUP BY ACCOUNTCODE  
            UNION    ALL
            SELECT 'z{'                
                 , N'데이터 없음' 
                 , 'z{'      
                 , N'데이터 없음'
                 , DATEADD(HOUR, 9 ,GETDATE())  
            UNION    ALL
            SELECT 'z~'              
                 , N'데이터 오류'      
                 , 'z~' 
                 , N'데이터 오류'    
                 , DATEADD(HOUR, 9 ,GETDATE())  
                 ;


            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_PJT_CLSS]
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

        --SELECT @v_load_cnt, @v_pgm_status, @v_err_mesg

    END

END

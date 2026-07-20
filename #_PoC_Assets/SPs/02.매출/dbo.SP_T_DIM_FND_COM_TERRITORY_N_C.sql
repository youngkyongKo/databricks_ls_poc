CREATE PROC [dbo].[SP_T_DIM_FND_COM_TERRITORY_N_C] AS
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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_TERRITORY_N_C' -- procedure name 
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
         

            MERGE [dbo].[T_DIM_FND_COM_TERRITORY]  AS TRG
            USING (
                        SELECT RT.TERRITORY_ID                      AS TERRITORY_ID
                             , CASE WHEN RT.SEGMENT1 = 'CIS' THEN 'CIS'
                                    ELSE FFVT.DESCRIPTION
                               END                                  AS TERRITORY_NAME
                             , RT.SEGMENT1                          AS TERRITORY_ENGLISH_NAME
                             , RT.DESCRIPTION                       AS TERRITORY_NAME_DETAIL
                             , CASE WHEN RT.TERRITORY_ID = 1211 THEN 'D'
                                    ELSE 'E'
                               END                                  AS DOMESTIC_OVERSEAS_TYPE 
                             , ISNULL(DCRT.REPRESENTATIVE_TERRITORY_CODE ,'z{')  AS REPRESENTATIVE_TERRITORY_CODE
                             , FFV.ENABLED_FLAG                     AS USAGE_FLAG
                             , DATEADD(HOUR, 9 ,GETDATE())  AS [ETL_DT]
                          FROM ERPSYS.ERP_RA_TERRITORIES        RT
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V       FFV
                            ON RT.SEGMENT1               =  FFV.FLEX_VALUE
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V    FFVT
                            ON FFVT.FLEX_VALUE_ID        =  FFV.FLEX_VALUE_ID
                    INNER JOIN ERPSYS.ERP_FND_FLEX_VALUE_SETS   A_SET 
                            ON FFV.FLEX_VALUE_SET_ID     =  A_SET.FLEX_VALUE_SET_ID
                           AND A_SET.FLEX_VALUE_SET_NAME = 'LSIS_AR_TERRITORY_AREA'
                    INNER JOIN T_DIM_FND_COM_REP_TERR              DCRT
                            ON RT.SEGMENT1               =  DCRT.REPRESENTATIVE_TERRITORY_CODE
                         WHERE 1=1
                     UNION ALL SELECT -99, N'데이터 없음', 'NO DATA', N'데이터 없음', 'z{', NULL, 'Y', DATEADD(HOUR, 9 ,GETDATE())
                     UNION ALL SELECT -999, N'데이터 오류', 'ERROR DATA', N'데이터 오류', 'z~', NULL, 'Y', DATEADD(HOUR, 9 ,GETDATE())
         
                  ) AS SRC 
               ON (TRG.TERRITORY_ID = SRC.TERRITORY_ID)
             WHEN MATCHED THEN
           UPDATE SET TRG.TERRITORY_NAME                = SRC.TERRITORY_NAME
                    , TRG.TERRITORY_ENGLISH_NAME        = SRC.TERRITORY_ENGLISH_NAME
                    , TRG.TERRITORY_NAME_DETAIL         = SRC.TERRITORY_NAME_DETAIL
                    , TRG.DOMESTIC_OVERSEAS_TYPE        = SRC.DOMESTIC_OVERSEAS_TYPE
                    , TRG.REPRESENTATIVE_TERRITORY_CODE = SRC.REPRESENTATIVE_TERRITORY_CODE 
                    , TRG.USAGE_FLAG                    = SRC.USAGE_FLAG
                    , TRG.ETL_DT                        = SRC.ETL_DT      
             WHEN NOT MATCHED BY TARGET THEN 
           INSERT ( TERRITORY_ID
                  , TERRITORY_NAME
                  , TERRITORY_ENGLISH_NAME
                  , TERRITORY_NAME_DETAIL
                  , DOMESTIC_OVERSEAS_TYPE
                  , REPRESENTATIVE_TERRITORY_CODE
                  , USAGE_FLAG
                  , ETL_DT
                  )
           VALUES ( TERRITORY_ID
                  , TERRITORY_NAME
                  , TERRITORY_ENGLISH_NAME
                  , TERRITORY_NAME_DETAIL
                  , DOMESTIC_OVERSEAS_TYPE
                  , REPRESENTATIVE_TERRITORY_CODE
                  , USAGE_FLAG
                  , ETL_DT
                  ) 
                  ;


            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_TERRITORY]
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

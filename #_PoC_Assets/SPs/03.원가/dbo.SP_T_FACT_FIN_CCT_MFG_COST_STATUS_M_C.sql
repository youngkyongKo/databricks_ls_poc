CREATE PROC [dbo].[SP_T_FACT_FIN_CCT_MFG_COST_STATUS_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS

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
               ,@v_parm_from        varchar(50) = @F_YYYYMM
               ,@v_parm_to          varchar(50) = @T_YYYYMM
               ,@v_parm_comm_from   varchar(50)
               ,@v_parm_comm_to     varchar(50)
        ;

        SET @v_run_pgm = 'SP_T_FACT_FIN_CCT_MFG_COST_STATUS_M_C'
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

            DELETE FROM [dbo].[T_FACT_FIN_CCT_MFG_COST_STATUS]
             WHERE BASE_YYYYMM >= CASE WHEN SCENARIO_CODE <> 'BP' THEN @v_parm_from ELSE SUBSTRING(@v_parm_from,1,4) + '01' END
               AND BASE_YYYYMM <= CASE WHEN SCENARIO_CODE <> 'BP' THEN @v_parm_to ELSE SUBSTRING(@v_parm_to,1,4) + '12' END
            ;
            
            WITH T_PIN AS (
            SELECT AA.OCCUR_YYYYMM
                  ,'N'                                                                                          AS ACCUMULATION_FLAG
                  ,AA.ORG_CODE
                  ,BB.ACCT_BIZ_PLACE_CODE
                  ,AA.PRODUCT_LINE_CODE
                  ,SUM(AA.AMOUNT)                                                                               AS AMOUNT
              FROM (
                    SELECT A.OCCUR_YYYYMM
                          ,A.ORG_CODE
                          ,A.PRODUCT_LINE_CODE
                          ,A.AMOUNT                                                                             AS AMOUNT
                      FROM T_DW_FIN_CCT_AP_PJT_INDIVID_COST A
                     UNION ALL
                    SELECT B.OCCUR_YYYYMM
                          ,B.ORG_CODE
                          ,B.PRODUCT_LINE_CODE
                          ,B.DEBIT_AMOUNT AS AMOUNT
                      FROM T_DW_FIN_CCT_GL_PJT_INDIVID_COST B
                   ) AA
              JOIN T_DIM_FND_COM_ORG BB
                ON AA.ORG_CODE = BB.ORG_CODE
             GROUP BY AA.OCCUR_YYYYMM
                  ,AA.ORG_CODE
                  ,AA.PRODUCT_LINE_CODE
                  ,BB.ACCT_BIZ_PLACE_CODE
            )
            INSERT INTO [dbo].[T_FACT_FIN_CCT_MFG_COST_STATUS]
            (
                   [BASE_YYYYMM]                                                     --기준년월
                  ,[SALES_RECOGNITION_BASE_CODE]                                     --매출인식기준코드
                  ,[SCENARIO_CODE]                                                   --시나리오코드
                  ,[ACCUMULATION_FLAG]                                               --누계여부
                  ,[ORG_CODE]                                                        --ORG코드
                  ,[PRODUCT_LINE_CODE]                                               --제품류코드
                  ,[ORG_PRODUCT_LINE_CODE]                                           --조합키(조직코드+품목라인)
                  ,[ACCT_BIZ_PLACE_CODE]                                             --회계사업장코드
                  ,[PRODUCTION_AMOUNT]                                               --생산금액
                  ,[MFG_COST_VAR_MTL_COST]                                           --제조원가변동재료비
                  ,[MFG_COST_VAR_LBR_COST]                                           --제조원가변동노무비
                  ,[MFG_COST_FIX_LBR_COST]                                           --제조원가고정노무비
                  ,[MFG_COST_VAR_EXPENSE]                                            --제조원가변동경비
                  ,[MFG_COST_FIX_EXPENSE]                                            --제조원가고정경비
                  ,[PLAN_CONVERSION_COST]                                            --계획가공비
                  ,[ABSORPTION_AMOUNT]                                               --전부원가금액
                  ,[RESULT_CONVERSION_COST]                                          --실적가공비
                  ,[IND_COST_EXCL_RSLT_CONV_COST]                                    --개별비제외실적가공비
                  ,[ETL_DT]                                                          --적재일시
            )
            SELECT A.CLOSING_YYYYMM                                                                             AS BASE_YYYYMM
                  ,A.SALES_RECOGNITION_BASE_CODE
                  ,A.SCENARIO_CODE                                                                              AS SCENARIO_CODE
                  ,A.ACCUMULATION_FLAG                                                                          AS ACCUMULATION_FLAG
                  ,C.ORG_CODE                                                                                   AS ORG_CODE
                  ,A.PRODUCT_LINE_CODE                                                                          AS PRODUCT_LINE_CODE
                  ,CONCAT(TRIM(C.ORG_CODE),TRIM(A.PRODUCT_LINE_CODE))                                           AS ORG_PRODUCT_LINE_CODE    --조합키(조직코드+품목라인)
                  ,A.ACCT_BIZ_PLACE_CODE
                  ,SUM(CASE B.FS_IDX_CODE WHEN 'MS00001' /* 생산금액 */  THEN A.CLOSING_AMOUNT
                                          ELSE 0
                       END)                                                                                     AS PRODUCTION_AMOUNT
                  ,SUM(CASE B.FS_IDX_CODE WHEN 'MS10000' /* 제조원가변동재료비 */  THEN A.CLOSING_AMOUNT
                                          ELSE 0
                       END)                                                                                     AS MFG_COST_VAR_MTL_COST
                  ,SUM(CASE WHEN B.FS_IDX_CODE IN ('MS21000','MS22000','MS23000','MS24000','MS25000','MS26000','MS27000') /* 제조원가변동노무비 */
                                 THEN A.CLOSING_AMOUNT - A.CLOSING_AMOUNT * ISNULL(A.FIXED_COST_RATE,0)
                            ELSE 0
                       END)                                                                                     AS MFG_COST_VAR_LBR_COST
                  ,SUM(CASE WHEN B.FS_IDX_CODE IN ('MS21000','MS22000','MS23000','MS24000','MS25000','MS26000','MS27000') /* 제조원가고정노무비 */
                                 THEN A.CLOSING_AMOUNT * ISNULL(A.FIXED_COST_RATE,0)
                            ELSE 0
                       END )                                                                                    AS MFG_COST_FIX_LBR_COST
                  ,SUM(CASE WHEN B.FS_IDX_CODE IN ('MS31000','MS32000','MS33000','MS34000','MS35000','MS36000'
                                                  ,'MS37000','MS38000','MS39000','MS3B000','MS3C000','MS3D000'
                                                  ,'MS3E000','MS3F000','MS3G000','MS3H000','MS3I000','MS3J000'
                                                  ,'MS3K000','MS3L000','MS3M000','MS3N000','MS3O000','MS3P000'
                                                  ,'MS3Q000','MS3R000','MS3S000','MS50000','MS60000','MS70000'
                                                  ,'MS80000','MS3T000')                                                   -- 20190920 MS계정 리스자산상각비 MS3T000 추가 (DD_COM_MA_FS_ACCT)
                                 THEN A.CLOSING_AMOUNT - A.CLOSING_AMOUNT * ISNULL(A.FIXED_COST_RATE,1)
                            ELSE 0
                       END)                                                                                     AS MFG_COST_VAR_EXPENSE
                  ,SUM(CASE WHEN B.FS_IDX_CODE IN ('MS31000','MS32000','MS33000','MS34000','MS35000','MS36000'
                                                  ,'MS37000','MS38000','MS39000','MS3B000','MS3C000','MS3D000'
                                                  ,'MS3E000','MS3F000','MS3G000','MS3H000','MS3I000','MS3J000'
                                                  ,'MS3K000','MS3L000','MS3M000','MS3N000','MS3O000','MS3P000'
                                                  ,'MS3Q000','MS3R000','MS3S000','MS50000','MS60000','MS70000'
                                                  ,'MS80000','MS3T000')                                                    -- 20190920 MS계정 리스자산상각비 MS3T000 추가 (DD_COM_MA_FS_ACCT)
                                 THEN A.CLOSING_AMOUNT * ISNULL(A.FIXED_COST_RATE,1)
                            ELSE 0
                       END)                                                                                     AS MFG_COST_FIX_EXPENSE
                  ,SUM(CASE B.FS_IDX_CODE WHEN 'MSF0000' /* 계획가공비 */ THEN E.PLAN_CONVERSION_COST
                                          ELSE 0
                       END)                                                                                     AS PLAN_CONVERSION_COST
                  ,SUM(CASE B.FS_IDX_CODE WHEN 'MSE0000' /* Absorption 금액 */ THEN A.CLOSING_AMOUNT
                                          ELSE 0
                       END)                                                                                     AS ABSORPTION_AMOUNT
                  ,SUM(CASE B.FS_IDX_CODE WHEN 'MSF0000' /* 실적가공비 */ THEN A.CLOSING_AMOUNT
                                          ELSE 0
                       END)                                                                                     AS RESULT_CONVERSION_COST
                  ,SUM(CASE B.FS_IDX_CODE WHEN 'MSF0000' /* 개별비제외실적가공비 */ THEN A.CLOSING_AMOUNT - ISNULL(T_PIN.AMOUNT,0)
                                          ELSE 0
                       END)                                                                                     AS IND_COST_EXCL_RSLT_CONV_COST
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                                  AS ETL_DT                      --적재일시
              FROM T_FACT_FIN_CCT_MFG_COST_STMT A
              JOIN T_DIM_FND_COM_MA_FS_ACCT B    
                ON B.FS_TP_CODE = 'MS'
            --              AND A.CLOSING_YYYYMM BETWEEN B.START_YYYYMM AND B.END_YYYYMM
               AND A.FS_ACCT_SEQ_NO = B.FS_ACCT_SEQ_NO
              LEFT OUTER
              JOIN T_DIM_FND_COM_PROD_LN C
                ON A.PRODUCT_LINE_CODE = C.PRODUCT_LINE_CODE
              LEFT OUTER
              JOIN T_PIN
                ON A.CLOSING_YYYYMM = T_PIN.OCCUR_YYYYMM
               AND A.ACCT_BIZ_PLACE_CODE = T_PIN.ACCT_BIZ_PLACE_CODE
               AND A.PRODUCT_LINE_CODE  = T_PIN.PRODUCT_LINE_CODE
               AND A.ACCUMULATION_FLAG  = T_PIN.ACCUMULATION_FLAG
              LEFT OUTER
              JOIN T_FACT_FIN_CCM_MFG_COST_BIZ_PLN E
                ON A.CLOSING_YYYYMM      = E.PLAN_YYYYMM
               AND A.ACCT_BIZ_PLACE_CODE = E.ACCT_BIZ_PLACE_CODE
               AND A.PRODUCT_LINE_CODE   = E.PRODUCT_LINE_CODE
               AND A.ACCUMULATION_FLAG   = E.ACCUMULATION_FLAG
               AND E.INSIDE_OUTSIDE_TYPE_CODE = 'TOTAL'
             WHERE A.CLOSING_YYYYMM >= CASE WHEN SCENARIO_CODE <> 'BP' THEN @v_parm_from ELSE SUBSTRING(@v_parm_from,1,4) + '01' END
               AND A.CLOSING_YYYYMM <= CASE WHEN SCENARIO_CODE <> 'BP' THEN @v_parm_to ELSE SUBSTRING(@v_parm_to,1,4) + '12' END
               AND A.ACCT_BIZ_PLACE_CODE NOT IN ( 'z~','z{')
               AND C.ORG_CODE NOT IN ( 'z~','z{')
            --   AND A.SALES_RECOGNITION_BASE_CODE IN ('SC','ZZ') -- 출하('SC'), 진행('PG'), 계획('ZZ') 20140319
             GROUP BY A.CLOSING_YYYYMM
                  ,A.ACCUMULATION_FLAG
                  ,A.ACCT_BIZ_PLACE_CODE
                  ,A.PRODUCT_LINE_CODE
                  ,A.ACCT_BIZ_PLACE_CODE
                  ,C.ORG_CODE
                  ,A.SCENARIO_CODE
                  ,A.SALES_RECOGNITION_BASE_CODE
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_FACT_FIN_CCT_MFG_COST_STATUS]
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

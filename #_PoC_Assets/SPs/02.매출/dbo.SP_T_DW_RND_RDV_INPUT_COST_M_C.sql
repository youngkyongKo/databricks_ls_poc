CREATE PROC [dbo].[SP_T_DW_RND_RDV_INPUT_COST_M_C] @F_YYYYMM [varchar](50),@T_YYYYMM [varchar](50) AS

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

        SET @v_run_pgm = 'SP_T_DW_RND_RDV_INPUT_COST_M_C'
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

            DELETE FROM [dbo].[T_DW_RND_RDV_INPUT_COST] WHERE YYYYMM = @v_parm_to
            ;
            
            INSERT INTO [dbo].[T_DW_RND_RDV_INPUT_COST]
            (
                   [YYYYMM]                                        --기준년월
                  ,[PROJECT_NO]                                    --과제번호
                  ,[SLABOR_COST]                                   --인건비
                  ,[TST_RSCH_COST]                                 --기타시험연구비
                  ,[EXPENSE]                                       --일반경비
                  ,[MATERIAL_COST]                                 --재료비
                  ,[CON_RND_COST]                                  --위탁개발비
                  ,[TECH_COST]                                     --기술료
                  ,[DEPRN_EXPENSE]                                 --감가삼각비
                  ,[ETL_DT]                                        --적재일시
            )
            SELECT @v_parm_to                                                                              AS YYYYMM
                  ,C.PROJECT_NO
                  ,SUM(CASE WHEN AA.ITEM_CODE = N'인건비' THEN AA.AMOUNT_SIGN * AA.AMOUNT
                            ELSE 0
                       END)                                                                                AS SLABOR_COST     --인건비
                  ,SUM(CASE WHEN AA.ITEM_CODE = N'기타시험연구비' THEN AA.AMOUNT_SIGN * AA.AMOUNT
                            ELSE 0
                       END)                                                                                AS TST_RSCH_COST   --기타시험연구비
                  ,CAST(SUM(CASE WHEN AA.ITEM_CODE = N'일반경비' THEN AA.AMOUNT_SIGN * AA.AMOUNT
                                 ELSE 0
                            END) AS DECIMAL(21,4))                                                         AS EXPENSE         --일반경비
                  ,SUM(CASE WHEN AA.ITEM_CODE = N'재료비' THEN AA.AMOUNT_SIGN * AA.AMOUNT
                            ELSE 0
                       END)                                                                                AS MATERIAL_COST   --재료비
                  ,SUM(CASE WHEN AA.ITEM_CODE = N'위탁개발비' THEN AA.AMOUNT_SIGN * AA.AMOUNT
                            ELSE 0
                       END)                                                                                AS CON_RND_COST    --위탁개발비
                  ,SUM(CASE WHEN AA.ITEM_CODE = N'기술료' THEN AA.AMOUNT_SIGN * AA.AMOUNT
                            ELSE 0
                       END)                                                                                AS TECH_COST       --기술료
                  ,SUM(CASE WHEN AA.ITEM_CODE = N'감가상각비' THEN AA.AMOUNT_SIGN * AA.AMOUNT
                            ELSE 0
                       END)                                                                                AS DEPRN_EXPENSE   --감가삼각비
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                             AS ETL_DT          --적재일시
              FROM (
                    SELECT A.PROJECT_ID
                          ,B.ITEM_CODE
                          ,B.AMOUNT_SIGN
                          ,A.AMOUNT
                      FROM ERPSYS.ERP_EDCM_MGT_MONTH_DETAIL A
                      JOIN ERPSYS.ERP_EDCM_SUM_OF_ACCOUNTS_V B
                        ON A.ACCOUNT_CODE = B.ACCOUNT_CODE
                       AND B.ACCOUNT_LEVEL = 'NATURAL'
                       AND B.ITEM_CLASS = N'사업계획계정'
                       AND B.ENABLED_FLAG = 'Y'
                     WHERE A.YYYYMM <= @v_parm_to
                     UNION ALL
                    SELECT A.PROJECT_ID
                          ,B.ITEM_CODE
                          ,B.AMOUNT_SIGN
                          ,A.AMOUNT
                      FROM ERPSYS.ERP_EDCM_MGT_MONTH_DETAIL A
                      JOIN ERPSYS.ERP_EDCM_SUM_OF_ACCOUNTS_V B
                        ON A.PARENT_ACCOUNT_CODE = B.ACCOUNT_CODE
                       AND B.ACCOUNT_LEVEL = 'MIDDLE'
                       AND B.ITEM_CLASS = N'사업계획계정'
                       AND B.ENABLED_FLAG = 'Y'
                     WHERE A.YYYYMM <= @v_parm_to
                     UNION ALL
                    SELECT A.PROJECT_ID
                          ,B.ITEM_CODE
                          ,B.AMOUNT_SIGN
                          ,A.AMOUNT
                      FROM ERPSYS.ERP_EDCM_MGT_MONTH_DETAIL A
                      JOIN ERPSYS.ERP_EDCM_SUM_OF_ACCOUNTS_V B
                        ON dbo.RPAD(SUBSTRING(A.ACCOUNT_CODE, 1, 3), 7, '0') = B.ACCOUNT_CODE
                       AND B.ACCOUNT_LEVEL = 'SUPER'
                       AND B.ITEM_CLASS = N'사업계획계정'
                       AND B.ENABLED_FLAG = 'Y'
                     WHERE A.YYYYMM <= @v_parm_to
                   ) AA
              JOIN T_DIM_FND_COM_PROJECT C
                ON AA.PROJECT_ID = C.PROJECT_ID
             GROUP BY C.PROJECT_NO
            ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DW_RND_RDV_INPUT_COST]
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

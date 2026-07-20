CREATE PROC [dbo].[SP_T_DIM_FND_COM_RND_PJT_N_C] AS
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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_RND_PJT_N_C' -- procedure name 
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
 
                    TRUNCATE TABLE [dbo].[T_DIM_FND_COM_RND_PJT];
                    INSERT INTO [dbo].[T_DIM_FND_COM_RND_PJT]
                    (
                                [PROJECT_NO]
                              , [INVEST_ID]
                              , [METHODOLOGY_ID]
                              , [PROJECT_NO_INVEST_ID_METHODOLOGY_ID_KEY]
                              , [STEPID]
                              , [PROJECT_NAME]
                              , [PROJECT_CLASS_CODE]
                              , [PROJECT_LARGE_CLASS_CODE]
                              , [CHARGE_DEPARTMENT_CODE]
                              , [CHARGE_DIVISION_CODE]
                              , [PRODUCT_LINE_CODE]
                              , [PRI_ITEM_CODE]
                              , [REP_BIZ_PLACE_CODE]
                              , [PRODUCT_GROUP_CODE]
                              , [FUNDING_TYPE_CODE]
                              , [DEVELOPMENT_TYPE_CODE]
                              , [STRATEGY_TYPE_CODE]
                              , [APPLY_WBS_CODE]
                              , [MANY_YEARS_FLAG]
                              , [NEW_PRODUCT_FLAG]
                              , [TECHNICAL_COOPERATION_FLAG]
                              , [PLAN_PROJECT_FLAG]
                              , [PLAN_START_DATE]
                              , [PLAN_END_DATE]
                              , [FORECAST_START_DATE]
                              , [FORECAST_END_DATE]
                              , [ACTUAL_START_DATE]
                              , [ACTUAL_END_DATE]
                              , [END_REQUEST_TYPE_CODE]
                              , [TRANSFER_PROJECT_FLAG]
                              , [TRANSFER_DATE]
                              , [PM_PL_NAME]
                              , [PM_PL_EMPLOYEE_NO]
                              , [PROGRESS_STATUS_CODE]
                              , [PROGRESS_RATE]
                              , [CURRENT_PROGRESS_STEP_DESC]
                              , [RND_OBJECTIVE_DETAIL]
                              , [RND_CONTENT]
                              , [MAIN_SPEC_DESC]
                              , [CORE_TECHNICAL_DESC]
                              , [REVENUE_START_DATE]
                              , [ETL_DT]
                    ) 
                    SELECT O.ERPCD	                                                                AS PROJECT_NO                      -- 프로젝트번호
                         , A.REQUESTID                                                              AS INVEST_ID                                   -- 투자ID
                         , B.METHODID                                                               AS METHODOLOGY_ID                                   -- 방법론ID
                         , CONCAT(O.ERPCD, A.REQUESTID, B.METHODID)                                 AS PROJECT_NO_INVEST_ID_METHODOLOGY_ID_KEY
                         , B.STEPID				                                                    AS STEP_ID                                  -- STEPID
                         , O.NAME                                                                   AS PROJECT_NAME                    -- 프로젝트명
                         , ISNULL(H.PROJECTLEVELCD      , 'z{')                                     AS PROJECT_CLASS_CODE         -- 프로젝트분류코드
                         , ISNULL(S.PROJECT_LARGE_CLASS_CODE, 'z{')                                 AS PROJECT_LARGE_CLASS_CODE              -- 프로젝트대분류코드
                         , ISNULL((SELECT ISNULL(CONVERSION_DEPARTMENT_CODE, 'z{') FROM T_DIM_FND_COM_ORGANIZATION WHERE DEPARTMENT_CODE = SUBSTRING(O.DEPTCD, 1, 5)), 'z{')   AS CHARGE_DEPARTMENT_CODE      -- 담당부서코드(20110311 JSM)
                         , ISNULL((SELECT ISNULL(CONVERSION_DIVISION_CODE, 'z{') FROM T_DIM_FND_COM_ORGANIZATION WHERE DEPARTMENT_CODE = SUBSTRING(O.DEPTCD, 1, 5)), 'z{')     AS CHARGE_DIVISION_CODE      -- 담당사업부코드(20110304 JSM)
                         , ISNULL((SELECT ISNULL(CONVERSION_PRODUCT_LINE_CODE, 'z{') FROM T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP WHERE PRODUCT_LINE_CODE = D.PRODUCT), 'z{')        AS PRODUCT_LINE_CODE   -- 제품류코드(20110311 JSM)
                         , ISNULL(P.ITEMCODE                , 'z{')                                 AS PRI_ITEM_CODE              -- 대표ITEM코드
                         , ISNULL(P.ORGCODE                 , 'z{')                                 AS REP_BIZ_PLACE_CODE              -- 대표사업장코드
                         , ISNULL(G.PRODUCTGROUPCD      , 'z{')                                     AS PRODUCT_GROUP_CODE           -- 제품그룹코드
                         , ISNULL(I.PROJECTTYPECD      , 'z{')                                      AS FUNDING_TYPE_CODE         -- 펀딩유형코드
                         , ISNULL(J.DEVTYPECD        , 'z{')                                        AS DEVELOPMENT_TYPE_CODE       -- 개발유형코드
                         , ISNULL(M.STRATEGYTYPECD      , 'z{')                                     AS STRATEGY_TYPE_CODE          -- 전략유형코드
                         , ISNULL(N.ACCOUNTCODE         , 'z{')                                     AS WBSCODE             -- 적용WBS코드
                         , CASE WHEN (CONVERT(INT, FORMAT(B.REQUIREDEND, 'yyyy')) - CONVERT(INT, FORMAT(B.REQUIREDSTART, 'yyyy'))) =  0 THEN '0'ELSE '1' END  AS MANY_YEARS_FLAG -- 다년여부
                         , CASE WHEN ISNULL(K.NEWPRODUCT, '0') = '005001' THEN '1' ELSE '0' END     AS NEW_PRODUCT_FLAG  -- 신제품개발과제여부 --> 데이터 이슈
                         , CASE WHEN T.COMTECH = '003001' THEN '1' ELSE '0' END                     AS TECHNICAL_COOPERATION_FLAG     -- 기술협력여부 (★)     
                         , CASE WHEN TRIM(O.PLANNED_PJT) = 'YES' THEN '1' ELSE '0' END              AS PLAN_PROJECT_FLAG   -- 계획프로젝트여부
                         , FORMAT(B.REQUIREDSTART       , 'yyyyMMdd')                               AS PLAN_START_DATE           -- 계획시작일자
                         , FORMAT(B.REQUIREDEND         , 'yyyyMMdd')                               AS PLAN_END_DATE          -- 계획종료일자
                         , FORMAT(B.FORECASTSTART       , 'yyyyMMdd')                               AS FORECAST_START_DATE             -- 예측시작일자
                         , FORMAT(B.FORECASTEND         , 'yyyyMMdd')                               AS FORECAST_END_DATE             -- 예측종료일자
                         , FORMAT(B.ACTUALSTART         , 'yyyyMMdd')                               AS ACTUAL_START_DATE             -- 실제시작일자
                         , FORMAT(B.ACTUALEND           , 'yyyyMMdd')                               AS ACTUAL_END_DATE             -- 실제종료일자
                         , D.REQ_YN                                                                 AS END_REQUEST_TYPE_CODE        -- 종료요청여부
                         , O.TRANS_YN                                                               AS TRANSFER_PROJECT_FLAG              -- 이관프로젝트여부
                         , FORMAT(O.TRANSDT             , 'yyyyMMdd')                               AS TRANSFER_DATE             -- 이관일자
                         , C.PLNAME                                                                 AS PM_PL_NAME        -- PMPL명
                         , C.PLEMPNO                                                                AS PM_PL_EMPLOYEE_NO         -- PMPL사번
                         , ISNULL(E.DESCRIPTION             , 'z{')                                 AS PROGRESS_STATUS_CODE           -- 진행상태코드
                         , ISNULL(F.PERCENT_COMPLETE        , 0)                                    AS PROGRESS_RATE       -- 진척률
                         , N.CURRENT_LEVEL                                                          AS CURRENT_PROGRESS_STEP_DESC              -- 현재진행단계설명
                         , D.OBJECTIVE                                                              AS RND_OBJECTIVE_DETAIL                   -- 연구개발목적상세
                         , D.CONTENT                                                                AS RND_CONTENT            -- 연구개발내용
                         , D.SPEC                                                                   AS MAIN_SPEC_DESC                   -- 주요스펙내용
                         , D.CORETECH                                                               AS CORE_TECHNICAL_DESC                    -- 핵심기술내용
                         , FORMAT(B.REVENUESTART         , 'yyyyMMdd')                              AS REVENUE_START_DATE              -- 신제품매출인정시작일
                         , DATEADD(HOUR, 9 ,GETDATE())                                              AS ETL_DT
                      FROM RMS.RMS_TR_REQUEST               A                             -- 투자안 정의
                INNER JOIN RMS.RMS_TR_STEP                  B                             -- 프로젝트 정의
                        ON A.REQUESTID         = B.REQUESTID
                INNER JOIN (SELECT DISTINCT TRSA.STEPID
                                 , TRSA.RESOURCEID         AS PLID
                                 , TRR.NAME                AS PLNAME
                                 , TRR.DESCRIPTION         AS PLEMPNO
                              FROM RMS.RMS_TR_STEPACCESS     TRSA
                        INNER JOIN RMS.RMS_TR_RESOURCE       TRR
                                ON TRSA.RESOURCEID = TRR.RESOURCEID
                             WHERE 1=1
                               AND TRSA.ROLEID =  (SELECT DISTINCT ROLEID FROM RMS.RMS_TR_ROLE
                                                    WHERE DESCRIPTION = 'R01' )
                           )                                                        C                     -- PMPL명
                        ON B.STEPID = C.STEPID
           LEFT OUTER JOIN RMS.RMS_RMSD_RND_STEP                             D                     -- RMS R&D 과제정보
                        ON B.STEPID = D.STEPID 
           LEFT OUTER JOIN (SELECT RELEASESTATUSID
                                 , DESCRIPTION
                              FROM RMS.RMS_TR_RELEASESTATUS         
                             WHERE TYPE = 'R'
                           )                                                        E                     -- 진행상태코드 정의
                        ON B.RELEASESTATUSID = E.RELEASESTATUSID 
           LEFT OUTER JOIN (SELECT STEPID
                                 , PERCENT_COMPLETE
                              FROM RMS.RMS_TR_TASK
                             WHERE SEQUENCEKEY =   'AAB'
                           )                                                        F                     -- 진척률
                        ON B.STEPID = F.STEPID
           LEFT OUTER JOIN (SELECT TCV.STRINGVALUE     AS PRODUCTGROUP
                                 , TCV.ACCOUNTCODE     AS PRODUCTGROUPCD
                                 , TSC.STEPID
                              FROM RMS.RMS_TR_STEPCHARAC       TSC
                        INNER JOIN RMS.RMS_TR_CHARACVALUE      TCV
                                ON TSC.CHARACVALUEID   =   TCV.CHARACVALUEID
                             WHERE TCV.ACCOUNTCODE LIKE 'A0%'
                           )                                                        G                     -- 제품그룹코드
                        ON B.STEPID = G.STEPID
           LEFT OUTER JOIN (SELECT TSC.STEPID
                                 , MAX(TCV.ACCOUNTCODE)     AS PROJECTLEVELCD
                              FROM RMS.RMS_TR_STEPCHARAC       TSC
                        INNER JOIN RMS.RMS_TR_CHARACVALUE      TCV
                                ON TSC.CHARACVALUEID   =   TCV.CHARACVALUEID
                             WHERE TCV.ACCOUNTCODE LIKE 'B0%'
                          GROUP BY TSC.STEPID
                           )                                                        H                     -- 프로젝트분류코드
                        ON B.STEPID = H.STEPID
           LEFT OUTER JOIN (SELECT TSC.STEPID
                                 , MAX(TCV.ACCOUNTCODE)     AS PROJECTTYPECD
                              FROM RMS.RMS_TR_STEPCHARAC       TSC
                        INNER JOIN RMS.RMS_TR_CHARACVALUE      TCV
                                ON TSC.CHARACVALUEID   =   TCV.CHARACVALUEID
                             WHERE TCV.ACCOUNTCODE LIKE 'C0%'
                          GROUP BY TSC.STEPID
                           )                                                        I                     -- 펀딩유형코드
                        ON B.STEPID            = I.STEPID
           LEFT OUTER JOIN (SELECT TCV.STRINGVALUE     AS DEVTYPE
                                 , TCV.ACCOUNTCODE     AS DEVTYPECD
                                 , TSC.STEPID
                                 , (SELECT STRINGVALUE
                                      FROM RMS.RMS_TR_CHARACVALUE
                                     WHERE CHARACVALUEID   = TCV.PARENTVALUEID
                                   )                   AS SUDEVTYPE
                                 , (SELECT ACCOUNTCODE
                                      FROM RMS.RMS_TR_CHARACVALUE
                                     WHERE CHARACVALUEID   = TCV.PARENTVALUEID
                                   )                   AS SUDEVTYPECD
                              FROM RMS.RMS_TR_STEPCHARAC       TSC
                        INNER JOIN RMS.RMS_TR_CHARACVALUE      TCV
                                ON TSC.CHARACVALUEID   =   TCV.CHARACVALUEID
                             WHERE TCV.ACCOUNTCODE LIKE 'D0%'
                           )                                                        J                     -- 개발유형코드
                        ON B.STEPID            = J.STEPID
           LEFT OUTER JOIN (SELECT TSC.STEPID
                                 , TCV.ACCOUNTCODE     AS NEWPRODUCT
                              FROM RMS.RMS_TR_STEPCHARAC       TSC
                        INNER JOIN RMS.RMS_TR_CHARACVALUE      TCV
                                ON TSC.CHARACVALUEID   = TCV.CHARACVALUEID
                             WHERE TCV.ACCOUNTCODE = '005001'
                           )                                                        K                     -- 신제품여부
                        ON B.STEPID            = K.STEPID
           LEFT OUTER JOIN (SELECT TCV.STRINGVALUE     AS STRATEGYTYPE
                                 , TCV.ACCOUNTCODE     AS STRATEGYTYPECD
                                 , TSC.STEPID
                              FROM RMS.RMS_TR_STEPCHARAC       TSC
                        INNER JOIN RMS.RMS_TR_CHARACVALUE      TCV
                                ON TSC.CHARACVALUEID   =   TCV.CHARACVALUEID
                              WHERE TCV.ACCOUNTCODE LIKE 'M0%'
                           )                                                        M                     -- 전략유형코드
                        ON B.STEPID = M.STEPID
           LEFT OUTER JOIN (SELECT NAME AS CURRENT_LEVEL
                                 , STEPID
                                 , ACCOUNTCODE
                              FROM RMS.RMS_TR_TASK      TTS
                             WHERE TTS.SEQUENCEKEY IN (SELECT MIN(SEQUENCEKEY)
                                                         FROM RMS.RMS_TR_TASK
                                                        WHERE TTS.STEPID = STEPID
                                                          AND LEN(SEQUENCEKEY) = 6
                                                          AND PERCENT_COMPLETE < 100
                                                      )
                           )                                                        N                     -- 적용WBS코드
                        ON B.STEPID = N.STEPID
                INNER JOIN RMS.RMS_RMSD_STEP_ERPCD                           O                     -- ERP 전송 프로젝트번호
                        ON B.STEPID = O.STEPID
           LEFT OUTER JOIN (SELECT PROJECTCODE
                                 , SUBSTRING(ORGITEMCODE, 1, 3)     ORGCODE
                                 , SUBSTRING(ORGITEMCODE, 4, 15)    ITEMCODE
                              FROM ( SELECT PROJECTCODE
                                          , MAX(CONCAT(ORGCODE,ITEMCODE))  ORGITEMCODE
                                       FROM RMS.RMS_LSISPARTPROJECTLINK
                                      WHERE ISREP = 'Y'
                                   GROUP BY PROJECTCODE) A
                           )                                                        P                     -- 프로젝트 품목코드 연결
                       ON O.ERPCD = P.PROJECTCODE
                LEFT JOIN T_DIM_FND_COM_PJT_CLSS         S                     -- 프로젝트분류코드
                       ON H.PROJECTLEVELCD    = S.PROJECT_CLASS_CODE
          LEFT OUTER JOIN (SELECT MAX(TCV.ACCOUNTCODE)     AS COMTECH
                                , TSC.STEPID
                             FROM RMS.RMS_TR_STEPCHARAC        TSC
                       INNER JOIN RMS.RMS_TR_CHARACVALUE       TCV
                               ON TSC.CHARACVALUEID   = TCV.CHARACVALUEID
                            WHERE TCV.ACCOUNTCODE LIKE '003%'
                         GROUP BY TSC.STEPID
                          )                                                         T                     -- 기술협력여부  12월 10일 추가 ★
                        ON B.STEPID            = T.STEPID
                     WHERE 1=1    
                       AND B.PARENTSTEPID      LIKE '%'
                       AND ( B.TEMPLATESTEPID IS NULL OR B.TEMPLATESTEPID = 0 OR B.TEMPLATESTEPID ='')
                       ;

            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_RND_PJT]
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

CREATE PROC [dbo].[SP_T_DIM_FND_COM_ITEM_N_C] AS

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

        SET @v_run_pgm = 'SP_T_DIM_FND_COM_ITEM_N_C'
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

            TRUNCATE TABLE [dbo].[T_DIM_FND_COM_ITEM]
            ;

            INSERT INTO [dbo].[T_DIM_FND_COM_ITEM]
            (
                   [ITEM_ID]                                                 --품목ID
                  ,[ORG_ID]                                                  --ORG_ID
                  ,[ORG_CODE]                                                --ORG코드
                  ,[ORG_NAME]                                                --ORG명
                  ,[ITEM_CODE]                                               --품목코드
                  ,[ITEM_NAME]                                               --품목명
                  ,[ORG_ITEM_ID_KEY]                                         --조합키1(조직아이디+품목아이디)
                  ,[ORG_ITEM_CODE_KEY]                                       --조합키2(조직코드+품목코드)
                  ,[ORG_ID_ITEM_CODE_KEY]                                    --조합키3(조직아이디+품목코드)
                  ,[ORG_PRODUCT_LINE_CODE_KEY]                               --조합키4(조직코드+제품류코드)
                  ,[FRAME_CODE2]                                             --프레임코드2
                  ,[FRAME_NAME2]                                             --프레임명2
                  ,[FRAME_CODE1]                                             --프레임코드1
                  ,[FRAME_NAME1]                                             --프레임명1
                  ,[SERIES_CODE]                                             --시리즈코드
                  ,[SERIES_NAME]                                             --시리즈명
                  ,[PRODUCT_LINE_CODE]                                       --제품류코드
                  ,[PRODUCT_LINE_NAME]                                       --제품류명
                  ,[SPG_CODE]                                                --SPG코드
                  ,[SPG_NAME]                                                --SPG명
                  ,[BUSINESS_CODE]                                           --사업코드
                  ,[BUSINESS_NAME]                                           --사업명
                  ,[ITEM_UNIT_CODE]                                          --품목단위코드
                  ,[INVENTORY_TYPE_CODE]                                     --재고구분코드
                  ,[ITEM_STATUS_CODE]                                        --품목상태코드
                  ,[PURCHASE_TYPE_NAME]                                      --구매구분명
                  ,[ITEM_SUFFIX_CODE]                                        --품목SUFFIX코드
                  ,[ITEM_GRADE_CODE]                                         --품목등급코드
                  ,[CURRENCY_CODE]                                           --통화코드
                  ,[COMMODITY_CODE]                                          --CMDT코드
                  ,[VENDOR_SHIP_TO_LEAD_TIME]                                --구매처납품리드타임
                  ,[ITEM_COMMERCIALIZE_DATE]                                 --품목출시일자
                  ,[ITEM_END_DATE]                                           --품목종료일자
                  ,[ITEM_TYPE_CODE]                                          --품목유형코드
                  ,[BOOKING_UNIT_PRICE]                                      --예약단가
                  ,[INSPECTION_METHOD_ID]                                    --검사방법ID
                  ,[INVENTORY_PLAN_CODE]                                     --재고계획코드
                  ,[PLANNER_CODE]                                            --계획자코드
                  ,[MFG_PUR_TP_CODE]                                         --제조구매구분코드
                  ,[MINIMUM_ORDER_QTY]                                       --최소발주수량
                  ,[FIXED_ORDER_QTY]                                         --고정발주수량
                  ,[MAXIMUM_ORDER_QTY]                                       --최대발주수량
                  ,[PTF_APPLY_METHOD_CODE]                                   --PTF적용방법코드
                  ,[DTF_APPLY_METHOD_CODE]                                   --DTF적용방법코드
                  ,[PTF_APPLY_DAYS]                                          --PTF적용일수
                  ,[DTF_APPLY_DAYS]                                          --DTF적용일수
                  ,[MRP_PLAN_CODE]                                           --MRP계획코드
                  ,[RTF_APPLY_CODE]                                          --RTF적용코드
                  ,[RTF_APPLY_DAYS]                                          --RTF적용일수
                  ,[LEAD_TIME_LOT_SIZE]                                      --리드타임LOT크기
                  ,[ACCU_MFG_LT]                                             --누계제조리드타임
                  ,[ACCUMULATION_TOTAL_LEAD_TIME]                            --누계총리드타임
                  ,[FIXED_LEAD_TIME]                                         --고정리드타임
                  ,[VARIABLE_LEAD_TIME]                                      --변동리드타임
                  ,[SHIP_INSPECTION_LEAD_TIME]                               --납품검사리드타임
                  ,[ORDER_PREPARATION_LEAD_TIME]                             --주문준비리드타임
                  ,[LEAD_TIME]                                               --리드타임
                  ,[ISSUE_METHOD_CODE]                                       --출고방법코드
                  ,[WAREHOUSE_CODE]                                          --창고코드
                  ,[ORDER_CYCLE_CODE]                                        --발주주기코드
                  ,[ADD_LOT_QTY]                                             --추가LOT수량
                  ,[INVENTORY_IN_OUT_ENABLED_FLAG]                           --재고입출가능여부
                  ,[IN_OUT_ENABLED_FLAG]                                     --입출가능여부
                  ,[INVENTORY_ENABLED_FLAG]                                  --재고가능여부
                  ,[BOOKING_ENABLED_FLAG]                                    --예약가능여부
                  ,[BOM_COMPOSE_ENABLED_FLAG]                                --BOM구성가능여부
                  ,[BOM_COMPOSE_METHOD_CODE]                                 --BOM구성방법코드
                  ,[STD_LOT_SIZE]                                            --STD_LOT_SIZE
                  ,[PURCHASE_SHIP__ENABLED_FLAG]                             --구매납품가능여부
                  ,[PURCHASE_ENABLED_FLAG]                                   --구매가능여부
                  ,[PEGGING_FLAG]                                            --PEGGING여부
                  ,[ATO_FCST_CTRL_CODE]                                      --ATO예측제어코드
                  ,[MFG_ORD_TG_FLAG]                                         --제조주문대상여부
                  ,[ALLOCATION_SHIP_ENABLED_FLAG]                            --배정출하가능여부
                  ,[CUST_ORD_SHP_ENABLE_FLAG]                                --고객주문출하가능여부
                  ,[INT_ORD_ISS_ENABLE_FLAG]                                 --내부주문출고가능여부
                  ,[CUSTOMER_ORDER_ENABLED_FLAG]                             --고객주문가능여부
                  ,[INTERNAL_ORDER_ENABLED_FLAG]                             --내부주문가능여부
                  ,[ALLOCATION_ENABLED_FLAG]                                 --배정가능여부
                  ,[RETURN_ENABLED_FLAG]                                     --반품가능여부
                  ,[ATP_PARTS_FLAG]                                          --ATP부품여부
                  ,[ATP_FLAG]                                                --ATP여부
                  ,[ENG_ITEM_FLAG]                                           --ENG품목여부
                  ,[BF_CONV_PROD_LN_CODE]                                    --변환전제품류코드
                  ,[USAGE_FLAG]                                              --사용여부
                  ,[LIFE_TIME]                                               --유수명자재
                  ,[ETL_DT]                                                  --적재일시
            )
            SELECT A.INVENTORY_ITEM_ID                                                                              AS ITEM_ID
                  ,A.ORGANIZATION_ID                                                                                AS ORG_ID
                  ,D.ORGANIZATION_CODE                                                                              AS ORG_CODE
                  ,D.ORGANIZATION_NAME                                                                              AS ORG_NAME
                  ,ISNULL(A.SEGMENT1 ,'z{')                                                                         AS ITEM_CODE
                  ,ISNULL(A.DESCRIPTION, N'데이타 없음')                                                               AS ITEM_NAME
                  ,CONCAT(CAST(A.ORGANIZATION_ID AS INT), CAST(A.INVENTORY_ITEM_ID AS INT))                         AS ORG_ITEM_ID_KEY               --조합키1(조직아이디+품목아이디)
                  ,CONCAT(TRIM(D.ORGANIZATION_CODE),ISNULL(TRIM(A.SEGMENT1),'z{'))                                  AS ORG_ITEM_CODE_KEY             --조합키2(조직코드+품목코드)
                  ,CONCAT(CAST(A.ORGANIZATION_ID AS INT),ISNULL(TRIM(A.SEGMENT1),'z{'))                             AS ORG_ID_ITEM_CODE_KEY          --조합키3(조직아이디+품목코드)
                  ,CONCAT(TRIM(D.ORGANIZATION_CODE),ISNULL(LEFT(C.SEGMENT1,3), 'z{'))                               AS ORG_PRODUCT_LINE_CODE_KEY     --조합키4(조직코드+제품류코드)
                  ,ISNULL(E.FRAME2_CODE,'z{')                                                                       AS FRAME2_CODE
                  ,E.FRAME2_NAME                                                                                    AS FRAME2_NAME
                  ,ISNULL(E.FRAME1_CODE,'z{')                                                                       AS FRAME1_CODE
                  ,E.FRAME1_NAME                                                                                    AS FRAME1_NAME
                  ,ISNULL(E.SERIES_CODE,'z{')                                                                       AS SERIES_CODE
                  ,E.SERIES_NAME                                                                                    AS SERIES_NAME
                  ,ISNULL(LEFT(C.SEGMENT1,3), 'z{')                                                                 AS PRODUCT_LINE_CODE
                  ,ISNULL(I.PRODUCT_LINE_NAME, N'데이터 없음')                                                         AS PRODUCT_LINE_NAME
                  ,ISNULL(H.CONVERSION_SPG_CODE,'z{')                                                               AS SPG_CODE                      --MAP 테이블 연결 하는것으로 로직 변경함
                  ,ISNULL(H.CONVERSION_SPG_NAME, N'데이터 없음')                                                       AS SPG_NAME                      --MAP 테이블 연결 하는것으로 로직 변경함
                  ,ISNULL(H.CONVERSION_BUSINESS_CODE,'z{')                                                          AS BUSINESS_CODE                 --MAP 테이블 연결 하는것으로 로직 변경함
                  ,ISNULL(H.CONVERSION_BUSINESS_NAME, N'데이터 없음')                                                  AS BUSINESS_NAME                 --MAP 테이블 연결 하는것으로 로직 변경함
                  ,A.PRIMARY_UOM_CODE                                                                               AS ITEM_UNIT_CODE
                  ,ISNULL(C.SEGMENT2, 'z{')                                                                         AS INVENTORY_TYPE_CODE
                  ,A.INVENTORY_ITEM_STATUS_CODE                                                                     AS ITEM_STATUS_CODE              --송정호부장님 요청으로 변경 0209
                  ,ISNULL(F.SEGMENT1,'z{')                                                                          AS PURCHSE_TYPE_CODE             --구매구분코드
                  ,A.ATTRIBUTE1                                                                                     AS ITEM_SUFFIX_CODE
                  ,ISNULL(A.ATTRIBUTE14, ' ')                                                                       AS ITEM_GRADE_CODE
                  ,ISNULL(A.ATTRIBUTE5, 'z{')                                                                       AS CURRENCY_CODE
                  ,ISNULL(A.ATTRIBUTE18,'z{')                                                                       AS COMMODITY_CODE
                  ,A.POSTPROCESSING_LEAD_TIME                                                                       AS VENDOR_SHIP_LEAD_TIME_DATE
                  ,FORMAT(G.START_DATE_ACTIVE, 'yyyyMMdd')                                                          AS ITEM_COMMERCIALIZE_DATE       --품목출시일자 별도 쿼리 명시함 참고할 것
                  ,FORMAT(G.END_DATE_ACTIVE  , 'yyyyMMdd')                                                          AS ITEM_END_DATE                 --품목종료일자  별도 쿼리 명시함 참고할 것
                  ,A.ITEM_TYPE                                                                                      AS ITEM_TYPE_CODE                --품목구분코드
                  ,A.LIST_PRICE_PER_UNIT                                                                            AS BOOKING_UNIT_PRICE            --예약단가
                  ,A.RECEIVING_ROUTING_ID                                                                           AS INSPECTION_METHOD_ID          --검사방법ID
                  ,A.INVENTORY_PLANNING_CODE                                                                        AS INVENTORY_PLAN_CODE           --재고계획코드
                  ,A.PLANNER_CODE                                                                                   AS PLANNER_CODE                  --계획자코드
                  ,A.PLANNING_MAKE_BUY_CODE                                                                         AS MFG_PUR_TP_CODE               --제조구매구분코드
                  ,A.MINIMUM_ORDER_QUANTITY                                                                         AS MINIMUM_ORDER_QTY             --최소발주수량
                  ,A.FIXED_ORDER_QUANTITY                                                                           AS FIXED_ORDER_QTY               --고정발주수량
                  ,A.MAXIMUM_ORDER_QUANTITY                                                                         AS MAXIMUM_ORDER_QTY             --최대발주수량
                  ,A.PLANNING_TIME_FENCE_CODE                                                                       AS PTF_APPLY_METHOD_CODE         --PTF적용방법
                  ,A.DEMAND_TIME_FENCE_CODE                                                                         AS DTF_APPLY_METHOD_CODE         --DTF적용방법
                  ,A.PLANNING_TIME_FENCE_DAYS                                                                       AS PTF_APPLY_DAYS                --PTF적용일수
                  ,A.DEMAND_TIME_FENCE_DAYS                                                                         AS DTF_APPLY_DAYS                --DTF적용일수
                  ,A.MRP_PLANNING_CODE                                                                              AS MRP_PLAN_CODE                 --MRP계획코드
                  ,A.RELEASE_TIME_FENCE_CODE                                                                        AS RTF_APPLY_CODE                --RTF적용방법
                  ,A.RELEASE_TIME_FENCE_DAYS                                                                        AS RTF_APPLY_DAYS                --RTF적용일수
                  ,A.LEAD_TIME_LOT_SIZE                                                                             AS LEAD_TIME_LOT_SIZE            --리드타임LOT크기
                  ,A.CUM_MANUFACTURING_LEAD_TIME                                                                    AS ACCU_MFG_LT                   --누계제조리드타임
                  ,A.CUMULATIVE_TOTAL_LEAD_TIME                                                                     AS ACCUMULATION_TOTAL_LEAD_TIME  --누계총리드타임
                  ,A.FIXED_LEAD_TIME                                                                                AS FIXED_LEAD_TIME               --고정리드타임
                  ,A.VARIABLE_LEAD_TIME                                                                             AS VARIABLE_LEAD_TIME            --변동리드타임
                  ,A.POSTPROCESSING_LEAD_TIME                                                                       AS SHIP_INSPECTION_LEAD_TIME     --납품검사리드타임
                  ,A.PREPROCESSING_LEAD_TIME                                                                        AS ORDER_PREPARATION_LEAD_TIME   --Order준비리드타임
                  ,A.FULL_LEAD_TIME                                                                                 AS LEAD_TIME                     --리드타임
                  ,A.WIP_SUPPLY_TYPE                                                                                AS ISSUE_METHOD_CODE             --출고방법
                  ,ISNULL(A.WIP_SUPPLY_SUBINVENTORY,'z{')                                                           AS WAREHOUSE_CODE                --창고코드
                  ,A.FIXED_DAYS_SUPPLY                                                                              AS ORDER_CYCLE_CODE              --발주주기
                  ,A.FIXED_LOT_MULTIPLIER                                                                           AS ADD_LOT_QTY                   --추가Lot수량
                  ,A.INVENTORY_ITEM_FLAG                                                                            AS INVENTORY_IN_OUT_ENABLED_FLAG --재고입출가능여부
                  ,A.MTL_TRANSACTIONS_ENABLED_FLAG                                                                  AS IN_OUT_ENABLED_FLAG           --입출가능여부
                  ,A.STOCK_ENABLED_FLAG                                                                             AS INVENTORY_ENABLED_FLAG        --재고가능여부
                  ,A.RESERVABLE_TYPE                                                                                AS BOOKING_ENABLED_FLAG          --예약가능여부
                  ,A.BOM_ENABLED_FLAG                                                                               AS BOM_COMPOSE_ENABLED_FLAG      --BOM구성가능여부
                  ,A.BOM_ITEM_TYPE                                                                                  AS BOM_COMPOSE_METHOD_CODE       --BOM구성방법
                  ,A.STD_LOT_SIZE                                                                                   AS STD_LOT_SIZE                  --STD_LOT_SIZE
                  ,A.PURCHASING_ITEM_FLAG                                                                           AS PURCHASE_SHIP__ENABLED_FLAG   --구매납품가능여부
                  ,A.PURCHASING_ENABLED_FLAG                                                                        AS PURCHASE_ENABLED_FLAG         --구매가능여부
                  ,A.END_ASSEMBLY_PEGGING_FLAG                                                                      AS PEGGING_FLAG                  --PEGGING여부
                  ,A.ATO_FORECAST_CONTROL                                                                           AS ATO_FCST_CTRL_CODE            --ATO예측제어코드
                  ,A.BUILD_IN_WIP_FLAG                                                                              AS MFG_ORD_TG_FLAG               --제조주문대상여부
                  ,A.SHIPPABLE_ITEM_FLAG                                                                            AS ALLOCATION_SHIP_ENABLED_FLAG  --배정출하가능여부
                  ,A.CUSTOMER_ORDER_FLAG                                                                            AS CUST_ORD_SHP_ENABLE_FLAG      --고객주문출하가능여부
                  ,A.INTERNAL_ORDER_FLAG                                                                            AS INT_ORD_ISS_ENABLE_FLAG       --내부주문출고가능여부
                  ,A.CUSTOMER_ORDER_ENABLED_FLAG                                                                    AS CUSTOMER_ORDER_ENABLED_FLAG   --고객주문가능여부
                  ,A.INTERNAL_ORDER_ENABLED_FLAG                                                                    AS INTERNAL_ORDER_ENABLED_FLAG   --내부주문가능여부
                  ,A.SO_TRANSACTIONS_FLAG                                                                           AS ALLOCATION_ENABLED_FLAG       --배정가능여부
                  ,A.RETURNABLE_FLAG                                                                                AS RETURN_ENABLED_FLAG           --반품가능여부
                  ,A.ATP_COMPONENTS_FLAG                                                                            AS ATP_PARTS_FLAG                --ATP부품여부
                  ,A.ATP_FLAG                                                                                       AS ATP_FLAG                      --ATP체크여부
                  ,A.ENG_ITEM_FLAG                                                                                  AS ENG_ITEM_FLAG                 --ENG품목여부
                  ,ISNULL(LEFT(C.SEGMENT1,3),'z{')                                                                  AS BF_CONV_PROD_LN_CODE          --변환전제품류코드(원제품류코드)
                  ,A.ENABLED_FLAG                                                                                   AS USAGE_FLAG
                  ,CAST(ATTRIBUTE23 AS DECIMAL(21,0))                                                               AS LIFE_TIME                     --유수명자재
                  ,DATEADD(HOUR, 9 ,GETDATE())                                                                      AS ETL_DT
              FROM ERPSYS.ERP_MTL_SYSTEM_ITEMS_B    A
              JOIN ERPSYS.ERP_MTL_ITEM_CATEGORIES   B
                ON A.ORGANIZATION_ID = B.ORGANIZATION_ID
               AND A.INVENTORY_ITEM_ID = B.INVENTORY_ITEM_ID
              JOIN ERPSYS.ERP_MTL_CATEGORIES_V  C
                ON B.CATEGORY_ID = C.CATEGORY_ID
              --JOIN ERPSYS.ERP_ORG_ORGA_DEFI_V   D
			  JOIN [ERPSYS].[ERP_EORG_ORGA_DEFI_V] D
                ON A.ORGANIZATION_ID = D.ORGANIZATION_ID
              LEFT OUTER
              JOIN (
                    SELECT A.ORGANIZATION_ID
                          ,A.INVENTORY_ITEM_ID
                          ,A.SERIES_CODE
                          ,D.SERIES_NAME
                          ,A.FRAME1_CODE
                          ,C.FRAME1_NAME
                          ,A.FRAME2_CODE
                          ,B.FRAME2_NAME
                      FROM (
                            SELECT A.ORGANIZATION_ID
                                  ,A.INVENTORY_ITEM_ID
                                  ,B.SEGMENT2                                                     AS SERIES_CODE
                                  ,B.SEGMENT3                                                     AS FRAME1_CODE
                                  ,B.SEGMENT4                                                     AS FRAME2_CODE
                              FROM ERPSYS.ERP_MTL_ITEM_CATEGORIES   A
                              JOIN ERPSYS.ERP_MTL_CATEGORIES_V  B
                                ON A.CATEGORY_ID = B.CATEGORY_ID
                             WHERE A.CATEGORY_SET_ID = 1100000043
                           ) A
                      LEFT OUTER
                      JOIN (
                            SELECT B.DESCRIPTION                                                  AS FRAME2_NAME
                                  ,C.FLEX_VALUE
                              FROM ERPSYS.ERP_FND_FLEX_VALUE_SETS   A
                              JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V       C
                                ON A.FLEX_VALUE_SET_ID = C.FLEX_VALUE_SET_ID
                              JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V    B
                                ON B.FLEX_VALUE_ID = C.FLEX_VALUE_ID
                             WHERE A.FLEX_VALUE_SET_NAME = 'LSIS_CATEGORY_FRAME2_VS'

                           ) B
                        ON A.FRAME2_CODE = B.FLEX_VALUE
                      LEFT OUTER
                      JOIN (
                            SELECT B.DESCRIPTION                                                  AS FRAME1_NAME
                                  ,C.FLEX_VALUE
                              FROM ERPSYS.ERP_FND_FLEX_VALUE_SETS  A
                              JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V      C
                                ON A.FLEX_VALUE_SET_ID   =  C.FLEX_VALUE_SET_ID
                              JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V   B
                                ON B.FLEX_VALUE_ID =  C.FLEX_VALUE_ID
                             WHERE A.FLEX_VALUE_SET_NAME = 'LSIS_CATEGORY_FRAME1_VS'

                           ) C
                        ON A.FRAME1_CODE = C.FLEX_VALUE
                      LEFT OUTER
                      JOIN (
                            SELECT B.DESCRIPTION                                                  AS SERIES_NAME
                                  ,B.FLEX_VALUE
                              FROM ERPSYS.ERP_FND_FLEX_VALUE_SETS A
                              JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V  B
                                ON A.FLEX_VALUE_SET_ID   = B.FLEX_VALUE_SET_ID
                             WHERE A.FLEX_VALUE_SET_NAME = 'LSIS_CATEGORY_SERIES_VS'

                           ) D
                        ON A.SERIES_CODE = D.FLEX_VALUE
                   ) E
                ON A.ORGANIZATION_ID = E.ORGANIZATION_ID
               AND A.INVENTORY_ITEM_ID = E.INVENTORY_ITEM_ID
              LEFT OUTER
              JOIN (
                    SELECT MIC.ORGANIZATION_ID
                          ,MIC.INVENTORY_ITEM_ID
                          ,MCB.SEGMENT1
                      FROM ERPSYS.ERP_MTL_ITEM_CATEGORIES   MIC
                      JOIN ERPSYS.ERP_MTL_CATEGORIES_V      MCB
                        ON MIC.CATEGORY_ID = MCB.CATEGORY_ID
                     WHERE MIC.CATEGORY_SET_ID = 1100000042
                   ) F
                ON A.ORGANIZATION_ID = F.ORGANIZATION_ID
               AND A.INVENTORY_ITEM_ID = F.INVENTORY_ITEM_ID
              LEFT OUTER
              JOIN (
                    SELECT ESIC.INVENTORY_ITEM_ID
                          ,ESIC.INV_ORG_ID
                          ,MSIB.SEGMENT1 ITEM_CODE
                          ,ESIC.ENABLED_FLAG
                          ,ESIC.START_DATE_ACTIVE
                          ,ESIC.END_DATE_ACTIVE
                          ,ESIC.CREATION_DATE
                          ,ESIC.LAST_UPDATED_BY
                          ,ESIC.LAST_UPDATE_DATE
                      FROM ERPSYS.ERP_ESVC_SYST_ITEM_CLAI   ESIC
                      JOIN ERPSYS.ERP_MTL_SYSTEM_ITEMS_B    MSIB
                        ON ESIC.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
                       AND ESIC.INV_ORG_ID        = MSIB.ORGANIZATION_ID
                   ) G
                ON A.ORGANIZATION_ID = G.INV_ORG_ID
               AND A.INVENTORY_ITEM_ID = G.INVENTORY_ITEM_ID
              LEFT OUTER
              JOIN T_DIM_FND_COM_PROD_LN_SPG_BIZ_MAP H
                ON C.SEGMENT1 = H.PRODUCT_LINE_CODE
              LEFT OUTER
              JOIN (
                    SELECT B.DESCRIPTION AS PRODUCT_LINE_NAME
                          ,C.FLEX_VALUE
                      FROM ERPSYS.ERP_FND_FLEX_VALUE_SETS   A
                      JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V       C
                        ON A.FLEX_VALUE_SET_ID = C.FLEX_VALUE_SET_ID
                      JOIN ERPSYS.ERP_FND_FLEX_VALU_VL_V    B
                        ON B.FLEX_VALUE_ID = C.FLEX_VALUE_ID
                      JOIN ERPSYS.ERP_ORG_ORGA_DEFI_V D                  -- 20210331
                        ON C.PARENT_FLEX_VALUE_LOW = D.ORGANIZATION_CODE -- 20210331
                     WHERE 1=1
            --           AND A.FLEX_VALUE_SET_NAME = 'LSIS_CATEGORY_SPG_VS' -- 20210331
                       AND A.FLEX_VALUE_SET_NAME = 'LSIS_ORG_SPG'  -- 20210331
                       AND C.ENABLED_FLAG  = 'Y' -- 20210331
                       AND D.SET_OF_BOOKS_ID = 2022 -- 20210331
                       AND ISNULL(C.END_DATE_ACTIVE,DATEADD(HOUR, 9 ,GETDATE())) >= CAST(FORMAT(DATEADD(HOUR, 9 ,GETDATE()),'yyyyMMdd') AS DATETIME) -- 20210331
                       AND D.ORGANIZATION_CODE LIKE (CASE WHEN SUBSTRING(C.FLEX_VALUE,1,1) = '9' THEN D.ORGANIZATION_CODE
                                                          ELSE 'M%'
                                                     END) -- 20210331
                   ) I
                ON C.SEGMENT1 = I.FLEX_VALUE
             WHERE B.CATEGORY_SET_ID     = 1
               ---2011.02.18 추가(문지연)--
               AND D.ORGANIZATION_CODE <> 'M00'
            ;
			
			-- Digital IPP 가상 품목 강제 입력
			INSERT INTO [dbo].[T_DIM_FND_COM_ITEM]
                 VALUES
                 ( -99
                 ,'541'
                 ,'M10'
                 ,N'M10-청주2(SE_양산) Org'
                 ,'Digital IPP'
                 ,'Digital IPP'
                 ,'541-99'
                 ,'M10Digital IPP'
                 ,'541Digital IPP'
                 ,'M10891'
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,NULL
                 ,'891'
                 ,'Digital IPP'
                 ,'Z04'
                 ,'Digital IPP'
                 ,'Z00'
                 ,N'기타'
                 ,'ea'
                 ,'Finished Goods'
                 ,'Active'
                 ,'Make'
                 ,NULL
                 ,NULL
                 ,'KRW'
                 ,'z{'
                 ,'0'
                 ,NULL
                 ,NULL
                 ,'FG'
                 ,'0'
                 ,'1'
                 ,'6'
                 ,NULL
                 ,'1'
                 ,NULL
                 ,'1'
                 ,NULL
                 ,'4'
                 ,'4'
                 ,'0'
                 ,'0'
                 ,'3'
                 ,NULL
                 ,NULL
                 ,'1'
                 ,'1'
                 ,'23'
                 ,'0'
                 ,'0'
                 ,'0'
                 ,NULL
                 ,'0'
                 ,'1'
                 ,'z{'
                 ,NULL
                 ,NULL
                 ,'Y'
                 ,'N'
                 ,'N'
                 ,'1'
                 ,'N'
                 ,'4'
                 ,'1'
                 ,'Y'
                 ,'N'
                 ,'I'
                 ,'2'
                 ,'N'
                 ,'Y'
                 ,'Y'
                 ,'Y'
                 ,'N'
                 ,'N'
                 ,'Y'
                 ,'Y'
                 ,'N'
                 ,'N'
                 ,'N'
                 ,'891'
                 ,'Y'
                 ,NULL
                 ,@v_st_date
                 )
                 ;
			/*	 
            UPDATE [dbo].[T_DIM_FND_COM_ITEM]
               SET FRAME_CODE2         = ITEM_CODE
                  ,FRAME_NAME2         = ITEM_NAME
                  ,FRAME_CODE1         = ITEM_CODE
                  ,FRAME_NAME1         = ITEM_NAME
                  ,SERIES_CODE         = ITEM_CODE
                  ,SERIES_NAME         = ITEM_NAME
                  ,PRODUCT_LINE_CODE   = ITEM_CODE
                  ,PRODUCT_LINE_NAME   = ITEM_NAME
                  ,SPG_CODE            = ITEM_CODE
                  ,SPG_NAME            = ITEM_NAME
                  ,BUSINESS_CODE       = ITEM_CODE
                  ,BUSINESS_NAME       = ITEM_NAME
                  ,ITEM_UNIT_CODE      = ITEM_CODE
                  ,INVENTORY_TYPE_CODE = ITEM_NAME
                  ,ITEM_STATUS_CODE    = ITEM_NAME
                  ,ITEM_GRADE_CODE     = ITEM_NAME
                  ,CURRENCY_CODE       = ITEM_CODE
                  ,WAREHOUSE_CODE      = ITEM_CODE
                  ,ITEM_TYPE_CODE      = ITEM_CODE
             WHERE ITEM_ID < 0
               AND (FRAME_CODE2 IS NULL
                OR  FRAME_NAME2 IS NULL
                OR  FRAME_CODE1 IS NULL
                OR  FRAME_NAME1 IS NULL
                OR  SERIES_CODE IS NULL
                OR  SERIES_NAME IS NULL
                OR  PRODUCT_LINE_CODE IS NULL
                OR  PRODUCT_LINE_NAME IS NULL
                OR  SPG_CODE IS NULL
                OR  SPG_NAME IS NULL
                OR  BUSINESS_CODE IS NULL
                OR  BUSINESS_NAME IS NULL
                OR  ITEM_UNIT_CODE IS NULL
                OR  INVENTORY_TYPE_CODE IS NULL
                OR  ITEM_STATUS_CODE IS NULL
                OR  ITEM_GRADE_CODE IS NULL
                OR  CURRENCY_CODE IS NULL
                OR  WAREHOUSE_CODE IS NULL
                OR  ITEM_TYPE_CODE IS NULL
              )
            ;
			*/
            SELECT @v_load_cnt = COUNT(1)
              FROM [dbo].[T_DIM_FND_COM_ITEM]
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

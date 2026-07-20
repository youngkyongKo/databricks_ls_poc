-- Databricks notebook source
-- MAGIC %md
-- MAGIC # Usage
-- MAGIC ```text
-- MAGIC %py
-- MAGIC SP_ETL_DATA_INSERT_LOG('v_run_pgm', 'v_tgt_job_area', 'v_parm_from', 'v_parm_to', '2025-07-24 10:00', -1, 'v_err_mesg', 'v_pgm_status')
-- MAGIC ```

-- COMMAND ----------

-- MAGIC %py
-- MAGIC # ------------------------------------------------------------------
-- MAGIC # Catalog parameterization
-- MAGIC # 이 노트북(00_imports)을 %run 으로 호출하는 SP 노트북 쪽에서
-- MAGIC # %run "./00_imports" $catalog_name="syncopy" 형태로 override 가능
-- MAGIC # 지정하지 않으면 기본값 'syncopy' 사용
-- MAGIC # ------------------------------------------------------------------
-- MAGIC dbutils.widgets.text("catalog_name", "syncopy")
-- MAGIC CATALOG_NAME = dbutils.widgets.get("catalog_name")
-- MAGIC
-- MAGIC if not CATALOG_NAME:
-- MAGIC     raise ValueError("catalog_name widget이 비어있습니다. 로그 테이블 catalog를 지정하세요.")
-- MAGIC
-- MAGIC print(f"[00_imports] Log table catalog set to: {CATALOG_NAME}")

-- COMMAND ----------

DECLARE OR REPLACE VARIABLE v_base_date varchar(8);
DECLARE OR REPLACE VARIABLE v_sub_seq   int;
DECLARE OR REPLACE VARIABLE v_end_date  timestamp;
DECLARE OR REPLACE VARIABLE v_run_time  decimal(18,3);

DECLARE OR REPLACE VARIABLE sqlstate STRING;
DECLARE OR REPLACE VARIABLE msg STRING;

-- COMMAND ----------

-- MAGIC %py
-- MAGIC from pyspark.errors import PySparkException
-- MAGIC from pyspark.sql import DataFrame

-- COMMAND ----------

-- MAGIC %py
-- MAGIC def SP_ETL_DATA_INSERT_LOG(run_pgm: str,
-- MAGIC                            tgt_job_area: str,
-- MAGIC                            parm_from: str,
-- MAGIC                            parm_to: str,
-- MAGIC                            st_date: str,
-- MAGIC                            load_cnt: int,
-- MAGIC                            err_mesg: str,
-- MAGIC                            pgm_status: str):
-- MAGIC     """
-- MAGIC     ETL 실행 로그를 {CATALOG_NAME}.dbo.ETL_DATA_INSERT_LOG2 에 기록.
-- MAGIC     - catalog는 상단 widget(CATALOG_NAME)으로 파라미터화됨 (하드코딩 제거)
-- MAGIC     - 문자열 값은 manual escape 대신 named parameter binding(:param) 사용하여
-- MAGIC       injection 위험 및 escape 누락 버그를 원천 차단
-- MAGIC     """
-- MAGIC     try:
-- MAGIC         log_table = f"{CATALOG_NAME}.dbo.ETL_DATA_INSERT_LOG2"
-- MAGIC
-- MAGIC         spark.sql(
-- MAGIC             "SET VARIABLE v_base_date = (DATE_FORMAT(DATEADD(HOUR, 9, GETDATE() - interval 1 day), 'yyyyMMdd'))"
-- MAGIC         )
-- MAGIC
-- MAGIC         spark.sql(
-- MAGIC             f"""
-- MAGIC             SET VARIABLE v_sub_seq = (
-- MAGIC                 SELECT IFNULL(MAX(SUB_SEQ), 0) + 1
-- MAGIC                 FROM {log_table}
-- MAGIC                 WHERE BASE_DATE = v_base_date
-- MAGIC                   AND RUN_PGM   = :run_pgm
-- MAGIC             )
-- MAGIC             """,
-- MAGIC             args={"run_pgm": run_pgm}
-- MAGIC         )
-- MAGIC
-- MAGIC         spark.sql("SET VARIABLE v_end_date = DATEADD(HOUR, 9, GETDATE())")
-- MAGIC
-- MAGIC         spark.sql(
-- MAGIC             "SET VARIABLE v_run_time = CAST(DATEDIFF(SECOND, :st_date, v_end_date) AS DECIMAL)",
-- MAGIC             args={"st_date": st_date}
-- MAGIC         )
-- MAGIC
-- MAGIC         spark.sql(
-- MAGIC             f"""
-- MAGIC             INSERT INTO {log_table}
-- MAGIC                 (
-- MAGIC                     BASE_DATE
-- MAGIC                     ,TGT_JOB_AREA
-- MAGIC                     ,RUN_PGM
-- MAGIC                     ,SUB_SEQ
-- MAGIC                     ,PARM_FROM
-- MAGIC                     ,PARM_TO
-- MAGIC                     ,START_DATE
-- MAGIC                     ,END_DATE
-- MAGIC                     ,RUN_TIME
-- MAGIC                     ,LOAD_CNT
-- MAGIC                     ,MESSAGE
-- MAGIC                     ,PGM_STATUS
-- MAGIC                 )
-- MAGIC             VALUES
-- MAGIC                 (
-- MAGIC                     v_base_date::string
-- MAGIC                     ,:tgt_job_area
-- MAGIC                     ,:run_pgm
-- MAGIC                     ,v_sub_seq
-- MAGIC                     ,:parm_from
-- MAGIC                     ,:parm_to
-- MAGIC                     ,:st_date
-- MAGIC                     ,v_end_date
-- MAGIC                     ,v_run_time
-- MAGIC                     ,:load_cnt
-- MAGIC                     ,:err_mesg
-- MAGIC                     ,:pgm_status
-- MAGIC                 )
-- MAGIC             """,
-- MAGIC             args={
-- MAGIC                 "tgt_job_area": tgt_job_area,
-- MAGIC                 "run_pgm": run_pgm,
-- MAGIC                 "parm_from": parm_from,
-- MAGIC                 "parm_to": parm_to,
-- MAGIC                 "st_date": st_date,
-- MAGIC                 "load_cnt": load_cnt,
-- MAGIC                 "err_mesg": err_mesg,
-- MAGIC                 "pgm_status": pgm_status,
-- MAGIC             }
-- MAGIC         )
-- MAGIC     except PySparkException as ex:
-- MAGIC         # 로그 적재 함수 자체가 실패하면 최소한 콘솔에는 남긴다 (PII는 여기서도 출력하지 않도록 주의)
-- MAGIC         print("Error Condition   : " + ex.getErrorClass())
-- MAGIC         print("Message arguments : " + str(ex.getMessageParameters()))
-- MAGIC         print("SQLSTATE          : " + ex.getSqlState())
-- MAGIC         print(ex)

-- COMMAND ----------

-- MAGIC %py
-- MAGIC def sql(sql: str) -> (DataFrame, str, str):
-- MAGIC     df: DataFrame = None
-- MAGIC     sqlstate: str = ''
-- MAGIC     msg: str = ''
-- MAGIC     try:
-- MAGIC         df = spark.sql(sql)
-- MAGIC         # display(df)
-- MAGIC     except PySparkException as ex:
-- MAGIC         print("Error Condition   : " + ex.getErrorClass())
-- MAGIC         print("Message arguments : " + str(ex.getMessageParameters()))
-- MAGIC         print("SQLSTATE          : " + ex.getSqlState())
-- MAGIC         print(ex)
-- MAGIC         sqlstate = ex.getSqlState()
-- MAGIC         msg = str(ex)
-- MAGIC         r = spark.sql(f'select v_run_pgm, v_tgt_job_area, v_parm_from, v_parm_to, v_st_date, v_load_cnt').collect()[0]
-- MAGIC         SP_ETL_DATA_INSERT_LOG(r['v_run_pgm'], r['v_tgt_job_area'], r['v_parm_from'], r['v_parm_to'], r['v_st_date'], r['v_load_cnt'], msg, 'E')
-- MAGIC     return df, sqlstate, msg

-- COMMAND ----------

-- MAGIC %py
-- MAGIC def success():
-- MAGIC     r = spark.sql('select v_work_result').collect()[0]
-- MAGIC     v_work_result = r['v_work_result']
-- MAGIC
-- MAGIC     if v_work_result == 0:
-- MAGIC         r = spark.sql(f'select v_run_pgm, v_tgt_job_area, v_parm_from, v_parm_to, v_st_date, v_load_cnt, v_err_mesg, v_pgm_status').collect()[0]
-- MAGIC         SP_ETL_DATA_INSERT_LOG(r['v_run_pgm'], r['v_tgt_job_area'],
-- MAGIC                             r['v_parm_from'], r['v_parm_to'], r['v_st_date'],
-- MAGIC                             r['v_load_cnt'], r['v_err_mesg'], r['v_pgm_status'])

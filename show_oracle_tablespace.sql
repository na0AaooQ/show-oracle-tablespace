set echo on
set colsep |
set pages 1000
set lines 1000

column TEMP_SIZE(MB)    format a15
column TEMP_HWM(MB)     format a15
column TEMP_HWM(%)      format a15
column TEMP_USED(MB)    format a15
column TEMP_USING(%)    format a15

----- TEMP TABLESPACE USED
SELECT
       d.tablespace_name,
       round(現サイズ) "SIZE(MB)",
       round(最大使用量) "USED(MB)",
       round(((最大使用量/現サイズ))*100) "USE(%)",
       round(現サイズ-最大使用量) "AVAIL(MB)"
FROM
       (SELECT tablespace_name, SUM(bytes)/(1024*1024) "現サイズ" FROM dba_temp_files GROUP BY tablespace_name) d,
       (SELECT tablespace_name, SUM(bytes_used)/(1024*1024) "最大使用量" FROM v$temp_extent_pool GROUP BY tablespace_name) f,
       dba_tablespaces t
WHERE
       (d.tablespace_name = f.tablespace_name) AND (d.tablespace_name = t.tablespace_name )
ORDER BY
       d.tablespace_name
;

----- TEMP TABLESPACE HWM
SELECT
       d.tablespace_name,
       TO_CHAR(NVL(a.bytes / 1024 / 1024, 0),'99,999,990.900') "TEMP_SIZE(MB)",
       TO_CHAR(NVL(t.hwm, 0)/1024/1024,'99999999.999')  "TEMP_HWM(MB)",
       TO_CHAR(NVL(t.hwm / a.bytes * 100, 0), '990.00') "TEMP_HWM(%)" ,
       TO_CHAR(NVL(t.bytes/1024/1024, 0),'99999999.999') "TEMP_USED(MB)",
       TO_CHAR(NVL(t.bytes / a.bytes * 100, 0), '990.00') "TEMP_USING(%)"
FROM
       sys.dba_tablespaces d,
       (select tablespace_name, sum(bytes) bytes from dba_temp_files group by tablespace_name) a,
       (select tablespace_name, sum(bytes_cached) hwm, sum(bytes_used) bytes from v$temp_extent_pool group by tablespace_name) t
WHERE d.tablespace_name = a.tablespace_name(+)
       AND d.tablespace_name = t.tablespace_name(+)
       AND d.extent_management like 'LOCAL'
       AND d.contents like 'TEMPORARY'
;

----- DISK SORT INCIDENCE
col "SORT_INCIDENCE(%)" format 990.99
SELECT
        tablespace_name, ( used_blocks / total_blocks ) * 100 "SORT_INCIDENCE(%)"
FROM
        v$sort_segment
WHERE
        tablespace_name = 'TEMP' OR tablespace_name = 'TEMP_EXAMPLE1' OR tablespace_name = 'TEMP_EXAMPLE2'
ORDER BY
        tablespace_name
;

----- DISK SORT COUNT
SELECT
        name, value "SORT_FREQUENCY"
FROM
        v$sysstat
WHERE
        name like '%sort%'
ORDER BY
        name
;

----- TABLESPACE USED
SELECT
        d.tablespace_name,
        現サイズ "SIZE(MB)",
        round(現サイズ-空き容量) "USED(MB)",
        round((1 - (空き容量/現サイズ))*100) "USE(%)",
        空き容量 "AVAIL(MB)"
FROM
        (SELECT tablespace_name, round(SUM(bytes)/(1024*1024)) "現サイズ" FROM dba_data_files GROUP BY tablespace_name) d,
        (SELECT tablespace_name, round(SUM(bytes)/(1024*1024)) "空き容量" FROM dba_free_space GROUP BY tablespace_name) f
WHERE
        d.tablespace_name = f.tablespace_name
ORDER BY
        d.tablespace_name
;

exit;


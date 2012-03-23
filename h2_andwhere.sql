/* $Header: h2_andwhere.sql 1.001 2011/06/24 12:10:10 h2$ 
-- Copyright (c) 2011 Hanming Tu All Rights Reserved.

PURPOSE:
  This function generate SQL WHERE or AND codes 

TYPE: Function
  
PROGRAMS OR OBJECTS REQUIRED:  None

NOTES
  1. Make sure the used functions are created. 

TESTS:
  select h2_andwhere('A')      from dual;
  select h2_andwhere('a%')     from dual;
  select h2_andwhere('A,B,C')  from dual;
  select h2_andwhere('a%','object_name','where') from dual;
  select h2_andwhere('a%','obj_name','and') from dual;
  select h2_andwhere('a%','obj_name','and','\') from dual;
  select h2_andwhere('a%','obj_name','andnot') from dual;
  select h2_andwhere('a,b,c','obj_name','and') from dual;

HISTORY:   MM/DD/YYYY (developer) 
  06/24/2011 (htu) - initial creation based on cc_andwhere_fn
  07/05/2011 (htu) - added p_als

*/

CREATE OR REPLACE FUNCTION h2_andwhere (
    p_str  	VARCHAR2 			-- string with wildcard
  , p_obj	VARCHAR2  DEFAULT 'object_name'	-- object name
  , p_typ  	VARCHAR2  DEFAULT 'WHERE'	-- type: where|and
  , p_esc	VARCHAR2  DEFAULT null		-- escape character
  , p_als	VARCHAR2  DEFAULT null		-- table alias
) RETURN VARCHAR2
IS
  v_prg      	VARCHAR2(100) 	:= 'h2_andwhere';
  v_typ		VARCHAR2(1000)	:= UPPER(NVL(p_typ, 'WHERE')); 
  v_val		VARCHAR2(32000)	;
  v_whr		VARCHAR2(32000)	;
  v_obj		VARCHAR2(100)	;
  v_cr		CHAR(1)		:= CHR(10);
BEGIN
  IF p_str IS NULL OR p_obj IS NULL THEN
    RETURN null;
  END IF;
  IF p_als IS NULL THEN 
    v_obj := ' UPPER("'||UPPER(p_obj)||'") '; 
  ELSE
    v_obj := ' UPPER('||p_als||'."'||UPPER(p_obj)||'") '; 
  END IF; 
  -- remove space and replace "," with "','"
  v_val := UPPER(REPLACE(REPLACE(p_str, ' ',''),',',''','''));
  IF v_typ = 'AND' THEN
    v_whr := '   '||v_typ||v_obj; 
  ELSIF v_typ = 'ANDNOT' THEN
    IF INSTR(p_str,',') = 0 AND INSTR(p_str,'%') = 0 THEN
      v_whr := '   AND '||v_obj;   
    ELSE 
      v_whr := '   AND '||v_obj||'NOT ';   
    END IF;
  ELSE
    v_whr := ' '  ||v_typ||v_obj; 
  END IF;
  IF INSTR(p_str,',') > 0 THEN
    v_whr := v_whr||' IN ('''||v_val||''')';
  ELSIF INSTR(p_str,'%') > 0 THEN
    v_whr := v_whr||' LIKE '''||v_val||''' ';
  ELSE 
    IF v_typ IN ('ANDNOT') THEN
      v_whr := v_whr||' <>  UPPER('''||v_val||''') ';
    ELSE 
      v_whr := v_whr||' =  UPPER('''||v_val||''') ';
    END IF;
  END IF;
  IF p_esc IS NOT NULL AND INSTR(p_str,'%') > 0 THEN
    v_whr := v_whr||' ESCAPE '''||p_esc||''' '||v_cr; 
  ELSE
    v_whr := v_whr||v_cr; 
  END IF; 
  RETURN v_whr;
END;
/
show err

/*
@src/h2_andwhere.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/src -a wrap h2_andwhere
@src/wrapped/h2_andwhere.plb

*/

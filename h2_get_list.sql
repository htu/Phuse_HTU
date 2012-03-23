/* $Header: h2_get_list.sql 1.001 2011/06/24 12:10:10 h2$ 
-- Copyright (c) 2011 Hanming Tu All Rights Reserved.

PURPOSE:
  This function convert a list into array.

TYPE: Function
  
PROGRAMS OR OBJECTS REQUIRED:  
  h2_vctab_tp

NOTES
  1. Make sure the used functions are created. 

TESTS:
  declare
    a  h2_vctab_tp;
  begin
    a := h2_getlist2(',a,b,c,,g,');
    dbms_output.put_line(a.last);
     FOR i IN a.FIRST..a.LAST LOOP
         dbms_output.put_line(to_char(i)||':'||a(i));
     END LOOP;
  end;
  /
  
HISTORY:   MM/DD/YYYY (developer) 
  07/05/2011 (htu) - initial creation based on cc_getlist2_fn

*/

CREATE OR REPLACE FUNCTION h2_get_list (
    p_str 	IN  VARCHAR2            	-- In string
  , p_sep 	IN  VARCHAR2 DEFAULT ','	-- separator
) RETURN h2_vctab_tp IS
    vc_var             h2_vctab_tp := h2_vctab_tp();
    l_size             CONSTANT NUMBER := length(p_str) + 1;
    l_min_index        NUMBER := 1;
    l_max_index        NUMBER;
    l_value            VARCHAR2(32676);
    i                  NUMBER := 0;
BEGIN
  IF (p_str IS NULL) THEN RETURN vc_var; END IF;
  LOOP
    l_max_index := instr(p_str, p_sep, l_min_index);
    IF l_max_index = 0 THEN l_max_index := l_size; END IF;
    l_value := trim(substr(p_str, l_min_index, (l_max_index - l_min_index)));
    i := i + 1;
    vc_var.EXTEND(1);
    vc_var(i) := l_value;
    EXIT WHEN l_max_index = l_size;
    l_min_index := l_max_index + 1;
   END LOOP;
   RETURN vc_var;
END;
/

show err

/*
@src/h2_get_list.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/src -a wrap h2_get_list
@src/wrapped/h2_get_list.plb


*/

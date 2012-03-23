/* $Header: h2_echo.sql 1.001 2011/06/24 12:10:10 h2$ 
-- Copyright (c) 2011 Hanming Tu All Rights Reserved.

PURPOSE:
  This procedure displays message using dbms_output.put_line. 
  It uses the G_MSG_LEVEL stored in user context variable as
  global message level. 

TYPE: Procedure
  
PROGRAMS OR OBJECTS REQUIRED:  None

NOTES
  1. Make sure the used functions are created. 

TESTS:
  exec h2_echo('This is a test.', 0);
  exec h2_ctx_pkg.crt(); 
  exec h2_ctx_pkg.set('G_MSG_LEVEL', 2);
  exec h2_echo('This is a test 2.', 3);

HISTORY:   MM/DD/YYYY (developer) 
  06/24/2011 (htu) - initial creation based on sp_pkg.echo
  07/05/2011 (htu) - default G_MSG_LEVEL to 1
  
*/

CREATE OR REPLACE PROCEDURE h2_echo ( 
    msg clob
  , lvl NUMBER DEFAULT 999 
) IS
  v_tot number 		:= length(msg); 
  v_pos number 		:= 1;
  v_msg varchar2(32767)	; 
  v_cnt number 		:= 0; 
  v_amt number 		:= 0; 
  v_ps2 number 		:= 1; 
  v_am2 number 		:= 0; 
  v_cn2 number		:= 0; 
  v_ctx	varchar2(100)	:= 'CTX_'||UPPER(SUBSTR(USER, 1 ,26));
  v_var varchar2(50)	:= 'G_MSG_LEVEL'; 
  v_lvl number		;
BEGIN
  SELECT sys_context(v_ctx,v_var) INTO v_lvl FROM dual;
  v_lvl := NVL(v_lvl, 1); 
  IF lvl > v_lvl THEN RETURN; END IF; 

  WHILE (v_pos <= v_tot and v_cnt < 50000) LOOP
    IF INSTR(msg, chr(10), v_pos) > 0 THEN 
      v_amt := INSTR(msg, chr(10), v_pos) - v_pos;
    ELSE
      v_amt := v_tot - v_pos + 1; 
    END IF; 
    -- dbms_output.put_line('pos='||v_pos||',amt='||v_amt);                 
    v_msg := substr(msg,v_pos, v_amt); 
    IF v_amt > 255 THEN
      -- dbms_output.put_line(v_msg);                 
      while (length(v_msg) > 0 AND v_cn2 < 1000) loop 
        -- from the 255 char search backward
        v_ps2 := instr(substr(v_msg,1,255),chr(32), -1);  	-- check space
        IF v_ps2 = 0 THEN 
          v_ps2 := instr(substr(v_msg,1,255), chr(62), -1); 	-- check '>'
        END IF; 
        IF v_ps2 = 0 THEN 
          v_ps2 := instr(substr(v_msg,1,255), chr(59), -1); 	-- check ';'
        END IF; 
        IF v_ps2 = 0 OR v_ps2 > 255 THEN
          v_am2 := 255; v_ps2 := 256; 
        ELSE
          v_am2 := v_ps2; v_ps2 := v_ps2+1; 
        END IF; 
        -- dbms_output.put_line('ps2='||v_ps2||',am2='||v_am2);  
        dbms_output.put_line(substr(v_msg,1, v_am2));
        v_msg := substr(v_msg,v_ps2);  
        v_cn2 := v_cn2 + 1;
      end loop; 
    ELSE
      dbms_output.put_line(v_msg); 
    END IF; 
    v_cnt := v_cnt + 1; 		-- so that it will not go into infinite loop
    v_pos := v_pos + v_amt; 
    IF INSTR(msg, chr(10), v_pos) > 0 THEN v_pos := v_pos + 1; END IF; 
  END LOOP;

END;
/

show err

/*
@src/h2_echo.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/src -a wrap h2_echo
@src/wrapped/h2_echo.plb

*/


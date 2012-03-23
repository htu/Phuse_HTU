/* $Header: h2_ctx_pkg.sql 1.001 2011/06/24 12:10:10 cc$ 
-- Copyright (c) 2011 Hanming Tu All Rights Reserved.

PURPOSE:
  This package contains the functions and procedures related to context within
  Oracle name space. 
  
TYPE: Package  

PROGRAMS OR OBJECTS REQUIRED:  None

NOTES:
  1. This pkg requires to have access to dba_context view: 
  sys@dis1> grant select on dba_context to owb_admin,sdtm_base;

TESTS:

  -- CREATE OR REPLACE CONTEXT ctx_system USING h2_ctx_pkg;
  exec h2_ctx_pkg.crt(); 
  exec h2_ctx_pkg.set_app_user('cmdr_dev');
  select h2_ctx_pkg.get_app_user from dual;
  select h2_ctx_pkg.get_os_user from dual;
  exec h2_ctx_pkg.set('CTX_OWB_ADMIN','G_MSG_LEVEL', 3);
  select sys_context('CTX_OWB_ADMIN','G_MSG_LEVEL') from dual;

  select h2_ctx_pkg.get('USERENV','DB_NAME') from dual;

HISTORY:   MM/DD/YYYY (developer)
  06/24/2011 (htu) - initial creation
  07/05/2011 (htu) - 
    1. added g_ctx
    2. changed get from (p_ctx,p_var) to (p_var,p_ctx)
    3. changed set from (p_ctx,p_var,p_val) to (p_var,p_val,p_ctx)
*/

CREATE OR REPLACE PACKAGE h2_ctx_pkg
IS
  g_prg		varchar2(200)	:= 'h2_ctx_pkg';
  g_lvl		number 		:= 0;
  g_ctx		varchar2(200)	:= 'CTX_'||UPPER(SUBSTR(USER, 1 ,26));

  FUNCTION get (
     p_var VARCHAR2 DEFAULT NULL 	-- variable name
  ,  p_ctx VARCHAR2 DEFAULT NULL	-- context name
  ) RETURN VARCHAR2;

  FUNCTION get_os_user  RETURN VARCHAR2;
  FUNCTION get_app_user RETURN VARCHAR2;
  
  PROCEDURE set_app_user (p_usr VARCHAR2);

  PROCEDURE echo (
    msg clob
  , lvl NUMBER DEFAULT 999
  );
  
  PROCEDURE crt (
    p_ctx VARCHAR2 DEFAULT NULL		-- context name
  , p_pkg VARCHAR2 DEFAULT NULL 	-- package name or schema.pkg
  , p_typ VARCHAR2 DEFAULT NULL		-- context type
  );
  
  PROCEDURE set (
    p_var VARCHAR2		-- variable name
  , p_val VARCHAR2 DEFAULT NULL	-- value
  , p_ctx VARCHAR2 DEFAULT NULL	-- context name
  ); 

END;
/

show err

CREATE OR REPLACE PACKAGE BODY h2_ctx_pkg
IS

-------------------- FUNC: get  ---------------------------------------------
FUNCTION get (
    p_var VARCHAR2 DEFAULT NULL 	-- variable name
  , p_ctx VARCHAR2 DEFAULT NULL		-- context name
) RETURN VARCHAR2 IS
  v_ctx VARCHAR2(100);
  v_var VARCHAR2(100);
  v_val VARCHAR2(100);
BEGIN
  v_ctx := NVL(UPPER(p_ctx),g_ctx);
  v_var := NVL(UPPER(p_var), 'APP_USER');
  SELECT sys_context(v_ctx,v_var) INTO v_val FROM dual;
  RETURN v_val;
END;

-------------------- FUNC: get_os_user  -------------------------------------
FUNCTION get_os_user RETURN VARCHAR2 IS
BEGIN
  RETURN h2_ctx_pkg.get('OS_USER','USERENV');
END;

-------------------- FUNC: get_app_user  ------------------------------------
FUNCTION get_app_user RETURN VARCHAR2 IS
BEGIN
  RETURN NVL(h2_ctx_pkg.get('APP_USER'), 'MISSING');
END;

-------------------- PROC: echo  --------------------------------------------
PROCEDURE echo (
    msg clob
  , lvl NUMBER DEFAULT 999
) IS
BEGIN
  IF lvl <= g_lvl THEN dbms_output.put_line(msg); END IF;
END;

-------------------- PROC: set_app_user  -----------------------------------
PROCEDURE set_app_user (p_usr VARCHAR2) IS
  v_var VARCHAR2(100) := 'APP_USER';
BEGIN
  h2_ctx_pkg.set(v_var,p_usr,g_ctx);
END;

-------------------- PROC: crt ----------------------------------------------
PROCEDURE crt (
    p_ctx VARCHAR2 DEFAULT NULL		-- context name
  , p_pkg VARCHAR2 DEFAULT NULL 	-- package name or schema.pkg
  , p_typ VARCHAR2 DEFAULT NULL		-- context type
) IS
  v_prg 	varchar2(200) := g_prg||'.crt';
  v_ctx 	varchar2(200);
  v_pkg		varchar2(200);
  n 		number;
  msg		varchar2(2000);
  v_sql		varchar2(2000);
BEGIN
  -- 1. check inputs
  v_ctx := NVL(p_ctx,g_ctx);
  v_pkg := NVL(p_pkg,g_prg); 

  -- 2. check objects
  SELECT count(*) INTO n   FROM dba_context
   WHERE namespace = v_ctx  AND schema = USER;
  IF n > 0 THEN
    msg := 'INFO('||v_prg||'): context - '||v_ctx||' alread exist.';
    echo(msg, 0);
    RETURN;
  END IF;
  
  -- 3. create conext
  v_sql := 'CREATE CONTEXT '||v_ctx||' USING '||v_pkg;
  IF p_typ IS NOT NULL THEN
    v_sql := v_sql||' ACCESSED GLOBALLY';
  END IF;
  EXECUTE IMMEDIATE v_sql; 

  EXCEPTION WHEN OTHERS THEN echo('ERR('||v_prg||'): '||SQLERRM,0); 
END;

-------------------- PROC: set ----------------------------------------------
PROCEDURE set (
    p_var VARCHAR2		-- variable name
  , p_val VARCHAR2 DEFAULT NULL	-- value
  , p_ctx VARCHAR2 DEFAULT NULL	-- context name
) IS 
  v_prg 	varchar2(200) := g_prg||'.set_context';
  v_var 	varchar2(200);
  v_ctx 	varchar2(200);
  n 		number;
  msg		varchar2(2000);
BEGIN
  -- 1. check inputs
  v_ctx := NVL(p_ctx,g_ctx);
  v_var := UPPER(p_var); 
  IF p_var IS NULL THEN
    msg := 'ERR('||v_prg||'): variable name is required.';
    echo(msg, 1);    RETURN;
  END IF;
  
  -- 2. check objects  
  SELECT count(*) INTO n FROM dba_context 
   WHERE namespace = v_ctx  AND schema = USER;
  IF n < 1 THEN
    msg := 'ERR('||v_prg||'): invalid context name';
    raise_application_error(-20000, msg);
  END IF;
  
  -- 3. set conext to the value
  DBMS_SESSION.SET_CONTEXT(v_ctx,v_var,p_val);

  EXCEPTION WHEN OTHERS THEN echo('ERR('||v_prg||'): '||SQLERRM,0); 
END;


END;
/

show err


/*
@src/h2_ctx_pkg.sql
/opt/www/bin/ora_wrap -d /opt/www/sqls/src -a wrap h2_ctx_pkg
@src/wrapped/h2_ctx_pkg.plb


*/

dSET SERVEROUTPUT ON SIZE UNLIMITED FORMAT WRAPPED;

DECLARE
    l_ref_cursor      SYS_REFCURSOR;
    l_dbms_sql_cursor NUMBER;
    l_column_count    NUMBER;
    l_desc_tab        DBMS_SQL.DESC_TAB;
    l_value           VARCHAR2(4000);
    l_header          VARCHAR2(4000);
    l_separator       VARCHAR2(4000);
    l_row_line        VARCHAR2(4000);
    
    -- Variables for column width calculation
    TYPE width_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_col_widths      width_tab;
    l_max_width       NUMBER := 20; -- Default max column width
BEGIN
    -- Open your cursor here (replace with your query)
    OPEN l_ref_cursor FOR SELECT * FROM your_table WHERE 1=0; -- Example query
    
    -- Convert to DBMS_SQL cursor
    l_dbms_sql_cursor := DBMS_SQL.TO_CURSOR_NUMBER(l_ref_cursor);
    
    -- Describe the columns
    DBMS_SQL.DESCRIBE_COLUMNS(l_dbms_sql_cursor, l_column_count, l_desc_tab);
    
    -- Calculate column widths based on header and sample data
    FOR i IN 1..l_column_count LOOP
        -- Set initial width to column name length
        l_col_widths(i) := LEAST(GREATEST(LENGTH(l_desc_tab(i).col_name), 10), l_max_width);
    END LOOP;
    
    -- Define VARCHAR2 columns to hold values
    FOR i IN 1..l_column_count LOOP
        DBMS_SQL.DEFINE_COLUMN(l_dbms_sql_cursor, i, l_value, 4000);
    END LOOP;
    
    -- Build header and separator
    l_header := '|';
    l_separator := '+';
    FOR i IN 1..l_column_count LOOP
        l_header := l_header || ' ' || RPAD(l_desc_tab(i).col_name, l_col_widths(i)) || ' |';
        l_separator := l_separator || LPAD('-', l_col_widths(i)+2, '-') || '+';
    END LOOP;
    
    -- Print table header
    DBMS_OUTPUT.PUT_LINE(l_separator);
    DBMS_OUTPUT.PUT_LINE(l_header);
    DBMS_OUTPUT.PUT_LINE(l_separator);
    
    -- Fetch and print rows
    WHILE DBMS_SQL.FETCH_ROWS(l_dbms_sql_cursor) > 0 LOOP
        l_row_line := '|';
        FOR i IN 1..l_column_count LOOP
            DBMS_SQL.COLUMN_VALUE(l_dbms_sql_cursor, i, l_value);
            
            -- Truncate long values and format
            IF LENGTH(l_value) > l_col_widths(i) THEN
                l_value := SUBSTR(l_value, 1, l_col_widths(i)-3) || '...';
            END IF;
            
            -- Handle NULL values
            l_value := NVL(l_value, 'NULL');
            
            -- Add to row line
            l_row_line := l_row_line || ' ' || RPAD(l_value, l_col_widths(i)) || ' |';
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(l_row_line);
    END LOOP;
    
    -- Close table
    DBMS_OUTPUT.PUT_LINE(l_separator);
    
    -- Close cursor
    DBMS_SQL.CLOSE_CURSOR(l_dbms_sql_cursor);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_SQL.CLOSE_CURSOR(l_dbms_sql_cursor);
        RAISE;
END;
/

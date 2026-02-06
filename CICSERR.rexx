/* REXX - CICS Error Checker */
/* Access SDSF and extract CICS error messages */
/* Read CICS regions from file and process each one */

parse arg input_file
if input_file = "" then input_file = "CICS.REGIONS.LIST"

say "================================"
say "CICS REGION ERROR CHECKER"
say "================================"
say "Input file:" input_file
say " "

/* Read the CICS region list from file */
region_list. = ""
region_count = 0

/* Allocate and read the input file */
"ALLOC FI(REGLIST) DA('"input_file"') SHR REUSE"
if rc <> 0 then do
   say "Error allocating input file:" input_file
   say "Return code:" rc
   exit rc
end

"EXECIO * DISKR REGLIST (STEM region_list. FINIS"
read_rc = rc

"FREE FI(REGLIST)"

if read_rc <> 0 then do
   say "Error reading input file:" input_file
   say "Return code:" read_rc
   exit read_rc
end

/* Validate and clean up region names */
region_count = region_list.0
say "Found" region_count "CICS region(s) to check"
say " "

if region_count = 0 then do
   say "No CICS regions found in input file"
   exit 4
end

/* Initialize SDSF once for all regions */
rc = isfcalls('ON')
if rc <> 0 then do
   say "Error initializing SDSF REXX interface"
   exit rc
end

/* Initialize summary arrays */
summary_region. = ""
summary_control. = ""
summary_db2conn. = ""
summary_db2state. = ""
summary_mqconn. = ""
summary_mqstate. = ""
summary_errors. = ""
summary_status. = ""
summary_notes. = ""
summary_count = 0

/* Process each CICS region */
total_errors = 0
healthy_count = 0

do reg_idx = 1 to region_count
   region_name = strip(region_list.reg_idx)
   
   /* Skip empty lines or comments */
   if region_name = "" | substr(region_name, 1, 1) = "*" then
      iterate
   
   /* Ensure region name is uppercase and max 8 chars */
   region_name = translate(region_name)
   region_name = substr(region_name, 1, 8)
   
   say "###############################################"
   say "# Processing CICS Region:" region_name
   say "###############################################"
   say " "
   
   call process_cics_region region_name
   
   say " "
end

/* Clean up SDSF */
call isfcalls 'OFF'

say " "
say " "
say "========================================"
say "PROCESSING COMPLETE"
say "========================================"

/* Display Summary Tables NOW - right after completion */
call display_summary_tables

say " "
say "Total regions checked:" summary_count
say "Total errors found:" total_errors
say "Healthy regions:" healthy_count || "/" || summary_count
say "========================================"

exit 0

/* Process a single CICS region */
process_cics_region: procedure expose total_errors summary_region. ,
                     summary_control. summary_db2conn. summary_db2state. ,
                     summary_mqconn. summary_mqstate. summary_errors. ,
                     summary_status. summary_notes. summary_count ,
                     healthy_count
   parse arg region_name
   
   msg_count = 0
   cics_control = 0
   db2_conn_enabled = 0
   db2_connected = 0
   mq_conn_enabled = 0
   mq_connected = 0
   cics_msg = ""
   db2_msg = ""
   mq_msg = ""
   
   /* Initialize SDSF defaults */
   isfowner = "*"
   isfprefix = region_name
   
   /* Display status */
   Address SDSF "ISFEXEC ST (ALTERNATE DELAYED)"
   if rc <> 0 then do
      say "Error executing SDSF ST command - RC:" rc
      /* Add to summary as not found */
      summary_count = summary_count + 1
      summary_region.summary_count = region_name
      summary_control.summary_count = "N/A"
      summary_db2conn.summary_count = "N/A"
      summary_db2state.summary_count = "N/A"
      summary_mqconn.summary_count = "N/A"
      summary_mqstate.summary_count = "N/A"
      summary_errors.summary_count = 0
      summary_status.summary_count = "ERROR"
      summary_notes.summary_count = "SDSF error"
      return
   end
   
   /* Find the CICS region */
   job_found = 0
   do i = 1 to jname.0
      if pos(region_name, jname.i) > 0 then do
         job_found = 1
         target_token = token.i
         target_jname = jname.i
         say "Found CICS region:" jname.i
         leave
      end
   end
   
   if job_found = 0 then do
      say "CICS region" region_name "not found or not active"
      say " "
      /* Add to summary as not found */
      summary_count = summary_count + 1
      summary_region.summary_count = region_name
      summary_control.summary_count = "N/A"
      summary_db2conn.summary_count = "N/A"
      summary_db2state.summary_count = "N/A"
      summary_mqconn.summary_count = "N/A"
      summary_mqstate.summary_count = "N/A"
      summary_errors.summary_count = 0
      summary_status.summary_count = "NOT FOUND"
      summary_notes.summary_count = "Not active"
      return
   end
   
   /* Access the output */
   Address SDSF "ISFACT ST TOKEN('"target_token"') PARM(NP ?)"
   if rc <> 0 then do
      say "Error accessing output - RC:" rc
      /* Add to summary as error */
      summary_count = summary_count + 1
      summary_region.summary_count = region_name
      summary_control.summary_count = "N/A"
      summary_db2conn.summary_count = "N/A"
      summary_db2state.summary_count = "N/A"
      summary_mqconn.summary_count = "N/A"
      summary_mqstate.summary_count = "N/A"
      summary_errors.summary_count = 0
      summary_status.summary_count = "ERROR"
      summary_notes.summary_count = "Access error"
      return
   end
   
   /* Process each DD */
   if datatype(ddname.0) = 'NUM' then do
      dd_count = ddname.0
      
      say " "
      say "--- Checking CICS Status ---"
      
      /* Pass 1: Check CICS control and connection settings */
      do j = 1 to dd_count
         curr_dd = ddname.j
         
         if curr_dd = "JESMSGLG" then do
            Address SDSF "ISFBROWSE ST TOKEN('"token.j"')"
            if rc = 0 & datatype(isfline.0) = 'NUM' then do
               call check_cics_status
            end
         end
      end
      
      /* Display what was found during the check */
      if cics_msg <> "" then say "  " || cics_msg
      if db2_msg <> "" then say "  " || db2_msg
      if mq_msg <> "" then say "  " || mq_msg
      
      /* Display CICS Control Status */
      say " "
      say "CICS Control:"
      if cics_control = 1 then do
         say "  ✓ CICS has control (DFHSI1517 found)"
      end
      else do
         say "  ✗ WARNING: CICS does not have control"
      end
      
      /* Display DB2 Connection Status */
      say " "
      say "DB2 Connection:"
      if db2_conn_enabled = 0 then do
         say "  - NO DB2 Connection for the region" region_name
      end
      else do
         if db2_connected = 1 then do
            say "  ✓ DB2 Connection successful"
         end
         else do
            say "  ✗ DB2 Connection not completed"
         end
      end
      
      /* Display MQ Connection Status */
      say " "
      say "MQ Connection:"
      if mq_conn_enabled = 0 then do
         say "  - NO MQ Connection for the region" region_name
      end
      else do
         if mq_connected = 1 then do
            say "  ✓ MQ Connection successful"
         end
         else do
            say "  ✗ MQ Connection not completed"
         end
      end
      
      say " "
      say "--- Error Messages ---"
      
      /* Pass 2: Search for error messages */
      do j = 1 to dd_count
         curr_dd = ddname.j
         
         if curr_dd = "MSGUSR" | curr_dd = "JESMSGLG" | ,
            curr_dd = "SYSOUT" | curr_dd = "SYSPRINT" | ,
            pos("LOG", curr_dd) > 0 then do
            
            Address SDSF "ISFBROWSE ST TOKEN('"token.j"')"
            if rc = 0 & datatype(isfline.0) = 'NUM' then do
               call process_all_lines
            end
         end
      end
      
      if msg_count = 0 then
         say "  No DFH error messages found"
      else
         say " "
      
      say "--- Summary for" region_name "---"
      say "Error messages found:" msg_count
      
      /* Update total errors */
      total_errors = total_errors + msg_count
      
      /* Determine overall status and notes */
      status = "HEALTHY"
      notes = ""
      
      /* Check for critical issues */
      if cics_control = 0 then do
         status = "ERROR"
         notes = "Control not given"
      end
      else if db2_conn_enabled = 1 & db2_connected = 0 then do
         status = "WARNING"
         notes = "DB2 conn failed"
      end
      else if mq_conn_enabled = 1 & mq_connected = 0 then do
         status = "WARNING"
         if notes <> "" then
            notes = notes || ", MQ conn failed"
         else
            notes = "MQ conn failed"
      end
      else do
         /* Build notes for healthy region */
         if db2_conn_enabled = 1 & mq_conn_enabled = 1 then
            notes = "DB2 + MQ"
         else if db2_conn_enabled = 1 then
            notes = "DB2 only"
         else if mq_conn_enabled = 1 then
            notes = "MQ only"
         else
            notes = "No DB2/MQ"
      end
      
      if status = "HEALTHY" then
         healthy_count = healthy_count + 1
      
      /* Add to summary arrays */
      summary_count = summary_count + 1
      summary_region.summary_count = region_name
      summary_control.summary_count = cics_control
      summary_db2conn.summary_count = db2_conn_enabled
      if db2_conn_enabled = 1 then do
         if db2_connected = 1 then
            summary_db2state.summary_count = "SUCCESS"
         else
            summary_db2state.summary_count = "FAILED"
      end
      else
         summary_db2state.summary_count = "N/A"
      
      summary_mqconn.summary_count = mq_conn_enabled
      if mq_conn_enabled = 1 then do
         if mq_connected = 1 then
            summary_mqstate.summary_count = "SUCCESS"
         else
            summary_mqstate.summary_count = "FAILED"
      end
      else
         summary_mqstate.summary_count = "N/A"
      
      summary_errors.summary_count = msg_count
      summary_status.summary_count = status
      summary_notes.summary_count = notes
   end
   
return

/* Check CICS status, DB2, and MQ connections */
check_cics_status: procedure expose isfline. cics_control ,
                                    db2_conn_enabled db2_connected ,
                                    mq_conn_enabled mq_connected ,
                                    region_name cics_msg db2_msg mq_msg
   
   line_count = isfline.0
   
   do i = 1 to line_count
      current_line = isfline.i
      upper_line = translate(current_line)
      
      /* Check for CICS Control (DFHSI1517) */
      if pos("DFHSI1517", upper_line) > 0 then do
         if pos("CONTROL", upper_line) > 0 & ,
            pos("GIVEN", upper_line) > 0 then do
            cics_control = 1
            cics_msg = "Found: " || strip(current_line)
         end
      end
      
      /* Check for DB2CONN setting */
      if pos("DB2CONN=", upper_line) > 0 then do
         if pos("DB2CONN=YES", upper_line) > 0 then do
            db2_conn_enabled = 1
         end
         else if pos("DB2CONN=NO", upper_line) > 0 then do
            db2_conn_enabled = 0
         end
      end
      
      /* Check for DB2 connection message (DFHDB2023I) */
      if db2_conn_enabled = 1 then do
         if pos("DFHDB2023", upper_line) > 0 then do
            db2_connected = 1
            db2_msg = "Found: " || strip(current_line)
         end
      end
      
      /* Check for MQCONN setting */
      if pos("MQCONN=", upper_line) > 0 then do
         if pos("MQCONN=YES", upper_line) > 0 then do
            mq_conn_enabled = 1
         end
         else if pos("MQCONN=NO", upper_line) > 0 then do
            mq_conn_enabled = 0
         end
      end
      
      /* Check for MQ connection message (DFHMQ0307I) */
      if mq_conn_enabled = 1 then do
         if pos("DFHMQ0307", upper_line) > 0 then do
            mq_connected = 1
            mq_msg = "Found: " || strip(current_line)
         end
      end
   end
   
return

/* Process all lines looking for multi-line error messages */
process_all_lines: procedure expose isfline. msg_count
   
   line_count = isfline.0
   i = 1
   
   do while i <= line_count
      current_line = isfline.i
      
      /* Check if this line starts a DFH error message */
      if pos("DFH", current_line) > 0 then do
         upper_line = translate(current_line)
         
         /* Look for pattern DFHxxxxx E */
         dfh_pos = pos("DFH", upper_line)
         if dfh_pos > 0 then do
            test_part = substr(upper_line, dfh_pos, 12)
            /* Check for E after message code */
            if pos(" E ", test_part) > 0 then do
               /* Found error message start */
               msg_text = substr(current_line, dfh_pos)
               
               /* Check if message ends with period on this line */
               if pos(".", msg_text) = 0 then do
                  /* Multi-line message - collect subsequent lines */
                  i = i + 1
                  do while i <= line_count
                     next_line = isfline.i
                     msg_text = msg_text next_line
                     
                     /* Check if this line has the period */
                     if pos(".", next_line) > 0 then leave
                     
                     i = i + 1
                  end
               end
               
               /* Extract up to and including the period */
               period_pos = pos(".", msg_text)
               if period_pos > 0 then do
                  complete_msg = substr(msg_text, 1, period_pos)
               end
               else do
                  complete_msg = msg_text
               end
               
               say " "
               say complete_msg
               msg_count = msg_count + 1
            end
         end
      end
      
      i = i + 1
   end
   
return

/* Display Summary Tables */
display_summary_tables: procedure expose summary_region. summary_control. ,
                        summary_db2conn. summary_db2state. summary_mqconn. ,
                        summary_mqstate. summary_errors. summary_status. ,
                        summary_notes. summary_count
   
   if summary_count = 0 then return
   
   say " "
   say "========================================================================"
   say "                            QUICK SUMMARY"
   say "========================================================================"
   say "Region      Status      Errors  Notes"
   say "------------------------------------------------------------------------"
   
   do i = 1 to summary_count
      region = left(summary_region.i, 12)
      status = left(summary_status.i, 12)
      errors = left(summary_errors.i, 8)
      notes = summary_notes.i
      
      say region || status || errors || notes
   end
   
   say "========================================================================"
   say " "
   say " "
   
   say "========================================================================"
   say "                          DETAILED STATUS"
   say "========================================================================"
   say "Region      CICS Ctrl   DB2 Conn    DB2 State   MQ Conn     MQ State    Errors"
   say "------------------------------------------------------------------------"
   
   do i = 1 to summary_count
      region = left(summary_region.i, 12)
      
      /* Format CICS Control */
      if summary_control.i = 1 then
         ctrl = left("YES", 12)
      else if summary_control.i = 0 then
         ctrl = left("NO", 12)
      else
         ctrl = left("N/A", 12)
      
      /* Format DB2 Connection */
      if summary_db2conn.i = 1 then
         db2c = left("YES", 12)
      else if summary_db2conn.i = 0 then
         db2c = left("NO", 12)
      else
         db2c = left("N/A", 12)
      
      /* Format DB2 State */
      db2s = left(summary_db2state.i, 12)
      
      /* Format MQ Connection */
      if summary_mqconn.i = 1 then
         mqc = left("YES", 12)
      else if summary_mqconn.i = 0 then
         mqc = left("NO", 12)
      else
         mqc = left("N/A", 12)
      
      /* Format MQ State */
      mqs = left(summary_mqstate.i, 12)
      
      /* Format Errors */
      errs = left(summary_errors.i, 12)
      
      say region || ctrl || db2c || db2s || mqc || mqs || errs
   end
   
   say "========================================================================"
   
return

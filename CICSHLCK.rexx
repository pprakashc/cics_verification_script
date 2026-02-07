/* REXX - CICS Verification script                                   */
/*********************************************************************/
/*                                                                   */
/* SCRIPT NAME: CICSHLCK                                             */
/*                                                                   */
/* DESCRIPTION: CICS Region Startup Verification and Health Monitor  */
/*              This script verifies CICS region startup status,     */
/*              checks DB2 and MQ connectivity, scans for error      */
/*              messages, and produces summary reports.              */
/*                                                                   */
/* AUTHOR:      Prakash Chenniyappan                                 */
/*                                                                   */
/* DATE:        February 2026                                        */
/*                                                                   */
/* VERSION:     1.1.0                                                */
/*                                                                   */
/* PURPOSE:     - Verify CICS regions have control (DFHSI1517)       */
/*              - Check DB2 connection status                        */
/*              - Check MQ connection status                         */
/*              - Count DFH error messages                           */
/*              - Generate health summary reports                    */
/*              - Support batch processing of multiple regions       */
/*                                                                   */
/* INPUT:       Dataset containing CICS region names (cols 1-8)      */
/*              Format: YOURHLQ.CICS.<sysname>.REGIONS.LIST          */
/*              - One region name per line (1-8 characters)          */
/*              - Lines starting with * are comments                 */
/*              - Columns 9-80 ignored (supports line numbers)       */
/*                                                                   */
/*              Example input file:                                  */
/*                CICSTEST                                   00010000*/
/*                CICSPRD                                    00020000*/
/*                * Comment line                             00030000*/
/*                ABC                                        00040000*/
/*                                                                   */
/* OUTPUT:      TSO EXEC mode:                                       */
/*           Dataset: YOURHLQ.CICS.HLTHCHCK.<sysname>.Dmmddyy.Thhmmss*/
/*              - DCB: RECFM=FBA, LRECL=133                          */
/*              - Expiration: 180 days                               */
/*              - Contains detailed report and summary tables        */
/*                                                                   */
/*              Batch JCL mode:                                      */
/*              - Output to SYSTSPRT + Dataset                       */
/*                                                                   */
/*              Report sections:                                     */
/*              1. Individual region status checks                   */
/*              2. Quick summary table (status, errors, notes)       */
/*              3. Detailed status table (all connections)           */
/*              4. Overall statistics                                */
/*                                                                   */
/* EXECUTION:   TSO EXEC (automatic input file detection):           */
/*              EX 'YOUR.REXX.LIB(CICSHLCK)'                         */
/*                                                                   */
/*              TSO EXEC (explicit input file):                      */
/*              EX 'YOUR.REXX.LIB(CICSHLCK)' 'DATASET.NAME'          */
/*                                                                   */
/*              Batch JCL:                                           */
/*              //STEP1    EXEC PGM=IKJEFT01                         */
/*              //ISFPARMS DD DISP=SHR,DSN=HLQ.SISFPLIB              */
/*              //SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY         */
/*              //SYSTSPRT DD SYSOUT=*                               */
/*              //SYSTSIN  DD *                                      */
/*                %CICSHLCK                                          */
/*        OR %CICSHLCK YOUR.REGION.LIST                              */
/*                                                                   */
/* RETURN CODES: 0  - Successful execution                           */
/*               4  - No regions found in input file                 */
/*               8  - SDSF initialization error                      */
/*               12 - Input file allocation error                    */
/*                                                                   */
/* REQUIREMENTS: - z/OS operating system                             */
/*               - TSO/E REXX environment                            */
/*               - SDSF (System Display and Search Facility)         */
/*               - SDSF REXX interface enabled                       */
/*               - SDSF authorization for user                       */
/*               - Access to started tasks (STC) in SDSF             */
/*               - CICS Transaction Server                           */
/*                                                                   */
/* SYSTEM SYMBOLS: &SYSNAME - Used to identify LPAR                  */
/*                 Must be defined in IEASYMxx member                */
/*                                                                   */
/* CHECKS PERFORMED:                                                 */
/*   1. CICS Control Status:                                         */
/*      - Message: DFHSI1517 (Control is being given to CICS)        */
/*      - Indicates: CICS initialization complete                    */
/*                                                                   */
/*   2. DB2 Connection:                                              */
/*      - Parameter: DB2CONN=YES/NO in JESMSGLG                      */
/*      - Message: DFHDB2023I (DB2 connection established)           */
/*      - Status: Not enabled / Connected / Failed                   */
/*                                                                   */
/*   3. MQ Connection:                                               */
/*      - Parameter: MQCONN=YES/NO in JESMSGLG                       */
/*      - Message: DFHMQ0307I (MQ connection established)            */
/*      - Status: Not enabled / Connected / Failed                   */
/*                                                                   */
/*   4. Error Messages:                                              */
/*      - Pattern: DFHxxxxxE (CICS error messages)                   */
/*      - Scanned DDs: JESMSGLG, MSGUSR, SYSOUT, SYSPRINT, LOG*      */
/*      - Multi-line messages: Assembled until period found          */
/*      - Count only: Individual messages not printed                */
/*                                                                   */
/* HEALTH STATUS CATEGORIES:                                         */
/*   HEALTHY   - All configured connections working, CICS has control*/
/*   WARNING   - CICS has control but DB2/MQ connection failed       */
/*   ERROR     - CICS control not given                              */
/*   NOT FOUND - Region not active or not found in SDSF              */
/*                                                                   */
/* CUSTOMIZATION:                                                    */
/*   - Modify HLQ in setup_tso_output (currently YOURHLQ)            */
/*   - Adjust expiration days (currently 180)                        */
/*   - Add additional message patterns in check_cics_status          */
/*   - Modify error pattern in count_error_messages                  */
/*   - Add more DD names to scan in process_cics_region              */
/*                                                                   */
/* LIMITATIONS:                                                      */
/*   - Region names limited to 8 characters (z/OS job name limit)    */
/*   - Only scans JESMSGLG for connection status                     */
/*   - Error count only, individual errors not displayed             */
/*   - Requires CICS regions to be active (started tasks)            */
/*                                                                   */
/* DEPENDENCIES:                                                     */
/*   - SDSF REXX interface (ISFCALLS)                                */
/*   - MVS system symbols (MVSVAR)                                   */
/*   - TSO environment for file allocation                           */
/*                                                                   */
/* CHANGE HISTORY:                                                   */
/*   1.0.0 - 2026-02-06 - Initial release                            */
/*         - CICS control verification                               */
/*         - DB2/MQ connection monitoring                            */
/*         - Error message counting                                  */
/*         - Batch processing support                                */
/*         - Summary table generation                                */
/*         - Timestamped output with LPAR identification             */
/*         - Support for 1-8 character region names                  */
/*         - Column 1-8 input reading (supports line numbers)        */
/*                                                                   */
/* NOTES:    - Input file supports TSO NUM ON/OFF                    */
/*           - Only columns 1-8 are read from input file             */
/*           - Inline comments allowed after column 8                */
/*           - Exact match used for region name lookup               */
/*           - Output datasets auto-expire after 180 days            */
/*********************************************************************/

parse arg input_file

/* If no input file specified, build it using system name */
if input_file = "" then do
   temp_sysname = MVSVAR('SYMDEF','SYSNAME')
   if temp_sysname = '' then temp_sysname = 'UNKNOWN'
   input_file = "YOURHLQ.CICS." || temp_sysname || ".REGIONS.LIST"
end

/* Detect execution environment */
address_env = address()
output_mode = "BATCH"
output_dd = ""
output_dsn = ""

if address_env = "TSO" then do
   /* Running in TSO - set up flat file output */
   output_mode = "TSO"
   call setup_tso_output
end

call write_output "================================"
call write_output "   CICS REGION ERROR CHECKER"
call write_output "================================"
call write_output "Input file:" input_file
if output_mode = "TSO" then do
   call write_output "Output mode: TSO EXEC"
   call write_output "Output dataset:" output_dsn
end
call write_output " "

/* Read the CICS region list from file */
region_list. = ""
region_count = 0

/* Allocate and read the input file */
"ALLOC FI(REGLIST) DA('"input_file"') SHR REUSE"
if rc <> 0 then do
   call write_output "Error allocating input file:" input_file
   call write_output "Return code:" rc
   call cleanup_and_exit rc
end

"EXECIO * DISKR REGLIST (STEM rawlist. FINIS"
read_rc = rc

"FREE FI(REGLIST)"

if read_rc <> 0 then do
   call write_output "Error reading input file:" input_file
   call write_output "Return code:" read_rc
   call cleanup_and_exit read_rc
end

/* Extract region names from columns 1-8 only */
region_count = 0
do i = 1 to rawlist.0
   /* Extract only first 8 columns, ignore rest (line numbers, etc) */
   region_name = substr(rawlist.i, 1, 8)
   region_name = strip(region_name)
   
   /* Skip empty lines or comments */
   if region_name = "" | substr(region_name, 1, 1) = "*" then
      iterate
   
   /* Add to clean list */
   region_count = region_count + 1
   region_list.region_count = region_name
end

region_list.0 = region_count

call write_output "Found" region_count "CICS region(s) to check"
call write_output " "

if region_count = 0 then do
   call write_output "No CICS regions found in input file"
   call cleanup_and_exit 4
end

/* Initialize SDSF once for all regions */
rc = isfcalls('ON')
if rc <> 0 then do
   call write_output "Error initializing SDSF REXX interface"
   call cleanup_and_exit rc
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
   region_name = region_list.reg_idx
   
   /* Ensure uppercase */
   region_name = translate(region_name)
   
   call write_output "---------------------------------------------"
   call write_output "# Processing CICS Region:" region_name
   call write_output "---------------------------------------------"
   call write_output " "
   
   call process_cics_region region_name
   
   call write_output " "
end

/* Clean up SDSF */
call isfcalls 'OFF'

call write_output " "
call write_output " "
call write_output "========================================"
call write_output "=        PROCESSING COMPLETE           ="
call write_output "========================================"
call write_output " "

/* Display Summary Tables */
call display_summary_tables

call write_output " "
call write_output "Total regions checked:" summary_count
call write_output "Total errors found:" total_errors
call write_output "Healthy regions:" healthy_count || "/" || summary_count
call write_output "========================================"

call cleanup_and_exit 0

/* ==================================================================== */
/* MAIN CODE ENDS HERE - SUBROUTINES BELOW                              */
/* ==================================================================== */
exit 0

/* Setup output for TSO mode - flat file with timestamp */
setup_tso_output:
   /* Get system name from system symbol &SYSNAME. */
   sysname = MVSVAR('SYMDEF','SYSNAME')
   if sysname = '' then sysname = 'UNKNOWN'
   
   /* Get current date and time */
   date_part = date('S')
   current_time = time('N')
   
   /* Extract MMDDYY */
   mm = substr(date_part, 5, 2)
   dd = substr(date_part, 7, 2)
   yy = substr(date_part, 3, 2)
   mmddyy = mm || dd || yy
   
   /* Extract HHMMSS */
   parse var current_time hh ":" min ":" ss
   hhmmss = hh || min || ss
   
   /* Build dataset name */
   output_dsn = "YOURHLQ.CICS.HLTHCHCK." || sysname || ".D" || ,
                mmddyy || ".T" || hhmmss
   
   /* Calculate expiration date */
   exp_date = get_expiration_date(180)
   
   /* Allocate dataset */
   address TSO
   "ALLOC FI(OUTDD) DA('"output_dsn"') NEW CATALOG",
   "SPACE(1,1) CYL",
   "RECFM(F,B,A) LRECL(133) BLKSIZE(27930)",
   "UNIT(SYSALLDA)",
   "EXPDT("exp_date")"
   
   if rc <> 0 then do
      say "Error allocating output dataset:" output_dsn
      say "Return code:" rc
      say "Falling back to screen output only"
      output_mode = "BATCH"
      return
   end
   
   output_dd = "OUTDD"
   say "Output will be written to:" output_dsn
   say "System (LPAR):" sysname
   say "Expiration date:" exp_date "(180 days)"
   say " "
   
return

/* Calculate expiration date */
get_expiration_date:
   parse arg days_to_add
   
   today_julian = date('J')
   exp_julian = today_julian + days_to_add
   
   exp_year_full = substr(exp_julian, 1, 4)
   exp_year = substr(exp_year_full, 3, 2)
   exp_day = right(substr(exp_julian, 5), 3, '0')
   
   exp_date = exp_year || exp_day
   
   return exp_date

/* Write output to appropriate destination */
write_output:
   parse arg output_line
   
   if output_mode = "TSO" then do
      say output_line
   end
   
   if output_mode = "BATCH" then do
      say output_line
   end
   else do
      if output_dd <> "" then do
         queue output_line
         "EXECIO 1 DISKW" output_dd
      end
   end
   
return

/* Process a single CICS region */
process_cics_region:
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
   
   isfowner = "*"
   isfprefix = region_name
   
   Address SDSF "ISFEXEC ST (ALTERNATE DELAYED)"
   if rc <> 0 then do
      call write_output "Error executing SDSF ST command - RC:" rc
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
   
   /* Find the CICS region - EXACT MATCH */
   job_found = 0
   do i = 1 to jname.0
      /* Strip spaces and compare exactly */
      if strip(jname.i) = region_name then do
         job_found = 1
         target_token = token.i
         target_jname = jname.i
         call write_output "Found CICS region:" jname.i
         leave
      end
   end
   
   if job_found = 0 then do
      call write_output "CICS region" region_name "not found or not active"
      call write_output " "
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
   
   Address SDSF "ISFACT ST TOKEN('"target_token"') PARM(NP ?)"
   if rc <> 0 then do
      call write_output "Error accessing output - RC:" rc
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
   
   if datatype(ddname.0) = 'NUM' then do
      dd_count = ddname.0
      
      call write_output " "
      call write_output "--- Checking CICS Status ---"
      
      do j = 1 to dd_count
         curr_dd = ddname.j
         
         if curr_dd = "JESMSGLG" then do
            Address SDSF "ISFBROWSE ST TOKEN('"token.j"')"
            if rc = 0 & datatype(isfline.0) = 'NUM' then do
               call check_cics_status
            end
         end
      end
      
      if cics_msg <> "" then call write_output "  " || cics_msg
      if db2_msg <> "" then call write_output "  " || db2_msg
      if mq_msg <> "" then call write_output "  " || mq_msg
      
      call write_output " "
      call write_output "CICS Control:"
      if cics_control = 1 then do
         call write_output "  > CICS has control (DFHSI1517 found)"
      end
      else do
         call write_output "  > WARNING: CICS does not have control"
      end
      
      call write_output " "
      call write_output "DB2 Connection:"
      if db2_conn_enabled = 0 then do
         call write_output "  - NO DB2 Connection for region" region_name
      end
      else do
         if db2_connected = 1 then do
            call write_output "  > DB2 Connection successful"
         end
         else do
            call write_output "  > DB2 Connection not completed"
         end
      end
      
      call write_output " "
      call write_output "MQ Connection:"
      if mq_conn_enabled = 0 then do
         call write_output "  - NO MQ Connection for region" region_name
      end
      else do
         if mq_connected = 1 then do
            call write_output "  > MQ Connection successful"
         end
         else do
            call write_output "  > MQ Connection not completed"
         end
      end
      
      call write_output " "
      call write_output "--- Scanning for Error Messages ---"
      
      do j = 1 to dd_count
         curr_dd = ddname.j
         
         if curr_dd = "MSGUSR" | curr_dd = "JESMSGLG" | ,
            curr_dd = "SYSOUT" | curr_dd = "SYSPRINT" | ,
            pos("LOG", curr_dd) > 0 then do
            
            Address SDSF "ISFBROWSE ST TOKEN('"token.j"')"
            if rc = 0 & datatype(isfline.0) = 'NUM' then do
               call count_error_messages
            end
         end
      end
      
      call write_output "--- Summary for" region_name "---"
      call write_output "Error messages found:" msg_count
      
      total_errors = total_errors + msg_count
      
      status = "HEALTHY"
      notes = ""
      
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
check_cics_status:
   line_count = isfline.0
   
   do i = 1 to line_count
      current_line = isfline.i
      upper_line = translate(current_line)
      
      if pos("DFHSI1517", upper_line) > 0 then do
         if pos("CONTROL", upper_line) > 0 & ,
            pos("GIVEN", upper_line) > 0 then do
            cics_control = 1
            cics_msg = "Found: " || strip(current_line)
         end
      end
      
      if pos("DB2CONN=", upper_line) > 0 then do
         if pos("DB2CONN=YES", upper_line) > 0 then do
            db2_conn_enabled = 1
         end
         else if pos("DB2CONN=NO", upper_line) > 0 then do
            db2_conn_enabled = 0
         end
      end
      
      if db2_conn_enabled = 1 then do
         if pos("DFHDB2023", upper_line) > 0 then do
            db2_connected = 1
            db2_msg = "Found: " || strip(current_line)
         end
      end
      
      if pos("MQCONN=", upper_line) > 0 then do
         if pos("MQCONN=YES", upper_line) > 0 then do
            mq_conn_enabled = 1
         end
         else if pos("MQCONN=NO", upper_line) > 0 then do
            mq_conn_enabled = 0
         end
      end
      
      if mq_conn_enabled = 1 then do
         if pos("DFHMQ0307", upper_line) > 0 then do
            mq_connected = 1
            mq_msg = "Found: " || strip(current_line)
         end
      end
   end
   
return

/* Count error messages */
count_error_messages:
   line_count = isfline.0
   i = 1
   
   do while i <= line_count
      current_line = isfline.i
      
      if pos("DFH", current_line) > 0 then do
         upper_line = translate(current_line)
         
         dfh_pos = pos("DFH", upper_line)
         if dfh_pos > 0 then do
            test_part = substr(upper_line, dfh_pos, 12)
            if pos(" E ", test_part) > 0 then do
               msg_count = msg_count + 1
               
               if pos(".", current_line) = 0 then do
                  i = i + 1
                  do while i <= line_count
                     next_line = isfline.i
                     if pos(".", next_line) > 0 then leave
                     i = i + 1
                  end
               end
            end
         end
      end
      
      i = i + 1
   end
   
return

/* Display Summary Tables */
display_summary_tables:
   
   if summary_count = 0 then return
   
   call write_output " "
   call write_output "=========================================================="
   call write_output "                   QUICK SUMMARY"
   call write_output "=========================================================="
   call write_output "Region    Status    Errors    Notes"
   call write_output "----------------------------------------------------------"
   
   do i = 1 to summary_count
      region = left(summary_region.i, 10)
      status = left(summary_status.i, 10)
      errors = left(summary_errors.i, 10)
      notes = summary_notes.i
      
      call write_output region || status || errors || notes
   end
   
   call write_output "=========================================================="
   call write_output " "
   call write_output " "
   
   call write_output "=================================================================="
   call write_output "=                  DETAILED STATUS                               ="
   call write_output "=================================================================="
   call write_output "Region    CicsCtrl  DB2Conn   DB2State  MQConn    MQState   Err"
   call write_output "------------------------------------------------------------------"
   
   do i = 1 to summary_count
      region = left(summary_region.i, 10)
      
      if summary_control.i = 1 then
         ctrl = left("YES", 10)
      else if summary_control.i = 0 then
         ctrl = left("NO", 10)
      else
         ctrl = left("N/A", 10)
      
      if summary_db2conn.i = 1 then
         db2c = left("YES", 10)
      else if summary_db2conn.i = 0 then
         db2c = left("NO", 10)
      else
         db2c = left("N/A", 10)
      
      db2s = left(summary_db2state.i, 10)
      
      if summary_mqconn.i = 1 then
         mqc = left("YES", 10)
      else if summary_mqconn.i = 0 then
         mqc = left("NO", 10)
      else
         mqc = left("N/A", 10)
      
      mqs = left(summary_mqstate.i, 10)
      
      errs = left(summary_errors.i, 5)
      
      call write_output region || ctrl || db2c || db2s || mqc || mqs || errs
   end
   
   call write_output "=========================================================="
   
return

/* Cleanup and exit */
cleanup_and_exit:
   parse arg exit_rc
   
   if output_mode = "TSO" & output_dd <> "" then do
      "EXECIO 0 DISKW" output_dd "(FINIS"
      "FREE FI(" || output_dd || ")"
      
      say " "
      say "Output written to:" output_dsn
      say "Dataset will expire in 180 days"
   end
   
   exit exit_rc

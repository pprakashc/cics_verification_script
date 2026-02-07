# CICS Region Startup Verification and Health Monitor - Documentation

## Overview

The CICS Region Startup Verification and Health Monitor is a REXX script (CICSHLCK.rexx) designed to run on z/OS that automatically verifies CICS region startup completion and monitors region health status. It accesses SDSF (System Display and Search Facility) to retrieve CICS job logs and performs comprehensive checks on multiple CICS regions with timestamped output in TSO mode.

## Purpose

This utility provides automated CICS startup verification and health monitoring by:
- Verifying CICS control status and startup completion (DFHSI1517)
- Checking DB2 connection parameters and status
- Checking MQ (WebSphere MQ) connection parameters and status
- Extracting and counting all DFH error messages (DFHxxxxxE)
- Processing multiple CICS regions from a single input file
- Generating timestamped output datasets with LPAR identification (TSO mode)
- Creating summary and detailed status tables

## Features

### 1. CICS Control Verification
- Searches for message **DFHSI1517** which indicates "Control is being given to CICS"
- Confirms that the CICS region has fully initialized and is ready to process transactions

### 2. DB2 Connection Check
- Checks DB2CONN parameter status (YES/NO) in CICS startup
- If enabled, verifies successful connection via message **DFHDB2023I**
- Reports connection status (Connected/Failed/Not Enabled)

### 3. MQ Connection Check
- Checks MQCONN parameter status (YES/NO) in CICS startup
- If enabled, verifies successful connection via message **DFHMQ0307I**
- Reports connection status (Connected/Failed/Not Enabled)

### 4. Error Message Counting
- Identifies all CICS error messages matching pattern **DFHxxxxxE** (where xxxxx is any characters)
- Counts error occurrences across all monitored output DDs
- Properly assembles multi-line error messages up to the terminating period (.)
- Reports error count for each region

### 5. Batch Processing with Timestamped Output
- Processes multiple CICS regions from a single input file
- Provides individual status checks for each region
- Generates quick summary and detailed status tables
- **TSO Mode**: Creates timestamped output dataset with LPAR identification
- **Batch Mode**: Outputs to SYSTSPRT with scrollable results

## Technical Requirements

### System Requirements
- **Operating System**: z/OS
- **REXX Environment**: TSO/E REXX
- **SDSF Access**: User must have proper SDSF authorization
- **Permissions**: Read access to SDSF job output for CICS regions

### SDSF Authorization
The user running this script must have:
- SDSF access authorization
- Permission to view started task (STC) output
- Authority to browse job logs via SDSF REXX interface

### Dataset Requirements
- REXX script library (PDS/PDSE)
- Input file containing CICS region names (flat file, sequential dataset)

## Installation

### Step 1: Create REXX Library
Create a partitioned dataset to store the REXX script:

```jcl
//ALLOCPDS JOB ...
//STEP1    EXEC PGM=IEFBR14
//REXXLIB  DD DSN=YOUR.REXX.LIBRARY,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(10,5,10)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),
//            UNIT=SYSDA
```

### Step 2: Upload REXX Script
Copy the REXX script into member **CICSHLCK** in your REXX library.

### Step 3: Create Input File
Create a sequential dataset for your CICS region names. The recommended naming is:
`YOURHLQ.CICS.<sysname>.REGIONS.LIST` (for automatic detection in TSO mode)

Alternatively, use: `YOUR.CICS.REGION.LIST`

```jcl
//ALLOCINP JOB ...
//STEP1    EXEC PGM=IEFBR14
//REGLIST  DD DSN=YOURHLQ.CICS.SYSNAME.REGIONS.LIST,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),
//            UNIT=SYSDA
```

### Step 4: Populate Input File
Edit the input file and add your CICS region names (one per line, columns 1-8):

```
CICSTEST
CIABS56A
CICSPROD
CICSDEV1
* Comments start with asterisk
CICSQA01
```

**Input File Format Rules:**
- **Columns 1-8**: CICS region name (required)
- **Columns 9-80**: Ignored (supports TSO NUM ON line numbering)
- **One region per line** - Maximum 8 characters per region name
- **Comment lines**: Lines starting with `*` in column 1 are skipped
- **Blank lines**: Ignored during processing
- **Uppercase conversion**: Region names automatically converted to uppercase

**Example with TSO line numbers:**
```
CICSHLCK                                         00010000
CICSPRD                                          00020000
* Development region - commented out             00030000
CICSQA01                                         00040000
```

## Execution

### Method 1: TSO Interactive - Automatic Input File Detection

The script automatically builds the input file DSN using the system name:
`YOURHLQ.CICS.<sysname>.REGIONS.LIST`

From TSO/ISPF command line:
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)'
```

**Output**: Creates timestamped dataset `YOURHLQ.CICS.HLTHCHCK.<sysname>.Dmmddyy.Thhmmss` + screen output

### Method 2: TSO Interactive - Explicit Input File

Specify the input file directly:
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)' 'YOUR.CUSTOM.REGION.LIST'
```

**Output**: Still creates timestamped output dataset + screen output

### Method 3: Batch JCL Execution

**Note**: ISFPARMS DD statement is required for SDSF REXX interface in batch mode.

```jcl
//JOBNAME  JOB (ACCT),'CICS HEALTH CHECK',
//         CLASS=A,
//         MSGCLASS=X,
//         NOTIFY=&SYSUID
//********************************************************************
//* CICS REGION STARTUP VERIFICATION
//********************************************************************
//STEP1    EXEC PGM=IKJEFT01
//ISFPARMS DD DISP=SHR,DSN=HLQ.SISFPLIB
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  %CICSHLCK
/*
```

Or with explicit input file:
```jcl
//SYSTSIN  DD *
  %CICSHLCK 'YOUR.CICS.REGION.LIST'
/*
```

**JCL Parameters Explained:**
- **ISFPARMS**: Required for SDSF REXX interface (batch mode only)
- **SYSEXEC**: Points to the REXX library containing CICSHLCK
- **SYSTSPRT**: Output destination for script results (screen in TSO, spool in batch)
- **SYSTSIN**: Contains the command to execute the REXX script

**Key Differences:**
- **Automatic detection**: If no input file specified, uses `YOURHLQ.CICS.<sysname>.REGIONS.LIST`
- **Explicit file**: Specify full dataset name as parameter
- **Output location**: TSO mode creates timestamped dataset; Batch mode uses SYSTSPRT only

## Output Format

### Output Sections

The script generates output with three main sections:

1. **Individual Region Status** - For each CICS region
2. **Quick Summary Table** - Overview of all regions
3. **Detailed Status Table** - Connection and status details
4. **Overall Statistics** - Totals and summary counts

### Sample Output

```
================================
   CICS REGION ERROR CHECKER
================================
Input file: YOURHLQ.CICS.SYSNAME.REGIONS.LIST
Output mode: TSO EXEC
Output dataset: YOURHLQ.CICS.HLTHCHCK.SYSNAME.D020626.T143022
  
Found 2 CICS region(s) to check
 
---------------------------------------------
# Processing CICS Region: CICSTSHD
---------------------------------------------
  
Found CICS region: CICSTSHD
Processing job output...
CICS Control Status: YES
DB2 Connection: NO
MQ Connection: YES
Error messages found: 21
 
---------------------------------------------
# Processing CICS Region: CICSTST6
---------------------------------------------
  
Found CICS region: CICSTST6
Processing job output...
CICS Control Status: YES
DB2 Connection: YES - SUCCESS
MQ Connection: YES - SUCCESS
Error messages found: 27
 
 
========================================
=        PROCESSING COMPLETE           =
========================================
 
========================================================================
                            QUICK SUMMARY
========================================================================
Region      Status      Errors  Notes
------------------------------------------------------------------------
CICSTSHD    HEALTHY     21      MQ only
CICSTST6    HEALTHY     27      DB2 + MQ
========================================================================


========================================================================
                          DETAILED STATUS
========================================================================
Region    CICS Ctrl  DB2 Conn   DB2 State  MQ Conn   MQ State   Errors
------------------------------------------------------------------------
CICSTSHD  YES        NO         N/A        YES       SUCCESS    21
CICSTST6  YES        YES        SUCCESS    YES       SUCCESS    27
========================================================================

Total regions checked: 2
Total errors found: 48
Healthy regions: 2/2
========================================
```

## Output Interpretation

### Status Indicators

| Symbol | Meaning |
|--------|---------|
| ✓ | Success - Component is operational |
| ✗ | Warning/Error - Component issue detected |
| - | Not Applicable - Feature not enabled |

### CICS Control Status
- **Control given**: CICS has completed initialization (DFHSI1517 found)
- **Control not confirmed**: DFHSI1517 message not found, CICS may still be initializing or failed to start

### DB2 Connection Status
- **Not enabled**: DB2CONN=NO in CICS startup parameters
- **Connected**: DB2CONN=YES and DFHDB2023I message found
- **Not completed**: DB2CONN=YES but DFHDB2023I message not found (connection issue)

### MQ Connection Status
- **Not enabled**: MQCONN=NO in CICS startup parameters
- **Connected**: MQCONN=YES and DFHMQ0307I message found
- **Not completed**: MQCONN=YES but DFHMQ0307I message not found (connection issue)

### Error Messages
- Complete DFH error messages are displayed with full text
- Multi-line messages are assembled into single complete messages
- Message count is provided for each region

## Troubleshooting

### Common Issues

#### Issue 1: "Error initializing SDSF REXX interface"
**Cause**: SDSF REXX interface not available or user lacks authorization
**Solution**: 
- Verify SDSF is installed and configured
- Check user has SDSF access via RACF/ACF2/Top Secret
- Contact security administrator to grant SDSF access

#### Issue 2: "Error executing SDSF ST command - RC: 8"
**Cause**: Authorization failure or SDSF configuration issue
**Solution**:
- Verify user has authority to execute SDSF commands
- Check ISFPARMS settings
- Ensure proper SDSF resource access in security system

#### Issue 3: "CICS region not found or not active"
**Cause**: CICS region is not running or name is incorrect
**Solution**:
- Verify CICS region name is correct (8 characters max)
- Check if CICS region is actually started (use SDSF DA or ST panel manually)
- Ensure region name in input file matches actual started task name

#### Issue 4: "Error allocating input file"
**Cause**: Input file dataset does not exist or user lacks read access
**Solution**:
- Verify dataset name is correct and fully qualified
- Check dataset exists using ISPF 3.4
- Verify read access to the dataset

#### Issue 5: "Number of DDs: DDNAME.0"
**Cause**: SDSF stem variables not populated correctly
**Solution**:
- This is handled in the script with datatype checking
- If persists, check SDSF REXX interface configuration

### Return Codes

| RC | Meaning |
|----|-----------|
| 0 | Successful execution - all regions processed |
| 4 | No regions found in input file |
| 8 | SDSF initialization error - SDSF not available or not authorized |
| 12 | Input file allocation error - dataset not found or not accessible |
| Other | System error - check SYSTSPRT output |

## Script Logic Flow

## Script Logic Flow

```
1. Detect execution environment (TSO or Batch)
2. If TSO: Set up timestamped output dataset
3. Read input file containing CICS region names
   - Auto-detect: YOURHLQ.CICS.<sysname>.REGIONS.LIST
   - Or use explicitly specified dataset
4. Initialize SDSF REXX interface
5. For each CICS region:
   a. Search SDSF ST panel for the region (started task)
   b. Access region's job output (JESMSGLG)
   c. Check for DFHSI1517 (CICS control verification)
   d. Scan for DB2CONN parameter and DFHDB2023I message
   e. Scan for MQCONN parameter and DFHMQ0307I message
   f. Count all DFHxxxxxE error messages across all output DDs
   g. Build status information for this region
6. Display individual region status during processing
7. Generate summary tables (Quick Summary and Detailed Status)
8. Terminate SDSF interface
9. Clean up and exit with appropriate return code
```

## Customization Options

### Add Custom Message Checks

To check for different CICS messages, add custom checks to monitor for additional messages:

```rexx
/* Add custom message check in process_cics_region subroutine */
if pos("DFHYOUR123", upper_line) > 0 then do
   custom_flag = 1
   call write_output "  Found custom message: " current_line
end
```

### Modify Error Pattern

To detect different error patterns (e.g., warnings), modify the error counting section:

```rexx
/* Current pattern: DFHxxxxxE only */
if pos("DFH", test_part) > 0 & pos(" E ", upper_line) > 0 then do
   error_count = error_count + 1
end

/* To also include warnings: DFHxxxxxW */
if pos("DFH", test_part) > 0 & (pos(" E ", upper_line) > 0 | pos(" W ", upper_line) > 0) then do
   error_count = error_count + 1
end
```

### Change Output Expiration

Modify the expiration days in `setup_tso_output` subroutine:

```rexx
/* Calculate expiration date - change 180 to desired number of days */
exp_date = get_expiration_date(180)
```

### Modify Output Dataset High-Level Qualifier (HLQ)

Update the HLQ in `setup_tso_output` subroutine:

```rexx
/* Build dataset name - replace YOURHLQ with your actual HLQ */
output_dsn = "YOUR.HLQ.CICS.HLTHCHCK." || sysname || ".D" || ,
             mmddyy || ".T" || hhmmss
```

## Best Practices

1. **Regular Execution**: Schedule this script to run periodically (hourly/daily) to monitor CICS health
2. **Alert Integration**: Integrate output with monitoring tools by parsing SYSTSPRT
3. **Archive Results**: Save output for historical analysis and trending
4. **Security**: Limit SDSF access to authorized personnel only
5. **Input File Maintenance**: Keep CICS region list current, remove decommissioned regions
6. **Comment Usage**: Use comments in input file to organize regions by environment (DEV/QA/PROD)

## Performance Considerations

- **Processing Time**: Approximately 5-15 seconds per CICS region depending on log size
- **SDSF Impact**: Minimal - read-only access to job output
- **Resource Usage**: Low CPU and memory footprint
- **Scalability**: Can process 50+ CICS regions in a single run

## Support and Maintenance

### Logs
- All output is written to SYSTSPRT
- Save output for troubleshooting: `//SYSTSPRT DD DSN=YOUR.OUTPUT.LOG,DISP=(NEW,CATLG)`

### Updates
When updating the script:
1. Test in development environment first
2. Verify with a single CICS region before batch processing
3. Review changes to SDSF interface or CICS message formats

### Version Control
Maintain version history in the script header:

```rexx
/* Version 1.0 - Initial release - 2026-02-05 */
/* Version 1.1 - Added MQ connection check - 2026-02-10 */
```

## Appendix: CICS Message Reference

### Key Messages Monitored

| Message | Description | Significance |
|---------|-------------|--------------|
| DFHSI1517 | Control is being given to CICS | CICS initialization complete |
| DFHDB2023I | DB2 connection established | DB2 connectivity confirmed |
| DFHMQ0307I | MQ connection established | MQ connectivity confirmed |
| DFHxxxxxE | Various error messages | System/application errors |

### Error Message Format

CICS error messages follow this pattern:
```
DFHppnnnS regionname messagetext.
```

Where:
- **DFH**: CICS message prefix
- **pp**: Product/component code (2 characters)
- **nnn**: Message number (3-5 characters)
- **S**: Severity (E=Error, W=Warning, I=Information)
- **regionname**: CICS region identifier
- **messagetext**: Descriptive message text ending with period

## Contact and Support

For issues or enhancements:
- Review troubleshooting section
- Check SDSF and CICS system logs
- Verify security authorizations
- Contact your z/OS system administrator

---

**Document Version**: 1.1  
**Last Updated**: February 6, 2026  
**Script Version**: CICSHLCK.rexx v1.1.0  
**Maintained by**: z/OS Systems Team

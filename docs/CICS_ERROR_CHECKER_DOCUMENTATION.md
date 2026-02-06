# CICS Error Checker - Documentation

## Overview

The CICS Error Checker is a REXX script designed to run on z/OS that automatically monitors and reports on CICS region health status. It accesses SDSF (System Display and Search Facility) to retrieve CICS job logs and performs comprehensive checks on multiple CICS regions.

## Purpose

This utility provides automated health monitoring for CICS regions by:
- Verifying CICS control status (startup completion)
- Checking DB2 connection status
- Checking MQ (WebSphere MQ) connection status
- Extracting and reporting all DFH error messages
- Processing multiple CICS regions from a single input file

## Features

### 1. CICS Control Verification
- Searches for message **DFHSI1517** which indicates "Control is being given to CICS"
- Confirms that the CICS region has fully initialized and is ready to process transactions

### 2. DB2 Connection Check
- Detects if DB2 connection is enabled (DB2CONN=YES or DB2CONN=NO)
- If enabled, verifies successful connection via message **DFHDB2023I**
- Reports connection status accordingly

### 3. MQ Connection Check
- Detects if MQ connection is enabled (MQCONN=YES or MQCONN=NO)
- If enabled, verifies successful connection via message **DFHMQ0307I**
- Reports connection status accordingly

### 4. Error Message Extraction
- Identifies all CICS error messages matching pattern **DFHxxxxxE** (where xxxxx is any 5 characters)
- Extracts complete multi-line error messages up to the terminating period (.)
- Displays full error text for troubleshooting

### 5. Batch Processing
- Processes multiple CICS regions from a single input file
- Provides individual reports for each region
- Summarizes total errors across all regions

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
Copy the REXX script into member **CICSERR** in your REXX library.

### Step 3: Create Input File
Create a sequential dataset containing CICS region names:

```jcl
//ALLOCINP JOB ...
//STEP1    EXEC PGM=IEFBR14
//REGLIST  DD DSN=YOUR.CICS.REGION.LIST,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),
//            UNIT=SYSDA
```

### Step 4: Populate Input File
Edit the input file and add your CICS region names (one per line):

```
CICSTEST
CIABS56A
CICSPROD
CICSDEV1
* Comments start with asterisk
CICSQA01
```

**Input File Format Rules:**
- One CICS region name per line
- Maximum 8 characters per region name
- Lines starting with `*` are treated as comments and skipped
- Blank lines are ignored
- Region names are automatically converted to uppercase

## Execution

### Method 1: Interactive TSO Execution

From TSO/ISPF command line:

```
TSO %CICSERR 'YOUR.CICS.REGION.LIST'
```

### Method 2: Batch JCL Execution

```jcl
//JOBNAME  JOB (ACCT),'CICS ERROR SCAN',
//         CLASS=A,
//         MSGCLASS=X,
//         NOTIFY=&SYSUID
//********************************************************************
//* CICS REGION ERROR CHECKER
//********************************************************************
//STEP1    EXEC PGM=IKJEFT01
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  %CICSERR 'YOUR.CICS.REGION.LIST'
/*
```

**JCL Parameters Explained:**
- **PGM=IKJEFT01**: TSO/E batch execution program
- **SYSEXEC**: Points to the REXX library containing CICSERR
- **SYSTSPRT**: Output destination for script results
- **SYSTSIN**: Contains the command to execute the REXX script

### Method 3: Single Region Check

To check only one CICS region without using an input file, modify the REXX script's first line:

Change:
```rexx
parse arg input_file
if input_file = "" then input_file = "CICS.REGIONS.LIST"
```

To:
```rexx
parse arg region_name
if region_name = "" then region_name = "CICSTEST"
```

Then execute:
```
TSO %CICSERR CICSTEST
```

## Output Format

### Sample Output

```
================================
CICS REGION ERROR CHECKER
================================
Input file: YOUR.CICS.REGION.LIST

Found 3 CICS region(s) to check

###############################################
# Processing CICS Region: CICSTEST
###############################################

Found CICS region: CICSTEST

--- Checking CICS Status ---

CICS Control:
  ✓ CICS has control (DFHSI1517 found)

DB2 Connection:
  ✓ DB2 Connection successful

MQ Connection:
  - NO MQ Connection for the region CICSTEST

--- Error Messages ---

DFHAM4835 E CICSTEST 874
Install of TDQUEUE CCSE failed because the queue has already been
defined to the system, and initialization is still in progress.

DFHAP0001 E CICSTEST An abend (code 0C4/AKEA) has occurred at offset
X'00007E3A' in module DFHXFP.

--- Summary for CICSTEST ---
Error messages found: 2

###############################################
# Processing CICS Region: CICSPROD
###############################################

Found CICS region: CICSPROD

--- Checking CICS Status ---

CICS Control:
  ✓ CICS has control (DFHSI1517 found)

DB2 Connection:
  ✓ DB2 Connection successful

MQ Connection:
  ✓ MQ Connection successful

--- Error Messages ---
  No DFH error messages found

--- Summary for CICSPROD ---
Error messages found: 0

========================================
ALL REGIONS PROCESSED
========================================
Total regions checked: 2
Total errors found across all regions: 2
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
|----|---------|
| 0 | Successful execution |
| 4 | No regions found in input file or region not active |
| 8 | SDSF authorization or configuration error |
| Other | System error - check SYSTSPRT output |

## Script Logic Flow

```
1. Read input file containing CICS region names
2. Initialize SDSF REXX interface
3. For each CICS region:
   a. Search SDSF for the region (started task)
   b. Access region's JESMSGLG output
   c. Check for DFHSI1517 (CICS control)
   d. Check for DB2CONN setting
   e. If DB2CONN=YES, check for DFHDB2023I
   f. Check for MQCONN setting
   g. If MQCONN=YES, check for DFHMQ0307I
   h. Scan all output DDs for DFHxxxxxE error messages
   i. Extract and display complete error messages
   j. Display summary for this region
4. Display overall summary for all regions
5. Terminate SDSF interface
```

## Customization Options

### Modify Checked Messages

To check for different CICS messages, modify the `check_cics_status` subroutine:

```rexx
/* Add custom message check */
if pos("DFHYOUR123", upper_line) > 0 then do
   custom_flag = 1
   say "  Found:" current_line
end
```

### Change Error Pattern

To detect different error patterns, modify the `process_all_lines` subroutine:

```rexx
/* Current pattern: DFHxxxxxE */
if pos(" E ", test_part) > 0 then do

/* To also include warnings: DFHxxxxxW */
if pos(" E ", test_part) > 0 | pos(" W ", test_part) > 0 then do
```

### Add Additional DDs

To search additional output DDs, modify the DD list:

```rexx
if curr_dd = "MSGUSR" | curr_dd = "JESMSGLG" | ,
   curr_dd = "SYSOUT" | curr_dd = "SYSPRINT" | ,
   curr_dd = "YOURCUSTDD" | ,    /* Add your DD here */
   pos("LOG", curr_dd) > 0 then do
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

**Document Version**: 1.0  
**Last Updated**: February 5, 2026  
**Maintained by**: z/OS Systems Team

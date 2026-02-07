# CICS Region Startup Verification and Health Monitor - Quick Reference Guide

## Quick Start

### 1. Prepare Input File
Create dataset `YOURHLQ.CICS.<sysname>.REGIONS.LIST` or `YOUR.CICS.REGION.LIST` with region names (columns 1-8):
```
CICSTSHD
CICSTST6
CICSDEV1
* CICSOLD (commented out)
CICSQA01
```

### 2. Execute in TSO (Automatic Input File Detection)
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)'
```
Output: Timestamped dataset + screen display

### 3. Execute in Batch
```jcl
//STEP1    EXEC PGM=IKJEFT01
//ISFPARMS DD DISP=SHR,DSN=HLQ.SISFPLIB
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  %CICSHLCK
/*
```

### 4. Review Output
- **TSO Mode**: Check timestamped dataset `YOURHLQ.CICS.HLTHCHCK.<sysname>.Dmmddyy.Thhmmss`
- **Batch Mode**: Check SYSTSPRT or SYSOUT

## What It Checks

| Check | Success Indicator | Status |
|-------|------------------|---------|
| CICS Control | DFHSI1517 present | YES = Healthy |
| DB2 Connection | DFHDB2023I message | Connected/Failed/Not Enabled |
| MQ Connection | DFHMQ0307I message | Connected/Failed/Not Enabled |
| Error Messages | DFHxxxxxE count | Number displayed |

## Common Commands

### TSO Interactive (Automatic Input File Detection)
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)'
```

### TSO Interactive (Explicit Input File)
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)' 'YOUR.CICS.REGION.LIST'
```

### Edit Input File
```
EDIT 'YOURHLQ.CICS.SYSNAME.REGIONS.LIST'
```

### Browse Output Dataset
```
BROWSE 'YOURHLQ.CICS.HLTHCHCK.SYSNAME.Dmmddyy.Thhmmss'
```

## Input File Format

Columns 1-8 contain region names (columns 9-80 ignored for TSO NUM):
```
CICSTSHD                                         00010000
CICSTST6                                         00020000
* Development region - commented out             00030000
CICSTST5                                         00040000
                                                 (blank lines ignored)
CICSUXJ1                                         00050000
```

Format rules:
- **Columns 1-8**: Region name (max 8 chars)
- **Column 1 = `*`**: Comment line (skipped)
- **Region names**: Auto-converted to uppercase

## Output Sections

```
1. Header
   ├─ Input file name
   ├─ Output mode (TSO EXEC or BATCH)
   └─ Total regions to check

2. Individual Region Reports (for each region)
   ├─ Region name
   ├─ CICS Control Status (YES/NO)
   ├─ DB2 Connection (Connected/Failed/Not Enabled)
   ├─ MQ Connection (Connected/Failed/Not Enabled)
   └─ Error count

3. Summary Tables
   ├─ Quick Summary (Status, Errors, Notes)
   └─ Detailed Status (All connection details)

4. Final Statistics
   ├─ Total regions checked
   ├─ Total errors found
   └─ Healthy regions count
```

## Troubleshooting Quick Fixes

| Error | Cause | Quick Fix |
|-------|-------|-----------|
| RC 8 on SDSF | SDSF not available | Ensure ISFPARMS DD in JCL; check SDSF authorization |
| RC 4 - No regions | Input file empty/missing | Verify input dataset name and content |
| RC 12 - Can't allocate | Input file not found | Check dataset exists (ISPF 3.4); check name |
| No output generated | Output allocation failed (TSO) | Check HLQ in setup_tso_output; verify can create datasets |
| Region not found | Region not running | Check region via SDSF ST panel; verify name spelling |

## Messages Explained

### DFHSI1517
✓ CICS region has started successfully

### DFHDB2023I
✓ DB2 connection established

### DFHMQ0307I
✓ MQ connection established

### DFHxxxxxE
⚠ Error message - requires investigation

## Return Codes

- **0** = Success - all regions processed
- **4** = No regions found in input file
- **8** = SDSF initialization error
- **12** = Input file allocation error

## Example Output

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

CICS Control Status: YES
DB2 Connection: NO
MQ Connection: YES
Error messages found: 21

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
```

## Need More Help?

See full documentation: [CICS_ERROR_CHECKER_DOCUMENTATION.md](CICS_ERROR_CHECKER_DOCUMENTATION.md)

**Document Version**: 1.1  
**Last Updated**: February 6, 2026  
**Script Version**: CICSHLCK.rexx v1.1.0

# CICS Error Checker - Quick Reference Guide

## Quick Start

### 1. Prepare Input File
Create dataset `YOUR.CICS.REGION.LIST` with region names:
```
CICSTEST
CICSPROD
CICSDEV1
```

### 2. Submit JCL
```jcl
//CHKCICS  JOB (ACCT),'CHECK CICS',MSGCLASS=X
//STEP1    EXEC PGM=IKJEFT01
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  %CICSERR 'YOUR.CICS.REGION.LIST'
/*
```

### 3. Review Output
Check SYSTSPRT for results

## What It Checks

| Check | Success Indicator | Failure Indicator |
|-------|------------------|-------------------|
| CICS Control | ✓ CICS has control | ✗ Control not confirmed |
| DB2 Connection | ✓ DB2 Connected | ✗ Not completed / - Not enabled |
| MQ Connection | ✓ MQ Connected | ✗ Not completed / - Not enabled |
| Error Messages | Lists all DFHxxxxxE errors | Shows count |

## Common Commands

### TSO Interactive
```
TSO %CICSERR 'YOUR.CICS.REGION.LIST'
```

### Edit Input File
```
EDIT 'YOUR.CICS.REGION.LIST'
```

### View Output
```
BROWSE SYSTSPRT
```

## Input File Format

```
CICSTEST         ← Region name (max 8 chars)
CICSPROD         ← Another region
* CICSOLD        ← Commented out (skip)
CICSDEV1         ← Active region
                 ← Blank lines ignored
```

## Output Sections

```
1. Header
   ├─ Input file name
   └─ Total regions to check

2. Per Region Report
   ├─ CICS Control Status
   ├─ DB2 Connection Status
   ├─ MQ Connection Status
   ├─ Error Messages (if any)
   └─ Summary

3. Final Summary
   ├─ Total regions checked
   └─ Total errors found
```

## Troubleshooting Quick Fixes

| Error | Quick Fix |
|-------|-----------|
| RC 8 on SDSF | Check SDSF authorization |
| Region not found | Verify region is running (SDSF DA) |
| Can't allocate file | Check dataset name and permissions |
| No output | Check SYSTSPRT allocation |

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

- **0** = Success
- **4** = Region not found/active
- **8** = SDSF authorization error

## Example Output

```
###############################################
# Processing CICS Region: CICSTEST
###############################################

Found CICS region: CICSTEST

CICS Control:
  ✓ CICS has control (DFHSI1517 found)

DB2 Connection:
  ✓ DB2 Connection successful

MQ Connection:
  - NO MQ Connection for the region CICSTEST

--- Error Messages ---

DFHAM4835 E CICSTEST 874
Install of TDQUEUE CCSE failed.

--- Summary for CICSTEST ---
Error messages found: 1
```

## Need More Help?

See full documentation: `CICS_ERROR_CHECKER_DOCUMENTATION.md`

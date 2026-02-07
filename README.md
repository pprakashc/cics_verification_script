# CICS Region Startup Verification and Health Monitor

A z/OS REXX utility for automated verification of CICS region startup and health checking. This tool accesses SDSF to retrieve CICS job logs and performs comprehensive status checks including CICS control verification, DB2/MQ connection status, and DFH error message extraction.

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Platform](https://img.shields.io/badge/platform-z%2FOS-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## Features

- ✅ **CICS Control Verification** - Confirms CICS startup completion (DFHSI1517)
- ✅ **DB2 Connection Monitoring** - Checks DB2CONN status and connection messages
- ✅ **MQ Connection Monitoring** - Verifies MQ connectivity (DFHMQ0307I)
- ✅ **Error Message Extraction** - Identifies and extracts all DFHxxxxxE error messages
- ✅ **Batch Processing** - Process multiple CICS regions from a single input file
- ✅ **Summary Tables** - Clean tabular output with quick summary and detailed status
- ✅ **Multi-line Message Support** - Properly assembles error messages spanning multiple lines

## Quick Start

### 1. Upload to z/OS

Upload `CICSHLCK.rexx` to a REXX library on your z/OS system:

```jcl
//UPLOAD   JOB ...
//STEP1    EXEC PGM=IEFBR14
//REXXLIB  DD DSN=YOUR.REXX.LIBRARY(CICSHLCK),
//            DISP=SHR
```

### 2. Create Input File

Create a dataset containing CICS region names (one per line, columns 1-8):

```
CICSTEST
CICSPRD
* Development regions
CICSDEV1
CICSQA01
```

### 3. Run the Script

**Option A: TSO Interactive (Automatic Input File Detection)**
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)'
```
The script will automatically detect the input file using the system name: `YOURHLQ.CICS.<sysname>.REGIONS.LIST`

**Option B: TSO Interactive (Explicit Input File)**
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)' 'YOUR.CICS.REGION.LIST'
```

**Option C: Batch JCL**
```jcl
//CHKCICS  JOB (ACCT),'CICS HEALTH CHECK',MSGCLASS=X
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
  %CICSHLCK YOUR.REGION.LIST
```

## Sample Output

```
========================================================================
                            QUICK SUMMARY
========================================================================
Region      Status      Errors  Notes
------------------------------------------------------------------------
CICSREG1    HEALTHY     21      MQ only
CICSREG6    HEALTHY     27      DB2 + MQ
CICSR5      HEALTHY     16      MQ only
CICSR1      HEALTHY     13      DB2 + MQ
========================================================================


===============================================================================
                          DETAILED STATUS
===============================================================================
Region      CICS Ctrl   DB2 Conn    DB2 State   MQ Conn     MQ State    Errors
-------------------------------------------------------------------------------
CICSREG1    YES         NO          N/A         YES         SUCCESS     21
CICSREG6    YES         YES         SUCCESS     YES         SUCCESS     27
CICSR5      YES         NO          N/A         YES         SUCCESS     16
CICSR1      YES         YES         SUCCESS     YES         SUCCESS     13
===============================================================================
```

## Requirements

### System Requirements
- z/OS operating system
- TSO/E REXX environment
- SDSF (System Display and Search Facility)
- CICS Transaction Server

### Authorization Requirements
- SDSF access authorization
- Permission to view started task (STC) output
- Authority to browse job logs via SDSF REXX interface

## Installation

1. **Create REXX Library**
```jcl
//ALLOCPDS JOB ...
//STEP1    EXEC PGM=IEFBR14
//REXXLIB  DD DSN=YOUR.REXX.LIBRARY,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(10,5,10)),
//            DCB=(RECFM=VB,LRECL=259,BLKSIZE=27648),
//            UNIT=SYSDA
```

2. **Upload Script**
   - Copy `CICSHLCK.rexx` to member `CICSHLCK` in your REXX library

3. **Create Input File**
```jcl
//ALLOCINP JOB ...
//STEP1    EXEC PGM=IEFBR14
//REGLIST  DD DSN=YOURHLQ.CICS.<sysname>.REGIONS.LIST,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=800),
//            UNIT=SYSDA
```

4. **Populate Input File**
   - Edit and add your CICS region names (columns 1-8 only, one per line)
   - Supports comments with `*` in column 1
   - Blank lines are ignored

## Output Files

**TSO Mode Output**
- Dataset: `YOURHLQ.CICS.HLTHCHCK.<sysname>.Dmmddyy.Thhmmss`
- DCB: RECFM=FBA, LRECL=133, BLKSIZE=27930
- Expiration: 180 days
- Contains complete report with summary and detailed tables

*Note: Replace `YOURHLQ` with your organization's high-level qualifier and `<sysname>` is automatically populated from the &SYSNAME system symbol*

## What It Checks

| Check | Parameter/Message | Success Indicator | Details |
|-------|------------------|-------------------|---------|
| CICS Control | DFHSI1517 | ✓ YES | Control is being given to CICS (initialization complete) |
| DB2 Connection | DB2CONN parameter | ✓ Connected | DFHDB2023I message indicates connection established |
| DB2 Status | DFHDB2023I | ✓ SUCCESS | Connection established successfully |
| MQ Connection | MQCONN parameter | ✓ Connected | DFHMQ0307I message indicates connection established |
| MQ Status | DFHMQ0307I | ✓ SUCCESS | Connection established successfully |
| Error Messages | DFHxxxxxE pattern | Count displayed | All CICS error messages counted and reported |

## Input File Format

- **Location**: `YOURHLQ.CICS.<sysname>.REGIONS.LIST` (auto-detected in TSO mode)
- **One region name per line** (CICS region must be 8 characters or less)
- **Columns 1-8 only** are read (supports TSO NUM ON line numbering in columns 9-80)
- **Lines starting with `*`** are treated as comments and skipped
- **Blank lines** are ignored
- **Region names** are automatically converted to uppercase

Example input file (with TSO line numbers):
```
CICSTSHD                                         00010000
CICSTST6                                         00020000
* Development region - commented out             00030000
CICSTST5                                         00040000
CICSUXJ1                                         00050000
```

## Status Codes

The script categorizes each region into one of these statuses:

- **HEALTHY** - All configured connections working, CICS has control
- **WARNING** - CICS has control but DB2/MQ connection failed
- **ERROR** - CICS control not given
- **NOT FOUND** - Region not active or not found in SDSF

## Monitored Messages

| Message | Description | Significance |
|---------|-------------|--------------|
| DFHSI1517 | Control is being given to CICS | CICS initialization complete |
| DFHDB2023I | DB2 connection established | DB2 connectivity confirmed |
| DFHMQ0307I | MQ connection established | MQ connectivity confirmed |
| DFHxxxxxE | Various error messages | System/application errors |

## Troubleshooting

### Common Issues

**Error: "Error executing SDSF ST command - RC: 8"**
- **Cause**: SDSF initialization failed or SDSF not available
- **Solution**: Ensure SDSF REXX interface is enabled in your z/OS system. Contact system administrator if needed.

**Error: "CICS region not found or not active"**
- **Cause**: Region not running as a started task (STC) in SDSF, or incorrect name format
- **Solution**: Verify region name (must be 8 characters or less) and confirm it's running as a started task. Check SDSF ST panel.

**Error: "Error allocating input file"**
- **Cause**: Input file doesn't exist, not cataloged, or no read access
- **Solution**: Verify the input dataset exists and you have read access. Check DCB parameters match the dataset.

**No output generated in TSO mode**
- **Cause**: Output dataset allocation failed, falling back to screen output only
- **Solution**: Check that YOURHLQ is replaced with actual high-level qualifier. Ensure datasets can be created in SYSALLDA.

## Return Codes

| RC | Meaning |
|----|---------|
| 0 | Successful execution |
| 4 | No regions found in input file |
| 8 | SDSF initialization error |
| 12 | Input file allocation error |

## Customization

### Add Custom Message Checks
Edit the `check_cics_status` subroutine to check for additional CICS messages:

```rexx
/* Add custom message check */
if pos("DFHYOUR123", upper_line) > 0 then do
   custom_flag = 1
   call write_output "  Found custom message: " current_line
end
```

### Modify Error Pattern
To also detect warnings (DFHxxxxxW), modify the error counting section:

```rexx
/* Include both errors and warnings */
if pos("DFH", test_part) > 0 & (pos("E", upper_line) > 0 | pos("W", upper_line) > 0) then do
   error_count = error_count + 1
end
```

### Change Output Dataset Expiration
Modify the `get_expiration_date` call in `setup_tso_output`:

```rexx
/* Calculate expiration date - change 180 to desired number of days */
exp_date = get_expiration_date(180)
```

### Modify High-Level Qualifier (HLQ)
Update the output dataset prefix in `setup_tso_output`:

```rexx
/* Build dataset name - replace YOURHLQ with your actual HLQ */
output_dsn = "YOUR.HLQ.CICS.HLTHCHCK." || sysname || ".D" || ,
             mmddyy || ".T" || hhmmss
```

## Documentation

- [Full Documentation](docs/CICS_ERROR_CHECKER_DOCUMENTATION.md)
- [Quick Reference Guide](docs/CICS_ERROR_CHECKER_QUICK_REFERENCE.md)
- [Sample JCL](examples/sample.jcl)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Created with ❤️ for the mainframe community

## Acknowledgments

- Built for z/OS mainframe systems
- Uses SDSF REXX interface for job log access
- Designed for CICS system programmers and operators

## Version History

- **1.1.0** (2026-02-06)
  - CICS region startup verification with automatic input file detection
  - Support for both TSO automated dataset output and batch printing
  - Timestamped output with LPAR (system name) identification
  - Support for 1-8 character region names
  - DB2 and MQ connection monitoring with status tracking
  - Error message counting with multi-line message support
  - Summary and detailed status tables
  - Column 1-8 input reading with support for TSO line numbers

- **1.0.0** (2026-02-05)
  - Initial release
  - CICS control checking (DFHSI1517)
  - DB2/MQ connection monitoring
  - Error message extraction
  - Batch processing support
  - Summary tables

---

**Need Help?** Check the [documentation](docs/) or open an issue on GitHub.

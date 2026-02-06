# CICS Error Checker

A z/OS REXX utility for automated monitoring and health checking of CICS regions. This tool accesses SDSF to retrieve CICS job logs and performs comprehensive status checks including CICS control verification, DB2/MQ connection status, and DFH error message extraction.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
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

Upload `CICSERR.rexx` to a REXX library on your z/OS system:

```jcl
//UPLOAD   JOB ...
//STEP1    EXEC PGM=IEFBR14
//REXXLIB  DD DSN=YOUR.REXX.LIBRARY(CICSERR),
//            DISP=SHR
```

### 2. Create Input File

Create a dataset containing CICS region names (one per line):

```
CICSTEST
CICSPROD
CICSDEV1
* CICSOLD (commented out)
CICSQA01
```

### 3. Run the Script

**Option A: TSO Interactive**
```
TSO %CICSERR 'YOUR.CICS.REGION.LIST'
```

**Option B: Batch JCL**
```jcl
//CHKCICS  JOB (ACCT),'CHECK CICS',MSGCLASS=X
//STEP1    EXEC PGM=IKJEFT01
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  %CICSERR 'YOUR.CICS.REGION.LIST'
/*
```

## Sample Output

```
========================================================================
                            QUICK SUMMARY
========================================================================
Region      Status      Errors  Notes
------------------------------------------------------------------------
CICSTSHD    HEALTHY     21      MQ only
CICSTST6    HEALTHY     27      DB2 + MQ
CICSTST5    HEALTHY     16      MQ only
CICSUXJ1    HEALTHY     13      DB2 + MQ
========================================================================


========================================================================
                          DETAILED STATUS
========================================================================
Region      CICS Ctrl   DB2 Conn    DB2 State   MQ Conn     MQ State    Errors
------------------------------------------------------------------------
CICSTSHD    YES         NO          N/A         YES         SUCCESS     21
CICSTST6    YES         YES         SUCCESS     YES         SUCCESS     27
CICSTST5    YES         NO          N/A         YES         SUCCESS     16
CICSUXJ1    YES         YES         SUCCESS     YES         SUCCESS     13
========================================================================
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
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),
//            UNIT=SYSDA
```

2. **Upload Script**
   - Copy `CICSERR.rexx` to member `CICSERR` in your REXX library

3. **Create Input File**
```jcl
//ALLOCINP JOB ...
//STEP1    EXEC PGM=IEFBR14
//REGLIST  DD DSN=YOUR.CICS.REGION.LIST,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),
//            UNIT=SYSDA
```

4. **Populate Input File**
   - Edit and add your CICS region names

## What It Checks

| Check | Success Indicator | Failure Indicator |
|-------|------------------|-------------------|
| CICS Control | ✓ CICS has control | ✗ Control not confirmed |
| DB2 Connection | ✓ DB2 Connected | ✗ Not completed / - Not enabled |
| MQ Connection | ✓ MQ Connected | ✗ Not completed / - Not enabled |
| Error Messages | Lists all DFHxxxxxE errors | Shows count |

## Input File Format

- One CICS region name per line
- Maximum 8 characters per region name
- Lines starting with `*` are comments (skipped)
- Blank lines are ignored
- Region names are automatically converted to uppercase

Example:
```
CICSTEST
CICSPROD
* Development regions
CICSDEV1
CICSDEV2

CICSQA01
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
- **Cause**: SDSF authorization issue
- **Solution**: Contact security administrator to grant SDSF access

**Error: "CICS region not found or not active"**
- **Cause**: Region not running or incorrect name
- **Solution**: Verify region name and check if it's started

**Error: "Error allocating input file"**
- **Cause**: Input file doesn't exist or no read access
- **Solution**: Check dataset name and permissions

## Return Codes

| RC | Meaning |
|----|---------|
| 0 | Successful execution |
| 4 | No regions found in input file or region not active |
| 8 | SDSF authorization or configuration error |

## Customization

### Add Custom Message Checks

Edit the `check_cics_status` subroutine to check for additional messages:

```rexx
/* Add custom message check */
if pos("DFHYOUR123", upper_line) > 0 then do
   custom_flag = 1
   say "  Found:" current_line
end
```

### Modify Error Pattern

To also detect warnings (DFHxxxxxW), modify `process_all_lines`:

```rexx
/* Include both errors and warnings */
if pos(" E ", test_part) > 0 | pos(" W ", test_part) > 0 then do
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

- **1.0.0** (2026-02-05)
  - Initial release
  - CICS control checking
  - DB2/MQ connection monitoring
  - Error message extraction
  - Batch processing support
  - Summary tables

---

**Need Help?** Check the [documentation](docs/) or open an issue on GitHub.

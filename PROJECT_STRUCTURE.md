# CICS Region Startup Verification and Health Monitor - Project Structure

```
cics_verification_script/
├── .github/
│   └── workflows/          # GitHub Actions (future automation)
├── docs/
│   ├── CICS_ERROR_CHECKER_DOCUMENTATION.md    # Complete technical documentation
│   └── CICS_ERROR_CHECKER_QUICK_REFERENCE.md  # Quick reference guide
├── examples/
│   ├── sample.jcl          # Sample JCL for batch execution
│   └── sample-regions.txt  # Sample region list file
├── .gitignore              # Git ignore file
├── CHANGELOG.md            # Version history and changes
├── CICSHLCK.rexx           # Main REXX script (CICS health check)
├── CONTRIBUTING.md         # Contribution guidelines
├── GITHUB_SETUP.md         # GitHub repository setup instructions
├── LICENSE                 # MIT License
├── PACKAGE_SUMMARY.md      # Package summary
├── PROJECT_STRUCTURE.md    # This file
├── README.md               # Project overview and quick start
└── SETUP.md                # Setup and configuration guide
```

## File Descriptions

### Root Files

**CICSHLCK.rexx**
- Main REXX script for CICS region startup verification and health monitoring
- Performs automated CICS startup verification, DB2/MQ connection checks, and error message counting
- Upload this to your z/OS REXX library
- Supports both TSO execution (with timestamped output datasets) and batch JCL mode
- Automatically detects input file (`YOURHLQ.CICS.<sysname>.REGIONS.LIST`) or accepts explicit dataset name

**README.md**
- Project overview and features
- Quick start guide with execution examples
- Installation instructions
- Input/output file specifications
- Troubleshooting guide
- Version history

**SETUP.md**
- Detailed setup and configuration instructions for z/OS
- Environment configuration steps

**GITHUB_SETUP.md**
- Instructions for GitHub repository setup

**PACKAGE_SUMMARY.md**
- Summary of package contents and capabilities

**LICENSE**
- MIT License for the project

**CHANGELOG.md**
- Version history
- List of changes in each release

**CONTRIBUTING.md**
- Guidelines for contributors
- Code style standards
- Pull request process

**.gitignore**
- Files and directories to exclude from Git

### docs/

**CICS_ERROR_CHECKER_DOCUMENTATION.md**
- Complete technical documentation
- Detailed installation instructions
- Comprehensive usage guide with examples
- Troubleshooting section
- Customization options for message patterns and output

**CICS_ERROR_CHECKER_QUICK_REFERENCE.md**
- Quick reference for common tasks
- TSO and batch execution examples
- Output format interpretation
- Quick troubleshooting tips

### examples/

**sample.jcl**
- Sample JCL for batch execution
- ESFPARMS configuration for SDSF access
- Ready-to-customize with your dataset names and REXX library locations

**sample-regions.txt**
- Example CICS region input file format
- Shows how to format region names (columns 1-8)
- Demonstrates comment syntax with `*`
- Includes example of TSO line numbering support

## Script Features

**CICSHLCK.rexx** provides:
- **CICS Control Status**: Verifies CICS initialization (DFHSI1517 message)
- **DB2 Connection Monitoring**: Checks DB2CONN parameter and connection status
- **MQ Connection Monitoring**: Monitors MQCONN parameter and connection status
- **Error Message Counting**: Identifies and counts DFHxxxxxE error messages
- **Multi-line Message Support**: Properly assembles error messages spanning multiple lines
- **Automatic Input File Detection**: Uses system name to build input file DSN in TSO mode
- **Timestamped Output**: TSO mode generates timestamped output datasets with LPAR identification
- **Batch Processing**: Processes multiple CICS regions in a single execution
- **Summary Tables**: Generates quick summary and detailed status tables
- **Return Codes**: Standard return codes for integration with automation tools

### .github/

**workflows/**
- Placeholder for GitHub Actions workflows
- Future: automated documentation generation
- Future: syntax checking

## Usage

### Quick Start

1. Clone this repository
2. Upload `CICSHLCK.rexx` to your z/OS REXX library as member `CICSHLCK`
3. Create your input file (`YOURHLQ.CICS.<sysname>.REGIONS.LIST`) with CICS region names
4. Execute via TSO or batch JCL

### Execution Methods

**TSO - Automatic Input File Detection**
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)'
```
Automatically detects input file using system name.

**TSO - Explicit Input File**
```
EX 'YOUR.REXX.LIBRARY(CICSHLCK)' 'YOUR.CICS.REGION.LIST'
```

**Batch - Using JCL**
```jcl
//STEP1    EXEC PGM=IKJEFT01
//ISFPARMS DD DISP=SHR,DSN=HLQ.SISFPLIB
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSIN  DD *
  %CICSHLCK
/*
```

### Output

- **TSO Mode**: Timestamped dataset (`YOURHLQ.CICS.HLTHCHCK.<sysname>.Dmmddyy.Thhmmss`) + screen output
- **Batch Mode**: Screen output (SYSOUT)
- Both modes contain: Summary table, detailed status table, and overall statistics

For detailed instructions, see [README.md](README.md) and [docs/CICS_ERROR_CHECKER_DOCUMENTATION.md](docs/CICS_ERROR_CHECKER_DOCUMENTATION.md).

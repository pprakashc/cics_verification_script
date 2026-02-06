# CICS Error Checker - Setup Guide

This guide will walk you through setting up the CICS Error Checker on your z/OS system.

## Prerequisites

Before you begin, ensure you have:

- [ ] Access to a z/OS system with TSO/ISPF
- [ ] SDSF access authorization
- [ ] Permission to create datasets
- [ ] Access to CICS regions you want to monitor
- [ ] A text editor or file transfer tool (IND$FILE, FTP, etc.)

## Step-by-Step Installation

### Step 1: Download from GitHub

Clone or download this repository to your local machine:

```bash
git clone https://github.com/yourusername/cics-error-checker.git
cd cics-error-checker
```

### Step 2: Create REXX Library on z/OS

Submit this JCL to create a REXX library:

```jcl
//ALLOCPDS JOB (ACCT),'CREATE REXX LIB',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC PGM=IEFBR14
//REXXLIB  DD DSN=YOUR.REXX.LIBRARY,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(10,5,10)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),
//            UNIT=SYSDA
```

**Replace:** `YOUR.REXX.LIBRARY` with your desired dataset name

### Step 3: Upload CICSERR.rexx

Upload the `CICSERR.rexx` file to member `CICSERR` in your REXX library.

**Using IND$FILE from TSO:**
```
IND$FILE PUT CICSERR.rexx YOUR.REXX.LIBRARY(CICSERR) ASCII CRLF
```

**Using FTP:**
```
ftp your.zos.system
> ascii
> put CICSERR.rexx 'YOUR.REXX.LIBRARY(CICSERR)'
> quit
```

**Using ISPF Edit:**
1. From ISPF 3.4, browse to `YOUR.REXX.LIBRARY`
2. Type `E` next to `CICSERR` (or create new member)
3. Copy/paste the contents of `CICSERR.rexx`
4. Save with `F3`

### Step 4: Create Region List Dataset

Submit this JCL to create the input file:

```jcl
//ALLOCINP JOB (ACCT),'CREATE INPUT',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC PGM=IEFBR14
//REGLIST  DD DSN=YOUR.CICS.REGION.LIST,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),
//            UNIT=SYSDA
```

**Replace:** `YOUR.CICS.REGION.LIST` with your desired dataset name

### Step 5: Populate Region List

Edit `YOUR.CICS.REGION.LIST` and add your CICS region names:

```
CICSTEST
CICSPROD
CICSDEV1
* Add your regions here (one per line)
```

**Using ISPF Edit:**
1. From ISPF 3.4, find `YOUR.CICS.REGION.LIST`
2. Type `E` to edit
3. Add region names (one per line)
4. Save with `F3`

### Step 6: Test the Script

Run a test from TSO:

```
TSO %CICSERR 'YOUR.CICS.REGION.LIST'
```

Or submit the sample JCL (customize `examples/sample.jcl` first):

```jcl
//CHKCICS  JOB (ACCT),'TEST CICSERR',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1    EXEC PGM=IKJEFT01
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  %CICSERR 'YOUR.CICS.REGION.LIST'
/*
```

### Step 7: Verify Output

Check the output (SYSTSPRT) for:

- ✅ Region discovery messages
- ✅ Status checks for each region
- ✅ Summary tables at the end
- ✅ No error messages

## Common Setup Issues

### Issue: "CICSERR not found"

**Cause:** REXX library not in SYSPROC or SYSEXEC concatenation

**Solution:** Add the library to your JCL:
```jcl
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
```

### Issue: "Error allocating input file"

**Cause:** Dataset name incorrect or doesn't exist

**Solution:** 
1. Verify dataset exists: ISPF 3.4
2. Check spelling in script call
3. Ensure you have read access

### Issue: "Error initializing SDSF REXX interface"

**Cause:** No SDSF authorization

**Solution:** Contact your security administrator to grant SDSF access

## Next Steps

After successful installation:

1. **Schedule Regular Runs**
   - Set up batch job to run hourly/daily
   - Save output to datasets for historical tracking

2. **Customize for Your Environment**
   - Add more CICS regions to input file
   - Modify error patterns if needed
   - Add custom message checks

3. **Integrate with Monitoring**
   - Parse output for alerts
   - Send notifications on errors
   - Create dashboards

## Getting Help

- Check the [Full Documentation](docs/CICS_ERROR_CHECKER_DOCUMENTATION.md)
- Review [Troubleshooting Guide](docs/CICS_ERROR_CHECKER_DOCUMENTATION.md#troubleshooting)
- Open an issue on GitHub

---

**Setup complete!** You're ready to monitor your CICS regions. 🎉

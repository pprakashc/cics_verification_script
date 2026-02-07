//CHKCICS  JOB (ACCT),'CICS ERROR CHECK',
//             CLASS=A,
//             MSGCLASS=X,
//             NOTIFY=&SYSUID
//********************************************************************
//* CICS REGION ERROR CHECKER - BATCH EXECUTION
//*
//* This JCL executes the CICS Error Checker REXX script in batch mode
//* to monitor multiple CICS regions for health and error messages.
//*
//* Modify the following:
//*   - YOUR.REXX.LIBRARY: Dataset containing CICSERR member
//*   - YOUR.CICS.REGION.LIST: Dataset containing region names
//*   - YOUR.OUTPUT.LOG: Optional - save output to dataset
//********************************************************************
//STEP1    EXEC PGM=IKJEFT01
//ISFPARMS DD DISP=SHR,DSN=HLQ.SISFPLIB 
//SYSEXEC  DD DISP=SHR,DSN=YOUR.REXX.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  %CICSERR YOUR.CICS.REGION.LIST  /* lib optional
/*

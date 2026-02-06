# Changelog

All notable changes to the CICS Error Checker project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-05

### Added
- Initial release of CICS Error Checker
- CICS control status verification (DFHSI1517 message)
- DB2 connection monitoring (DB2CONN parameter and DFHDB2023I message)
- MQ connection monitoring (MQCONN parameter and DFHMQ0307I message)
- DFH error message extraction (DFHxxxxxE pattern)
- Multi-line error message support
- Batch processing from input file containing multiple CICS regions
- Quick Summary table showing overall health status
- Detailed Status table with all connection details
- Comprehensive documentation and quick reference guide
- Sample JCL for batch execution
- Error handling for missing regions and SDSF issues

### Features
- Process multiple CICS regions from a single input file
- Skip commented lines (starting with *) in input file
- Automatic uppercase conversion of region names
- Health status categorization (HEALTHY, WARNING, ERROR, NOT FOUND)
- Total error count across all regions
- Individual region detailed reports
- Clean tabular output with proper column alignment

### Documentation
- Complete installation guide
- Usage instructions
- Troubleshooting section
- Customization examples
- Return code reference

## [Unreleased]

### Planned Features
- Email notification support
- HTML output format
- Integration with monitoring tools
- Historical trending support
- Custom message pattern configuration
- Region exclusion list
- Scheduled execution framework

---

[1.0.0]: https://github.com/yourusername/cics-error-checker/releases/tag/v1.0.0

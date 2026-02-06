# CICS Error Checker - Project Structure

```
cics-error-checker/
├── .github/
│   └── workflows/          # GitHub Actions (future automation)
├── docs/
│   ├── CICS_ERROR_CHECKER_DOCUMENTATION.md    # Complete documentation
│   └── CICS_ERROR_CHECKER_QUICK_REFERENCE.md  # Quick reference guide
├── examples/
│   ├── sample.jcl          # Sample JCL for batch execution
│   └── sample-regions.txt  # Sample region list file
├── .gitignore              # Git ignore file
├── CHANGELOG.md            # Version history and changes
├── CICSERR.rexx            # Main REXX script
├── CONTRIBUTING.md         # Contribution guidelines
├── LICENSE                 # MIT License
├── PROJECT_STRUCTURE.md    # This file
└── README.md               # Project overview and quick start
```

## File Descriptions

### Root Files

**CICSERR.rexx**
- Main REXX script that performs CICS health checking
- Upload this to your z/OS REXX library

**README.md**
- Project overview
- Quick start guide
- Feature list
- Basic usage instructions

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
- Installation instructions
- Detailed usage guide
- Troubleshooting
- Customization options

**CICS_ERROR_CHECKER_QUICK_REFERENCE.md**
- Quick reference for common tasks
- Command examples
- Output interpretation
- Quick troubleshooting

### examples/

**sample.jcl**
- Sample JCL for batch execution
- Ready to customize with your dataset names

**sample-regions.txt**
- Example input file format
- Shows how to organize CICS region names

### .github/

**workflows/**
- Placeholder for GitHub Actions workflows
- Future: automated documentation generation
- Future: syntax checking

## Usage

1. Clone this repository
2. Upload `CICSERR.rexx` to your z/OS system
3. Customize `examples/sample.jcl` with your dataset names
4. Create your region list based on `examples/sample-regions.txt`
5. Run the script!

For detailed instructions, see `README.md` and `docs/CICS_ERROR_CHECKER_DOCUMENTATION.md`.

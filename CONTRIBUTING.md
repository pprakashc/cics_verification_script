# Contributing to CICS Error Checker

Thank you for your interest in contributing to the CICS Error Checker project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- z/OS environment details (CICS version, z/OS version, SDSF version)
- Sample output (if applicable)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please create an issue with:
- A clear description of the enhancement
- Use case and business value
- Implementation ideas (optional)

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add comments for complex logic
   - Update documentation as needed

4. **Test your changes**
   - Test on your z/OS environment
   - Verify with multiple CICS regions
   - Check edge cases (missing regions, connection failures, etc.)

5. **Commit your changes**
   ```bash
   git commit -m "Add feature: description of your changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Provide a clear description of the changes
   - Reference any related issues
   - Include test results

## Code Style Guidelines

### REXX Coding Standards

- Use meaningful variable names
- Add comments for complex logic
- Keep procedures focused and single-purpose
- Handle error conditions gracefully
- Use consistent indentation (3 spaces)

### Example:
```rexx
/* Good: Clear variable name and comments */
if cics_control = 1 then do
   /* CICS has successfully initialized */
   say "CICS control confirmed"
end

/* Avoid: Unclear variables and no comments */
if cc = 1 then do
   say "OK"
end
```

## Documentation

When adding features:
- Update README.md if user-facing
- Update documentation files in `docs/`
- Add examples if applicable
- Update CHANGELOG.md

## Testing

Before submitting:
- Test with at least 3 different CICS regions
- Test with missing/inactive regions
- Test with DB2-only, MQ-only, and both configurations
- Test with regions that have errors
- Verify output formatting

## Questions?

Feel free to open an issue for questions or clarifications.

## Code of Conduct

Be respectful and constructive in all interactions. We're all here to make mainframe monitoring better!

Thank you for contributing! 🎉

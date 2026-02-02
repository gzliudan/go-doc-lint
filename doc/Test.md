# Testing Guide for go-doc-lint

[中文版](Test_cn.md) | English

This document describes the comprehensive test suites for both the Bash and PowerShell implementations of the go-doc-lint tool.

See also:

- [Architecture Guide](ARCHITECTURE.md) - Design overview and implementation details
- [Troubleshooting Guide](TROUBLESHOOTING.md) - Advanced debugging and problem-solving

## Test Structure

Test scripts are located in the **root directory**, while test data is in the `fixtures/` directory:

```text
go-doc-lint/                # Root directory
├── test.sh                # Bash test suite
├── test.ps1               # PowerShell test suite
├── Test.md                # This file
└── fixtures/              # Test data directory
    ├── valid/             # Correctly documented files
    ├── invalid/           # Mismatched documentation
    ├── mixed/             # Mixed valid/invalid cases
    ├── utils/             # Utility test files
    ├── empty/             # Empty directory for testing
    └── deep/              # Deep nested structure
        └── nested/
            └── directory/
                └── structure/
```

Test files are organized by category:

- **valid/** - Correctly documented Go files
  - `good.go` - Valid production code with matching comments
  - `good_test.go` - Valid test files with matching comments

- **invalid/** - Go files with documentation mismatches
  - `bad.go` - Production code with non-matching comments
  - `bad_test.go` - Test code with non-matching comments

- **mixed/** - Mixed valid and invalid examples
  - `mixed.go` - Files with both valid and invalid comments, including edge cases like TODO comments

- **utils/** - Additional utility test files
  - `helper.go` - Helper functions for testing directory statistics

- **empty/** - Empty directory for testing empty directory handling

- **deep/nested/directory/structure/** - Deeply nested path for testing recursive scanning
  - `deep.go` - Valid Go file in deeply nested structure

### Test Scripts

#### Bash Test Suite (test.sh)

Comprehensive test suite for the go-doc-lint.sh script.

**Requirements:**

- Bash 4.0+
- The go-doc-lint.sh script must be executable

**How to run:**

```bash
cd /path/to/go-doc-lint
bash test.sh
```

**Test Coverage (33 Tests):**

- Version and help display
- Directory scanning
- Single file scanning
- Invalid path handling
- File type filtering (--test, --all flags)
- Output options (file and directory)
- Parameter validation and mutual exclusion
- Timestamp verification
- Report content verification
- Directory statistics
- Single file exclusion of directory statistics
- Valid file detection
- Empty directory handling
- Relative path support
- Nested directory auto-creation
- Deep nested path scanning

#### PowerShell Test Suite (test.ps1)

Comprehensive test suite for the go-doc-lint.ps1 script.

**Requirements:**

- PowerShell 5.0+
- The go-doc-lint.ps1 script must exist

**How to run:**

```powershell
cd path\to\go-doc-lint
.\test.ps1
```

Or with explicit script path:

```powershell
powershell -File test.ps1 -ScriptPath ".\go-doc-lint.ps1"
```

**Test Coverage (33 Tests):**

- Version and help display
- Directory scanning
- Single file scanning
- Invalid path handling
- File type filtering (--test, --all flags)
- Output options (file and directory)
- Parameter validation and mutual exclusion
- Timestamp verification
- Report content verification
- Directory statistics
- Single file exclusion of directory statistics
- Valid file detection
- Separator lines in output
- File type validation
- Empty directory handling
- Relative path support
- Nested directory auto-creation
- Deep nested path scanning
- Error handling

## Test Cases

Both test suites validate the following scenarios:

### Basic Operations

1. Display version information
2. Display help information
3. Scan directories
4. Scan single files

### Input Validation

1. Handle invalid/non-existent directories
2. Handle invalid/non-existent files
3. Validate file extension (.go only)
4. Reject mutually exclusive parameters

### File Filtering

1. Scan test files only (--test flag)
2. Scan all files (--all flag)
3. Default behavior (non-test files)

### Output Handling

1. Output to screen (no -o flag)
2. Output to specified file
3. Output to directory with auto-generated filename
4. Create missing output directories

### Report Verification

1. Verify Summary section presence
2. Verify Findings details section
3. Verify directory statistics display
4. Verify separator lines in output
5. Verify timestamp format in progress messages

### Parameter Validation

1. No arguments show help message
2. --version parameter isolation (rejects other parameters)
3. --help parameter isolation (rejects other parameters)
4. Output file existence check
5. Specific output filename specification
6. Nested output directory auto-creation

### Path Handling

1. Relative path support
2. Empty directory detection and error handling
3. Deep nested path scanning
4. Mixed valid/invalid file directories

### Special Cases

1. Single file scans exclude directory statistics
2. Valid files show zero findings
3. Invalid files show correct mismatch count
4. TODO and other special comments are handled correctly

## Test Output

Both test suites produce colored output:

- **Green (✓ PASS)** - Test passed successfully
- **Red (✗ FAIL)** - Test failed
- **Summary** - Total passed and failed test counts

## Continuous Integration

These test suites can be integrated into CI/CD pipelines:

**For GitHub Actions (Bash):**

```yaml
- name: Run Bash Tests
  run: bash test.sh
```

**For GitHub Actions (PowerShell):**

```yaml
- name: Run PowerShell Tests
  run: powershell -File test.ps1
```

## Troubleshooting

### Bash Tests

- Ensure the script has execute permissions: `chmod +x test.sh go-doc-lint.sh`
- On Windows (WSL), use bash: `wsl bash test.sh`

### PowerShell Tests

- Ensure execution policy allows script execution: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Run from PowerShell (not Windows PowerShell ISE for best compatibility)

## Adding New Tests

To add new test cases:

1. **For Bash** - Add a new function starting with `test_` in test.sh
2. **For PowerShell** - Add a new function starting with `Test-` in test.ps1
3. Call `print_result` (Bash) or `Print-Result` (PowerShell) with test name and result
4. Add the test call to the main execution section

### Test Writing Guide

Use the following checklist to design reliable tests:

1. **Define the scenario**

- One behavior per test (single responsibility)
- Include the expected exit code

1. **Prepare test data**

- Prefer fixtures under `fixtures/`
- Use unique filenames for new cases
- Avoid modifying existing fixtures unless needed

1. **Execute the tool**

- Run with explicit paths
- Capture stdout and stderr separately if possible

1. **Assert the result**

- Verify exit code
- Verify key output lines
- Avoid brittle assertions on timestamps

1. **Clean up**

- Remove temporary files/directories
- Keep fixtures intact

### Bash Test Example

```bash
# Example: verify --test only scans *_test.go
test_scan_test_files_only() {
  local output
  output=$(bash ./go-doc-lint.sh ./fixtures --test 2>&1)
  local status=$?

  # Exit code should be 0
  [[ $status -eq 0 ]] || return 1

  # Expect to see test file in output
  echo "$output" | grep -q "_test.go" || return 1

  return 0
}

# Register the test
test_scan_test_files_only
print_result "Scan test files only" $?
```

### PowerShell Test Example

```powershell
function Test-ScanTestFilesOnly {
   $output = powershell -File .\go-doc-lint.ps1 .\fixtures --test 2>&1
   $status = $LASTEXITCODE

   if ($status -ne 0) { return $false }
   if ($output -notmatch "_test\.go") { return $false }

   return $true
}

# Register the test
Print-Result "Scan test files only" (Test-ScanTestFilesOnly)
```

### Common Assertions

- **Exit code**: `$?` (Bash) / `$LASTEXITCODE` (PowerShell)
- **Output content**: `grep -q` (Bash) / `-match` (PowerShell)
- **File existence**: `[[ -f path ]]` (Bash) / `Test-Path` (PowerShell)

### Tips for Stable Tests

- Avoid exact timestamp matches; check presence or format instead.
- Use deterministic fixtures to prevent flaky output.
- Prefer `--output` to validate report files.
- Keep test names descriptive and consistent.

## Test Data

Test samples are intentionally simple to ensure:

- Fast execution
- Easy debugging
- Clear demonstration of functionality
- No external dependencies

If you need to test with larger codebases, you can point the scripts to your own Go projects.

---

**Last Updated:** 2026-02-01

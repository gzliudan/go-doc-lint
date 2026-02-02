# Go Documentation Linter - User Manual

[中文版](README_cn.md) | English

## Tool Introduction

`go-doc-lint` is a command-line tool for checking whether function documentation comments in Go source code are properly formatted. It scans Go files and verifies that the first word of a function's documentation comment matches the function name.

## Features

- ✅ Cross-platform support (Windows PowerShell and Linux/Unix)
- ✅ Flexible input options (directory or single file)
- ✅ Multiple output options (screen or file)
- ✅ File type filtering (test files, production files, or all)
- ✅ Detailed error reporting and logging
- ✅ Multi-level directory statistics
- ✅ Parameter mutual exclusion validation

## Script Mapping

| Operating System | Script File     | Execution Method                        |
| ---------------- | --------------- | --------------------------------------- |
| Windows          | go-doc-lint.ps1 | powershell -File go-doc-lint.ps1        |
| Linux/Unix/WSL   | go-doc-lint.sh  | ./go-doc-lint.sh or bash go-doc-lint.sh |

## Quick Start

Get started with go-doc-lint in seconds:

### 1. Scan Your Go Project (Most Common)

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/
```

### 2. Save Results to a File

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/ -o report.txt
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/ -o report.txt
```

### 3. Scan Only Test Files

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/ --test
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/ --test
```

### 4. Scan a Single File

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/types.go
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/types.go
```

💡 **Tip:** Check [Parameters](#parameters) section for all available options.

## Basic Usage

### Display Help

```bash
# PowerShell
powershell -File go-doc-lint.ps1 --help

# Bash
./go-doc-lint.sh --help
```

### Display Version

```bash
# PowerShell
powershell -File go-doc-lint.ps1 --version

# Bash
./go-doc-lint.sh --version
```

## System Requirements

### Windows Requirements

- **PowerShell 5.0 or higher** (included by default on Windows 10+)
- **Windows 10** or later (recommended)

#### PowerShell Version Mapping

| PowerShell Version | Windows Version                     | Included By Default |
| ------------------ | ----------------------------------- | ------------------- |
| 5.0 / 5.1          | Windows 10 (Build 1607+)            | Yes                 |
| 5.1                | Windows Server 2016+                | Yes                 |
| 7.0+               | Windows 10/11, Windows Server 2016+ | No (optional)       |

**Check version:** `$PSVersionTable.PSVersion`

### Linux/Unix/macOS Requirements

- **Bash 4.0 or higher**
- **Perl** (for comment parsing)
- **Standard tools**: `awk`, `grep`, `sed`

### System Resources

- **CPU**: No special requirements (I/O bound)
- **Memory**: < 50MB for typical projects
- **Disk**: No special requirements
- **Network**: Not required

---

## Parameters

### Positional Parameters

| Parameter      | Description                              | Example                            |
| -------------- | ---------------------------------------- | ---------------------------------- |
| `<input_path>` | Input path: directory or single .go file | `./common/` or `./common/types.go` |

### Optional Parameters

| Parameter             | Description                                               | Default             |
| --------------------- | --------------------------------------------------------- | ------------------- |
| `-o, --output <path>` | Output path (file or directory). Omit to output to screen | Screen output       |
| `-t, --test`          | Scan only *_test.go files                                 | Scan non-test files |
| `-a, --all`           | Scan all .go files including test files                   | Scan non-test files |
| `-h, --help`          | Display help information                                  | -                   |
| `-v, --version`       | Display version information                               | -                   |

### Parameter Mutual Exclusion Rules

- `--version` cannot be combined with other parameters
- `--help` cannot be combined with other parameters
- `--test` and `--all` cannot be used simultaneously

## Path Information

### Input Path (input_path)

The input path supports both **absolute paths** and **relative paths**:

- **Relative Paths**: Relative to the current working directory when the script is executed
  - `./common/` - common subdirectory in current directory
  - `../accounts/` - accounts subdirectory in parent directory
  - `core/types.go` - core/types.go file in current directory

- **Absolute Paths**: Full path from the root directory
  - Windows: `C:\Users\username\projects\go-ethereum\common\`
  - Linux/Unix: `/home/username/projects/go-ethereum/common/`
  - WSL: `/mnt/e/go-ethereum/common/`

### Output Path (-o, --output)

The output path also supports both **absolute paths** and **relative paths**:

- **Relative Paths**: Relative to the current working directory when the script is executed
  - `report.txt` - save as report.txt in current directory
  - `output/report.txt` - in the output subdirectory of current directory
  - `../results/` - in the results subdirectory of parent directory (auto-generates timestamped filename)

- **Absolute Paths**: Full file or directory path
  - Windows: `C:\reports\lint-result.txt`
  - Linux/Unix: `/var/reports/lint-result.txt`
  - WSL: `/mnt/e/reports/lint-result.txt`

**Automatic Path Normalization**: The tool automatically converts paths to absolute paths for processing to ensure accurate results.

## Usage Examples

### Example 1: Scan Directory and Output to Screen

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/

# Bash
./go-doc-lint.sh ./common/
```

**Sample Output:**

```text
================================================================================
                                    Summary
tool:     golang document linter
version:  v1.1.0
input:    /path/to/common
time:     2026-01-31 12:00:00
findings: 5

================================================================================
                             Directory statistics
common : 3
utils  : 2

================================================================================
                               Findings details

utils/helper.go
// Helper function
func helper() {}

common/types.go
// Type definition
func typesDef() {}

================================================================================
```

Note: The "Directory statistics" section only appears when scanning directories with findings.

### Example 2: Scan Directory and Save to File

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/ -o report.txt

# Bash
./go-doc-lint.sh ./common/ -o report.txt
```

**Screen Output:**

```text
[2026-01-31 19:38:00] Starting to scan directory: ./common
[2026-01-31 19:38:01] Scanning complete, found 45 go files
[2026-01-31 19:38:02] Save report: ./report.txt
```

### Example 3: Scan Directory and Save to Specified Directory

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./accounts/ -o output/

# Bash
./go-doc-lint.sh ./accounts/ -o output/
```

**Note:** If the directory doesn't exist, the tool will create it automatically. The result file will be named `go-doc-lint-YYYYMMDD-HHMMSS.txt`

### Example 4: Scan Nested Directory Structure

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./accounts/ -o result/nested/report.txt

# Bash
./go-doc-lint.sh ./accounts/ -o result/nested/report.txt
```

**Note:** The tool will automatically create all necessary intermediate directories.

### Example 5: Scan Only Test Files

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/ --test

# Bash
./go-doc-lint.sh ./common/ --test
```

### Example 6: Scan All Go Files (Including Test Files)

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/ --all

# Bash
./go-doc-lint.sh ./common/ --all
```

### Example 7: Scan Single File

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/types.go

# Bash
./go-doc-lint.sh ./common/types.go
```

## Output Explanation

### Screen Output

When `--output` is not specified, the tool outputs a report directly to the screen containing:

1. **Summary Section**
   - Tool name and version
   - Input path
   - Execution time
   - Total number of findings

2. **Directory Statistics** (only shown when scanning directories with subdirectories)
   - Number of mismatches per directory (aligned format)
   - Only displayed if there are findings and multiple top-level directories

3. **Findings Details**
   - Filename
   - Comment line
   - Function declaration

### File Output Behavior

When `--output` is specified:

1. **Screen Display**
   - Scan start: `[TIMESTAMP] Starting to scan directory/file: <path>`
   - Scan complete: `[TIMESTAMP] Scanning complete, found X go files`
   - Save result: `[TIMESTAMP] Save report: <filepath>`

2. **File Content**
   - Summary section with tool info, version, input path, execution time, and findings count
   - Directory statistics (only if scanning a directory with multiple subdirectories and there are findings)
   - Findings details section listing all mismatches
   - All sections bordered with `================================================================================`

## Exit Codes

| Exit Code | Meaning                                                        |
| --------- | -------------------------------------------------------------- |
| 0         | Success                                                        |
| 1         | Parameter error (conflicting parameters or missing values)     |
| 2         | Invalid input path (path doesn't exist or invalid file format) |
| 3         | Output file already exists                                     |
| 4         | Failed to create output directory                              |

## Troubleshooting

### Q1: Which operating systems are supported?

**A:**

- **Windows**: Use PowerShell script `go-doc-lint.ps1`
- **Linux/Unix/macOS**: Use Bash script `go-doc-lint.sh`
- **Windows with WSL**: Can use Bash script

### Q2: How to handle the case when output file already exists?

**A:** The tool will report an error and exit (exit code 3). You can:

- Delete the existing file and run again
- Use a different output filename
- Specify a directory so the tool auto-generates a timestamped filename

### Q3: What file types are scanned?

**A:**

- Default: Scan non-test files (files not ending with `_test.go`)
- `--test`: Scan only `*_test.go` files
- `--all`: Scan all `.go` files

### Q4: What does "mismatch" mean in the report?

**A:** It means the first word of a function's documentation comment doesn't match the function name. For example:

```go
// Read reads data from file
func Write(data []byte) error {  // Comment says Read, but function is Write
    // ...
}
```

### Q5: Can it scan recursive subdirectories?

**A:** Yes, the tool recursively scans all Go files in the directory and automatically excludes `vendor` and `.git` directories.

## Technical Details

### Comment Matching Rules

1. Consecutive `//` comments above a function are considered documentation comments
2. The first non-empty word of the comment is used as the "first word"
3. This first word is compared with the function name
4. Words ending with a colon (like `TODO:`, `NOTE:`) are ignored
5. Comparison is case-sensitive

### Output Filename Convention

- When filename specified: Uses the specified filename
- When directory specified: Auto-generates `go-doc-lint-YYYYMMDD-HHMMSS.txt`
  - YYYYMMDD: Execution date
  - HHMMSS: Execution time (24-hour format)

## Testing

The project includes comprehensive test suites for both Bash and PowerShell implementations.

### Run Tests

**Bash Test Suite:**

```bash
bash test.sh
```

**PowerShell Test Suite:**

```powershell
.\test.ps1
```

The test scripts will:

- Validate all core functionality (version, help, scanning, filtering, output)
- Check error handling and edge cases
- Verify report formatting and content
- Display colored pass/fail results

## More Information

For more details about using and integrating this tool:

- 📚 [Best Practices](doc/BEST_PRACTICES.md) - Integration guides, pre-commit hooks, CI/CD examples, performance tips
- 📋 [CHANGELOG](CHANGELOG.md) - Version history and release notes
- 🧪 [Testing Guide](doc/Test.md) - How to run tests
- 🧭 [Architecture](doc/ARCHITECTURE.md) - Design overview and implementation details
- 🔧 [Troubleshooting](doc/TROUBLESHOOTING.md) - Advanced debugging and problem-solving
- ❓ [FAQ](doc/FAQ.md) - Common questions and quick answers
- 📈 [Benchmarks](doc/BENCHMARKS.md) - Performance reference results
- 📦 [Examples](examples/README.md) - Sample project for quick testing
- 🔍 [Regex Comments](doc/REGEX_COMMENTS.md) - Regular expression patterns explained
- ⚡ [TODO](TODO.md) - Future improvement opportunities

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

MIT License

---

**Last Updated**: 2026-02-01

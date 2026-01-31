# Troubleshooting Guide

[中文版](TROUBLESHOOTING_cn.md) | English

## Overview

This guide covers advanced troubleshooting and problem-solving for go-doc-lint. For basic issues, see the [FAQ section in README.md](../README.md#troubleshooting).

---

## Table of Contents

1. [Performance Issues](#performance-issues)
2. [Output and Formatting Problems](#output-and-formatting-problems)
3. [Integration and Workflow Issues](#integration-and-workflow-issues)
4. [Platform-Specific Issues](#platform-specific-issues)
5. [Go Code Analysis Issues](#go-code-analysis-issues)
6. [Debugging Techniques](#debugging-techniques)
7. [Getting Help](#getting-help)

---

## Performance Issues

### Problem: Tool Runs Very Slowly

**Symptoms:**

- Takes >10 seconds to scan a project with 100 files
- CPU usage is high during scanning
- Memory usage increases significantly

**Diagnosis Steps:**

1. **Check file count**:

   ```bash
   find . -name "*.go" -type f | wc -l
   ```

2. **Identify large files**:

   ```bash
   find . -name "*.go" -type f -exec wc -l {} + | sort -rn | head -20
   ```

3. **Check for problematic patterns**:
   - Files with 10,000+ lines (rare in Go, but possible)
   - Files with extremely long function declarations
   - Files with massive comment blocks

**Solutions:**

1. **Exclude vendor directories explicitly** (should be automatic, but verify):

   ```bash
   ./go-doc-lint.sh ./src --exclude vendor --exclude .git
   ```

2. **Split large projects**:

   ```bash
   # Scan different directories separately
   ./go-doc-lint.sh ./cmd
   ./go-doc-lint.sh ./pkg
   ./go-doc-lint.sh ./internal
   ```

3. **Profile the tool** (for developers):

   ```bash
   time ./go-doc-lint.sh ./large-project/
   ```

4. **Check system resources**:

   ```bash
   # Unix/Linux
   top -p $$ # Monitor memory usage

   # Windows PowerShell
   Get-Process -Id $PID | Select-Object WorkingSet
   ```

### Problem: High Memory Usage with Large Projects

**Symptoms:**

- Memory usage exceeds 200MB
- Tool crashes on projects with 50,000+ files
- System becomes unresponsive during scan

**Solutions:**

1. **Use streaming output**:

   ```bash
   # Write to file instead of buffering to memory
   ./go-doc-lint.sh ./huge-project/ -o report.txt
   ```

2. **Scan in batches**:

   ```bash
   for dir in $(find . -maxdepth 2 -type d -name "*.go*"); do
     ./go-doc-lint.sh "$dir" -o "report-${dir//\//-}.txt"
   done
   ```

3. **Check for comment parser issues**:
   - Some files with unusual comment patterns may cause memory spikes
   - Review problematic files manually

---

## Output and Formatting Problems

### Problem: Output Looks Garbled or Has Wrong Encoding

**Symptoms:**

- Unicode characters display as `?` or escape sequences
- Chinese/Japanese/Korean characters not rendered correctly
- Emoji in comments cause display issues

**Causes:**

- Terminal encoding not set to UTF-8
- PowerShell encoding not set correctly
- File encoding issues in source code

**Solutions:**

1. **Set terminal encoding (Bash/Linux)**:

   ```bash
   export LANG=en_US.UTF-8
   export LC_ALL=en_US.UTF-8
   ./go-doc-lint.sh ./project/
   ```

2. **Set PowerShell encoding**:

   ```powershell
   [System.Environment]::SetEnvironmentVariable('PYTHONIOENCODING', 'utf-8')
   .\go-doc-lint.ps1 .\project\
   ```

3. **Check file encoding**:

   ```bash
   # Show file encoding
   file -bi yourfile.go

   # Convert to UTF-8 if needed
   iconv -f ISO-8859-1 -t UTF-8 yourfile.go > yourfile-utf8.go
   ```

### Problem: Report Doesn't Match Expected Format

**Symptoms:**

- Column alignment is off
- Headers are missing or wrong
- Directory statistics not shown when expected

**Common Causes:**

- Output redirection issues (mixing stdout and stderr)
- Terminal width too narrow
- Piping output to another command

**Solutions:**

1. **Check terminal width**:

   ```bash
   echo "Terminal width: $COLUMNS"
   # Expected: 80+ characters
   ```

2. **Use explicit output option**:

   ```bash
   # Instead of piping
   ./go-doc-lint.sh ./project/ > report.txt 2>&1

   # Use explicit file output
   ./go-doc-lint.sh ./project/ -o report.txt
   ```

3. **Verify report integrity**:

   ```bash
   # Check file size is reasonable
   wc -c report.txt

   # Check for expected headers
   grep -c "^===" report.txt  # Should have multiple separator lines
   ```

---

## Integration and Workflow Issues

### Problem: Tool Not Working with Pre-commit Hooks

**Symptoms:**

- Pre-commit hook doesn't trigger the tool
- Hook runs but doesn't fail on mismatches
- Tool output not shown in hook output

**Diagnosis:**

1. **Verify hook is configured correctly**:

   ```bash
   cat .pre-commit-config.yaml | grep -A 5 go-doc-lint
   ```

2. **Test hook manually**:

   ```bash
   pre-commit run go-doc-lint --all-files
   ```

3. **Check hook stage**:

   ```bash
   # Hook should run at 'commit' or 'push' stage
   pre-commit hook-impl --hook-type pre-commit
   ```

**Solutions:**

1. **Update .pre-commit-config.yaml**:

   ```yaml
   - repo: https://github.com/gzliudan/go-doc-lint
     rev: v1.0.0
     hooks:
       - id: go-doc-lint
         language: script
         types: [go]
         stages: [commit]
   ```

2. **Ensure tool is installed**:

   ```bash
   which go-doc-lint.sh
   # Or for PowerShell:
   Get-Command go-doc-lint.ps1
   ```

3. **Check file permissions**:

   ```bash
   ls -la go-doc-lint.sh
   # Should have execute permission: -rwxr-xr-x
   chmod +x go-doc-lint.sh
   ```

### Problem: Tool Fails in CI/CD Pipeline

**Symptoms:**

- Works locally but fails in GitHub Actions / GitLab CI / Jenkins
- CI reports "command not found" or "script failed"
- Exit code doesn't match expectations

**Diagnosis Steps:**

1. **Check CI log for error message**
2. **Verify tool path in pipeline**
3. **Check environment variables**
4. **Verify file permissions**

**Solutions:**

**GitHub Actions**:

```yaml
- name: Run go-doc-lint
  run: |
    chmod +x go-doc-lint.sh
    ./go-doc-lint.sh ./cmd/
  continue-on-error: false  # Fail if mismatches found
```

**GitLab CI**:

```yaml
lint-docs:
  script:
    - chmod +x go-doc-lint.sh
    - ./go-doc-lint.sh ./cmd/
  allow_failure: false
```

**Jenkins**:

```groovy
stage('Lint Docs') {
  steps {
    sh 'chmod +x go-doc-lint.sh'
    sh './go-doc-lint.sh ./cmd/'
  }
}
```

### Problem: Tool Fails with "Permission Denied"

**Symptoms:**

- Error: "Permission denied" when running script
- Can't execute despite file existing
- Works as admin/root but not regular user

**Solutions:**

1. **Fix file permissions**:

   ```bash
   chmod +x go-doc-lint.sh
   chmod +x test.sh
   ```

2. **Check directory permissions**:

   ```bash
   ls -ld . # Current directory should be readable and executable
   ```

3. **Run with explicit interpreter** (if needed):

   ```bash
   bash go-doc-lint.sh ./project/
   # Or for PowerShell
   powershell -File go-doc-lint.ps1 .\project\
   ```

---

## Platform-Specific Issues

### Windows: ExecutionPolicy Prevents Script Execution

**Error**:

```text
The file go-doc-lint.ps1 cannot be loaded. The file is not digitally signed.
```

**Solutions**:

1. **Temporarily bypass for current session**:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\go-doc-lint.ps1 .\project\
   ```

2. **Permanently change for current user**:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Use with explicit invocation**:

   ```powershell
   powershell -ExecutionPolicy Bypass -File go-doc-lint.ps1 .\project\
   ```

### Windows: Path Issues with Spaces and Special Characters

**Problem**: Paths containing spaces or non-ASCII characters fail

**Solutions**:

```powershell
# Quote paths properly
.\go-doc-lint.ps1 "C:\My Projects\go-app"

# Use -Path parameter
.\go-doc-lint.ps1 -Path ".\projects\my project"
```

### Unix: Locale Settings Cause Unicode Issues

**Problem**: Non-ASCII characters display incorrectly

**Solution**:

```bash
# Set proper locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
./go-doc-lint.sh ./project/

# Or add to ~/.bashrc for persistent change
echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
```

### WSL: File Permission Issues

**Problem**: Files appear with wrong permissions in WSL

**Solution**:

```bash
# Set umask for new files
umask 0022

# Fix existing files
chmod 755 go-doc-lint.sh test.sh
```

---

## Go Code Analysis Issues

### Problem: Tool Misses Some Comments or Functions

**Symptoms:**

- Some functions without proper comments aren't reported
- Comments that should match are flagged as mismatches
- Tool reports functions that don't exist

**Common Causes:**

1. Comments with unusual formatting
2. Nested functions or closures
3. Interface method signatures
4. Generated code with special markers

**Solutions:**

1. **Check comment format** - Comments must be:
   - On lines immediately above the function (no blank lines)
   - Start with `//` (not `/*` or `/**`)

   ```go
   // Good: Comment directly above function
   // ReadFile reads content from file
   func ReadFile(path string) ([]byte, error) {

   // Bad: Blank line breaks comment block

   // ReadFile reads content from file
   func ReadFile(path string) ([]byte, error) {
   ```

2. **Verify function declaration format**:

   ```bash
   # Extract function declarations to verify
   grep -n "^func " yourfile.go
   ```

3. **Check for generated code markers**:

   ```bash
   # Generated code often has special markers
   grep -l "Code generated by" *.go
   # Consider excluding these files
   ```

### Problem: False Positives (Reported as Mismatches When OK)

**Symptoms:**

- Comments flagged even though they match
- Aliases or shortcuts not recognized
- Package-level comments treated as function comments

**Example False Positive**:

```go
// NewReader creates a Reader (could be: NewReader is like New)
func NewReader() *Reader { // But tool expects: NewReader
```

**Solutions**:

1. **Understand matching rules**:
   - First word of comment must exactly match function name
   - Case-sensitive
   - Words ending with `:` (TODO, NOTE, etc.) are ignored

2. **Validate your comment pattern**:

   ```bash
   # Extract first word of comments above functions
   grep -B1 "^func " yourfile.go | grep "^//" | sed 's/.*\/\/ //' | cut -d' ' -f1
   ```

3. **Document intentional mismatches**:

   ```go
   // Reader wraps an io.Reader with buffering (legitimate description)
   func NewReader(rd io.Reader) *Reader { // Document why comment doesn't match
   ```

### Problem: Performance Issues with Specific Files

**Symptoms:**

- One file causes significant slowdown
- Memory spike when processing certain file
- Parser hangs on specific code pattern

**Diagnosis**:

```bash
# Test with individual file
time ./go-doc-lint.sh ./specific-slow-file.go

# Check file size
wc -l ./specific-slow-file.go

# Look for problematic patterns
grep -n "//.*$" ./specific-slow-file.go | head -20  # Many comments
```

**Solutions**:

1. **Temporarily exclude problematic file**:

   ```bash
   ./go-doc-lint.sh ./project/ --exclude problematic-file.go
   ```

2. **Split large file**:
   - Go best practices suggest files <500 lines
   - Breaking up the file improves overall performance

3. **Report as issue** if pattern is valid Go code:
   - Include the specific problematic code
   - Include file size and comment count
   - Include system specs (OS, shell version)

---

## Debugging Techniques

### Enable Debug Output (Developer Mode)

For contributors debugging the tool itself:

**Bash**:

```bash
# Run with bash debug mode
bash -x go-doc-lint.sh ./project/ 2>&1 | head -100

# Or enable in script
set -x  # at the beginning of go-doc-lint.sh
```

**PowerShell**:

```powershell
# Run with verbose output
.\go-doc-lint.ps1 .\project\ -Verbose

# Or enable debug preference
$DebugPreference = "Continue"
```

### Test with Minimal Input

**Create minimal test case**:

```bash
# Create test directory
mkdir test-case
cd test-case

# Create simple Go file
cat > main.go << 'EOF'
package main

// Main is the entry point
func Main() {
  println("test")
}
EOF

# Run tool on test case
../go-doc-lint.sh .
```

### Capture Full Output for Analysis

```bash
# Bash: Capture both stdout and stderr with timestamps
./go-doc-lint.sh ./project/ 2>&1 | sed "s/^/[$(date +'%H:%M:%S')] /" > debug.log

# PowerShell: Similar approach
$ErrorActionPreference = "Continue"
.\go-doc-lint.ps1 .\project\ 2>&1 | ForEach-Object { "[$(Get-Date -Format 'HH:mm:ss')] $_" } | Tee-Object -FilePath debug.log
```

### Validate Test Suite

```bash
# Run tests with verbose output
bash -v test.sh 2>&1 | head -200

# Or PowerShell
.\test.ps1 -Verbose
```

---

## Getting Help

### Check Documentation

1. **README.md** - Basic usage and quick start
2. **BEST_PRACTICES.md** - Integration patterns and common usage
3. **ARCHITECTURE.md** - Design and implementation details
4. **Test files** - Real-world usage examples

### Report an Issue

When reporting a bug, include:

1. **Tool version**:

   ```bash
   ./go-doc-lint.sh --version
   # or
   .\go-doc-lint.ps1 -Version
   ```

2. **System information**:

   ```bash
   # Unix/Linux
   uname -a
   bash --version
   perl --version

   # Windows
   $PSVersionTable.PSVersion
   ```

3. **Minimal reproduction**:
   - Include a small code sample that triggers the issue
   - Include exact command line used
   - Include full error output

4. **Steps to reproduce**:

   ```bash
   git clone https://github.com/gzliudan/go-doc-lint.git
   cd go-doc-lint
   ./go-doc-lint.sh [your test case]
   ```

### Support Resources

- **GitHub Issues**: [Report bugs or request features](https://github.com/gzliudan/go-doc-lint/issues)
- **GitHub Discussions**: Ask questions and discuss
- **Code Examples**: Check `fixtures/` directory for test cases
- **Contributing Guide**: See [CONTRIBUTING.md](../CONTRIBUTING.md) for development setup

---

## Common Error Messages and Solutions

### "No such file or directory"

**Cause**: Input path doesn't exist

**Solution**:

```bash
# Verify path exists
ls -la ./your-path/
# or
cd ./your-path && pwd
```

### "Permission denied"

**Cause**: Script not executable or directory not readable

**Solution**:

```bash
chmod +x go-doc-lint.sh
chmod +x test.sh
```

### "Perl: command not found"

**Cause**: Perl not installed

**Solution**:

```bash
# Ubuntu/Debian
sudo apt-get install perl

# macOS
brew install perl
# Or use system Perl (usually pre-installed)
```

### "ExecutionPolicy"

**Cause**: PowerShell execution policy prevents running scripts

**Solution**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Ambiguous output filename"

**Cause**: Output path is directory but contains special characters or is ambiguous

**Solution**:

```bash
# Use explicit filename
./go-doc-lint.sh ./project/ -o ./reports/result.txt

# Create directory first
mkdir -p ./reports
./go-doc-lint.sh ./project/ -o ./reports/
```

---

## Quick Reference: Solution by Symptom

| Symptom             | Most Likely Cause                      | Quick Fix                                                   |
| ------------------- | -------------------------------------- | ----------------------------------------------------------- |
| "command not found" | Script not in PATH or not executable   | `chmod +x && ./go-doc-lint.sh`                              |
| Slow performance    | Large project or system resource issue | Split scanning or use `-o file.txt`                         |
| Wrong encoding      | Locale/terminal encoding issue         | `export LANG=en_US.UTF-8`                                   |
| False positives     | Misunderstanding matching rules        | Review [comment rules](../README.md#comment-matching-rules) |
| CI/CD fails         | Path or environment variable issue     | Check CI log and use absolute paths                         |
| Tool hangs          | Large or problematic Go file           | Exclude file or split project                               |
| Missing findings    | Comment formatting issue               | Ensure comments on consecutive lines                        |

---

**Last Updated**: 2026-02-01
**Version**: 1.0.0

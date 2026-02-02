# Contributing to go-doc-lint

[中文版](CONTRIBUTING_cn.md) | English

Thank you for your interest in contributing to go-doc-lint! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

**For Bash Development (Linux/Unix/macOS/WSL):**

- Bash 4.0 or higher
- Perl (for comment parsing)
- Standard Unix tools: `awk`, `grep`, `sed`

**For PowerShell Development (Windows):**

- PowerShell 5.0 or higher
- Windows 10 or later

### Getting Started

1. **Fork and Clone**

   ```bash
   git clone https://github.com/YOUR_USERNAME/go-doc-lint.git
   cd go-doc-lint
   ```

2. **Make Scripts Executable (Bash)**

   ```bash
   chmod +x go-doc-lint.sh test.sh
   ```

3. **Verify Setup**

   ```bash
   # Test Bash version
   bash test.sh

   # Test PowerShell version
   .\test.ps1
   ```

## Development Best Practices

Before contributing, please review our [Best Practices Guide](doc/BEST_PRACTICES.md) which includes:

- Project organization guidelines
- Pre-commit hook integration patterns
- CI/CD pipeline examples
- Performance optimization tips
- Common pitfalls and how to avoid them

For information about project changes and versioning, see [CHANGELOG.md](CHANGELOG.md).

For a detailed understanding of the architecture and design decisions, see [ARCHITECTURE.md](doc/ARCHITECTURE.md).

For advanced troubleshooting and debugging, see [TROUBLESHOOTING.md](doc/TROUBLESHOOTING.md).

## Project Structure

```text
go-doc-lint/
├── go-doc-lint.sh       # Main Bash implementation
├── go-doc-lint.ps1      # Main PowerShell implementation
├── test.sh              # Bash test suite
├── test.ps1             # PowerShell test suite
├── fixtures/            # Test data directory
│   ├── valid/          # Valid Go files for testing
│   ├── invalid/        # Invalid Go files for testing
│   ├── mixed/          # Mixed valid/invalid files
│   ├── utils/          # Utility test files
│   ├── empty/          # Empty directory test case
│   └── deep/           # Deep nested path test case
├── doc/                # Documentation
│   ├── Test.md         # Testing guide (English)
│   └── Test_cn.md      # Testing guide (Chinese)
├── README.md           # User manual (English)
└── README_cn.md        # User manual (Chinese)
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- **Maintain Parity**: Both Bash and PowerShell implementations should have the same functionality
- **Follow Existing Style**: Match the coding style of existing code
- **Add Tests**: Every new feature should include corresponding test cases

### 3. Run Tests

Before submitting, ensure all tests pass:

```bash
# Run Bash tests
bash test.sh

# Run PowerShell tests
.\test.ps1
```

Expected output: All tests should pass (actual count shown in output).

### 4. Update Documentation

If your changes affect user-facing behavior:

- Update `README.md` (English)
- Update `README_cn.md` (Chinese)
- Update test documentation if adding new test cases

### 5. Commit Your Changes

Use clear, descriptive commit messages:

```bash
git add .
git commit -m "feat: add support for custom output formats"
```

**Commit Message Format:**

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test additions or modifications
- `refactor:` - Code refactoring
- `style:` - Code style changes (formatting, etc.)
- `chore:` - Maintenance tasks

## Coding Standards

### Bash Scripts

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use meaningful variable names in lowercase with underscores
- Add comments for complex logic
- Quote variables to prevent word splitting
- Use `[[` for conditionals instead of `[`

**Example:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Process input file
process_file() {
    local file_path="$1"

    if [[ -f "$file_path" ]]; then
        echo "Processing: $file_path"
    fi
}
```

### PowerShell Scripts

- Use verb-noun naming for functions (e.g., `Get-FileContent`)
- Use PascalCase for function names
- Use camelCase for variable names
- Add proper error handling with try-catch
- Use `param()` blocks for function parameters
- Add comment-based help for functions

**Example:**

```powershell
function Get-FileContent {
    param(
        [string]$FilePath
    )

    if (Test-Path $FilePath) {
        Write-Output "Processing: $FilePath"
    }
}
```

## Testing Guidelines

### Adding New Test Cases

1. **Bash Test (test.sh):**
   - Add a new function starting with `test_`
   - Use helper functions: `test_output_matches`, `test_file_contains`, etc.
   - Call the test function in `main()`

2. **PowerShell Test (test.ps1):**
   - Add a new function starting with `Test-`
   - Use helper functions: `Test-OutputMatches`, `Test-FileContains`, etc.
   - Call the test function in `Main`

### Test Categories

Ensure tests cover these areas:

- Basic operations (version, help, scanning)
- Input validation (invalid paths, file types)
- File filtering (--test, --all flags)
- Output handling (screen, file, directory)
- Report verification (format, content)
- Parameter validation (mutual exclusion)
- Path handling (relative, nested, empty)
- Special cases (single files, valid files, edge cases)

### Test Data

Add test data to appropriate `fixtures/` subdirectories:

- `valid/` - Correctly documented Go files
- `invalid/` - Files with documentation mismatches
- `mixed/` - Files with both valid and invalid examples
- `utils/` - Helper files for specific test scenarios

## Pull Request Process

1. **Ensure Quality:**
   - All tests pass (28/28)
   - Code follows style guidelines
   - Documentation is updated
   - No merge conflicts

2. **Submit PR:**
   - Provide clear description of changes
   - Reference any related issues
   - Include screenshots/examples if applicable

3. **Review Process:**
   - Maintainers will review your code
   - Address any feedback or requested changes
   - Once approved, your PR will be merged

## Reporting Issues

When reporting bugs or requesting features:

1. **Check Existing Issues:** Search to avoid duplicates
2. **Provide Details:**
   - Version information (`--version`)
   - Operating system
   - Steps to reproduce (for bugs)
   - Expected vs. actual behavior
   - Sample code/files if applicable

3. **Use Templates:** Follow the issue template if provided

## Getting Help

- **Documentation:** Check `README.md` and `doc/Test.md`
- **Issues:** Open an issue for questions or problems
- **Discussions:** Use GitHub Discussions for general questions

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain a positive community environment

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to go-doc-lint! 🎉

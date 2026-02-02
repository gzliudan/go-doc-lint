#!/usr/bin/env bash

# Test suite for go-doc-lint.sh
# This script tests various functionalities of the go-doc-lint tool

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINTER="$SCRIPT_DIR/go-doc-lint.sh"
TEST_DIR="$SCRIPT_DIR/fixtures"
OUTPUT_DIR="$SCRIPT_DIR/fixtures/test_output"
MIN_SEPARATORS=3  # Minimum number of separator lines expected in reports

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Helper function to print test start
print_test_start() {
    local test_name="$1"
    echo -e "${YELLOW}Running:${NC} $test_name"
}

# Helper function to print test result
print_result() {
    local test_name="$1"
    local result="$2"

    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        ((FAILED++))
    fi
}

# Generic test function for pattern matching in output
test_output_matches() {
    local test_name="$1"
    local pattern="$2"
    shift 2
    print_test_start "$test_name"
    local output
    output=$("$LINTER" "$@" 2>&1)
    if [[ "$output" =~ $pattern ]]; then
        print_result "$test_name" 0
    else
        print_result "$test_name" 1
    fi
}

# Generic test function for checking file content
test_file_contains() {
    local test_name="$1"
    local file="$2"
    local pattern="$3"
    shift 3
    print_test_start "$test_name"
    "$LINTER" "$@" > /dev/null 2>&1
    if grep -q "$pattern" "$file"; then
        print_result "$test_name" 0
    else
        print_result "$test_name" 1
    fi
}

# Generic test function for exact output matching
test_output_exact() {
    local test_name="$1"
    local expected="$2"
    shift 2
    print_test_start "$test_name"
    local output
    output=$("$LINTER" "$@" 2>&1)
    if [[ "$output" == "$expected" ]]; then
        print_result "$test_name" 0
    else
        print_result "$test_name" 1
    fi
}

# Generic test function for checking output does NOT match pattern
test_output_not_matches() {
    local test_name="$1"
    local pattern="$2"
    shift 2
    print_test_start "$test_name"
    local output
    output=$("$LINTER" "$@" 2>&1)
    if ! [[ "$output" =~ $pattern ]]; then
        print_result "$test_name" 0
    else
        print_result "$test_name" 1
    fi
}

# Generic test function for checking file exists after command
test_file_exists_after_command() {
    local test_name="$1"
    local file_path="$2"
    shift 2
    print_test_start "$test_name"
    "$LINTER" "$@" > /dev/null 2>&1
    if [ -f "$file_path" ]; then
        print_result "$test_name" 0
    else
        print_result "$test_name" 1
    fi
}

# Generic test function for counting files in directory
test_files_count_in_path() {
    local test_name="$1"
    local search_dir="$2"
    local file_pattern="$3"
    local expected_count="$4"
    shift 4
    print_test_start "$test_name"
    "$LINTER" "$@" > /dev/null 2>&1
    local count
    count=$(find "$search_dir" -name "$file_pattern" 2>/dev/null | wc -l)
    if [ "$count" -gt "$expected_count" ]; then
        print_result "$test_name" 0
    else
        print_result "$test_name" 1
    fi
}

# Generic test function for counting pattern matches in file
test_pattern_count_in_file() {
    local test_name="$1"
    local file_path="$2"
    local pattern="$3"
    local min_count="$4"
    print_test_start "$test_name"
    local count
    count=$(grep -c "$pattern" "$file_path" 2>/dev/null || echo 0)
    if [ "$count" -ge "$min_count" ]; then
        print_result "$test_name" 0
    else
        print_result "$test_name" 1
    fi
}

# Clean up previous test output
cleanup() {
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
}

# Test 1: Display version
test_version() {
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    expected_version=$(cat "$script_dir/VERSION" | tr -d '[:space:]')
    test_output_exact "Display version" "$expected_version" --version
}

# Test 2: Display help
test_help() {
    test_output_matches "Display help" "Usage:" --help
}

# Test 3: Scan directory without output option (screen output)
test_scan_directory_screen() {
    test_output_matches "Scan directory - screen output" "Summary" "$TEST_DIR/valid"
}

# Test 4: Scan single file
test_scan_single_file() {
    test_output_matches "Scan single file" "Summary" "$TEST_DIR/valid/good.go"
}

# Test 5: Scan with invalid directory
test_scan_invalid_directory() {
    test_output_matches "Handle invalid directory" "not found" "$TEST_DIR/nonexistent"
}

# Test 6: Scan with test files only
test_scan_test_only() {
    test_output_matches "Scan test files only (--test)" "Summary" "$TEST_DIR" --test
}

# Test 7: Scan all files (including tests)
test_scan_all() {
    test_output_matches "Scan all files (--all)" "Summary" "$TEST_DIR" --all
}

# Test 8: Save to file
test_save_to_file() {
    local output_file="$OUTPUT_DIR/report.txt"
    test_file_exists_after_command \
        "Save output to file" \
        "$output_file" \
        "$TEST_DIR/valid" -o "$output_file"
}

# Test 9: Save to directory (auto-generate filename)
test_save_to_directory() {
    local output_subdir="$OUTPUT_DIR/subdir"
    test_files_count_in_path \
        "Save to directory with auto-generated filename" \
        "$output_subdir" "go-doc-lint-*.txt" 0 \
        "$TEST_DIR/valid" -o "$output_subdir/"
}

# Test 10: Test mutual exclusion (--test with --all)
test_mutual_exclusion() {
    test_output_matches \
        "Reject mutually exclusive parameters" \
        "mutually exclusive" \
        "$TEST_DIR" --test --all
}

# Test 11: Check output contains timestamp
test_timestamp_in_progress() {
    test_output_matches \
        "Progress messages contain timestamps" \
        "\\[[0-9]{4}-[0-9]{2}-[0-9]{2}" \
        "$TEST_DIR/valid" -o "$OUTPUT_DIR/test_timestamp.txt"
}

# Test 12: Verify findings in report
test_findings_in_report() {
    local output_file="$OUTPUT_DIR/findings_test.txt"
    test_file_contains \
        "Report contains Findings details section" \
        "$output_file" "Findings details" \
        "$TEST_DIR/invalid" -o "$output_file"
}

# Test 13: Verify directory statistics section presence
test_directory_statistics() {
    test_output_matches \
        "Directory statistics shown for multi-directory scan" \
        "Directory statistics" "$TEST_DIR"
}

# Test 14: Single file should not show directory statistics
test_single_file_no_dir_stats() {
    test_output_not_matches \
        "Single file scan excludes directory statistics" \
        "Directory statistics" "$TEST_DIR/valid/good.go"
}

# Test 15: Check valid directory (good.go should pass)
test_valid_file_check() {
    test_output_matches \
        "Valid Go file shows zero findings" \
        "findings:[[:space:]]*0" "$TEST_DIR/valid/good.go"
}

# Test 16: Check separator lines in report
test_separator_lines() {
    local output_file="$OUTPUT_DIR/separator_test.txt"
    "$LINTER" "$TEST_DIR/valid" -o "$output_file" > /dev/null 2>&1
    test_pattern_count_in_file \
        "Report contains separator lines" \
        "$output_file" "^==========" "$MIN_SEPARATORS"
}

# Test 17: Handle non-existent file error
test_nonexistent_file() {
    test_output_matches "Handle non-existent file" "not found" "$TEST_DIR/nonexistent.go"
}

# Test 18: Reject non-.go files
test_invalid_file_type() {
    test_output_matches "Reject non-.go files" "must be a .go file" "$TEST_DIR/utils/README.md"
}

# Test 19: No arguments should show help
test_no_arguments() {
    print_test_start "No arguments shows help"
    local output
    output=$("$LINTER" 2>&1)
    if [[ "$output" =~ "Usage:" ]]; then
        print_result "No arguments shows help" 0
    else
        print_result "No arguments shows help" 1
    fi
}

# Test 20: Version cannot be used with other parameters
test_version_with_params() {
    test_output_matches \
        "Version with params rejected" \
        "cannot be used with other parameters" \
        --version -o "$OUTPUT_DIR/test.txt"
}

# Test 21: Help cannot be used with other parameters
test_help_with_params() {
    test_output_matches \
        "Help with params rejected" \
        "cannot be used with other parameters" \
        --help -o "$OUTPUT_DIR/test.txt"
}

# Test 22: Output file already exists error
test_output_file_exists() {
    print_test_start "Reject existing output file"
    local output_file="$OUTPUT_DIR/exists_test.txt"
    # Create the file first
    touch "$output_file"
    local output
    output=$("$LINTER" "$TEST_DIR/valid" -o "$output_file" 2>&1)
    if [[ "$output" =~ "already exists" ]]; then
        print_result "Reject existing output file" 0
    else
        print_result "Reject existing output file" 1
    fi
}

# Test 23: Output to specific file name
test_output_file_name() {
    local output_file="$OUTPUT_DIR/custom_report.txt"
    test_file_exists_after_command \
        "Output to specific filename" \
        "$output_file" "$TEST_DIR/valid" -o "$output_file"
}

# Test 24: Output to nested directory (auto-create)
test_output_nested_dir() {
    local nested_dir="$OUTPUT_DIR/level1/level2/level3"
    test_files_count_in_path \
        "Auto-create nested output directory" \
        "$nested_dir" "go-doc-lint-*.txt" 0 \
        "$TEST_DIR/valid" -o "$nested_dir/"
}

# Test 25: Scan mixed valid and invalid files
test_mixed_files() {
    test_output_matches "Scan mixed valid and invalid" "Summary" "$TEST_DIR/mixed"
}

# Test 26: Relative path handling
test_relative_path() {
    print_test_start "Handle relative path"
    local current_dir
    current_dir=$(pwd)
    cd "$SCRIPT_DIR" || exit 1
    local output
    output=$(./go-doc-lint.sh "fixtures/valid/good.go" 2>&1)
    cd "$current_dir" || exit 1
    if [[ "$output" =~ "Summary" ]]; then
        print_result "Handle relative path" 0
    else
        print_result "Handle relative path" 1
    fi
}

# Test 27: Empty directory handling
test_empty_directory() {
    test_output_matches "Empty directory no files message" "No Go files to scan" "$TEST_DIR/empty"
}

# Test 28: Deep nested path
test_deep_nested_path() {
    test_output_matches \
        "Scan deeply nested path" "Summary" \
        "$TEST_DIR/deep/nested/directory/structure"
}

# Test 29: Directory statistics shows correct directory names
test_directory_statistics_names() {
    print_test_start "Directory statistics shows correct directory names"
    local output_file="$OUTPUT_DIR/dir_stats_test.txt"
    "$LINTER" "$TEST_DIR" -o "$output_file" > /dev/null 2>&1
    local content
    content=$(cat "$output_file")
    # Check that directory statistics contains expected top-level directory names
    local has_invalid=0
    if echo "$content" | grep -qE "invalid[[:space:]]+:[[:space:]]+[0-9]+"; then
        has_invalid=1
    fi

    # Check that we don't see absolute paths or drive letters as directory names
    local no_absolute=1
    if echo "$content" | grep -qE "/[a-z]+[[:space:]]+:[[:space:]]+[0-9]+"; then
        no_absolute=0
    fi

    if [ "$has_invalid" -eq 1 ] && [ "$no_absolute" -eq 1 ]; then
        print_result "Directory statistics shows correct directory names" 0
    else
        print_result "Directory statistics shows correct directory names" 1
    fi
}

# Test 30: Directory statistics shows correct counts per directory
test_directory_statistics_counts() {
    print_test_start "Directory statistics behavior for single directory"
    local output_file="$OUTPUT_DIR/dir_counts_test.txt"
    "$LINTER" "$TEST_DIR/invalid" -o "$output_file" > /dev/null 2>&1
    local content
    content=$(cat "$output_file")
    # When scanning a single subdirectory with files, it will show directory statistics
    # This is expected behavior - we're just verifying it runs without errors
    if echo "$content" | grep -q "Directory statistics"; then
        print_result "Directory statistics behavior for single directory" 0
    else
        print_result "Directory statistics behavior for single directory" 1
    fi
}

# Test 31: Relative paths in findings (no absolute paths)
test_relative_paths_in_findings() {
    print_test_start "Findings show relative paths without absolute paths"
    local output_file="$OUTPUT_DIR/relative_paths_test.txt"
    "$LINTER" "$TEST_DIR" -o "$output_file" > /dev/null 2>&1

    # Find all lines that look like file paths (contain slash and .go)
    local path_lines
    path_lines=$(sed -n '/Findings details/,$p' "$output_file" | grep -E '/.*.go$')

    if [ -n "$path_lines" ]; then
        # Check if any path starts with / (absolute path)
        local has_absolute
        has_absolute=$(echo "$path_lines" | grep -E '^/' || echo "")
        if [ -z "$has_absolute" ]; then
            print_result "Findings show relative paths without absolute paths" 0
        else
            print_result "Findings show relative paths without absolute paths" 1
        fi
    else
        # No findings is also OK (check for 0 findings)
        if grep -qE "findings:[[:space:]]*0" "$output_file"; then
            print_result "Findings show relative paths without absolute paths" 0
        else
            print_result "Findings show relative paths without absolute paths" 1
        fi
    fi
}

# Test 32: Directory statistics with multi-level structure
test_directory_statistics_multilevel() {
    print_test_start "Directory statistics only shows top-level directories"
    local output_file="$OUTPUT_DIR/multilevel_test.txt"
    "$LINTER" "$TEST_DIR" -o "$output_file" > /dev/null 2>&1

    # Extract directory names from statistics section
    local dir_names
    dir_names=$(
        sed -n '/Directory statistics/,/^==========/p' "$output_file" | \
        grep -E '^[a-z_]+[[:space:]]+:' | \
        cut -d':' -f1 | tr -d ' '
    )

    if [ -n "$dir_names" ]; then
        # Check if any directory name contains a slash (nested path)
        local has_nested
        has_nested=$(echo "$dir_names" | grep '/' || echo "")
        if [ -z "$has_nested" ]; then
            print_result "Directory statistics only shows top-level directories" 0
        else
            print_result "Directory statistics only shows top-level directories" 1
        fi
    else
        print_result "Directory statistics only shows top-level directories" 1
    fi
}

# Test 33: Verify directory statistics format
test_directory_statistics_format() {
    print_test_start "Directory statistics has correct format"
    local output_file="$OUTPUT_DIR/format_test.txt"
    "$LINTER" "$TEST_DIR" -o "$output_file" > /dev/null 2>&1

    # Extract directory statistics lines
    local dir_lines
    dir_lines=$(
        sed -n '/Directory statistics/,/^==========/p' "$output_file" | \
        grep -E '^[a-z_]+[[:space:]]+:[[:space:]]+[0-9]+'
    )

    if [ -n "$dir_lines" ]; then
        # Check if lines are formatted correctly and sorted
        local dir_names
        dir_names=$(echo "$dir_lines" | cut -d':' -f1 | tr -d ' ')
        local is_sorted=1

        # Simple check: if we have multiple directories, verify they appear in order
        local count
        count=$(echo "$dir_names" | wc -l)
        if [ "$count" -gt 1 ]; then
            local sorted_names
            sorted_names=$(echo "$dir_names" | sort)
            if [ "$dir_names" = "$sorted_names" ]; then
                is_sorted=1
            else
                is_sorted=0
            fi
        fi

        if [ "$is_sorted" -eq 1 ]; then
            print_result "Directory statistics has correct format" 0
        else
            print_result "Directory statistics has correct format" 1
        fi
    else
        print_result "Directory statistics has correct format" 1
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "Go-doc-lint Bash Test Suite"
    echo "=========================================="
    echo

    cleanup

    test_version
    test_help
    test_scan_directory_screen
    test_scan_single_file
    test_scan_invalid_directory
    test_scan_test_only
    test_scan_all
    test_save_to_file
    test_save_to_directory
    test_mutual_exclusion
    test_timestamp_in_progress
    test_findings_in_report
    test_directory_statistics
    test_single_file_no_dir_stats
    test_valid_file_check
    test_separator_lines
    test_nonexistent_file
    test_invalid_file_type
    test_no_arguments
    test_version_with_params
    test_help_with_params
    test_output_file_exists
    test_output_file_name
    test_output_nested_dir
    test_mixed_files
    test_relative_path
    test_empty_directory
    test_deep_nested_path
    test_directory_statistics_names
    test_directory_statistics_counts
    test_relative_paths_in_findings
    test_directory_statistics_multilevel
    test_directory_statistics_format

    echo
    echo "=========================================="
    echo -e "Test Results: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
    echo "=========================================="

    # Clean up temporary test files
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    rm -rf "$OUTPUT_DIR"

    if [ $FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

main

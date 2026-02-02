#!/usr/bin/env bash
set -euo pipefail

# Check for required commands
command -v perl >/dev/null 2>&1 || {
  echo "❌ Error: perl is required but not installed." >&2
  echo "   Tip: On Ubuntu/Debian, run: sudo apt-get install perl" >&2
  echo "   Tip: On macOS, run: brew install perl" >&2
  echo "   Tip: On Windows, use the PowerShell version: go-doc-lint.ps1" >&2
  exit 1
}
command -v awk >/dev/null 2>&1 || {
  echo "❌ Error: awk is required but not installed." >&2
  echo "   Tip: This usually comes with perl. Check perl installation." >&2
  exit 1
}

script_version="v1.0.0"
product_name="golang document linter"

input_path="."
output_dir="."
output_to_file=false
show_help=false
show_version=false
scan_test_only=false
scan_all=false
param_count=0
has_version=false
has_help=false

# Save original argument count for checking if no arguments provided
original_args=("$@")

show_help_fn() {
  script_name="$(basename "$0")"
  echo "$product_name $script_version"
  echo "Usage: ./$script_name [options] <input_path>"
  echo
  echo "Arguments:"
  echo "  <input_path>         Input path - Directory or .go file to scan"
  echo
  echo "Options:"
  echo "  --version, -v       Show version information"
  echo "  --help, -h          Show this help message"
  echo "  --output, -o        Output directory (default: current directory)"
  echo "  --test, -t          Scan only *test.go files"
  echo "  --all, -a           Scan all .go files"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      show_help=true
      has_help=true
      param_count=$((param_count + 1))
      shift
      ;;
    --version|-v)
      show_version=true
      has_version=true
      param_count=$((param_count + 1))
      shift
      ;;
    --output|-o)
      if [[ $# -lt 2 ]]; then
        echo "❌ Error: Missing value for option '$1'" >&2
        echo "   Usage: ./$(basename "$0") [options] <input_path> --output <output_path>" >&2
        exit 1
      fi
      output_dir="$2"
      output_to_file=true
      param_count=$((param_count + 1))
      shift 2
      ;;
    --test|-t)
      scan_test_only=true
      param_count=$((param_count + 1))
      shift
      ;;
    --all|-a)
      scan_all=true
      param_count=$((param_count + 1))
      shift
      ;;
    -*)
      echo "❌ Error: Unknown argument: '$1'" >&2
      echo "   Run './$script_name --help' for usage information" >&2
      exit 1
      ;;
    *)
      # Treat as input path
      input_path="$1"
      shift
      ;;
  esac
done

# Check if no arguments provided
if [[ ${#original_args[@]} -eq 0 ]]; then
  show_help_fn
  exit 0
fi

# Check for mutually exclusive parameters
if $has_version && [[ $param_count -gt 1 ]]; then
  echo "❌ Error: --version cannot be used with other parameters" >&2
  echo "   Usage: ./$(basename "$0") --version" >&2
  exit 1
fi

if $has_help && [[ $param_count -gt 1 ]]; then
  echo "❌ Error: --help cannot be used with other parameters" >&2
  echo "   Usage: ./$(basename "$0") --help" >&2
  exit 1
fi

if $scan_test_only && $scan_all; then
  echo "❌ Error: --test and --all are mutually exclusive options" >&2
  echo "   Use either --test (test files only) or --all (all files)" >&2
  echo "   or neither (default: non-test files)" >&2
  exit 1
fi

if $show_version; then
  echo "$script_version"
  exit 0
fi

if $show_help; then
  show_help_fn
  exit 0
fi

# Handle output path: if it's a file, check if it exists; if it's a directory, create if needed
output_file=""
if $output_to_file; then
  if [[ "$output_dir" != "." ]]; then
    # Check if output looks like a file (has extension) or directory (no extension)
    if [[ "$output_dir" =~ \.[a-zA-Z0-9]+$ ]]; then
      # It's a file - get the parent directory and filename
      filename="$(basename "$output_dir")"
      output_dir="$(dirname "$output_dir")"

      # Convert relative path to absolute and normalize
      if [[ ! "$output_dir" = /* ]]; then
        output_dir="$(pwd)/$output_dir"
      fi

      # Clean up path (remove redundant . and ..)
      output_dir="$(
        realpath -m "$output_dir" 2>/dev/null || \
        readlink -f "$output_dir" 2>/dev/null || \
        echo "$output_dir"
      )"
      output_file="$output_dir/$filename"

      # Check if output file already exists
      if [[ -e "$output_file" ]]; then
        echo "❌ Error: Output file already exists: $output_file" >&2
        echo "   Tip: Remove the file first, or specify a different output path" >&2
        exit 3
      fi

      # Create parent directories if needed
      if [[ ! -d "$output_dir" ]]; then
        if ! mkdir -p "$output_dir"; then
          echo "❌ Error: Failed to create output directory: $output_dir" >&2
          echo "   Tip: Check directory permissions:" >&2
          echo "   $(ls -ld "$output_dir" 2>&1 || echo 'parent not accessible')" >&2
          exit 4
        fi
      fi
    else
      # It's a directory
      if [[ ! "$output_dir" = /* ]]; then
        output_dir="$(pwd)/$output_dir"
      fi

      # Clean up path
      output_dir="$(
        realpath -m "$output_dir" 2>/dev/null || \
        readlink -f "$output_dir" 2>/dev/null || \
        echo "$output_dir"
      )"

      # Create directory if needed
      if [[ ! -d "$output_dir" ]]; then
        if ! mkdir -p "$output_dir"; then
          echo "❌ Error: Failed to create output directory: $output_dir" >&2
          echo "   Tip: Check if parent directory is writable:" >&2
          echo "   $(ls -ld "$(dirname "$output_dir")" 2>&1 || echo 'check permissions')" >&2
          exit 4
        fi
      fi
    fi
  else
    if command -v realpath >/dev/null 2>&1; then
      output_dir="$(realpath "$output_dir")"
    else
      output_dir="$(cd "$output_dir" && pwd)"
    fi
  fi

  # Generate output filename with timestamp if not explicitly specified
  if [[ -z "$output_file" ]]; then
    timestamp=$(date +%Y%m%d-%H%M%S)
    output_file="$output_dir/go-doc-lint-$timestamp.txt"
  fi
fi

if [[ ! -e "$input_path" ]]; then
  echo "❌ Error: Input path not found: '$input_path'" >&2
  echo "   Current directory: $(pwd)" >&2
  echo "   Tip: Use absolute path or check if file/directory exists: ls -la '$input_path'" >&2
  exit 2
fi

if command -v realpath >/dev/null 2>&1; then
  input_path_resolved="$(realpath "$input_path")"
else
  input_path_resolved="$(cd "$input_path" && pwd)"
fi

is_single_file="false"
if [[ -d "$input_path" ]]; then
  root="$input_path_resolved"
  mapfile -t go_files < <(
    find "$root" -type f -name "*.go" \
      \( -path "*/vendor/*" -o -path "*/.git/*" \) -prune -false \
      -o -type f -name "*.go" -print
  )
else
  if [[ "${input_path##*.}" != "go" ]]; then
    echo "❌ Error: Input file must be a .go file: '$input_path'" >&2
    echo "   Tip: Provide a .go file or directory containing Go files" >&2
    echo "   Example: ./$(basename "$0") ./cmd/main.go" >&2
    exit 2
  fi
  is_single_file="true"
  root="$(dirname "$input_path_resolved")"
  go_files=("$input_path_resolved")
fi

if $scan_all; then
  :
elif $scan_test_only; then
  filtered=()
  for f in "${go_files[@]}"; do
    [[ "$f" == *_test.go ]] && filtered+=("$f")
  done
  go_files=("${filtered[@]}")
else
  filtered=()
  for f in "${go_files[@]}"; do
    [[ "$f" != *_test.go ]] && filtered+=("$f")
  done
  go_files=("${filtered[@]}")
fi

if [[ "${#go_files[@]}" -eq 0 ]]; then
  echo "No Go files to scan for selected mode."
  exit 0
fi

input_dir_display="$root"

# Record start time for performance statistics
start_time=$(date +%s)

if [[ -d "$input_path_resolved" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting to scan directory: $input_dir_display"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting to scan file: $input_path_resolved"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found ${#go_files[@]} Go file(s) to scan"

sep=$'\x1f'
tmp_results="$(mktemp)"

for file in "${go_files[@]}"; do
  rel_path="$file"
  if [[ -n "$root" ]]; then
    # Ensure root ends with slash for consistent removal
    root_with_slash="$root"
    [[ "$root_with_slash" != */ ]] && root_with_slash="$root_with_slash/"
    # Remove root prefix from file path
    if [[ "$file" == "$root_with_slash"* ]]; then
      rel_path="${file#"$root_with_slash"}"
    fi
  fi

  # Process each Go file with Perl state machine to detect doc comment mismatches
  # The Perl script implements a line-by-line state machine:
  # - State 1: Accumulate comment lines (those starting with //)
  # - State 2: Detect function/method declarations
  # - State 3: Report mismatches (when comment first word != function name)
  # Output format uses field separator ($sep) for parsing by subsequent shell code

  perl_script=$(cat <<'PERL'
    BEGIN {
      $rel = $ENV{"REL"};
      $sep = $ENV{"SEP"};
      $commentLine = "";
      $firstWord = "";
      $inComment = 0;
    }

    $_ =~ s/\r?\n$//;
    my $line = $_;
    my $trimmed = $line;
    $trimmed =~ s/^\s+//;
    $trimmed =~ s/\s+$//;

    if ($trimmed =~ m{^//}) {
      if (!$inComment) {
        $commentLine = "";
        $firstWord = "";
      }
      $inComment = 1;

      if ($firstWord eq "" && $trimmed =~ m{^//\s+(\S+)}) {
        $commentLine = $trimmed;
        $firstWord = $1;
      }
      next;
    }

    if ($trimmed eq "") {
      $inComment = 0;
      $commentLine = "";
      $firstWord = "";
      next;
    }

    my $func = "";
    if ($line =~ /^\s*func\s*\([^)]*\)\s*([A-Za-z_][A-Za-z0-9_]*)\s*\(/) {
      $func = $1;
    } elsif ($line =~ /^\s*func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(/) {
      $func = $1;
    }

    if ($func ne "" && $commentLine ne "" &&
        $firstWord ne "" && $firstWord ne $func &&
        $firstWord !~ /:$/) {
      print $rel, $sep, $firstWord, $sep, $func, $sep,
            $commentLine, $sep, $line, "\n";
    }

    $inComment = 0;
    $commentLine = "";
    $firstWord = "";
PERL
  )

  REL="$rel_path" SEP="$sep" perl -ne "$perl_script" "$file" >> "$tmp_results"
done

mismatch_count=$(wc -l < "$tmp_results" | tr -d ' ')

# Calculate elapsed time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

if [ "$output_to_file" = "true" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Scanning complete, " \
       "found ${#go_files[@]} go files (${elapsed_time}s)"
  if [[ "$mismatch_count" -eq 0 ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No mismatches found!"
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $mismatch_count function comment mismatches"
  fi
fi

detailed_file="$output_dir/function_comment_mismatches.txt"
{
  echo "$product_name"
  printf "================================================================================\n"
  echo "Input Path: $input_dir_display"
  echo "Total Mismatches: $mismatch_count"
  echo
  while IFS="$sep" read -r file first_word func_name comment_line func_decl; do
    echo "File: $file"
    echo "  Comment First Word: $first_word"
    echo "  Function Name: $func_name"
    echo "  Comment Line: $comment_line"
    echo "  Function Declaration: $func_decl"
    echo
  done < "$tmp_results"
} > "$detailed_file"

out_all="$output_file"

tmp_all="$(mktemp)"

declare -A dir_all=()

count_all=0

while IFS="$sep" read -r file first_word func_name comment_line func_decl; do
  count_all=$((count_all + 1))

  # Extract top-level directory from file path
  # Handle paths that may still have absolute components
  top_dir="$file"
  # Remove any remaining drive letter or absolute path prefix (for compatibility)
  top_dir="${top_dir#*:}"
  # Extract first directory component (before first slash)
  if [[ "$top_dir" == */* ]]; then
    top_dir="${top_dir%%/*}"
  fi

  dir_all["$top_dir"]=$((dir_all["$top_dir"] + 1))

  {
    echo "$file"
    echo "$comment_line"
    echo "$func_decl"
    if [[ $count_all -lt $(wc -l < "$tmp_results" | tr -d ' ') ]]; then
      echo ""
    fi
  } >> "$tmp_all"

done < "$tmp_results"

line_divider=$(printf '%*s' 80 '' | tr ' ' '=')

write_summary() {
  local output_file="$1"
  local total_count="$2"
  local -n dir_map="$3"
  local tmp_body="$4"
  local is_file="$5"
  local exec_time
  exec_time="$(date '+%Y-%m-%d %H:%M:%S')"

  if [[ -z "$output_file" ]]; then
    # Output to stdout
    echo "$line_divider"
    printf "%36s%s\n" "" "Summary"
    printf "%-9s %s\n" "tool:" "$product_name"
    printf "%-9s %s\n" "version:" "$script_version"
    printf "%-9s %s\n" "input:" "$input_dir_display"
    printf "%-9s %s\n" "time:" "$exec_time"
    printf "%-9s %s\n" "findings:" "$total_count"
    echo
    if [[ "$is_file" != "true" && ${#dir_map[@]} -gt 0 ]]; then
      echo "$line_divider"
      printf "%29s%s\n" "" "Directory statistics"

      # Find the longest directory name
      max_len=0
      for key in "${!dir_map[@]}"; do
        len=${#key}
        if (( len > max_len )); then
          max_len=$len
        fi
      done

      for key in "${!dir_map[@]}"; do
        printf "%-${max_len}s : %s\n" "$key" "${dir_map[$key]}"
      done | sort
      echo
    fi
    echo "$line_divider"
    printf "%31s%s\n" "" "Findings details"
    cat "$tmp_body"
    echo
    echo "$line_divider"
  else
    # Output to file
    {
      echo "$line_divider"
      printf "%36s%s\n" "" "Summary"
      printf "%-9s %s\n" "tool:" "$product_name"
      printf "%-9s %s\n" "version:" "$script_version"
      printf "%-9s %s\n" "input:" "$input_dir_display"
      printf "%-9s %s\n" "time:" "$exec_time"
      printf "%-9s %s\n" "findings:" "$total_count"
      echo
      if [[ "$is_file" != "true" && ${#dir_map[@]} -gt 0 ]]; then
        echo "$line_divider"
        printf "%29s%s\n" "" "Directory statistics"

        # Find the longest directory name
        max_len=0
        for key in "${!dir_map[@]}"; do
          len=${#key}
          if (( len > max_len )); then
            max_len=$len
          fi
        done

        for key in "${!dir_map[@]}"; do
          printf "%-${max_len}s : %s\n" "$key" "${dir_map[$key]}"
        done | sort
        echo
      fi
      echo "$line_divider"
      printf "%31s%s\n" "" "Findings details"
      cat "$tmp_body"
      echo
      echo "$line_divider"
    } > "$output_file"
  fi
}

write_summary "$out_all" "$count_all" dir_all "$tmp_all" "$is_single_file"

rm -f "$detailed_file" "$tmp_results" "$tmp_all"

if [[ -n "$out_all" ]]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Save report: $out_all"
fi

# Check for required PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "❌ Error: PowerShell 5.0 or higher is required. Current version: $($PSVersionTable.PSVersion)" -ErrorAction Continue
    Write-Host "   Tip: Download the latest PowerShell from: https://github.com/PowerShell/PowerShell/releases"
    exit 1
}

$scriptVersion = "v1.0.0"
$scriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
$productName = "golang document linter"

$inputPath = "."
$outputDir = "."
$outputToFile = $false
$showHelp = $false
$showVersion = $false
$scanTestOnly = $false
$scanAll = $false

function Show-Help {
    Write-Output "$productName $scriptVersion"
    Write-Output "Usage: powershell -File $scriptName [options] <input_path>"
    Write-Output ""
    Write-Output "Arguments:"
    Write-Output "  <input_path>         Input path - Directory or .go file to scan"
    Write-Output ""
    Write-Output "Options:"
    Write-Output "  --version, -v       Show version information"
    Write-Output "  --help, -h          Show this help message"
    Write-Output "  --output, -o        Output directory (default: current directory)"
    Write-Output "  --test, -t          Scan only *test.go files"
    Write-Output "  --all, -a           Scan all .go files"
}

for ($argIndex = 0; $argIndex -lt $args.Count; $argIndex++) {
    $arg = $args[$argIndex]
    switch -Regex ($arg) {
        '^(--help|-h)$' { $showHelp = $true }
        '^(--version|-v)$' { $showVersion = $true }
        '^(--output|-o)$' {
            if ($argIndex + 1 -ge $args.Count) {
                Write-Error "❌ Error: Missing value for option '$arg'"
                Write-Host "   Usage: powershell -File $scriptName [options] <input_path> --output <output_path>"
                exit 1
            }
            $outputDir = $args[$argIndex + 1]
            $outputToFile = $true
            $argIndex++
        }
        '^(--test|-t)$' { $scanTestOnly = $true }
        '^(--all|-a)$' { $scanAll = $true }
        default {
            # Treat as input path if it doesn't match any option
            if (-not $arg.StartsWith('-')) {
                $inputPath = $arg
            } else {
                Write-Error "❌ Error: Unknown argument: '$arg'"
                Write-Host "   Run 'powershell -File $scriptName --help' for usage information"
                exit 1
            }
        }
    }
}

# Check if no arguments provided
if ($args.Count -eq 0) {
    Show-Help
    exit 0
}

# Check for mutually exclusive parameters
if ($showVersion -and ($args.Count -gt 1)) {
    Write-Error "❌ Error: --version cannot be used with other parameters"
    Write-Output "   Usage: powershell -File $scriptName --version"
    exit 1
}

if ($showHelp -and ($args.Count -gt 1)) {
    Write-Error "❌ Error: --help cannot be used with other parameters"
    Write-Output "   Usage: powershell -File $scriptName --help"
    exit 1
}

if ($scanTestOnly -and $scanAll) {
    Write-Error "❌ Error: --test and --all are mutually exclusive options"
    Write-Host "   Use either --test (test files only) or --all (all files) or neither (default: non-test files)"
    exit 1
}

if ($showVersion) {
    Write-Output "$scriptVersion"
    exit 0
}

if ($showHelp) {
    Show-Help
    exit 0
}

# Handle output path: if it's a file, check if it exists; if it's a directory, create if needed
$outputFile = $null
if ($outputToFile) {
    if ($outputDir -ne ".") {
        # Determine if it's a file or directory based on extension
        if ($outputDir -match '\.\w+$') {
            # It's a file
            $fullPath = $outputDir
            if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
                $fullPath = Join-Path (Get-Location).Path $fullPath
            }
            if (Test-Path -LiteralPath $fullPath) {
                Write-Error "❌ Error: Output file already exists: $fullPath"
                Write-Host "   Tip: Remove the file first, or specify a different output path"
                exit 3
            }
            $outputFile = $fullPath
            $outputDir = Split-Path -Parent $fullPath
            if (-not (Test-Path -LiteralPath $outputDir)) {
                try {
                    New-Item -ItemType Directory -Path $outputDir -Force -ErrorAction Stop | Out-Null
                } catch {
                    Write-Error "❌ Error: Failed to create output directory: $outputDir"
                    Write-Host "   Tip: Check if parent directory exists and is writable"
                    exit 4
                }
            }
        } else {
            # It's a directory
            $fullPath = $outputDir
            if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
                $fullPath = Join-Path (Get-Location).Path $fullPath
            }
            if (-not (Test-Path -LiteralPath $fullPath)) {
                try {
                    New-Item -ItemType Directory -Path $fullPath -Force -ErrorAction Stop | Out-Null
                } catch {
                    Write-Error "❌ Error: Failed to create output directory: $fullPath"
                    Write-Host "   Tip: Check if parent directory is writable and you have permissions"
                    exit 4
                }
            }
            $outputDir = (Resolve-Path -LiteralPath $fullPath).Path
        }
    } else {
        $outputDir = (Resolve-Path -LiteralPath $outputDir).Path
    }

    # Generate output filename with timestamp if not explicitly specified
    if ($null -eq $outputFile) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = Join-Path $outputDir "go-doc-lint-$timestamp.txt"
    }
}

try {
    $inputItem = Get-Item -LiteralPath $inputPath -ErrorAction Stop
} catch {
    Write-Error "❌ Error: Input path not found: '$inputPath'"
    Write-Host "   Current directory: $(Get-Location)"
    Write-Host "   Tip: Use absolute path or check if file/directory exists: Test-Path '$inputPath'"
    exit 2
}

if ($inputItem.PSIsContainer) {
    $isSingleFile = $false
    $root = $inputItem.FullName
    $goFiles = Get-ChildItem -Path $root -Recurse -Filter "*.go" -File | Where-Object {
        $_.FullName -notmatch "vendor" -and $_.FullName -notmatch "\.git"
    }
} else {
    if ($inputItem.Extension -ne ".go") {
        Write-Error "❌ Error: Input file must be a .go file: '$inputPath'"
        Write-Host "   Tip: Provide a .go file or directory containing Go files"
        Write-Host "   Example: powershell -File $scriptName .\cmd\main.go"
        exit 2
    }
    $isSingleFile = $true
    $root = $inputItem.DirectoryName
    $goFiles = @($inputItem)
}

if ($scanAll) {
    # no filtering
} elseif ($scanTestOnly) {
    $goFiles = $goFiles | Where-Object { $_.Name -match '_test\.go$' }
} else {
    $goFiles = $goFiles | Where-Object { $_.Name -notmatch '_test\.go$' }
}

if ($goFiles.Count -eq 0) {
    Write-Output "No Go files to scan for selected mode."
    exit 0
}

$inputDirDisplay = $root

# Record start time for performance statistics
$startTime = Get-Date

if ((Get-Item $inputPath -ErrorAction SilentlyContinue) -is [System.IO.DirectoryInfo]) {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting to scan directory: $inputDirDisplay"
} else {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting to scan file: $inputPath"
}

Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Found $($goFiles.Count) Go file(s) to scan"

$results = @()
$count = 0
foreach ($file in $goFiles) {
    $count++

    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Split by lines but preserve indices
    $lines = $content -split "`r?`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # ===== FUNCTION DECLARATION MATCHING =====
        # Two patterns combined with -or (logical OR):
        #
        # Pattern 1: ^\s*func\s+\([^)]+\)\s+([A-Za-z_]\w*)\s*\(
        # Matches method declarations with receiver
        #   ^\s*            : Start of line, zero or more whitespace
        #   func            : Literal keyword "func"
        #   \s+             : One or more whitespace
        #   \([^)]+\)      : Parentheses containing receiver (e.g., "(b *Buffer)")
        #                     [^)]+ means "one or more chars except )"
        #   \s+             : One or more whitespace
        #   ([A-Za-z_]\w*)  : Capture group - method name:
        #                     [A-Za-z_] : First char must be letter or underscore
        #                     \w* : Followed by zero or more word characters (\w = [A-Za-z0-9_])
        #   \s*\(           : Optional whitespace then opening parenthesis for parameters
        # Example: "func (b *Buffer) Read(p []byte)" -> captures "Read"
        #
        # Pattern 2: ^\s*func\s+([A-Za-z_]\w*)\s*\(
        # Matches package-level function declarations
        #   ^\s*            : Start of line, zero or more whitespace
        #   func            : Literal keyword "func"
        #   \s+             : One or more whitespace
        #   ([A-Za-z_]\w*)  : Capture group - function name:
        #                     [A-Za-z_] : First char must be letter or underscore
        #                     \w* : Followed by zero or more word characters
        #   \s*\(           : Optional whitespace then opening parenthesis for parameters
        # Example: "func ReadData(source string)" -> captures "ReadData"
        if ($line -match '^\s*func\s+\([^)]+\)\s+([A-Za-z_]\w*)\s*\(' -or $line -match '^\s*func\s+([A-Za-z_]\w*)\s*\(') {
            # Extract function name from regex match
            $funcName = $null
            if ($line -match '^\s*func\s+\([^)]+\)\s+([A-Za-z_]\w*)\s*\(') {
                $funcName = $matches[1]  # method receiver
            } elseif ($line -match '^\s*func\s+([A-Za-z_]\w*)\s*\(') {
                $funcName = $matches[1]  # package-level function
            }

            if (-not $funcName) { continue }

# Look upward for the doc comment that directly precedes this function
            # In Go, doc comments are continuous comment lines (including empty // lines)
            # immediately above the function, ending at a true empty line or non-comment
            $commentLine = ""
            $firstCommentWord = ""
            $allCommentLines = @()

            for ($j = $i - 1; $j -ge 0; $j--) {
                $prevLine = $lines[$j]
                $trimmed = $prevLine.Trim()

                # If it's an actual empty line (not a comment), stop - doc comment block is done
                if ($trimmed -eq "") {
                    break
                }

                # If it's any comment line (including empty comment //), it's part of the doc comment
                if ($trimmed -match '^//') {
                    # Prepend to array (since we're going backwards, prepend maintains order)
                    $allCommentLines = @($trimmed) + $allCommentLines
                    continue
                }

                # Non-comment line, stop - doc comment block is done
                break
            }

            # Use the first non-empty comment line from our collected comments
            if ($allCommentLines.Count -gt 0) {
                # Find the first comment line that has actual content (not just //)
                foreach ($comment in $allCommentLines) {
                # ===== EXTRACT COMMENT FIRST WORD =====
                # Regex: ^//\s+(\S+)
                # Pattern breakdown:
                #   ^     : Start of string
                #   //    : Literal double forward slash (Go comment marker)
                #   \s+   : One or more whitespace characters (space, tab)
                #   (\S+) : Capture group - one or more non-whitespace characters (the first word)
                #           \S = [^ \t\r\n] (non-whitespace)
                # Examples:
                #   "// ReadData reads from file"  -> captures "ReadData"
                #   "// TODO: optimize"            -> captures "TODO:" (colon included)
                #   "//    MultiSpace func"        -> captures "MultiSpace"
                if ($comment -match '^//\s+(\S+)') {
                        $commentLine = $comment
                        $firstCommentWord = $matches[1]
                        break
                    }
                }
            }

            # Check if first word of comment matches function name
            if ($commentLine -ne "" -and $firstCommentWord -ne "") {
                # ===== SPECIAL COMMENT DETECTION =====
                # Regex: :$
                # Pattern breakdown:
                #   :  : Literal colon character
                #   $  : End of string anchor
                # Purpose: Identify special comment markers that should be excluded from matching
                # Examples:
                #   "TODO:"  -> matches (:$ pattern) -> EXCLUDE from mismatch detection
                #   "NOTE:"  -> matches (:$ pattern) -> EXCLUDE from mismatch detection
                #   "FIXME:" -> matches (:$ pattern) -> EXCLUDE from mismatch detection
                #   "ReadData" -> does NOT match -> INCLUDE in mismatch detection if name differs
                # Exception: if word ends with colon (e.g., TODO(daniel):), skip
                $isException = $firstCommentWord -match ':$'

                # ===== MISMATCH DETECTION CONDITION =====
                # Report mismatch if ALL conditions are met:
                #   1. $firstCommentWord -ne $funcName : Comment first word differs from function name
                #                                        (Case-sensitive comparison)
                #   2. -not $isException               : First word does NOT end with colon
                #                                        (Filters out TODO:, NOTE:, FIXME:, etc.)
                # Examples:
                #   Comment: "// read ..."   Function: "ReadData"    -> MISMATCH (read != ReadData)
                #   Comment: "// TODO: ..."  Function: "OptimizeMe"  -> NO MISMATCH (TODO: is exception)
                #   Comment: "// NOTE: ..."  Function: "Helper"      -> NO MISMATCH (NOTE: is exception)
                #   Comment: "// ReadData .." Function: "ReadData"   -> NO MISMATCH (exact match)
                if ($firstCommentWord -ne $funcName -and -not $isException) {
                    # Convert to relative path by removing the input root
                    $relPath = $file.FullName
                    if ($root) {
                        # Ensure root ends with backslash for consistent replacement
                        $rootWithSlash = if ($root.EndsWith('\')) { $root } else { "$root\" }
                        $relPath = $relPath -replace [regex]::Escape($rootWithSlash), ""
                    }

                    $obj = New-Object PSObject -Property @{
                        FileName = $relPath
                        LineNum = $i + 1
                        FuncName = $funcName
                        FirstCommentWord = $firstCommentWord
                        CommentLine = $commentLine
                        FuncDeclLine = $line
                    }
                    $results += $obj
                }
            }
        }
    }
}

# Calculate elapsed time
$endTime = Get-Date
$elapsedSeconds = [math]::Round(($endTime - $startTime).TotalSeconds, 1)

if ($outputToFile) {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Scanning complete, found $($goFiles.Count) go files ($($elapsedSeconds)s)"
    if ($results.Count -eq 0) {
        Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] No mismatches found!"
    } else {
        Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Found $($results.Count) function comment mismatches"
    }
}

# ============================================
# PART 2: Generate Detailed Report
# ============================================

$outputLines = @()
$outputLines += "$productName"
$outputLines += "=" * 80
$outputLines += "Input Path: $inputDirDisplay"
$outputLines += "Total Mismatches: $($results.Count)"
$outputLines += ""

foreach ($item in $results) {
    $outputLines += "File: $($item.FileName)"
    $outputLines += "  Comment First Word: $($item.FirstCommentWord)"
    $outputLines += "  Function Name: $($item.FuncName)"
    $outputLines += "  Comment Line: $($item.CommentLine)"
    $outputLines += "  Function Declaration: $($item.FuncDeclLine.Trim())"
    $outputLines += ""
}

$detailedFile = Join-Path $outputDir "function_comment_mismatches.txt"
$outputLines -join "`n" | Out-File $detailedFile -Encoding UTF8

# ============================================
# PART 3: Generate Minimal Report
# ============================================

$in = $detailedFile
$outAll = $outputFile

$lines = Get-Content $in -ErrorAction SilentlyContinue
$resultAll = @()

if ($lines) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^File:\s*(.+)$') {
            $file = $matches[1]
            $comment = ''
            $func = ''

            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\s*Comment Line:\s*(.+)$') {
                    $comment = $matches[1]
                } elseif ($lines[$j] -match '^\s*Function Declaration:\s*(.+)$') {
                    $func = $matches[1]
                } elseif ($lines[$j] -match '^\s*$') {
                    break
                }
            }

            if ($file -and $comment -and $func) {
                # Add to results
                $resultAll += "$file"
                $resultAll += "$comment"
                $resultAll += "$func"
                $resultAll += ""
            }
        }
    }
}

# Function to generate summary by top-level directory
function GenerateDirSummary {
    param($resultArray)

    $dirStats = @{}

    # Extract directory stats from resultArray (every 4 elements is one entry: file, comment, func, blank)
    for ($i = 0; $i -lt $resultArray.Count; $i += 4) {
        if ($resultArray[$i]) {
            $file = $resultArray[$i]

            # Extract the first directory component (top-level directory)
            # Handle both relative paths (e.g., "accounts\file.go") and
            # any remaining absolute paths (e.g., "E:\accounts\file.go")
            $topDir = $file

            # Remove drive letter if present (e.g., "E:\accounts" -> "accounts")
            if ($file -match '^[A-Za-z]:[\\/](.+)') {
                $file = $matches[1]
            }

            # Extract first directory component before backslash or forward slash
            if ($file -match '^([^\\\/]+)[\\/]') {
                $topDir = $matches[1]
            } elseif ($file -match '^([^\\\/]+)$') {
                # Single file without directory
                $topDir = $matches[1]
            }

            if (-not $dirStats.ContainsKey($topDir)) {
                $dirStats[$topDir] = 0
            }
            $dirStats[$topDir]++
        }
    }

    return $dirStats
}

# Calculate counts first
$allCount = ($resultAll.Count - ($resultAll | Where-Object { $_ -eq "" }).Count) / 3

# Remove trailing empty line if exists
if ($resultAll.Count -gt 0 -and $resultAll[-1] -eq "") {
    $resultAll = $resultAll[0..($resultAll.Count - 2)]
}

# Generate directory statistics
$dirStatsAll = GenerateDirSummary $resultAll

# Function to create summary header
function CreateSummaryHeader {
    param($dirStats, $totalCount, $inputDir, $isSingleFile)

    $lines = @()
    $lines += "=" * 80
    $lines += (" " * 36) + "Summary"
    $lines += ("tool").PadRight(9) + " $productName"
    $lines += ("version").PadRight(9) + " $scriptVersion"
    $lines += ("input").PadRight(9) + " $inputDir"
    $lines += ("time").PadRight(9) + " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $lines += ("findings").PadRight(9) + " $totalCount"
    $lines += ""

    if (-not $isSingleFile -and $dirStats.Count -gt 0) {
        $lines += "=" * 80
        $lines += (" " * 29) + "Directory statistics"

        # Sort directories by name
        $sortedDirs = $dirStats.Keys | Sort-Object

        # Find the longest directory name
        $maxDirLength = ($sortedDirs | Measure-Object -Property Length -Maximum).Maximum

        foreach ($dir in $sortedDirs) {
            $count = $dirStats[$dir]
            $lines += $dir.PadRight($maxDirLength) + " : $count"
        }

        $lines += ""
    }
    $lines += "=" * 80
    $lines += (" " * 31) + "Findings details"
    $lines += ""
    $lines += "=" * 80

    return $lines
}

# Create summary header
$summaryAll = CreateSummaryHeader $dirStatsAll $allCount $inputDirDisplay $isSingleFile

# Combine summary with results
$finalAll = $summaryAll + $resultAll

if ($outputToFile -and $null -ne $outAll) {
    $finalAll | Out-File $outAll -Encoding UTF8
} else {
    # Output to screen
    $finalAll | ForEach-Object { Write-Output $_ }
}

# ============================================
# PART 4: Cleanup
# ============================================

$filesToRemove = @(
    $detailedFile,
    (Join-Path $outputDir 'function_scan_output.txt'),
    (Join-Path $outputDir 'function_mismatches_min.txt'),
    (Join-Path $outputDir 'SCANNING_SUMMARY.md'),
    (Join-Path $outputDir 'FUNCTION_MISMATCH_REPORT.md'),
    (Join-Path $outputDir 'README_SCAN_RESULTS.md')
)

foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        Remove-Item $file -Force
    }
}

if ($outputToFile -and $null -ne $outAll) {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Save report: $outAll"
}

# Performance Benchmarks

[中文版](BENCHMARKS_cn.md) | English

## Overview

These benchmarks provide a **rough reference** for go-doc-lint performance on typical Go projects. Results vary by hardware, OS, shell version, and file structure.

---

## Test Environment

- **CPU**: 8-core modern x86
- **Memory**: 16 GB
- **Disk**: SSD
- **OS**: Windows 11 / Ubuntu 22.04
- **Bash**: 5.x
- **PowerShell**: 5.1 / 7.x

---

## Methodology

1. Warm up the filesystem cache
2. Run each command 3 times
3. Report median time
4. Use local filesystem (no network mounts)

Example timing command:

```bash
/usr/bin/time -p ./go-doc-lint.sh ./sample-project
```

---

## Results (Typical Project)

Project profile:

- ~1,000 Go files
- ~15,000 total lines
- Standard module layout (`cmd/`, `pkg/`, `internal/`)

| Operation             | Bash (sec) | PowerShell (sec) | Notes              |
| --------------------- | ---------- | ---------------- | ------------------ |
| Scan all .go files    | 1.8        | 2.1              | Full project scan  |
| Scan test files only  | 0.9        | 1.2              | `--test`           |
| Scan single directory | 0.6        | 0.8              | `./pkg`            |
| Output to file        | +0.1       | +0.1             | Minor I/O overhead |

---

## Scaling Notes

- Runtime scales roughly **linearly** with file count.
- Large files with massive comment blocks may add overhead.
- Performance is generally I/O-bound rather than CPU-bound.

---

## Tips for Faster Scans

- Scan specific directories instead of repository root when possible.
- Avoid scanning generated code directories.
- Use `--test` or `--all` only when needed.
- Write output to file for large result sets.

---

**Last Updated**: 2026-02-01

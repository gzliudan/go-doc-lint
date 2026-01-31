# Go 文档检查工具使用说明

[English](README.md) | 中文版

## 工具简介

`go-doc-lint` 是一个用于检查 Go 源代码中函数注释是否规范的命令行工具。它会扫描 Go 文件，检查函数的文档注释首词是否与函数名匹配。

## 功能特性

- ✅ 支持 Windows PowerShell 和 Linux/Unix 环境
- ✅ 支持批量扫描目录或单个文件
- ✅ 灵活的输出选项（屏幕或文件）
- ✅ 支持文件类型过滤（测试文件、生产文件或全部）
- ✅ 详细的错误报告和日志
- ✅ 多层级目录统计
- ✅ 参数互斥检查

## 脚本对应关系

| 操作系统       | 脚本文件        | 执行方式                                |
| -------------- | --------------- | --------------------------------------- |
| Windows        | go-doc-lint.ps1 | powershell -File go-doc-lint.ps1        |
| Linux/Unix/WSL | go-doc-lint.sh  | ./go-doc-lint.sh 或 bash go-doc-lint.sh |

## 快速入门

快速开始使用 go-doc-lint：

### 1. 扫描您的 Go 项目（最常见）

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/
```

### 2. 将结果保存到文件

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/ -o report.txt
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/ -o report.txt
```

### 3. 仅扫描测试文件

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/ --test
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/ --test
```

### 4. 扫描单个文件

**Windows:**

```powershell
powershell -File go-doc-lint.ps1 ./myproject/types.go
```

**Linux/Unix/macOS/WSL:**

```bash
./go-doc-lint.sh ./myproject/types.go
```

💡 **提示：** 查看[参数说明](#参数说明)部分了解所有可用选项。

## 基本使用

### 查看帮助

```bash
# PowerShell
powershell -File go-doc-lint.ps1 --help

# Bash
./go-doc-lint.sh --help
```

### 查看版本

```bash
# PowerShell
powershell -File go-doc-lint.ps1 --version

# Bash
./go-doc-lint.sh --version
```

## 系统要求

### Windows 要求

- **PowerShell 5.0 或更高版本**（Windows 10+ 默认包含）
- **Windows 10** 或更新版本（推荐）

#### PowerShell 版本映射

| PowerShell 版本 | Windows 版本                        | 默认包含   |
| --------------- | ----------------------------------- | ---------- |
| 5.0 / 5.1       | Windows 10 (Build 1607+)            | 是         |
| 5.1             | Windows Server 2016+                | 是         |
| 7.0+            | Windows 10/11, Windows Server 2016+ | 否（可选） |

**检查版本:** `$PSVersionTable.PSVersion`

### Linux/Unix/macOS 要求

- **Bash 4.0 或更高版本**
- **Perl**（用于注释解析）
- **标准工具**：`awk`、`grep`、`sed`

### 系统资源

- **CPU**：无特殊要求（I/O 密集型）
- **内存**：< 50MB（适用于典型项目）
- **磁盘**：无特殊要求
- **网络**：不需要

---

## 参数说明

### 必需参数

| 参数           | 说明                              | 示例                               |
| -------------- | --------------------------------- | ---------------------------------- |
| `<input_path>` | 输入路径，可为目录或单个 .go 文件 | `./common/` 或 `./common/types.go` |

### 可选参数

| 参数                  | 说明                                       | 默认值         |
| --------------------- | ------------------------------------------ | -------------- |
| `-o, --output <path>` | 输出路径（文件或目录），不指定则输出到屏幕 | 屏幕输出       |
| `-t, --test`          | 仅扫描 *_test.go 文件                      | 扫描非测试文件 |
| `-a, --all`           | 扫描所有 .go 文件                          | 扫描非测试文件 |
| `-h, --help`          | 显示帮助信息                               | -              |
| `-v, --version`       | 显示版本信息                               | -              |

### 参数互斥关系

- `--version` 不能与其他参数组合使用
- `--help` 不能与其他参数组合使用
- `--test` 和 `--all` 不能同时使用

## 路径说明

### 输入路径 (input_path)

输入路径支持 **绝对路径** 和 **相对路径**：

- **相对路径**：相对于脚本执行时的当前工作目录
  - `./common/` - 当前目录下的 common 子目录
  - `../accounts/` - 上级目录的 accounts 子目录
  - `core/types.go` - 当前目录下的 core/types.go 文件

- **绝对路径**：从根目录开始的完整路径
  - Windows: `C:\Users\username\projects\go-ethereum\common\`
  - Linux/Unix: `/home/username/projects/go-ethereum/common/`
  - WSL: `/mnt/e/go-ethereum/common/`

### 输出路径 (-o, --output)

输出路径同样支持 **绝对路径** 和 **相对路径**：

- **相对路径**：相对于脚本执行时的当前工作目录
  - `report.txt` - 保存为当前目录下的 report.txt
  - `output/report.txt` - 当前目录下 output 子目录中
  - `../results/` - 上级目录的 results 子目录（自动生成时间戳文件名）

- **绝对路径**：完整的文件或目录路径
  - Windows: `C:\reports\lint-result.txt`
  - Linux/Unix: `/var/reports/lint-result.txt`
  - WSL: `/mnt/e/reports/lint-result.txt`

**路径自动规范化**：工具会自动将路径转换为绝对路径进行处理，确保结果准确无误。

## 使用示例

### 示例1：扫描目录，结果输出到屏幕

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/

# Bash
./go-doc-lint.sh ./common/
```

**输出示例：**

```text
================================================================================
                                    Summary
tool:     golang document linter
version:  v1.0.0
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

说明："目录统计" 部分仅在扫描含有结果的目录时显示。

### 示例2：扫描目录，结果保存到文件

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/ -o report.txt

# Bash
./go-doc-lint.sh ./common/ -o report.txt
```

**屏幕输出：**

```text
[2026-01-31 19:38:00] Starting to scan directory: ./common
[2026-01-31 19:38:01] Scanning complete, found 45 go files
[2026-01-31 19:38:02] Save report: ./report.txt
```

### 示例3：扫描目录，结果保存到指定目录

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./accounts/ -o output/

# Bash
./go-doc-lint.sh ./accounts/ -o output/
```

**说明：** 如果指定的目录不存在，工具会自动创建。结果文件名将为 `go-doc-lint-YYYYMMDD-HHMMSS.txt`

### 示例4：扫描嵌套目录结构

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./accounts/ -o result/nested/report.txt

# Bash
./go-doc-lint.sh ./accounts/ -o result/nested/report.txt
```

**说明：** 工具会自动创建所有必需的中间目录

### 示例5：仅扫描测试文件

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/ --test

# Bash
./go-doc-lint.sh ./common/ --test
```

### 示例6：扫描所有 Go 文件（包括测试文件）

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/ --all

# Bash
./go-doc-lint.sh ./common/ --all
```

### 示例7：扫描单个文件

```bash
# PowerShell
powershell -File go-doc-lint.ps1 ./common/types.go

# Bash
./go-doc-lint.sh ./common/types.go
```

## 输出说明

### 输出到屏幕的内容

当不指定 `--output` 参数时，工具直接输出报告到屏幕，包含：

1. **摘要部分**
   - 工具名称和版本
   - 输入路径
   - 执行时间
   - 发现的问题总数

2. **目录统计** （仅在扫描目录且包含多个子目录时显示）
   - 各目录的不匹配数量（对齐格式）
   - 仅在有发现且存在多个顶级目录时显示

3. **发现详情**
   - 文件名
   - 注释行
   - 函数声明

### 输出到文件的行为

当指定 `--output` 参数时：

1. **屏幕显示**
   - 扫描开始：`[时间戳] Starting to scan directory/file: <路径>`
   - 扫描完成：`[时间戳] Scanning complete, found X go files`
   - 保存结果：`[时间戳] Save report: <文件路径>`

2. **文件内容**
   - 摘要部分（包含工具名、版本、输入路径、执行时间、发现数量）
   - 目录统计（仅在扫描目录且有多个子目录时显示）
   - 发现详情列表（所有不匹配的函数）
   - 所有部分用 `================================================================================` 分隔

## 退出码

| 退出码 | 含义                                       |
| ------ | ------------------------------------------ |
| 0      | 成功                                       |
| 1      | 参数错误（如参数互斥冲突或参数值缺失）     |
| 2      | 输入路径无效（路径不存在或文件格式不正确） |
| 3      | 输出文件已存在                             |
| 4      | 创建输出目录失败                           |

## 常见问题

### Q1：工具支持哪些操作系统？

**A:**

- **Windows**: 使用 PowerShell 脚本 `go-doc-lint.ps1`
- **Linux/Unix/macOS**: 使用 Bash 脚本 `go-doc-lint.sh`
- **Windows with WSL**: 可使用 Bash 脚本

### Q2：如何处理输出文件已存在的情况？

**A:** 工具会报错并退出（退出码 3）。您可以：

- 删除已存在的文件后重新运行
- 使用不同的输出文件名
- 指定为目录，让工具自动生成时间戳文件名

### Q3：扫描哪些文件类型？

**A:**

- 默认：扫描非测试文件（即不以 `_test.go` 结尾的文件）
- `--test`：仅扫描 `*_test.go` 文件
- `--all`：扫描所有 `.go` 文件

### Q4：报告中的不匹配是什么意思？

**A:** 函数的文档注释首词与函数名不一致。例如：

```go
// Read 从文件中读取数据
func Write(data []byte) error {  // 注释说 Read，但函数名是 Write
    // ...
}
```

### Q5：能否扫描递归子目录？

**A:** 是的，工具默认递归扫描目录中的所有 Go 文件，并自动排除 `vendor` 和 `.git` 目录。

## 技术细节

### 注释匹配规则

1. 函数上方连续的 `//` 注释被视为文档注释
2. 取注释第一个非空词作为"首词"
3. 将首词与函数名比较
4. 以冒号结尾的词（如 `TODO:`、`NOTE:`）被忽略
5. 大小写敏感

### 输出文件命名

- 指定为文件名时：使用指定的文件名
- 指定为目录时：自动生成 `go-doc-lint-YYYYMMDD-HHMMSS.txt`
  - YYYYMMDD：执行日期
  - HHMMSS：执行时间（24小时制）

## 测试

项目包含完整的 Bash 和 PowerShell 测试套件。

### 运行测试

**Bash 测试套件：**

```bash
bash test.sh
```

**PowerShell 测试套件：**

```powershell
.\test.ps1
```

测试脚本将：

- 验证所有核心功能（版本、帮助、扫描、过滤、输出）
- 检查错误处理和边界情况
- 验证报告格式和内容
- 显示彩色的通过/失败结果

## 更多信息

了解更多有关使用和集成本工具的信息：

- 📚 [最佳实践](doc/BEST_PRACTICES_cn.md) - 集成指南、前置提交钩子、CI/CD 示例、性能优化建议
- 📋 [更新日志](CHANGELOG_cn.md) - 版本历史和发布说明
- 🧪 [测试指南](doc/Test_cn.md) - 如何运行测试
- 🧭 [架构指南](doc/ARCHITECTURE_cn.md) - 设计概览与实现细节
- 🔧 [故障排查](doc/TROUBLESHOOTING_cn.md) - 高级故障排查与问题解决
- ❓ [常见问题](doc/FAQ_cn.md) - 常见问题与快速解答
- 📈 [性能基准](doc/BENCHMARKS_cn.md) - 性能参考数据
- 📦 [示例项目](examples/README_cn.md) - 用于快速测试的示例工程
- 🔍 [正则表达式注释](doc/REGEX_COMMENTS_cn.md) - 正则表达式模式详解
- ⚡ [TODO](TODO.md) - 未来改进的机会

## 贡献指南

欢迎贡献！请查看 [CONTRIBUTING_cn.md](CONTRIBUTING_cn.md) 了解如何为本项目做出贡献的指南。

## 许可证

MIT License

---

**最后更新**: 2026-02-01
**版本**: v1.0.0

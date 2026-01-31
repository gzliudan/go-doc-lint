# 故障排查指南

[English](TROUBLESHOOTING.md) | 中文版

## 概述

本指南涵盖 go-doc-lint 的进阶故障排查和问题解决。有关基础问题，请参见 [README.md 中的常见问题部分](../README_cn.md#常见问题)。

---

## 目录

1. [性能问题](#性能问题)
2. [输出和格式问题](#输出和格式问题)
3. [集成和工作流问题](#集成和工作流问题)
4. [平台特定问题](#平台特定问题)
5. [Go 代码分析问题](#go-代码分析问题)
6. [调试技巧](#调试技巧)
7. [获取帮助](#获取帮助)

---

## 性能问题

### 问题：工具运行非常缓慢

**症状**：

- 扫描 100 个文件的项目耗时 >10 秒
- 扫描期间 CPU 使用率很高
- 内存使用显著增加

**诊断步骤**：

1. **检查文件数量**：

   ```bash
   find . -name "*.go" -type f | wc -l
   ```

2. **识别大文件**：

   ```bash
   find . -name "*.go" -type f -exec wc -l {} + | sort -rn | head -20
   ```

3. **检查问题模式**：
   - 超过 10,000 行的文件（Go 中罕见，但可能存在）
   - 包含极长函数声明的文件
   - 包含大量注释块的文件

**解决方案**：

1. **显式排除 vendor 目录**（应自动执行，但要验证）：

   ```bash
   ./go-doc-lint.sh ./src --exclude vendor --exclude .git
   ```

2. **分割大型项目**：

   ```bash
   # 分别扫描不同目录
   ./go-doc-lint.sh ./cmd
   ./go-doc-lint.sh ./pkg
   ./go-doc-lint.sh ./internal
   ```

3. **对工具进行性能分析**（供开发者）：

   ```bash
   time ./go-doc-lint.sh ./large-project/
   ```

4. **检查系统资源**：

   ```bash
   # Unix/Linux
   top -p $$ # 监控内存使用

   # Windows PowerShell
   Get-Process -Id $PID | Select-Object WorkingSet
   ```

### 问题：大型项目的内存使用高

**症状**：

- 内存使用超过 200MB
- 在 50,000+ 文件的项目上工具崩溃
- 扫描期间系统变得无响应

**解决方案**：

1. **使用流输出**：

   ```bash
   # 写入文件而不是缓冲到内存
   ./go-doc-lint.sh ./huge-project/ -o report.txt
   ```

2. **批量扫描**：

   ```bash
   for dir in $(find . -maxdepth 2 -type d -name "*.go*"); do
     ./go-doc-lint.sh "$dir" -o "report-${dir//\//-}.txt"
   done
   ```

3. **检查注释解析器问题**：
   - 某些具有不寻常注释模式的文件可能导致内存峰值
   - 手动检查有问题的文件

---

## 输出和格式问题

### 问题：输出看起来乱码或编码错误

**症状**：

- Unicode 字符显示为 `?` 或转义序列
- 中文/日文/韩文字符无法正确呈现
- 注释中的表情符号导致显示问题

**原因**：

- 终端编码未设置为 UTF-8
- PowerShell 编码设置不正确
- 源代码文件编码问题

**解决方案**：

1. **设置终端编码 (Bash/Linux)**：

   ```bash
   export LANG=en_US.UTF-8
   export LC_ALL=en_US.UTF-8
   ./go-doc-lint.sh ./project/
   ```

2. **设置 PowerShell 编码**：

   ```powershell
   [System.Environment]::SetEnvironmentVariable('PYTHONIOENCODING', 'utf-8')
   .\go-doc-lint.ps1 .\project\
   ```

3. **检查文件编码**：

   ```bash
   # 显示文件编码
   file -bi yourfile.go

   # 如果需要，转换为 UTF-8
   iconv -f ISO-8859-1 -t UTF-8 yourfile.go > yourfile-utf8.go
   ```

### 问题：报告不符合预期格式

**症状**：

- 列对齐不正确
- 标题缺失或错误
- 预期显示目录统计时未显示

**常见原因**：

- 输出重定向问题（混合 stdout 和 stderr）
- 终端宽度太窄
- 将输出管道到另一个命令

**解决方案**：

1. **检查终端宽度**：

   ```bash
   echo "Terminal width: $COLUMNS"
   # 预期：80+ 个字符
   ```

2. **使用显式输出选项**：

   ```bash
   # 而不是管道
   ./go-doc-lint.sh ./project/ > report.txt 2>&1

   # 使用显式文件输出
   ./go-doc-lint.sh ./project/ -o report.txt
   ```

3. **验证报告完整性**：

   ```bash
   # 检查文件大小是否合理
   wc -c report.txt

   # 检查预期的标题
   grep -c "^===" report.txt  # 应该有多条分隔符行
   ```

---

## 集成和工作流问题

### 问题：工具不适用于前置提交钩子

**症状**：

- 前置提交钩子不触发工具
- 钩子运行但在不匹配时不失败
- 钩子输出中未显示工具输出

**诊断**：

1. **验证钩子配置正确**：

   ```bash
   cat .pre-commit-config.yaml | grep -A 5 go-doc-lint
   ```

2. **手动测试钩子**：

   ```bash
   pre-commit run go-doc-lint --all-files
   ```

3. **检查钩子阶段**：

   ```bash
   # 钩子应在 'commit' 或 'push' 阶段运行
   pre-commit hook-impl --hook-type pre-commit
   ```

**解决方案**：

1. **更新 .pre-commit-config.yaml**：

   ```yaml
   - repo: https://github.com/gzliudan/go-doc-lint
     rev: v1.0.0
     hooks:
       - id: go-doc-lint
         language: script
         types: [go]
         stages: [commit]
   ```

2. **确保工具已安装**：

   ```bash
   which go-doc-lint.sh
   # 或 PowerShell：
   Get-Command go-doc-lint.ps1
   ```

3. **检查文件权限**：

   ```bash
   ls -la go-doc-lint.sh
   # 应具有执行权限：-rwxr-xr-x
   chmod +x go-doc-lint.sh
   ```

### 问题：工具在 CI/CD 管道中失败

**症状**：

- 本地有效但在 GitHub Actions/GitLab CI/Jenkins 中失败
- CI 报告"command not found"或"script failed"
- 退出代码与预期不匹配

**诊断步骤**：

1. **检查 CI 日志的错误消息**
2. **验证管道中的工具路径**
3. **检查环境变量**
4. **验证文件权限**

**解决方案**：

**GitHub Actions**：

```yaml
- name: Run go-doc-lint
  run: |
    chmod +x go-doc-lint.sh
    ./go-doc-lint.sh ./cmd/
  continue-on-error: false  # 如果发现不匹配则失败
```

**GitLab CI**：

```yaml
lint-docs:
  script:
    - chmod +x go-doc-lint.sh
    - ./go-doc-lint.sh ./cmd/
  allow_failure: false
```

**Jenkins**：

```groovy
stage('Lint Docs') {
  steps {
    sh 'chmod +x go-doc-lint.sh'
    sh './go-doc-lint.sh ./cmd/'
  }
}
```

### 问题：工具失败，显示"权限被拒绝"

**症状**：

- 错误："Permission denied"运行脚本时
- 尽管文件存在但无法执行
- 作为管理员/root 运行可以，但普通用户不行

**解决方案**：

1. **修复文件权限**：

   ```bash
   chmod +x go-doc-lint.sh
   chmod +x test.sh
   ```

2. **检查目录权限**：

   ```bash
   ls -ld . # 当前目录应该可读和可执行
   ```

3. **使用显式解释器运行**（如需）：

   ```bash
   bash go-doc-lint.sh ./project/
   # 或 PowerShell
   powershell -File go-doc-lint.ps1 .\project\
   ```

---

## 平台特定问题

### Windows：ExecutionPolicy 阻止脚本执行

**错误**：

```text
文件 go-doc-lint.ps1 无法加载。该文件未经数字签名。
```

**解决方案**：

1. **临时绕过当前会话**：

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   .\go-doc-lint.ps1 .\project\
   ```

2. **永久更改当前用户**：

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **使用显式调用**：

   ```powershell
   powershell -ExecutionPolicy Bypass -File go-doc-lint.ps1 .\project\
   ```

### Windows：包含空格和特殊字符的路径问题

**问题**：包含空格或非 ASCII 字符的路径失败

**解决方案**：

```powershell
# 正确引用路径
.\go-doc-lint.ps1 "C:\My Projects\go-app"

# 使用 -Path 参数
.\go-doc-lint.ps1 -Path ".\projects\my project"
```

### Unix：区域设置导致 Unicode 问题

**问题**：非 ASCII 字符显示不正确

**解决方案**：

```bash
# 设置正确的区域
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
./go-doc-lint.sh ./project/

# 或添加到 ~/.bashrc 以保持改变
echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
```

### WSL：文件权限问题

**问题**：WSL 中文件权限似乎错误

**解决方案**：

```bash
# 为新文件设置 umask
umask 0022

# 修复现有文件
chmod 755 go-doc-lint.sh test.sh
```

---

## Go 代码分析问题

### 问题：工具遗漏某些注释或函数

**症状**：

- 没有适当注释的某些函数未报告
- 应该匹配的注释被标记为不匹配
- 工具报告不存在的函数

**常见原因**：

1. 格式不寻常的注释
2. 嵌套函数或闭包
3. 接口方法签名
4. 带有特殊标记的生成代码

**解决方案**：

1. **检查注释格式** - 注释必须：
   - 在函数上方的行中（无空行）
   - 以 `//` 开头（不是 `/*` 或 `/**`）

   ```go
   // 好：注释直接在函数上方
   // ReadFile 从文件中读取内容
   func ReadFile(path string) ([]byte, error) {

   // 不好：空行打破注释块

   // ReadFile 从文件中读取内容
   func ReadFile(path string) ([]byte, error) {
   ```

2. **验证函数声明格式**：

   ```bash
   # 提取函数声明以验证
   grep -n "^func " yourfile.go
   ```

3. **检查生成的代码标记**：

   ```bash
   # 生成的代码通常有特殊标记
   grep -l "Code generated by" *.go
   # 考虑排除这些文件
   ```

### 问题：误报（报告为不匹配，但实际正确）

**症状**：

- 注释被标记，尽管它们匹配
- 别名或快捷方式无法识别
- 包级注释被视为函数注释

**示例误报**：

```go
// NewReader 创建 Reader（可能是：NewReader 如同 New）
func NewReader() *Reader { // 但工具期望：NewReader
```

**解决方案**：

1. **理解匹配规则**：
   - 注释首词必须完全匹配函数名
   - 区分大小写
   - 以 `:` 结尾的词（TODO、NOTE 等）被忽略

2. **验证注释模式**：

   ```bash
   # 提取函数上方注释的首词
   grep -B1 "^func " yourfile.go | grep "^//" | sed 's/.*\/\/ //' | cut -d' ' -f1
   ```

3. **记录有意的不匹配**：

   ```go
   // Reader 包装带缓冲的 io.Reader（合法描述）
   func NewReader(rd io.Reader) *Reader { // 记录为什么注释不匹配
   ```

### 问题：特定文件的性能问题

**症状**：

- 一个文件导致显著减速
- 处理某些文件时内存峰值
- 解析器在特定代码模式上挂起

**诊断**：

```bash
# 用单个文件测试
time ./go-doc-lint.sh ./specific-slow-file.go

# 检查文件大小
wc -l ./specific-slow-file.go

# 查找问题模式
grep -n "//.*$" ./specific-slow-file.go | head -20  # 许多注释
```

**解决方案**：

1. **临时排除问题文件**：

   ```bash
   ./go-doc-lint.sh ./project/ --exclude problematic-file.go
   ```

2. **分割大型文件**：
   - Go 最佳实践建议文件 <500 行
   - 拆分文件可改善整体性能

3. **如果模式是有效的 Go 代码，则报告为问题**：
   - 包含特定问题代码
   - 包含文件大小和注释数
   - 包含系统规格（OS、shell 版本）

---

## 调试技巧

### 启用调试输出（开发者模式）

供贡献者调试工具本身：

**Bash**：

```bash
# 使用 bash 调试模式运行
bash -x go-doc-lint.sh ./project/ 2>&1 | head -100

# 或在脚本中启用
set -x  # 在 go-doc-lint.sh 开头
```

**PowerShell**：

```powershell
# 使用详细输出运行
.\go-doc-lint.ps1 .\project\ -Verbose

# 或启用调试首选项
$DebugPreference = "Continue"
```

### 用最小化输入测试

**创建最小测试用例**：

```bash
# 创建测试目录
mkdir test-case
cd test-case

# 创建简单 Go 文件
cat > main.go << 'EOF'
package main

// Main 是入口点
func Main() {
  println("test")
}
EOF

# 在测试用例上运行工具
../go-doc-lint.sh .
```

### 捕获完整输出以供分析

```bash
# Bash：使用时间戳捕获 stdout 和 stderr
./go-doc-lint.sh ./project/ 2>&1 | sed "s/^/[$(date +'%H:%M:%S')] /" > debug.log

# PowerShell：类似方法
$ErrorActionPreference = "Continue"
.\go-doc-lint.ps1 .\project\ 2>&1 | ForEach-Object { "[$(Get-Date -Format 'HH:mm:ss')] $_" } | Tee-Object -FilePath debug.log
```

### 验证测试套件

```bash
# 使用详细输出运行测试
bash -v test.sh 2>&1 | head -200

# 或 PowerShell
.\test.ps1 -Verbose
```

---

## 获取帮助

### 检查文档

1. **README.md** - 基本用法和快速开始
2. **BEST_PRACTICES.md** - 集成模式和常见用法
3. **ARCHITECTURE.md** - 设计和实现详情
4. **测试文件** - 真实世界使用示例

### 报告问题

报告错误时，请包含：

1. **工具版本**：

   ```bash
   ./go-doc-lint.sh --version
   # 或
   .\go-doc-lint.ps1 -Version
   ```

2. **系统信息**：

   ```bash
   # Unix/Linux
   uname -a
   bash --version
   perl --version

   # Windows
   $PSVersionTable.PSVersion
   ```

3. **最小复现**：
   - 包含触发问题的小代码样本
   - 包含使用的确切命令行
   - 包含完整的错误输出

4. **复现步骤**：

   ```bash
   git clone https://github.com/gzliudan/go-doc-lint.git
   cd go-doc-lint
   ./go-doc-lint.sh [your test case]
   ```

### 支持资源

- **GitHub Issues**：[报告错误或请求功能](https://github.com/gzliudan/go-doc-lint/issues)
- **GitHub Discussions**：提出问题和讨论
- **代码示例**：检查 `fixtures/` 目录的测试用例
- **贡献指南**：参见 [CONTRIBUTING_cn.md](../CONTRIBUTING_cn.md) 了解开发设置

---

## 常见错误消息和解决方案

### "No such file or directory"

**原因**：输入路径不存在

**解决方案**：

```bash
# 验证路径存在
ls -la ./your-path/
# 或
cd ./your-path && pwd
```

### "Permission denied"

**原因**：脚本不可执行或目录不可读

**解决方案**：

```bash
chmod +x go-doc-lint.sh
chmod +x test.sh
```

### "Perl: command not found"

**原因**：Perl 未安装

**解决方案**：

```bash
# Ubuntu/Debian
sudo apt-get install perl

# macOS
brew install perl
# 或使用系统 Perl（通常预装）
```

### "ExecutionPolicy"

**原因**：PowerShell 执行策略阻止运行脚本

**解决方案**：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Ambiguous output filename"

**原因**：输出路径是目录但包含特殊字符或不明确

**解决方案**：

```bash
# 使用显式文件名
./go-doc-lint.sh ./project/ -o ./reports/result.txt

# 首先创建目录
mkdir -p ./reports
./go-doc-lint.sh ./project/ -o ./reports/
```

---

## 快速参考：按症状求解

| 症状                | 最可能原因                 | 快速修复                                     |
| ------------------- | -------------------------- | -------------------------------------------- |
| "command not found" | 脚本不在 PATH 中或不可执行 | `chmod +x && ./go-doc-lint.sh`               |
| 性能缓慢            | 大型项目或系统资源问题     | 分割扫描或使用 `-o file.txt`                 |
| 编码错误            | 区域/终端编码问题          | `export LANG=en_US.UTF-8`                    |
| 误报                | 误解匹配规则               | 审查[注释规则](../README_cn.md#注释匹配规则) |
| CI/CD 失败          | 路径或环境变量问题         | 检查 CI 日志并使用绝对路径                   |
| 工具挂起            | 大型或问题 Go 文件         | 排除文件或分割项目                           |
| 遗漏发现            | 注释格式问题               | 确保注释在连续行中                           |

---

**最后更新**：2026-02-01
**版本**：1.0.0

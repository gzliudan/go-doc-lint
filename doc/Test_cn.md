# go-doc-lint 测试指南

[English](Test.md) | 中文版

本文档描述了 go-doc-lint 工具 Bash 和 PowerShell 实现的综合测试套件。

相关文档：

- [架构指南](ARCHITECTURE_cn.md) - 设计概览与实现细节
- [故障排查指南](TROUBLESHOOTING_cn.md) - 高级故障排查与问题解决

## 测试结构

测试脚本位于**根目录**，测试数据位于 `fixtures/` 目录中：

```text
go-doc-lint/                # 根目录
├── test.sh                # Bash 测试套件
├── test.ps1               # PowerShell 测试套件
├── Test.md                # 英文测试指南
├── Test_cn.md             # 中文测试指南（本文件）
└── fixtures/              # 测试数据目录
    ├── valid/             # 文档正确的文件
    ├── invalid/           # 文档不匹配的文件
    ├── mixed/             # 混合有效/无效的情况
    ├── utils/             # 实用程序测试文件
    ├── empty/             # 空目录，用于测试
    └── deep/              # 深层嵌套结构
        └── nested/
            └── directory/
                └── structure/
```

测试文件按类别组织：

- **valid/** - 文档正确的 Go 文件
  - `good.go` - 有效的生产代码，注释匹配
  - `good_test.go` - 有效的测试文件，注释匹配

- **invalid/** - 文档不匹配的 Go 文件
  - `bad.go` - 生产代码，注释不匹配
  - `bad_test.go` - 测试代码，注释不匹配

- **mixed/** - 混合有效和无效的示例
  - `mixed.go` - 包含有效和无效注释的文件，包括 TODO 等特殊情况

- **utils/** - 其他实用程序测试文件
  - `helper.go` - 用于测试目录统计的辅助函数

- **empty/** - 空目录，用于测试空目录处理

- **deep/nested/directory/structure/** - 深层嵌套路径，用于测试递归扫描
  - `deep.go` - 深层嵌套结构中的有效 Go 文件

### 测试脚本

#### Bash 测试套件 (test.sh)

go-doc-lint.sh 脚本的综合测试套件。

**要求：**

- Bash 4.0+
- go-doc-lint.sh 脚本必须可执行

**运行方式：**

```bash
cd /path/to/go-doc-lint
bash test.sh
```

**测试覆盖范围（33 个测试）：**

- 版本和帮助显示
- 目录扫描
- 单个文件扫描
- 无效路径处理
- 文件类型过滤（--test、--all 标志）
- 输出选项（文件和目录）
- 参数验证和互斥检查
- 时间戳验证
- 报告内容验证
- 目录统计
- 单个文件排除目录统计
- 有效文件检测
- 空目录处理
- 相对路径支持
- 嵌套目录自动创建
- 深层嵌套路径扫描

#### PowerShell 测试套件 (test.ps1)

go-doc-lint.ps1 脚本的综合测试套件。

**要求：**

- PowerShell 5.0+
- go-doc-lint.ps1 脚本必须存在

**运行方式：**

```powershell
cd path\to\go-doc-lint
.\test.ps1
```

或指定脚本路径：

```powershell
powershell -File test.ps1 -ScriptPath ".\go-doc-lint.ps1"
```

**测试覆盖范围（33 个测试）：**

- 版本和帮助显示
- 目录扫描
- 单个文件扫描
- 无效路径处理
- 文件类型过滤（--test、--all 标志）
- 输出选项（文件和目录）
- 参数验证和互斥检查
- 时间戳验证
- 报告内容验证
- 目录统计
- 单个文件排除目录统计
- 有效文件检测
- 输出中的分隔线
- 文件类型验证
- 空目录处理
- 相对路径支持
- 嵌套目录自动创建
- 深层嵌套路径扫描
- 错误处理

## 测试用例

两个测试套件验证以下场景：

### 基本操作

1. 显示版本信息
2. 显示帮助信息
3. 扫描目录
4. 扫描单个文件

### 输入验证

1. 处理无效/不存在的目录
2. 处理无效/不存在的文件
3. 验证文件扩展名（仅限 .go）
4. 拒绝互斥参数

### 文件过滤

1. 仅扫描测试文件（--test 标志）
2. 扫描所有文件（--all 标志）
3. 默认行为（非测试文件）

### 输出处理

1. 输出到屏幕（无 -o 标志）
2. 输出到指定文件
3. 输出到目录，使用自动生成的文件名
4. 创建缺失的输出目录

### 报告验证

1. 验证摘要部分的存在
2. 验证发现详情部分
3. 验证目录统计显示
4. 验证输出中的分隔线
5. 验证进度消息中的时间戳格式

### 参数验证

1. 无参数显示帮助信息
2. --version 参数隔离（拒绝其他参数）
3. --help 参数隔离（拒绝其他参数）
4. 输出文件存在性检查
5. 指定特定输出文件名
6. 嵌套输出目录自动创建

### 路径处理

1. 相对路径支持
2. 空目录检测和错误处理
3. 深层嵌套路径扫描
4. 混合有效/无效文件目录

### 特殊情况

1. 单个文件扫描排除目录统计
2. 有效文件显示零个发现
3. 无效文件显示正确的不匹配数量
4. TODO 和其他特殊注释被正确处理

## 测试输出

两个测试套件生成彩色输出：

- **绿色 (✓ PASS)** - 测试成功通过
- **红色 (✗ FAIL)** - 测试失败
- **摘要** - 通过和失败的测试总数

## 持续集成

这些测试套件可以集成到 CI/CD 流程中：

**GitHub Actions (Bash)：**

```yaml
- name: 运行 Bash 测试
  run: bash test.sh
```

**GitHub Actions (PowerShell)：**

```yaml
- name: 运行 PowerShell 测试
  run: powershell -File test.ps1
```

## 故障排除

### Bash 测试

- 确保脚本具有执行权限：`chmod +x test.sh go-doc-lint.sh`
- 在 Windows (WSL) 上，使用 bash：`wsl bash test.sh`

### PowerShell 测试

- 确保执行策略允许脚本执行：`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- 从 PowerShell 运行（不是 Windows PowerShell ISE，以获得最佳兼容性）

## 添加新测试

要添加新的测试用例：

1. **对于 Bash** - 在 test.sh 中添加以 `test_` 开头的新函数
2. **对于 PowerShell** - 在 test.ps1 中添加以 `Test-` 开头的新函数
3. 调用 `print_result`（Bash）或 `Print-Result`（PowerShell），传入测试名称和结果
4. 在主执行部分添加测试调用

### 测试编写指南

使用以下清单设计可靠的测试：

1. **定义场景**

- 每个测试只验证一个行为（单一职责）
- 明确预期退出码

1. **准备测试数据**

- 优先使用 `fixtures/` 下的文件
- 新用例使用唯一文件名
- 除非必要，不修改已有 fixtures

1. **执行工具**

- 使用明确路径
- 尽量分离捕获 stdout 和 stderr

1. **断言结果**

- 验证退出码
- 验证关键输出行
- 避免对时间戳做精确断言

1. **清理**

- 删除临时文件/目录
- 保持 fixtures 不变

### Bash 测试示例

```bash
# 示例：验证 --test 仅扫描 *_test.go
test_scan_test_files_only() {
  local output
  output=$(bash ./go-doc-lint.sh ./fixtures --test 2>&1)
  local status=$?

  # 退出码应为 0
  [[ $status -eq 0 ]] || return 1

  # 期望输出包含测试文件
  echo "$output" | grep -q "_test.go" || return 1

  return 0
}

# 注册测试
test_scan_test_files_only
print_result "仅扫描测试文件" $?
```

### PowerShell 测试示例

```powershell
function Test-ScanTestFilesOnly {
   $output = powershell -File .\go-doc-lint.ps1 .\fixtures --test 2>&1
   $status = $LASTEXITCODE

   if ($status -ne 0) { return $false }
   if ($output -notmatch "_test\.go") { return $false }

   return $true
}

# 注册测试
Print-Result "仅扫描测试文件" (Test-ScanTestFilesOnly)
```

### 常用断言

- **退出码**：`$?`（Bash）/ `$LASTEXITCODE`（PowerShell）
- **输出内容**：`grep -q`（Bash）/ `-match`（PowerShell）
- **文件存在**：`[[ -f path ]]`（Bash）/ `Test-Path`（PowerShell）

### 稳定测试的建议

- 避免精确匹配时间戳；只检查是否存在或格式正确。
- 使用确定性的 fixtures 防止输出波动。
- 优先使用 `--output` 验证报告文件。
- 测试名称保持清晰一致。

## 测试数据

测试样本有意设计得简单，以确保：

- 快速执行
- 易于调试
- 清晰演示功能
- 无外部依赖

如果需要用更大的代码库进行测试，可以将脚本指向您自己的 Go 项目。

---

**最后更新：** 2026-02-01

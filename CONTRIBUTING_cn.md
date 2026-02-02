# 为 go-doc-lint 做贡献

[English](CONTRIBUTING.md) | 中文版

感谢您对 go-doc-lint 项目的关注！本文档提供了贡献指南和说明。

## 开发环境设置

### 前置要求

**Bash 开发环境（Linux/Unix/macOS/WSL）：**

- Bash 4.0 或更高版本
- Perl（用于注释解析）
- 标准 Unix 工具：`awk`、`grep`、`sed`

**PowerShell 开发环境（Windows）：**

- PowerShell 5.0 或更高版本
- Windows 10 或更高版本

### 开始使用

1. **Fork 和克隆**

   ```bash
   git clone https://github.com/YOUR_USERNAME/go-doc-lint.git
   cd go-doc-lint
   ```

2. **赋予脚本执行权限（Bash）**

   ```bash
   chmod +x go-doc-lint.sh test.sh
   ```

3. **验证设置**

   ```bash
   # 测试 Bash 版本
   bash test.sh

   # 测试 PowerShell 版本
   .\test.ps1
   ```

## 开发最佳实践

在贡献前，不妨查看我们的[最佳实践指南](doc/BEST_PRACTICES_cn.md)，其中包含：

- 项目组织指南
- 前置提交钩子集成模式
- CI/CD 管道示例
- 性能优化提示
- 常见错误及其规避方式

有关项目变更和版本信息，请查看 [更新日志](CHANGELOG_cn.md)。

如需详细了解架构和设计决策，请查看 [架构指南](doc/ARCHITECTURE_cn.md)。

有关高级故障排查和调试，请查看 [故障排查指南](doc/TROUBLESHOOTING_cn.md)。

## 项目结构

```text
go-doc-lint/
├── go-doc-lint.sh       # 主 Bash 实现
├── go-doc-lint.ps1      # 主 PowerShell 实现
├── test.sh              # Bash 测试套件
├── test.ps1             # PowerShell 测试套件
├── fixtures/            # 测试数据目录
│   ├── valid/          # 有效的 Go 文件测试用例
│   ├── invalid/        # 无效的 Go 文件测试用例
│   ├── mixed/          # 混合有效/无效文件
│   ├── utils/          # 实用工具测试文件
│   ├── empty/          # 空目录测试用例
│   └── deep/           # 深层嵌套路径测试用例
├── doc/                # 文档目录
│   ├── Test.md         # 测试指南（英文）
│   └── Test_cn.md      # 测试指南（中文）
├── README.md           # 用户手册（英文）
└── README_cn.md        # 用户手册（中文）
```

## 开发工作流

### 1. 创建功能分支

```bash
git checkout -b feature/your-feature-name
```

### 2. 进行修改

- **保持一致性**：Bash 和 PowerShell 实现应具有相同的功能
- **遵循现有风格**：匹配现有代码的编码风格
- **添加测试**：每个新功能都应包含相应的测试用例

### 3. 运行测试

提交前，确保所有测试通过：

```bash
# 运行 Bash 测试
bash test.sh

# 运行 PowerShell 测试
.\test.ps1
```

预期输出：所有测试都应通过（具体数量见输出）。

### 4. 更新文档

如果您的更改影响用户可见的行为：

- 更新 `README.md`（英文）
- 更新 `README_cn.md`（中文）
- 如果添加新测试用例，更新测试文档

### 5. 提交更改

使用清晰、描述性的提交消息：

```bash
git add .
git commit -m "feat: 添加自定义输出格式支持"
```

**提交消息格式：**

- `feat:` - 新功能
- `fix:` - Bug 修复
- `docs:` - 文档更改
- `test:` - 测试添加或修改
- `refactor:` - 代码重构
- `style:` - 代码样式更改（格式化等）
- `chore:` - 维护任务

## 编码规范

### Bash 脚本

- 使用 `#!/usr/bin/env bash` 作为 shebang
- 启用严格模式：`set -euo pipefail`
- 使用有意义的小写变量名，单词间用下划线分隔
- 为复杂逻辑添加注释
- 引用变量以防止单词拆分
- 使用 `[[` 进行条件判断而不是 `[`

**示例：**

```bash
#!/usr/bin/env bash
set -euo pipefail

# 处理输入文件
process_file() {
    local file_path="$1"

    if [[ -f "$file_path" ]]; then
        echo "正在处理: $file_path"
    fi
}
```

### PowerShell 脚本

- 函数使用动词-名词命名（如 `Get-FileContent`）
- 函数名使用 PascalCase
- 变量名使用 camelCase
- 使用 try-catch 进行适当的错误处理
- 函数参数使用 `param()` 块
- 为函数添加基于注释的帮助

**示例：**

```powershell
function Get-FileContent {
    param(
        [string]$FilePath
    )

    if (Test-Path $FilePath) {
        Write-Output "正在处理: $FilePath"
    }
}
```

## 测试指南

### 添加新测试用例

1. **Bash 测试（test.sh）：**
   - 添加以 `test_` 开头的新函数
   - 使用辅助函数：`test_output_matches`、`test_file_contains` 等
   - 在 `main()` 中调用测试函数

2. **PowerShell 测试（test.ps1）：**
   - 添加以 `Test-` 开头的新函数
   - 使用辅助函数：`Test-OutputMatches`、`Test-FileContains` 等
   - 在 `Main` 中调用测试函数

### 测试类别

确保测试覆盖以下领域：

- 基本操作（版本、帮助、扫描）
- 输入验证（无效路径、文件类型）
- 文件过滤（--test、--all 标志）
- 输出处理（屏幕、文件、目录）
- 报告验证（格式、内容）
- 参数验证（互斥检查）
- 路径处理（相对路径、嵌套路径、空目录）
- 特殊情况（单个文件、有效文件、边界情况）

### 测试数据

将测试数据添加到适当的 `fixtures/` 子目录：

- `valid/` - 文档正确的 Go 文件
- `invalid/` - 文档不匹配的文件
- `mixed/` - 同时包含有效和无效示例的文件
- `utils/` - 特定测试场景的辅助文件

## Pull Request 流程

1. **确保质量：**
   - 所有测试通过（28/28）
   - 代码遵循风格指南
   - 文档已更新
   - 没有合并冲突

2. **提交 PR：**
   - 提供清晰的更改描述
   - 引用相关的 issue
   - 如适用，包含截图/示例

3. **审查流程：**
   - 维护者将审查您的代码
   - 处理反馈或请求的更改
   - 批准后，您的 PR 将被合并

## 报告问题

报告 bug 或请求功能时：

1. **检查现有 Issue：** 搜索以避免重复
2. **提供详细信息：**
   - 版本信息（`--version`）
   - 操作系统
   - 重现步骤（对于 bug）
   - 预期行为 vs. 实际行为
   - 示例代码/文件（如适用）

3. **使用模板：** 如果提供了 issue 模板，请遵循

## 获取帮助

- **文档：** 查看 `README.md` 和 `doc/Test.md`
- **Issue：** 为问题或疑问创建 issue
- **讨论：** 使用 GitHub Discussions 进行一般性问题讨论

## 行为准则

- 尊重和包容他人
- 专注于建设性反馈
- 帮助他人学习和成长
- 维护积极的社区环境

## 许可证

通过贡献，您同意您的贡献将根据 MIT 许可证授权。

---

感谢您为 go-doc-lint 做出贡献！🎉

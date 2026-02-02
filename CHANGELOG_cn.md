# 更新日志

[English](CHANGELOG.md) | 中文版

本项目的所有值得注意的变更都将在此文件中进行记录。

此项目遵循[语义化版本](https://semver.org/spec/v2.0.0.html)规范，
日志格式基于 [Keep a Changelog](https://keepachangelog.com/) 标准。

## [1.0.1] - 2026-02-02

### 变更

- 将版本管理集中到 VERSION 文件
- 脚本现在从 VERSION 文件读取版本号，而不是硬编码
- 简化了版本维护流程
- 优化代码行长度以提升可读性

### 移除

- 从文档文件中删除了冗余的版本信息

### 修复

- 修复相对路径问题并消除 linter 告警

## [1.0.0] - 2026-02-01

### 新增功能

- **初始发布**：功能完整的 Go 文档检查工具
- **Bash 实现** (`go-doc-lint.sh`)：
  - 跨平台支持（Linux、Unix、macOS、WSL）
  - 递归目录扫描，自动排除 vendor 和 .git 目录
  - 参数解析和互斥验证
  - 多种输出选项（屏幕、文件、目录）
  - 文件类型过滤（--test、--all 标志）
  - 基于 Perl 的状态机注释解析
  - 性能指标（文件数、耗时统计）
  - 完善的错误处理（退出码 0, 1, 2, 3, 4）

- **PowerShell 实现** (`go-doc-lint.ps1`)：
  - 与 Bash 版本功能完全一致
  - Windows 原生 PowerShell 5.0+ 支持
  - 版本检查和验证
  - 相同的功能和输出格式

- **完整的测试套件**：
  - Bash 测试 (`test.sh`) 覆盖所有功能
  - PowerShell 测试 (`test.ps1`) 覆盖所有功能
  - 测试覆盖：基本操作、输入验证、文件过滤、输出处理、
    报告验证、参数验证、路径处理、边界情况
  - 彩色输出反馈（绿色/红色/黄色）
  - 100% 通过率验证

- **完整的文档**：
  - **英文版** (`README.md`)：用户手册含示例和故障排除
  - **中文版** (`README_cn.md`)：完整的中文翻译
  - **贡献指南** (`CONTRIBUTING.md`)：开发者指南
  - **贡献指南中文版** (`CONTRIBUTING_cn.md`)：中文版本
  - **测试文档** (`doc/Test.md` & `doc/Test_cn.md`)：测试指南
  - **最佳实践指南** (`doc/BEST_PRACTICES.md` & `doc/BEST_PRACTICES_cn.md`)：集成模式
  - 所有文档中的语言切换链接
  - 快速入门部分用于快速启动
  - 系统要求和版本映射

- **双语支持**：
  - 所有主要文档提供英文和中文版本
  - 双向语言链接便于导航
  - 完整翻译保持相同的结构和内容
  - Windows (PowerShell) 和 Unix (Bash) 的本地化示例

- **项目基础设施**：
  - 全面的 `.gitignore` 包含测试输出和临时文件排除
  - 空测试目录中的 `.gitkeep` 文件用于 Git 跟踪
  - 正确的项目结构（`/doc` 和 `/fixtures` 组织）
  - MIT 许可证

- **测试固件**：
  - `fixtures/valid/` - 文档正确的 Go 文件
  - `fixtures/invalid/` - 文档不匹配的文件
  - `fixtures/mixed/` - 混合有效/无效示例
  - `fixtures/utils/` - 实用工具测试文件
  - `fixtures/empty/` - 空目录用于测试
  - `fixtures/deep/nested/directory/structure/` - 深层嵌套路径

- **代码质量功能**：
  - 依赖验证（Bash 用 perl、awk；Windows 用 PowerShell 5.0）
  - 跨平台路径规范化
  - 空白和换行符处理（Unix/Windows 兼容性）
  - 特殊注释异常处理（TODO:、FIXME:、NOTE: 等）
  - 区分大小写的函数/注释匹配
  - 使用状态机的注释块检测

- **性能特性**：
  - 每秒扫描 ~50-100 个 Go 文件
  - 与文件数量呈线性扩展
  - 最小内存占用（典型 < 50MB）
  - I/O 密集型（非 CPU 限制）
  - 自动排除 vendor 和 .git 目录

### 安全性

- 无外部依赖
- 无需网络访问
- 可安全用于 CI/CD 管道

---

## 未来规划（潜在功能）

### 计划用于未来版本的功能

- [ ] JSON 输出格式用于机器解析
- [ ] 配置文件支持 (.go-doc-lint.yaml)
- [ ] 自定义注释模式匹配
- [ ] 与流行 linter 的集成 (golangci-lint)
- [ ] 性能分析和基准测试
- [ ] Docker 镜像用于容器化执行
- [ ] IDE 插件 (VSCode、GoLand 等)
- [ ] GitHub Actions 应用市场集成
- [ ] 大型项目的并行文件处理

---

## 注释

### 版本 1.0.0 亮点

- **生产就绪**：通过 28 个完整的测试用例全面测试
- **无外部依赖**：仅使用原生语言功能
- **跨平台**：在 Windows、Linux、macOS 和 WSL 上无缝体验
- **文档完整**：提供完整的双语文档和示例
- **易于集成**：支持前置提交钩子、CI/CD 管道、IDE 集成
- **社区友好**：包含贡献指南和开发设置

### 已知限制

- 需要 Bash 4.0+（Linux/Unix/macOS）
- 需要 PowerShell 5.0+（Windows）
- Bash 版本的注释解析需要 Perl
- 不支持自定义文档注释格式（仅 Go 标准格式）

### 兼容性

- ✅ Windows 10/11 配合 PowerShell 5.0+
- ✅ Linux（任何现代发行版含 Bash 4.0+）
- ✅ macOS 10.14+（Mojave 及更新版本）
- ✅ Windows with WSL（Windows 子系统 for Linux）
- ✅ GitHub Actions runners（Linux 和 Windows）
- ✅ CI/CD 平台（GitLab CI、Jenkins、Travis CI 等）

---

**最后更新**：2026-02-02
**维护者**：Daniel Liu
**许可证**：MIT

[1.0.1]: https://github.com/gzliudan/go-doc-lint/releases/tag/v1.0.1
[1.0.0]: https://github.com/gzliudan/go-doc-lint/releases/tag/v1.0.0

<div align="center">

# Skill 质量门禁

**Language / 语言**: [English](README.md) | 中文

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude-Code-purple)](https://claude.ai)

**Claude Code Skills 安装前质量评估与安全审计系统**

</div>

---

## 为什么需要 Skill 质量门禁？

安装第三方 Claude Code Skills 时，你可能面临以下风险：

- **安全风险**：恶意代码、数据外泄、权限提升
- **质量问题**：文档不完整、错误处理缺失、死代码
- **兼容性问题**：缺少依赖、边界情况未测试

**Skill 质量门禁** 提供全面的评估框架，在安装前从 6 个维度评估 Skills，帮助你做出明智决策。

## 功能特性

### 6 维度质量评估

| 维度 | 权重 | 检查内容 |
|------|------|----------|
| **代码质量** | 25% | 结构、复杂度、注释、最佳实践 |
| **文档质量** | 20% | SKILL.md 完整性、示例、触发条件 |
| **安全性** | 30% | 危险模式、数据外发、权限提升 |
| **功能完整性** | 15% | 依赖、错误处理、输出格式 |
| **可维护性** | 5% | 版本追踪、更新频率 |
| **社区认可** | 5% | 作者信誉、安装数量 |

### 质量等级

| 分数 | 等级 | 建议 |
|------|------|------|
| 90-100 | ⭐⭐⭐⭐⭐ | 强烈推荐 |
| 75-89 | ⭐⭐⭐⭐ | 推荐 |
| 60-74 | ⭐⭐⭐ | 可用 |
| 40-59 | ⭐⭐ | 需改进 |
| 0-39 | ⭐ | 不推荐 |

### 三层防护机制

1. **CLAUDE.md 规则** — 强制每次安装前评估
2. **Skill 集成** — 与 skill-manager、skills-discovery 无缝协作
3. **Hook 兜底** — 安装后审计作为安全网

## 快速开始

### 安装

```bash
# 克隆或下载到你的 Claude skills 目录
git clone https://github.com/your-username/skill-quality-gate.git ~/.claude/skills/skill-quality-gate
```

### 基本用法

```bash
# 评估一个 skill 目录
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill

# 指定报告输出路径
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill report.md
```

### 示例输出

```
========================================
   SKILL QUALITY ASSESSMENT SYSTEM
========================================

Target: /tmp/skill-audit/example-skill

[INFO] Assessing code quality...
[OK] SKILL.md is well-structured (45 lines)
[OK] Scripts are well-structured (3 found)
[OK] Reasonable code size (234 lines)
[OK] Good comment coverage (15%)
Code Quality Score: 25/25

[INFO] Assessing documentation quality...
[OK] Has description/overview section
[OK] Has trigger conditions documented
[OK] Has usage examples
Documentation Score: 16/20

[INFO] Assessing security...
[OK] Security audit passed - no critical issues
Security Score: 30/30

...

======================================
SKILL QUALITY ASSESSMENT SUMMARY
======================================
Skill: example-skill
Score: 82/100
Grade: Good (Recommended)
======================================
```

## 兼容性

支持所有主流 Skill 安装方式：

| 方式 | 支持 | 触发条件 |
|------|------|----------|
| **skill-manager** | ✅ | "安装第 N 个 skill" |
| **skills-discovery** | ✅ | "npx skills-installer install @owner/repo" |
| **手动安装 (GitHub)** | ✅ | 提供 GitHub URL |

## 集成配置

### 添加到 CLAUDE.md

要在每次安装时强制执行评估，将以下内容添加到 `~/.claude/CLAUDE.md`：

```markdown
# Skill 安装规则

**IMPORTANT - 安装前必须执行评估**:

**触发条件**: 任何 Skill 安装请求

**流程**:
1. 下载 skill 到临时目录
2. 运行安全审计 + 质量评估
3. 显示综合报告
4. 获得用户确认后才安装

**决策逻辑**:
- 安全 CRITICAL + 质量 < 40 → ⛔ 禁止安装
- 安全 HIGH + 质量 < 60 → ⚠️ 警告，需确认
- 安全 OK + 质量 >= 75 → ✅ 推荐安装
```

### 可信 Skills 白名单

创建 `~/.claude/config/trusted-skills.txt` 跳过可信 skill 的评估：

```
anthropic/official-skill
mycompany/internal-tools
```

## 项目结构

```
skill-quality-gate/
├── SKILL.md                    # Claude Code 入口文档
├── README.md                   # 英文文档
├── README.zh-CN.md             # 中文文档
├── LICENSE                     # MIT 协议
├── scripts/
│   └── assess-skill-quality.sh # 主评估脚本
├── data/
│   ├── scoring-rules.json      # 可配置的评分规则
│   └── security-patterns.json  # 安全检测模式
├── docs/
│   ├── en/
│   │   ├── scoring-dimensions.md
│   │   └── integration-guide.md
│   └── zh-CN/
│       ├── scoring-dimensions.md
│       └── integration-guide.md
└── examples/
    └── sample-report.md
```

## 退出码

| 退出码 | 含义 | 建议操作 |
|--------|------|----------|
| 0 | 分数 >= 60 | 可以安装 |
| 1 | 分数 40-59 | 需要用户决定 |
| 2 | 分数 < 40 或有严重问题 | 不要安装 |

## 依赖

- Bash 4.0+
- Node.js（可选，用于数据库查询）
- `audit-skill-security.sh`（推荐）

## 相关项目

- [skill-manager](https://github.com/...) - 浏览和安装 31,767+ skills
- [skills-discovery](https://github.com/...) - 搜索 claude-plugins.dev 注册表
- [skill-security-auditor](https://github.com/...) - 详细安全分析

## 贡献

欢迎贡献！请：

1. Fork 本仓库
2. 创建功能分支
3. 提交 Pull Request

## 协议

MIT 协议 - 详见 [LICENSE](LICENSE)

---

<div align="center">

**安装任何第三方 skill 前，请务必审查源代码。**

</div>

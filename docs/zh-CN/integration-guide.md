# 集成指南

本指南说明如何将 Skill 质量门禁集成到你的 Claude Code 工作流中。

## 目录

1. [基础集成](#基础集成)
2. [CLAUDE.md 集成](#claudemd-集成)
3. [skill-manager 集成](#skill-manager-集成)
4. [skills-discovery 集成](#skills-discovery-集成)
5. [安装后 Hook](#安装后-hook)
6. [白名单配置](#白名单配置)
7. [自定义评分规则](#自定义评分规则)

---

## 基础集成

### 独立使用

```bash
# 评估一个 skill 目录
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill

# 保存报告到指定位置
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill ~/reports/my-skill-report.md
```

### 编程使用

```bash
#!/bin/bash
SKILL_DIR="/tmp/downloaded-skill"
REPORT="/tmp/quality-report.md"

# 运行评估
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh "$SKILL_DIR" "$REPORT"
exit_code=$?

# 处理结果
case $exit_code in
    0) echo "可以安装" ;;
    1) echo "需要审查" ;;
    2) echo "不要安装" ;;
esac
```

---

## CLAUDE.md 集成

将以下规则添加到 `~/.claude/CLAUDE.md`，强制在每次安装 skill 前进行质量评估。

### 推荐配置

```markdown
---

# Skill 安装安全与质量规则

**IMPORTANT - 安装前强制评估**:

**触发条件**:
- 任何安装 skill 的请求
- `npx skills-installer install` 命令
- "安装第 N 个 skill" 或 "装第 N 个"
- 提供 GitHub URL 安装 skill

**必须流程**:
1. **禁止直接安装** - 不能跳过评估
2. **下载到临时目录** - `/tmp/skill-audit-$(date +%s)/`
3. **双重评估**:
   ```bash
   # 安全审计（如果可用）
   bash ~/.claude/scripts/audit-skill-security.sh "$SKILL_DIR"

   # 质量评估
   bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh "$SKILL_DIR"
   ```
4. **显示综合报告** - 展示安全和质量结果
5. **获得明确确认** - 用户必须说"是"或"安装"才能继续

**决策逻辑**:

| 安全 | 质量 | 操作 |
|------|------|------|
| exit 2 (CRITICAL) | 任何 | 禁止安装 |
| 任何 | < 40 | 禁止安装 |
| exit 1 (HIGH) | < 60 | 警告 - 需确认 |
| exit 0 | >= 75 | 推荐安装 |
| 其他 | 其他 | 显示报告，用户决定 |

**报告必须包含**:
- 安全审计结果（CRITICAL/HIGH/MEDIUM/LOW 数量）
- 质量分数（X/100）和等级
- 主要建议
- 明确的安装/不安装判断

**禁止行为**:
- 不经评估直接运行 `npx skills-installer install`
- 说"应该是安全的"而不运行检查
- 只做安全检查不做质量评估
- 假设官方/高星 skill 不需要检查
```

---

## skill-manager 集成

使用 skill-manager 浏览和安装 skill 时：

### 工作流程

1. 用户搜索 skills："找数据分析相关的 skills"
2. skill-manager 显示结果
3. 用户说："安装第 3 个"
4. **质量门禁激活**：
   - 下载 skill 到临时目录
   - 运行评估
   - 显示报告
   - 等待确认

### 示例对话

```
用户：安装列表里的第三个

Claude：我会在安装前评估这个 skill。

[下载到 /tmp/skill-audit-1737xxx/]
[运行安全审计...]
[运行质量评估...]

========================================
SKILL 质量评估摘要
========================================
Skill: data-analyzer
分数: 78/100
等级: 良好（推荐）

安全: 通过（0 critical, 0 high）
质量: 78/100（4/5 星）

建议:
- 添加更多使用示例
- 考虑添加错误处理

是否继续安装？(是/否)

用户：是

Claude：[运行 npx skills-installer install ...]
```

---

## skills-discovery 集成

对于来自 claude-plugins.dev 注册表的 skills：

### 拦截安装

当用户请求：
```
npx skills-installer install @owner/repo/skill-name
```

工作流程应该是：
1. 从命令中提取 skill 信息
2. 克隆/下载到临时目录
3. 运行质量评估
4. 显示报告
5. 只有用户确认后才继续

### 示例脚本

```bash
#!/bin/bash
# safe-skill-install.sh - skills-installer 的安全包装

SKILL_SPEC="$1"
TEMP_DIR="/tmp/skill-audit-$(date +%s)"

echo "下载 skill 用于评估..."
git clone "https://github.com/$SKILL_SPEC" "$TEMP_DIR" 2>/dev/null

if [ ! -d "$TEMP_DIR" ]; then
    echo "下载失败"
    exit 1
fi

echo "运行质量评估..."
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh "$TEMP_DIR"
exit_code=$?

if [ $exit_code -eq 2 ]; then
    echo "评估失败 - 安装被阻止"
    rm -rf "$TEMP_DIR"
    exit 2
fi

read -p "是否继续安装？(是/否): " confirm
if [ "$confirm" = "是" ]; then
    npx skills-installer install "$SKILL_SPEC"
else
    echo "安装已取消"
fi

rm -rf "$TEMP_DIR"
```

---

## 安装后 Hook

创建一个在任何 skill 安装后运行的 hook 作为安全网。

### Hook 脚本

创建 `~/.claude/hooks/post-skill-install.sh`:

```bash
#!/bin/bash
# 安装后安全审计和质量评估

SKILL_DIR="$1"
SKILL_NAME=$(basename "$SKILL_DIR")
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_DIR="$HOME/.claude/logs/skill-audits"
mkdir -p "$LOG_DIR"

echo ""
echo "============================================"
echo "  安装后审计"
echo "============================================"
echo "Skill: $SKILL_NAME"
echo "时间: $TIMESTAMP"
echo ""

# 1. 安全审计
if [ -f "$HOME/.claude/scripts/audit-skill-security.sh" ]; then
    echo "运行安全审计..."
    bash "$HOME/.claude/scripts/audit-skill-security.sh" "$SKILL_DIR" \
        "$LOG_DIR/${SKILL_NAME}_security_${TIMESTAMP}.md"
    SECURITY_EXIT=$?
else
    echo "安全审计脚本未找到"
    SECURITY_EXIT=0
fi

# 2. 质量评估
echo ""
echo "运行质量评估..."
bash "$HOME/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh" "$SKILL_DIR" \
    "$LOG_DIR/${SKILL_NAME}_quality_${TIMESTAMP}.md"
QUALITY_EXIT=$?

# 3. 摘要
echo ""
echo "============================================"
echo "  审计完成"
echo "============================================"
echo "安全: $([ $SECURITY_EXIT -eq 0 ] && echo '通过' || echo '发现问题')"
echo "质量: $([ $QUALITY_EXIT -eq 0 ] && echo '通过' || echo '发现问题')"
echo ""
echo "报告保存到: $LOG_DIR/"

# 4. 警告
if [ $SECURITY_EXIT -eq 2 ] || [ $QUALITY_EXIT -eq 2 ]; then
    echo ""
    echo "发现严重问题！"
    echo "建议卸载: npx skills-installer uninstall $SKILL_NAME"
fi
```

### 设置可执行权限

```bash
chmod +x ~/.claude/hooks/post-skill-install.sh
```

---

## 白名单配置

创建白名单跳过可信 skill 的评估。

### 创建白名单文件

创建 `~/.claude/config/trusted-skills.txt`:

```
# 官方 Anthropic skills
anthropic/official-tools
anthropic/code-reviewer

# 你组织的内部 skills
mycompany/internal-utils
mycompany/deployment-helper

# 知名社区 skills
popular-author/well-known-skill
```

### 修改评估脚本

在评估脚本开头添加白名单检查：

```bash
# 检查白名单
WHITELIST="$HOME/.claude/config/trusted-skills.txt"
SKILL_NAME=$(basename "$SKILL_DIR")

if [ -f "$WHITELIST" ]; then
    if grep -q "$SKILL_NAME" "$WHITELIST"; then
        echo "Skill '$SKILL_NAME' 在白名单中 - 跳过评估"
        exit 0
    fi
fi
```

---

## 自定义评分规则

### 修改评分规则

编辑 `~/.claude/skills/skill-quality-gate/data/scoring-rules.json`:

```json
{
  "dimensions": {
    "security": {
      "weight": 40,  // 增加安全权重
      "scoring": {
        "base_score": 40,
        "deductions": {
          "critical_per_issue": 15  // 更严格的惩罚
        }
      }
    }
  },
  "grades": {
    "excellent": { "min_score": 95, "stars": 5 },  // 更严格的阈值
    "good": { "min_score": 80, "stars": 4 }
  }
}
```

### 添加自定义检查

在 `data/custom-checks.json` 中创建额外检查：

```json
{
  "custom_checks": {
    "no_external_apis": {
      "pattern": "api\\..*\\.com",
      "severity": "medium",
      "description": "使用外部 API"
    },
    "requires_auth": {
      "pattern": "API_KEY|AUTH_TOKEN",
      "severity": "low",
      "description": "需要认证"
    }
  }
}
```

---

## 故障排除

### 评估未运行

1. 检查脚本权限：
   ```bash
   chmod +x ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh
   ```

2. 验证 Bash 版本：
   ```bash
   bash --version  # 应该是 4.0+
   ```

### 安全审计缺失

如果找不到 `audit-skill-security.sh`，质量评估会使用基本检查。完整安全评估需要：

```bash
# 验证安全审计脚本存在
ls -la ~/.claude/scripts/audit-skill-security.sh
```

### 数据库未找到

如果缺少 skill-manager 数据库，可维护性和社区评分会被估算：

```bash
# 检查数据库位置
ls -la ~/.claude/skills/skill-manager/data/all_skills_with_cn.json
```

---

## 最佳实践

1. **始终启用 CLAUDE.md 规则** - 确保一致的执行
2. **手动审查高严重性问题** - 自动检查有局限性
3. **保持白名单最小化** - 只放真正可信的来源
4. **定期更新评分规则** - 随着威胁演变
5. **保存审计日志** - 用于未来参考和追责

#!/bin/bash

# Skill Security Auditor v2.0 (Context-Aware)
# 全面审计 Claude Code Skills 的安全性，支持上下文感知
# 用法: bash audit-skill-security-v2.sh <skill-directory>

set -euo pipefail

SKILL_DIR="${1:?需要提供 skill 目录路径}"
REPORT_FILE="${2:-skill-security-report.md}"

# 排除模式: 忽略依赖
EXCLUDE_PATTERN="node_modules\|\.git"

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 风险计数器
CRITICAL=0
HIGH=0
MEDIUM=0
LOW=0
INFO=0

# 安全框架检测
HAS_SAFETY_RULES=false
SAFETY_SCORE=0

# ============================================================
# 辅助函数
# ============================================================

# 判断文件类型
get_file_type() {
    local file=$1

    # 文档文件
    if [[ "$file" =~ \.(md|markdown|txt)$ ]]; then
        echo "doc"
    # References 目录（通常是文档）
    elif [[ "$file" =~ /references/ ]]; then
        echo "doc"
    # 可执行脚本
    elif [[ "$file" =~ \.(sh|bash|py|js|ts|rb)$ ]]; then
        echo "script"
    # 配置文件
    elif [[ "$file" =~ \.(json|yaml|yml|toml)$ ]]; then
        echo "config"
    else
        echo "unknown"
    fi
}

# 检查内容是否在代码块中（Markdown）
is_in_code_block() {
    local file=$1
    local lineno=$2

    # 只对 Markdown 文件检查
    if [[ ! "$file" =~ \.md$ ]]; then
        echo "false"
        return
    fi

    # 简化：检查该行是否包含代码块标记或在行首有缩进
    local line_content=$(sed -n "${lineno}p" "$file" 2>/dev/null || echo "")

    # 如果行包含 ``` 或以 4 个空格/tab 开头，可能是代码
    if echo "$line_content" | grep -q '```\|^    \|^\t'; then
        echo "true"
        return
    fi

    # 检查上一行是否有 ``` 开始标记
    local prev_lines=$(head -n $((lineno - 1)) "$file" 2>/dev/null || echo "")
    local last_code_marker=$(echo "$prev_lines" | grep -n '```' | tail -1 | cut -d: -f1 || echo "0")

    if [ "$last_code_marker" -gt 0 ]; then
        # 检查从last_code_marker到当前行之间是否有偶数个```
        local between_markers=$(sed -n "${last_code_marker},${lineno}p" "$file" 2>/dev/null | grep -c '```' || echo "0")
        if [ "$between_markers" -eq 1 ]; then
            echo "true"
            return
        fi
    fi

    echo "false"
}

# 检查内容是否在表格中（Markdown）
is_in_table() {
    local file=$1
    local lineno=$2

    if [[ ! "$file" =~ \.md$ ]]; then
        echo "false"
        return
    fi

    # 检查当前行是否包含表格分隔符 |
    if sed -n "${lineno}p" "$file" 2>/dev/null | grep -q '|'; then
        echo "true"
    else
        echo "false"
    fi
}

# 开始报告
echo "# Skill Security Audit Report v2.0" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "**Skill:** $(basename "$SKILL_DIR")" >> "$REPORT_FILE"
echo "**Audit Time:** $(date)" >> "$REPORT_FILE"
echo "**Auditor:** Claude Code Security Scanner v2.0 (Context-Aware)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "---" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# 函数：添加发现
add_finding() {
    local severity=$1
    local title=$2
    local description=$3
    local file=$4
    local line=$5
    local context=${6:-""}

    case $severity in
        CRITICAL) CRITICAL=$((CRITICAL + 1)); color=$RED ;;
        HIGH)     HIGH=$((HIGH + 1));     color=$YELLOW ;;
        MEDIUM)   MEDIUM=$((MEDIUM + 1));   color=$YELLOW ;;
        LOW)      LOW=$((LOW + 1));      color=$GREEN ;;
        INFO)     INFO=$((INFO + 1));     color=$BLUE ;;
    esac

    echo -e "${color}[${severity}]${NC} $title${context:+ ($context)}"

    echo "## 🚨 [$severity] $title" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "$description" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "**文件:** \`$file\`" >> "$REPORT_FILE"
    if [ -n "$line" ]; then
        echo "**行号:** $line" >> "$REPORT_FILE"
    fi
    if [ -n "$context" ]; then
        echo "**上下文:** $context" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

echo "🔍 开始审计: $SKILL_DIR"
echo ""

# ============================================================
# 0. 检测安全框架
# ============================================================
echo "🛡️  检测安全框架..."

# 检查是否有 safety_rules.md
if [ -f "$SKILL_DIR/references/safety_rules.md" ]; then
    echo -e "${GREEN}[✓]${NC} 发现安全规则文档: references/safety_rules.md"
    HAS_SAFETY_RULES=true
    ((SAFETY_SCORE+=30))
fi

# 检查 SKILL.md 中的安全承诺
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    if grep -qi "NEVER.*execute.*without.*confirmation\|NEVER.*run.*without.*user" "$SKILL_DIR/SKILL.md"; then
        echo -e "${GREEN}[✓]${NC} SKILL.md 中发现安全承诺"
        HAS_SAFETY_RULES=true
        ((SAFETY_SCORE+=30))
    fi

    # 检查是否有安全原则章节
    if grep -qi "Safety\|Security\|安全原则" "$SKILL_DIR/SKILL.md"; then
        echo -e "${GREEN}[✓]${NC} SKILL.md 中发现安全章节"
        ((SAFETY_SCORE+=20))
    fi

    # 检查是否有风险等级标记
    if grep -q "🟢\|🟡\|🔴" "$SKILL_DIR/SKILL.md"; then
        echo -e "${GREEN}[✓]${NC} 发现风险等级标记系统"
        ((SAFETY_SCORE+=20))
    fi
fi

if [ $SAFETY_SCORE -gt 0 ]; then
    echo -e "${GREEN}[✓]${NC} 安全框架得分: $SAFETY_SCORE/100"
    echo ""

    echo "## 🛡️ 安全框架检测" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "✅ 此 Skill 具有安全框架，得分: **$SAFETY_SCORE/100**" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "这意味着作者考虑了安全问题，并提供了相应的安全机制。" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
else
    echo -e "${YELLOW}[!]${NC} 未检测到安全框架"
    echo ""
fi

# ============================================================
# 1. 检查危险的文件操作（上下文感知）
# ============================================================
echo "📁 检查危险文件操作..."

# 检查 rm -rf
if grep -rn "rm -rf" "$SKILL_DIR" 2>/dev/null | grep -v "$EXCLUDE_PATTERN"; then
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        content=$(echo "$line" | cut -d: -f3-)

        file_type=$(get_file_type "$file")
        in_code_block=$(is_in_code_block "$file" "$lineno")
        in_table=$(is_in_table "$file" "$lineno")

        # 根据上下文调整严重性
        if [ "$file_type" == "doc" ]; then
            if [ "$in_code_block" == "true" ]; then
                # 文档中的代码块示例
                severity="INFO"
                title="文档示例中的危险命令"
                desc="在文档的代码块中提及 rm -rf，可能是教学示例"
            elif [ "$in_table" == "true" ]; then
                # 表格中的说明
                severity="LOW"
                title="文档表格中提及危险命令"
                desc="在文档表格中提及 rm -rf，可能是命令说明"
            else
                # 文档正文
                severity="LOW"
                title="文档中提及危险命令"
                desc="在文档正文中提及 rm -rf"
            fi
            context="文档文件"
        elif [ "$file_type" == "script" ]; then
            # 实际可执行脚本
            if echo "$content" | grep -E "(~|/home|/root|/etc|/var|\$HOME)" &>/dev/null; then
                severity="CRITICAL"
                title="脚本中执行危险删除操作"
                desc="检测到脚本中可能删除重要文件/目录的命令: \`$content\`"
            else
                severity="HIGH"
                title="脚本中使用 rm -rf 命令"
                desc="发现脚本中使用 rm -rf 命令: \`$content\`"
            fi
            context="可执行脚本"
        else
            severity="MEDIUM"
            title="未知文件中的 rm -rf"
            desc="发现 rm -rf 命令: \`$content\`"
            context="未知类型"
        fi

        add_finding "$severity" "$title" "$desc" "$file" "$lineno" "$context"
    done < <(grep -rn "rm -rf" "$SKILL_DIR" 2>/dev/null | grep -v "$EXCLUDE_PATTERN" || true)
fi

# ============================================================
# 2. 检查权限提升（上下文感知）
# ============================================================
echo "⬆️  检查权限提升..."

# 检查 sudo
if grep -rn "sudo" "$SKILL_DIR" 2>/dev/null | grep -v "$EXCLUDE_PATTERN"; then
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        content=$(echo "$line" | cut -d: -f3-)

        file_type=$(get_file_type "$file")
        in_code_block=$(is_in_code_block "$file" "$lineno")

        # 检查是否有"不要自动执行"的警告
        has_warning=false
        if echo "$content" | grep -qi "manual\|caution\|careful\|warn\|don't.*execute\|需要.*确认"; then
            has_warning=true
        fi

        # 根据上下文调整严重性
        if [ "$file_type" == "doc" ]; then
            if [ "$in_code_block" == "true" ]; then
                if [ "$has_warning" == "true" ]; then
                    severity="INFO"
                    title="文档示例中的 sudo（带警告）"
                else
                    severity="LOW"
                    title="文档示例中的 sudo"
                fi
            else
                severity="LOW"
                title="文档中提及 sudo"
            fi
            context="文档文件"
        elif [ "$file_type" == "script" ]; then
            severity="HIGH"
            title="脚本中使用 sudo"
            desc="尝试以 root 权限执行命令: \`$content\`"
            context="可执行脚本"
        else
            severity="MEDIUM"
            title="未知文件中的 sudo"
            context="未知类型"
        fi

        add_finding "$severity" "$title" "内容: \`$content\`" "$file" "$lineno" "$context"
    done < <(grep -rn "sudo" "$SKILL_DIR" 2>/dev/null | grep -v "$EXCLUDE_PATTERN" || true)
fi

# ============================================================
# 3. 检查命令注入风险（简化，只检查脚本）
# ============================================================
echo "💉 检查命令注入风险..."

# 只检查脚本文件中的动态执行
find "$SKILL_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | while read -r file; do
    if grep -n -E "exec|system|spawn|child_process" "$file" 2>/dev/null; then
        while IFS= read -r line; do
            lineno=$(echo "$line" | cut -d: -f1)
            content=$(echo "$line" | cut -d: -f2-)

            add_finding "HIGH" "脚本中的动态命令执行" \
                "发现动态命令执行，可能存在注入风险: \`$content\`" \
                "$file" "$lineno" "可执行脚本"
        done < <(grep -n -E "exec|system|spawn|child_process" "$file" 2>/dev/null || true)
    fi
done

# ============================================================
# 4. 检查敏感信息访问（区分读取和提及）
# ============================================================
echo "🔑 检查敏感信息访问..."

if grep -rn -E "(\.ssh|\.aws|\.env|credentials|id_rsa|\.pem|\.key)" "$SKILL_DIR" 2>/dev/null | grep -v "$EXCLUDE_PATTERN"; then
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        content=$(echo "$line" | cut -d: -f3-)

        file_type=$(get_file_type "$file")

        # 判断是读取还是只是提及
        if echo "$content" | grep -E "(cat|read|open|readFile|with open)" &>/dev/null; then
            if [ "$file_type" == "script" ]; then
                severity="CRITICAL"
                title="脚本中读取敏感文件"
            else
                severity="MEDIUM"
                title="文档中提及读取敏感文件"
            fi
        else
            severity="INFO"
            title="提及敏感路径"
        fi

        add_finding "$severity" "$title" "内容: \`$content\`" "$file" "$lineno" "$file_type"
    done < <(grep -rn -E "(\.ssh|\.aws|\.env|credentials|id_rsa|\.pem|\.key)" "$SKILL_DIR" 2>/dev/null | grep -v "$EXCLUDE_PATTERN" || true)
fi

# ============================================================
# 5. 检查网络外发行为（只检查脚本）
# ============================================================
echo "🌐 检查网络外发行为..."

find "$SKILL_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | while read -r file; do
    if grep -n -E "curl|wget" "$file" 2>/dev/null; then
        while IFS= read -r line; do
            lineno=$(echo "$line" | cut -d: -f1)
            content=$(echo "$line" | cut -d: -f2-)

            # 检查是否发送敏感数据
            if echo "$content" | grep -E "(@|--data|-d|-F|env|\.aws|\.ssh|credentials|token|key)" &>/dev/null; then
                add_finding "CRITICAL" "可疑的数据外发" \
                    "检测到可能上传敏感数据的网络请求: \`$content\`" \
                    "$file" "$lineno" "可执行脚本"
            else
                add_finding "MEDIUM" "网络请求" \
                    "发现网络请求: \`$content\`" \
                    "$file" "$lineno" "可执行脚本"
            fi
        done < <(grep -n -E "curl|wget" "$file" 2>/dev/null || true)
    fi
done

# ============================================================
# 生成摘要
# ============================================================
echo ""
echo "======================================"
echo "📊 审计摘要"
echo "======================================"
echo -e "${RED}🔴 CRITICAL: $CRITICAL${NC}"
echo -e "${YELLOW}🟡 HIGH:     $HIGH${NC}"
echo -e "${YELLOW}🟡 MEDIUM:   $MEDIUM${NC}"
echo -e "${GREEN}🟢 LOW:      $LOW${NC}"
echo -e "${BLUE}ℹ️  INFO:     $INFO${NC}"
echo "======================================"
echo ""

if [ $HAS_SAFETY_RULES == true ]; then
    echo -e "${GREEN}✅ 检测到安全框架 (得分: $SAFETY_SCORE/100)${NC}"
fi

# 计算调整后的风险分数
RISK_SCORE=$((CRITICAL * 10 + HIGH * 3 + MEDIUM * 1))
if [ $HAS_SAFETY_RULES == true ]; then
    # 有安全框架，降低风险分数
    RISK_SCORE=$((RISK_SCORE * (100 - SAFETY_SCORE) / 100))
    echo -e "${GREEN}调整后风险分数: $RISK_SCORE (原始: $((CRITICAL * 10 + HIGH * 3 + MEDIUM * 1)))${NC}"
fi

echo ""

# 添加摘要到报告
{
    echo "# 审计摘要"
    echo ""
    echo "| 严重性 | 数量 |"
    echo "|--------|------|"
    echo "| 🔴 CRITICAL | $CRITICAL |"
    echo "| 🟡 HIGH     | $HIGH |"
    echo "| 🟡 MEDIUM   | $MEDIUM |"
    echo "| 🟢 LOW      | $LOW |"
    echo "| ℹ️  INFO     | $INFO |"
    echo ""

    if [ $HAS_SAFETY_RULES == true ]; then
        echo "## 🛡️ 安全框架"
        echo ""
        echo "✅ 检测到安全框架，得分: **$SAFETY_SCORE/100**"
        echo ""
        echo "风险分数: **$RISK_SCORE** (原始: $((CRITICAL * 10 + HIGH * 3 + MEDIUM * 1))，已根据安全框架调整)"
        echo ""
    else
        echo "风险分数: **$RISK_SCORE**"
        echo ""
    fi

    echo "## 建议"
    echo ""

    # 根据调整后的风险分数判断
    if [ $CRITICAL -gt 0 ] && [ $HAS_SAFETY_RULES == false ]; then
        echo "⛔ **不要安装此 Skill！** 发现 $CRITICAL 个严重安全问题且无安全框架。"
    elif [ $CRITICAL -gt 0 ] && [ $HAS_SAFETY_RULES == true ]; then
        echo "⚠️  **谨慎评估！** 发现 $CRITICAL 个严重问题，但存在安全框架。"
        echo ""
        echo "建议："
        echo "1. 仔细阅读 SKILL.md 中的安全原则"
        echo "2. 检查是否所有危险操作都需要用户确认"
        echo "3. 理解风险后决定是否安装"
    elif [ $RISK_SCORE -gt 20 ]; then
        echo "⚠️  **建议人工审查！** 风险分数较高 ($RISK_SCORE)，建议审查代码后再决定。"
    elif [ $RISK_SCORE -gt 10 ]; then
        echo "✅ 风险可控，但建议阅读文档了解安全机制。"
    else
        echo "✅ 未发现明显安全问题，可以考虑安装。"
    fi
    echo ""
    echo "---"
    echo ""
    echo "## 📝 v2.0 改进说明"
    echo ""
    echo "此版本的审计工具支持："
    echo "- ✅ 上下文感知：区分文档示例和实际代码"
    echo "- ✅ 安全框架识别：检测 Skill 的安全承诺"
    echo "- ✅ 调整风险等级：根据上下文和安全框架调整评分"
    echo ""
    echo "*注意：此工具只能检测常见的恶意模式，不能保证 100% 安全。安装任何第三方 Skill 前，请仔细阅读源代码。*"
} >> "$REPORT_FILE"

echo "📄 完整报告已保存到: $REPORT_FILE"
echo ""

# 返回状态码（根据调整后的风险）
if [ $CRITICAL -gt 0 ] && [ $HAS_SAFETY_RULES == false ]; then
    exit 2  # 严重问题且无安全框架
elif [ $RISK_SCORE -gt 30 ]; then
    exit 1  # 高风险
else
    exit 0  # 可接受
fi

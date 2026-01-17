#!/bin/bash

# Skill Quality Assessment System
# Comprehensive quality scoring for Claude Code Skills before installation
# Usage: bash assess-skill-quality.sh <skill-directory> [report-output.md]
#
# Exit Codes:
#   0: Score >= 60 (Safe to install)
#   1: Score 40-59 (Needs improvement, user decision required)
#   2: Score < 40 or critical security issues (Not recommended)

set -euo pipefail

# Configuration
SKILL_DIR="${1:?Error: Please provide skill directory path}"
REPORT_FILE="${2:-skill-quality-report.md}"

# Get script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_GATE_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SKILL_GATE_DIR/data"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Score trackers (using simple variables for Bash 3.x compatibility)
SCORE_CODE_QUALITY=0
SCORE_DOCUMENTATION=0
SCORE_SECURITY=0
SCORE_FUNCTIONALITY=0
SCORE_MAINTAINABILITY=0
SCORE_COMMUNITY=0

MAX_CODE_QUALITY=25
MAX_DOCUMENTATION=20
MAX_SECURITY=30
MAX_FUNCTIONALITY=15
MAX_MAINTAINABILITY=5
MAX_COMMUNITY=5

# Issue arrays
CRITICAL_ISSUES=""
IMPROVEMENTS=""
OPTIONAL_OPTIMIZATIONS=""

# Helpers
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }

add_critical() {
    if [ -z "$CRITICAL_ISSUES" ]; then
        CRITICAL_ISSUES="$1"
    else
        CRITICAL_ISSUES="$CRITICAL_ISSUES|$1"
    fi
}
add_improvement() {
    if [ -z "$IMPROVEMENTS" ]; then
        IMPROVEMENTS="$1"
    else
        IMPROVEMENTS="$IMPROVEMENTS|$1"
    fi
}
add_optional() {
    if [ -z "$OPTIONAL_OPTIMIZATIONS" ]; then
        OPTIONAL_OPTIMIZATIONS="$1"
    else
        OPTIONAL_OPTIMIZATIONS="$OPTIONAL_OPTIMIZATIONS|$1"
    fi
}

# Check if file exists
file_exists() { [ -f "$1" ]; }

# Count lines excluding blanks and comments
count_code_lines() {
    local file="$1"
    grep -v '^[[:space:]]*$\|^[[:space:]]*#\|^[[:space:]]*//\|^[[:space:]]*\*' "$file" 2>/dev/null | wc -l | tr -d ' '
}

# Count total lines
count_lines() {
    wc -l < "$1" 2>/dev/null | tr -d ' '
}

# ============================================================
# 1. CODE QUALITY ASSESSMENT (25 points)
# ============================================================
assess_code_quality() {
    log_info "Assessing code quality..."
    local score=0

    # Check 1: SKILL.md is clear and well-structured (+5)
    if file_exists "$SKILL_DIR/SKILL.md"; then
        local skill_lines
        skill_lines=$(count_lines "$SKILL_DIR/SKILL.md")
        if [ "$skill_lines" -gt 20 ]; then
            score=$((score + 5))
            log_success "SKILL.md is well-structured ($skill_lines lines)"
        else
            score=$((score + 2))
            add_improvement "SKILL.md is too brief ($skill_lines lines). Consider adding more details."
        fi
    else
        add_critical "Missing SKILL.md - essential entry point for skills"
    fi

    # Check 2: Has auxiliary scripts with clear structure (+5)
    local script_count
    script_count=$(find "$SKILL_DIR" -name "*.sh" -o -name "*.py" -o -name "*.js" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$script_count" -gt 0 ]; then
        local well_structured=true
        for script in $(find "$SKILL_DIR" -name "*.sh" 2>/dev/null); do
            if ! grep -q "#!/bin/bash\|#!/usr/bin/env" "$script" 2>/dev/null; then
                well_structured=false
                add_improvement "Script missing shebang: $(basename "$script")"
            fi
        done
        if $well_structured; then
            score=$((score + 5))
            log_success "Scripts are well-structured ($script_count found)"
        else
            score=$((score + 3))
        fi
    else
        score=$((score + 3))  # No scripts needed is okay
        log_info "No auxiliary scripts (using markdown-only approach)"
    fi

    # Check 3: Reasonable script size (excluding data/) (+5)
    local total_code_lines=0
    while IFS= read -r file; do
        if [[ "$file" != *"/data/"* ]] && [[ "$file" != *"/node_modules/"* ]]; then
            local lines
            lines=$(count_code_lines "$file")
            total_code_lines=$((total_code_lines + lines))
        fi
    done < <(find "$SKILL_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" \) 2>/dev/null)

    if [ "$total_code_lines" -lt 500 ]; then
        score=$((score + 5))
        log_success "Reasonable code size ($total_code_lines lines)"
    elif [ "$total_code_lines" -lt 1000 ]; then
        score=$((score + 3))
        add_optional "Consider breaking down large files ($total_code_lines lines total)"
    else
        score=$((score + 1))
        add_improvement "Very large codebase ($total_code_lines lines) - may be hard to review"
    fi

    # Check 4: Has code comments (+5)
    local comment_ratio=0
    local total_lines=0
    local comment_lines=0
    while IFS= read -r file; do
        if [[ "$file" != *"/data/"* ]] && [[ "$file" != *"/node_modules/"* ]]; then
            local fl tl cl
            fl=$(count_lines "$file")
            total_lines=$((total_lines + fl))
            cl=$(grep -c '^[[:space:]]*#\|^[[:space:]]*//\|^[[:space:]]*\*' "$file" 2>/dev/null || echo 0)
            comment_lines=$((comment_lines + cl))
        fi
    done < <(find "$SKILL_DIR" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.md" \) 2>/dev/null)

    if [ "$total_lines" -gt 0 ]; then
        comment_ratio=$((comment_lines * 100 / total_lines))
        if [ "$comment_ratio" -gt 10 ]; then
            score=$((score + 5))
            log_success "Good comment coverage (${comment_ratio}%)"
        elif [ "$comment_ratio" -gt 5 ]; then
            score=$((score + 3))
            add_optional "Could improve comment coverage (${comment_ratio}%)"
        else
            score=$((score + 1))
            add_improvement "Low comment coverage (${comment_ratio}%) - add more documentation"
        fi
    else
        score=$((score + 3))  # Markdown-only skill
    fi

    SCORE_CODE_QUALITY=$score
    log_info "Code Quality Score: $score/$MAX_CODE_QUALITY"
}

# ============================================================
# 2. DOCUMENTATION QUALITY ASSESSMENT (20 points)
# ============================================================
assess_documentation() {
    log_info "Assessing documentation quality..."
    local score=0
    local skill_md="$SKILL_DIR/SKILL.md"

    if ! file_exists "$skill_md"; then
        log_error "SKILL.md not found - documentation assessment skipped"
        SCORE_DOCUMENTATION=0
        return
    fi

    # Check 1: Has description (+4)
    if grep -qi "description\|overview\|purpose" "$skill_md"; then
        score=$((score + 4))
        log_success "Has description/overview section"
    else
        add_improvement "Add a description/overview section to SKILL.md"
    fi

    # Check 2: Has trigger conditions (+4)
    if grep -qi "trigger\|when to use\|activation\|invoked" "$skill_md"; then
        score=$((score + 4))
        log_success "Has trigger conditions documented"
    else
        add_improvement "Add trigger conditions (when should this skill be used?)"
    fi

    # Check 3: Has usage examples (+4)
    if grep -qi "example\|usage\|demo\|sample" "$skill_md"; then
        score=$((score + 4))
        log_success "Has usage examples"
    else
        add_improvement "Add usage examples to help users understand the skill"
    fi

    # Check 4: Has parameter documentation (+4)
    if grep -qi "parameter\|argument\|option\|input\|config" "$skill_md"; then
        score=$((score + 4))
        log_success "Has parameter/configuration documentation"
    else
        add_optional "Consider documenting parameters/configuration options"
    fi

    # Check 5: Has README.md (+4)
    if file_exists "$SKILL_DIR/README.md"; then
        score=$((score + 4))
        log_success "Has README.md for GitHub display"
    else
        add_optional "Add README.md for better GitHub visibility"
    fi

    SCORE_DOCUMENTATION=$score
    log_info "Documentation Score: $score/${MAX_DOCUMENTATION}"
}

# ============================================================
# 3. SECURITY ASSESSMENT (30 points)
# ============================================================
assess_security() {
    log_info "Assessing security..."
    local score=30  # Start with full score, deduct for issues

    # Security audit script location
    local audit_script="$HOME/.claude/scripts/audit-skill-security.sh"
    local temp_report="/tmp/security-audit-$$.md"

    if file_exists "$audit_script"; then
        # Run security audit
        log_info "Running security audit..."
        local audit_exit=0
        bash "$audit_script" "$SKILL_DIR" "$temp_report" 2>/dev/null || audit_exit=$?

        case $audit_exit in
            0)
                log_success "Security audit passed - no critical issues"
                # Keep full 30 points
                ;;
            1)
                # HIGH issues found - deduct 5-10 points based on count
                local high_count
                high_count=$(grep -c "HIGH" "$temp_report" 2>/dev/null || echo 0)
                if [ "$high_count" -le 2 ]; then
                    score=$((score - 5))
                else
                    score=$((score - 10))
                fi
                add_improvement "Security audit found $high_count HIGH severity issues"
                log_warn "Security audit found HIGH severity issues"
                ;;
            2)
                # CRITICAL issues found - major deduction
                local critical_count
                critical_count=$(grep -c "CRITICAL" "$temp_report" 2>/dev/null || echo 0)
                score=$((score - 20 - critical_count * 2))
                [ $score -lt 0 ] && score=0
                add_critical "Security audit found $critical_count CRITICAL issues - DO NOT INSTALL"
                log_error "Security audit found CRITICAL issues!"
                ;;
        esac

        # Check for MEDIUM issues
        local medium_count
        medium_count=$(grep -c "MEDIUM" "$temp_report" 2>/dev/null || echo 0)
        if [ "$medium_count" -gt 0 ]; then
            score=$((score - medium_count))
            [ $score -lt 0 ] && score=0
            add_improvement "Found $medium_count MEDIUM severity security issues"
        fi

        rm -f "$temp_report"
    else
        log_warn "Security audit script not found, using basic checks"

        # Basic security checks
        # Check for dangerous patterns
        if grep -rq "rm -rf\s*[/~]" "$SKILL_DIR" 2>/dev/null; then
            score=$((score - 15))
            add_critical "Found dangerous rm -rf command targeting system directories"
        fi

        if grep -rq "sudo\|chmod 777" "$SKILL_DIR" 2>/dev/null; then
            score=$((score - 10))
            add_critical "Found privilege escalation commands (sudo/chmod 777)"
        fi

        if grep -rq "curl.*\$\|wget.*\$" "$SKILL_DIR" 2>/dev/null; then
            score=$((score - 5))
            add_improvement "Found network requests with variables - verify endpoints"
        fi
    fi

    [ $score -lt 0 ] && score=0
    SCORE_SECURITY=$score
    log_info "Security Score: $score/${MAX_SECURITY}"
}

# ============================================================
# 4. FUNCTIONALITY ASSESSMENT (15 points)
# ============================================================
assess_functionality() {
    log_info "Assessing functionality..."
    local score=0

    # Check 1: Has dependency documentation (+4)
    if grep -rqi "require\|dependency\|prerequisite\|need.*install" "$SKILL_DIR" 2>/dev/null; then
        score=$((score + 4))
        log_success "Has dependency documentation"
    else
        # Check if skill actually needs dependencies
        if grep -rq "npm\|pip\|brew\|apt" "$SKILL_DIR" 2>/dev/null; then
            add_improvement "Uses package managers but no dependency documentation"
        else
            score=$((score + 4))  # Simple skill, no deps needed
            log_success "No external dependencies required"
        fi
    fi

    # Check 2: Has error handling (+4)
    local has_error_handling=false
    if grep -rq "set -e\|trap\|try\|catch\|except\||| exit\|if \[" "$SKILL_DIR" 2>/dev/null; then
        has_error_handling=true
    fi

    if $has_error_handling; then
        score=$((score + 4))
        log_success "Has error handling logic"
    else
        add_improvement "Add error handling to scripts (set -e, trap, try/catch)"
    fi

    # Check 3: Has formatted output (+4)
    if grep -rq "echo\|print\|console.log\|format" "$SKILL_DIR" 2>/dev/null; then
        score=$((score + 4))
        log_success "Has formatted output"
    else
        score=$((score + 2))  # Markdown-only is acceptable
    fi

    # Check 4: No dead code (+3)
    # Check for unused functions (basic heuristic)
    local dead_code_score=3
    for script in $(find "$SKILL_DIR" -name "*.sh" 2>/dev/null); do
        # Find function definitions
        while IFS= read -r func; do
            func_name="${func%%(*}"
            func_name="${func_name# }"
            if [ -n "$func_name" ] && ! grep -q "$func_name" "$script" 2>/dev/null | grep -v "^$func_name()"; then
                add_optional "Possible unused function: $func_name in $(basename "$script")"
                dead_code_score=$((dead_code_score - 1))
            fi
        done < <(grep "^[a-zA-Z_][a-zA-Z0-9_]*\s*()" "$script" 2>/dev/null || true)
    done
    [ $dead_code_score -lt 0 ] && dead_code_score=0
    score=$((score + dead_code_score))

    SCORE_FUNCTIONALITY=$score
    log_info "Functionality Score: $score/${MAX_FUNCTIONALITY}"
}

# ============================================================
# 5. MAINTAINABILITY ASSESSMENT (5 points)
# ============================================================
assess_maintainability() {
    log_info "Assessing maintainability..."
    local score=0

    # Try to get info from skill-manager database first
    local skill_name
    skill_name=$(basename "$SKILL_DIR")
    local db_file="$HOME/.claude/skills/skill-manager/data/all_skills_with_cn.json"

    if file_exists "$db_file"; then
        # Extract info from local database
        local stars forks
        stars=$(node -e "
            const fs = require('fs');
            const db = JSON.parse(fs.readFileSync('$db_file'));
            const skill = db.find(s => s.name && s.name.toLowerCase().includes('$skill_name'.toLowerCase()));
            console.log(skill?.stars || 0);
        " 2>/dev/null || echo 0)

        if [ "$stars" -gt 100 ]; then
            score=$((score + 2))
            log_success "Popular skill ($stars stars)"
        elif [ "$stars" -gt 10 ]; then
            score=$((score + 1))
        fi
    fi

    # Check for version info
    if grep -rqi "version\|changelog\|v[0-9]" "$SKILL_DIR" 2>/dev/null; then
        score=$((score + 2))
        log_success "Has version tracking"
    else
        add_optional "Consider adding version information"
    fi

    # Check for recent updates (if .git exists)
    if [ -d "$SKILL_DIR/.git" ]; then
        local last_commit
        last_commit=$(git -C "$SKILL_DIR" log -1 --format="%ci" 2>/dev/null | cut -d' ' -f1)
        if [ -n "$last_commit" ]; then
            local days_ago
            days_ago=$(( ($(date +%s) - $(date -d "$last_commit" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$last_commit" +%s 2>/dev/null || echo 0)) / 86400 ))
            if [ "$days_ago" -lt 180 ]; then
                score=$((score + 1))
                log_success "Recently updated ($days_ago days ago)"
            fi
        fi
    else
        score=$((score + 1))  # Give benefit of doubt if not a git repo
    fi

    SCORE_MAINTAINABILITY=$score
    log_info "Maintainability Score: $score/${MAX_MAINTAINABILITY}"
}

# ============================================================
# 6. COMMUNITY ASSESSMENT (5 points)
# ============================================================
assess_community() {
    log_info "Assessing community recognition..."
    local score=0
    local skill_name
    skill_name=$(basename "$SKILL_DIR")

    # Check if from official/known source
    if [[ "$SKILL_DIR" == *"anthropic"* ]] || [[ "$SKILL_DIR" == *"official"* ]]; then
        score=$((score + 3))
        log_success "Official/trusted source"
    else
        # Try to determine from package.json or similar
        if file_exists "$SKILL_DIR/package.json"; then
            local author
            author=$(node -e "console.log(require('$SKILL_DIR/package.json').author || '')" 2>/dev/null || echo "")
            if [ -n "$author" ]; then
                score=$((score + 1))
                log_info "Author identified: $author"
            fi
        fi
    fi

    # Check installation count from database
    local db_file="$HOME/.claude/skills/skill-manager/data/all_skills_with_cn.json"
    if file_exists "$db_file"; then
        local installs
        installs=$(node -e "
            const fs = require('fs');
            const db = JSON.parse(fs.readFileSync('$db_file'));
            const skill = db.find(s => s.name && s.name.toLowerCase().includes('$skill_name'.toLowerCase()));
            console.log(skill?.installs || skill?.downloads || 0);
        " 2>/dev/null || echo 0)

        if [ "$installs" -gt 100 ]; then
            score=$((score + 2))
            log_success "Well-adopted ($installs installs)"
        elif [ "$installs" -gt 10 ]; then
            score=$((score + 1))
        fi
    else
        score=$((score + 2))  # Give benefit of doubt if no data
    fi

    SCORE_COMMUNITY=$score
    log_info "Community Score: $score/${MAX_COMMUNITY}"
}

# ============================================================
# GENERATE REPORT
# ============================================================
generate_report() {
    local total_score=$((SCORE_CODE_QUALITY + SCORE_DOCUMENTATION + SCORE_SECURITY + SCORE_FUNCTIONALITY + SCORE_MAINTAINABILITY + SCORE_COMMUNITY))
    local max_total=$((MAX_CODE_QUALITY + MAX_DOCUMENTATION + MAX_SECURITY + MAX_FUNCTIONALITY + MAX_MAINTAINABILITY + MAX_COMMUNITY))

    # Calculate grade
    local grade stars
    if [ "$total_score" -ge 90 ]; then
        grade="Excellent (Highly Recommended)"
        stars="5"
    elif [ "$total_score" -ge 75 ]; then
        grade="Good (Recommended)"
        stars="4"
    elif [ "$total_score" -ge 60 ]; then
        grade="Acceptable (Usable with improvements)"
        stars="3"
    elif [ "$total_score" -ge 40 ]; then
        grade="Poor (Needs optimization)"
        stars="2"
    else
        grade="Not Recommended"
        stars="1"
    fi

    local star_display=""
    for ((i=0; i<stars; i++)); do
        star_display+="*"
    done

    # Generate markdown report
    cat > "$REPORT_FILE" << EOF
# Skill Quality Assessment Report

**Skill:** $(basename "$SKILL_DIR")
**Assessment Time:** $(date)
**Assessor:** Skill Quality Gate v1.0

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Score** | $total_score/$max_total |
| **Rating** | $star_display ($stars/5) |
| **Grade** | $grade |

---

## Score Breakdown

| Dimension | Score | Max | Weight |
|-----------|-------|-----|--------|
| Code Quality | ${SCORE_CODE_QUALITY} | ${MAX_CODE_QUALITY} | 25% |
| Documentation | ${SCORE_DOCUMENTATION} | ${MAX_DOCUMENTATION} | 20% |
| Security | ${SCORE_SECURITY} | ${MAX_SECURITY} | 30% |
| Functionality | ${SCORE_FUNCTIONALITY} | ${MAX_FUNCTIONALITY} | 15% |
| Maintainability | ${SCORE_MAINTAINABILITY} | ${MAX_MAINTAINABILITY} | 5% |
| Community | ${SCORE_COMMUNITY} | ${MAX_COMMUNITY} | 5% |

---

## Recommendations

EOF

    # Add critical issues
    if [ -n "$CRITICAL_ISSUES" ]; then
        echo "### Critical Issues (Must Fix)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        IFS='|' read -ra ISSUES <<< "$CRITICAL_ISSUES"
        for issue in "${ISSUES[@]}"; do
            echo "- $issue" >> "$REPORT_FILE"
        done
        echo "" >> "$REPORT_FILE"
    fi

    # Add improvements
    if [ -n "$IMPROVEMENTS" ]; then
        echo "### Suggested Improvements" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        IFS='|' read -ra IMPR <<< "$IMPROVEMENTS"
        for item in "${IMPR[@]}"; do
            echo "- $item" >> "$REPORT_FILE"
        done
        echo "" >> "$REPORT_FILE"
    fi

    # Add optional optimizations
    if [ -n "$OPTIONAL_OPTIMIZATIONS" ]; then
        echo "### Optional Optimizations" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        IFS='|' read -ra OPTS <<< "$OPTIONAL_OPTIMIZATIONS"
        for item in "${OPTS[@]}"; do
            echo "- $item" >> "$REPORT_FILE"
        done
        echo "" >> "$REPORT_FILE"
    fi

    # Add verdict
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "## Verdict" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [ -n "$CRITICAL_ISSUES" ]; then
        echo "**DO NOT INSTALL** - Critical security or quality issues found." >> "$REPORT_FILE"
    elif [ "$total_score" -ge 75 ]; then
        echo "**RECOMMENDED** - This skill meets quality standards and is safe to install." >> "$REPORT_FILE"
    elif [ "$total_score" -ge 60 ]; then
        echo "**ACCEPTABLE** - This skill is functional but has room for improvement." >> "$REPORT_FILE"
    elif [ "$total_score" -ge 40 ]; then
        echo "**USE WITH CAUTION** - This skill has significant issues. Review carefully before installing." >> "$REPORT_FILE"
    else
        echo "**NOT RECOMMENDED** - This skill does not meet minimum quality standards." >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
    echo "---" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "*This report was generated automatically by Skill Quality Gate. Always review source code before installing third-party skills.*" >> "$REPORT_FILE"

    # Print summary to console
    echo ""
    echo "======================================"
    echo -e "${BOLD}SKILL QUALITY ASSESSMENT SUMMARY${NC}"
    echo "======================================"
    echo -e "Skill: ${CYAN}$(basename "$SKILL_DIR")${NC}"
    echo -e "Score: ${BOLD}$total_score/$max_total${NC}"
    echo -e "Grade: ${BOLD}$grade${NC}"
    echo ""

    if [ -n "$CRITICAL_ISSUES" ]; then
        echo -e "${RED}CRITICAL ISSUES:${NC}"
        IFS='|' read -ra ISSUES <<< "$CRITICAL_ISSUES"
        for issue in "${ISSUES[@]}"; do
            echo -e "  ${RED}*${NC} $issue"
        done
        echo ""
    fi

    echo "Report saved to: $REPORT_FILE"
    echo "======================================"

    # Return exit code
    if [ -n "$CRITICAL_ISSUES" ] || [ "$total_score" -lt 40 ]; then
        return 2
    elif [ "$total_score" -lt 60 ]; then
        return 1
    else
        return 0
    fi
}

# ============================================================
# MAIN
# ============================================================
main() {
    echo ""
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}   SKILL QUALITY ASSESSMENT SYSTEM${NC}"
    echo -e "${BOLD}========================================${NC}"
    echo ""
    echo -e "Target: ${CYAN}$SKILL_DIR${NC}"
    echo ""

    # Verify directory exists
    if [ ! -d "$SKILL_DIR" ]; then
        log_error "Directory not found: $SKILL_DIR"
        exit 2
    fi

    # Run all assessments
    assess_code_quality
    echo ""
    assess_documentation
    echo ""
    assess_security
    echo ""
    assess_functionality
    echo ""
    assess_maintainability
    echo ""
    assess_community
    echo ""

    # Generate and display report
    generate_report
}

main "$@"

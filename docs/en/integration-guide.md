# Integration Guide

This guide explains how to integrate Skill Quality Gate into your Claude Code workflow.

## Table of Contents

1. [Basic Integration](#basic-integration)
2. [CLAUDE.md Integration](#claudemd-integration)
3. [skill-manager Integration](#skill-manager-integration)
4. [skills-discovery Integration](#skills-discovery-integration)
5. [Post-Installation Hook](#post-installation-hook)
6. [Whitelist Configuration](#whitelist-configuration)
7. [Custom Scoring Rules](#custom-scoring-rules)

---

## Basic Integration

### Standalone Usage

```bash
# Assess a skill directory
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill

# Save report to custom location
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill ~/reports/my-skill-report.md
```

### Programmatic Usage

```bash
#!/bin/bash
SKILL_DIR="/tmp/downloaded-skill"
REPORT="/tmp/quality-report.md"

# Run assessment
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh "$SKILL_DIR" "$REPORT"
exit_code=$?

# Handle result
case $exit_code in
    0) echo "Safe to install" ;;
    1) echo "Review needed" ;;
    2) echo "Do not install" ;;
esac
```

---

## CLAUDE.md Integration

Add the following rules to `~/.claude/CLAUDE.md` to enforce quality assessment before every skill installation.

### Recommended Configuration

```markdown
---

# Skill Installation Security & Quality Rules

**IMPORTANT - Mandatory Pre-Installation Assessment**:

**Trigger Conditions**:
- Any request to install a skill
- `npx skills-installer install` commands
- "install skill #N" or "install the Nth one"
- Providing a GitHub URL for a skill

**Required Flow**:
1. **Never install directly** - Skip assessment is forbidden
2. **Download to temp directory** - `/tmp/skill-audit-$(date +%s)/`
3. **Run dual assessment**:
   ```bash
   # Security audit (if available)
   bash ~/.claude/scripts/audit-skill-security.sh "$SKILL_DIR"

   # Quality assessment
   bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh "$SKILL_DIR"
   ```
4. **Display combined report** - Show both security and quality results
5. **Require explicit confirmation** - User must say "yes" or "install" to proceed

**Decision Logic**:

| Security | Quality | Action |
|----------|---------|--------|
| exit 2 (CRITICAL) | Any | DO NOT INSTALL |
| Any | < 40 | DO NOT INSTALL |
| exit 1 (HIGH) | < 60 | Warning - confirm first |
| exit 0 | >= 75 | Recommended |
| Other | Other | Show report, user decides |

**Report Must Include**:
- Security audit results (CRITICAL/HIGH/MEDIUM/LOW counts)
- Quality score (X/100) and grade
- Top recommendations
- Clear install/don't-install verdict

**Forbidden Actions**:
- Running `npx skills-installer install` without assessment
- Saying "it should be safe" without running checks
- Only running security check without quality assessment
- Assuming official/popular skills don't need checking
```

---

## skill-manager Integration

When using skill-manager to browse and install skills:

### Workflow

1. User searches for skills: "find data analysis skills"
2. skill-manager shows results
3. User says: "install #3"
4. **Quality Gate activates**:
   - Download skill to temp directory
   - Run assessment
   - Show report
   - Wait for confirmation

### Example Conversation

```
User: Install the third skill from the list

Claude: I'll assess this skill before installation.

[Downloads to /tmp/skill-audit-1737xxx/]
[Runs security audit...]
[Runs quality assessment...]

========================================
SKILL QUALITY ASSESSMENT SUMMARY
========================================
Skill: data-analyzer
Score: 78/100
Grade: Good (Recommended)

Security: Passed (0 critical, 0 high)
Quality: 78/100 (4/5 stars)

Recommendations:
- Add more usage examples
- Consider adding error handling

Proceed with installation? (yes/no)

User: yes

Claude: [Runs npx skills-installer install ...]
```

---

## skills-discovery Integration

For skills from claude-plugins.dev registry:

### Intercepting Installation

When user requests:
```
npx skills-installer install @owner/repo/skill-name
```

The workflow should be:
1. Extract skill information from the command
2. Clone/download to temp directory
3. Run quality assessment
4. Show report
5. Proceed only with user confirmation

### Example Script

```bash
#!/bin/bash
# safe-skill-install.sh - Wrapper for skills-installer

SKILL_SPEC="$1"
TEMP_DIR="/tmp/skill-audit-$(date +%s)"

echo "Downloading skill for assessment..."
git clone "https://github.com/$SKILL_SPEC" "$TEMP_DIR" 2>/dev/null

if [ ! -d "$TEMP_DIR" ]; then
    echo "Failed to download skill"
    exit 1
fi

echo "Running quality assessment..."
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh "$TEMP_DIR"
exit_code=$?

if [ $exit_code -eq 2 ]; then
    echo "Assessment failed - installation blocked"
    rm -rf "$TEMP_DIR"
    exit 2
fi

read -p "Proceed with installation? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
    npx skills-installer install "$SKILL_SPEC"
else
    echo "Installation cancelled"
fi

rm -rf "$TEMP_DIR"
```

---

## Post-Installation Hook

Create a hook that runs after any skill installation as a safety net.

### Hook Script

Create `~/.claude/hooks/post-skill-install.sh`:

```bash
#!/bin/bash
# Post-installation security audit and quality assessment

SKILL_DIR="$1"
SKILL_NAME=$(basename "$SKILL_DIR")
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_DIR="$HOME/.claude/logs/skill-audits"
mkdir -p "$LOG_DIR"

echo ""
echo "============================================"
echo "  POST-INSTALLATION AUDIT"
echo "============================================"
echo "Skill: $SKILL_NAME"
echo "Time: $TIMESTAMP"
echo ""

# 1. Security Audit
if [ -f "$HOME/.claude/scripts/audit-skill-security.sh" ]; then
    echo "Running security audit..."
    bash "$HOME/.claude/scripts/audit-skill-security.sh" "$SKILL_DIR" \
        "$LOG_DIR/${SKILL_NAME}_security_${TIMESTAMP}.md"
    SECURITY_EXIT=$?
else
    echo "Security audit script not found"
    SECURITY_EXIT=0
fi

# 2. Quality Assessment
echo ""
echo "Running quality assessment..."
bash "$HOME/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh" "$SKILL_DIR" \
    "$LOG_DIR/${SKILL_NAME}_quality_${TIMESTAMP}.md"
QUALITY_EXIT=$?

# 3. Summary
echo ""
echo "============================================"
echo "  AUDIT COMPLETE"
echo "============================================"
echo "Security: $([ $SECURITY_EXIT -eq 0 ] && echo 'PASSED' || echo 'ISSUES FOUND')"
echo "Quality:  $([ $QUALITY_EXIT -eq 0 ] && echo 'PASSED' || echo 'ISSUES FOUND')"
echo ""
echo "Reports saved to: $LOG_DIR/"

# 4. Warning
if [ $SECURITY_EXIT -eq 2 ] || [ $QUALITY_EXIT -eq 2 ]; then
    echo ""
    echo "CRITICAL ISSUES FOUND!"
    echo "Consider uninstalling: npx skills-installer uninstall $SKILL_NAME"
fi
```

### Make Executable

```bash
chmod +x ~/.claude/hooks/post-skill-install.sh
```

---

## Whitelist Configuration

Skip assessment for trusted skills by creating a whitelist.

### Create Whitelist File

Create `~/.claude/config/trusted-skills.txt`:

```
# Official Anthropic skills
anthropic/official-tools
anthropic/code-reviewer

# Your organization's internal skills
mycompany/internal-utils
mycompany/deployment-helper

# Well-established community skills
popular-author/well-known-skill
```

### Modify Assessment Script

Add whitelist check at the beginning of the assessment:

```bash
# Check whitelist
WHITELIST="$HOME/.claude/config/trusted-skills.txt"
SKILL_NAME=$(basename "$SKILL_DIR")

if [ -f "$WHITELIST" ]; then
    if grep -q "$SKILL_NAME" "$WHITELIST"; then
        echo "Skill '$SKILL_NAME' is whitelisted - skipping assessment"
        exit 0
    fi
fi
```

---

## Custom Scoring Rules

### Modify Scoring Rules

Edit `~/.claude/skills/skill-quality-gate/data/scoring-rules.json`:

```json
{
  "dimensions": {
    "security": {
      "weight": 40,  // Increase security weight
      "scoring": {
        "base_score": 40,
        "deductions": {
          "critical_per_issue": 15  // Stricter penalty
        }
      }
    }
  },
  "grades": {
    "excellent": { "min_score": 95, "stars": 5 },  // Stricter threshold
    "good": { "min_score": 80, "stars": 4 }
  }
}
```

### Add Custom Checks

Create additional checks in `data/custom-checks.json`:

```json
{
  "custom_checks": {
    "no_external_apis": {
      "pattern": "api\\..*\\.com",
      "severity": "medium",
      "description": "Uses external APIs"
    },
    "requires_auth": {
      "pattern": "API_KEY|AUTH_TOKEN",
      "severity": "low",
      "description": "Requires authentication"
    }
  }
}
```

---

## Troubleshooting

### Assessment Not Running

1. Check script permissions:
   ```bash
   chmod +x ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh
   ```

2. Verify Bash version:
   ```bash
   bash --version  # Should be 4.0+
   ```

### Security Audit Missing

The quality assessment will use basic checks if `audit-skill-security.sh` is not found. For full security assessment:

```bash
# Verify security audit script exists
ls -la ~/.claude/scripts/audit-skill-security.sh
```

### Database Not Found

If skill-manager database is missing, maintainability and community scores will be estimated:

```bash
# Check database location
ls -la ~/.claude/skills/skill-manager/data/all_skills_with_cn.json
```

---

## Best Practices

1. **Always enable CLAUDE.md rules** - Ensures consistent enforcement
2. **Review high-severity issues manually** - Automated checks have limitations
3. **Keep whitelist minimal** - Only truly trusted sources
4. **Update scoring rules periodically** - As threats evolve
5. **Save audit logs** - For future reference and accountability

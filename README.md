<div align="center">

# Skill Quality Gate

**Language / 语言**: English | [中文](README.zh-CN.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude-Code-purple)](https://claude.ai)

**Pre-installation quality assessment and security audit system for Claude Code Skills**

</div>

---

## Why Skill Quality Gate?

When installing third-party Claude Code Skills, you face potential risks:

- **Security risks**: Malicious code, data exfiltration, privilege escalation
- **Quality issues**: Incomplete documentation, poor error handling, dead code
- **Compatibility problems**: Missing dependencies, untested edge cases

**Skill Quality Gate** provides a comprehensive assessment framework that evaluates skills across 6 dimensions before you install them, helping you make informed decisions.

## Features

### 6-Dimension Quality Assessment

| Dimension | Weight | What It Checks |
|-----------|--------|----------------|
| **Code Quality** | 25% | Structure, complexity, comments, best practices |
| **Documentation** | 20% | SKILL.md completeness, examples, trigger conditions |
| **Security** | 30% | Dangerous patterns, data exfiltration, privilege escalation |
| **Functionality** | 15% | Dependencies, error handling, output formatting |
| **Maintainability** | 5% | Version tracking, update frequency |
| **Community** | 5% | Author reputation, installation count |

### Quality Grades

| Score | Grade | Recommendation |
|-------|-------|----------------|
| 90-100 | ⭐⭐⭐⭐⭐ | Highly Recommended |
| 75-89 | ⭐⭐⭐⭐ | Recommended |
| 60-74 | ⭐⭐⭐ | Acceptable |
| 40-59 | ⭐⭐ | Needs Improvement |
| 0-39 | ⭐ | Not Recommended |

### Three-Layer Protection

1. **CLAUDE.md Rules** - Enforced assessment before every installation
2. **Skill Integration** - Seamless workflow with skill-manager and skills-discovery
3. **Hook Fallback** - Post-installation audit as safety net

## Quick Start

### Installation

```bash
# Clone or download to your Claude skills directory
git clone https://github.com/your-username/skill-quality-gate.git ~/.claude/skills/skill-quality-gate
```

### Basic Usage

```bash
# Assess a skill directory
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill

# With custom report output
bash ~/.claude/skills/skill-quality-gate/scripts/assess-skill-quality.sh /path/to/skill report.md
```

### Example Output

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

## Compatibility

Works with all major skill installation methods:

| Method | Support | Trigger |
|--------|---------|---------|
| **skill-manager** | ✅ | "install skill #N" |
| **skills-discovery** | ✅ | "npx skills-installer install @owner/repo" |
| **Manual (GitHub)** | ✅ | Provide GitHub URL |

## Integration

### Add to CLAUDE.md

For enforced assessment on every installation, add this to your `~/.claude/CLAUDE.md`:

```markdown
# Skill Installation Rules

**IMPORTANT - Pre-Installation Assessment Required**:

**Trigger**: Any skill installation request

**Flow**:
1. Download skill to temp directory
2. Run security audit + quality assessment
3. Display combined report
4. Get user confirmation before installing

**Decision Logic**:
- Security CRITICAL + Quality < 40 → ⛔ Do not install
- Security HIGH + Quality < 60 → ⚠️ Warning, confirm first
- Security OK + Quality >= 75 → ✅ Recommended
```

### Trusted Skills Whitelist

Skip assessment for trusted skills by creating `~/.claude/config/trusted-skills.txt`:

```
anthropic/official-skill
mycompany/internal-tools
```

## Project Structure

```
skill-quality-gate/
├── SKILL.md                    # Entry point for Claude Code
├── README.md                   # English documentation
├── README.zh-CN.md             # Chinese documentation
├── LICENSE                     # MIT License
├── scripts/
│   └── assess-skill-quality.sh # Main assessment script
├── data/
│   ├── scoring-rules.json      # Configurable scoring rules
│   └── security-patterns.json  # Security detection patterns
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

## Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Score >= 60 | Safe to install |
| 1 | Score 40-59 | User decision required |
| 2 | Score < 40 or critical issues | Do not install |

## Requirements

- Bash 4.0+
- Node.js (optional, for database queries)
- `audit-skill-security.sh` (recommended)

## Related Projects

- [skill-manager](https://github.com/...) - Browse and install from 31,767+ skills
- [skills-discovery](https://github.com/...) - Search claude-plugins.dev registry
- [skill-security-auditor](https://github.com/...) - Detailed security analysis

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

**Always review source code before installing third-party skills.**

</div>

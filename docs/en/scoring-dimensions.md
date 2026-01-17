# Scoring Dimensions

This document explains each dimension used in the Skill Quality Gate assessment system.

## Overview

The quality assessment evaluates skills across 6 dimensions:

| Dimension | Weight | Max Score |
|-----------|--------|-----------|
| Code Quality | 25% | 25 points |
| Documentation | 20% | 20 points |
| Security | 30% | 30 points |
| Functionality | 15% | 15 points |
| Maintainability | 5% | 5 points |
| Community | 5% | 5 points |

---

## 1. Code Quality (25 points)

Evaluates the structural quality and readability of the skill's code.

### Checks

#### SKILL.md Structure (5 points)
- **5 points**: Well-structured SKILL.md with 50+ lines
- **3 points**: Basic SKILL.md with 20-49 lines
- **1 point**: Minimal SKILL.md with <20 lines
- **0 points**: Missing SKILL.md (critical issue)

#### Script Structure (5 points)
- **+2 points**: Has proper shebang (#!/bin/bash)
- **+2 points**: Uses set -e or similar error handling
- **+1 point**: Clear file organization

#### Code Size (5 points)
Excludes `data/`, `node_modules/`, and `.git/` directories.

- **5 points**: < 500 lines (optimal)
- **3 points**: 500-1000 lines (acceptable)
- **1 point**: > 1000 lines (review recommended)

#### Comment Coverage (5 points)
- **5 points**: > 15% comment ratio
- **4 points**: 10-15% comment ratio
- **2 points**: 5-10% comment ratio
- **1 point**: < 5% comment ratio

---

## 2. Documentation (20 points)

Evaluates the completeness and clarity of documentation.

### Checks

#### Has Description (4 points)
Keywords searched: `description`, `overview`, `purpose`, `about`

#### Has Trigger Conditions (4 points)
Keywords searched: `trigger`, `when to use`, `activation`, `invoked`

#### Has Usage Examples (4 points)
Keywords searched: `example`, `usage`, `demo`, `sample`

#### Has Parameter Documentation (4 points)
Keywords searched: `parameter`, `argument`, `option`, `input`, `config`

#### Has README.md (4 points)
Checks for `README.md` or `readme.md` in the root directory.

---

## 3. Security (30 points)

The most heavily weighted dimension. Uses the security audit script if available.

### Scoring Logic

- **Base score**: 30 points
- **Deductions**:
  - Per CRITICAL issue: -10 points (capped at -25)
  - 1-2 HIGH issues: -5 points
  - 3+ HIGH issues: -10 points
  - Per MEDIUM issue: -1 point

### Critical Patterns
- `rm -rf` targeting system directories
- `sudo` commands
- Reading credential files
- Data exfiltration via curl/wget
- Netcat reverse shells
- Eval with dynamic input
- Cron/LaunchAgent persistence

### High Patterns
- General `rm -rf` usage
- `chmod 777`
- Dynamic command execution
- Hex-encoded content
- Base64 decoding operations

### Medium Patterns
- Network requests (curl/wget)
- Environment variable access
- File write with dynamic paths

---

## 4. Functionality (15 points)

Evaluates whether the skill is complete and usable.

### Checks

#### Has Dependency Documentation (4 points)
- Checks for dependency mentions when package managers (npm, pip, brew, apt) are used
- Skills without external dependencies get full points

#### Has Error Handling (4 points)
Patterns searched: `set -e`, `trap`, `try`, `catch`, `except`, `|| exit`, `if [`

#### Has Formatted Output (4 points)
Patterns searched: `echo`, `print`, `console.log`, `format`

#### No Dead Code (3 points)
Heuristic check for unused functions.

---

## 5. Maintainability (5 points)

Evaluates long-term viability of the skill.

### Checks

#### Popularity (2 points)
Data source: skill-manager database or GitHub API

- **2 points**: > 100 stars
- **1 point**: > 10 stars

#### Version Tracking (2 points)
Keywords searched: `version`, `changelog`, `v[0-9]`

#### Recent Updates (1 point)
- Checks git history if available
- **1 point**: Updated within last 180 days

---

## 6. Community (5 points)

Evaluates community trust and adoption.

### Checks

#### Official Source (3 points)
- Full points if from `anthropic` or marked `official`
- Partial points if author is identified in package.json

#### Installation Count (2 points)
Data source: skill-manager database

- **2 points**: > 100 installs
- **1 point**: > 10 installs

---

## Grade Boundaries

| Score Range | Grade | Stars | Recommendation |
|-------------|-------|-------|----------------|
| 90-100 | Excellent | 5/5 | Highly Recommended |
| 75-89 | Good | 4/5 | Recommended |
| 60-74 | Acceptable | 3/5 | Usable with improvements |
| 40-59 | Poor | 2/5 | Needs optimization |
| 0-39 | Not Recommended | 1/5 | Do not install |

---

## Exit Codes

| Code | Condition | Meaning |
|------|-----------|---------|
| 0 | Score >= 60 | Safe to install |
| 1 | Score 40-59 | User decision required |
| 2 | Score < 40 OR critical issues | Do not install |

---

## Customization

You can customize scoring rules by editing `data/scoring-rules.json`:

```json
{
  "dimensions": {
    "code_quality": {
      "weight": 25,
      "checks": {
        "skill_md_structure": {
          "max_points": 5,
          "thresholds": {
            "excellent": { "min_lines": 50, "points": 5 }
          }
        }
      }
    }
  }
}
```

---

## Limitations

1. **Static analysis only**: Cannot detect runtime issues
2. **Heuristic-based**: Some checks use pattern matching which may miss edge cases
3. **Database dependency**: Maintainability and community scores may be limited without skill-manager database
4. **No network validation**: Does not verify if URLs are actually malicious

Always review source code manually, regardless of the quality score.

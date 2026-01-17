# Release Checklist

Use this checklist before publishing Skill Quality Gate to GitHub and claude-plugins.dev.

## Pre-Release Testing

- [ ] Run test suite: `bash scripts/test-quality-gate.sh`
- [ ] Test on macOS with Bash 3.2+
- [ ] Test on Linux with Bash 4.0+ (if available)
- [ ] Verify assessment works on at least 3 different skills:
  - [ ] One high-quality skill (should score 75+)
  - [ ] One medium-quality skill (should score 60-74)
  - [ ] One low-quality skill (should score < 60)
- [ ] Test integration with security audit script
- [ ] Verify all documentation links work
- [ ] Check that examples in docs can be executed

## Documentation Review

- [ ] README.md is clear and complete
- [ ] README.zh-CN.md is accurate translation
- [ ] SKILL.md has correct trigger conditions
- [ ] All code examples in docs are tested
- [ ] CHANGELOG.md is up to date
- [ ] CONTRIBUTING.md guidelines are clear
- [ ] LICENSE file is present (MIT)

## Code Quality

- [ ] All scripts have proper shebang (`#!/bin/bash`)
- [ ] Variables are quoted properly
- [ ] Error handling is in place (`set -euo pipefail`)
- [ ] Functions have clear names
- [ ] Complex logic has comments
- [ ] No hardcoded paths (use variables)
- [ ] shellcheck passes (if available):
  ```bash
  shellcheck scripts/assess-skill-quality.sh
  ```

## Configuration Files

- [ ] `data/scoring-rules.json` is valid JSON
- [ ] `data/security-patterns.json` is valid JSON
- [ ] Scoring weights add up to 100%
- [ ] Security patterns are tested
- [ ] No sensitive data in config files

## Git Repository Setup

- [ ] Initialize git repository:
  ```bash
  cd ~/.claude/skills/skill-quality-gate
  git init
  ```
- [ ] Create `.gitignore` (already present)
- [ ] Add all files:
  ```bash
  git add .
  ```
- [ ] Initial commit:
  ```bash
  git commit -m "feat: initial release of Skill Quality Gate v1.0.0"
  ```
- [ ] Create GitHub repository (don't push yet)
- [ ] Add remote:
  ```bash
  git remote add origin https://github.com/YOUR-USERNAME/skill-quality-gate.git
  ```

## GitHub Repository Configuration

- [ ] Set repository description:
  > "Pre-installation quality assessment and security audit system for Claude Code Skills"
- [ ] Add topics/tags:
  - `claude-code`
  - `skill-quality`
  - `security-audit`
  - `bash`
  - `quality-assurance`
- [ ] Enable Issues
- [ ] Enable Discussions (optional)
- [ ] Create repository structure:
  - [ ] Add README.md to repository root
  - [ ] Ensure all docs are in correct locations

## Release Preparation

- [ ] Create annotated tag:
  ```bash
  git tag -a v1.0.0 -m "Release version 1.0.0

  Initial release with:
  - 6-dimension quality assessment
  - Security audit integration
  - Bilingual documentation
  - Configurable scoring rules
  - Example reports"
  ```
- [ ] Review tag:
  ```bash
  git show v1.0.0
  ```

## Push to GitHub

- [ ] Push code:
  ```bash
  git push origin main
  ```
- [ ] Push tags:
  ```bash
  git push origin v1.0.0
  ```

## GitHub Release

- [ ] Create release on GitHub from tag v1.0.0
- [ ] Release title: "Skill Quality Gate v1.0.0 - Initial Release"
- [ ] Release notes (copy from CHANGELOG.md)
- [ ] Attach any additional assets if needed

## claude-plugins.dev Registration

- [ ] Visit https://claude-plugins.dev (or appropriate registry)
- [ ] Submit skill for registration
- [ ] Provide required information:
  - Repository URL
  - Skill name: `skill-quality-gate`
  - Description
  - Tags
  - Documentation link

## Post-Release

- [ ] Verify skill can be installed:
  ```bash
  npx skills-installer install YOUR-USERNAME/skill-quality-gate
  ```
- [ ] Test installed skill works correctly
- [ ] Monitor for issues in first 48 hours
- [ ] Respond to early feedback

## Integration Testing

- [ ] Test with CLAUDE.md rules enabled
- [ ] Verify mandatory pre-installation flow works
- [ ] Test whitelist functionality
- [ ] Confirm reports are generated correctly

## Documentation Website (Optional)

- [ ] Create GitHub Pages branch
- [ ] Deploy documentation
- [ ] Add website link to repository

## Community

- [ ] Announce on relevant channels (if applicable)
- [ ] Prepare to respond to questions
- [ ] Monitor GitHub issues
- [ ] Consider creating a discussion forum

## Maintenance Plan

- [ ] Set up issue templates
- [ ] Define support policy
- [ ] Plan for security updates
- [ ] Schedule periodic pattern database updates

---

## Quick Release Commands

```bash
# From skill-quality-gate directory

# 1. Initialize and commit
git init
git add .
git commit -m "feat: initial release of Skill Quality Gate v1.0.0"

# 2. Add remote (replace with your URL)
git remote add origin https://github.com/YOUR-USERNAME/skill-quality-gate.git

# 3. Tag release
git tag -a v1.0.0 -m "Release version 1.0.0"

# 4. Push everything
git push origin main
git push origin v1.0.0
```

## Verification Commands

```bash
# Test the skill
bash scripts/test-quality-gate.sh

# Validate JSON
python3 -m json.tool data/scoring-rules.json
python3 -m json.tool data/security-patterns.json

# Check Bash compatibility
bash --version
bash scripts/assess-skill-quality.sh --help || echo "Missing --help (OK)"
```

---

**Note**: This is a comprehensive checklist. Adjust based on your specific needs and timeline.

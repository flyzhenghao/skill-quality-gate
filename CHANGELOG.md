# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-18

### Added
- Initial release of Skill Quality Gate
- 6-dimension quality assessment system:
  - Code Quality (25%)
  - Documentation (20%)
  - Security (30%)
  - Functionality (15%)
  - Maintainability (5%)
  - Community (5%)
- Core assessment script (`assess-skill-quality.sh`) compatible with Bash 3.x+
- Integration with existing `audit-skill-security.sh` for security scanning
- Comprehensive bilingual documentation (English and Chinese):
  - README files
  - SKILL.md entry point
  - Integration guides
  - Scoring dimension explanations
- Configurable scoring rules (`data/scoring-rules.json`)
- Security pattern database (`data/security-patterns.json`)
- Example reports for both good and poor quality skills
- CLAUDE.md integration rules for mandatory pre-installation assessment
- Safe skill installer workflow documentation
- Exit code system (0/1/2) for automated decision making
- Support for multiple installation methods:
  - skill-manager (local database)
  - skills-discovery (online registry)
  - Manual GitHub URL installation
- MIT license

### Features
- Automatic detection of:
  - Dangerous file operations (rm -rf, etc.)
  - Privilege escalation attempts (sudo, chmod 777)
  - Data exfiltration patterns
  - Missing documentation
  - Poor code practices
  - Security vulnerabilities
- Markdown report generation with:
  - Overall quality score and grade
  - Dimension-by-dimension breakdown
  - Critical issues, improvements, and optimizations
  - Clear install/don't-install verdict
- Whitelist support for trusted skills
- Offline mode (basic checks when network unavailable)

### Technical Notes
- Compatible with macOS Bash 3.2+ and Linux Bash 4.0+
- Uses simple variables instead of associative arrays for Bash 3.x compatibility
- Integrates seamlessly with existing Claude Code workflow
- No external dependencies required (Node.js optional for database queries)

[1.0.0]: https://github.com/your-username/skill-quality-gate/releases/tag/v1.0.0

# Contributing to Skill Quality Gate

Thank you for your interest in contributing to Skill Quality Gate! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Issues

If you find a bug or have a suggestion:

1. **Search existing issues** first to avoid duplicates
2. **Create a new issue** with a clear title and description
3. **Include**:
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your environment (OS, Bash version, Claude Code version)
   - Sample skill that demonstrates the issue (if applicable)

### Suggesting Enhancements

We welcome suggestions for:
- New security patterns to detect
- Additional quality checks
- Improved scoring algorithms
- Better documentation
- Translation improvements

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Test thoroughly**:
   ```bash
   # Test the assessment script
   bash scripts/assess-skill-quality.sh /path/to/test-skill

   # Verify it works on both good and bad skills
   ```
5. **Update documentation** if needed
6. **Commit with clear messages**:
   ```
   feat: add detection for new security pattern
   fix: correct scoring calculation for documentation
   docs: improve integration guide clarity
   ```
7. **Push to your fork**: `git push origin feature/amazing-feature`
8. **Open a Pull Request** with:
   - Clear description of changes
   - Why the change is needed
   - Any breaking changes
   - Test results

## Development Guidelines

### Code Style

**Bash Scripts**:
- Use 4-space indentation
- Always quote variables: `"$VARIABLE"`
- Use meaningful function names
- Add comments for complex logic
- Test with both Bash 3.x and 4.x

**JSON Configuration**:
- Use 2-space indentation
- Keep patterns readable with comments
- Validate JSON syntax before committing

**Markdown Documentation**:
- Use clear headings
- Include code examples
- Keep line length < 100 characters for readability
- Use tables for structured data

### Testing

Before submitting:

1. **Test with real skills**:
   ```bash
   # Test with a known good skill
   bash scripts/assess-skill-quality.sh ~/.claude/skills/skill-manager

   # Test with a skill that has issues
   bash scripts/assess-skill-quality.sh /path/to/problematic-skill
   ```

2. **Test on different platforms**:
   - macOS (Bash 3.2)
   - Linux (Bash 4.x)

3. **Verify exit codes**:
   ```bash
   bash scripts/assess-skill-quality.sh /path/to/skill
   echo "Exit code: $?"
   ```

4. **Check report generation**:
   - Reports should be valid Markdown
   - All sections should be present
   - Scores should be accurate

### Adding New Security Patterns

To add a new security pattern:

1. **Edit** `data/security-patterns.json`
2. **Add your pattern** under the appropriate severity level:
   ```json
   {
     "id": "unique-pattern-id",
     "name": "Human-Readable Name",
     "pattern": "regex-pattern-here",
     "description": "What this pattern detects",
     "remediation": "How to fix it"
   }
   ```
3. **Test the pattern**:
   - Create a test file with the pattern
   - Run assessment to verify detection
   - Ensure no false positives
4. **Document** in `docs/en/scoring-dimensions.md`

### Adding New Quality Checks

To add a new quality check:

1. **Edit** `data/scoring-rules.json` to define scoring
2. **Implement** in `scripts/assess-skill-quality.sh`:
   - Add to appropriate assess_* function
   - Update score calculation
   - Add improvement/optimization messages
3. **Update documentation**:
   - `docs/en/scoring-dimensions.md`
   - `docs/zh-CN/scoring-dimensions.md`
4. **Test thoroughly** with various skills

### Translation

We welcome translations to new languages:

1. **Create language directory**: `docs/[language-code]/`
2. **Translate files**:
   - `README.[lang].md`
   - `docs/[lang]/scoring-dimensions.md`
   - `docs/[lang]/integration-guide.md`
3. **Update language selector** in README.md
4. **Ensure accuracy** - prefer clarity over literal translation

## Commit Message Guidelines

Format: `<type>: <subject>`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```
feat: add detection for credential file access
fix: correct Bash 3.x compatibility issue
docs: improve integration guide with examples
refactor: simplify score calculation logic
```

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help newcomers
- Assume good intentions
- No harassment or discrimination

## Questions?

- Open an issue with the `question` label
- Check existing documentation first
- Be specific about what you need help with

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Skill Quality Gate better!

# Contributing to Winget Offline Installer

🎉 Thank you for your interest in contributing to the Winget Offline Installer project! 

## 🚀 How to Contribute

### 🐛 Reporting Bugs

Before creating bug reports, please check the [existing issues](https://github.com/EXLOUD/winget-offline-installer/issues) to avoid duplicates.

When creating a bug report, please include:

- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **System information**:
  - Windows version
  - Architecture (x86, x64, ARM64)
  - PowerShell version
- **Error messages** (if any)
- **Screenshots** (if applicable)

### 💡 Suggesting Enhancements

Enhancement suggestions are welcome! Please:

- Check if the enhancement has already been suggested
- Provide a clear and detailed explanation
- Explain why this enhancement would be useful
- Include examples if possible

### 🔧 Code Contributions

#### Prerequisites

- Git installed on your system
- Windows 10/11 for testing
- PowerShell 5.1 or later
- Basic knowledge of PowerShell and Batch scripting

#### Development Process

1. **Fork** the repository
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/your-username/winget-offline-installer.git
   cd winget-offline-installer
   ```

3. **Create** a new branch for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make** your changes following the [coding standards](#coding-standards)

5. **Test** your changes thoroughly:
   - Test on different Windows versions (if possible)
   - Test on different architectures
   - Verify existing functionality still works

6. **Commit** your changes:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

7. **Push** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Create** a Pull Request with:
   - Clear title and description
   - Link to any related issues
   - Screenshots of testing (if applicable)

#### Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat: add ARM64 architecture support
fix: resolve PATH environment variable issue
docs: update installation instructions
style: improve code formatting in launcher script
```

## 📋 Coding Standards

### PowerShell Scripts

- Use **4 spaces** for indentation
- Follow [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/writing-portable-cmdlets)
- Use **PascalCase** for function names
- Use **camelCase** for variables
- Add **comments** for complex logic
- Use **Try-Catch** blocks for error handling
- Prefer **explicit** over implicit operations

Example:
```powershell
function Install-WingetDependency {
    param(
        [string]$FilePath,
        [string]$Architecture
    )
    
    try {
        Write-Host "[INFO] Installing dependency for $Architecture..." -ForegroundColor Yellow
        Add-AppxPackage -Path $FilePath -ErrorAction Stop
        Write-Host "[SUCCESS] Dependency installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to install dependency: $_" -ForegroundColor Red
        throw
    }
}
```

### Batch Files

- Use **2 spaces** for indentation
- Use **UPPERCASE** for environment variables
- Add **comments** using `::` for important sections
- Use **error checking** with `%errorlevel%`
- Quote paths that might contain spaces

Example:
```batch
:: Check if file exists
if not exist "%SCRIPT_PATH%" (
  echo [ERROR] Script not found: %SCRIPT_PATH%
  exit /b 1
)
```

### General Guidelines

- **Keep functions small** and focused
- **Use descriptive variable names**
- **Add error handling** for all operations
- **Test edge cases** when possible
- **Document complex logic** with comments
- **Follow existing code patterns** in the project

## 🧪 Testing

### Manual Testing Checklist

Before submitting a PR, please verify:

- [ ] Script runs without errors on clean system
- [ ] All dependencies are installed correctly
- [ ] Winget is accessible after installation
- [ ] Telemetry is properly disabled
- [ ] PATH is updated correctly
- [ ] Works with existing winget installations
- [ ] Handles permission errors gracefully
- [ ] Provides clear error messages

### Test Environments

If possible, test on:
- Windows 10 (different versions)
- Windows 11
- Different architectures (x64, x86, ARM64)
- Systems with and without existing winget
- Systems with different PowerShell versions

## 📚 Documentation

### When to Update Documentation

Update documentation when:
- Adding new features
- Changing existing functionality
- Fixing bugs that affect usage
- Adding new configuration options
- Changing file structure

### Documentation Standards

- Use **clear, concise language**
- Include **examples** where helpful
- Keep **screenshots up to date**
- Use **proper markdown formatting**
- Update **table of contents** if needed

## 🎯 Pull Request Guidelines

### Before Submitting

- [ ] Code follows the project's style guidelines
- [ ] Self-review of the code completed
- [ ] Code is commented, particularly in hard-to-understand areas
- [ ] Documentation has been updated
- [ ] Changes have been tested
- [ ] No new warnings or errors introduced

### PR Description Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tested on Windows 10
- [ ] Tested on Windows 11
- [ ] Tested on x64 architecture
- [ ] Tested on x86 architecture
- [ ] Tested on ARM64 architecture
- [ ] Tested with existing winget installation
- [ ] Tested on clean system

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Additional Notes
Any additional information about the changes.
```

## 🏷️ Release Process

Releases are managed by maintainers and follow semantic versioning:

- **Major** version: Breaking changes
- **Minor** version: New features (backwards compatible)
- **Patch** version: Bug fixes

## 📞 Getting Help

If you need help with contributing:

1. Check the [README](README.md) for basic information
2. Look through [existing issues](https://github.com/EXLOUD/winget-offline-installer/issues)
3. Create a new issue with the `question` label
4. Join discussions in existing issues

## 🙏 Recognition

Contributors will be:
- Added to the contributors list
- Mentioned in release notes for significant contributions
- Credited in documentation updates

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Winget Offline Installer! 🚀
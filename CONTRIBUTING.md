# Contributing to IntentKit

First off, thank you for considering contributing to IntentKit! It's people like you that make IntentKit such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the [IntentKit Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title** for the issue to identify the problem
* **Describe the exact steps which reproduce the problem** in as many details as possible
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps** and point out what exactly is the problem with that behavior
* **Explain which behavior you expected to see instead and why**
* **Include code samples** that demonstrate the issue
* **Include your environment details** (iOS/macOS version, Xcode version, Swift version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title** for the issue to identify the suggestion
* **Provide a step-by-step description of the suggested enhancement** in as many details as possible
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior** and **explain which behavior you expected to see instead** and why
* **Explain why this enhancement would be useful** to most IntentKit users

### Pull Requests

1. Fork the repo and create your branch from `develop`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the existing code style
6. Issue that pull request!

## Development Process

1. **Fork & Clone**: Fork the repository and clone it locally
   ```bash
   git clone https://github.com/yourusername/IntentKit.git
   cd IntentKit
   ```

2. **Create a Branch**: Create a branch for your feature or fix
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Make Changes**: Make your changes and commit them
   ```bash
   git add .
   git commit -m "Add your meaningful commit message"
   ```

4. **Run Tests**: Ensure all tests pass
   ```bash
   swift test
   ```

5. **Run Benchmarks**: Check performance impact
   ```bash
   swift test --filter Benchmark
   ```

6. **Push & PR**: Push your branch and create a pull request
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### Swift Style Guide

* Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
* Use 4 spaces for indentation (not tabs)
* Keep lines under 120 characters when possible
* Use meaningful variable and function names
* Add documentation comments for all public APIs

### Code Organization

```
IntentKit/
├── Sources/
│   ├── IntentKitCore/       # Core framework code
│   ├── IntentKitCodeGen/    # Code generation module
│   └── IntentKitCLI/        # Command-line tool
├── Tests/
│   ├── IntentKitCoreTests/  # Unit tests
│   ├── IntentKitCodeGenTests/
│   └── IntentKitBenchmarks/ # Performance tests
└── Examples/                # Example usage
```

### Documentation

* Use Swift documentation comments for all public APIs:
  ```swift
  /// Brief description of the function.
  /// - Parameters:
  ///   - parameter1: Description of parameter1
  ///   - parameter2: Description of parameter2
  /// - Returns: Description of return value
  /// - Throws: Description of errors that can be thrown
  public func myFunction(parameter1: String, parameter2: Int) throws -> Bool
  ```

* Update README.md if you change user-facing functionality
* Add entries to CHANGELOG.md for notable changes

### Testing

* Write unit tests for all new functionality
* Ensure test coverage remains above 95%
* Include both positive and negative test cases
* Add performance tests for critical paths
* Test names should clearly describe what they test:
  ```swift
  func testParameterExtractionWithValidatorSucceeds()
  func testBatchDonationFailsWithInvalidIntents()
  ```

## Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

Examples:
```
Add async parameter resolution support

- Implement AsyncParameterResolver
- Add tests for async resolution
- Update documentation

Fixes #123
```

## Release Process

1. Update version numbers in relevant files
2. Update CHANGELOG.md with release notes
3. Create a git tag for the release
4. GitHub Actions will automatically run tests and create release

## Questions?

Feel free to open an issue with the `question` label or reach out to the maintainers.

## Recognition

Contributors will be recognized in:
* The project README
* Release notes for their contributions
* The contributors graph on GitHub

Thank you for contributing to IntentKit! 🎉
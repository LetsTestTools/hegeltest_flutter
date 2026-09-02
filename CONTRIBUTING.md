# Contributing to hegeltest_flutter

First off, thank you for considering contributing to `hegeltest_flutter`! We welcome contributions of all kinds, including bug reports, feature requests, documentation improvements, and code changes.

## Development Environment Setup

To set up the project locally:

1. Fork and clone the repository.
2. Run `flutter pub get` to fetch dependencies.
3. Run `flutter test` to execute the test suite.

### Running with hegeltest 0.5.0+

Due to limitations in how `flutter test` resolves Native Assets from pub dependencies, `hegeltest` (0.5.0+) requires the `HEGEL_LIBHEGEL_PATH` environment variable to load the native binary. Find the binary in your pub cache:

```bash
# macOS arm64:
export HEGEL_LIBHEGEL_PATH=$(find $HOME/.pub-cache/hosted/pub.dev -path '*/hegeltest-*/native/macos_arm64/libhegel_c.dylib' | sort -V | tail -1)
# Linux x64:
export HEGEL_LIBHEGEL_PATH=$(find $HOME/.pub-cache/hosted/pub.dev -path '*/hegeltest-*/native/linux_x64/libhegel_c.so' | sort -V | tail -1)

flutter test
```

## Making Changes

1. Create a branch for your changes (`git checkout -b feature/amazing-feature`).
2. Make your changes and test them locally.
3. Write tests for any new features or bug fixes. Do not break existing tests!
4. Ensure your code follows the existing style patterns.
5. Format your code using `dart format .`
6. Run static analysis using `flutter analyze` and resolve any issues.

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

* `feat:` A new feature
* `fix:` A bug fix
* `docs:` Documentation only changes
* `test:` Adding missing tests or correcting existing tests
* `ci:` Changes to our CI configuration files and scripts
* `chore:` Other changes that don't modify src or test files

## Submitting Changes

1. Push your branch to your fork (`git push origin feature/amazing-feature`).
2. Open a Pull Request against the `main` branch.
3. Fill out the PR template.
4. The CI pipeline (GitHub Actions) will automatically run tests across platforms, check formatting, and verify the package.
5. A maintainer will review your PR and provide feedback.

## Need Help?

If you have questions, please open a GitHub Issue or reach out on our [GitHub repository](https://github.com/LetsTestTools/hegeltest_flutter).

Looking for something to work on? Check the issues labeled **"good first issue"**.

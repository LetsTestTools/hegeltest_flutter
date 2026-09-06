# Contributing to hegeltest_flutter

First off, thank you for considering contributing to `hegeltest_flutter`! We welcome contributions of all kinds, including bug reports, feature requests, documentation improvements, and code changes.

## Development Environment Setup

To set up the project locally:

1. Fork and clone the repository.
2. Ensure you have the [Flutter SDK](https://flutter.dev/docs/get-started/install) installed (`>=3.38.0`).
3. Run `flutter pub get` to fetch dependencies.
4. Install [Lefthook](https://github.com/evilmartians/lefthook) for automated pre-commit checks:
   ```bash
   # macOS:
   brew install lefthook

   # Linux / Windows (via npm or release binary):
   npm install -g @evilmartians/lefthook
   # or download from https://github.com/evilmartians/lefthook/releases

   # Activate git pre-commit hooks:
   lefthook install
   ```
5. Run tests locally (see below for `HEGEL_LIBHEGEL_PATH`).

### Pre-commit Hooks (Lefthook)

This repository enforces formatting and static analysis on every commit via Lefthook:
- **`format`**: Verifies staged files conform to `dart format`.
- **`analyze`**: Ensures `flutter analyze --fatal-infos` passes with 0 issues.

> [!NOTE]
> Please do not bypass pre-commit hooks (avoid `git commit --no-verify`). Fixing lints locally ensures our multi-platform CI checks pass on the first attempt.

> [!TIP]
> **Why no Nix devShell for Flutter?**
> Flutter requires write access to its internal cache (`bin/cache/`) and direct integration with host Xcode / CocoaPods toolchains on macOS. Placing Flutter inside a read-only Nix store frequently causes permission and code-signing conflicts. We recommend using your standard host Flutter install with Lefthook.

### Running Tests Locally (HEGEL_LIBHEGEL_PATH)

Due to limitations in how `flutter test` resolves Native Assets from transitive dependencies during local execution, `hegeltest` requires the `HEGEL_LIBHEGEL_PATH` environment variable to load the native engine binary. Point it to the prebuilt binary in your local checkout or pub cache:

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

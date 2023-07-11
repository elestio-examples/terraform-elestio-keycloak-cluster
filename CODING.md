These instructions are intended for those who make modifications to the module and wish to open a pull request.

A plugin is used to parse the module and update the documentation in the README file.</br>
We use a precommit hook to simplify the process in this repository.

## Instructions

1. Install [terraform-docs](https://terraform-docs.io/user-guide/installation/)

```bash
brew install terraform-docs # macOS user
```

2. Install [pre-commit](https://pre-commit.com/) hooks

```bash
brew install pre-commit # macOS user

pre-commit install
```

Documentation will be updated when you commit.

If you want to run it manually: `pre-commit run --all-files`

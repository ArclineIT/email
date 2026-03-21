# Contributing to arcline-email

Thanks for your interest. This is a small project maintained by one person, so
keep expectations calibrated accordingly.

## Getting Started

1. Fork the repo and clone your fork
2. Make sure you have Go 1.22+ installed
3. Run `go mod tidy` to pull dependencies
4. Build with `go build ./...` and confirm it compiles clean

## Reporting Issues

Open a GitHub issue. Include:
- What you were trying to do
- What happened instead
- Relevant logs or error output
- Go version and OS

For security vulnerabilities, do **not** open a public issue. Email
`blake@arclineit.com` directly with details.

## Submitting Changes

1. Open an issue first for anything non-trivial — discuss the approach before
   writing code
2. Keep PRs focused: one fix or feature per PR
3. Write clear commit messages (what changed and why, not just what)
4. Make sure `go build ./...` and `go vet ./...` pass before submitting
5. If you add a new package, add a brief comment at the top explaining what
   it does

## Code Style

- Standard `gofmt` formatting — no exceptions
- Exported identifiers get doc comments
- Errors are returned, not logged inside library code
- No `panic` in non-main packages
- Prefer the standard library over adding new dependencies; new deps need a
  reason

## What Gets Accepted

This project has a specific scope (see `todo.md` and `README.md`). PRs that
add features outside that scope are unlikely to be merged, not because they're
bad ideas, but because scope creep is how small projects become unmaintainable.

If you want to propose something outside current scope, open an issue and make
the case first.

## License

By contributing, you agree that your contributions will be licensed under the
same MIT license as the project.

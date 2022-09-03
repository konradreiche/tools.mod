# tools.mod

Go projects may require tools that do not end up being the code running in a production environment, examples include linters for static code analysis or code generation tools.

One common [approach](https://github.com/golang/go/wiki/Modules#how-can-i-track-tool-dependencies-for-a-module) to track tool dependencies in Go is the use of a `tools.go` file, which includes all tools with import statements and using a `//go:build tools` build constraint. Tool dependencies can also be managed in a separate Go modules file within the same project.

This repository illustrates how to manage your Go tool dependencies using a separate Go modules file which is described in more detail here: https://konradreiche.com/blog/managing-tool-dependencies-with-go-modules

## TL;DR

Create a separate Go modules file:

```bash
go mod -modfile=tools.mod init 
```

Add tool dependencies to track, for example `staticcheck` and `sqlc`:

```bash
go get -modfile=tools.mod honnef.co/go/tools/cmd/staticcheck@v0.3.3
go get -modfile=tools.mod ithub.com/kyleconroy/sqlc/cmd/sqlc@v1.15.0
```

Install dependencies based on the version specified:

```bash
go install -modfile=tools.mod honnef.co/go/tools/cmd/staticcheck
go install -modfile=tools.mod github.com/kyleconroy/sqlc/cmd/sqlc
```

## tools.mod

To illustrate this we are going to create a new Go project with one of my two favorite tools:

* [Staticcheck](https://staticcheck.io/) - Go linter
* [sqlc](https://sqlc.dev/) - Generate idiomatic Go code from SQL

In this project we want to use `staticcheck` to lint our code. The specific version used in this project will be tracked in a different Go modules file. Here we call it `tools.mod` but you can choose a different name.

```bash
go mod init -modfile=tools.mod
```

To add `staticcheck` as a new tool dependencies we call `go get` with `-modfile=tools.mod` specifying the alternative Go modules file.

```bash
go get -modfile=tools.mod honnef.co/go/tools/cmd/staticcheck@v0.3.3
 ```

This will add all of staticchecks' dependencies to the `tools.mod` file and will generate a `tools.sum` containing the cryptographic hashes of the content of specific module versions. We repeat this for `sqlc`.

```bash
go get -modfile=tools.mod github.com/kyleconroy/sqlc/cmd/sqlc@v1.15.0
```

If someone checks out this project, they can now install both tools according to the version specified in `tools.mod` by running:

```bash
go install -modfile=tools.mod honnef.co/go/tools/cmd/staticcheck
go install -modfile=tools.mod github.com/kyleconroy/sqlc/cmd/sqlc
```

Note here how the version tag is omitted because `tools.mod` defines which version to install. To make it easier for someone new to set everything up those commands can be extracted into a make target:

```make
.PHONY: install-tools
install-tools:
	go install -modfile=tools.mod honnef.co/go/tools/cmd/staticcheck
	go install -modfile=tools.mod github.com/kyleconroy/sqlc/cmd/sqlc
```

To remove a dependency you can run:

```bash
go get -modfile=tools.mod github.com/kyleconroy/sqlc@none
```

With all of this in mind: why would you choose a `tools.mod` over a `tools.go` which tracks tool dependencies in the same Go modules file? Using a Go file which imports the tools with a [blank identifier](https://go.dev/ref/spec#Import_declarations) works around the requirement for dependencies to be referenced in code.

If the referenced code is run in production, should it even be imported in the first place? The tools might generate code which runs in production but those dependencies will be tracked in the `go.mod` file after all.

Using a separate `tools.mod` makes it possible to cleanly separate code which is compiled into the target build and tools which are used to maintain the code.

There is, however, an issue with not being able to run `go mod tidy`. This command only works based on dependencies being referenced in code. Since none of the code is referenced, running `go mod tidy -modfile=tools.mod` will end up wiping out the content of your `tools.mod` file. If you want to keep your `tools.sum` file tidy you would need to re-generate it from scratch.

To get the best of both worlds, you could use a `tools.go` file but manage it in a [git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) which allows you to manage the tool dependencies in a `go.mod` file, be able to run `go mod tidy` but also keep the dependency graph separate from your main module.

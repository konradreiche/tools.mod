.PHONY: install-tools
install-tools:
	go install -modfile=tools.mod honnef.co/go/tools/cmd/staticcheck
	go install -modfile=tools.mod github.com/kyleconroy/sqlc/cmd/sqlc

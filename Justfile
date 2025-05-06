# Justfile for OCaml project using dune
# See: https://just.systems/man/en/

# Default recipe: build the project
default: build

# Build the project
build:
    dune build

# Run the project (pass extra args if needed)
run *ARGS:
    dune exec echos_dark -- {{ARGS}}

debug *ARGS:
  rm -rf resources/chunks
  dune exec echos_dark -- --debug {{ARGS}}

# Clean build artifacts
clean:
    dune clean
    rm -rf resources/chunks

# Run tests (if you have them)
test:
    dune runtest

# List all available recipes
help:
    just --list

# pixi build + kache example

A tiny Rust CLI that demonstrates `pixi build` using
[kache](https://github.com/kunobi-ninja/kache) (from
[conda-forge](https://github.com/conda-forge/kache-feedstock)) as the
compilation cache.

The second build compiles nothing: kache restores every crate from its local
store.

```
==> cold build stats
  Hit rate     0.0%    0 of 14 crates from cache, 15 compiled, 1 not cached

==> warm build stats
  Hit rate     100.0%   14 of 14 crates from cache, 0 compiled
```

## Requirements

- pixi 0.82.0 or newer (the example uses the `pixi-build` preview)
- one of the declared platforms: `osx-arm64` or `linux-64`

## Quickstart

```sh
pixi run -e dev demo
```

The `demo` task:

1. runs `pixi build --clean -o dist` (cold),
2. prints `kache stats`,
3. clears only the kache runtime directory (events/sockets),
4. runs `pixi build --clean -o dist` again (warm),
5. prints `kache stats` for the warm session.

The built conda package lands in `dist/`. A single clean build is available as
`pixi run -e dev build`, and the CLI itself can be run with
`pixi run -e dev cargo run -- Alice`.

## How it works

`pixi.toml` uses the `pixi-build-rust` backend:

```toml
[package.build-dependencies]
kache = { workspace = true }

[package.build]
backend = { name = "pixi-build-rust", workspace = true }
secrets = ["KACHE_CACHE_DIR", "KACHE_RUNTIME_DIR", "CARGO_HOME"]

[package.build.config]
extra-args = ["--profile", "release"]
env = { RUSTC_WRAPPER = "kache", KACHE_LOCAL_ONLY = "1" }
```

Three details make the cache usable:

- **Cache paths must be passed in.** A pixi build runs isolated: `HOME` and
  `PWD` point at `.pixi/bld/<pkg>/<key>/work`, so kache's default cache
  location would die with the build directory. `scripts/env.sh` points
  `KACHE_CACHE_DIR`, `KACHE_RUNTIME_DIR`, and `CARGO_HOME` at repo-local
  directories and they reach the sandbox through `secrets`.
- **The cache lives outside `.pixi`.** `pixi build --clean` removes pixi's
  artifact/workspace cache. Keeping `.kache` at the repo root means a clean
  build still gets warm kache hits.
- **`SCCACHE*` variables are stripped.** `pixi-build-rust` force-exports
  `RUSTC_WRAPPER="sccache"` whenever any `SCCACHE*` variable is visible, even
  when kache is the configured wrapper. `scripts/env.sh` unsets them before
  invoking pixi.

`kache report`/`kache stats --full` read the event log directly and do not
start a daemon; local-only caching works without one.

## CI

`.github/workflows/ci.yml` builds on `ubuntu-latest` and `macos-latest`:

- `actions/cache` restores `./.kache` and `./.cargo` (keyed on OS/arch and
  `Cargo.lock`),
- two `pixi build --clean` runs force cargo to recompile and then hit kache,
- `kache stats --last-build --full --json` is written to the job summary.

`kache-action` is intentionally not used: it installs its own kache (v2 by
default) and exports `RUSTC_WRAPPER` outside the pixi sandbox, so it would not
drive the conda-forge binary used inside the build.

## Notes

- Versions are pinned: `kache ==1.2.2`, `pixi-build-rust >=0.5.7,<0.6`, Rust
  `1.95.0` (build variant). conda-forge currently ships kache 1.x, not the
  upstream 2.x line.
- The demo keeps its dependencies free of proc-macro crates. In kache 1.2.2
  the sandboxed build failed to resolve a proc-macro dylib (`clap_derive`) for
  its dependent crate, so the CLI uses clap's builder API instead of `derive`.

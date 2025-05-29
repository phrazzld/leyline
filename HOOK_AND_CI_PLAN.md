# Dev‑Infra Reusable Workflows & Composite Actions

> **Status:** Draft v0.1 — May 15 2025
> **Authors:** Platform Engineering

---

## 1 · Purpose

Provide a **single source of truth** for GitHub Actions workflows, composite actions, and development‑time quality gates (pre‑commit hooks) that can be shared across all internal and open‑source repositories with minimal per‑project boilerplate.

## 2 · Goals & Non‑Goals

|                                                           | In scope | Out of scope                                         |
| --------------------------------------------------------- | -------- | ---------------------------------------------------- |
| CI pipelines for build / test / lint / coverage           | ✅        | —                                                    |
| Canonical pre‑commit configuration                        | ✅        | Alternate hooks runners (lefthook, husky)            |
| Multi‑language support (Node, Python, Rust, Go)           | ✅        | Niche stacks without runners in GitHub‑hosted images |
| Tag‑based versioning & semver breaking‑change policy      | ✅        | Publishing to other CI providers (GitLab, Circle)    |
| Automated upgrade PRs via Dependabot/pre‑commit.ci        | ✅        | Auto‑merging of those PRs                            |
| Security hardening of actions (OIDC, least‑privilege PAT) | ✅        | Supply‑chain monitoring beyond GitHub’s Dependabot   |

## 3 · Repository Layout

```text
 dev‑infra/
 ├─ .github/
 │   ├─ workflows/
 │   │   ├─ _build‑test.yml        # reusable workflow — language‑agnostic build+test
 │   │   ├─ _lint.yml              # lint passes
 │   │   ├─ _coverage.yml          # upload & enforce coverage
 │   │   └─ release.yml            # dev‑infra’s own release pipeline
 │   └─ dependabot.yml             # auto‑bump third‑party actions
 ├─ actions/                       # Composite & Docker actions
 │   ├─ setup‑node/
 │   │   └─ action.yml
 │   ├─ setup‑python/
 │   ├─ setup‑rust/
 │   ├─ vitest/
 │   ├─ pytest/
 │   └─ cargo‑fmt/
 ├─ hooks/                         # Custom hook scripts referenced by pre‑commit
 ├─ pre‑commit‑config.yaml         # Canonical hook manifest (importable)
 ├─ templates/                     # Optional one‑shot scaffolding
 │   ├─ ts‑app/
 │   ├─ py‑lib/
 │   └─ rust‑crate/
 ├─ scripts/
 │   ├─ generate_dispatcher.sh     # one‑liner for new repos
 │   └─ validate_workflow_inputs.py
 └─ docs/
     ├─ plan.md  ← this file
     └─ CHANGELOG.md
```

## 4 · Reusable Workflows (`.github/workflows/_*.yml`)

Each workflow is declared with `on: workflow_call` so consumer repos include just a stub.

### 4.1 `_build-test.yml`

* **Inputs**

  | name           | type   | required | default | description                          |
  | -------------- | ------ | -------- | ------- | ------------------------------------ |
  | `lang`         | string | ✅        | —       | `node` \| `python` \| `rust` \| `go` |
  | `test_command` | string | ✅        | —       | Shell snippet to run unit tests      |
  | `cache_key`    | string | ❌        | auto    | Extra salt for build cache           |

* **Jobs**

  1. *setup* — calls matching `actions/setup‑<lang>` composite.
  2. *deps‑cache* — uses built‑in cache action keyed on lockfile.
  3. *build+test* — executes `test_command`.
  4. *artifact* (matrix‑conditional) — uploads dist or wheels.

* **Success criteria** — job must exit 0; optional coverage gate is deferred to `_coverage.yml`.

### 4.2 `_lint.yml`

Runs language‑specific linters (eslint, ruff, cargo‑clippy). Accepts `linters` input list; maps to composite actions.

### 4.3 `_coverage.yml`

*Requires* the `coverage‑summary.json` created in `_build-test`. Uses `codecov/codecov‑action` or `shields‑io/coverage‑badge‑action`. Fails if coverage < `min_coverage` input.

### 4.4 `release.yml`

Dev‑infra’s own tag+publish pipeline; reuses `_build-test` with `lang=python` and deploys docs to GitHub Pages.

## 5 · Composite Actions (`actions/*/action.yml`)

Composite actions wrap repetitive three‑to‑five‑step sequences:

* **setup‑node** — mounts Node `cache: "npm"`, pins version from input, installs pnpm.
* **setup‑python** — uses `actions/setup‑python` + `pip cache`. Accepts array of `requirements` for virtualenv.
* **setup‑rust** — toolchain install, `cargo install cargo‑llvm‑cov`.
* **vitest / pytest / cargo‑fmt** — run and annotate results with the Problems matcher.

Each composite is completely self‑contained (no calls back into the repo) so it can be used independently if needed.

## 6 · Versioning & Release Management

* **Semantic tags:** `v1`, `v1.2.0`, `v2‑beta`
  *Consumer repos are *required* to pin to a major tag.*
* **CHANGELOG.md** updated with *Keep a Changelog* format.
* **Breaking‑change policy:** major‑version bump; migration notes in release drafter.
* **Release process:** create PR → merge to `main` → `release.yml` creates GitHub Release and moves `vX` tag.

## 7 · Consumer Integration Guide

1. **Dispatcher workflow** (`ci.yml`) in consuming repo:

   ```yaml
   name: CI
   on:
     pull_request:
     push:
       branches: [main]
   jobs:
     ci:
       uses: org/dev‑infra/.github/workflows/_build‑test.yml@v1
       with:
         lang: node
         test_command: npm run vitest -- --coverage
   ```
2. **Optional lint job** adds second `uses:` call.
3. **Hooks**:

   ```bash
   curl -sSL https://raw.githubusercontent.com/org/dev-infra/main/scripts/generate_dispatcher.sh | bash
   pre‑commit install
   ```

## 8 · Local Development & Testing of Dev‑Infra

| Task                                 | Tool                                                       |
| ------------------------------------ | ---------------------------------------------------------- |
| Validate YAML                        | `actionlint` + `yamllint` (pre‑commit)                     |
| Dry‑run workflows                    | `nektos/act` with custom runners                           |
| Unit tests for composite‑action bash | `bats`                                                     |
| Contract tests                       | Container‑based — run sample repo fixtures and assert logs |

CI for dev‑infra executes all reusable workflows against miniature sample projects in `fixtures/` (Hello‑World Node, Python, Rust).

## 9 · Security & Compliance

* All third‑party actions pinned to **commit SHA**; weekly Dependabot checks.
* OIDC tokens used instead of PAT wherever the workflow uploads artefacts.
* `permissions:` block set to least privilege (`id‑token: write`, `contents: read`).
* Secret scanning on push; any secret found blocks merge.

## 10 · Migration Path

| Phase                   | Action                                                                                 |
| ----------------------- | -------------------------------------------------------------------------------------- |
|  0 — Pilot              | Pick three canary repos (one per language), integrate dev‑infra v1.0, gather feedback. |
|  1 — Adopt              | Teams create dispatcher PRs in their repos following the integration guide.                             |
|  2 — Deprecate old YAML | Archive legacy `.github/workflows` after two green builds.                             |
|  3 — Deprecate husky    | Replace with pre‑commit; add Husky shim hook that warns contributors.                  |

## 11 · Future Enhancements

* **Matrix fan‑out**: automatically test on multiple Node minors / Python versions.
* **Cloud cache**: integrate GitHub Actions cache‑service or self‑hosted `actions/cache` backend.
* **SBOM & provenance**: add SLSA‑compliant provenance to build artefacts.
* **Performance**: explore switching heavy test suites to `gha‑large` runners or self‑hosted ARM.

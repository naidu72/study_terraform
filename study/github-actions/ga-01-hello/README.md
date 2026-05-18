# GA-01 — Your First Workflow

> **What we built:** Hello World workflow covering triggers, jobs, steps, and GitHub contexts
> **Workflow file:** [.github/workflows/ga-01-hello.yml](../../../.github/workflows/ga-01-hello.yml)

---

## Workflow File Location — The Golden Rule

GitHub Actions **only** scans `.github/workflows/*.yml` — not subdirectories.

```
.github/workflows/ga-01-hello.yml    ← GitHub picks this up  ✓
.github/workflows/learning/ga-01.yml ← GitHub ignores this   ✗
```

---

## YAML Structure — Every Level Explained

```yaml
name: GA-01 - Hello World          ← display name in GitHub Actions UI

on:                                 ← WHEN to run (triggers)
  workflow_dispatch:                ← manual run from GitHub UI
  push:                             ← run on git push
    branches:
      - 'learn/**'                  ← only on branches matching learn/*
    paths:
      - '.github/workflows/ga-01-hello.yml'  ← only when this file changes

jobs:                               ← WHAT to run
  hello:                            ← job name (your label)
    runs-on: ubuntu-latest          ← WHERE to run

    steps:                          ← list of commands in order
      - name: Say Hello             ← step display name
        run: echo "Hello!"          ← shell command to execute
```

---

## YAML Indentation — Critical Rule

GitHub Actions YAML uses **2 spaces per level**. Wrong indentation = workflow not found or silently broken.

```yaml
on:                    # level 0 — 0 spaces
  push:                # level 1 — 2 spaces
    paths:             # level 2 — 4 spaces
      - 'file'         # level 3 — 6 spaces

jobs:                  # level 0
  job_name:            # level 1 — 2 spaces
    runs-on: ...       # level 2 — 4 spaces
    steps:             # level 2 — 4 spaces
      - name: ...      # level 3 — 6 spaces
        run: ...       # level 4 — 8 spaces
```

---

## Triggers — `on:`

```yaml
on:
  workflow_dispatch:   # Run button in GitHub UI — only visible on default branch (main)
  push:                # fires on every git push
  pull_request:        # fires when PR is opened, updated, or synchronized
  schedule:
    - cron: '0 9 * * 1'  # fires every Monday at 9am UTC
```

### `paths:` filter — only trigger when specific files change

```yaml
on:
  push:
    paths:
      - 'inventory-manager/terraform/**'  # only when terraform files change
      - '.github/workflows/ga-01-hello.yml'
```

Without `paths:`, a README change triggers a Terraform plan — wasteful and noisy.

### `branches:` filter — only trigger on specific branches

```yaml
on:
  push:
    branches:
      - main           # only on pushes to main
      - 'learn/**'     # wildcard — any branch starting with learn/
```

### `workflow_dispatch` on non-default branches

The "Run workflow" button only appears for workflows that exist on the **default branch (main)**.
On feature branches, use the `push` trigger or GitHub CLI:

```bash
gh workflow run ga-01-hello.yml --ref learn/terraform-journey
```

---

## Jobs

```yaml
jobs:
  hello:              ← job name — used in needs: to reference this job
    runs-on: ubuntu-latest
    steps:
      - ...
```

- Multiple jobs run **in parallel** by default
- Use `needs:` to make jobs run sequentially (covered in GA-05)
- Each job gets a **fresh virtual machine** — no state shared between jobs

---

## Contexts — `${{ github.* }}`

GitHub provides built-in variables called **contexts**:

```yaml
${{ github.ref_name }}    # branch name: "learn/terraform-journey"
${{ github.sha }}         # full commit SHA: "abc123def456..."
${{ github.actor }}       # who triggered the run: "naidu72"
${{ github.event_name }}  # what triggered it: "push", "pull_request", "workflow_dispatch"
${{ github.repository }}  # "naidu72/terraform-study-terraform"
${{ github.run_id }}      # unique ID for this workflow run
```

These are read-only values injected by GitHub at runtime.

---

## `runs-on` — Where the Job Runs

```yaml
runs-on: ubuntu-latest        # GitHub-hosted runner — fresh VM, GitHub pays for it
runs-on: [self-hosted, pi5]   # your Pi self-hosted runner
```

| | GitHub-hosted | Self-hosted (Pi) |
|---|---|---|
| Machine | GitHub's cloud VM | Your Pi cluster |
| Cost | Free up to limits | Your electricity |
| Access to cluster | No — needs kubeconfig | Yes — direct access |
| Internet access | Yes | Yes (via your network) |
| Fresh per run | Always | Persistent |

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `.github/workflows/` | Only files directly here are picked up — no subdirectories |
| `on:` | Defines when the workflow triggers |
| `workflow_dispatch` | Manual run button — only on default branch |
| `paths:` | Only trigger when specific files change |
| `branches:` | Only trigger on specific branches |
| `jobs:` | Groups of steps that run on a runner |
| `runs-on:` | Which runner executes the job |
| `steps:` | Ordered list of commands within a job |
| `${{ github.* }}` | Built-in context variables from GitHub |
| YAML indentation | 2 spaces per level — must be exact |

---

## What's Next — GA-02: Runners

Deep dive into GitHub-hosted vs self-hosted runners, how your Pi runner works,
and when to use each.

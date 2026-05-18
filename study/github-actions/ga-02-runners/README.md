# GA-02 — Runners

> **What we built:** Two identical jobs running in parallel on different runners — comparing GitHub-hosted vs Pi self-hosted
> **Workflow file:** [.github/workflows/ga-02-runners.yml](../../../.github/workflows/ga-02-runners.yml)

---

## What is a Runner?

A runner is the machine that executes your workflow jobs.

```yaml
jobs:
  my-job:
    runs-on: ubuntu-latest       ← tells GitHub which runner to use
```

---

## Two Types of Runners

### GitHub-Hosted Runners

```yaml
runs-on: ubuntu-latest    # Linux (most common)
runs-on: windows-latest   # Windows
runs-on: macos-latest     # macOS
```

- Fresh virtual machine spun up for every job run
- Destroyed completely after the job finishes
- GitHub manages it — no setup needed
- Pre-installed tools: git, docker, node, python, terraform, etc.

**What we saw:**
```
Runner name: GitHub Actions 1000000138   ← random, different every run
Hostname:    runnervmrw5os               ← random VM name
User:        runner                      ← generic user
CPU:         4 cores
Memory:      15Gi
Disk:        90G free
```

### Self-Hosted Runners

```yaml
runs-on: [self-hosted, pi5]
```

- Your own machine running the GitHub Actions runner agent
- Persistent — same machine every run, tools stay installed
- You manage it — install whatever tools you need
- Can access private networks GitHub-hosted runners cannot reach

**What we saw:**
```
Runner name: pi5-runner      ← name you gave when registering
Hostname:    raspberrypi     ← your actual Pi machine
User:        naidu           ← your actual user
CPU:         4 cores         ← Raspberry Pi 5 Cortex-A76
Memory:      7.9Gi           ← Pi 5's 8GB RAM (0.1GB used by OS)
Disk:        64G free
```

---

## Runner Labels

Labels are how GitHub matches a job to the right runner.

```yaml
runs-on: [self-hosted, pi5]
#         ↑              ↑
#         built-in       custom label you set when registering
```

ALL labels must match — a runner with only `self-hosted` but not `pi5` won't pick up the job.

**Setting labels when registering a runner:**
```bash
./config.sh --url https://github.com/naidu72/repo --token TOKEN --labels pi5,arm64,homelab
```

---

## Parallel Jobs

Jobs run in parallel by default — no `needs:` = simultaneous:

```yaml
jobs:
  github-hosted:          ─┐
    runs-on: ubuntu-latest  ├── both start at the same time
  self-hosted:            ─┘
    runs-on: [self-hosted, pi5]
```

In the Actions UI you see two job cards running simultaneously.

---

## Why Your Inventory-Manager Uses Self-Hosted

Your infrastructure is on a private home network:

```
MinIO:            http://192.168.0.151:30900  ← private IP, not reachable from internet
Pi k3s cluster:   192.168.0.x                ← private network
Vault:            https://vault.naidu72.info  ← public (via Cloudflare)
```

```
GitHub-hosted runner:  external VM  →  CANNOT reach 192.168.0.x  ✗
Self-hosted Pi runner: on your LAN  →  CAN reach 192.168.0.x     ✓
```

This is why `runs-on: [self-hosted, pi5]` — not a preference, a requirement.

**Additional advantage — pre-installed tools:**
```
kubectl    → already installed and configured on Pi
terraform  → already installed
helm       → already installed
kubeconfig → already at ~/.kube/config pointing to your cluster
```

GitHub-hosted runner needs all of these injected every run via setup steps.
Self-hosted runner has them permanently — faster jobs, less setup code.

---

## `runner.*` Context

```yaml
${{ runner.os }}      # "Linux", "Windows", "macOS"
${{ runner.name }}    # "GitHub Actions 1000000138" or "pi5-runner"
${{ runner.arch }}    # "X64" or "ARM64"
${{ runner.temp }}    # temp directory path
```

---

## Comparison Table

| | GitHub-Hosted | Self-Hosted (Pi) |
|---|---|---|
| Machine | Random cloud VM | Your Pi |
| Lifecycle | Fresh per run, destroyed after | Persistent |
| Memory | 15Gi | 7.9Gi |
| Private network access | No | Yes |
| Pre-installed tools | Standard set | Whatever you install |
| Cost | Free up to limits | Your electricity |
| Maintenance | GitHub manages | You manage |
| Best for | Build, test, lint | Cluster deploy, private infra |

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `runs-on: ubuntu-latest` | GitHub-hosted — fresh VM, GitHub manages |
| `runs-on: [self-hosted, pi5]` | Your Pi — persistent, private network access |
| Labels | ALL labels must match for runner to pick up the job |
| Parallel jobs | No `needs:` = jobs run simultaneously |
| Private network | Main reason to use self-hosted — GitHub VMs can't reach your LAN |
| `runner.*` context | Built-in variables about the current runner |

---

## What's Next — GA-03: Contexts and Expressions

GitHub injects many built-in variables beyond `github.*` and `runner.*`.
Expressions let you use them in conditions, names, and values throughout your workflow.

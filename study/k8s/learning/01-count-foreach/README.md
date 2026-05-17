# Lesson 1b — count vs for_each

> **What we built:** Alpine pods on Pi cluster demonstrating count and for_each meta-arguments
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1
> **Backend:** MinIO remote state via NodePort `http://192.168.0.151:30900`

---

## Files Created

```
01-count-foreach/
├── provider.tf    → Kubernetes provider pointing to Pi cluster
├── backend.tf     → MinIO S3 remote state backend
├── variables.tf   → worker_count, list_pods, named_pods
├── main.tf        → 4 examples: count, count+list, for_each, conditional count
├── outputs.tf     → shows index vs key-based access difference
└── README.md      → this file
```

---

## Why This Lesson?

When you need multiple copies of a resource, Terraform gives you two tools:

```
count     → creates N identical copies, addressed by INDEX (0, 1, 2)
for_each  → creates one copy per map key, addressed by KEY ("web", "api")
```

The difference matters enormously when you add or remove items.

---

## Example 1 — `count` (simple number)

```hcl
resource "kubernetes_pod" "alpine_worker" {
  count = var.worker_count    ← creates pods[0], pods[1], pods[2]

  metadata {
    name = "alpine-worker-${count.index}"   ← count.index = 0, 1, 2
  }
}
```

```
worker_count = 3  →  alpine-worker-0, alpine-worker-1, alpine-worker-2
worker_count = 0  →  nothing created (count = 0 → conditional resource)
```

**Reference syntax:**
```hcl
kubernetes_pod.alpine_worker[0].metadata[0].name   ← specific index
kubernetes_pod.alpine_worker[*].metadata[0].name   ← all (splat) → returns list
```

---

## Example 2 — `count` over a List (the index-shifting problem)

```hcl
variable "list_pods" {
  default = ["web", "api", "batch"]
}

resource "kubernetes_pod" "alpine_list" {
  count = length(var.list_pods)

  metadata {
    name = "alpine-list-${count.index}"
    labels = {
      role = var.list_pods[count.index]
    }
  }
}
```

**Initial state:**
```
index 0 → "web"    pod: alpine-list-0
index 1 → "api"    pod: alpine-list-1
index 2 → "batch"  pod: alpine-list-2
```

**Remove "api" from the list → `["web", "batch"]`:**
```
index 0 → "web"    → no change      ✓
index 1 → "batch"  → REPLACE        ✗ (was "api", now "batch" — Terraform recreates)
index 2 → gone     → DESTROY        ✗

Result: 2 operations for removing 1 item!
```

Terraform only sees indexes — it doesn't know "api" was removed. It sees that index 1 changed from "api" config to "batch" config and recreates it.

---

## Example 3 — `for_each` over a Map (key-stable)

```hcl
variable "named_pods" {
  type = map(object({
    command     = list(string)
    environment = string
  }))
  default = {
    "web"   = { command = [...], environment = "frontend" }
    "api"   = { command = [...], environment = "backend" }
    "batch" = { command = [...], environment = "worker" }
  }
}

resource "kubernetes_pod" "alpine_named" {
  for_each = var.named_pods

  metadata {
    name = "alpine-${each.key}"         ← each.key = "web", "api", "batch"
    labels = {
      environment = each.value.environment
    }
  }

  spec {
    container {
      command = each.value.command      ← each pod runs a different command
    }
  }
}
```

**Remove "api" from the map:**
```
"web"   → no change   ✓
"api"   → DESTROY     ✓ (only "api" removed)
"batch" → no change   ✓

Result: 1 operation for removing 1 item ✓
```

Keys are stable — removing "api" never affects "web" or "batch".

**Reference syntax:**
```hcl
kubernetes_pod.alpine_named["web"].metadata[0].name    ← specific key
{ for k, pod in kubernetes_pod.alpine_named : k => pod.metadata[0].name }  ← all as map
```

---

## Example 4 — Conditional Resource with `count`

```hcl
resource "kubernetes_config_map" "demo_info" {
  count = var.worker_count > 0 ? 1 : 0   ← exists only when workers exist
  ...
}
```

```
worker_count = 3  →  count = 1  →  ConfigMap created
worker_count = 0  →  count = 0  →  ConfigMap destroyed
```

`count = 0 or 1` is the standard Terraform pattern for optional/conditional resources.
`for_each` cannot do this as cleanly.

---

## count vs for_each — Side by Side

| | `count` | `for_each` |
|---|---|---|
| Input | number or list | map or set |
| Identifier | `count.index` (0, 1, 2) | `each.key` ("web", "api") |
| Reference | `resource[0]` | `resource["web"]` |
| Remove middle item | Recreates everything after it | Only removes that item |
| Best for | Identical replicas, conditional (0 or 1) | Items with distinct identity |

---

## Outputs — Index vs Key

```hcl
# count → returns a LIST
output "count_pod_names" {
  value = kubernetes_pod.alpine_worker[*].metadata[0].name
  # ["alpine-worker-0", "alpine-worker-1", "alpine-worker-2"]
}

# for_each → returns a MAP
output "foreach_pod_names" {
  value = { for k, pod in kubernetes_pod.alpine_named : k => pod.metadata[0].name }
  # { "api" = "alpine-api", "batch" = "alpine-batch", "web" = "alpine-web" }
}
```

---

## Remote State — MinIO Backend

This lesson uses MinIO remote state. Credentials are passed via `-backend-config` flags:

```bash
terraform init \
  -backend-config="access_key=YOUR_KEY" \
  -backend-config="secret_key=YOUR_SECRET"
```

Why NodePort `http://192.168.0.151:30900` not Cloudflare URL:
Cloudflare Tunnel strips `Content-Length` header → SigV4 signature mismatch → AccessDenied.
NodePort bypasses Cloudflare → works correctly.

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `count` | Creates N identical copies — addressed by index |
| `count.index` | Current index (0, 1, 2) inside a count resource |
| `for_each` | Creates one copy per map key — addressed by key |
| `each.key` | Current key ("web", "api") inside a for_each resource |
| `each.value` | Current value object for the key |
| Index-shifting | count + list → removing middle item recreates all below it |
| Key-stable | for_each + map → removing a key only affects that key |
| `[*]` splat | Get all count resource values as a list |
| `count = 0 or 1` | Standard pattern for conditional/optional resources |
| Prefer for_each | When items have distinct identity — safer add/remove |

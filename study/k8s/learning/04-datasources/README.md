# Lesson 4 — Data Sources

> **What we built:** Read an existing `kube-system` namespace and copied its name as a label onto a new namespace
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
04-datasources/
├── providers.tf  → same as previous lessons (typed from memory)
├── main.tf       → data source reading kube-system + resource using it
├── outputs.tf    → exposes data source values to the terminal
└── README.md     → this file
```

---

## Why Data Sources?

So far every lesson has **created** resources. But what if you need to **read** something
that already exists — created before Terraform, or managed by another team?

```
resource  →  Terraform creates it, owns it, can destroy it
data      →  Terraform only reads it — never creates, never destroys
```

---

## Declaring a Data Source

```hcl
data "kubernetes_namespace_v1" "kube_system" {
  metadata {
    name = "kube-system"    ← the real name on the cluster
  }
}
```

**Format:**
```
data  "TYPE"                    "YOUR_LABEL"  {
       ↑ same types as resource   ↑ your name for it inside Terraform
}
```

Same type names as `resource` blocks — just the keyword changes from `resource` to `data`.

---

## Referencing a Data Source

```
resource  →  TYPE.LABEL.attribute
             kubernetes_namespace_v1.this.metadata[0].name

data      →  data.TYPE.LABEL.attribute
             data.kubernetes_namespace_v1.kube_system.metadata[0].name
             ↑ "data." prefix is the only difference
```

Used in `main.tf` to copy the kube-system name as a label:

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = "lesson4-namespace"
    labels = {
      copied_from = data.kubernetes_namespace_v1.kube_system.metadata[0].name
    }
  }
}
```

Result on the cluster:

```bash
kubectl get namespace lesson4-namespace --show-labels
# NAME                LABELS
# lesson4-namespace   copied_from=kube-system
```

---

## Outputs — Reading Data Source Values

```hcl
output "kube_system_labels" {
  value = data.kubernetes_namespace_v1.kube_system.metadata[0].labels
}

output "kube_system_uid" {
  value = data.kubernetes_namespace_v1.kube_system.metadata[0].resource_version
}
```

`terraform apply` or `terraform output` prints these to the terminal — useful for
inspecting what a data source found on the cluster.

---

## The Fundamental Rule — Ownership

```
resource  →  Terraform OWNS it
              terraform plan   → detects drift
              terraform apply  → creates / updates
              terraform destroy → DELETES it

data      →  Terraform only READS it
              terraform plan   → queries the cluster (read-only)
              terraform apply  → queries the cluster (read-only)
              terraform destroy → does NOTHING to it
```

`kube-system` existed before Terraform. After `terraform destroy`:
- `lesson4-namespace` → deleted (Terraform owns it)
- `kube-system` → untouched (Terraform only reads it)

---

## Real World Pattern

Data sources let you **cross team boundaries** safely:

```hcl
# Team A manages "shared-config" namespace — you cannot touch it
data "kubernetes_namespace_v1" "shared" {
  metadata { name = "shared-config" }
}

# Team B (you) — read their labels, apply to your namespace
resource "kubernetes_namespace_v1" "mine" {
  metadata {
    name   = "my-app"
    labels = data.kubernetes_namespace_v1.shared.metadata[0].labels
  }
}
```

You read their resource, use its values — zero ownership, zero risk of destroying it.

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `data` block | Read-only query against existing infrastructure |
| `data.TYPE.LABEL.attr` | Reference format — same as resource but with `data.` prefix |
| `terraform destroy` | Never touches data sources — only destroys `resource` blocks |
| Cross-team reads | Data sources safely read resources owned by others |
| `output` with data | Print data source values to terminal to inspect what was found |

---

## What's Next — Lesson 5: Lifecycle Rules

**Problem this solves:**
By default Terraform decides when to destroy and recreate resources.
But sometimes you need to control that — prevent accidental deletion, or
create the new resource before destroying the old one.

```hcl
lifecycle {
  prevent_destroy       = true   ← terraform destroy will ERROR, not delete
  create_before_destroy = true   ← new resource created first, then old one deleted
  ignore_changes        = [metadata[0].labels]  ← covered in Lesson 1
}
```

→ **Lesson 5 directory:** `study/k8s/learning/05-lifecycle/`

# Lesson 5 — Lifecycle Rules

> **What we built:** Namespaces demonstrating prevent_destroy and create_before_destroy
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
05-lifecycle/
├── provider.tf  → same as previous lessons (typed from memory)
├── main.tf      → resource with lifecycle rules
└── README.md    → this file
```

---

## Why Lifecycle Rules?

By default Terraform decides when and how to create, update, and destroy resources.
Lifecycle rules let you override that default behavior for specific resources.

---

## All 5 Lifecycle Arguments

```hcl
lifecycle {
  prevent_destroy       = true                      # block deletion
  create_before_destroy = true                      # zero downtime replacements
  ignore_changes        = [metadata[0].labels]      # ignore specific field drift
  replace_triggered_by  = [some_resource.other]     # chain replacements
  precondition {
    condition     = var.environment != "prod"
    error_message = "Do not deploy to prod with this config."
  }
}
```

---

## 1. `prevent_destroy`

Blocks `terraform destroy` with a hard error. No flag, no override — the only way
to delete the resource is to **remove the lifecycle block from the code first**.

```hcl
resource "kubernetes_namespace_v1" "protected" {
  metadata {
    name = "lesson5-protected"
  }

  lifecycle {
    prevent_destroy = true
  }
}
```

```bash
terraform destroy
# Error: Instance cannot be destroyed
#   on main.tf line 1:
#    1: resource "kubernetes_namespace_v1" "protected" {
```

**To actually destroy it — two steps required:**

```
Step 1:  Remove the lifecycle block from main.tf
Step 2:  terraform apply   (updates state, removes protection)
Step 3:  terraform destroy (now works)
```

This is intentional — forces a deliberate code change before anything critical can be deleted.

**Use for:** production databases, shared namespaces, anything that must never be accidentally deleted.

---

## 2. `create_before_destroy`

When Terraform needs to replace a resource (destroy + recreate), it normally:

```
Default:              DELETE old  →  CREATE new   ← gap where nothing exists
create_before_destroy: CREATE new  →  DELETE old   ← no gap, zero downtime
```

**When does Terraform need to replace a resource?**
When you change an **immutable field** — a field the provider cannot update in-place.
For Kubernetes namespaces, `name` is immutable. Changing it forces a replace.

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = "lesson5-blue"    ← change this to "lesson5-green"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

**What the plan shows:**
```
-/+  kubernetes_namespace_v1.this   (must be replaced)
```

`-/+` means destroy-then-recreate. With `create_before_destroy = true`, the actual
execution order becomes: create `lesson5-green` first → wait → destroy `lesson5-blue`.

**Verified on cluster:**
```
lesson5-green created   ← new namespace healthy
lesson5-blue destroyed  ← old namespace removed after
```

**Use for:** any resource where a gap in availability would cause downtime (load balancers,
DNS records, certificates, namespaces used by running workloads).

---

## 3. `ignore_changes` — recap from Lesson 1

Tell Terraform to permanently ignore a specific field, even if it drifts from the `.tf` file.

```hcl
lifecycle {
  ignore_changes = [metadata[0].labels]   # another tool manages labels
}
```

**Use for:** fields managed by another tool (ArgoCD, a controller, an ops team).

---

## 4. `replace_triggered_by`

Force this resource to be replaced when another resource changes.

```hcl
lifecycle {
  replace_triggered_by = [kubernetes_namespace_v1.other]
}
```

**Use for:** chaining replacements — when resource A changes, resource B must also be recreated.

---

## 5. `precondition` / `postcondition`

Validate conditions before or after a resource is created.

```hcl
lifecycle {
  precondition {
    condition     = var.environment != "prod"
    error_message = "Do not deploy to prod with this config."
  }
}
```

```
precondition  → checked BEFORE create/update — plan errors if condition is false
postcondition → checked AFTER create/update  — apply errors if condition is false
```

**Use for:** enforcing rules at apply time (environment guards, size limits, required tags).

---

## The Three You'll Use Daily

| Rule | When to use |
|---|---|
| `prevent_destroy` | Databases, prod resources — must never be accidentally deleted |
| `create_before_destroy` | Any resource where downtime during replacement is unacceptable |
| `ignore_changes` | Fields managed by another tool or team |

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `lifecycle` block | Overrides Terraform's default create/update/destroy behavior |
| `prevent_destroy` | Hard error on destroy — only removable by changing the code |
| `create_before_destroy` | New resource live before old one deleted — zero downtime |
| `ignore_changes` | Specific field drift permanently ignored |
| `-/+` in plan | Resource will be destroyed then recreated (immutable field changed) |
| Immutable field | A field the provider cannot update in-place — forces replace |

---

## What's Next — Lesson 6: Outputs

**Problem this solves:**
Resources create values you need elsewhere — a namespace name, an IP address, a generated ID.
Outputs expose those values so other modules or users can consume them.

```hcl
output "namespace_name" {
  value = kubernetes_namespace_v1.this.metadata[0].name
}
```

→ **Lesson 6 directory:** `study/k8s/learning/06-outputs/`

# Lesson 3 — Locals

> **What we built:** A Kubernetes namespace whose name and labels are computed from variables using locals
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
03-locals/
├── provider.tf   → same as Lessons 1 and 2 (typed from memory)
├── variables.tf  → input variables (team, environment, app)
├── local.tf      → computed values built from those variables
├── main.tf       → uses local.* references, no var.* directly
└── README.md     → this file
```

---

## Why Locals?

Variables solve the hardcoded value problem. But what about repeated logic?

Without locals — the same computation duplicated everywhere:

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = "${var.environment}-${var.team}-${var.app}"   ← duplicated
    labels = {
      team        = var.team
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}

resource "kubernetes_namespace_v1" "other" {
  metadata {
    name = "${var.environment}-${var.team}-${var.app}"   ← duplicated again
  }
}
```

With locals — compute once, reference everywhere:

```hcl
locals {
  namespace_name = "${var.environment}-${var.team}-${var.app}"   ← defined once
}

# use local.namespace_name in as many resources as needed
```

---

## Declaring Locals

```hcl
locals {
  name_prefix    = "${var.environment}-${var.team}"
  namespace_name = "${local.name_prefix}-${var.app}"
  common_labels = {
    team        = var.team
    environment = var.environment
    managed_by  = "terraform"    ← hardcoded string, not from any variable
  }
}
```

**Key points:**
- The block is called `locals` (plural) when declaring
- Referenced as `local.name` (singular) when using — no 's'
- A local can reference another local (`local.namespace_name` uses `local.name_prefix`)
- Terraform resolves them in the correct order automatically

---

## Referencing Locals

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata {
    name   = local.namespace_name    ← singular "local"
    labels = local.common_labels
  }
}
```

```
DECLARE with:  locals { }          ← plural
REFERENCE with: local.name         ← singular (easy to mix up)
```

---

## What the Plan Showed

With defaults (`team=platform`, `environment=dev`, `app=api`):

```
name   = "dev-platform-api"
labels = {
  environment = "dev"
  managed_by  = "terraform"
  team        = "platform"
}
```

With `-var="environment=prod"`:

```
name   = "prod-platform-api"    ← cascaded through local.name_prefix → local.namespace_name
```

---

## locals vs variables — The Critical Distinction

This is the most important concept in this lesson.

### Variables — overrideable from outside

```hcl
variable "env" { default = "dev" }
```

```bash
terraform plan -var="env=prod"     →  var.env = "prod"  ✓ works
terraform plan -var-file="prod.tfvars"  →  var.env = "prod"  ✓ works
```

### Locals with hardcoded values — fixed, cannot be overridden

```hcl
locals {
  env = "stage"    ← hardcoded, not reading from any variable
}
```

```bash
terraform plan -var="env=prod"     →  local.env = "stage"  still  ✗ no effect
```

No flag, no tfvars file, nothing can change a hardcoded local from outside.

### Locals that read from variables — follows the variable

```hcl
locals {
  env = var.env    ← reads from the variable
}
```

```bash
terraform plan -var="env=prod"     →  var.env = "prod"  →  local.env = "prod"  ✓ cascades
```

---

## Summary Table

| | `var.*` | `local.*` (hardcoded) | `local.*` (reads var) |
|---|---|---|---|
| Overrideable with `-var`? | Yes | No | Yes (via the variable) |
| Overrideable with `.tfvars`? | Yes | No | Yes (via the variable) |
| Can reference other locals? | No | Yes | Yes |
| Caller controls it? | Yes | No | No (caller controls the var, not the local) |

---

## When to Use Each

```
variable  →  value comes FROM OUTSIDE  (environment name, team name, replica count)
              caller decides the value

local     →  value computed INSIDE     (composed names, shared label maps, conditional logic)
              you decide the logic, caller cannot change it directly
```

**Good use cases for locals:**
- Building resource names from multiple variables (`"${var.env}-${var.team}-${var.app}"`)
- Shared label maps used across many resources (`common_labels`)
- Hardcoded values that should never be an input (`managed_by = "terraform"`)
- Conditional expressions that would be messy inline

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `locals { }` | Block to declare computed values — plural when declaring |
| `local.name` | Reference a local — singular when using |
| Hardcoded local | Fixed forever — no flag can change it from outside |
| Local reads var | Inherits the variable's overridability |
| Local references local | Allowed — Terraform resolves order automatically |
| DRY principle | Define once in locals, reference everywhere |

---

## What's Next — Lesson 4: Data Sources

**Problem this solves:**
So far we have only created resources. But what if something already exists on the cluster
and you just want to read its values without managing it?

```hcl
data "kubernetes_namespace_v1" "existing" {
  metadata {
    name = "kube-system"    ← already exists, Terraform didn't create it
  }
}

# now read its labels:
data.kubernetes_namespace_v1.existing.metadata[0].labels
```

Data sources let you query existing infrastructure and use those values in your resources.

→ **Lesson 4 directory:** `study/k8s/learning/04-data-sources/`

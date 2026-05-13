# Lesson 2 — Variables

> **What we built:** A Kubernetes namespace driven entirely by variables — no hardcoded values
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
02-variables/
├── provider.tf       → same as Lesson 1 (typed from memory)
├── variables.tf      → declares all input variables
├── main.tf           → uses var.* references instead of hardcoded values
├── terraform.tfvars  → auto-loaded default values
├── dev.tfvars        → dev environment overrides
├── staging.tfvars    → staging environment overrides
├── prod.tfvars        → prod environment overrides
└── README.md         → this file
```

---

## Why Variables?

Without variables, values are hardcoded in `main.tf`:

```hcl
name = "my-first-namespace"   ← hardcoded, have to edit the file for every change
```

With variables, the `.tf` file never changes — only the values change:

```hcl
name = var.namespace_name     ← reads from variable, controlled from outside
```

---

## Declaring a Variable

```hcl
variable "namespace_name" {
  description = "The name of the Kubernetes namespace to create"
  type        = string
  default     = "my-second-namespace"
}
```

**The 4 fields:**
| Field | Required | Purpose |
|---|---|---|
| `description` | No (but always write it) | Documents what this variable is for |
| `type` | No (but always write it) | Enforces the value type |
| `default` | No | Value used when nothing else is provided |
| `sensitive` | No | Hides value from plan/apply output |

**Reference a variable in your code:**
```hcl
var.namespace_name    ← always lowercase "var." prefix
```

---

## 4 Ways to Pass Variable Values — Priority Order

```
Priority (highest wins):
1. -var flag on the command line
2. -var-file flag pointing to a .tfvars file
3. terraform.tfvars (auto-loaded, no flag needed)
4. default = "..." in variables.tf
```

### Method 1 — `-var` flag

```bash
terraform plan -var="namespace_name=team-alpha"
```

Overrides everything. Good for one-off testing.

### Method 2 — `-var-file` flag

```bash
terraform plan -var-file="dev.tfvars"
terraform plan -var-file="prod.tfvars"
```

Points to a specific file. Used for **multi-environment workflows**.

### Method 3 — `terraform.tfvars` (auto-loaded)

```hcl
# terraform.tfvars
namespace_name = "my-tfvars-namespace"
```

Terraform picks this up automatically — no flag needed. Good for local defaults.

### Method 4 — `default` in `variables.tf`

```hcl
variable "namespace_name" {
  default = "my-second-namespace"
}
```

Used only when no other method provides a value.

---

## Multi-Environment Pattern with `.tfvars`

Same `.tf` files, different values per environment:

```hcl
# dev.tfvars
namespace_name = "app-dev"

# staging.tfvars
namespace_name = "app-staging"

# prod.tfvars
namespace_name = "app-prod"
```

```bash
terraform plan -var-file="dev.tfvars"      # deploys dev namespace
terraform plan -var-file="prod.tfvars"     # deploys prod namespace
```

The `.tf` files never change between environments — only the `.tfvars` file changes.

---

## Variable Types

### `string`

```hcl
variable "namespace_name" {
  type    = string
  default = "my-second-namespace"
}
```

Plain text. Most common type.

---

### `number`

```hcl
variable "replica_count" {
  type    = number
  default = 2
}
```

Integer or float. Used for counts, sizes, timeouts.

---

### `bool`

```hcl
variable "enable_labels" {
  type    = bool
  default = true
}
```

`true` or `false`. Used as an on/off switch.

**Using a bool with a ternary operator:**

```hcl
labels = var.enable_labels ? var.team_labels : {}
#                          ↑ if true          ↑ if false
```

```bash
terraform plan                          → labels added (enable_labels = true)
terraform plan -var="enable_labels=false"  → labels empty {}
```

---

### `map(string)`

```hcl
variable "team_labels" {
  type = map(string)
  default = {
    team        = "platform"
    environment = "dev"
  }
}
```

Key-value pairs where **all values must be the same type** (`string` in this case).
Access with: `var.team_labels["team"]` or `var.team_labels.team`

---

### `object`

```hcl
variable "namespace_config" {
  type = object({
    name        = string
    team        = string
    environment = string
    replicas    = number    ← different type to the strings above
  })
  default = {
    name        = "my-configured-namespace"
    team        = "platform"
    environment = "dev"
    replicas    = 1
  }
}
```

Structured config where **each field can be a different type**.
Access with: `var.namespace_config.name`, `var.namespace_config.replicas`

---

## `map` vs `object` — Key Difference

| | `map(string)` | `object({})` |
|---|---|---|
| Value types | All values same type | Each field can differ |
| Access style | `var.map["key"]` | `var.obj.field` |
| Use when | Simple key-value pairs (e.g. labels) | Grouped config with mixed types |

**Common mistake — putting a number where a string is expected:**

```hcl
# WRONG — replicas is a number (1), not a string
labels = {
  team = var.namespace_config.replicas   ← plan shows team = "1", not "platform"
}

# CORRECT
labels = {
  team = var.namespace_config.team       ← plan shows team = "platform"
}
```

Terraform allowed it because Kubernetes labels accept strings, and it coerced `1` → `"1"`.
But the value was wrong. Always double-check which field you're referencing.

---

## Key-Based Access vs Index-Based Access

Both `map` and `object` use **key-based access** — this is important:

```
list  →  index 0, 1, 2, 3
          delete middle item → everything below shifts index → resources recreated

map   →  key "web", "api", "batch"
          delete "api" → only "api" is affected → others untouched

object → field .name, .team, .environment
          remove one field → only that field affected → others untouched
```

This connects back to the **count vs for_each** lesson:
- `count` uses a list → index-shifting problem
- `for_each` uses a map → key-stable, safe to add/remove

Whenever you have a choice, prefer keys over indexes.

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `variable` block | Declares an input the caller can set |
| `var.name` | References a variable anywhere in `.tf` files |
| `-var` flag | Highest priority override, good for testing |
| `terraform.tfvars` | Auto-loaded, no flag needed |
| `-var-file` | Points to a named tfvars file, used for environments |
| `default` | Fallback when nothing else provides a value |
| `string` | Plain text |
| `number` | Integer or float |
| `bool` | true / false, used as on/off switch with ternary |
| `map(string)` | Key-value pairs, all values same type |
| `object({})` | Structured config, each field can differ in type |

---
```
variable "db_password" {
  type      = string
  sensitive = true    ← value hidden in plan/apply output, shown as (sensitive value)
}
```
## What's Next — Lesson 3: Locals

**Problem this solves:**
Variables are for values that come from outside (the caller).
But sometimes you need to compute a value from other variables — and that value is not an input, it's internal logic.

```hcl
locals {
  name_prefix = "${var.environment}-${var.team}"
  # now use local.name_prefix anywhere — computed once, reused everywhere
}
```

→ **Lesson 3 directory:** `study/k8s/learning/03-locals/`

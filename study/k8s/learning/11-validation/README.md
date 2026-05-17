# Mini-Lesson D — Variable Validation

> **What we built:** Variables with custom validation rules that error at plan time
> **Key insight:** Catch wrong values before anything touches the cluster

---

## Files Created

```
11-validation/
├── provider.tf    → same as previous lessons
├── variables.tf   → variables with validation blocks
└── README.md      → this file
```

---

## Why Validation?

Without validation, any value is accepted:

```bash
terraform plan -var="environment=qa"    ← silently accepted, may cause errors later
terraform plan -var="replica_count=100" ← silently accepted, expensive surprise
```

With validation, wrong values are caught immediately at `terraform plan`:

```bash
terraform plan -var="environment=qa"
# Error: Invalid value for variable
#   var.environment is "qa"
#   environment must be one of: dev, staging, prod.
```

---

## Validation Block Syntax

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}
```

**Rules:**
- `condition` must evaluate to `true` or `false`
- `error_message` must be a plain string — no variable references
- One variable can have **multiple** validation blocks — each checked independently
- First failure stops the plan with your error message

---

## Validation Examples

### Allowed values list

```hcl
validation {
  condition     = contains(["dev", "staging", "prod"], var.environment)
  error_message = "environment must be one of: dev, staging, prod."
}
```

```bash
terraform plan -var="environment=qa"
# Error: var.environment is "qa"
#        environment must be one of: dev, staging, prod.
```

---

### String length

```hcl
validation {
  condition     = length(var.namespace_name) >= 3 && length(var.namespace_name) <= 63
  error_message = "namespace_name must be between 3 and 63 characters."
}
```

```bash
terraform plan -var="namespace_name=ab"
# Error: var.namespace_name is "ab"
#        namespace_name must be between 3 and 63 characters.
```

---

### Regex pattern

```hcl
validation {
  condition     = can(regex("^[a-z0-9-]+$", var.namespace_name))
  error_message = "namespace_name must only contain lowercase letters, numbers, and hyphens."
}
```

```bash
terraform plan -var="namespace_name=UPPERCASE"
# Error: var.namespace_name is "UPPERCASE"
#        namespace_name must only contain lowercase letters, numbers, and hyphens.
```

**Why `can(regex(...))`?**

```
regex()  →  throws an error if pattern doesn't match
can()    →  catches any error and returns false instead
Together →  "does this string match the pattern?" → true or false
```

---

### Numeric range

```hcl
validation {
  condition     = var.replica_count >= 1 && var.replica_count <= 10
  error_message = "replica_count must be between 1 and 10."
}
```

```bash
terraform plan -var="replica_count=15"
# Error: var.replica_count is 15
#        replica_count must be between 1 and 10.
```

---

## Multiple Validation Blocks

One variable can have many validation blocks — each rule is checked independently:

```hcl
variable "namespace_name" {
  type = string

  validation {
    condition     = length(var.namespace_name) >= 3 && length(var.namespace_name) <= 63
    error_message = "namespace_name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.namespace_name))
    error_message = "namespace_name must only contain lowercase letters, numbers, and hyphens."
  }
}
```

First failing validation stops the plan — the rest are not evaluated.

---

## When Validation Runs

```
terraform plan   → validation runs BEFORE any cluster communication
terraform apply  → validation runs BEFORE any changes

Wrong value → error immediately, nothing touches the cluster
```

This is better than discovering the error after a partial apply.

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `validation` block | Custom rule inside a variable — errors at plan time |
| `condition` | Expression that must be true — false triggers error_message |
| `error_message` | Shown to user when condition is false — be specific |
| `contains()` | Check if value is in an allowed list |
| `length()` | Enforce min/max string or collection length |
| `can(regex())` | Check if string matches a pattern — regex errors become false |
| Multiple validations | Each block checked independently — first failure errors |

# Mini-Lesson C — Dynamic Blocks & For Expressions

> **What we built:** Namespaces from for_each, a ConfigMap from a for expression, and a Role with dynamic rule blocks
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
10-dynamic-blocks/
├── provider.tf    → same as previous lessons
├── variables.tf   → namespaces map + role_rules list
├── main.tf        → ConfigMap (for expression) + namespaces (for_each) + Role (dynamic block)
└── README.md      → this file
```

---

## Three Ways to Handle Repeated Config

```
1. for_each on resource  →  create multiple resources from a map/list
2. for expression        →  transform a collection into a map/list VALUE inline
3. dynamic block         →  generate multiple nested BLOCKS inside one resource
```

---

## 1. `for_each` on a Resource

Creates one resource per item in a map or set:

```hcl
resource "kubernetes_namespace_v1" "this" {
  for_each = var.namespaces    ← one namespace per map key

  metadata {
    name = each.key            ← "lesson10-app", "lesson10-monitoring", "lesson10-data"
    labels = {
      team        = each.value.team
      environment = each.value.environment
    }
  }
}
```

```
var.namespaces has 3 keys → terraform plan shows 3 namespaces to create
each.key   → map key ("lesson10-app")
each.value → map value object ({ team = "backend", environment = "dev" })
```

---

## 2. `for` Expression — Inline Collection Transformation

Transforms a collection into a new map or list directly in an attribute value:

```hcl
resource "kubernetes_config_map_v1" "namespace_registry" {
  metadata {
    name      = "namespace-registry"
    namespace = "default"
  }

  data = {
    for name, config in var.namespaces :
    name => "${config.team}/${config.environment}"
  }
}
```

Result in the ConfigMap:
```
"lesson10-app"        = "backend/dev"
"lesson10-data"       = "data/staging"
"lesson10-monitoring" = "platform/dev"
```

**For expression syntax:**
```hcl
{ for KEY, VALUE in COLLECTION : NEW_KEY => NEW_VALUE }
[ for VALUE in COLLECTION : NEW_VALUE ]
```

Used when the resource attribute **accepts a map or list directly** — no nested blocks needed.

---

## 3. Dynamic Block — Generating Nested Blocks

Used when a resource needs multiple **nested block sections** (not just map values).

**Without dynamic — copy-paste for every rule:**
```hcl
resource "kubernetes_role_v1" "this" {
  metadata { name = "lesson10-role", namespace = "lesson10-app" }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "update"]
  }
}
```

**With dynamic — driven from a variable:**
```hcl
resource "kubernetes_role_v1" "this" {
  metadata {
    name      = "lesson10-role"
    namespace = "lesson10-app"
  }

  dynamic "rule" {
    for_each = var.role_rules    ← iterates over the list
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }
}
```

Now adding a new rule = adding one item to `var.role_rules`. No `.tf` file changes needed.

---

## Dynamic Block — Key and Value

The iterator name matches the dynamic block label (`rule` in this case):

```
For a LIST:
  rule.key   → numeric index (0, 1, 2)
  rule.value → entire object from the list item

For a MAP:
  rule.key   → the map key string ("admin", "viewer")
  rule.value → the map value object
```

Accessing fields inside the object:
```hcl
rule.value.api_groups    ← drill into rule.value to get each field
rule.value.resources
rule.value.verbs
```

---

## Dynamic Block Syntax

```hcl
dynamic "BLOCK_NAME" {
  for_each = COLLECTION             ← list or map to iterate over
  iterator = CUSTOM_NAME            ← optional: rename from BLOCK_NAME to something else
  content {
    field = BLOCK_NAME.value.field  ← use BLOCK_NAME (or iterator name) to access values
  }
}
```

**With custom iterator name (useful when block name is long or unclear):**
```hcl
dynamic "rule" {
  for_each = var.role_rules
  iterator = r                      ← rename to "r" for brevity
  content {
    api_groups = r.value.api_groups
    resources  = r.value.resources
    verbs      = r.value.verbs
  }
}
```

---

## When to Use Each

| Pattern | Use when |
|---|---|
| `for_each` on resource | Creating multiple separate resources from a collection |
| `for` expression | Attribute accepts a map/list — transform inline |
| `dynamic` block | Resource has repeated nested block sections |

**Quick test — which to use?**
```
"I need 5 namespaces from a list"               → for_each on resource
"I need a ConfigMap data map from a variable"   → for expression in data = {}
"I need a Role with 5 rule{} blocks"            → dynamic block
```

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `for_each` on resource | Creates N resources from a map/set |
| `for` expression | Transforms collection inline — `{ for k, v in map : k => v }` |
| `dynamic` block | Generates repeated nested blocks from a list or map |
| `BLOCK.key` | Index (list) or key string (map) of current item |
| `BLOCK.value` | The current item's value — drill in with `.field` for objects |
| `iterator` | Optional rename of the block iterator variable |

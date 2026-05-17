# Mini-Lesson B — `depends_on`

> **Key insight:** Terraform detects dependencies automatically from references.
> `depends_on` is only needed when no reference exists but a dependency still does.

---

## How Terraform Detects Dependencies Automatically

When resource B references a value from resource A, Terraform knows A must be created first:

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata { name = "my-app" }
}

resource "kubernetes_config_map_v1" "this" {
  metadata {
    name      = "my-config"
    namespace = kubernetes_namespace_v1.this.metadata[0].name  ← reference = implicit dependency
  }
}
```

Terraform reads the reference and builds the correct order automatically:
`namespace → configmap`

---

## When Terraform CANNOT Detect the Dependency

When the value is hardcoded instead of referenced:

```hcl
resource "kubernetes_namespace_v1" "this" {
  metadata { name = "my-app" }
}

resource "kubernetes_config_map_v1" "this" {
  metadata {
    name      = "my-config"
    namespace = "my-app"    ← hardcoded string — Terraform sees no connection
  }
}
```

Terraform sees two independent resources. It may create the ConfigMap before the
namespace exists → error because the namespace doesn't exist yet.

---

## Fix — `depends_on`

```hcl
resource "kubernetes_config_map_v1" "this" {
  metadata {
    name      = "my-config"
    namespace = "my-app"
  }

  depends_on = [kubernetes_namespace_v1.this]    ← wait for namespace first
}
```

`depends_on` takes a list — you can depend on multiple resources:

```hcl
depends_on = [
  kubernetes_namespace_v1.this,
  kubernetes_config_map_v1.other,
]
```

---

## Other Real Scenarios for `depends_on`

```
1. Module dependency — wait for an entire module to finish, not just one resource:

   module "namespace" { ... }

   module "app" {
     depends_on = [module.namespace]   ← entire namespace module must complete first
   }

2. Data source that needs a resource to exist before querying:

   data "kubernetes_namespace_v1" "this" {
     metadata { name = "my-app" }
     depends_on = [kubernetes_namespace_v1.this]   ← ensure namespace exists before reading
   }

3. Script (null_resource) sets something up before another resource uses it
```

---

## Best Practice

```
PREFER this (reference):
  namespace = kubernetes_namespace_v1.this.metadata[0].name
  → Terraform detects dependency automatically
  → also passes the actual value

USE depends_on only when:
  → value is hardcoded and cannot be a reference
  → dependency is between modules, not individual resources
  → a data source needs a resource to exist before querying
```

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| Implicit dependency | Terraform detects from references automatically — preferred |
| `depends_on` | Explicit dependency when no reference exists |
| Hardcoded value | Breaks automatic detection — use `depends_on` to fix |
| Module dependency | `depends_on = [module.name]` — waits for entire module |
| List syntax | `depends_on = [resource.a, resource.b]` — can depend on multiple |

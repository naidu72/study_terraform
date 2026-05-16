# Lesson 6 — Outputs

> **What we built:** A namespace with outputs exposing its values, plus sensitive output and variable tests
> **Cluster:** Pi k3s (v1.35.3+k3s1)
> **Provider:** hashicorp/kubernetes ~> 3.1

---

## Files Created

```
06-outputs/
├── providers.tf  → same as previous lessons (typed from memory)
├── variables.tf  → includes a sensitive variable
├── main.tf       → namespace resource
├── outputs.tf    → multiple outputs including sensitive ones
└── README.md     → this file
```

---

## Why Outputs?

Resources create values you need elsewhere — a namespace name, a UID, an IP address.
Outputs expose those values so users, scripts, and other modules can consume them.

```hcl
output "namespace_name" {
  description = "The name of the namespace"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}
```

---

## Declaring an Output

```hcl
output "namespace_name" {
  description = "The name of the namespace"       ← documents what this is
  value       = kubernetes_namespace_v1.this.metadata[0].name  ← what to expose
  sensitive   = true                              ← optional: mask in terminal
}
```

---

## The 3 Output Commands

```bash
terraform output                   # all outputs, human-readable (name = value)
terraform output namespace_name    # single value only — no formatting
terraform output -json             # all outputs as JSON — for scripts and CI/CD
terraform output -raw namespace_name  # bare string, no quotes — for shell scripts
```

**Using in a shell script:**

```bash
NS=$(terraform output -raw namespace_name)
kubectl get pods -n $NS
```

---

## `sensitive = true` on Outputs

```hcl
output "fake_secret" {
  value     = "super-secret-token-123"
  sensitive = true
}
```

```bash
terraform output              → fake_secret = (sensitive value)    ← masked
terraform output fake_secret  → "super-secret-token-123"           ← REVEALED
terraform output -json        → "value": "super-secret-token-123"  ← REVEALED
```

`sensitive = true` only prevents accidental exposure in the summary view.
It is **not real security** — the value is still accessible with a direct query.

---

## `sensitive = true` on Variables — Cascades Automatically

```hcl
variable "secret_token" {
  type      = string
  sensitive = true
}
```

```bash
terraform plan -var="secret_token=my-super-secret"
# secret_token → (sensitive value)  ← masked in plan
```

**Cascading rule — any output derived from a sensitive variable is also sensitive:**

```hcl
output "token_length" {
  value = length(var.secret_token)
  # sensitive = true  ← REQUIRED, Terraform will error without it
}
```

```
Error: Output refers to sensitive values
  To reduce the risk of accidentally exporting sensitive data...
  annotate the output value as sensitive by adding: sensitive = true
```

Terraform forces you to explicitly acknowledge you are exposing data derived from a
sensitive source. You cannot accidentally leak it through an output.

---

## The Full Sensitivity Picture

| Where | `sensitive = true` behaviour |
|---|---|
| `terraform plan` | Value masked — shows `(sensitive value)` |
| `terraform apply` | Value masked — shows `(sensitive value)` |
| `terraform output` (all) | Value masked — shows `(sensitive value)` |
| `terraform output <name>` | **Value revealed** |
| `terraform output -json` | **Value revealed** |
| State file (`terraform.tfstate`) | **Stored in plaintext** |

**`sensitive = true` = masking, not encryption.**

---

## Real Secret Management in Terraform

```
WRONG  →  putting secrets in variables.tf defaults
WRONG  →  putting secrets in .tfvars files (committed to git)
WRONG  →  relying on sensitive = true as security

CORRECT:
  → Read secrets from Vault at apply time using a data source
  → Store secrets in Kubernetes Secrets, not Terraform state
  → Pass secrets via CI/CD environment variables: TF_VAR_secret_token=...
  → Never commit .tfvars files that contain real credentials to git
```

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `output` block | Exposes a resource value to users, scripts, or other modules |
| `terraform output` | Prints all outputs after apply |
| `terraform output -raw` | Bare string value — use in shell scripts |
| `terraform output -json` | Machine-readable format for CI/CD |
| `sensitive = true` on output | Masks in summary only — not real security |
| `sensitive = true` on variable | Cascades — any output using it must also be sensitive |
| State file | Always stores values in plaintext — protect access to it |

---

## What's Next — Lesson 7: Modules

**Problem this solves:**
Every lesson so far has been a flat directory of `.tf` files.
Modules let you package resources into reusable units — like functions in code.

```
Without modules:  copy-paste the same namespace + labels block in every project
With modules:     call module.namespace — one line, reusable everywhere
```

→ **Lesson 7 directory:** `study/k8s/learning/07-modules/`

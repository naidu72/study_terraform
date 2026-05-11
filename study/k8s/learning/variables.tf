# ── count demo (simple number) ────────────────────────────────────
variable "worker_count" {
  description = "Number of identical alpine worker pods (count demo)"
  type        = number
  default     = 3
}

# ── count demo (list — shows the INDEX SHIFTING problem) ──────────
#
# EXPERIMENT: remove "api" from this list, then run: terraform plan
# You will see:
#   alpine-list-0 (web)   → No changes       ✓
#   alpine-list-1 (api)   → destroy + replace ← was "api", now sees "batch"
#   alpine-list-2 (batch) → destroy           ← index 2 no longer exists
#
# Terraform does NOT know about names — it only sees indexes.
# Index 1 changed from "api" config to "batch" config → recreate.
# Index 2 is gone → destroy.
# Result: 2 destroys + 1 recreate, even though you only removed 1 item!
#
# COMPARE: do the same with named_pods (for_each) below.
# Only "api" is destroyed. web and batch are never touched.
variable "list_pods" {
  description = "Ordered list of pod roles (demonstrates count index-shifting problem)"
  type        = list(string)
  default     = ["web", "api", "batch"]
}

# ── for_each demo ─────────────────────────────────────────────────
# A map where each key becomes a pod with its own identity.
# Try removing "batch" and re-applying — only that pod is destroyed.
# With count that would have shifted indexes and recreated everything.
variable "named_pods" {
  description = "Map of pod name → config (for_each demo)"
  type = map(object({
    command     = list(string)
    environment = string
  }))
  default = {
    "web" = {
      command     = ["sh", "-c", "echo 'I am the web pod' && sleep 3600"]
      environment = "frontend"
    }
    "api" = {
      command     = ["sh", "-c", "echo 'I am the api pod' && sleep 3600"]
      environment = "backend"
    }
    "batch" = {
      command     = ["sh", "-c", "echo 'I am the batch pod' && sleep 3600"]
      environment = "worker"
    }
  }
}

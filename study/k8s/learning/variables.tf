# ── count demo ────────────────────────────────────────────────────
# How many identical alpine pods to spin up.
# Try changing this to 2 and re-applying — Terraform only adds/removes
# from the end. No existing pods are touched.
variable "worker_count" {
  description = "Number of identical alpine worker pods (count demo)"
  type        = number
  default     = 3
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

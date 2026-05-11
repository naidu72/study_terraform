# ── count outputs: use [*] splat or [index] ───────────────────────
output "count_pod_names" {
  description = "Names of all count-based worker pods"
  value       = kubernetes_pod.alpine_worker[*].metadata[0].name
  # Result: ["alpine-worker-0", "alpine-worker-1", "alpine-worker-2"]
  # Notice it's a LIST — order matters, addressed by index
}

output "count_pod_count" {
  description = "How many worker pods were created"
  value       = length(kubernetes_pod.alpine_worker)
}

# ── for_each outputs: use values() or specific key ─────────────────
output "foreach_pod_names" {
  description = "Names of all for_each pods"
  value       = { for k, pod in kubernetes_pod.alpine_named : k => pod.metadata[0].name }
  # Result: { "api" = "alpine-api", "batch" = "alpine-batch", "web" = "alpine-web" }
  # Notice it's a MAP — addressed by key, order doesn't matter
}

output "foreach_pod_environments" {
  description = "Environment label for each named pod"
  value       = { for k, pod in kubernetes_pod.alpine_named : k => pod.metadata[0].labels.environment }
}

# ── side-by-side comparison ───────────────────────────────────────
output "learning_summary" {
  description = "Key takeaway from this demo"
  value = {
    count_pods   = "Addressed by INDEX — alpine-worker-0, 1, 2 (risky to remove middle)"
    foreach_pods = "Addressed by KEY  — alpine-web, alpine-api, alpine-batch (safe to remove any)"
    tip          = "Prefer for_each when items have unique identities. Use count for identical replicas or on/off toggles."
  }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Learning: count vs for_each with Alpine pods
#
#  Run these commands to experiment:
#    terraform init
#    terraform plan
#    terraform apply
#    kubectl get pods -n terraform-learning
#
#  Then edit variables.tf and re-apply to see the difference.
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

resource "kubernetes_namespace" "learning" {
  metadata {
    name = "terraform-learning"
    labels = {
      managed-by = "terraform"
      purpose    = "learning-count-foreach"
    }
  }
}

# ── EXAMPLE 1: count ──────────────────────────────────────────────
#
# count = N creates N identical copies of the resource.
# Each copy is identified by its INDEX: pod[0], pod[1], pod[2]
#
# The KEY PROBLEM with count:
#   If you have pods ["a", "b", "c"] at index 0,1,2
#   and you remove "b" from the middle, Terraform sees:
#     index 0 → "a"  (unchanged)
#     index 1 → "c"  (was "b" — RECREATE)
#     index 2 → gone (was "c" — DESTROY)
#   It recreates more resources than needed.
#
# USE count WHEN: all instances are interchangeable (worker pools,
# identical replicas where the number is all that matters).
#
resource "kubernetes_pod" "alpine_worker" {
  count = var.worker_count # creates pods[0], pods[1], pods[2]

  metadata {
    name      = "alpine-worker-${count.index}" # count.index = 0, 1, 2, ...
    namespace = kubernetes_namespace.learning.metadata[0].name
    labels = {
      app     = "alpine-worker"
      index   = tostring(count.index)
      demo    = "count"
    }
  }

  spec {
    restart_policy = "Never"

    container {
      name    = "alpine"
      image   = "alpine:3.19"
      command = ["sh", "-c", "echo \"Worker ${count.index} started\" && sleep 3600"]

      resources {
        requests = { cpu = "10m", memory = "16Mi" }
        limits   = { cpu = "50m", memory = "32Mi" }
      }
    }
  }
}

# ── EXAMPLE 1b: count over a LIST (shows index-shifting danger) ───
#
# This uses var.list_pods = ["web", "api", "batch"]
# count = length(list) creates pods at index 0, 1, 2
#
# ┌─────────────────────────────────────────────────────────────────┐
# │  EXPERIMENT — Run this to feel the problem:                     │
# │                                                                 │
# │  Step 1: terraform apply   (creates web=0, api=1, batch=2)      │
# │  Step 2: In variables.tf, remove "api" from list_pods           │
# │          list_pods = ["web", "batch"]                           │
# │  Step 3: terraform plan                                         │
# │                                                                 │
# │  Expected (wrong) result you will see:                          │
# │    alpine-list-0 → no changes     (web at index 0, unchanged)   │
# │    alpine-list-1 → REPLACE        (index 1 was api, now batch)  │
# │    alpine-list-2 → DESTROY        (index 2 gone)                │
# │                                                                 │
# │  You removed 1 pod but Terraform does 2 operations!             │
# │  Now do the same with for_each (named_pods) and compare.        │
# └─────────────────────────────────────────────────────────────────┘
#
resource "kubernetes_pod" "alpine_list" {
  count = length(var.list_pods)

  metadata {
    name      = "alpine-list-${count.index}"
    namespace = kubernetes_namespace.learning.metadata[0].name
    labels = {
      app      = "alpine-list"
      role     = var.list_pods[count.index] # the value at this index
      index    = tostring(count.index)
      demo     = "count-list-problem"
    }
  }

  spec {
    restart_policy = "Never"

    container {
      name  = "alpine"
      image = "alpine:3.19"
      # prints which role this index currently holds
      command = ["sh", "-c", "echo \"Index ${count.index} = role: ${var.list_pods[count.index]}\" && sleep 3600"]

      resources {
        requests = { cpu = "10m", memory = "16Mi" }
        limits   = { cpu = "50m", memory = "32Mi" }
      }
    }
  }
}

# ── EXAMPLE 2: for_each ───────────────────────────────────────────
#
# for_each iterates over a map (or set of strings).
# Each resource is identified by its KEY: pod["web"], pod["api"]
#
# The KEY ADVANTAGE over count:
#   If you remove "batch" from the map, Terraform only destroys
#   the "batch" pod. The "web" and "api" pods are untouched.
#   Their keys ("web", "api") never change, so Terraform knows
#   exactly which real resource maps to which config.
#
# USE for_each WHEN: each instance has a distinct identity,
# different configuration, or you might add/remove specific items.
#
resource "kubernetes_pod" "alpine_named" {
  for_each = var.named_pods # keys: "web", "api", "batch"

  metadata {
    name      = "alpine-${each.key}" # each.key = "web", "api", "batch"
    namespace = kubernetes_namespace.learning.metadata[0].name
    labels = {
      app         = "alpine-named"
      pod-name    = each.key
      environment = each.value.environment # each.value = the object for this key
      demo        = "for_each"
    }
  }

  spec {
    restart_policy = "Never"

    container {
      name    = "alpine"
      image   = "alpine:3.19"
      command = each.value.command # each pod runs a different command

      env {
        name  = "POD_ROLE"
        value = each.key # "web", "api", or "batch"
      }

      env {
        name  = "ENVIRONMENT"
        value = each.value.environment
      }

      resources {
        requests = { cpu = "10m", memory = "16Mi" }
        limits   = { cpu = "50m", memory = "32Mi" }
      }
    }
  }
}

# ── EXAMPLE 3: count for conditional resource ─────────────────────
#
# count = 0 or 1 is the standard pattern to conditionally create
# a resource. for_each cannot do this as cleanly.
#
# Try: terraform apply -var="worker_count=0"
# All worker pods disappear. Set back to 3 to restore.
#
resource "kubernetes_config_map" "demo_info" {
  count = var.worker_count > 0 ? 1 : 0 # only create when workers exist

  metadata {
    name      = "demo-info"
    namespace = kubernetes_namespace.learning.metadata[0].name
  }

  data = {
    worker_count = tostring(var.worker_count)
    named_pods   = join(", ", keys(var.named_pods))
    description  = "This ConfigMap only exists when worker_count > 0"
  }
}

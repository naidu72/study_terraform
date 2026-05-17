# Mini-Lesson A — Functions

> **How we learned:** `terraform console` — interactive REPL, no resources needed
> **Key insight:** Functions transform values — used heavily in locals and modules

---

## Running Functions

```bash
terraform console    ← open interactive shell in any initialized directory
exit                 ← quit
```

Test any function instantly without writing or applying any `.tf` files.

---

## String Functions

```hcl
lower("PLATFORM")                           → "platform"
upper("platform")                           → "PLATFORM"
format("lesson-%s-%d", "test", 9)          → "lesson-test-9"
replace("my-namespace-dev", "-dev", "")    → "my-namespace"
trimspace("  hello  ")                      → "hello"
join("-", ["dev", "platform", "api"])       → "dev-platform-api"
split("-", "dev-platform-api")             → ["dev", "platform", "api"]
substr("lesson9-remote-state", 0, 7)       → "lesson9"
```

**Real use — building consistent resource names:**

```hcl
locals {
  name = format("%s-%s-%s", var.environment, var.team, var.app)
  # same as: "${var.environment}-${var.team}-${var.app}"
  # format() is better when you need padding or number formatting
}
```

---

## Collection Functions

```hcl
length(["a", "b", "c"])                    → 3
keys({team = "platform", env = "dev"})     → ["env", "team"]   ← sorted
values({team = "platform", env = "dev"})   → ["dev", "platform"] ← sorted by key
merge({a = "1"}, {b = "2"})               → {a = "1", b = "2"}
flatten([["a", "b"], ["c", "d"]])          → ["a", "b", "c", "d"]
contains(["dev", "staging", "prod"], "dev") → true
contains(["dev", "staging", "prod"], "qa") → false
```

### `toset` — removes duplicates and sorts

```hcl
toset(["a", "b", "a", "c"])   → ["a", "b", "c"]
```

Removes duplicates + sorts alphabetically.
Used to convert a list with duplicates into a unique set — required for `for_each`.

### `lookup` — safe map access with fallback

```hcl
lookup({team = "platform", env = "dev"}, "team", "unknown")   → "platform"
lookup({team = "platform", env = "dev"}, "owner", "unknown")  → "unknown"
```

Safer than `map["key"]` — returns the default instead of erroring when key is missing.

---

## Type Conversion Functions

```hcl
tostring(42)                        → "42"
tonumber("42")                      → 42
tolist(toset(["b", "a", "c"]))      → ["a", "b", "c"]   ← sorted
```

---

## Conditional Functions

### `coalesce` — first non-empty value wins

```hcl
coalesce("", "fallback")      → "fallback"   ← empty string skipped
coalesce("first", "fallback") → "first"      ← first non-empty wins
```

Use when a variable might be empty and you want a fallback:

```hcl
locals {
  team = coalesce(var.team, "platform")
  # var.team = ""        → "platform"
  # var.team = "backend" → "backend"
}
```

### `try` — fallback when ANY expression errors

```hcl
try({"a" = "1"}["b"], "default")      → "default"  ← expression errored
try({"a" = "1"}["a"], "default")      → "1"         ← expression worked
try(var.config.optional_field, "")    → ""           ← field doesn't exist
```

**`lookup` vs `try` — key difference:**

```
lookup(map, key, default)  →  only works with maps, fallback when KEY is missing
try(expression, default)   →  works with ANY expression, fallback when it ERRORS
```

`try()` is more powerful — catches any error, not just missing map keys:

```hcl
locals {
  owner = try(var.namespace_config.owner, "unknown")
  # safe even if "owner" field doesn't exist on the object
}
```

---

## Encoding Functions

```hcl
base64encode("hello-world")           → "aGVsbG8td29ybGQ="
base64decode("aGVsbG8td29ybGQ=")      → "hello-world"
yamlencode({name = "test", labels = {env = "dev"}})
# labels:
#   env: dev
# name: test
```

`yamlencode` is useful for generating Kubernetes manifests or ConfigMap values.

---

## Network Functions

```hcl
cidrsubnet("10.0.0.0/16", 8, 1)    → "10.0.1.0/24"
cidrhost("10.0.1.0/24", 5)         → "10.0.1.5"
```

Used heavily in networking modules — calculating subnet ranges and host IPs.

---

## Date Functions

```hcl
formatdate("YYYY-MM-DD", timestamp())   → "2026-05-16"
```

---

## Functions Used Most in Real Modules

| Function | When to use |
|---|---|
| `merge()` | Combine label maps — base labels + extra labels |
| `lookup()` | Safe map access with a fallback default |
| `try()` | Safe access to any expression that might error |
| `coalesce()` | First non-empty value from a list |
| `join()` | Build strings from list parts |
| `split()` | Parse strings into lists |
| `toset()` | Remove duplicates, required for `for_each` with lists |
| `flatten()` | Collapse nested lists into one flat list |
| `contains()` | Check if a value exists in a list |
| `format()` | Build formatted strings with type control |
| `length()` | Count items in a list, map, or string |

---

## Key Takeaways

| Concept | One line summary |
|---|---|
| `terraform console` | Interactive shell — test any function instantly |
| `lookup` vs `try` | lookup = safe map key access, try = safe any-expression access |
| `toset` | Removes duplicates and sorts — required before using a list with for_each |
| `merge` | Combines maps — second map wins on key conflicts |
| `coalesce` | Returns first non-empty value — useful for variable fallbacks |
| `flatten` | Collapses nested lists — useful when modules return lists of lists |

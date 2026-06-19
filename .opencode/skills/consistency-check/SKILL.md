---
name: consistency-check
description: "Scan all GDDs against the entity registry to detect cross-document inconsistencies: same entity with different stats, same item with different values, same formula with different variables. Grep-first approach â€?reads registry then targets only conflicting GDD sections rather than full document reads."
argument-hint: "[full | since-last-review | entity:<name> | item:<name>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

# Consistency Check

Detects cross-document inconsistencies by comparing all GDDs against the
entity registry (`design/registry/entities.yaml`). Uses a grep-first approach:
reads the registry once, then targets only the GDD sections that mention
registered names â€?no full document reads unless a conflict needs investigation.

**This skill is the write-time safety net.** It catches what `/design-system`'s
per-section checks may have missed and what `/review-all-gdds`'s holistic review
catches too late.

**When to run:**
- After writing each new GDD (before moving to the next system)
- Before `/review-all-gdds` (so that skill starts with a clean baseline)
- Before `/create-architecture` (inconsistencies poison downstream ADRs)
- On demand: `/consistency-check entity:[name]` to check one entity specifically

**Output:** Conflict report + optional registry corrections

---

## Phase 1: Parse Arguments and Load Registry

**Modes:**
- No argument / `full` â€?check all registered entries against all GDDs
- `since-last-review` â€?check only GDDs modified since the last review report
- `entity:<name>` â€?check one specific entity across all GDDs
- `item:<name>` â€?check one specific item across all GDDs

**Load the registry:**

```
Read path="design/registry/entities.yaml"
```

If the file does not exist or has no entries:
> "Entity registry is empty. Run `/design-system` to write GDDs â€?the registry
> is populated automatically after each GDD is completed. Nothing to check yet."

Stop and exit.

Build four lookup tables from the registry:
- **entity_map**: `{ name â†?{ source, attributes, referenced_by } }`
- **item_map**: `{ name â†?{ source, value_gold, weight, ... } }`
- **formula_map**: `{ name â†?{ source, variables, output_range } }`
- **constant_map**: `{ name â†?{ source, value, unit } }`

Count total registered entries. Report:
```
Registry loaded: [N] entities, [N] items, [N] formulas, [N] constants
Scope: [full | since-last-review | entity:name]
```

---

## Phase 2: Locate In-Scope GDDs

```
Glob pattern="game/design/gdd/*.md"
```

Exclude: `game-concept.md`, `systems-index.md`, `game-pillars.md` â€?these are
not system GDDs.

For `since-last-review` mode:
```bash
git log --name-only --pretty=format: -- game/design/gdd/ | grep "\.md$" | sort -u
```
Limit to GDDs modified since the most recent `game/design/gdd/gdd-cross-review-*.md`
file's creation date.

Report the in-scope GDD list before scanning.

---

## Phase 3: Grep-First Conflict Scan

For each registered entry, grep every in-scope GDD for the entry's name.
Do NOT do full reads â€?extract only the matching lines and their immediate
context (-C 3 lines).

This is the core optimization: instead of reading 10 GDDs Ã— 400 lines each
(4,000 lines), you grep 50 entity names Ã— 10 GDDs (50 targeted searches,
each returning ~10 lines on a hit).

### 3a: Entity Scan

For each entity in entity_map:

```
Grep pattern="[entity_name]" glob="game/design/gdd/*.md" output_mode="content" -C 3
```

For each GDD hit, extract the values mentioned near the entity name:
- any numeric attributes (counts, costs, durations, ranges, rates)
- any categorical attributes (types, tiers, categories)
- any derived values (totals, outputs, results)
- any other attributes registered in entity_map

Compare extracted values against the registry entry.

**Conflict detection:**
- Registry says `[entity_name].[attribute] = [value_A]`. GDD says `[entity_name] has [value_B]`. â†?**CONFLICT**
- Registry says `[item_name].[attribute] = [value_A]`. GDD says `[item_name] is [value_B]`. â†?**CONFLICT**
- GDD mentions `[entity_name]` but doesn't specify the attribute. â†?**NOTE** (no conflict, just unverifiable)

### 3b: Item Scan

For each item in item_map, grep all GDDs for the item name. Extract:
- sell price / value / gold value
- weight
- stack rules (stackable / non-stackable)
- category

Compare against registry entry values.

### 3c: Formula Scan

For each formula in formula_map, grep all GDDs for the formula name. Extract:
- variable names mentioned near the formula
- output range or cap values mentioned

Compare against registry entry:
- Different variable names â†?**CONFLICT**
- Output range stated differently â†?**CONFLICT**

### 3d: Constant Scan

For each constant in constant_map, grep all GDDs for the constant name. Extract:
- Any numeric value mentioned near the constant name

Compare against registry value:
- Different number â†?**CONFLICT**

---

## Phase 4: Deep Investigation (Conflicts Only)

For each conflict found in Phase 3, do a targeted full-section read of the
conflicting GDD to get precise context:

```
Read path="game/design/gdd/[conflicting_gdd].md"
```
(Or use Grep with wider context if the file is large)

Confirm the conflict with full context. Determine:
1. **Which GDD is correct?** Check the `source:` field in the registry â€?the
   source GDD is the authoritative owner. Any other GDD that contradicts it
   is the one that needs updating.
2. **Is the registry itself out of date?** If the source GDD was updated after
   the registry entry was written (check git log), the registry may be stale.
3. **Is this a genuine design change?** If the conflict represents an intentional
   design decision, the resolution is: update the source GDD, update the registry,
   then fix all other GDDs.

For each conflict, classify:
- **ðŸ”´ CONFLICT** â€?same named entity/item/formula/constant with different values
  in different GDDs. Must resolve before architecture begins.
- **âš ï¸ STALE REGISTRY** â€?source GDD value changed but registry not updated.
  Registry needs updating; other GDDs may be correct already.
- **â„¹ï¸ UNVERIFIABLE** â€?entity mentioned but no comparable attribute stated.
  Not a conflict; just noting the reference.

---

## Phase 5: Output Report

```
## Consistency Check Report
Date: [date]
Registry entries checked: [N entities, N items, N formulas, N constants]
GDDs scanned: [N] ([list names])

---

### Conflicts Found (must resolve before architecture)

ðŸ”´ [Entity/Item/Formula/Constant Name]
   Registry (source: [gdd]): [attribute] = [value]
   Conflict in [other_gdd].md: [attribute] = [different_value]
   â†?Resolution needed: [which doc to change and to what]

---

### Stale Registry Entries (registry behind the GDD)

âš ï¸ [Entry Name]
   Registry says: [value] (written [date])
   Source GDD now says: [new value]
   â†?Update registry entry to match source GDD, then check referenced_by docs.

---

### Unverifiable References (no conflict, informational)

â„¹ï¸ [gdd].md mentions [entity_name] but states no comparable attributes.
   No conflict detected. No action required.

---

### Clean Entries (no issues found)

âœ?[N] registry entries verified across all GDDs with no conflicts.

---

Verdict: PASS | CONFLICTS FOUND
```

**Verdict:**
- **PASS** â€?no conflicts. Registry and GDDs agree on all checked values.
- **CONFLICTS FOUND** â€?one or more conflicts detected. List resolution steps.

---

## Phase 6: Registry Corrections

If stale registry entries were found, ask:
> "May I update `design/registry/entities.yaml` to fix the [N] stale entries?"

For each stale entry:
- Update the `value` / attribute field
- Set `revised:` to today's date
- Add a YAML comment with the old value: `# was: [old_value] before [date]`

If new entries were found in GDDs that are not in the registry, ask:
> "Found [N] entities/items mentioned in GDDs that aren't in the registry yet.
> May I add them to `design/registry/entities.yaml`?"

Only add entries that appear in more than one GDD (true cross-system facts).

**Never delete registry entries.** Set `status: deprecated` if an entry is removed
from all GDDs.

After writing: Verdict: **COMPLETE** â€?consistency check finished.
If conflicts remain unresolved: Verdict: **BLOCKED** â€?[N] conflicts need manual resolution before architecture begins.

### 6b: Append to Reflexion Log

If any ðŸ”´ CONFLICT entries were found (regardless of whether they were resolved),
append an entry to `docs/consistency-failures.md` for each conflict:

```markdown
### [YYYY-MM-DD] â€?/consistency-check â€?ðŸ”´ CONFLICT
**Domain**: [system domain(s) involved]
**Documents involved**: [source GDD] vs [conflicting GDD]
**What happened**: [specific conflict â€?entity name, attribute, differing values]
**Resolution**: [how it was fixed, or "Unresolved â€?manual action needed"]
**Pattern**: [generalised lesson, e.g. "Item values defined in combat GDD were not
referenced in economy GDD before authoring â€?always check entities.yaml first"]
```

Only append if `docs/consistency-failures.md` exists. If the file is missing,
skip this step silently â€?do not create the file from this skill.

---

## Next Steps

- **If PASS**: Run `/review-all-gdds` for holistic design-theory review, or
  `/create-architecture` if all MVP GDDs are complete.
- **If CONFLICTS FOUND**: Fix the flagged GDDs, then re-run
  `/consistency-check` to confirm resolution.
- **If STALE REGISTRY**: Update the registry (Phase 6), then re-run to verify.
- Run `/consistency-check` after writing each new GDD to catch issues early,
  not at architecture time.

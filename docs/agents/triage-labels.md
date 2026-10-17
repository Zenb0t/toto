# Triage Labels

The skills speak in terms of canonical roles. This file maps them to the label strings used in this repo.
Every label below exists on the repo. A new one must be created before an issue can use it: the GitHub MCP tools
refuse unknown labels (in a cloud session, create it with `gh api`, see `docs/agents/issue-tracker.md`). Use the
colours below.

## Triage (from the `triage` skill)

Every triaged issue carries exactly one category and one state.

| Role | Label in our tracker | Colour | Meaning |
| --- | --- | --- | --- |
| category | `bug` | `d73a4a` | Something is broken |
| category | `enhancement` | `a2eeef` | New feature or improvement |
| state | `needs-triage` | `fbca04` | Maintainer needs to evaluate this issue |
| state | `needs-info` | `d876e3` | Waiting on reporter for more information |
| state | `ready-for-agent` | `0e8a16` | Fully specified, ready for an AFK agent |
| state | `ready-for-human` | `1d76db` | Requires human implementation |
| state | `wontfix` | `ffffff` | Will not be actioned |

## Epics (from the `wayfinder` skill)

An epic is a wayfinder map. Maps and their decision tickets carry only `wayfinder:` labels, never triage
labels: they hold decisions, not build work. Build tickets made afterwards by `/to-tickets` get triage labels.

| Label | Colour | Meaning |
| --- | --- | --- |
| `wayfinder:map` | `5319e7` | An epic: the map of decisions for one big piece of work |
| `wayfinder:grilling` | `c5def5` | Decision made in conversation with the maintainer |
| `wayfinder:research` | `c5def5` | Fact-finding an agent can do alone |
| `wayfinder:prototype` | `c5def5` | A rough playable or visual mock to react to |
| `wayfinder:task` | `c5def5` | Work that must happen before a decision can be made |

## Ideas

| Label | Colour | Meaning |
| --- | --- | --- |
| `idea` | `bfdadc` | Brainstorm, not committed. Triage skips it until it's promoted to `enhancement` (+ `needs-triage`) |

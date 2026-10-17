# Issue tracker: GitHub

Issues, specs and wayfinder maps for this repo live as GitHub issues in `zenb0t/toto`.

**Which tool.** On a computer with the `gh` CLI, use `gh` as below. In a Claude Code cloud session, use the GitHub
MCP tools (`mcp__github__issue_write` to create or edit, `issue_read`, `list_issues` / `search_issues`,
`add_issue_comment`, `sub_issue_write`). The conventions are the same either way.

**Cloud workaround: `gh api`.** The MCP tools can't create labels, and refuse an issue whose labels don't exist yet.
The cloud container does have `gh`: `gh auth status` reports an invalid token, but `gh api` calls still work
because the session's proxy adds the credentials. Use it for what the MCP tools can't do:

```sh
gh api --method POST repos/zenb0t/toto/labels -f name="ready-for-agent" -f color="0e8a16" -f description="..."
gh api --method POST repos/zenb0t/toto/issues/<number>/labels -f 'labels[]=ready-for-agent'
```

Colours and descriptions are in `docs/agents/triage-labels.md`.

Every issue or comment written by an agent ends with the Claude Code attribution footer; triage comments also
start with the triage disclaimer (see the `triage` skill).

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..." --label "..."`. Use a heredoc for multi-line
  bodies. People filing by hand use the issue forms (Bug, Feature), which apply the category and `needs-triage`.
- **Read an issue**: `gh issue view <number> --json number,title,body,labels,comments`.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with `--label` and `--state` filters.
- **Make an issue a sub-issue of a parent**: `gh issue create --parent <parent> ...`, or
  `gh issue edit <parent> --add-sub-issue <child>` (`gh` 2.94+). MCP: `sub_issue_write` with method `add`.
  Without sub-issues, put `Part of #<parent>` at the top of the child body.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage`
reads this flag.)_

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read it as in **Read an issue** above.

## Wayfinding operations

Used by `/wayfinder`. An **epic** in this repo is a wayfinder map. The **map** is a single issue with **child**
issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Destination / Notes / Decisions-so-far /
  Not-yet-specified / Out-of-scope body.
- **Child ticket**: a sub-issue of the map (see **Make an issue a sub-issue of a parent**). Labels:
  `wayfinder:<type>` (`research` / `prototype` / `grilling` / `task`). Once claimed, the ticket is assigned to
  the driving dev.
- **Blocking**: GitHub's native issue dependencies where the tool can set them:
  `gh api --method POST repos/zenb0t/toto/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`
  (`<blocker-db-id>` is the numeric database id: `gh api repos/zenb0t/toto/issues/<n> --jq .id`). When the
  tool can't (the cloud session's MCP tools), put a `Blocked by: #<n>, #<n>` line at the top of the child body.
  A ticket is unblocked when every blocker is closed.
- **Frontier query**: the map's open sub-issues, minus any with an open blocker or an assignee; first in map
  order wins.
- **Claim**: assign the ticket to yourself, as the session's first write.
- **Resolve**: comment the answer, close the ticket, then append a context pointer (name + link + one-line gist)
  to the map's Decisions-so-far.

When a map reaches its destination, its spec is published with `/to-spec` (as a sub-issue of the map) and split
into build tickets with `/to-tickets`.

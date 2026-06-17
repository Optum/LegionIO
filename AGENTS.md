# LegionIO — Agent Notes

`legionio` is the **primary gem** of the LegionIO framework: it orchestrates all `legion-*` gems and
loads `lex-*` extensions. It's an async job engine, an AI coding assistant, an MCP server, and a
cognitive platform in one. See `CLAUDE.md` for the full boot sequence, module map, and conventions;
`README.md` for the user-facing tour.

## Fast Start

```bash
bundle install
bundle exec rspec       # ~3500+ examples — 0 failures required before commit
bundle exec rubocop     # 0 offenses required
```

Run **both** in full and fix everything before committing. No exceptions — the PR CI gate is green
and must stay green.

## Primary Entry Points

- `lib/legion.rb` — `Legion.start`, `.shutdown`, `.reload`
- `lib/legion/service.rb` — the 15-phase startup orchestrator (logging → settings → crypt →
  transport → cache → data → rbac → llm → apollo → gaia → telemetry → supervision → extensions →
  cluster secret → api)
- `lib/legion/cli.rb` + `lib/legion/cli/` — Thor CLI across the two binaries (`legion`, `legionio`)
- `lib/legion/cli/chat/` — the interactive AI REPL
- `lib/legion/api.rb` + `lib/legion/api/` — Sinatra REST API (port 4567) + middleware
- `lib/legion/extensions/` — LEX discovery/loading/actors/builders
- `lib/legion/tools/` — canonical tool layer (Registry, Discovery, EmbeddingCache)
- `exe/legion`, `exe/legionio` — the binaries; perf opts applied before any code loads

## Guardrails / Gotchas (these prevent real bugs)

- **`Legion::JSON` only** — `Legion::JSON.load` returns **symbol keys**; `.dump` takes exactly one
  positional arg (wrap kwargs in `{}`). Inside the `Legion::` namespace, **`::JSON` and `::Process`
  must be explicit** (they resolve to `Legion::JSON` / `Legion::Process` otherwise).
- **Thor 1.5+ reserves `run`** — use `map 'run' => :trigger` in the Task subcommand.
- **Sinatra 4** — `set :host_authorization, permitted: :any`. API response shape is
  `{ data:, meta: { timestamp:, node: } }`; errors `{ error: { code:, message: }, meta: }`.
- **LLM routes are owned by `legion-llm`** and mounted from it — do not re-add in-app LLM routes or a
  provider gateway fallback (that migration is intentional).
- **Bootsnap is opt-in** (`LEGION_BOOTSNAP=true`), not always-on.
- **Never swallow exceptions** — every `rescue` re-raises or `handle_exception`s; use `log.*`, never
  `puts`. **No personal/company identifiers in VCS**; never force-push.
- Extensions declare `data_required?` / `cache_required?` / `crypt_required?` / `vault_required?` /
  `llm_required?` and are skipped when the dependency is absent — keep that contract intact.
- `LEGION_MODE=lite` must keep working end-to-end (in-process transport + in-memory cache, no
  RabbitMQ/Redis).

## Validation

Run targeted specs for the area you touched, then full `rspec` + `rubocop` before handoff. Specs use
`rack-test`; the suite runs without external infrastructure.

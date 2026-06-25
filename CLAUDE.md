# LegionIO

Primary gem. Orchestrates all `legion-*` gems and loads LEX extensions.

**GitHub**: https://github.com/LegionIO/LegionIO
**Gem**: `legionio` | **Ruby**: >= 3.4

## Binary Split

| Binary | Purpose |
|--------|---------|
| `legion` | Interactive TTY shell + dev-workflow (chat, commit, review, plan, memory) |
| `legionio` | Daemon lifecycle + operational commands (start, stop, lex, task, config, mcp) |

## Boot Sequence

Executables enable YJIT + GC tuning (600k heap slots). Bootsnap is **opt-in** —
set `LEGION_BOOTSNAP=true` (it is no longer applied unconditionally).

```
Legion.start → Legion::Service.new
  1.  setup_logging
  2.  setup_settings
  3.  Legion::Crypt.start
  4.  setup_transport (RabbitMQ)
  5.  require legion-cache
  6.  setup_data (optional)
  7.  setup_rbac (optional)
  8.  setup_llm (optional)
  9.  setup_apollo (optional)
  10. setup_gaia (optional)
  11. setup_telemetry (optional)
  12. setup_supervision
  13. load_extensions (multi-phase: phase 0 identity, phase 1 everything else, parallel)
  14. Legion::Crypt.cs (distribute cluster secret)
  15. setup_api (Sinatra/Puma on port 4567)
```

Extension loading: phase 0 = `lex-identity-*` (sequential), phase 1 = everything else on `Concurrent::FixedThreadPool(24)`. After all phases: catalog transitions + registry writes.

## Extension Discovery

`find_extensions` discovers `lex-*` gems via Bundler or `Gem::Specification`. Category registry determines load phase and tier. Extensions declare requirements via `data_required?`, `cache_required?`, `crypt_required?`, `vault_required?`, `llm_required?` — skipped if dependency unavailable.

Role profiles filter extensions: `nil` (all), `:core` (14), `:cognitive` (core + agentic), `:service` (core + integrations), `:dev` (core + AI + essential agentic), `:custom` (explicit list).

## CLI Design Rules

- Thor 1.5+ reserves `run` — use `map 'run' => :trigger` in Task subcommand
- `::Process` must be explicit (resolves to `Legion::Process` otherwise)
- `::JSON` must be explicit (resolves to `Legion::JSON` otherwise)
- All commands support `--json` and `--no-color` at class_option level
- `Connection` module has class-level `ensure_*` methods, not instance-based

## API Design

- `Legion::API < Sinatra::Base` with `set :host_authorization, permitted: :any`
- Response: `{ data: ..., meta: { timestamp:, node: } }`
- Error: `{ error: { code:, message: }, meta: ... }`
- `Legion::JSON.dump` — 1 positional arg, wrap kwargs in `{}`
- `Legion::JSON.load` — returns symbol keys

## Module Structure (Key Parts)

```
Legion
├── Service        # Lifecycle orchestrator
├── Process        # PID, signals, daemonization
├── Readiness      # Component readiness tracking
├── Events         # In-process pub/sub (on/emit/once/off, wildcard *)
├── Ingress        # Universal runner entry point (normalize + run)
├── Extensions     # Discovery, loading, actors, builders, helpers
│   ├── Core       # Mixin: requirement flags, autobuild
│   ├── Actors/    # Every, Loop, Once, Poll, Subscription, Nothing
│   └── Builders/  # Actors, Runners, Helpers, Hooks, Routes
├── Tools          # Registry (always/deferred), Discovery, EmbeddingCache
├── API            # Sinatra routes, middleware (Auth, Tenant, RateLimit, BodyLimit)
├── DigitalWorker  # AI-as-labor: Lifecycle, Registry, RiskTier, ValueMetrics
├── CLI            # Thor commands (40+ subcommands)
│   └── Chat       # Interactive AI REPL (sessions, tools, memory, agents, skills)
└── Graph          # Task relationship visualization (Mermaid/DOT)
```

## Where Things Live (most-touched)

| Path | Purpose |
|------|---------|
| `lib/legion.rb` | Entry: `Legion.start`, `.shutdown`, `.reload` |
| `lib/legion/service.rb` | 15-phase startup orchestrator |
| `lib/legion/cli.rb` + `lib/legion/cli/` | Thor CLI — two binaries, 40+ subcommands |
| `lib/legion/cli/chat/` | Interactive AI REPL (sessions, tools, agents, memory, skills) |
| `lib/legion/api.rb` + `lib/legion/api/` | Sinatra REST API + middleware (Auth, Tenant, RateLimit, BodyLimit) |
| `lib/legion/extensions/` | LEX discovery, loading, actors, builders |
| `lib/legion/tools/` | Canonical tool layer (Registry, Discovery, EmbeddingCache) |
| `lib/legion/digital_worker/` | AI-as-labor governance (Lifecycle, RiskTier, ValueMetrics) |
| `exe/legion`, `exe/legionio` | The two binaries; perf opts (YJIT/GC, opt-in bootsnap) applied here |
| `spec/` | RSpec suite (~3500+ examples) |

LLM HTTP routes are **owned by `legion-llm`** and mounted from it — LegionIO no longer
defines its own LLM routes or a provider gateway fallback.

## Lite Mode

`LEGION_MODE=lite` — `InProcess` transport adapter + `Memory` cache adapter. No RabbitMQ/Redis needed.

## Development

```bash
bundle exec rspec       # ~3500+ examples
bundle exec rubocop     # 0 offenses
```

Always run both before committing. Specs use `rack-test`. `Legion::JSON.load` returns symbol keys.

## Rubocop

`.rubocop.yml` excludes `spec/**/*` from `Metrics/BlockLength`. `chat_command.rb` excluded from most Metrics cops. Hash alignment: `table` style.

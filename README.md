<h1 align="center">LegionIO</h1>

<p align="center">
  <b>One Ruby gem that is a distributed async job engine, an AI coding assistant, an MCP server,
  and a cognitive-computing platform — and runs with zero required infrastructure.</b>
</p>

<p align="center">
  <a href="https://rubygems.org/gems/legionio"><img alt="Gem Version" src="https://img.shields.io/gem/v/legionio.svg"></a>
  <img alt="Ruby" src="https://img.shields.io/badge/ruby-%3E%3D%203.4-CC342D.svg">
  <img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-blue.svg">
  <img alt="HA" src="https://img.shields.io/badge/HA-no%20paid%20tiers%20·%20no%20feature%20gates-success.svg">
</p>

```
         ╭──────────────────────────────────────╮
         │           L E G I O N I O            │
         │                                      │
         │   async jobs  ·  AI chat  ·  MCP     │
         │   REST API  ·  HA  ·  cognitive AI   │
         │   zero-infra lite mode  ·  Vault     │
         ╰──────────────────────────────────────╯
```

> Schedule tasks, chain services into dependency graphs, run them concurrently across a RabbitMQ
> fleet, and orchestrate AI-powered workflows — from a single `legion` command. Then run the whole
> thing with **no RabbitMQ, no Redis, nothing** via lite mode.

## Why LegionIO

- 🧩 **Four products in one gem.** A RabbitMQ-backed async **job engine**, an **AI coding assistant** (chat, commit, review, PR, multi-agent), an **MCP server** that exposes your infrastructure to any agent, and a brain-modeled **cognitive platform** — all in one `gem install`.
- 🪶 **Zero-infrastructure lite mode.** `LEGION_MODE=lite` swaps RabbitMQ for in-process pub/sub and Redis/Memcached for an in-memory cache. Every feature still works — `gem install` to a running daemon in seconds, no services to stand up.
- 🔗 **Dependency-graph orchestration.** Chain tasks with JSON conditions and ERB transformations, fan out in parallel, and scale by simply launching more processes — RabbitMQ distributes the work automatically (tested to 100+ workers).
- 🤖 **AI workflows built in.** `legion chat`, `commit`, `review`, `pr`, multi-agent `swarm`, persistent cross-session memory, and a shared knowledge store — powered by [legion-llm](https://github.com/LegionIO/legion-llm)'s any-client → any-provider routing.
- 🧠 **Cognitive architecture.** 240+ brain-modeled extensions across 18 domains (emotion, reasoning, social, metacognition…), coordinated by a tick-cycle scheduler ([legion-gaia](https://github.com/LegionIO/legion-gaia)).
- 🔌 **MCP-native.** Exposes itself as an MCP server (stdio or streamable HTTP), so Claude Desktop or any agent SDK can run tasks, manage extensions, and query your infrastructure directly.
- 🛡️ **Operational from day one.** Vault secrets, AES-256 message encryption, RBAC, JWT / API-key auth, sliding-window rate limiting, Prometheus metrics, an OpenAPI 3.1 spec, and live `SIGHUP` reload. **No paid tiers, no feature gates, full HA out of the box.**

## The Legion Ecosystem

LegionIO is the orchestrator; the heavy lifting lives in a family of focused, independently-versioned gems. Here's the one-line version — follow a link to dig in:

| Gem | What it is |
|-----|-----------|
| [legion-llm](https://github.com/LegionIO/legion-llm) | Universal LLM proxy — any client dialect → any provider, with routing, escalation, and metering |
| [legion-gaia](https://github.com/LegionIO/legion-gaia) | Cognitive coordination layer — tick-cycle scheduler + weighted routing across cognitive modules |
| [legion-apollo](https://github.com/LegionIO/legion-apollo) | Shared + local knowledge store — RAG retrieval, embeddings, and a knowledge graph |
| [legion-data](https://github.com/LegionIO/legion-data) | Persistence — task history, scheduling, and chains over SQLite / PostgreSQL / MySQL |
| [legion-transport](https://github.com/LegionIO/legion-transport) | Messaging abstraction — RabbitMQ AMQP plus the in-process lite adapter |
| [legion-cache](https://github.com/LegionIO/legion-cache) | Caching abstraction — Redis / Memcached plus the in-memory lite adapter |
| [legion-crypt](https://github.com/LegionIO/legion-crypt) | Secrets & encryption — Vault integration, AES-256, JWT auth |
| [legion-rbac](https://github.com/LegionIO/legion-rbac) | Role-based access control with Vault-style flat policies |
| [legion-mcp](https://github.com/LegionIO/legion-mcp) | Model Context Protocol server/client implementation |
| [legion-settings](https://github.com/LegionIO/legion-settings) | Layered configuration + secret resolution (`vault://`, `env://`) |
| [legion-logging](https://github.com/LegionIO/legion-logging) | Structured logging used across every gem |
| [legion-tty](https://github.com/LegionIO/legion-tty) | Terminal UI components — spinners, tables, prompts |

Capabilities (`lex-*` extensions) are a separate, much larger catalog — see [Extensions](#extensions) below.

## What Does It Do?

LegionIO routes work between services asynchronously. Tasks chain into dependency graphs with conditions and transformations controlling data flow:

```
Task A ──→ [condition] ──→ Task B ──→ [transform] ──→ Task C
                                  └──→ Task D  (parallel)
                                  └──→ Task E ──→ Task F
```

When A completes, B runs. B triggers C, D, and E in parallel. Conditions gate execution. Transformations reshape payloads between steps. Add more workers by running more processes — RabbitMQ handles distribution automatically.

But that's just the foundation. LegionIO is also:

- **An AI coding assistant** — interactive chat with tools, code review, commit messages, PR generation, and multi-agent workflows
- **An MCP server** — 60 tools that let any AI agent run tasks, manage extensions, and query your infrastructure
- **A cognitive computing platform** — 242 brain-modeled extensions across 18 cognitive domains
- **A digital worker platform** — AI-as-labor with governance, risk tiers, and cost tracking

## Quick Start

```bash
gem install legionio
legionio check            # verify subsystem connections
legionio start            # start the daemon
```

For the AI features:

```bash
legion                    # launch the interactive TTY shell
legion chat               # interactive AI REPL with 40 built-in tools
legion commit             # AI-generated commit message from staged changes
legion review             # AI code review of your code
```

### Two Binaries

| Binary | Purpose |
|--------|---------|
| `legion` | Interactive TTY shell + dev-workflow commands (`chat`, `commit`, `review`, `plan`, `memory`, `init`) |
| `legionio` | Daemon lifecycle + all operational commands (`start`, `stop`, `lex`, `task`, `config`, `mcp`, and 40+ more) |

`legion` with no args drops into the interactive TTY shell. `legionio` is the full operational CLI.

## Installation

```bash
gem install legionio
```

Or add to your Gemfile:

```ruby
gem 'legionio'
```

### Optional Capabilities

| Gem | What It Unlocks |
|-----|-----------------|
| `legion-data` | Task history, scheduling, chains (SQLite/PostgreSQL/MySQL) |
| `legion-llm` | AI chat, commit, review, agents, multi-provider LLM routing |
| `legion-cache` | Redis/Memcached caching for extensions |
| `legion-crypt` | Vault integration, encryption, JWT auth |
| `legion-tty` | TTY UI components (spinners, tables, prompts) |

## Zero-Infrastructure Mode (Lite)

Run LegionIO without RabbitMQ, Redis, or Memcached:

```bash
LEGION_MODE=lite legion start     # environment variable
legion start --lite               # CLI flag
```

In lite mode, `legion-transport` uses an in-process pub/sub adapter (no RabbitMQ required) and `legion-cache` uses a pure in-memory store with TTL (no Redis/Memcached required). All extensions and features work normally. Useful for single-machine development, CI, and trying LegionIO with no infrastructure.

## Natural Language Intent Router

```bash
legion do "list all running tasks"
legion do "start the email extension"
```

`legion do` routes free-text to the Capability Registry. Routes through the running daemon (MCP Tier 0 fast path) when available, or runs in-process otherwise.

## Infrastructure

| Component | Role | Required? |
|-----------|------|-----------|
| **RabbitMQ** | Task distribution (AMQP 0.9.1) | No (lite mode replaces with InProcess adapter) |
| **SQLite/PostgreSQL/MySQL** | Persistence (tasks, scheduling, chains) | Optional |
| **Redis/Memcached** | Extension caching | No (lite mode replaces with Memory adapter) |
| **HashiCorp Vault** | Secrets, PKI, encrypted settings | Optional |

## The CLI

Operational commands run through `legionio`. Dev-workflow and AI commands run through `legion`.

### Daemon & Health

```bash
legionio start                    # foreground
legionio start -d                 # daemonize
legionio start --http-port 8080   # custom API port
legionio status                   # service status
legionio stop                     # graceful shutdown
legionio check                    # smoke-test all connections
legionio check --extensions       # also verify extensions
legionio check --full             # full boot including API
```

### Extensions (LEX)

Extensions are gems named `lex-*`, auto-discovered at startup:

```bash
legion lex list                 # installed extensions
legion lex info <name>          # runners, actors, dependencies
legion lex create <name>        # scaffold a new extension
legion lex enable <name>        # enable / disable
```

### Tasks

```bash
legion task run http.request.get url:https://example.com   # dot notation
legion task run -e http -r request -f get                   # explicit flags
legion task run                                             # interactive picker
legion task list                                            # recent tasks
legion task show <id>                                       # detail + logs
```

### AI Chat

An interactive AI coding assistant with project awareness, persistent memory, tool use, and multi-agent coordination. Requires `legion-llm`.

```bash
legion chat                             # interactive REPL
legion chat prompt "explain main.rb"    # single-prompt mode
echo "fix the bug" | legion chat prompt - # pipe from stdin
```

**40 built-in tools**: read_file, write_file, edit_file, search_files, search_content, run_command, save_memory, search_memory, web_search, spawn_agent, search_traces, query_knowledge, ingest_knowledge, consolidate_memory, relate_knowledge, knowledge_maintenance, knowledge_stats, summarize_traces, list_extensions, manage_tasks, system_status, view_events, cost_summary, reflect, manage_schedules, worker_status, detect_anomalies, view_trends, trigger_dream, generate_insights, budget_status, provider_health, model_comparison, shadow_eval_status, entity_extract, arbitrage_status, escalation_status, graph_explore, scheduling_status, memory_status

**Slash commands**: `/help` `/quit` `/cost` `/status` `/clear` `/new` `/save` `/load` `/sessions` `/compact` `/fetch URL` `/search QUERY` `/diff` `/copy` `/rewind` `/memory` `/agent` `/agents` `/plan` `/swarm` `/review` `/permissions` `/personality` `/model` `/edit` `/commit` `/workers` `/dream`

**Bang commands**: `!ls -la` — run shell commands with output injected into context

**At-mentions**: `@reviewer check main.rb` — delegate to custom agents in `.legion/agents/`

### AI Workflows

```bash
legion commit                       # AI-generated commit message
legion pr                           # AI-generated PR title + description
legion pr --base develop --draft    # target branch, draft mode
legion review                       # AI code review of staged changes
legion review src/main.rb           # review specific files
legion review --diff                # review uncommitted diff
```

### Multi-Agent Orchestration

```bash
legion plan                         # read-only exploration mode (AI reasons, no writes)
legion swarm start deploy-pipeline  # run multi-agent workflow
legion swarm list                   # available workflows
```

### Memory

Persistent project and global memory that survives across sessions:

```bash
legion memory list                  # project memories
legion memory add "always use rspec"
legion memory search "testing"
legion memory forget 3
```

### Knowledge

Query and manage the Apollo shared knowledge store and local knowledge index:

```bash
legion knowledge query "how does transport routing work?"
legion knowledge retrieve "embedding cosine similarity" --scope global
legion knowledge ingest /path/to/docs/
legion knowledge status             # index stats, embedding coverage
legion knowledge health             # detect orphans, quality metrics
legion knowledge maintain           # cleanup orphans, reindex
legion knowledge quality            # quality report
```

### Mind Growth

Autonomous cognitive architecture expansion system. Analyzes gaps, proposes new cognitive extensions, and builds them via a staged pipeline:

```bash
legion mind-growth status           # current growth cycle state
legion mind-growth analyze          # gap analysis against 5 reference models
legion mind-growth propose          # propose a new concept
legion mind-growth evaluate <id>    # evaluate a proposal
legion mind-growth build <id>       # run staged build pipeline
legion mind-growth list             # list proposals
legion mind-growth approve <id>     # manually approve
legion mind-growth reject <id>      # manually reject
legion mind-growth profile          # cognitive profile across all models
legion mind-growth health           # extension fitness validation
```

Requires `lex-mind-growth`. Also exposes 6 MCP tools in the `legion.mind_growth_*` namespace.

### Digital Workers

AI-as-labor with governance, risk tiers, and cost tracking:

```bash
legion worker list                  # list workers
legion worker show <id>             # worker detail
legion worker create <name>         # register new worker (bootstrap state)
legion worker pause <id>            # pause / activate / retire
legion worker costs --days 30       # cost report
```

### Code Generation

Run inside a `lex-*` directory:

```bash
legion generate runner <name>       # add runner + spec
legion generate actor <name>        # add actor + spec
legion g exchange <name>            # 'g' is an alias
```

### Scheduling

Requires `lex-scheduler`:

```bash
legion schedule add alerts "*/5 * * * *" http.request.get
legion schedule add daily "every day at noon" report.generate.summary
legion schedule list
```

### Configuration

```bash
legion config show              # resolved config (redacted)
legion config validate          # verify settings + subsystem health
legion config scaffold          # generate starter config files (auto-detects env vars)
```

`config scaffold` auto-detects environment variables (`ANTHROPIC_API_KEY`, `AWS_BEARER_TOKEN_BEDROCK`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `VAULT_TOKEN`, `RABBITMQ_USER`/`PASSWORD`) and a running Ollama instance, enabling providers and setting `env://` references automatically.

Settings load from the first directory found: `/etc/legionio/` → `~/.legionio/settings/` → `~/legionio/` → `./settings/`

### Observability

```bash
legion dashboard               # TUI operational dashboard with auto-refresh
legion cost summary             # cost overview (today/week/month)
legion cost worker <id>         # per-worker cost breakdown
legion trace search "failed tasks last hour"  # natural language trace search
legion graph show --format mermaid            # task relationship graph
```

### Audit & RBAC

```bash
legion audit list               # query audit log
legion audit export --format csv
legion rbac roles               # list roles
legion rbac check <identity> <resource> <action>
```

### Diagnostics

```bash
legion doctor                   # diagnose environment, suggest fixes
legion doctor --fix             # auto-remediate fixable issues (stale PIDs, missing gems)
legion doctor --json            # machine-readable output
```

Checks Ruby version, bundle status, config files, RabbitMQ, database, cache, Vault, extensions, PID files, and permissions. Exits 1 if any check fails.

### Updating

```bash
legion update                   # update all legion gems in-place
legion update --dry-run         # check what's available without installing
```

Uses the same Ruby that `legion` is running from — safe for Homebrew installs (updates go into the bundled gem directory, not your system Ruby).

All commands support `--json` for structured output and `--no-color` to strip ANSI codes.

## REST API

The daemon exposes a REST API on port 4567 (configurable):

| Route | Description |
|-------|-------------|
| `GET /api/health` | Health check |
| `GET /api/ready` | Readiness + component status |
| `GET/POST /api/tasks` | List / create tasks |
| `GET /api/extensions` | Installed extensions + runners |
| `GET /api/nodes` | Cluster nodes |
| `GET/POST/PUT/DELETE /api/schedules` | Cron / interval scheduling |
| `GET /api/settings` | Config (sensitive values redacted) |
| `GET /api/transport` | RabbitMQ connection status |
| `GET /api/events` | SSE event stream |
| `GET/POST/PUT/DELETE /api/workers` | Digital worker lifecycle |
| `GET /api/capacity` | Workforce capacity and forecasting |
| `GET /api/tenants` | Multi-tenant management |
| `GET /api/audit` | Audit log query and export |
| `GET /api/rbac/*` | Role-based access control |
| `GET /api/webhooks` | Webhook subscription management |
| `GET /api/openapi.json` | OpenAPI 3.1.0 specification |
| `GET /metrics` | Prometheus metrics |
| `POST /api/coldstart/ingest` | Context ingestion |

```json
{
  "data": { "..." },
  "meta": { "timestamp": "2026-03-15T12:00:00Z", "node": "legion-01" }
}
```

## MCP Server

LegionIO exposes itself as an [MCP](https://modelcontextprotocol.io/) server, letting any AI agent run tasks, manage extensions, and query infrastructure directly.

```bash
legion mcp                # stdio transport (Claude Desktop, agent SDKs)
legion mcp http           # streamable HTTP on localhost:9393
legion mcp http --port 8080 --host 0.0.0.0
```

**60 tools** in the `legion.*` namespace:

| Category | Tools |
|----------|-------|
| **Agentic** | `run_task`, `describe_runner` |
| **Tasks** | `list_tasks`, `get_task`, `delete_task`, `get_task_logs` |
| **Extensions** | `list_extensions`, `get_extension`, `enable_extension`, `disable_extension` |
| **Chains** | `list_chains`, `create_chain`, `update_chain`, `delete_chain` |
| **Relationships** | `list_relationships`, `create_relationship`, `update_relationship`, `delete_relationship` |
| **Schedules** | `list_schedules`, `create_schedule`, `update_schedule`, `delete_schedule` |
| **System** | `get_status`, `get_config` |
| **Workers** | `list_workers`, `show_worker`, `worker_lifecycle`, `worker_costs`, `team_summary` |
| **RBAC** | `rbac_assignments`, `rbac_check`, `rbac_grants` |
| **Analytics** | `routing_stats` |
| **Knowledge** | `query_knowledge`, `knowledge_health` |
| **Mind Growth** | `mind_growth_status`, `mind_growth_analyze`, `mind_growth_propose`, `mind_growth_evaluate`, `mind_growth_build`, `mind_growth_profile` |

**Resources**: `legion://runners` (full runner catalog), `legion://extensions/{name}` (extension detail)

## Task Relationships

### Conditions

JSON rule engine via `lex-conditioner`. Supports nested `all`/`any` with operators:

```json
{
  "all": [
    {"fact": "pet.type", "value": "dog", "operator": "equal"},
    {"fact": "pet.hungry", "operator": "is_true"}
  ]
}
```

### Transformations

ERB templates via `lex-transformer`. Map data between services:

```json
{"message": "Incident assigned to <%= assignee %> with priority <%= severity %>"}
```

Access Vault secrets inline: `<%= Legion::Crypt.read('pushover/token') %>`

## Extensions

Browse: [LegionIO GitHub](https://github.com/LegionIO) | [legionio topic](https://github.com/topics/legionio?l=ruby)

### Core (14 operational extensions)

`lex-node` `lex-tasker` `lex-conditioner` `lex-transformer` `lex-scheduler` `lex-health` `lex-log` `lex-ping` `lex-exec` `lex-lex` `lex-codegen` `lex-metering` `lex-telemetry` `lex-task_pruner`

### Agentic (242 cognitive extensions)

Brain-modeled cognitive architecture. 20 core orchestration extensions plus 222 expanded modules across 18 domains:

| Domain | Examples |
|--------|----------|
| **Orchestration** | `lex-tick`, `lex-cortex`, `lex-dream`, `lex-memory`, `lex-identity` |
| **Emotion** | `lex-emotion`, `lex-mood`, `lex-empathy` |
| **Reasoning** | `lex-prediction`, `lex-planning`, `lex-logic` |
| **Social** | `lex-trust`, `lex-consent`, `lex-governance` |
| **Metacognition** | `lex-reflection`, `lex-awareness`, `lex-curiosity` |

Coordinated by [legion-gaia](https://github.com/LegionIO/legion-gaia), the cognitive coordination layer with tick-cycle scheduling, channel abstraction, and weighted routing across cognitive modules.

### AI / LLM

`legion-llm` `lex-llm` `lex-llm-anthropic` `lex-llm-azure-foundry` `lex-llm-bedrock` `lex-llm-gemini` `lex-llm-ledger` `lex-llm-mlx` `lex-llm-ollama` `lex-llm-openai` `lex-llm-vertex` `lex-llm-vllm`

Powered by [legion-llm](https://github.com/LegionIO/legion-llm) with provider-neutral model offerings, local and fleet routing, hosted cloud providers, health tracking, metering, and automatic model discovery.

LLM API routes are mounted from `legion-llm` when available; LegionIO only hosts those route modules and does not provide a provider gateway fallback.

### Service Integrations (8 common + 15 additional)

**Common**: `lex-http` `lex-redis` `lex-s3` `lex-github` `lex-consul` `lex-tfe` `lex-vault` `lex-kerberos` `lex-microsoft_teams`

**Additional**: `lex-ssh` `lex-slack` `lex-smtp` `lex-influxdb` `lex-pagerduty` `lex-elasticsearch` `lex-chef` `lex-pushover` `lex-twilio` `lex-todoist` `lex-pushbullet` `lex-sleepiq` `lex-elastic_app_search` `lex-memcached` `lex-sonos`

### Build Your Own

```bash
legion lex create myextension
cd lex-myextension
legion generate runner myrunner
legion generate actor myactor
bundle exec rspec
```

## Role Profiles

Control which extensions load at startup via `settings/legion.json`:

```json
{"role": {"profile": "dev"}}
```

| Profile | What loads |
|---------|-----------|
| *(default)* | Everything — no filtering |
| `core` | 14 core operational extensions only |
| `cognitive` | core + all agentic extensions |
| `service` | core + service + other integrations |
| `dev` | core + native LLM providers + essential agentic (~20 extensions) |
| `custom` | only what's listed in `role.extensions` |

Faster boot and lower memory footprint for dedicated worker roles.

## Scaling

Task distribution uses RabbitMQ FIFO queues. Add workers by running more Legion processes — each subscribes to the same queues and picks up work automatically. Tested to 100+ workers.

Run different LEX combinations per worker: 10 pods focused on `lex-ssh`, a separate pod for `lex-pagerduty` + `lex-log` notifications.

No paid tiers. No feature gates. Full HA out of the box.

## Security

- **Message encryption**: AES-256-CBC via `legion-crypt`
- **Vault integration**: Secrets, PKI, encrypted settings
- **Node identity**: Each worker generates a keypair for inter-node communication
- **Cluster secret**: Generated at first startup, distributed via Vault or in-memory
- **JWT auth**: Bearer token authentication on the REST API
- **API key support**: `X-API-Key` header authentication
- **RBAC**: Role-based access control with Vault-style flat policies
- **Rate limiting**: Sliding-window per-IP/agent/tenant rate limiting
- **API versioning**: `/api/v1/` prefix with deprecation headers
- **Kerberos**: SPNEGO/GSSAPI authentication with LDAP group resolution

## Docker

```bash
docker pull legionio/legion
```

```dockerfile
FROM ruby:3-alpine
RUN gem install legionio
CMD ruby --yjit $(which legion) start
```

## Architecture

Before any Legion code loads, the executable applies performance optimizations:

- **YJIT** — `RubyVM::YJIT.enable` for 15-30% runtime throughput (Ruby 3.1+ builds)
- **GC tuning** — pre-allocates 600k heap slots and raises malloc limits (ENV overrides respected)
- **bootsnap** *(opt-in)* — set `LEGION_BOOTSNAP=true` to cache YARV bytecode and `$LOAD_PATH` resolution at `~/.legionio/cache/bootsnap/`

```
legion start
  └── Legion::Service
      ├── 1.  Logging          (legion-logging)
      ├── 2.  Settings         (legion-settings — /etc/legionio, ~/legionio, ./settings)
      ├── 3.  Crypt            (legion-crypt — Vault connection)
      ├── 4.  Transport        (legion-transport — RabbitMQ)
      ├── 5.  Cache            (legion-cache — Redis/Memcached)
      ├── 6.  Data             (legion-data — database + migrations)
      ├── 7.  RBAC             (legion-rbac — optional role-based access control)
      ├── 8.  LLM              (legion-llm — AI provider setup + routing)
      ├── 9.  Apollo           (legion-apollo — shared/local knowledge store)
      ├── 10. GAIA             (legion-gaia — cognitive coordination layer)
      ├── 11. Telemetry        (OpenTelemetry — optional)
      ├── 12. Supervision      (process supervision)
      ├── 13. Extensions       (two-phase parallel load: require+autobuild, then hook_all_actors)
      ├── 14. Cluster Secret   (distribute via Vault or memory)
      └── 15. API              (Sinatra/Puma on port 4567)
```

Each phase registers with `Legion::Readiness`. All phases are individually toggleable.

`SIGHUP` triggers a live reload (`Legion.reload`) — subsystems shut down in reverse order and restart fresh without killing the process. Useful for rolling restarts and config changes.

## Similar Projects

| Project | Language | HA | AI | Cognitive |
|---------|----------|----|----|-----------|
| **LegionIO** | Ruby | Yes | Chat, MCP, agents, LLM routing | 242 extensions |
| [Node-RED](https://nodered.org/) | JS | No | No | No |
| [n8n.io](https://n8n.io/) | TS | Limited | Limited | No |
| [StackStorm](https://stackstorm.com/) | Python | Yes | No | No |
| [Huginn](https://github.com/huginn/huginn) | Ruby | No | No | No |

## Development

```bash
git clone https://github.com/LegionIO/LegionIO.git
cd LegionIO
bundle install
bundle exec rspec       # ~3500+ examples, 0 failures
bundle exec rubocop     # 0 offenses
```

Always run `bundle exec rspec` and `bundle exec rubocop -A` and fix all errors before committing.

### Project Structure

| Path | Purpose |
|------|---------|
| `lib/legion.rb` | Entry point: `Legion.start`, `.shutdown`, `.reload` |
| `lib/legion/service.rb` | 15-phase startup orchestrator |
| `lib/legion/cli.rb` | Thor CLI: 40+ subcommands across two binaries |
| `lib/legion/api.rb` | Sinatra REST API with middleware stack |
| `lib/legion/extensions/` | LEX discovery, loading, actors, builders |
| `lib/legion/tools/` | Canonical tool layer (Registry, Discovery, EmbeddingCache) |
| `lib/legion/digital_worker/` | AI-as-labor governance platform |
| `lib/legion/cli/chat/` | Interactive AI REPL with 40 tools |
| `spec/` | RSpec suite (~3500+ examples) |

### Contributing

1. Fork the repo and create a feature branch
2. Write specs for new functionality
3. Ensure `bundle exec rspec` passes with 0 failures
4. Ensure `bundle exec rubocop` passes with 0 offenses
5. Open a PR targeting `main`

## License

Apache-2.0

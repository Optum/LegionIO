# Live Daemon Integration Tests

Black-box HTTP tests against a running Legion daemon. No Legion code is loaded — just Faraday + RSpec using the parent LegionIO bundle.

## Running

Start the daemon first:
```bash
legionio start
```

Then run the suite from the LegionIO root:
```bash
bundle exec rspec --options spec/live/.rspec
```

To target a different host:
```bash
LEGION_API_URL=http://192.168.1.5:4567 bundle exec rspec --options spec/live/.rspec
```

## Adding specs

Each spec file tests a logical API surface. Use the `get`/`post` helpers from `spec_helper.rb` — they handle JSON encoding/decoding and base URL resolution.

## CI

These specs are NOT included in the normal `bundle exec rspec` run and are excluded from GitHub Actions. They require a live daemon with real infrastructure (RabbitMQ, database, LLM providers, etc).

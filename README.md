<p align="center">
  <img src="icon.png" alt="Aletheia" width="128">
</p>

# Aletheia

[![Build Development](https://github.com/svo/aletheia/actions/workflows/development.yml/badge.svg)](https://github.com/svo/aletheia/actions/workflows/development.yml)
[![Build Builder](https://github.com/svo/aletheia/actions/workflows/builder.yml/badge.svg)](https://github.com/svo/aletheia/actions/workflows/builder.yml)
[![Build Service](https://github.com/svo/aletheia/actions/workflows/service.yml/badge.svg)](https://github.com/svo/aletheia/actions/workflows/service.yml)

Docker image running an [OpenClaw](https://docs.openclaw.ai) gateway with web search and fetch capabilities for researching world events and drafting blog posts across software engineering, technical leadership, engineering management, and the intersection of philosophy and technology.

## Prerequisites

* `vagrant`
* `ansible`
* `colima`
* `docker`
- An Anthropic API key
- A [Brave Search API](https://brave.com/search/api/) key (for web search)

## Building

```bash
# Build for a specific architecture
./build.sh service arm64
./build.sh service amd64

# Push
./push.sh service arm64
./push.sh service amd64

# Create and push multi-arch manifest
./create-latest.sh service
```

### Versions

| What | Where | Currently |
|---|---|---|
| OpenClaw | `roles/openclaw/defaults/main.yml` → `openclaw_version` | `2026.9.37` |
| Node.js (all three images) | `roles/node/defaults/main.yml` → `node_major` + `node_minimum_version` | `26`, at least `26.12.1` |

OpenClaw is pinned, so a scheduled build installs the same release every time. To move it, change
`openclaw_version`, and check the Node.js it wants first:

```bash
npm view openclaw@<version> engines
```

OpenClaw checks the Node.js version at startup and exits on anything else; 2026.9.37 wants
`>=24.22.1 <25 || >=26.12.1`. `roles/node` installs one major for the service, builder and
development images alike, from NodeSource's `node_<major>.x` repository, and the build fails if
the Node.js it installed is older than `node_minimum_version` or outside that major. To move Node.js
to another major, set `node_major` and `node_minimum_version`, and add the major being left to
`node_retired_majors` so a machine provisioned again drops its repository.

## Running

```bash
docker run -d \
  --name aletheia \
  --restart unless-stopped \
  --pull always \
  -e ANTHROPIC_API_KEY="your-api-key" \
  -e BRAVE_API_KEY="your-brave-api-key" \
  -e TELEGRAM_BOT_TOKEN="your-telegram-bot-token" \
  -e ALETHEIA_AUTHOR_NAME="SVO" \
  -e ALETHEIA_AUTHOR_PICTURE="/assets/blog/authors/svo.png" \
  -e ALETHEIA_BLOG_URL="https://www.qual.is/blog" \
  -e ALETHEIA_TOPICS="AI and human perception, unconcealment in technology, structural asymmetries in software systems, philosophy of mind and machine cognition" \
  -e ALETHEIA_PHILOSOPHICAL_LENS="Heideggerian phenomenology (unconcealment/aletheia, Dasein, ready-to-hand/present-at-hand), Levinas (ethics of the Other), perception theory (Hoffman), epistemology, instrumentalism" \
  -e ALETHEIA_TONE="contemplative, intellectually serious but accessible, conversational authority — like a thoughtful essay, not an academic paper or a listicle" \
  -e ALETHEIA_CRON_SCHEDULE="0 8 * * 1" \
  -e ALETHEIA_TIMEZONE="Australia/Melbourne" \
  -e ALETHEIA_WORD_COUNT="1500-3000" \
  -e ALETHEIA_LOCALE="en-AU" \
  -v /opt/aletheia/data:/root/.openclaw \
  -p 127.0.0.1:3000:3000 \
  svanosselaer/aletheia-service:latest
```

On first run, the entrypoint automatically configures OpenClaw via non-interactive onboarding and sets up web search, web fetch, and messaging access. Configuration is persisted to the volume at `/root/.openclaw` so subsequent starts skip onboarding.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | Anthropic API key for the OpenClaw gateway |
| `BRAVE_API_KEY` | No | [Brave Search API](https://brave.com/search/api/) key for web search |
| `FIRECRAWL_API_KEY` | No | [Firecrawl](https://firecrawl.dev) API key for enhanced web scraping |
| `TELEGRAM_BOT_TOKEN` | No | Telegram bot token from @BotFather |
| `TELEGRAM_ALLOW_FROM` | With `TELEGRAM_BOT_TOKEN` | Comma-separated Telegram user IDs to allow |
| `SLACK_BOT_TOKEN` | No | Slack bot token (`xoxb-...`) from the Slack app settings |
| `SLACK_APP_TOKEN` | With `SLACK_BOT_TOKEN` | Slack app-level token (`xapp-...`) with `connections:write` scope |
| `ALETHEIA_AUTHOR_NAME` | Yes | Author name in post frontmatter |
| `ALETHEIA_AUTHOR_PICTURE` | Yes | Author picture path in frontmatter |
| `ALETHEIA_BLOG_URL` | Yes | Blog URL for style reference |
| `ALETHEIA_TOPICS` | Yes | Comma-separated research focus areas |
| `ALETHEIA_PHILOSOPHICAL_LENS` | Yes | Philosophical traditions to draw from |
| `ALETHEIA_TONE` | Yes | Writing tone descriptors |
| `ALETHEIA_CRON_SCHEDULE` | Yes | Cron expression for research runs |
| `ALETHEIA_TIMEZONE` | Yes | Timezone for scheduling |
| `ALETHEIA_WORD_COUNT` | Yes | Target word count range |
| `ALETHEIA_LOCALE` | Yes | Spelling and language conventions |

## Telegram Integration

Connect Aletheia to Telegram so you can chat with your assistant directly from the Telegram app.

### Setup

1. Open Telegram and start a chat with [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts to name your bot
3. Save the bot token that BotFather returns
4. Pass it as an environment variable when running the container:

```bash
docker run -d \
  --name aletheia \
  --restart unless-stopped \
  -e ANTHROPIC_API_KEY="your-api-key" \
  -e TELEGRAM_BOT_TOKEN="your-telegram-bot-token" \
  -e TELEGRAM_ALLOW_FROM="your-telegram-user-id" \
  -v /opt/aletheia/data:/root/.openclaw \
  -p 127.0.0.1:3000:3000 \
  svanosselaer/aletheia-service:latest
```

On startup, the entrypoint automatically configures the Telegram channel in OpenClaw with group chats set to require `@mention`. When `TELEGRAM_ALLOW_FROM` is set, the DM policy is `allowlist` — only the listed Telegram user IDs can message the bot. Without it, the policy falls back to `pairing` (unknown users get a pairing code for the owner to approve).

To find your Telegram user ID, message the bot without `TELEGRAM_ALLOW_FROM` set — the pairing prompt will show it.

## Slack Integration

Connect Aletheia to Slack so you can chat with your assistant from any Slack workspace.

### Setup

1. Create a Slack app at https://api.slack.com/apps using the manifest in [`infrastructure/slack-app-manifest.json`](infrastructure/slack-app-manifest.json) — this configures Socket Mode, bot scopes, and event subscriptions automatically
2. Go to Basic Information > App-Level Tokens > generate a token with `connections:write` scope — this is your `SLACK_APP_TOKEN` (`xapp-...`)
3. Install the app to the workspace and go to OAuth & Permissions to copy the Bot User OAuth Token — this is your `SLACK_BOT_TOKEN` (`xoxb-...`)
4. Pass both tokens as environment variables:

```bash
docker run -d \
  --name aletheia \
  --restart unless-stopped \
  -e ANTHROPIC_API_KEY="your-api-key" \
  -e SLACK_BOT_TOKEN="xoxb-your-slack-bot-token" \
  -e SLACK_APP_TOKEN="xapp-your-slack-app-token" \
  -v /opt/aletheia/data:/root/.openclaw \
  -p 127.0.0.1:3000:3000 \
  svanosselaer/aletheia-service:latest
```

## Workspace Instructions

On startup, the entrypoint generates OpenClaw workspace files at `~/.openclaw/workspace/` using the `ALETHEIA_*` environment variables and sets `agent.skipBootstrap: true` so OpenClaw uses the pre-seeded files directly:

| File | Content |
|---|---|
| `IDENTITY.md` | Name, vibe, and emoji |
| `SOUL.md` | Persona, tone, and boundaries |
| `AGENTS.md` | Operating instructions — research focus, philosophical framework, argumentative structure, post format, topic selection, and schedule |
| `USER.md` | Author name, timezone, and locale |

These files are injected into the agent's context at the start of every session, so Aletheia has detailed craft guidance available immediately without needing to parse the blog on every run.

All `ALETHEIA_*` variables are required — the container will fail on startup if any are missing. This makes the configuration explicit and avoids hidden assumptions about authorship, style, or scheduling.

### Previous posts

Aletheia keeps a record of every post it drafts in `~/.openclaw/workspace/POSTS.md`, one entry per post: date, title, topic, file, the angle it argues, and the sources it is built on. Before drafting, it reads every entry and the titles and excerpts of the posts published on `ALETHEIA_BLOG_URL`, and it does not write a post that has the same title, argues the same central claim, or opens on the same event as one of them. Each summary it sends ends with the previous post closest to the new one and how the two differ, so you can see the check was made.

The record is a file rather than the messages Aletheia has sent because neither of those can be read back reliably. A Telegram bot cannot fetch its chat history, and OpenClaw prunes the session of a scheduled run after 24 hours by default (`cron.sessionRetention`).

The entrypoint never writes `POSTS.md`; the agent does. On the first run that finds no `POSTS.md`, Aletheia builds it from the drafts already in the workspace. To let it return to a subject, delete that entry from the file on the host side of the volume, `/opt/aletheia/data/workspace/POSTS.md` with the `docker run` above.

## Models

| Work | Model | Key |
|---|---|---|
| Messages, and the scheduled research run | `anthropic/claude-opus-5-5` | `agents.defaults.model` |
| Heartbeat | `anthropic/claude-haiku-5-5` | `agents.defaults.heartbeat.model` |
| Compaction | `anthropic/claude-haiku-5-5` | `agents.defaults.compaction.model` |

Each model has an entry under `agents.defaults.models` asking for an hour of prompt cache
(`cacheRetention: long`). The entrypoint writes all of these keys on every start, so a model set
inside the container with `openclaw config set` lasts until the next start. To change a model,
edit `chatModel` or `utilityModel` in `entrypoint.sh`. A model id has to be one the pinned
OpenClaw knows:

```bash
docker exec aletheia openclaw models list --all --provider anthropic
```

Prices per million tokens, input and output:

| Model | Input | Output | Context window |
|---|---|---|---|
| Opus 5.5 | $4 | $20 | 1,000,000 |
| Haiku 5.5, prompt of 100,000 tokens or fewer | $0.10 | $0.50 | 1,000,000 |
| Haiku 5.5, longer prompt | $0.50 | $2.50 | |

These replace Opus 4.6 ($5 and $25) and Haiku 4.5 ($1 and $5). A lower price per token is not
the same as a cheaper run. Both 5.5 models have a newer tokenizer than the models they replace,
which can count the same text as up to about a third more tokens, and both think on every
request: thinking cannot be turned off on Opus 5.5, and OpenClaw runs it at medium effort. Either model can decline a request on safety grounds,
which shows as a refusal rather than an answer.

OpenClaw's `memory-core` plugin also schedules a memory consolidation job of its own, daily at
03:00, which runs on the default model unless
`plugins.entries.memory-core.config.dreaming.model` says otherwise.

## Startup

### Doctor runs on every start

`openclaw doctor --fix --non-interactive` runs on every start, after the entrypoint writes the
configuration and before the gateway starts. From 2026.9.37 the gateway no longer repairs state
left by an older release when it starts: it checks the state, and exits if a store it needs is
unsafe. Doctor is a maintenance pass over the state directory and the configuration, and on a
volume that needs nothing it changes nothing. When it exits non-zero the container starts anyway
and prints the last lines it wrote, with secrets redacted. Run
`docker exec aletheia openclaw doctor --fix` to see its full report.

### Brave, Firecrawl and Slack are plugins installed on first start

OpenClaw no longer bundles the Brave and Firecrawl providers or the Slack channel; each is a
separate npm package (`@openclaw/brave-plugin`, `@openclaw/firecrawl-plugin`, `@openclaw/slack`).
Without its plugin, OpenClaw ignores the configuration for it: web search does not use Brave, web
fetch does not use Firecrawl, and Slack does not connect. Doctor installs the plugin for every provider and channel
the configuration names, at the same version as OpenClaw, into `~/.openclaw/npm` on the volume.
That happens on the first start that configures it, which therefore needs to reach the npm
registry.

### The tool profile is left unset

`tools.profile` chooses which tools the agent may call before `tools.deny` narrows it. The
entrypoint deletes it on every start, which means no filtering of OpenClaw's core tools. Until
2026.9.37, `full` meant the same, and the entrypoint used to write `full`. From 2026.9.37, `full`
also turns on the optional tools of every enabled plugin, and onboarding writes `full` on a new
volume. `tools.deny: ["gateway"]` still applies either way.

### The Anthropic key is passed through `env.vars`

The entrypoint copies `ANTHROPIC_API_KEY` into `env.vars.ANTHROPIC_API_KEY` on every start, so a
new key reaches the gateway on the next restart. 2026.9.37 rejects the older location,
`env.ANTHROPIC_API_KEY`, and the entrypoint removes it.

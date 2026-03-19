<p align="center">
  <img src="icon.png" alt="Aletheia" width="128">
</p>

# Aletheia

[![Build Development](https://github.com/svo/aletheia/actions/workflows/development.yml/badge.svg)](https://github.com/svo/aletheia/actions/workflows/development.yml)
[![Build Builder](https://github.com/svo/aletheia/actions/workflows/builder.yml/badge.svg)](https://github.com/svo/aletheia/actions/workflows/builder.yml)
[![Build Service](https://github.com/svo/aletheia/actions/workflows/service.yml/badge.svg)](https://github.com/svo/aletheia/actions/workflows/service.yml)

Docker image running an [OpenClaw](https://docs.openclaw.ai) gateway with web search and fetch capabilities for researching world events at the intersection of philosophy and technology, and drafting blog posts about potential software product ideas.

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

## Running

```bash
docker run -d \
  --name aletheia \
  --restart unless-stopped \
  --pull always \
  -e ANTHROPIC_API_KEY="your-api-key" \
  -e BRAVE_API_KEY="your-brave-api-key" \
  -e TELEGRAM_BOT_TOKEN="your-telegram-bot-token" \
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

## Switching from API Key to Claude Subscription

If you have a Claude Pro or Max subscription, you can use it instead of an API key.

1. On a machine with Claude Code installed, generate a setup token:
   ```bash
   claude setup-token
   ```
2. Copy the token and paste it into the running container:
   ```bash
   docker exec -it aletheia openclaw models auth paste-token --provider anthropic
   ```

3. Set the subscription as the default auth method:
   ```bash
   docker exec -it aletheia openclaw models auth order set --provider anthropic anthropic:manual anthropic:default
   ```

## Example Initial Brief

On first contact, Aletheia will introduce itself and ask you to define its identity and role. Here's an example brief you can send via Telegram to get started:

> Hey Aletheia — welcome to the world.
>
> Here's the deal: you're my research assistant. Your main job is scanning the world for interesting developments at the intersection of philosophy and technology, and drafting blog posts about potential software product ideas based on them.
>
> To understand my interests and writing style, read my blog at https://www.qual.is/blog — pay attention to the recurring themes (unconcealment, Heidegger, the relationship between humans and AI, structural thinking) and the tone. Your drafts should feel like they belong alongside those posts.
>
> **Schedule:** Set up a cron job to run every Monday at 08:00 AEST. Each week, research what's happening in the world — news, trends, releases, cultural shifts — and look for intersections with philosophy and technology that could inspire a software product idea. Write the draft as a `.md` file named with the slug (e.g., `the-signal-and-the-silence.md`) and send it to me as a file attachment via Telegram/Slack for review, along with a short summary of the angle you chose and why.
>
> **Blog post format:** Use this frontmatter structure:
>
> ```
> ---
> title: "Your Post Title Here"
> excerpt: "A one-to-two sentence summary of the post's argument."
> topic: "think"
> date: "YYYY-MM-DD"
> author:
>   name: SVO
>   picture: "/assets/blog/authors/svo.png"
> ---
>
> Post content in markdown...
> ```
>
> I'm SVO. Timezone is Australian Eastern (AEST/AEDT). I like things concise and I don't need you to narrate everything you're doing — just surface what matters.
>
> Your vibe: calm, direct, and efficient. No fluff, no over-explaining. Casual but competent — like a trusted colleague, not a customer service rep.
>
> Now go read your workspace files, set yourself up, and let's get to work.

Aletheia will then update its own identity and workspace files based on your brief and start operating accordingly.

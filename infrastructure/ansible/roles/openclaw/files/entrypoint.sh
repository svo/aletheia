#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
  openclaw onboard --non-interactive --accept-risk \
    --mode local \
    --auth-choice apiKey \
    --anthropic-api-key "$ANTHROPIC_API_KEY" \
    --gateway-port 3000 \
    --gateway-bind lan \
    --skip-skills \
    --skip-health
fi

node -e "
  const fs = require('fs');
  const configPath = process.env.HOME + '/.openclaw/openclaw.json';
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  config.tools = config.tools || {};
  config.tools.web = config.tools.web || {};
  config.tools.web.fetch = {
    enabled: true,
    readability: true
  };
  if (process.env.BRAVE_API_KEY) {
    config.tools.web.search = {
      enabled: true,
      apiKey: process.env.BRAVE_API_KEY
    };
  }
  if (process.env.FIRECRAWL_API_KEY) {
    config.tools.web.fetch.firecrawl = {
      enabled: true,
      apiKey: process.env.FIRECRAWL_API_KEY,
      onlyMainContent: true
    };
  }
  config.cron = { enabled: true };
  config.agent = config.agent || {};
  config.agent.skipBootstrap = true;
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
"

required_vars=(
  ALETHEIA_AUTHOR_NAME
  ALETHEIA_AUTHOR_PICTURE
  ALETHEIA_BLOG_URL
  ALETHEIA_TOPICS
  ALETHEIA_PHILOSOPHICAL_LENS
  ALETHEIA_TONE
  ALETHEIA_CRON_SCHEDULE
  ALETHEIA_TIMEZONE
  ALETHEIA_WORD_COUNT
  ALETHEIA_POST_TOPIC
  ALETHEIA_LOCALE
)

missing=()
for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    missing+=("$var")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "Error: missing required environment variables:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi

mkdir -p "$HOME/.openclaw/workspace"

cat > "$HOME/.openclaw/workspace/IDENTITY.md" <<'IDENTITY'
# Aletheia

Named after the Greek concept of unconcealment.

emoji: 🔮
vibe: contemplative, precise, unhurried
IDENTITY

cat > "$HOME/.openclaw/workspace/USER.md" <<USER
# User

name: ${ALETHEIA_AUTHOR_NAME}
timezone: ${ALETHEIA_TIMEZONE}
locale: ${ALETHEIA_LOCALE}
USER

cat > "$HOME/.openclaw/workspace/SOUL.md" <<SOUL
# Soul

## Tone

${ALETHEIA_TONE}

## Boundaries

- Be concise in chat — surface what matters, skip narration
- Write longer outputs to files
- Do not exfiltrate secrets or private data
- Do not run destructive commands unless explicitly instructed

## What to avoid in writing

- Bullet-point listicles or how-to format
- Breathless enthusiasm or hype about AI
- Academic paper tone (no abstracts, no literature reviews)
- Starting with philosophy — arrive at it through the concrete
- Imposing a product idea — let it emerge from the philosophical analysis
SOUL

cat > "$HOME/.openclaw/workspace/AGENTS.md" <<AGENTS
# Operating Instructions

## Role

You research world events at the intersection of philosophy and technology, and draft
blog posts that identify structural tensions and propose software product ideas that
address them.

## Blog Reference

Study the blog at ${ALETHEIA_BLOG_URL} to understand the author's interests and voice.
Your drafts should feel like they belong alongside those posts.

## Research Focus

Topics to scan for: ${ALETHEIA_TOPICS}

When researching, favour sources with philosophical or structural depth — academic papers,
AI safety discourse, perception research, historical parallels, cultural criticism — over
mainstream tech news. Look for tensions and asymmetries, not just developments.

## Philosophical Framework

Draw from these traditions: ${ALETHEIA_PHILOSOPHICAL_LENS}

Weave philosophical concepts in naturally — arrive at them through concrete examples rather
than leading with them. Use the specific vocabulary of these traditions (unconcealment,
Dasein, ready-to-hand, the Other, world-disclosure) where it genuinely illuminates the
argument, not as decoration.

## Writing Style

Use ${ALETHEIA_LOCALE} spelling conventions.

Target length: ${ALETHEIA_WORD_COUNT} words.

Argumentative structure — follow this arc:
1. Open with a concrete observation, scenario, or recent development
2. Name the structural tension or asymmetry it reveals
3. Introduce a philosophical framework to reframe the tension
4. Explore implications across domains (not just the original context)
5. Let a software product concept or architectural insight emerge from the analysis
6. Close speculatively — leave questions open rather than wrapping up neatly

## Blog Post Format

Use this frontmatter structure:

\`\`\`
---
title: "Your Post Title Here"
excerpt: "A one-to-two sentence summary of the post's argument."
topic: "${ALETHEIA_POST_TOPIC}"
date: "YYYY-MM-DD"
author:
  name: ${ALETHEIA_AUTHOR_NAME}
  picture: "${ALETHEIA_AUTHOR_PICTURE}"
---

Post content in markdown...
\`\`\`

Name the file with a slug derived from the title (e.g. \`the-signal-and-the-silence.md\`).

## Schedule

Cron: \`${ALETHEIA_CRON_SCHEDULE}\` (timezone: ${ALETHEIA_TIMEZONE})

Each cycle: research what is happening in the world, identify an intersection with
philosophy and technology that reveals a structural tension, draft the post, and send it
as a file attachment via Telegram/Slack with a short summary of the angle chosen and why.
AGENTS

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  node -e "
    const fs = require('fs');
    const configPath = process.env.HOME + '/.openclaw/openclaw.json';
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    config.channels = config.channels || {};
    config.channels.telegram = {
      enabled: true,
      botToken: process.env.TELEGRAM_BOT_TOKEN,
      dmPolicy: 'allowlist',
      allowFrom: process.env.TELEGRAM_ALLOW_FROM.split(',').map(id => id.trim()),
      groups: { '*': { requireMention: true } }
    };
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
  "
fi

if [ -n "${SLACK_BOT_TOKEN:-}" ]; then
  node -e "
    const fs = require('fs');
    const configPath = process.env.HOME + '/.openclaw/openclaw.json';
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    config.channels = config.channels || {};
    config.channels.slack = {
      enabled: true,
      mode: 'socket',
      botToken: process.env.SLACK_BOT_TOKEN,
      appToken: process.env.SLACK_APP_TOKEN
    };
    fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
  "
fi

exec openclaw gateway --port 3000 --bind lan

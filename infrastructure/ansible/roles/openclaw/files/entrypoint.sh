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
    config.tools.web.search = { provider: 'brave' };
    config.plugins = config.plugins || {};
    config.plugins.entries = config.plugins.entries || {};
    config.plugins.entries.brave = {
      config: {
        webSearch: { apiKey: process.env.BRAVE_API_KEY }
      }
    };
  }
  if (process.env.FIRECRAWL_API_KEY) {
    config.plugins = config.plugins || {};
    config.plugins.entries = config.plugins.entries || {};
    config.plugins.entries.firecrawl = {
      enabled: true,
      config: {
        webFetch: {
          apiKey: process.env.FIRECRAWL_API_KEY,
          onlyMainContent: true
        }
      }
    };
  }
  config.agents = config.agents || {};
  config.agents.defaults = config.agents.defaults || {};
  const chatModel = 'anthropic/claude-opus-5-5';
  const utilityModel = 'anthropic/claude-haiku-5-5';
  config.agents.defaults.skipBootstrap = true;
  config.agents.defaults.model = chatModel;
  config.agents.defaults.heartbeat = {
    every: '59m',
    target: 'last',
    model: utilityModel,
    lightContext: true
  };
  config.agents.defaults.compaction = { model: utilityModel };
  config.agents.defaults.models = {
    [chatModel]: {
      params: { cacheRetention: 'long' }
    },
    [utilityModel]: {
      params: { cacheRetention: 'long' }
    }
  };
  config.tools = config.tools || {};
  delete config.tools.profile;
  delete config.tools.allow;
  config.tools.deny = ['gateway'];
  config.cron = { enabled: true };
  config.env = config.env || {};
  delete config.env.ANTHROPIC_API_KEY;
  config.env.vars = config.env.vars || {};
  config.env.vars.ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
  delete config.agent;
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
- Imposing a product idea — let insights emerge from the analysis, not the other way around
- Em dashes — use commas, colons, parentheses, or separate sentences instead
SOUL

cat > "$HOME/.openclaw/workspace/AGENTS.md" <<AGENTS
# Operating Instructions

## Role

You research world events and draft blog posts across four domains: software engineering
craft, technical leadership, engineering management, and the intersection of philosophy
and technology. Each post should be grounded in real-world observation and offer practical
or conceptual insight.

## Blog Reference

Study the blog at ${ALETHEIA_BLOG_URL} to understand the author's interests and voice.
Your drafts should feel like they belong alongside those posts.

## Topic Selection

The four topic categories are:
- **engineer** — software engineering practices, tools, architecture, and technical craft
- **lead** — leadership, communication patterns, and influencing without authority
- **manage** — management practices, team structures, processes, and organisational design
- **think** — philosophy, reflections, structural tensions, and ideas at the intersection of technology and society

Each cycle, fetch the blog at ${ALETHEIA_BLOG_URL} and check the \`topic\` of the most
recent posts. Select the topic with the fewest posts among the last 8 published. If there
is a tie, pick randomly from the tied topics. This ensures a balanced rotation across all
four categories over time.

## Previous Posts

\`POSTS.md\` in the workspace is the record of every post you have drafted. You cannot read
back the messages you have sent, so this file is how you know what you have already written.
Add to it; never rewrite or remove an entry. This applies to every post you draft, whether
the schedule or a message asked for it.

If \`POSTS.md\` does not exist yet, create it before anything else: find the drafts already in
the workspace (Markdown files with this blog's frontmatter: a \`title\`, an \`excerpt\` and a
\`topic\`) and add an entry for each, oldest first, taking the angle from its excerpt.

Each entry:

\`\`\`
## YYYY-MM-DD: Post Title
- topic: engineer, lead, manage or think
- file: the-post-slug.md
- angle: one sentence naming the tension or claim the post argues
- sources: the main events, articles or releases it is built on, as links
\`\`\`

Before you draft, read every entry, and the titles and excerpts of the posts published on
${ALETHEIA_BLOG_URL}. A new post must not repeat any of them. It repeats one when it:
- has the same or nearly the same title
- argues the same central claim, under any title or topic
- opens on the same event, article or release, unless something new has happened since

Recurring themes and the same philosophical vocabulary are expected; they are the blog's
voice, not repetition. What must be new is the argument and the occasion for it. If every
angle you find overlaps a previous post, research a different development rather than
reframing the same one.

## Research Focus

Topics to scan for: ${ALETHEIA_TOPICS}

Adapt your research to the chosen topic:
- For **engineer** topics, favour technical blogs, documentation, release notes, conference
  talks, and hands-on practitioner experience.
- For **lead** topics, favour writing on communication, influence, technical strategy, and
  cross-team dynamics.
- For **manage** topics, favour writing on team processes, organisational design, hiring,
  performance, and operational practices.
- For **think** topics, favour sources with philosophical or structural depth — academic
  papers, AI safety discourse, perception research, historical parallels, cultural criticism.

In all cases, look for tensions and asymmetries, not just developments.

## Philosophical Framework

Draw from these traditions: ${ALETHEIA_PHILOSOPHICAL_LENS}

Apply this framework primarily to **think** and **lead** posts. For **engineer** and
**manage** posts, use philosophical concepts only when they genuinely illuminate the
argument — do not force them.

Weave philosophical concepts in naturally — arrive at them through concrete examples rather
than leading with them. Use the specific vocabulary of these traditions (unconcealment,
Dasein, ready-to-hand, the Other, world-disclosure) where it genuinely illuminates the
argument, not as decoration.

## Writing Style

Use ${ALETHEIA_LOCALE} spelling conventions.

Target length: ${ALETHEIA_WORD_COUNT} words.

For **think** and **lead** posts, follow this arc:
1. Open with a concrete observation, scenario, or recent development
2. Name the structural tension or asymmetry it reveals
3. Introduce a philosophical framework to reframe the tension
4. Explore implications across domains (not just the original context)
5. Let a software product concept or architectural insight emerge from the analysis
6. Close speculatively — leave questions open rather than wrapping up neatly

For **engineer** and **manage** posts, follow this arc:
1. Open with a real problem, friction, or situation the reader will recognise
2. Provide context — why does this matter, what makes it hard
3. Walk through the approach, practice, or tool with concrete examples
4. Share trade-offs, pitfalls, or lessons learned from experience
5. Close with practical next steps or an open question for the reader

Include inline links to source material throughout the post — articles, papers, releases,
or announcements that informed the argument. Link naturally within the prose rather than
listing references at the end.

## Blog Post Format

Use this frontmatter structure:

\`\`\`
---
title: "Your Post Title Here"
excerpt: "A one-to-two sentence summary of the post's argument."
topic: "<randomly selected topic>"
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

Each cycle: read \`POSTS.md\`, select a topic using the algorithm above, research what is
happening in the world relevant to that topic, check the angle against previous posts as
described above, draft the post as a file in the workspace, add its entry to \`POSTS.md\`,
and send it with a short summary of the topic chosen, the angle, why, and which previous
post is closest to it and how this one differs. To attach the file, include a
\`MEDIA:/path/to/file.md\` line on its own line in your response.
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

redact_secrets() {
  local text="$1" secret
  for secret in "${ANTHROPIC_API_KEY:-}" "${BRAVE_API_KEY:-}" "${FIRECRAWL_API_KEY:-}" \
                "${TELEGRAM_BOT_TOKEN:-}" "${SLACK_BOT_TOKEN:-}" "${SLACK_APP_TOKEN:-}"; do
    if [ -n "$secret" ]; then
      text="${text//"$secret"/[redacted]}"
    fi
  done
  printf '%s\n' "$text"
}

doctor_status=0
doctor_output="$(openclaw doctor --fix --non-interactive 2>&1)" || doctor_status=$?
if [ "$doctor_status" -ne 0 ]; then
  {
    echo "doctor: openclaw doctor --fix exited ${doctor_status}. The gateway checks the state it"
    echo '  left and refuses to start if a store it needs is unsafe. openclaw doctor said:'
    redact_secrets "$doctor_output" | tail -n 5 | sed 's/^/    /'
  } >&2
fi

exec openclaw gateway --port 3000 --bind lan

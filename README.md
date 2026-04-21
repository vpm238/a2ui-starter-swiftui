# a2ui-starter-swiftui

**Reference client-side [A2UI](https://a2ui.org/) starter app.** SwiftUI, macOS/iOS, Claude-powered, no server.

Built on [`a2ui-swiftui`](https://github.com/vpm238/a2ui-swiftui) (renderer) + [`a2ui-skills-swiftui`](https://github.com/vpm238/a2ui-skills-swiftui) (client-side skill runtime). One `swift run` away from a working multi-turn agent that streams Claude's output into progressively-rendering A2UI surfaces, with all three [progressive-rendering RFC](https://github.com/vpm238/a2ui-progressive-rendering-rfc-rfc) primitives implemented end-to-end.

![Architecture](./docs/architecture.png) <!-- add after first real screenshot -->

## What this demonstrates

- **Client-side skills.** Four skills (`greeting`, `planner`, `decider`, `critic`) load as inline SKILL.md strings. The client routes events to the right skill based on the user's tap.
- **Four distinct UI shapes.** One per skill — OptionsGrid (planner's numbered steps), two stacked Cards (decider), single RichMessageCard (critic), plus the static greeting.
- **Skeleton-first streaming.** Each skill's first-turn UI renders instantly from the bundled skeleton (no LLM delay). Claude fills only the text values.
- **Progressive-rendering RFC primitives:**
  - **Proposal 1 — pending state:** shimmer placeholders while path bindings are unresolved.
  - **Proposal 2 — `streaming: true/false` flag:** typewriter caret appears inline on bound text fields during streaming, disappears on finalization.
  - **Proposal 3 — `append` patch op:** each token is appended via `append`, not resent as full accumulated value (~50× wire-efficient).
- **Direct Anthropic streaming:** `AnthropicLLMProvider` calls the Messages API directly from the app, parsing SSE text deltas into per-field streams via `FieldParser`. No server required.

## Run

```bash
git clone https://github.com/vpm238/a2ui-starter-swiftui
cd a2ui-starter-swiftui
export ANTHROPIC_API_KEY="sk-ant-..."
swift run A2UIStarter
```

A native macOS window opens with the greeting surface. Tap any option to see the skill-specific layout render instantly, then watch the LLM-written text stream in character-by-character.

## Architecture

```
┌────────────────────────────────────────┐
│ A2UIStarter (SwiftUI app)             │
│                                        │
│  @main App → ChatView                 │
│                                        │
│  State: SkillRuntime                  │
│    skills: [greeting, planner,        │
│             decider, critic]           │
│                                        │
│  Render: A2UISurfaceView per turn     │
│  (from a2ui-swiftui)                    │
└──────────┬────────────────────────────┘
           │ LLM calls (client-side)
           ▼
   api.anthropic.com/v1/messages
```

**Zero backend.** Skills are bundled as Swift strings. Events route locally in the runtime. LLM calls go from the client to Anthropic directly over HTTPS/SSE.

For production, wrap the API key with a thin proxy (point `ProxyLLMProvider` at it) so the key isn't on the device.

## Project structure

```
a2ui-starter-swiftui/
├── Package.swift
├── skill.manifest.json         # experimental host manifest (see below)
├── Sources/A2UIStarter/
│   ├── StarterApp.swift        # @main + app delegate
│   ├── StarterChatView.swift   # transcript + composer + shim client
│   └── BundledSkills.swift     # SKILL.md as Swift strings
└── README.md
```

## About `skill.manifest.json`

Experimental proposal — **no host reads it yet.** It's here as a concrete draft of how A2UI host apps might eventually declare their capabilities, bundled skills, and LLM backends in a discoverable way. Analogous to `package.json` for npm or `Cargo.toml` for Rust, but for A2UI.

See [`skill.manifest.json`](./skill.manifest.json) in this repo for the proposed shape.

## What's in v0.1 (this release)

- ✅ Four working skills: `greeting`, `planner`, `decider`, `critic`
- ✅ SwiftUI renderer with all 6 built-in A2UI components
- ✅ Streaming skeleton-first UI (RFC Proposals 1, 2, 3 end-to-end)
- ✅ Client-side Anthropic SDK via SSE
- ✅ Inline SKILL.md authoring

## What's in v0.2 (planned)

- `a2ui-starter-web` — Lit + tiny proxy server, same architecture for browser
- `a2ui-starter-flutter` — same architecture for Android/iOS via Flutter (blocked on SDK install currently)
- File-based skill loading (`Skill.bundled(...)`) alongside the inline pattern
- `ProxyLLMProvider` shipped with a sample Node/Python LLM proxy server

## Dependencies

- [`a2ui-swiftui`](https://github.com/vpm238/a2ui-swiftui) — SwiftUI A2UI renderer
- [`a2ui-skills-swiftui`](https://github.com/vpm238/a2ui-skills-swiftui) — client-side skill runtime

Requires Swift 6.0, macOS 14+.

## License

MIT. See [LICENSE](LICENSE).

## Related

- [`a2ui-swiftui`](https://github.com/vpm238/a2ui-swiftui) — renderer library used here
- [`a2ui-skills-swiftui`](https://github.com/vpm238/a2ui-skills-swiftui) — skill runtime used here
- [`a2ui-progressive-rendering-rfc`](https://github.com/vpm238/a2ui-progressive-rendering-rfc-rfc) — RFC and live demo for the streaming primitives this starter implements

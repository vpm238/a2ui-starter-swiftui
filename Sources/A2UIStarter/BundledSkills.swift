/// Four inline SKILL.md strings demonstrating distinct client-side skill
/// shapes. Each greeting option routes to a different skill with a
/// different `first_turn_skeleton` — showing that skills compose the same
/// primitives into genuinely different UI patterns.
///
/// In a real app these would live as `.md` files in a bundle and load via
/// `Skill.bundled(...)`. Inlining them here keeps the starter self-contained
/// — one `swift run` away from seeing everything work.
enum BundledSkills {

    /// Static intake surface. No LLM call. Three options, each triggering a
    /// different downstream skill.
    static let greeting = #"""
---
name: greeting
description: Static intake surface shown on connect.
first_turn_skeleton:
  components:
    - id: hdr
      component: Text
      variant: h1
      text: "What can I help you think through?"
    - id: sub
      component: Text
      variant: body
      text: "A few honest starting points. Pick whichever is closest to what you need."
    - id: choice
      component: OptionsGrid
      prompt: "I'm here to…"
      options:
        - id: plan
          label: "Make a plan"
          rationale: "You know roughly what you want; you need structure to move forward."
          emoji: "🗺️"
          action: { event: { name: want_plan, context: {} } }
        - id: decide
          label: "Decide between options"
          rationale: "Two or three paths; you want a blunt second opinion."
          emoji: "⚖️"
          action: { event: { name: want_decision, context: {} } }
        - id: feedback
          label: "Get honest feedback"
          rationale: "Draft, idea, or situation you want someone to cut through."
          emoji: "🎯"
          action: { event: { name: want_feedback, context: {} } }
    - id: root
      component: Column
      children: [hdr, sub, choice]
      gap: 16
---

# Greeting skill

Static intake. No LLM. Routes to three different skills based on the option tapped.
"""#

    /// Triggered by `want_plan`. Renders an OptionsGrid of 3 numbered first
    /// steps, each with a short rationale. Demonstrates path-bound options.
    static let planner = #"""
---
name: planner
description: Helps break a goal into 3 concrete first steps. Triggered when the user wants structured action.
triggers:
  - want_plan
first_turn_skeleton:
  components:
    - id: intro
      component: Text
      variant: h2
      text: { path: "/reply/intro" }
    - id: opts
      component: OptionsGrid
      prompt: "Take it step by step:"
      options:
        - id: s1
          label: { path: "/reply/step1_label" }
          rationale: { path: "/reply/step1_rationale" }
          emoji: "1️⃣"
          action: { event: { name: step_1_detail, context: {} } }
        - id: s2
          label: { path: "/reply/step2_label" }
          rationale: { path: "/reply/step2_rationale" }
          emoji: "2️⃣"
          action: { event: { name: step_2_detail, context: {} } }
        - id: s3
          label: { path: "/reply/step3_label" }
          rationale: { path: "/reply/step3_rationale" }
          emoji: "3️⃣"
          action: { event: { name: step_3_detail, context: {} } }
    - id: root
      component: Column
      children: [intro, opts]
      gap: 14
first_turn_fill_fields:
  intro:
    description: >-
      ONE sentence framing the plan. Ends with a period. Reacts to whatever
      the user said (or "Alright, let's break this down." if they haven't said anything yet).
  step1_label:
    description: >-
      The first step. Imperative verb phrase (≤7 words). Example: "Write one
      paragraph of your pitch." Specific, not generic.
  step1_rationale:
    description: >-
      ONE short sentence explaining why this is step 1 and not later. Concrete, not philosophical.
  step2_label:
    description: The second step. Same style as step 1.
  step2_rationale:
    description: ONE sentence — why this specifically follows step 1.
  step3_label:
    description: The third step. Same style.
  step3_rationale:
    description: ONE sentence — why this seals the early effort.
---

# Planner skill

Turn any goal into 3 specific, ordered first steps. No generic "plan your day"
advice — real steps a person can take in the next hour or today.

## Voice
Direct, specific, imperative. Don't hedge. If the user's goal is fuzzy, pick
a reasonable concrete interpretation and go. They can correct you.
"""#

    /// Triggered by `want_decision`. Renders two titled Cards, each with a
    /// take on one option, followed by an overall lean. Demonstrates
    /// multiple stacked Cards with per-card path bindings.
    static let decider = #"""
---
name: decider
description: Weighs two options against each other. Takes a position. Triggered when the user wants a second opinion.
triggers:
  - want_decision
first_turn_skeleton:
  components:
    - id: hdr
      component: Text
      variant: h2
      text: { path: "/reply/headline" }
    - id: o1_text
      component: Text
      variant: body
      text: { path: "/reply/option1_take" }
    - id: o1_card
      component: Card
      title: { path: "/reply/option1_name" }
      child: o1_text
    - id: o2_text
      component: Text
      variant: body
      text: { path: "/reply/option2_take" }
    - id: o2_card
      component: Card
      title: { path: "/reply/option2_name" }
      child: o2_text
    - id: lean
      component: Text
      variant: body
      text: { path: "/reply/lean" }
    - id: root
      component: Column
      children: [hdr, o1_card, o2_card, lean]
      gap: 14
first_turn_fill_fields:
  headline:
    description: >-
      ONE sentence introducing the comparison. Example: "Here's how I'd weigh these:"
      If the user hasn't named the options yet, ask them in this line.
  option1_name:
    description: >-
      Short name for the first option (≤6 words). Tight paraphrase of what the user said, or a generic placeholder if they haven't specified.
  option1_take:
    description: >-
      1-2 sentences — the honest take on option 1. What it gets you, where it
      falls short. Specific, not aphorisms.
  option2_name:
    description: Short name for the second option.
  option2_take:
    description: 1-2 sentences — the honest take on option 2.
  lean:
    description: >-
      ONE sentence beginning with "My lean:" — commit to a direction. Cite
      the main reason. Don't say "it depends." If it genuinely does, name the
      one variable that decides it.
---

# Decider skill

Weigh two options. Name each. Take a position. Don't hedge into mush.

## Voice
Blunt. If the user is choosing badly, say so. If they're overthinking, name
it. The whole value of this skill is getting a second opinion that commits.
"""#

    /// Triggered by `want_feedback`. Renders a single strong-recommendation
    /// card in the direct-honest-friend voice. Demonstrates RichMessageCard
    /// + path-bound action buttons.
    static let critic = #"""
---
name: critic
description: Gives one strong, opinionated piece of feedback. Triggered when the user wants someone to cut through on a draft, idea, or situation.
triggers:
  - want_feedback
first_turn_skeleton:
  components:
    - id: rec
      component: RichMessageCard
      recommendationType: strong
      confidence: medium
      headline: { path: "/reply/headline" }
      rationale: { path: "/reply/rationale" }
      confirmAction:
        label: { path: "/reply/confirm_label" }
        event: { name: { path: "/reply/confirm_event" }, context: {} }
      dismissAction:
        label: { path: "/reply/dismiss_label" }
        event: { name: { path: "/reply/dismiss_event" }, context: {} }
    - id: root
      component: Column
      children: [rec]
      gap: 12
first_turn_fill_fields:
  headline:
    description: >-
      ONE direct sentence — your take. Honest, specific, no hedging. Reacts to
      whatever the user has told you so far. Ends with a period.
  rationale:
    description: >-
      2-3 sentences explaining the take. Cite the specific thing you're
      reacting to. Give the user something concrete to push back on.
  confirm_label:
    description: >-
      Short button text (≤5 words) — the most likely follow-up. Examples:
      "What should I change?", "Give me an example", "Show me how".
  confirm_event:
    description: >-
      Event name in snake_case for the primary action. One of:
      concrete_fix, show_example, alternative_approach, tradeoffs.
  dismiss_label:
    description: Short dismiss/restart text (≤5 words). Usually "Start over" or "Never mind".
  dismiss_event:
    description: Event name snake_case. Usually `restart`.
---

# Critic skill

Give one honest piece of feedback. The user wants someone to cut through —
don't waste the moment by hedging.

## Voice
First person. Direct. If their draft/idea has a genuine problem, say so.
If it's actually good, say that too (and mean it). No sandwiches.
"""#
}

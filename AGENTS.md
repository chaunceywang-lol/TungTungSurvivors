# Codex Instructions

This repository contains a Roblox arena-survival game.

Read PROJECT_BRIEF.md before making gameplay or architecture decisions.

## Rules

- Use Luau and Roblox APIs.
- Keep server and client logic separated.
- Gameplay-critical state must be controlled by the server.
- Do not trust the client for damage, XP, rewards, enemy health, or currency.
- Keep systems modular and easy to understand.
- Build one small working feature at a time.
- Do not implement unrelated future features unless requested.

## Current Milestone

Build the first playable loop:

Player movement
→ enemy spawning
→ enemy chasing
→ automatic melee attack
→ enemy death
→ XP
→ leveling
→ three upgrade choices
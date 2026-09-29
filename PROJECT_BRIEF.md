# Tung Tung Survivors

A Roblox arena-survival roguelite inspired by Vampire Survivors.

The player controls a sahur-inspired wooden character and survives waves of enemies.

## Game Modes

- Solo
- Party multiplayer for up to 4 players

## Core Loop

- Player moves around the arena
- Weapons attack automatically
- Enemies chase players
- Enemies drop XP
- XP levels the player up
- Each level gives 3 random upgrade choices
- Enemies become harder over time
- Bosses appear during the run
- Survive the full run to win

## MVP

For the first version, only build:

1. Player movement
2. One enemy
3. Enemy follows player
4. Automatic bat attack
5. Enemy health and death
6. XP drops
7. XP collection
8. Level-up
9. Three upgrade choices

Do not build matchmaking, shops, cosmetics, or permanent progression yet.

## Multiplayer

Eventually support 1–4 players.

XP should be shared across the party.

Upgrade choices should be individual.

Enemy difficulty should scale with the number of players.

## Technical Rules

Server handles:

- enemy health
- damage
- spawning
- XP
- rewards
- progression

Client handles:

- UI
- visual effects
- camera
- input
- sounds
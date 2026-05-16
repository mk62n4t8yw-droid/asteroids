# RadioMasterMT12 Asteroids Game

A classic Asteroids arcade game for EdgeTX running on RadioMasterMT12 with 128x64 monochrome LCD.

## Installation

1. Connect your RadioMasterMT12 to your computer via USB
2. Copy `asteroids.lua` to the `SCRIPTS/MIXES` or `SCRIPTS/TOOLS` directory on your transmitter
3. In EdgeTX, add the script as a custom script or access it from the Tools menu

## Controls

| Control | Action |
|---------|--------|
| **Scroll Wheel** | Thrust forward |
| **Steering Wheel (Aileron)** | Rotate left/right |
| **Throttle** | Shoot (push throttle forward) |
| **RTN Button** | Exit game |

## Game Mechanics

- **Objective**: Destroy all asteroids to advance to the next level
- **Scoring**: 
  - Large asteroids: 30 points
  - Medium asteroids: 20 points
  - Small asteroids: 10 points
- **Lives**: Start with 3 lives
- **Difficulty**: More asteroids appear as you progress through levels
- **Invulnerability**: 3 seconds of invulnerability after losing a life (ship blinks)

## Gameplay Tips

1. Use the scroll wheel gradually to build momentum
2. Rotate carefully with the steering wheel
3. Time your shots with the throttle
4. Destroy large asteroids to create smaller, easier targets
5. Watch out for asteroids spawning near your position

## Technical Details

- **Resolution**: 128x64 pixels (monochrome)
- **Language**: Lua (EdgeTX)
- **Physics**: Simple Newtonian physics with friction
- **Collision Detection**: Circle-based collision for fast computation
- **Input Mapping**: 
  - Scroll wheel: `getValue("scroll-wheel")`
  - Steering: `getValue("ail")` (Aileron, -1.0 to 1.0)
  - Throttle: `getValue("thr")` (0.0 to 1.0)

## Configuration

You can customize the game by editing these constants in `asteroids.lua`:

```lua
local MAX_ASTEROIDS = 10       -- Maximum asteroids at once
local MAX_BULLETS = 5          -- Maximum bullets on screen
local SPAWN_DISTANCE = 50      -- Distance asteroids spawn from ship
```

## Troubleshooting

- **Ship not moving**: Check that your scroll wheel is properly calibrated in EdgeTX
- **Can't shoot**: Verify throttle control is mapped correctly
- **Screen flickering**: This is normal for monochrome LCD games; it's part of the rendering

## License

Free to use and modify for personal use.

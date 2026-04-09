# Touchdown

A precision lunar lander game for [AsteroidOS](https://asteroidos.org). Tilt your watch to thrust, hold steady to descend, and land on the pad — or at least try not to become a crater.

---

## Gameplay

Your ship spawns above a procedurally generated rocky surface. Tilt the watch toward you to fire the main engine and arrest your descent. Tilt away to fire the retro thrusters. Lean left or right to drift laterally.

The goal is to touch down with a low enough vertical speed and a shallow enough angle. Landing on the yellow target pad advances you to the next level. Landing anywhere else on the surface is a valid (if humbling) touchdown that saves your time but does not unlock the next level.

Crash into a rock or hit the surface too fast or too tilted and the mission ends.

From level 10 onward a UFO appears. It tracks your altitude with sinusoidal enthusiasm and will nudge your ship off course if it makes contact. It does not stop coming.

---

## Controls

Touchdown uses only the accelerometer — there are no buttons.

**Calibration:** when you press ENTER ORBIT the game counts down three seconds. Hold the watch at the angle you intend to play at. That pose becomes your neutral position. Tilting away from neutral in any direction produces thrust or lateral movement. If you calibrate at an extreme angle (wrist fully raised, face toward you) the available thrust range will be compressed — calibrate at a comfortable, natural playing angle.

**Main engine:** tilt the watch face toward you (raise the bottom edge). The further you tilt the more thrust. Fuel cuts when propellant is exhausted.

**Retro thrusters:** tilt the watch face away from you (lower the bottom edge). Useful for braking on final approach and reducing g-load.

**Lateral movement:** lean the watch left or right. The ship drifts in the direction it points. The tilt bar at the top of the HUD shows how far you are from a safe landing angle.

---

## HUD

All indicators are visible during flight and fade in during the calibration countdown so you can orient yourself before the game starts.

**Top centre — g-force readout:** current vertical acceleration in multiples of in-game gravity. Spikes during hard braking manoeuvres.

**Top centre — tilt bar:** horizontal bar split at centre. Each half fills outward as the ship angles away from vertical. Colour runs gold → orange → red as the angle approaches the crash threshold.

**Left edge — AGL bar:** Above Ground Level. Fills from the bottom, shrinks as you descend. The cyan bar draining to nothing is your final warning.

**Right edge — PROP bar:** propellant remaining. Fills from the bottom in amber, shifts to orange and then red as reserves run low. Tick marks at 10% intervals dim as the level drops below them.

**Left side — speed danger bar:** vertical bar that fills upward as your descent speed increases. Green when survivable, orange when marginal, red when a contact would be fatal.

**Right side — thrust bar:** bidirectional. The pivot point reflects the force ratio between the main engine and retro thrusters. Amber fills rightward from the pivot for main thrust, blue fills leftward for retro. Wider bar means more thrust.

**Bottom centre — level indicator:** current level number. The combo stash score floats above it when a chain is active.

---

## Scoring and progression

Each level completed records a best time. Lower is better.

Landing on the target pad unlocks the next level. Landing off-pad saves a best time but does not advance progression.

**Combo system:** landing successfully on successive levels without crashing builds a combo stash. The stash accumulates your run scores — each run scores 0 to 1000 points based on time (faster is better, ceiling one minute) and propellant remaining. The stash persists after closing the app. To continue a chain, you must play the next level in sequence — the start screen and game over screen both highlight the continuation level in gold and show a COMBO STREAK button when your stash is active.

Crashing while a combo is active saves the stash to your all-time combo high score if it is a new record. The combo high score appears at the top of the game over scores list.

---

## Levels

The world gets harder as levels increase. The target pad moves progressively further from your starting position and shrinks with each level. Rock count and roughness increase. From level 10, a UFO patrols the surface at your altitude and becomes faster with each successive level.

---

## IPK Sideload

Check the releases tab for the latest release including installable binary .ipk

---

## Building

Touchdown is built with the [AsteroidOS SDK](https://asteroidos.org/wiki/building-asteroidos/) using the standard CMake Qt5 workflow.

```bash
source /usr/local/oecore-x86_64/environment-setup-armv7vehf-neon-oe-linux-gnueabi
cmake -B build
cmake --build build
```

To build and deploy via Yocto:

```bash
bitbake asteroid-touchdown
scp tmp/deploy/ipk/armv7vehf-neon/asteroid-touchdown_+git-r1_armv7vehf-neon.ipk root@192.168.2.15:/home/root
ssh root@192.168.2.15 "opkg install --force-reinstall /home/root/asteroid-touchdown_+git-r1_armv7vehf-neon.ipk && systemctl restart user@1000"
```

The watch connects over USB at `192.168.2.15` via RNDIS. Run `sudo dhclient <interface>` on the host if the address is not assigned automatically.

---

## Tuning

All physics, viewport, and world generation constants are documented inline in the three QtObjects at the top of `src/main.qml`:

- `physics` — gravity, thrust forces, fuel drain rates, sensor smoothing, landing tolerances, UFO behaviour
- `viewport` — world dimensions, camera anchor positions, zoom limits
- `world` — rock count and geometry, pad sizing, landing gear offset

Changing any of these values requires a rebuild. No tuning values are hardcoded outside these blocks.

---

## Persistent data

Save data is stored at `~/.config/asteroid-touchdown/game.ini` on the watch. It contains highest unlocked level, per-level best times, combo high score, and active combo stash state. Delete this file to reset all progress.

---

## License

GPL-3.0-only. See [LICENSE](LICENSE).

© 2026 Timo Könnecke — [github.com/moWerk](https://github.com/moWerk)

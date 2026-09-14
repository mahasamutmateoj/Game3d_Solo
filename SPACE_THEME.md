# Orbital Outpost

The active scene is Scenes/demo_scene.tscn. Press F5 in Godot to play.
WASD: move. Space: jump; press again while moving in air for a double jump.
Mouse: look. Escape: release cursor. Left click: capture cursor. R: restart.
Collect five energy cells and reach the shuttle on the final platform.

Assets supplied by the project owner:
- Ultimate Space Kit-zip.zip: bases, outpost buildings, solar panels, radar, planets, rocks, shuttle and energy pickups.
- Rigged Astronaut by J-Toastie - 0oBRDJ9Zl9.zip: astronaut mesh and skeleton. The bundled animation is a single pose; walking and jumping use procedural rig movement.

Original starter credits retained: platform models by Rayyan Aziz; original character by GDQuest; programming and level design by Adil Shafiq / SD Studios. See LICENSE.md.

Original scenes, scripts and project settings are backed up outside this project at:
C:/Users/WINDOWS 10/Downloads/Platformer-before-space-20260914-180827

Validation: Godot 4.7 headless integration checks cover spawn, jump input, double jump input, fall respawn, all five pickups and extraction. Rendered preview checked with Forward+ on the local GPU.
The malformed walking.ogg metadata comment was repaired with an updated Ogg page checksum; encoded audio packets are unchanged. Starfield creation uses a fresh MultiMesh on each scene load; three repeated scene reloads pass without warnings or errors.

Motion update: four blue platforms move on gentle 10-13 second cycles and carry the player; their energy pickups follow. Double jump also works without movement. Jump poses blend smoothly without spinning or scaling the physics body. Verified rider drift below 0.02 units, jump-off, double-jump limit and mission completion.

Level 2 / Reactor Run:
- Finish level 1 with five cells, reach the shuttle to advance automatically.
- Scenes/level_2.tscn can also be opened and played with F6.
- Twelve smaller pads, five moving pads on 5-6 second cycles, eight cells, three timed laser gates and two solid cargo obstacles.
- Red laser is dangerous, amber warns before activation, dark laser is safe. All in-game labels, counters and instructions have been removed.
- The green midpoint pad saves a checkpoint. Falling or touching an active laser returns there; collected cells remain collected. R restarts the current level and resets the checkpoint and score.
- Pickups no longer shrink or chase the player on proximity. Only contact with the small pickup collider grants one point and removes the item.
- Integration checks cover proximity retention, contact collection, level transition, checkpoint activation, laser safe/danger phases, death respawn, eight pickups and final extraction. GPU render checked as well.

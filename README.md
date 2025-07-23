# The Witcher 3 | Smart Camera
A mod that controls the camera positioning during combat so that you don't have to
manage it yourself. Mainly aimed at gamepads.

# Showcase
 - [Reactive auto-center & organic camera shake demo](https://www.youtube.com/watch?v=sA1KzKzSfdI)
 - [Horse camera demo](https://www.youtube.com/watch?v=zfitqUrAA8U)
 - [Combat camera demo](https://www.youtube.com/watch?v=zfitqUrAA8U)

# Features
## Exploration camera
- Reactive auto-center: adjusts the rotation speed on sudden movements to aim at where Geralt is heading in a faster manner
- Left/Right/Back offsets: When heading off-camera, the mod will smoothly adjust the camera's position so you get to see more of the terrain ahead. For example going backward towards the camera will result in a zoom-out, increasing the distance between Geralt and the camera.
- Interaction focus: Whenever an interaction prompt is visible, to talk to NPCs, open doors, loot containers, etc... the camera will slowly pan towards it.
- Organic camera shake: Unlike most common camera shakes, the camera is synced to Geralt feet movements for an always immersive shake.
## Horse camera
- Organic camera shake: Unlike most common camera shakes, the camera is synced with Roach' head & Geralt torso movements
- Opt-in auto-center: The horse riding auto-center is only enabled if you line up the camera with Roach's current heading, once lined up the auto-center is enabled until new inputs from the player are received. This allows you to look at your surroundings when needed without having to fight against the auto-center.
- Dynamic positioning & speed: Depending on Roach' speed the camera will adjust its position, rotation speed and tilt for a camera style that is reminiscent of the E3 horse segment
## Combat camera
- Automatic targeting: The camera will automatically look at a position to ensure that all nearby targets are always visible on your screen.
- "Geralt in view" detection: The mod detects if Geralt is blocking the view and prevents you from seeing a nearby target, at which point it will adjust its position so the target is visible again
- Back-stabbing detection: If creatures are in Geralt's back, the camera will zoom-out to give you enough time to react
- Flying creature detection: If there is a flying creature nearby, the camera will adjust its position so you can see both the ground & the creature. Note that this behaviour may be limited by some settings.

# Installing
The mod is modular, you can choose to install the core version (the fight camera) without the horse camera. However it is not possible to do the opposite as the horse camera depends on the combat camera.

 - Download ["SmartCamera Core" and/or "SmartCamera Horse"](https://github.com/Aelto/tw3-smart-camera/releases)
 - Drop the release's `mods` and `bin` folders inside your Witcher 3 directory in order to merge them with your current mods/dlc/bin folders.
 - Merge the scripts with the script-merger of your choice
 - Launch the game, open the mod menu and apply the default preset
 - Load a save and confirm everything is working as intended

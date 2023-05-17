## DynamicSoundHandler

A module designed for realistic audio in roblox for run time use. Be aware that this isn't optimized as much as it could be.  
The reason there is no "stop sound" function is because this module was specifically designed for enhancing realism in gameplay. It's not recommended to use this module for all sounds.

> :warning: This module can only run on the **client** (LocalScript). Use RemoteEvents to replicate sound to all clients.

Credits to Sleitnick for his sound delay implementation and BoatBomber for his 3D sound implementation.

## API
`.New(Sounds:{[SoundName] = Sound:Sound}?)`  
Returns a new DynamicSoundHandler.

`:AddSound(Sounds:{[SoundName] = Sound:Sound})`  
Adds a sound to the sounds list.

`:RemoveSound(SoundNames{SoundName:string})`
Removes a sound from the sound list

`:Play(SoundName:string, Target:Vector3|Instance)`
Plays the sound with Reverb, Delay, and 3D sound effect applied in run time.

## How to use

```lua
local Sounds = {
    ["Gun Shot"] = Sound
 }
local DynamicSoundHandler = require([[path to the module]])
local SoundHandler = DynamicSoundHandler.New(Sounds)
SoundHandler:Play("Gun Shot", Vector3.new(0,5,0))
```

## DynamicSoundHandler

A module designed for realistic audio in roblox for run time use. Be aware that this isn't optimized as much as it could be.
Now the reason why it does not have "stop sound" function is because this was designed to be used for realism in gameplay, please only use this module for that.
Dont forget that this is only to be used in the client and not the server.

Credits to Sleitnick for his sound delay implementation and BoatBomber for his 3D sound implementation.

## API
`.New(Sounds:{[SoundName] = Sound:Sound}?)`
returns a new DynamicSoundHandler. Must be used in the client!

`:AddSound(Sounds:{[SoundName] = Sound:Sound})`
Adds sounds to the sounds list.

`:RemoveSound(SoundNames{SoundName:string})`
removes sounds from the sound list

`:Play(SoundName:string, Target:Vector3|Instance)`
plays the sound with Reverb, Delay, and 3D sound effect applied in run time.

## How to use

```lua
local Sounds = {
    ["Gun Shot"] = Sound
 }
local DynamicSoundHandler = require([[path to the module]])
local SoundHandler = DynamicSoundHandler.new(Sounds)
SoundHandler:Play("Gun Shot", Vector3.new(0,5,0))
```

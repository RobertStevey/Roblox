## R6IK

Simulates what a 2 joint inverse kinematics behaviour on an R6 Rig rather than the usual "point at" behaviour.

## API
`R6IK = R6IK.New(Rig:Model)`
  Constructs a new IK
  
`R6IK:ArmIK(Side : "Left" | "Right", Position:Vector3)`
  Automatically Solves the arm on the left or right side (given the 'Side' input) to reach the Position
  
`R6IK:LegIK(Side : "Left" | "Right", Position:Vector3)`
  Automatically Solves the leg on the left or right side (given the 'Side' input) to reach the Position

## How to use

It is quite simple to use this module. Here is a basic setup

```lua
local R6IK = [[path to the module]]
local Dummy = workspace.Rig

local IKController = R6IK.New(Dummy)
IKController:LegIK("Right", workspace.Target.Position)
IKController:ArmIK("Right", workspace.Target.Position)
```

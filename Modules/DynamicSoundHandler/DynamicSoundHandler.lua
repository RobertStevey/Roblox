local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Define settings for sound occlusion and 3D sound rendering
local Settings = {
	Occlusion = {
		-- Reflectivity values for different materials (higher value = more echo)
		DefaultReflect = 0.1,
		MaterialReflect = {
			Fabric = 0.1, Grass = 0.3, Sand = 0.35, 
			SmoothPlastic = 0.5, Plastic = 0.8, Cobblestone = 0.35, 
			Concrete = 0.3, Wood = 0.5, WoodPlanks = 0.5, 
			Brick = 0.3, Ice = 0.7, Metal = 0.6, Marble = 0.8, Granite = 0.8
		},
		Rays = 8, -- Number of rays to cast for occlusion checks
		Fallback = 0.1, -- Fallback reflectivity value
		FilterDescendants = {}, -- Objects to exclude from raycasting
		RayLength = 20, -- Maximum distance of each ray
		IgnoreWater = true, -- Whether to ignore water in raycasting
		MaxBounce = 3, -- Maximum number of ray bounces
	},
	DelaySound = {
		Speed = 343 -- Speed of sound for delay calculation (in m/s)
	},
	Debug = {
		Enabled = true, -- Toggle for debug mode
		Thickness = 5, -- Thickness of debug lines
		Colors = { -- Color coding for rays based on bounce count
			Default = BrickColor.Gray(),
			[0] = BrickColor.Green(), [1] = BrickColor.Yellow(), [2]= BrickColor.Red()
		}
	}
}

local DynamicSoundHandler = {}
DynamicSoundHandler.__index = DynamicSoundHandler

local Camera = workspace.CurrentCamera

function GetDirection(n, Length)
	local result = {}
	for i = 0, n do
		table.insert(result, Vector3.new(Random.new():NextNumber(-Length, Length),Random.new():NextNumber(-Length, Length),Random.new():NextNumber(-Length, Length)))
	end
	return result
end

local function Reflect(vector, normal)
	return -2 * vector:Dot(normal) * normal + vector
end

function Average(t:{number})
	local sum = 0
	for _,v in pairs(t) do -- Get the sum of all numbers in t
		sum = sum + v
	end
	return sum / #t
end

local function LerpNumber(a, b, t)
	return a + (b - a) * t
end

local function ValidateSoundID(SoundID : string)
	if SoundID:match("rbxassetid://") then
		return SoundID
	end
	return "rbxassetid://".. string.gsub(SoundID, "%D+", "")
end

function DynamicSoundHandler.New(Sounds)
	if RunService:IsServer() then
		error("DynamicSoundHandler must run on the client!")
		return
	end

	local self = setmetatable({}, DynamicSoundHandler)
	self.Sounds = {}
	self.PlayingSounds = {}
	if Sounds then self:AddSounds(Sounds) end

	return self
end


function DynamicSoundHandler:AddSounds(Sounds, Name)

	if typeof(Sounds) == "table" then
		for SoundName, Sound : Sound in pairs(Sounds) do
			if typeof(Sound) ~= "Instance" then 
				if type(Sound) ~= "string" then continue end
				local SoundID = ValidateSoundID(Sound)
				Sound = Instance.new("Sound")
				Sound.SoundId = SoundID
			end

			if not Sound:IsA("Sound") then 
				warn(Sound.Name.. " Is not a Sound Object or ID")
				continue 
			end

			self.Sounds[SoundName] = Sound
			--if self.Sounds[SoundName].Occlusion then
			local Reverb = Instance.new("ReverbSoundEffect")
			Reverb.DryLevel = 0
			Reverb.WetLevel = 0
			Reverb.DecayTime = 0
			Reverb.Density = 0
			Reverb.Diffusion = 0
			Reverb.Parent = Sound
			--end
			--if self.Sounds[SoundName].Sound3D then
			local Equalizer = Instance.new("EqualizerSoundEffect")
			Equalizer.LowGain	= 0
			Equalizer.MidGain	= 0
			Equalizer.HighGain	= 0
			Equalizer.Parent = Sound
			--end
		end
		return
	end

	if typeof(Sounds) ~= "Instance" then 
		if type(Sounds) ~= "string" then return end
		local SoundID = ValidateSoundID(Sounds)
		Sounds = Instance.new("Sound")
		Sounds.SoundId = SoundID
	end

	if not Sounds:IsA("Sound") then 
		warn(Sounds.Name.. " Is not a Sound Object or ID") 
		return
	end

	self.Sounds[Name] = Sounds
	--if self.Sounds[SoundName].Occlusion then
	local Reverb = Instance.new("ReverbSoundEffect")
	Reverb.DryLevel = 0
	Reverb.WetLevel = 0
	Reverb.DecayTime = 0
	Reverb.Density = 0
	Reverb.Diffusion = 0
	Reverb.Parent = Sounds
	--end
	--if self.Sounds[SoundName].Sound3D then
	local Equalizer = Instance.new("EqualizerSoundEffect")
	Equalizer.LowGain	= 0
	Equalizer.MidGain	= 0
	Equalizer.HighGain	= 0
	Equalizer.Parent = Sounds

end

function DynamicSoundHandler:RemoveSounds(SoundNames)

	if typeof(SoundNames) ~= "table" then
		if type(SoundNames) ~= "string" then return end
		local Sound = self.Sounds[SoundNames]
		if not Sound then warn(SoundNames, "Was not found in Sound table") return end

		Sound:FindFirstChild("ReverbSoundEffect"):Destroy()
		Sound:FindFirstChild("EqualizerSoundEffect"):Destroy()
		self:Stop(SoundNames)
		self.Sounds[SoundNames] = nil
		return
	end

	for SoundName, _ in pairs(SoundNames) do
		local Sound = self.Sounds[SoundName]
		if not Sound then warn(SoundName, "Was not found in Sound table") continue end

		Sound:FindFirstChild("ReverbSoundEffect"):Destroy()
		Sound:FindFirstChild("EqualizerSoundEffect"):Destroy()
		self:Stop(SoundName)
		self.Sounds[SoundName] = nil
	end
end


function DynamicSoundHandler:DebugRays(From, To, Distance, Direction, Color)
	local Line = Instance.new("LineHandleAdornment")
	Line.Color = Color or Settings.Debug.Colors.Default
	Line.Thickness = Settings.Debug.Thickness
	Line.Length = Distance
	Line.CFrame = CFrame.new(From)
	Line.CFrame = CFrame.lookAt(From, To)
	Line.Parent = workspace.Terrain
	Line.Adornee = workspace.Terrain

	task.spawn(function()
		RunService.RenderStepped:Wait()
		Line:Destroy()
	end)
end

function DynamicSoundHandler:_OcclusionRender(Sound:Sound,Position)
	local Counter = Settings.Occlusion.MaxBounce
	local Length = Settings.Occlusion.RayLength
	local Directions = GetDirection(Settings.Occlusion.Rays, Length)

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude
	RayParams.FilterDescendantsInstances = {Settings.Occlusion.FilterDescendants}
	RayParams.IgnoreWater = Settings.Occlusion.IgnoreWater

	local ReverbSoundEffect = Sound:FindFirstChild("ReverbSoundEffect") 

	local Hits = {}
	local AverageDistanceTable = {}
	local AverageCoefficientTable = {}
	local AveragebouncesTable = {}

	local function Fire(From, Direction, bounce)
		local bounce = bounce or 0
		if bounce <= Settings.Occlusion.MaxBounce then
			local RayResult = workspace:Raycast(From, Direction*Length, RayParams)


			if RayResult then
				local Position = RayResult.Position
				local Vector = Position-From
				local Ref = Reflect(Vector, RayResult.Normal)

				table.insert(AverageDistanceTable, Vector.Magnitude)
				table.insert(AverageCoefficientTable, Settings.Occlusion.MaterialReflect[RayResult.Material.Name])
				table.insert(Hits, {From, Position, Vector.Magnitude, Direction, Settings.Debug.Colors[bounce]})
				Fire(Position, Ref, bounce+1)
			else
				table.insert(AveragebouncesTable, bounce)
				table.insert(AverageCoefficientTable, Settings.Occlusion.Fallback)
			end
		else
			table.insert(AveragebouncesTable, Settings.Occlusion.MaxBounce)
		end
	end

	for i = 1, #Directions do
		Fire(Position, Directions[i], 0)
	end
	local MaxBounce = math.max(table.unpack(AveragebouncesTable))
	--[[local MaxCoefficient = math.max(table.unpack(AvarageCoefficient))
	local MaxDistance = math.max(table.unpack(AvarageDistance))
	]]

	local AverageDistance : number = Average(AverageDistanceTable)
	local AverageCoefficient : number = Average(AverageCoefficientTable)
	local Averagebounces : number = Average(AveragebouncesTable)

	local bounceFactor = Averagebounces / Settings.Occlusion.MaxBounce
	ReverbSoundEffect.DecayTime = LerpNumber(ReverbSoundEffect.DecayTime, ((bounceFactor * AverageCoefficient) * (AverageDistance * AverageCoefficient)), .2)
	ReverbSoundEffect.Density = LerpNumber(ReverbSoundEffect.Density, MaxBounce, .2)
	ReverbSoundEffect.Diffusion = LerpNumber(ReverbSoundEffect.Diffusion, 1 - Averagebounces/Settings.Occlusion.MaxBounce, .2)
	ReverbSoundEffect.WetLevel = LerpNumber(ReverbSoundEffect.WetLevel, (Averagebounces/MaxBounce) * AverageCoefficient, .2)
	if Settings.Debug.Enabled then
		for _, RayTable in Hits do
			self:DebugRays(RayTable[1], RayTable[2], RayTable[3], RayTable[4], RayTable[5])
		end
	end	
end

function DynamicSoundHandler:_Sound3DRender(Sound, Position)
	--credits to boatbomber on his 3D sound!
	local _, Listener = SoundService:GetListener()

	if Listener then
		if Listener:IsA("BasePart") then
			Listener = Listener.CFrame
		end
	else
		Listener = Camera.CFrame
	end


	local Facing = Listener.LookVector
	local Vector = (Position - Listener.Position).unit

	--Remove Y so up/down doesn't matter
	Facing	= Vector3.new(Facing.X,0,Facing.Z)
	Vector	= Vector3.new(Vector.X,0,Vector.Z)

	local Angle = math.acos(Facing:Dot(Vector)/(Facing.magnitude*Vector.magnitude))


	Sound.EqualizerSoundEffect.HighGain = -(25 * ((Angle/math.pi)^2))
end

function DynamicSoundHandler:_DelaySoundRender(Sound, Start, Position)
	if not Sound then return end
	if Sound.IsPlaying then return end
	--credits to Sleitnick for his delay sound module i found
	local Elapsed = os.clock() - Start
	local Distance = (Camera.CFrame.Position - Position).Magnitude
	local PlayTime = Distance / Settings.DelaySound.Speed
	
	if Elapsed >= PlayTime then
		Sound:Play()
	end
end

function DynamicSoundHandler:Play(SoundName, Target : BasePart|Vector3)
	local SoundInfo = self.Sounds[SoundName]
	if not SoundInfo then error(SoundName.. "not found in SoundTable") end

	local Sound : Sound = SoundInfo:Clone()
	local Connection

	local Start = os.clock()

	local function Update(Position)
		self:_DelaySoundRender(Sound, Start, Position)
		self:_Sound3DRender(Sound, Position)
		self:_OcclusionRender(Sound, Position)
	end

	if typeof(Target) == "Instance" and Target.Position then
		Sound.Parent = Target

		Connection = RunService.RenderStepped:Connect(function()
			Update(Target.Position)
		end)

		local function StopPlaying()
			Connection:Disconnect()
			Sound:Destroy()
		end

		local function OnDestroy()
			Connection:Disconnect()
		end

		Sound.Destroying:Once(OnDestroy)
		Sound.Ended:Once(StopPlaying)
		Sound.Stopped:Once(StopPlaying)
		return Sound
	elseif typeof(Target) == "Vector3" then
		local Emitter = Instance.new("Attachment")
		Emitter.Position = Target
		Emitter.Parent = workspace.Terrain
		Sound.Parent = Emitter
		Connection = RunService.RenderStepped:Connect(function()
			Update(Emitter.Position)
		end)

		local function OnDestroy()
			Connection:Disconnect()
			Emitter:Destroy()
		end

		local function StopPlaying()
			Connection:Disconnect()
			Emitter:Destroy()
		end

		Sound.Destroying:Once(OnDestroy)
		Sound.Ended:Once(StopPlaying)
		Sound.Stopped:Once(StopPlaying)
		return Sound, Emitter
	end
end

return DynamicSoundHandler

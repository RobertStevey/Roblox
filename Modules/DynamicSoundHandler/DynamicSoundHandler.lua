local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
-- only to be used for realism stuff

local Settings = {
	Occlusion = {
		--how reflective are the material? if it gets higher then it is more echo-ey
		MaterialReflect = {
			Fabric = 0.1,
			Grass = 0.3,
			Sand = 0.35,
			SmoothPlastic = 0.5,
			Plastic = 0.8,
			Cobblestone = 0.35,
			Concrete = 0.3,
			Wood = 0.5,
			WoodPlanks = 0.5,
			Brick = 0.3,
			Ice = 0.7,
			Metal = 0.6,
			Marble = 0.8,
			Granite = 0.8
		},
		Rays = 8,
		Fallback = 0.1,
		FilterDescendants = {},
		RayLength = 20,
		IgnoreWater = true,
		MaxBounce = 3,
	},
	DelaySound = {
		Speed = 343
	}
}

local DynamicSoundHandler = {}
DynamicSoundHandler.__index = DynamicSoundHandler

local Camera = workspace.Camera

function DynamicSoundHandler.New(Sounds)
	if RunService:IsServer() then
		error("DynamicSoundHandler must run on the client!")
		return
	end
	local self = {}
	self.Sounds = {}
	if Sounds then
		for SoundName, Sound in pairs(Sounds) do
			self.Sounds[SoundName] = Sound
			--if self.Sounds[SoundName].Occlusion then
			local Reverb = Instance.new("ReverbSoundEffect")
			Reverb.DryLevel = 6
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
	end
	self.PlayingSounds = {}
	return setmetatable(self, DynamicSoundHandler)
end

function GetDirection(n, Length)
	local result = {}
	for i = 0, n do
		table.insert(result, Vector3.new(Random.new():NextNumber(-Length, Length),Random.new():NextNumber(-Length, Length),Random.new():NextNumber(-Length, Length)))
	end
	return result
end

local function Reflect(vector, normal)
	return 2 * vector:Dot(normal) * normal + vector
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

function DynamicSoundHandler:AddSound(Sounds)
	for SoundName, Sound in pairs(Sounds) do
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
end

function DynamicSoundHandler:RemoveSound(SoundNames)
	for SoundName, Sound in pairs(SoundNames) do
		local Sound = self.Sounds[SoundName]
		Sound:FindFirstChild("ReverbSoundEffect"):Destroy()
		Sound:FindFirstChild("EqualizerSoundEffect"):Destroy()
		self.Sounds[SoundName] = nil
	end
end



function DynamicSoundHandler:_OcclusionRender(Sound:Sound,Position)
	local Counter = Settings.Occlusion.MaxBounce
	local Length = Settings.Occlusion.RayLength
	local Directions = GetDirection(Settings.Occlusion.Rays, Length)

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Blacklist
	RayParams.FilterDescendantsInstances = {Settings.Occlusion.FilterDescendants}
	RayParams.IgnoreWater = Settings.Occlusion.IgnoreWater
	
	local ReverbSoundEffect:ReverbSoundEffect = Sound:FindFirstChild("ReverbSoundEffect")

	local Hit = {}
	local AvarageDistance = {}
	local AvarageCoefficient = {}
	local Avaragebounces = {}
	
	local function Fire(From, Direction, bounce)
		local bounce = bounce or 0
		if bounce <= Settings.Occlusion.MaxBounce then
			local RayResult = workspace:Raycast(From, Direction*Length, RayParams)
			
			if RayResult then
				local Position = RayResult.Position
				local Vector = Position-From
				local Ref = Reflect(Vector, RayResult.Normal)

				table.insert(AvarageDistance, Vector.Magnitude)
				table.insert(AvarageCoefficient, Settings.Occlusion.MaterialReflect[RayResult.Material.Name])
				bounce = bounce
				Fire(Position, Ref, bounce+1)
			else
				table.insert(Avaragebounces, bounce)
				table.insert(AvarageCoefficient, Settings.Occlusion.Fallback)
			end
		else
			table.insert(Avaragebounces, Settings.Occlusion.MaxBounce)
		end
	end

	for i = 1, #Directions do
		Fire(Position, Directions[i], 0)
	end
	local MaxBounce = math.max(table.unpack(Avaragebounces))
	--[[local MaxCoefficient = math.max(table.unpack(AvarageCoefficient))
	local MaxDistance = math.max(table.unpack(AvarageDistance))
	]]AvarageDistance = Average(AvarageDistance)
	AvarageCoefficient = Average(AvarageCoefficient)
	Avaragebounces = Average(Avaragebounces)
	
	ReverbSoundEffect.DecayTime = LerpNumber(ReverbSoundEffect.DecayTime, ((Avaragebounces*AvarageCoefficient)*(AvarageDistance * AvarageCoefficient)), .2)
	ReverbSoundEffect.Density = LerpNumber(ReverbSoundEffect.Density, MaxBounce, .2)
	ReverbSoundEffect.Diffusion = LerpNumber(ReverbSoundEffect.Diffusion, 1 - Avaragebounces/Settings.Occlusion.MaxBounce, .2)
	ReverbSoundEffect.WetLevel = LerpNumber(ReverbSoundEffect.WetLevel, (Avaragebounces/MaxBounce) * AvarageCoefficient, .2)

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
	--credits to Sleitnick for his delay sound module i found
	local Elapsed = os.clock() - Start
	local Distance = (Camera.CFrame.Position - Position).Magnitude
	local PlayTime = Distance / Settings.DelaySound.Speed
	if Elapsed >= PlayTime then
		if not Sound.IsPlaying then
			Sound:Play()
		end
	end
end

function DynamicSoundHandler:Play(SoundName, Target:Vector3|Instance)
	local SoundInfo = self.Sounds[SoundName]
	local Sound = Instance.new("Sound")
	Sound = SoundInfo:Clone()
	local TargetType = typeof(Target)
	local Connection = nil
	local Start = os.clock()
	
	local function Update(Position)
		self:_DelaySoundRender(Sound, Start, Position)
		self:_Sound3DRender(Sound, Position)
		self:_OcclusionRender(Sound, Position)
	end
	
	if TargetType == "Instance" and Target.Position then
		Sound.Parent = Target
		Connection = RunService.RenderStepped:Connect(function()
			Update(Target.Position)
		end)
		Sound.Ended:Once(function()
			Connection:Disconnect()
			Sound:Destroy()
		end)
	elseif TargetType == "Vector3" then
		local Emitter = Instance.new("Attachment")
		Emitter.Position = Target
		Emitter.Parent = workspace.Terrain
		Sound.Parent = Emitter
		Connection = RunService.RenderStepped:Connect(function()
			Update(Target)
		end)
		Sound.Ended:Once(function()
			Connection:Disconnect()
			Sound:Destroy()
			Emitter:Destroy()
		end)
	end
end

return DynamicSoundHandler

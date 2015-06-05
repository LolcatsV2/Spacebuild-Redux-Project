AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

util.PrecacheSound( "Buttons.snd17" )

include('shared.lua')

--
local screens = {}

--[[
	--SetResourceAmount
	--PumpTurnOn
	--PumpTurnOff
]]

util.AddNetworkString("LSScreenTurnOn")				-- turn on screen
util.AddNetworkString("LSScreenTurnOff")			-- turn off screen
util.AddNetworkString("AddLSScreenResource")		-- add a resource to screen
util.AddNetworkString("RemoveLSSCreenResource")		-- remove a resource from screen
util.AddNetworkString("LS_Open_Screen_Menu")		-- open the screen menu
util.AddNetworkString("LS_Add_ScreenResource")		-- add resources to the screen for drawing
util.AddNetworkString("LS_Remove_ScreenResource")	-- remove resources from screen for drawing

local function TurnOnScreen()

	local ent = net.ReadEntity()
	
	if ent.IsScreen and ent.TurnOn then
		ent:TurnOn()
	end
end
net.Receive("LSScreenTurnOn", TurnOnScreen)  

local function TurnOffScreen()
	
	local ent = net.ReadEntity()
	
	if ent.IsScreen and ent.TurnOff then
		ent:TurnOff()
	end
end
net.Receive("LSScreenTurnOff", TurnOffScreen)  

local function AddResource()

	local ent = net.ReadEntity()
	local str = net.ReadString()
	
	if ent.IsScreen and ent.resources then
		if not table.HasValue(ent.resources, str) then
			table.insert(ent.resources, str)
			net.Start("LS_Add_ScreenResource")
				net.WriteEntity(ent)
				net.WriteString(str)
			net.Broadcast()
		end
	end
end
net.Receive("AddLSScreenResource", AddResource)  

local function RemoveResource(ply, com, args)
	
	local ent = net.ReadEntity()
	local str = net.ReadString()
	
	if ent.IsScreen and ent.resources then
		if table.HasValue(ent.resources, str) then
			for k, v in pairs(ent.resources) do
				if v == str then
					table.remove(ent.resources, k)
					break
				end
			end
			net.Start("LS_Remove_ScreenResource")
				net.WriteEntity(ent)
				net.WriteString(str)
			net.Broadcast()
		end
	end
end
net.Receive("RemoveLSScreenResource", RemoveResource)  

local function UserConnect(ply)
	if table.Count(screens) > 0 then
		for k, v in pairs(screens) do
			if IsValid(v) then
				if table.Count(v.resources) > 0 then
					for l, w in pairs(v.resources) do
						net.Start("LS_Add_ScreenResource")
							net.WriteEntity(v)
							net.WriteString(w)
						net.Send(ply)
					end
				end
			end
		end
	end
end
hook.Add("PlayerInitialSpawn", "LS_Screen_info_Update", UserConnect)
--

local Energy_Increment = 4

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self.Active = 0
	self.damaged = 0
	self.resources = {}
	if not (WireAddon == nil) then
		self.WireDebugName = self.PrintName
		self.Inputs = Wire_CreateInputs(self, { "On" })
		self.Outputs = Wire_CreateOutputs(self, { "On" })
	else
		self.Inputs = {{Name="On"},{Name="Overdrive"}}
	end
	table.insert(screens, self)
end

function ENT:TurnOn()
	if self.Active == 0 then
		self:EmitSound( "Buttons.snd17" )
		self.Active = 1
		self:SetOOO(1)
		if not (WireAddon == nil) then Wire_TriggerOutput(self, "On", 1) end
	end
end

function ENT:TurnOff(warn)
	if self.Active == 1 then
		if (!warn) then self:EmitSound( "Buttons.snd17" ) end
		self.Active = 0
		self:SetOOO(0)
		if not (WireAddon == nil) then
			Wire_TriggerOutput(self, "On", 0)
		end
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "On") then
		if value == 0 then
			self:TurnOff()
		elseif value == 1 then
			self:TurnOn()
		end
	end
end

--use this to set self.active
--put a self:TurnOn and self:TurnOff() in your ent
--give value as nil to toggle
--override to do overdrive
--AcceptInput (use action) calls this function with value = nil
function ENT:SetActive( value, caller )
	net.Start("LS_Open_Screen_Menu")
		net.WriteEntity(self)
	net.Send(caller)
end

function ENT:Damage()
	if (self.damaged == 0) then self.damaged = 1 end
end

function ENT:Repair()
	self.BaseClass.Repair(self)
	self:SetColor(Color(255, 255, 255, 255))
	self.damaged = 0
end

function ENT:Destruct()
	if CAF and CAF.GetAddon("Life Support") then
		CAF.GetAddon("Life Support").Destruct( self, true )
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if (self.Active == 1) then
		if (self:GetResourceAmount("energy") < math.Round(Energy_Increment * self:GetMultiplier())) then
			self:EmitSound( "common/warning.wav" )
			self:TurnOff(true)
		else
			self:ConsumeResource("energy", math.Round(Energy_Increment * self:GetMultiplier()))
		end
	end
	
	self:NextThink(CurTime() + 1)
	return true
end


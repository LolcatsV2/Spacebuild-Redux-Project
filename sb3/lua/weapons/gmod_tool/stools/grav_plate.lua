
TOOL.Category = 'Life Support'
TOOL.Name = '#Gravity Plating'
TOOL.Command = nil
TOOL.ConfigName = ''
if (CLIENT and GetConVarNumber("CAF_UseTab") == 1) then TOOL.Tab = "Custom Addon Framework" end

-- Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then
	language.Add( "tool.grav_plate.name", "Gravity Plating" )
	language.Add( "tool.grav_plate.desc", "Enables walking on a prop even in low-to-zero gravity." )
	language.Add( "tool.grav_plate.0", "Left Click to attach Gravity Plating.  Right Click to take it off." )
end

local function SaveGravPlating( Player, Entity, Data )
	if not SERVER then return end
	if Data.GravPlating then
		Entity.grav_plate = 1
		if ( SERVER ) then
			Entity.EntityMods = Entity.EntityMods or {}
			Entity.EntityMods.GravPlating = Data
		end
	else
		Entity.grav_plate = nil
		if ( SERVER ) then
			if Entity.EntityMods then Entity.EntityMods.GravPlating = nil end
		end	
	end
	duplicator.StoreEntityModifier( Entity, "gravplating", Data )
end
duplicator.RegisterEntityModifier( "gravplating", SaveGravPlating )

function TOOL:LeftClick( trace )
	if trace.Entity then
		if !IsValid(trace.Entity) or trace.Entity:IsPlayer() or trace.HitWorld or trace.Entity:IsNPC() then
			return false
		end
	end
	if CLIENT then return true end
	local gravplating = 1
	SaveGravPlating(self:GetOwner(),trace.Entity,{ GravPlating = gravplating })
	self:GetOwner():SendLua( "GAMEMODE:AddNotify('Surface has received Gravity Plating.', NOTIFY_GENERIC, 7);" )
	return true
end

function TOOL:RightClick( trace )
	if trace.Entity then
		if !IsValid(trace.Entity) or trace.Entity:IsPlayer() or trace.HitWorld or trace.Entity:IsNPC() then
			return false
		end
	end
	if CLIENT then return true end
	local gravplating = 0
	SaveGravPlating(self:GetOwner(),trace.Entity,{ GravPlating = gravplating })
	self:GetOwner():SendLua( "GAMEMODE:AddNotify('Gravity Plating removed from surface.', NOTIFY_GENERIC, 7);" )
	return true
end

function TOOL.BuildCPanel( CPanel )
	-- HEADER
	CPanel:AddControl( "Header", { Text = "#tool.grav_plate.name", Description	= "#tool.grav_plate.desc" }  )
end


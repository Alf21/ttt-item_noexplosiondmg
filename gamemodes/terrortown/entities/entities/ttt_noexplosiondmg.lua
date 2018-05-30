if SERVER then
	AddCSLuaFile()
end

EQUIP_NOEXPLOSIONDMG = (GenerateNewEquipmentID and GenerateNewEquipmentID()) or 16

local noexplosiondmg = {
	id = EQUIP_NOEXPLOSIONDMG,
	loadout = false,
	type = "item_passive",
	material = "vgui/ttt/icon_noexplosiondmg",
	name = "No Fall Damage",
	desc = "You don't get explosiondamage anymore!",
	hud = true
}

local flag = {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}

local detectiveCanUse = CreateConVar("ttt_noexplosiondmg_det", 1, flag, "Should the Detective be able to buy NoExplosionDamage.")
local traitorCanUse = CreateConVar("ttt_noexplosiondmg_tr", 1, flag, "Should the Traitor be able to use buy NoExplosionDamage.")

if detectiveCanUse:GetBool() then
	table.insert(EquipmentItems[ROLE_DETECTIVE], noexplosiondmg)
end

if traitorCanUse:GetBool() then
	table.insert(EquipmentItems[ROLE_TRAITOR], noexplosiondmg)
end

if SERVER then
	hook.Add("ScalePlayerDamage", "TTTNoExplosionDmg", function(ply, hitgroup, dmginfo)
        if target:IsActive() and target:HasEquipmentItem(EQUIP_NOEXPLOSIONDMG) then
            if dmginfo:IsExplosionDamage() then
				dmginfo:ScaleDamage(0)
			end
        end
    end)

    hook.Add("EntityTakeDamage", "TTTNoExplosionDmg", function(target, dmginfo)
        if not target or not IsValid(target) or not target:IsPlayer() then return end
    
        if target:IsActive() and target:HasEquipmentItem(EQUIP_NOEXPLOSIONDMG) then
            if dmginfo:IsExplosionDamage() then -- check its explosion dmg.
                dmginfo:ScaleDamage(0) -- no dmg
            end
        end
    end)
else
	-- feel for to use this function for your own perk, but please credit Zaratusa
	-- your perk needs a "hud = true" in the table, to work properly
	local defaultY = ScrH() / 2 + 20
	
	local function getYCoordinate(currentPerkID)
		local amount, i, perk = 0, 1
		local client = LocalPlayer()
		
		while i < currentPerkID do
			local role = client:GetRole()

			if role == ROLE_INNOCENT then -- he gets it in a special way
				if GetEquipmentItem(ROLE_TRAITOR, i) then
					role = ROLE_TRAITOR -- Temp fix what if a perk is just for Detective
				elseif GetEquipmentItem(ROLE_DETECTIVE, i) then
					role = ROLE_DETECTIVE
				end
			end

			perk = GetEquipmentItem(role, i)

			if istable(perk) and perk.hud and client:HasEquipmentItem(perk.id) then
				amount = amount + 1
			end
			
			i = i * 2
		end

		return defaultY - 80 * amount
	end

	local yCoordinate = defaultY
	
	-- best performance, but the has about 0.5 seconds delay to the HasEquipmentItem() function
	hook.Add("TTTBoughtItem", "TTTNoExplosionDmg", function()
		if LocalPlayer():HasEquipmentItem(EQUIP_NOEXPLOSIONDMG) then
			yCoordinate = getYCoordinate(EQUIP_NOEXPLOSIONDMG)
		end
	end)
	
	local material = Material("vgui/ttt/perks/hud_noexplosiondmg.png")
	
	hook.Add("HUDPaint", "TTTNoExplosionDmg", function()
		if LocalPlayer():HasEquipmentItem(EQUIP_NOEXPLOSIONDMG) then
			surface.SetMaterial(material)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(20, yCoordinate, 64, 64)
		end
	end)

	hook.Add("TTTBodySearchEquipment", "TTTNoExplosionDmgCorpseIcon", function(search, eq)
		search.eq_noexplosiondmg = util.BitSet(eq, EQUIP_NOEXPLOSIONDMG)
	end)

	hook.Add("TTTBodySearchPopulate", "TTTNoExplosionDmgCorpseIcon", function(search, raw)
		if not raw.eq_noexplosiondmg then return end

		local highest = 0
		
		for _, v in pairs(search) do
			highest = math.max(highest, v.p)
		end

		search.eq_noexplosiondmg = {img = "vgui/ttt/icon_noexplosiondmg", text = "They didn't got explosiondamage.", p = highest + 1}
	end)
end

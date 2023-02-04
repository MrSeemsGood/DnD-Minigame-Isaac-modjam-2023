local cnctable = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

--Thank you budj for providing this old-ass hack I used in AB+ Eevee
---@param pos Vector
local function RemoveRecentRewards(pos)
	for _, pickup in ipairs(Isaac.FindByType(5, -1, -1)) do
		if pickup.FrameCount <= 1 and pickup.SpawnerType == 0
			and pickup.Position:Distance(pos) <= 20 then
			pickup:Remove()
		end
	end

	for _, trollbomb in ipairs(Isaac.FindByType(4, -1, -1)) do
		if (trollbomb.Variant == 3 or trollbomb.Variant == 4)
			and trollbomb.FrameCount <= 1 and trollbomb.SpawnerType == 0
			and trollbomb.Position:Distance(pos) <= 20 then
			trollbomb:Remove()
		end
	end
end

---@param slot Entity
local function YouFuckedUp(slot)
	local beggarRNG = RNG()
	beggarRNG:SetSeed(slot.InitSeed, 0)
	for _ = 1, 2 do
		local enemyToSpawn = g.AllDungeonEnemies[beggarRNG:RandomInt(#g.AllDungeonEnemies) + 1]
		local type = enemyToSpawn[1]
		local variant = enemyToSpawn[2]
		local subType = enemyToSpawn[3] ~= nil and enemyToSpawn[3] or 0
		g.game:Spawn(type, variant, g.game:GetRoom():FindFreeTilePosition(slot.Position, 150 ^ 2),
			Vector.Zero, slot, subType, slot.InitSeed)
	end
end

---@param slot Entity
local function OverrideExplosionHack(slot)
	local s = slot:GetSprite()
	local bombed = slot.GridCollisionClass == EntityGridCollisionClass.GRIDCOLL_GROUND
	if not bombed or s:GetAnimation() == "Bombed" then return end

	RemoveRecentRewards(slot.Position)
	s:Play("Bombed", true)
	slot.Friction = 0

	if slot.Variant == g.CNC_BEGGAR then
		YouFuckedUp(slot)
	end
end

---@param slot Entity
local function SpawnRewards(slot)
	local items = {
		CollectibleType.COLLECTIBLE_D6,
		CollectibleType.COLLECTIBLE_YUM_HEART,
		CollectibleType.COLLECTIBLE_LUCKY_FOOT,
		CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL,
		CollectibleType.COLLECTIBLE_D20,
		CollectibleType.COLLECTIBLE_D8,
		CollectibleType.COLLECTIBLE_D10,
		CollectibleType.COLLECTIBLE_D12,
		CollectibleType.COLLECTIBLE_BERSERK,
		CollectibleType.COLLECTIBLE_MONSTER_MANUAL,
	}
	local itemPool = VeeHelper.GetCustomItemPool(items)
	local beggarRNG = RNG()
	beggarRNG:SetSeed(slot.InitSeed, 0)
	local pos = g.game:GetRoom():FindFreePickupSpawnPosition(slot.Position, 1)
	g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, Vector.Zero, slot,
		itemPool[beggarRNG:RandomInt(#itemPool) + 1], slot.InitSeed)

	for name, num in pairs(g.GameState.PickupsCollected) do
		if num > 0 then
			local nameToType = {
				["Keys"] = { PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL },
				["Bombs"] = { PickupVariant.PICKUP_BOMB, BombSubType.BOMB_NORMAL },
				["Coins"] = { PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY },
			}
			if nameToType[name] then
				local pos = g.game:GetRoom():FindFreePickupSpawnPosition(slot.Position, 1)
				g.game:Spawn(EntityType.ENTITY_PICKUP, nameToType[name][1], pos, Vector.Zero, slot, nameToType[name][2],
					slot.InitSeed)
			end
			g.GameState.PickupsCollected[name] = 0
		end
	end
end

function cnctable:slotUpdate()
	for _, slot in pairs(Isaac.FindByType(EntityType.ENTITY_SLOT, g.CNC_EMPTY_TABLE)) do
		OverrideExplosionHack(slot)

		slot:GetSprite():Play('EmptyTable')
	end

	for _, slot in pairs(Isaac.FindByType(EntityType.ENTITY_SLOT, g.CNC_BEGGAR)) do
		OverrideExplosionHack(slot)
		local s = slot:GetSprite()
		local d = slot:GetData()

		if not s:IsPlaying("Bombed") then --Or whatever the name you want to be
			print(d.TimesEndAnimLooped)
			if d.TimesEndAnimLooped then
				if s:GetFrame() == 0 then
					if d.TimesEndAnimLooped < 3 then
						d.TimesEndAnimLooped = d.TimesEndAnimLooped + 1
						--print("Loopy")
					else
						if s:IsPlaying("Winner") then
							SpawnRewards(slot)
						end

						Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, slot.Position, Vector.Zero, slot)
						slot:Remove()
						local empty = Isaac.Spawn(6, g.CNC_EMPTY_TABLE, 0, slot.Position, Vector.Zero, nil)
					end
				end
			end

			if g.GameState.HasLost then
				--print("You lost")
				s:Play("Loser", true)
				g.GameState.HasLost = false
				d.TimesEndAnimLooped = 0
			elseif g.GameState.HasWon then
				--print("You won!")
				s:Play("Winner", true)
				g.GameState.HasWon = false
				d.TimesEndAnimLooped = 0
			end

			if s:IsFinished('Hide') then
				s:Play('IdleHidden', true)
			elseif s:IsFinished('Show') then
				s:Play('IdleShown', true)
			end

			if s:IsPlaying("Winner") or s:IsPlaying("Loser") or s:GetAnimation() == "EmptyTable" then return end

			local near = #Isaac.FindInRadius(slot.Position, 80, EntityPartition.PLAYER)
			if near > 0
				and (s:IsPlaying('Hide') or s:GetAnimation() == 'IdleHidden') then
				s:Play('Show', true)
			elseif near == 0
				and (s:IsPlaying('Show') or s:GetAnimation() == 'IdleShown') then
				s:Play('Hide', true)
			end
		end
	end
end

---@param player EntityPlayer
---@param collider Entity
---@param _ any
function cnctable:onPlayerCollision(player, collider, _)
	local s = collider:GetSprite()
	if collider.Type == EntityType.ENTITY_SLOT
		and collider.Variant == g.CNC_BEGGAR
		and not g.GameState.ShouldStart
		and not g.GameState.GameActive
		and not (g.GameState.HasLost or g.GameState.HasWon)
		and collider.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_GROUND
		and not (s:IsPlaying("Winner") or s:IsPlaying("Loser") or s:GetAnimation() == "EmptyTable")
	then
		g.GameState.BeggarInitSeed = collider.InitSeed
		g.GameState.ShouldStart = true
	end
end

return cnctable

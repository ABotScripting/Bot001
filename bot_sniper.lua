local utils = require(GetScriptDirectory().."/utils");

-- Items


-- Abilities
local SKILL_Q = 'sniper_shrapnel'
local SKILL_W = 'sniper_headshot'
local SKILL_E = 'sniper_take_aim'
local SKILL_R = 'sniper_assassinate'

local TALENT1 = 'talent_damage_20'
local TALENT2 = 'special_bonus_cooldown_reduction_15'
local TALENT3 = 'special_bonus_unique_sniper_1' 
local TALENT4 = 'special_bonus_attack_speed_40'
local TALENT5 = 'special_bonus_unique_sniper_2'
local TALENT6 = 'special_bonus_unique_sniper_3'
local TALENT7 = 'special_bonus_attack_range_125'
local TALENT8 = 'special_bonus_unique_sniper_4'

--Skill Lvls
local ultLvl = 0;
local eLvl = 0;

local nextAbility = 1;
local nextItem = 1;
local atkRange = 550;
local targetLoc = GetLocationAlongLane(LANE_MID, .525);
local sightings;
local currentLane = "mid";
local laneFront;


local SniperAbilityPriority = {
    --SKILL_W,    SKILL_E,    SKILL_E,    SKILL_W,    SKILL_E,
    --SKILL_R,    SKILL_W,    SKILL_E,    SKILL_W,	
	TALENT1,
    SKILL_Q,    SKILL_R,    SKILL_Q,    SKILL_Q,	--TALENT4,
    SKILL_Q,    SKILL_R,	--TALENT6,	TALENT7
}

local itemPurchase = {
	"item_circlet",
	"item_slippers",
	"item_recipe_wraith_band",
	"item_tango",
	"item_blight_stone",
	"item_blades_of_attack",
	"item_blades_of_attack",
	"item_boots",
	"item_mithril_hammer",
	"item_mithril_hammer",
	"item_gloves",
	"item_mithril_hammer",
	"item_recipe_maelstrom",
	"item_broadsword",
	"item_blades_of_attack",
	"item_recipe_crystalys"
}
	
function Think()
	local self = GetBot();
	local time = DotaTime();
	
	if (sightings == nil or #sightings == 0) then
	else
		UpdateSightings();
	end;
	
	UpdateLaneFront();
	
	if (self:IsUsingAbility() or self:IsChanneling()) then
		print("Using ability...")
	elseif(self:IsAlive() and time > -85) then
		--print("Running...");
		
		-- Itmes
		Purchase();
		
		-- Abilities
		LevelUp();
		
		-- Motion
		if(time < 0) then
			--print("Pre-GameTime: " .. time);
			MoveToLane();
		else 
			--print("Post GameTime: " .. time);
			--MoveToLane();
			
			local atkOrder = 0;
			if (false) then -- adjust to not be sitting in enemy creeps
			end
			
			atkOrder = atkOrder + DenyCreeps();
			atkOrder = atkOrder + HitHero();	
			atkOrder = atkOrder + LastHit();
			atkOrder = atkOrder + UltHero();
			if (atkOrder == 0) then 
				atkOrder = atkOrder + MoveAtkHero();
			end
			
			if (atkOrder == 0) then 
				
				MoveBehindCreeps();
			end
		end
	end;
end

function MoveToLane()--Lane)
	local self = GetBot();
	--targetLoc = GetLocationAlongLane(LANE_MID, .525);
	--GetFrontTower(Lane);
	self:Action_MoveToLocation(targetLoc);
end

function LevelUp()
	local self = GetBot();
	if(#SniperAbilityPriority == 0 or SniperAbilityPriority[nextAbility] == nil) then -- If skill list empty
		print("Ability List Format Error")
		return
	end
	local nextSkill = self:GetAbilityByName(SniperAbilityPriority[nextAbility]);
	print(nextSkill:GetName());
	if(nextSkill:CanAbilityBeUpgraded() and (self:GetAbilityPoints() > 0)) then
		print("I have ability points available, Lvl:" .. self:GetLevel() .. ". Next ability: " .. SniperAbilityPriority[1])
		self:ActionImmediate_LevelAbility(SniperAbilityPriority[nextAbility]);
		UpdateSkillLvls();
		nextAbility = nextAbility + 1;
	end
end

function Purchase()
	local self = GetBot();
	local savings = self:GetGold();
	
	if (savings >= GetItemCost(itemPurchase[nextItem])) then
		self:ActionImmediate_PurchaseItem(itemPurchase[nextItem]);
		-- If dragonLance or hurricane pike (not from already purchased dragon lance)
		-- and is equipped then update atk range
		nextItem = nextItem + 1;
		-- Courier delivery
		local teamCourier = GetCourier(self:GetTeam()-2);
		self:ActionImmediate_Courier(teamCourier, COURIER_ACTION_TAKE_AND_TRANSFER_ITEMS);
	end
end

function UpdateSightings()
	for i, s in ipairs(sightings) do
		if (s[2] == 0) then
		else 
			sightings[i][2] = sightings[i][2] -1;
		end;
	end
end

function UpdateLaneFront()
	local self = GetBot();
	if (self:GetTeam() == 2) then
		laneFront = GetLaneFrontLocation(TEAM_RADIANT, LANE_MID, 0);
	end
	if (self:GetTeam() == 3) then
		laneFront = GetLaneFrontLocation(TEAM_DIRE, LANE_MID, 0);
	end
	--print("Lane Front: ");
	--print(laneFront);
	self:ActionImmediate_Ping(laneFront[1], laneFront[2], true);
end

function MoveBehindCreeps() 
	local self = GetBot();
	--print("Moving behind creeps");
	if (self:GetTeam() == 2) then
		targetLoc = GetLaneFrontLocation(TEAM_RADIANT, LANE_MID, -(atkRange-(200 + 50*eLvl)));
	end
	if (self:GetTeam() == 3) then
		targetLoc = GetLaneFrontLocation(TEAM_DIRE, LANE_MID, -(atkRange-200));
	end
	-- TODO Seige creeps countas front
	-- TODO Face any nearby enemy creeps
	self:Action_MoveToLocation(targetLoc);
	self:ActionImmediate_Ping(targetLoc[1], targetLoc[2], true);
end

function UpdateRange()
	if (SniperAbilityPriority[nextAbility] == SKILL_E) then
		atkRange = atkRange + 100;
		print("Range increased to " .. atkRange);
	end
end

function UpdateSkillLvls()
	local self = GetBot();
	local skillUpdated = SniperAbilityPriority[nextAbility];
	
	if (skillUpdated == 'sniper_shrapnel') then
	elseif (skillUpdated == 'sniper_headshot') then	
	elseif (skillUpdated == 'sniper_take_aim') then 
		UpdateRange();
		eLvl = eLvl + 1;
	elseif (skillUpdated == 'sniper_assassinate') then
		ultLvl = ultLvl+1;
	else
		print("Talent Updated");
	end;
end                     
                        
function DenyCreeps()   
	local self = GetBot();
	local denyableCreeps = self:GetNearbyLaneCreeps(atkRange, false);
	local ret = 0;

	-- TODO Predict nearby enemy creeps' dmg to target
	-- TODO factor in armor
	if (#denyableCreeps > 0) then
		for i, u in ipairs(denyableCreeps) do
			if (denyableCreeps[i]:GetHealth() < self:GetAttackDamage()) then
				--print(denyableCreeps[i]:GetUnitName());
				--print("Unit Health: " .. denyableCreeps[i]:GetHealth() .. " Attack Damage: " .. self:GetAttackDamage());
				self:Action_AttackUnit(denyableCreeps[i], true);
				ret = 1;
			end
		end
	end
	
	return ret;
end

function HitHero()
	local self = GetBot();
	local attackableHeroes = self:GetNearbyHeroes(atkRange, true, BOT_MODE_NONE);
	local aggroCreeps = self:GetNearbyLaneCreeps(500, true);
	local ret = 0;
	
	-- TODO go toward heros if creeps are far enough away
	if (#attackableHeroes > 0) then
		print("Unit in sight");
		if (sightings == nil) then
		else
			for i, u in ipairs(attackableHeroes) do
				for i, s in ipairs(sightings) do
					if (u:GetUnitName() == s[1]) then
						print("Unit in sightings");
						if (s[2] == 0) then
							sightings[1][2] = 60;
							self:ActionImmediate_Chat(u:GetUnitName() .. " is " .. currentLane , false);
						end
					else 
						sightings[#sightings+1] = {u:GetUnitName(), 60}
						self:ActionImmediate_Chat(u:GetUnitName() .. " is " .. currentLane , false);
					end;
				end
			end
		end
		if (#aggroCreeps == 0) then
			self:Action_AttackUnit(attackableHeroes[1], true);
			ret = 1;
			-- TODO fix
			-- go to attack, when atack finished sf close enough to prompt again
		else 
			MoveBehindCreeps();
		end;
	end
	
	return ret;
end

function MoveAtkHero()
	local self = GetBot();
	local heroes = self:GetNearbyHeroes(1500, true, BOT_MODE_NONE);
	local creeps = self:GetNearbyLaneCreeps(1500, true);
	local closestHero;
	local closestDistance;
	local closestDistanceCreep;
	local ret = 0;
	
	if(#heroes > 0) then
		closestHero = heroes[1];
		closestDistance = GetUnitToUnitDistance(self, heroes[1]);
		for i, e in ipairs(heroes) do
			if(GetUnitToUnitDistance(self, e) < closestDistance) then
				closestHero = e;
				closestDistance = GetUnitToUnitDistance(self, e);
			end
		end
	end
	
	if(#creeps > 0 and #heroes > 0) then
		closestDistanceCreep = GetUnitToUnitDistance(self, creeps[1]);
		for i, c in ipairs(creeps) do
			if(GetUnitToUnitDistance(self, c) < closestDistanceCreep) then
				closestDistanceCreep = GetUnitToUnitDistance(self, c);
			end
		end
		if ((closestDistance-closestDistanceCreep)+500 < atkRange) then
			self:Action_AttackUnit(closestHero, true);
			ret = 1
		end
	else
		if(#heroes > 0) then
			self:Action_AttackUnit(closestHero, true);
			ret = 1
		end
	end
	return ret;
end

function UltHero() 
	local self = GetBot();
	local ultableHeroes = self:GetNearbyHeroes(1500 + (ultLvl*500), true, BOT_MODE_NONE);
	local aggroCreeps = self:GetNearbyLaneCreeps(500, true);
	local ret = 0;
	
	if (ultLvl > 0 and self:GetAbilityByName(SKILL_R):IsCooldownReady()) then -- if ult available
		for i, enemy in ipairs(ultableHeroes) do
			if(enemy:GetHealth() < 250) then -- if hero is below health threshold
				print("Use ability");
				self:Action_UseAbilityOnEntity(self:GetAbilityByName(SKILL_R), target);
			end;
		end;
	end;
	return ret;
end;

function LastHit()
	local self = GetBot();
	local attackableCreeps = self:GetNearbyLaneCreeps(atkRange, true);
	local ret = 0;

	-- TODO Predict nearby friendly creeps' dmg to target
	-- TODO factor in armor
	if (#attackableCreeps > 0) then
		for i, u in ipairs(attackableCreeps) do
			if (attackableCreeps[i]:GetHealth() < self:GetAttackDamage()) then
				--print(attackableCreeps[i]:GetUnitName());
				--print("Unit Health: " .. attackableCreeps[i]:GetHealth() .. " Attack Damage: " .. self:GetAttackDamage());
				self:Action_AttackUnit(attackableCreeps[i], true);
				ret = 1;
			end
		end
	end
	
	return ret;
end

function CreepBlock()

end
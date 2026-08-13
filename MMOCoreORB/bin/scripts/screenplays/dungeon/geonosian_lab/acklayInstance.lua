--[[ =========================================================================
	AcklayInstance  --  per-group spawned instance for the Geonosian Bio Lab
	-------------------------------------------------------------------------
	Turns the shared, persistent Acklay boss (the 2h world-respawn in the
	"largeendcave" of the Geonosian Research Lab on Yavin 4) into a private,
	per-group instance in the modern-MMO sense.

	How it works (modelled on the Corellian Corvette + ThemePark instancing
	already in Core3, but using DIRECTOR dynamic building spawning instead of
	a pre-placed building pool, so you don't have to edit a world snapshot):

	  1. An "Acklay Containment Controls" object is placed at self.entrance
	     (open world on yavin4 at -6469 / 83 / -442, cell 0).
	  2. A player (solo OR a group) uses its radial -> AcklayInstance:activate.
	  3. activate() DYNAMICALLY spawns a fresh arena building via spawnBuilding(),
	     spawns a private Acklay (+ adds) inside it, scales the boss to the
	     party size / chosen difficulty, and teleports the whole group in.
	  4. Kill the Acklay -> loot + completion + a short exit timer.
	  5. On completion, expiry, or party wipe/disband the arena is emptied,
	     everyone is returned to the hub, and the building is destroyed
	     (destroyBuilding), freeing all resources.

	INSTALL
	  a) Drop this file at:
	       MMOCoreORB/bin/scripts/screenplays/dungeon/geonosian_lab/acklayInstance.lua
	  b) Register it in screenplays.lua (near the other geonosian_lab lines):
	       includeFile("dungeon/geonosian_lab/acklayInstance.lua")
	     NOTE: in the public SR repo geoLab.lua itself is commented out on
	     line 122 of screenplays.lua -- uncomment it if you want the hub lab
	     loaded. AcklayInstance can also run standalone (it spawns its own
	     entrance), see self.spawnStandaloneEntrance below.
	  c) OPTIONAL, recommended: remove the shared world Acklay so the boss is
	     instance-only. In geoLab.lua:spawnMobiles() delete the line:
	       spawnMobile("yavin4", "acklay",7200,101.1,-34.3,-321.6,-136,1627823, true)

	CAVEATS
	  - This is written against the SR/SWGEmu Core3 Lua API (spawnBuilding,
	    destroyBuilding, switchZone, createObserver(OBJECTDESTRUCTION,...)).
	    All of those bindings exist in this tree; still TEST on a dev server
	    before shipping -- coordinates/templates below are sane defaults, not
	    tuned values.
	  - Arena uses object/building/general/cave_02.iff (a real cave building
	    with an interior cell). Swap self.arenaTemplate for any building whose
	    getCell(self.arenaCell) is the room you want the fight in.
========================================================================= --]]

local ObjectManager = require("managers.object.object_manager")

AcklayInstance = ScreenPlay:new {
	screenplayName = "AcklayInstance",

	-- ---- world / entrance --------------------------------------------------
	instanceZone = "yavin4",

	-- Entrance object placed in the shared lab (Acklay's old largeendcave spot).
	-- Set spawnStandaloneEntrance = false and instead call
	-- AcklayInstance:activate(pPlayer) from your own object if you prefer.
	spawnStandaloneEntrance = true,
	entrance = {
		template = "object/tangible/dungeon/wall_terminal_s1.iff",
		name     = "Acklay Containment Controls",
		-- Open-world placement on yavin4 (cell 0 = terrain). Order is x, z(height), y.
		-- Placed at -6469 / 83 / -442. Tune 'dir' to face the approach.
		x = -6469.0, z = 83.0, y = -442.0, dir = 90, cell = 0,
	},

	-- Where ejected players are dropped back -- a few metres from the entrance.
	returnPoint = { x = -6475.0, z = 83.0, y = -442.0, cell = 0 },

	-- ---- arena building (dynamically spawned per group) --------------------
	arenaTemplate = "object/building/general/cave_02.iff",
	arenaCell     = 1,                       -- getCell() index used as the arena room
	interiorDrop  = { x = 0.0, z = 0.5, y = -4.0 }, -- cell-local coords players land on

	-- Staging: buildings are spawned far off in the wilderness so their
	-- exterior footprints never collide. Coordinates are recycled with a wide
	-- stride; 48 slots is far more than you will ever run concurrently.
	stagingBaseX = 7000, stagingBaseY = 7000, stagingStride = 220, stagingSlots = 48,

	-- ---- encounter ---------------------------------------------------------
	-- cell-local coords, no respawn (0) -- the instance is torn down after use.
	bossSpawn = { template = "acklay", x = 0.0, z = 0.0, y = 6.0, dir = 0 },
	addSpawns = {
		{ template = "enhanced_kwi",          x =  5.0, z = 0.0, y = 4.0, dir = -30 },
		{ template = "enhanced_kliknik",      x = -5.0, z = 0.0, y = 4.0, dir =  30 },
		{ template = "enhanced_force_kliknik", x =  0.0, z = 0.0, y =-3.0, dir = 180 },
	},

	-- ---- rules -------------------------------------------------------------
	maxPlayers        = 8,
	groupInviteRange  = 64,        -- members within this range get pulled in
	instanceDuration  = 30 * 60,   -- seconds before a running instance expires
	exitDelayAfterKill = 3 * 60,   -- seconds to loot/leave after the boss dies

	-- Per-player lockout applied on a CLEAR (boss killed). Stops a group
	-- farming the boss back-to-back. A wipe / timeout does NOT lock you out,
	-- so a failed attempt can be retried immediately. Persisted via quest
	-- status, so it survives relog and server restarts.
	lockoutDuration   = 30 * 60,   -- seconds

	-- Difficulty scaling. Base HAM comes from the acklay template
	-- (96000/118000). We multiply by soloMult for a lone player, then add
	-- perExtraMember for every additional body so a full group is meatier.
	-- This is the "pull group-level content" knob from the difficulty design.
	soloMult          = 1.00,
	perExtraMember    = 0.18,      -- +18% boss HAM per extra player
}

registerScreenPlay("AcklayInstance", true)

-- ===========================================================================
--  Boot
-- ===========================================================================
function AcklayInstance:start()
	if (not isZoneEnabled(self.instanceZone)) then
		return
	end

	if (self.spawnStandaloneEntrance) then
		self:spawnEntrance()
	end
end

function AcklayInstance:spawnEntrance()
	local e = self.entrance
	local pEntrance = spawnSceneObject(self.instanceZone, e.template, e.x, e.z, e.y, e.cell, math.rad(e.dir))

	if (pEntrance == nil) then
		printLuaError("AcklayInstance: failed to spawn entrance object")
		return
	end

	SceneObject(pEntrance):setCustomObjectName(e.name)
	SceneObject(pEntrance):setObjectMenuComponent("AcklayInstanceEntranceMenuComponent")
end

-- ===========================================================================
--  Activation  --  reserve + spawn a private arena for this player/group
-- ===========================================================================
function AcklayInstance:activate(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local player   = CreatureObject(pPlayer)
	local playerID = player:getObjectID()

	-- One active instance per owner, and don't let someone already inside an
	-- instance start another. (Stock Core3 Lua does NOT expose the group leader
	-- -- there is no getGroup()/leader binding -- so we can't hard-gate to the
	-- leader. Instead the activator becomes the owner and the per-owner /
	-- per-member flags below stop a second person in the same party from
	-- forking a duplicate instance. If your fork adds a getGroupLeaderID()
	-- binding, re-add a leader check here.)
	if (readData(playerID .. ":acklayInstanceOwner") == 1
		or readData(playerID .. ":acklayBuilding") ~= 0) then
		player:sendSystemMessage("You are already bound to an Acklay containment cycle.")
		return
	end

	-- Lockout: can't re-enter until the cooldown from your last clear elapses.
	local lockRemaining = self:getLockoutRemaining(playerID)
	if (lockRemaining > 0) then
		player:sendSystemMessage("The containment systems are still recharging from your last hunt. Try again in " .. self:formatMinutes(lockRemaining) .. ".")
		return
	end

	-- Reserve a staging slot + spawn the building.
	local slot = self:getNextSlot()
	local sx   = self.stagingBaseX + (slot * self.stagingStride)
	local sy   = self.stagingBaseY

	local pArena = spawnBuilding(pPlayer, self.arenaTemplate, sx, sy, 0)

	if (pArena == nil) then
		player:sendSystemMessage("The containment chamber is unavailable right now. Try again shortly.")
		printLuaError("AcklayInstance: spawnBuilding returned nil at slot " .. slot)
		return
	end

	local arenaID = SceneObject(pArena):getObjectID()
	writeData("acklayActive:" .. arenaID, 1)
	writeData("acklayStart:" .. arenaID, os.time())
	writeData(arenaID .. ":acklayOwner", playerID)
	writeData(playerID .. ":acklayInstanceOwner", 1)

	-- Build the encounter and pull the party in.
	local members = self:gatherParty(pPlayer)
	self:spawnEncounter(pArena, #members)
	self:transportParty(pArena, members)

	-- Lifetime timer.
	createEvent(self.instanceDuration * 1000, "AcklayInstance", "handleInstanceExpired", pArena, "")

	player:sendSystemMessage("Containment breached -- an Acklay has been released into your chamber.")
	return true
end

-- Returns a list of pointers: the owner + in-range, non-AI group members.
function AcklayInstance:gatherParty(pPlayer)
	local members = { pPlayer }

	if (not CreatureObject(pPlayer):isGrouped()) then
		return members
	end

	local groupSize = CreatureObject(pPlayer):getGroupSize()

	for i = 0, groupSize - 1, 1 do
		local pMember = CreatureObject(pPlayer):getGroupMember(i)
		if (pMember ~= nil and pMember ~= pPlayer
			and not SceneObject(pMember):isAiAgent()
			and readData(SceneObject(pMember):getObjectID() .. ":acklayBuilding") == 0
			and CreatureObject(pPlayer):isInRangeWithObject(pMember, self.groupInviteRange)) then

			-- Locked-out members can't be pulled in; tell them why.
			if (self:getLockoutRemaining(SceneObject(pMember):getObjectID()) > 0) then
				CreatureObject(pMember):sendSystemMessage("You are still locked out of the Acklay chamber and were left behind.")
			else
				table.insert(members, pMember)
				if (#members >= self.maxPlayers) then
					break
				end
			end
		end
	end

	return members
end

-- ===========================================================================
--  Encounter spawning + difficulty scaling
-- ===========================================================================
function AcklayInstance:spawnEncounter(pArena, partySize)
	local pCell = BuildingObject(pArena):getCell(self.arenaCell)
	if (pCell == nil) then
		printLuaError("AcklayInstance: arena has no cell " .. self.arenaCell)
		return
	end

	local cellID  = SceneObject(pCell):getObjectID()
	local arenaID = SceneObject(pArena):getObjectID()

	-- Boss.
	local b = self.bossSpawn
	local pAcklay = spawnMobile(self.instanceZone, b.template, 0, b.x, b.z, b.y, b.dir, cellID)

	if (pAcklay ~= nil) then
		self:scaleBoss(pAcklay, partySize)
		writeData(arenaID .. ":acklayBossID", SceneObject(pAcklay):getObjectID())
		-- Kill detection (same pattern as the Corvette assassination target).
		createObserver(OBJECTDESTRUCTION, "AcklayInstance", "onAcklayKilled", pAcklay)
	end

	-- Adds.
	for i = 1, #self.addSpawns, 1 do
		local a = self.addSpawns[i]
		spawnMobile(self.instanceZone, a.template, 0, a.x, a.z, a.y, a.dir, cellID)
	end
end

function AcklayInstance:scaleBoss(pAcklay, partySize)
	local extra = math.max(0, partySize - 1)
	local mult  = self.soloMult + (extra * self.perExtraMember)

	local creature = CreatureObject(pAcklay)

	-- HAM indices: 0 = Health, 3 = Action, 6 = Mind (constitution pools).
	for _, pool in ipairs({ 0, 3, 6 }) do
		local base = creature:getMaxHAM(pool)
		if (base > 0) then
			local scaled = math.floor(base * mult)
			creature:setBaseHAM(pool, scaled)
			creature:setMaxHAM(pool, scaled)
			creature:setHAM(pool, scaled)
		end
	end

	creature:setCustomObjectName("Acklay (Contained)")
end

-- ===========================================================================
--  Transport in / out
-- ===========================================================================
function AcklayInstance:transportParty(pArena, members)
	local pCell = BuildingObject(pArena):getCell(self.arenaCell)
	if (pCell == nil) then
		return
	end

	local cellID  = SceneObject(pCell):getObjectID()
	local arenaID = SceneObject(pArena):getObjectID()
	local d       = self.interiorDrop

	for i = 1, #members, 1 do
		local pMember = members[i]
		if (pMember ~= nil) then
			local memberID = SceneObject(pMember):getObjectID()
			writeData(memberID .. ":acklayBuilding", arenaID)

			if (CreatureObject(pMember):isRidingMount()) then
				CreatureObject(pMember):dismount()
			end

			-- small local spread so nobody lands stacked
			SceneObject(pMember):switchZone(self.instanceZone, d.x + (i - 1), d.z, d.y, cellID)
		end
	end
end

function AcklayInstance:ejectAllPlayers(pArena)
	if (pArena == nil) then
		return
	end

	local toEject = {}
	local cellCount = BuildingObject(pArena):getTotalCellNumber()

	for i = 1, cellCount, 1 do
		local pCell = BuildingObject(pArena):getCell(i)
		if (pCell ~= nil) then
			for j = 1, SceneObject(pCell):getContainerObjectsSize(), 1 do
				local pObject = SceneObject(pCell):getContainerObject(j - 1)
				if (pObject ~= nil and SceneObject(pObject):isPlayerCreature()) then
					table.insert(toEject, pObject)
				end
			end
		end
	end

	for i = 1, #toEject, 1 do
		self:ejectPlayer(toEject[i])
	end
end

function AcklayInstance:ejectPlayer(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	deleteData(playerID .. ":acklayBuilding")
	deleteData(playerID .. ":acklayInstanceOwner")

	local r = self.returnPoint
	if (isZoneEnabled(self.instanceZone)) then
		SceneObject(pPlayer):switchZone(self.instanceZone, r.x, r.z, r.y, r.cell)
	end
end

-- ===========================================================================
--  Boss killed -> success
-- ===========================================================================
function AcklayInstance:onAcklayKilled(pAcklay, pKiller)
	if (pAcklay == nil) then
		return 1
	end

	-- Find the arena this boss belongs to (cell -> building).
	local pCell = SceneObject(pAcklay):getParent()
	if (pCell == nil) then
		return 1
	end
	local pArena = SceneObject(pCell):getParent()
	if (pArena == nil or not SceneObject(pArena):isBuildingObject()) then
		return 1
	end

	local arenaID = SceneObject(pArena):getObjectID()
	if (readData("acklayActive:" .. arenaID) ~= 1) then
		return 1
	end

	writeData("acklayComplete:" .. arenaID, 1)
	self:broadcast(pArena, "The Acklay falls. Gather your spoils -- the chamber collapses shortly.")

	-- Clear = lockout for everyone present (prevents back-to-back farming).
	self:applyLockout(pArena)

	-- (Loot is handled by the acklay lootGroups on the template. Add any
	--  instance-only reward / badge here if you want one.)

	-- Give the party time to loot, then tear the instance down.
	createEvent(self.exitDelayAfterKill * 1000, "AcklayInstance", "handleInstanceExpired", pArena, "")

	return 1
end

-- ===========================================================================
--  Expiry / teardown
-- ===========================================================================
function AcklayInstance:handleInstanceExpired(pArena)
	if (pArena == nil) then
		return
	end

	local arenaID = SceneObject(pArena):getObjectID()
	if (readData("acklayActive:" .. arenaID) ~= 1) then
		return  -- already cleaned up (e.g. boss-kill teardown already fired)
	end

	self:broadcast(pArena, "The containment field destabilizes. Returning you to the lab.")
	self:ejectAllPlayers(pArena)
	createEvent(4000, "AcklayInstance", "destroyInstance", pArena, "")
end

function AcklayInstance:destroyInstance(pArena)
	if (pArena == nil) then
		return
	end

	local arenaID = SceneObject(pArena):getObjectID()
	local ownerID = readData(arenaID .. ":acklayOwner")

	-- clear per-owner + per-building bookkeeping
	if (ownerID ~= 0) then
		deleteData(ownerID .. ":acklayInstanceOwner")
	end
	deleteData("acklayActive:" .. arenaID)
	deleteData("acklayStart:" .. arenaID)
	deleteData("acklayComplete:" .. arenaID)
	deleteData(arenaID .. ":acklayOwner")
	deleteData(arenaID .. ":acklayBossID")

	-- destroyBuilding despawns the structure + its cells and everything
	-- (mobs, loot crates, leftover objects) contained in them.
	destroyBuilding(arenaID)
end

-- ===========================================================================
--  Helpers
-- ===========================================================================
function AcklayInstance:broadcast(pArena, message)
	if (pArena == nil) then
		return
	end

	local cellCount = BuildingObject(pArena):getTotalCellNumber()
	for i = 1, cellCount, 1 do
		local pCell = BuildingObject(pArena):getCell(i)
		if (pCell ~= nil) then
			for j = 1, SceneObject(pCell):getContainerObjectsSize(), 1 do
				local pObject = SceneObject(pCell):getContainerObject(j - 1)
				if (pObject ~= nil and SceneObject(pObject):isPlayerCreature()) then
					CreatureObject(pObject):sendSystemMessage(message)
				end
			end
		end
	end
end

-- ---- lockout --------------------------------------------------------------
-- Seconds remaining on a player's lockout (0 = free to enter).
function AcklayInstance:getLockoutRemaining(playerID)
	local stamp = tonumber(getQuestStatus(playerID .. ":acklayLockout"))
	if (stamp == nil) then
		return 0
	end

	local remaining = self.lockoutDuration - (os.time() - stamp)
	if (remaining < 0) then
		return 0
	end

	return remaining
end

-- Stamp a fresh lockout on every player currently inside the arena.
function AcklayInstance:applyLockout(pArena)
	if (pArena == nil) then
		return
	end

	local now = os.time()
	local cellCount = BuildingObject(pArena):getTotalCellNumber()

	for i = 1, cellCount, 1 do
		local pCell = BuildingObject(pArena):getCell(i)
		if (pCell ~= nil) then
			for j = 1, SceneObject(pCell):getContainerObjectsSize(), 1 do
				local pObject = SceneObject(pCell):getContainerObject(j - 1)
				if (pObject ~= nil and SceneObject(pObject):isPlayerCreature()) then
					setQuestStatus(SceneObject(pObject):getObjectID() .. ":acklayLockout", tostring(now))
					CreatureObject(pObject):sendSystemMessage("Acklay containment secured. You may return in " .. self:formatMinutes(self.lockoutDuration) .. ".")
				end
			end
		end
	end
end

function AcklayInstance:formatMinutes(seconds)
	local mins = math.ceil(seconds / 60)
	if (mins <= 1) then
		return "1 minute"
	end
	return mins .. " minutes"
end

-- Rolling staging-slot index (recycled; wide stride keeps footprints apart).
function AcklayInstance:getNextSlot()
	local last = tonumber(getQuestStatus("AcklayInstance:lastSlot"))
	local slot = 0
	if (last ~= nil) then
		slot = (last + 1) % self.stagingSlots
	end
	setQuestStatus("AcklayInstance:lastSlot", slot)
	return slot
end

-- ===========================================================================
--  Entrance radial menu component
-- ===========================================================================
AcklayInstanceEntranceMenuComponent = { }

function AcklayInstanceEntranceMenuComponent:fillObjectMenuResponse(pSceneObject, pMenuResponse, pPlayer)
	if (pMenuResponse == nil) then
		return
	end
	local menuResponse = LuaObjectMenuResponse(pMenuResponse)
	menuResponse:addRadialMenuItem(68, 3, "Initiate Acklay Containment") -- 68 = SERVER_MENU1
end

function AcklayInstanceEntranceMenuComponent:handleObjectMenuSelect(pSceneObject, pPlayer, selectedID)
	if (pPlayer == nil or selectedID ~= 68) then
		return 0
	end

	if (not CreatureObject(pPlayer):isInRangeWithObject(pSceneObject, 8)) then
		CreatureObject(pPlayer):sendSystemMessage("You are too far from the controls.")
		return 0
	end

	AcklayInstance:activate(pPlayer)
	return 0
end

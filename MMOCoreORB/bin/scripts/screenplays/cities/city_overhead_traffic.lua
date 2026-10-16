-- 10/13/26 klambright - New screenplay that gives player cities of rank 7 and above the NPC-city style overhead traffic (distant ship particle objects spawned above the player and removed after a short time) and audio (ship flyby sounds played to the player). Intensity scales: rank 7 = light (Moenia-like), rank 8 = medium, rank 9 = heavy (Theed-like). Cities of rank 6 and below, and NPC (client) cities, are untouched. Interacts with: PlayerTriggers (playerTriggers.lua) login/logout hooks, screenplays.lua (include), LuaCityRegion.cpp getCityRank binding, getCityRegionAt/spawnSceneObject/createEvent/shared memory Lua APIs, object/static/particle/particle_distant_ships*.lua templates, and sound/eng_flyby_*.snd client assets.
CityOverheadTraffic = {
	-- 10/14/26 klambright - Enables the per-tick diagnostic log in CityOverheadTraffic:trafficTick (set to false once confirmed working).
	debug = true,
	--->END OF MODIFICATION - kl<-- continue
	minimumRank = 7,
	-- 10/13/26 klambright - Extends how long overhead ship particles stay in the world from 30 to 60 seconds so slow ships do not vanish mid-approach; read by CityOverheadTraffic:spawnTraffic, which schedules CityOverheadTraffic:despawnTraffic via createEvent.
	despawnTime = 60000,
	--->END OF MODIFICATION - kl<-- continue
	-- 10/13/26 klambright - Delay in ms before the flyby sound is replayed so audio lasts 30 seconds longer, matching the extended ship lifetime; used by CityOverheadTraffic:trafficTick and CityOverheadTraffic:replaySound.
	soundReplayTime = 30000,
	--->END OF MODIFICATION - kl<-- continue
	minAltitude = 40,
	maxAltitude = 70,
	spread = 60,

	-- Rank 7 light, rank 8 medium, rank 9 heavy; delays are seconds between traffic events, count is ships per event.
	tiers = {
		[7] = {
			minDelay = 90, maxDelay = 150, count = 1,
			ships = {"object/static/particle/particle_distant_ships.iff"},
			sounds = {"sound/eng_flyby_yt1300.snd"},
		},
		[8] = {
			minDelay = 50, maxDelay = 90, count = 2,
			ships = {"object/static/particle/particle_distant_ships.iff", "object/static/particle/particle_distant_ships_rebel.iff", "object/static/particle/particle_distant_ships_imperial.iff"},
			sounds = {"sound/eng_flyby_yt1300.snd", "sound/eng_flyby_xwing.snd"},
		},
		[9] = {
			minDelay = 25, maxDelay = 50, count = 3,
			ships = {"object/static/particle/particle_distant_ships.iff", "object/static/particle/particle_distant_ships_rebel.iff", "object/static/particle/particle_distant_ships_imperial.iff"},
			-- 10/14/26 klambright - Moves the rank 9 dogfight particles into their own list with a 5 percent per-ship spawn chance (originally 3 of 6 ship choices, about 50 percent), sharply cutting dogfight frequency (updated from 25 percent on 10/14/26); consumed only by CityOverheadTraffic:spawnTraffic in this file, so rank 7/8 traffic, regular ships and sounds are unchanged.
			dogfights = {"object/static/particle/particle_distant_ships_dogfight_t_vs_x.iff", "object/static/particle/particle_distant_ships_dogfight_tb_vs_bw.iff", "object/static/particle/particle_distant_ships_dogfight_ti_vs_aw.iff"},
			dogfightChance = 5,
			--->END OF MODIFICATION - kl<-- continue
			sounds = {"sound/eng_flyby_yt1300.snd", "sound/eng_flyby_xwing.snd", "sound/eng_flyby_tie.snd"},
		},
	},
}

function CityOverheadTraffic:getTier(rank)
	if rank < self.minimumRank then
		return nil
	end

	if rank > 9 then
		rank = 9
	end

	return self.tiers[rank]
end

function CityOverheadTraffic:playerLoggedIn(pPlayer)
	if pPlayer == nil then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local token = (readSharedMemory("cityOverheadTraffic:" .. playerID) or 0) + 1
	writeSharedMemory("cityOverheadTraffic:" .. playerID, token)

	createEvent(getRandomNumber(30, 60) * 1000, "CityOverheadTraffic", "trafficTick", pPlayer, playerID .. ":" .. token)
end

function CityOverheadTraffic:playerLoggedOut(pPlayer)
	if pPlayer == nil then
		return
	end

	-- Invalidates the running tick loop for this player
	local playerID = SceneObject(pPlayer):getObjectID()
	writeSharedMemory("cityOverheadTraffic:" .. playerID, (readSharedMemory("cityOverheadTraffic:" .. playerID) or 0) + 1)
end

function CityOverheadTraffic:trafficTick(pPlayer, args)
	local playerID, token = string.match(args or "", "(%d+):(%d+)")

	if playerID == nil or tonumber(token) ~= readSharedMemory("cityOverheadTraffic:" .. playerID) then
		return
	end

	pPlayer = getSceneObject(tonumber(playerID))

	if pPlayer == nil then
		return
	end

	local delay = 60
	local tier = nil

	-- 10/14/26 klambright - Reworks the city check to record why a tick does not qualify (indoors, no city region at the position, client city, or the rank read from CityRegion:getCityRank) for the debug log below; qualification rules are unchanged.
	-- Outdoor players only, inside a player city (not a client/NPC city) of qualifying rank
	local parentID = SceneObject(pPlayer):getParentID()
	local zoneName = SceneObject(pPlayer):getZoneName()
	local cityState = "indoors"
	local rank = -1

	if parentID == 0 then
		-- 10/15/26 klambright - Uses the player's current city region (SceneObject:getCityRegion, new C++ binding) instead of getCityRegionAt, which only finds cities registered on the planetary map and so missed unregistered player cities; falls back to getCityRegionAt.
		local pCity = SceneObject(pPlayer):getCityRegion()

		if pCity == nil then
			pCity = getCityRegionAt(zoneName, SceneObject(pPlayer):getWorldPositionX(), SceneObject(pPlayer):getWorldPositionY())
		end
		--->END OF MODIFICATION - kl<-- continue

		if pCity == nil then
			cityState = "no city region at position"
		elseif CityRegion(pCity):isClientRegion() then
			cityState = "client city"
		else
			rank = CityRegion(pCity):getCityRank()
			cityState = "player city"
			tier = self:getTier(rank)
		end
	end
	--->END OF MODIFICATION - kl<-- continue

	-- 10/14/26 klambright - Diagnostic log line (core3.log) each tick showing zone, detected rank and whether traffic fires, to confirm rank 7+ cities qualify; toggle with CityOverheadTraffic.debug. Uses Logger:log.
	if self.debug then
		Logger:log("CityOverheadTraffic tick player " .. playerID .. " zone " .. tostring(zoneName) .. " x " .. math.floor(SceneObject(pPlayer):getWorldPositionX()) .. " y " .. math.floor(SceneObject(pPlayer):getWorldPositionY()) .. " parent " .. tostring(parentID) .. " state " .. cityState .. " rank " .. tostring(rank) .. " tier " .. tostring(tier ~= nil), LT_INFO)
	end
	--->END OF MODIFICATION - kl<-- continue

	if tier ~= nil then
		self:spawnTraffic(pPlayer, tier)
		-- 10/13/26 klambright - Plays the flyby sound now and schedules a replay of the same sound 30 seconds later (CityOverheadTraffic:replaySound) to extend the audio; uses playMusicMessage on the player's CreatureObject and the createEvent Lua API.
		local sound = tier.sounds[getRandomNumber(1, #tier.sounds)]
		CreatureObject(pPlayer):playMusicMessage(sound)
		createEvent(self.soundReplayTime, "CityOverheadTraffic", "replaySound", pPlayer, playerID .. ":" .. token .. ":" .. sound)
		--->END OF MODIFICATION - kl<-- continue
		delay = getRandomNumber(tier.minDelay, tier.maxDelay)
	end

	createEvent(delay * 1000, "CityOverheadTraffic", "trafficTick", pPlayer, playerID .. ":" .. token)
end

-- 10/13/26 klambright - Replays a flyby sound for a player if the traffic loop is still valid (same login token); called from createEvent in CityOverheadTraffic:trafficTick and uses shared memory and getSceneObject.
function CityOverheadTraffic:replaySound(pPlayer, args)
	local playerID, token, sound = string.match(args or "", "(%d+):(%d+):(.+)")

	if playerID == nil or tonumber(token) ~= readSharedMemory("cityOverheadTraffic:" .. playerID) then
		return
	end

	pPlayer = getSceneObject(tonumber(playerID))

	if pPlayer ~= nil then
		CreatureObject(pPlayer):playMusicMessage(sound)
	end
end
--->END OF MODIFICATION - kl<-- continue

function CityOverheadTraffic:spawnTraffic(pPlayer, tier)
	local zone = SceneObject(pPlayer):getZoneName()
	local px = SceneObject(pPlayer):getWorldPositionX()
	local pz = SceneObject(pPlayer):getWorldPositionZ()
	local py = SceneObject(pPlayer):getWorldPositionY()
	-- 10/14/26 klambright - Per-player shared-memory lock so only one dogfight particle can exist at a time (a new one is not allowed while the previous is still in the world, i.e. within despawnTime); released in CityOverheadTraffic:despawnTraffic. Uses readSharedMemory/writeSharedMemory and getObjectID.
	local playerID = SceneObject(pPlayer):getObjectID()
	local dogfightKey = "cityOverheadDogfight:" .. playerID
	--->END OF MODIFICATION - kl<-- continue

	for i = 1, tier.count do
		-- 10/14/26 klambright - Picks a dogfight particle only with tier.dogfightChance percent probability (rank 9 only), otherwise a regular ship; works with the dogfights/dogfightChance fields in CityOverheadTraffic.tiers.
		local template = tier.ships[getRandomNumber(1, #tier.ships)]

		local isDogfight = false

		if tier.dogfights ~= nil and readSharedMemory(dogfightKey) == 0 and getRandomNumber(1, 100) <= tier.dogfightChance then
			template = tier.dogfights[getRandomNumber(1, #tier.dogfights)]
			isDogfight = true
		end
		--->END OF MODIFICATION - kl<-- continue
		local x = px + getRandomNumber(-self.spread, self.spread)
		local y = py + getRandomNumber(-self.spread, self.spread)
		local z = pz + getRandomNumber(self.minAltitude, self.maxAltitude)
		local pShip = spawnSceneObject(zone, template, x, z, y, 0, getRandomNumber(0, 360) * math.pi / 180)

		if pShip ~= nil then
			local despawnArgs = tostring(SceneObject(pShip):getObjectID())

			if isDogfight then
				writeSharedMemory(dogfightKey, 1)
				despawnArgs = despawnArgs .. ":" .. dogfightKey
			end

			createEvent(self.despawnTime, "CityOverheadTraffic", "despawnTraffic", nil, despawnArgs)
		end
	end
end

function CityOverheadTraffic:despawnTraffic(pNil, args)
	-- 10/14/26 klambright - Args are now "objectID" or "objectID:dogfightKey"; a dogfight key releases the per-player dogfight lock set in CityOverheadTraffic:spawnTraffic.
	local objectID, dogfightKey = string.match(args, "^(%d+):?(.*)$")

	if dogfightKey ~= nil and dogfightKey ~= "" then
		deleteSharedMemory(dogfightKey)
	end
	--->END OF MODIFICATION - kl<-- continue

	local pShip = getSceneObject(tonumber(objectID))

	if pShip ~= nil then
		SceneObject(pShip):destroyObjectFromWorld()
	end
end
--->END OF MODIFICATION - kl<--

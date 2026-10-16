PlayerTriggers = { }

function PlayerTriggers:playerLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return
	end
	ServerEventAutomation:playerLoggedIn(pPlayer)
	BestineElection:playerLoggedIn(pPlayer)
	-- 10/13/26 klambright - Starts the per-player rank 7+ city overhead traffic/sound loop defined in cities/city_overhead_traffic.lua; called from PlayerObjectImplementation.cpp login trigger.
	CityOverheadTraffic:playerLoggedIn(pPlayer)
	--->END OF MODIFICATION - kl<-- continue
end

function PlayerTriggers:playerLoggedOut(pPlayer)
	if (pPlayer == nil) then
		return
	end
	ServerEventAutomation:playerLoggedOut(pPlayer)
	-- 10/13/26 klambright - Stops the per-player rank 7+ city overhead traffic/sound loop defined in cities/city_overhead_traffic.lua; called from PlayerObjectImplementation.cpp logout trigger.
	CityOverheadTraffic:playerLoggedOut(pPlayer)
	--->END OF MODIFICATION - kl<--
end

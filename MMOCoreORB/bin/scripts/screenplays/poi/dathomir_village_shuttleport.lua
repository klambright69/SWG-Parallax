-- 09/25/26 - AI / klambright: Adds a startup-registered persistent scene screenplay for The Village Dathomir shuttleport; this interacts with the screenplay loader, dedicated Dathomir shuttleport template, and Dathomir planet travel point.
DathomirVillageShuttleportScreenPlay = ScreenPlay:new {
	numberOfActs = 1,
	screenplayName = "DathomirVillageShuttleportScreenPlay",
	planet = "dathomir"
}

registerScreenPlay("DathomirVillageShuttleportScreenPlay", true)

function DathomirVillageShuttleportScreenPlay:start()
	if (isZoneEnabled(self.planet)) then
		self:spawnSceneObjects()
	end
end

--->END OF MODIFICATION<---

-- 09/25/26 - AI / klambright: Moves The Village shuttleport scene to x 5234, y -4085, z 78 with a 255-degree heading; standard child objects supply the NPC shuttle, travel terminal, and ticket collector, interacting with Dathomir travel routing and shuttle service.
function DathomirVillageShuttleportScreenPlay:spawnSceneObjects()
	spawnSceneObject(self.planet, "object/building/dathomir/shuttleport_dathomir.iff", 5234, 78, -4085, 0, math.rad(255))
	-- 09/25/26 - AI / klambright: Moves the persistent general mission terminal to x 5252.7, y -4091.7, z 78.5 while preserving its 75-degree facing; it is spawned by the Village screenplay and saved through the standard scene-object persistence path.
	spawnSceneObject(self.planet, "object/tangible/terminal/terminal_mission.iff", 5252.7, 78.5, -4091.7, 0, math.rad(75))
	--->END OF MODIFICATION<---
	-- 09/26/26 - AI / klambright: Moves the Village bazaar terminal east to x 5250 to separate its interaction area from the nearby bank terminal while preserving y -4068, z 78.5, and its 75-degree facing; it is spawned by the Village screenplay through the standard scene-object path.
	-- spawnSceneObject(self.planet, "object/tangible/terminal/terminal_bazaar.iff", 5250, 78.5, -4068, 0, math.rad(75))
	--->END OF MODIFICATION<---
	-- 09/26/26 - AI / klambright: Disables the Village Bazaar terminal spawn while retaining the original call as a commented historical record; this screenplay no longer creates the Bazaar object.
	--->END OF MODIFICATION<---
	-- 09/26/26 - AI / klambright: Moves the Village bank terminal to the Bazaar terminal's original coordinates x 5246, y -4068, z 78.5 and changes its facing to the Bazaar's original 75 degrees; it is spawned by this screenplay through the standard bank terminal template and scene-object path.
	spawnSceneObject(self.planet, "object/tangible/terminal/terminal_bank.iff", 5246, 78.5, -4068, 0, math.rad(75))
	--->END OF MODIFICATION<---
end
--->END OF MODIFICATION<---

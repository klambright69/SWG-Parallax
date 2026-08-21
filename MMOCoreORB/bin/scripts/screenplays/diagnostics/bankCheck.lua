-- Read-only diagnostic: reports the live containerVolumeLimit of each online
-- player's bank and inventory. Invoked from the server console with:
--     runLuaFunction BankCheck:report
-- Reads nothing else and changes nothing.

BankCheck = ScreenPlay:new {
	screenplayName = "BankCheck",
}

registerScreenPlay("BankCheck", true)

function BankCheck:start()
end

-- Names to inspect. getPlayerByName is the available binding; there is no
-- getOnlinePlayers in this tree.
BankCheckNames = { "Dadmin", "Badonka", "Kird", "Chaleeza", "Elvis", "Pyxins", "Esti", "Mylak" }

function BankCheck:report()
	for i = 1, #BankCheckNames, 1 do
		local pPlayer = getPlayerByName(BankCheckNames[i])

		if (pPlayer ~= nil) then
			local name = CreatureObject(pPlayer):getFirstName()
			local pBank = CreatureObject(pPlayer):getSlottedObject("bank")
			local pInv  = CreatureObject(pPlayer):getSlottedObject("inventory")

			local bankLimit = "nil"
			local bankUsed  = "nil"
			local invLimit  = "nil"

			if (pBank ~= nil) then
				bankLimit = tostring(SceneObject(pBank):getContainerVolumeLimit())
				bankUsed  = tostring(SceneObject(pBank):getContainerObjectsSize())
			end

			if (pInv ~= nil) then
				invLimit = tostring(SceneObject(pInv):getContainerVolumeLimit())
			end

			printLuaError("BankCheck: " .. name .. " bank=" .. bankUsed .. "/" .. bankLimit .. "  inventoryLimit=" .. invLimit)
		end
	end
end

-- Reports which building cell (room) each named player is standing in.
-- Console:  runLuaFunction BankCheck:whereAmI
--
-- There is no getCellNumber binding on cells, so the index is recovered by
-- comparing the player's parent against each of the building's cells in turn.
-- The index matches the CellProperty order in the building's .pob, i.e. r1..rN.
function BankCheck:whereAmI()
	for i = 1, #BankCheckNames, 1 do
		local pPlayer = getPlayerByName(BankCheckNames[i])

		if (pPlayer ~= nil) then
			local name = CreatureObject(pPlayer):getFirstName()
			local pParent = SceneObject(pPlayer):getParent()

			if (pParent == nil) then
				printLuaError("Where: " .. name .. " is outdoors (no parent cell)")
			else
				local pBuilding = SceneObject(pParent):getParent()

				if (pBuilding == nil) then
					printLuaError("Where: " .. name .. " parent has no building")
				else
					local tmpl = SceneObject(pBuilding):getTemplateObjectPath()
					local cellID = SceneObject(pParent):getObjectID()
					local total = BuildingObject(pBuilding):getTotalCellNumber()
					local found = -1

					for c = 1, total, 1 do
						local pCell = BuildingObject(pBuilding):getCell(c)

						if (pCell ~= nil and SceneObject(pCell):getObjectID() == cellID) then
							found = c
							break
						end
					end

					-- Cell-LOCAL coordinates: these are exactly what
					-- DataTransformWithParent feeds to getCellFloorCollision,
					-- so they pin down the coordinate frame of the floor meshes.
					printLuaError("Where: " .. name .. " cell=" .. found .. "/" .. total
						.. " local x=" .. string.format("%.3f", SceneObject(pPlayer):getPositionX())
						.. " y=" .. string.format("%.3f", SceneObject(pPlayer):getPositionY())
						.. " z=" .. string.format("%.3f", SceneObject(pPlayer):getPositionZ())
						.. " building=" .. tostring(tmpl))
				end
			end
		end
	end
end

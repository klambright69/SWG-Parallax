/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef MISSIONDIRECTIONSUICALLBACK_H_
#define MISSIONDIRECTIONSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/terminal/mission/MissionTerminal.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/ZoneServer.h"

/**
 * Applies the compass sector chosen from a mission terminal radial.
 *
 * Stored as 0 for "any direction" and 1..8 for N, NE, E, SE, S, SW, W, NW. Destroy
 * mission target positions are then generated within that 45 degree sector instead of
 * a random bearing. The terminal list is regenerated immediately so the change is
 * visible without leaving the terminal.
 */
class MissionDirectionSuiCallback : public SuiCallback {
public:
	MissionDirectionSuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed || player == nullptr || args == nullptr || args->size() <= 0)
			return;

		if (!suiBox->isListBox())
			return;

		int selection = Integer::valueOf(args->get(0).toString());

		// Row order must match the list built in MissionTerminalImplementation.
		static const char* const names[] = {
			"Any Direction", "North", "Northeast", "East", "Southeast",
			"South", "Southwest", "West", "Northwest"
		};

		if (selection < 0 || selection >= (int)(sizeof(names) / sizeof(names[0])))
			return;

		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		ghost->setMissionDirectionPreference(selection);

		StringBuffer msg;

		if (selection == 0)
			msg << "Missions will now be generated in any direction.";
		else
			msg << "Missions will now be generated to the " << names[selection] << ".";

		player->sendSystemMessage(msg.toString());

		ManagedReference<SceneObject*> usingObject = suiBox->getUsingObject().get();

		if (usingObject == nullptr || !usingObject->isMissionTerminal())
			return;

		MissionTerminal* terminal = cast<MissionTerminal*>(usingObject.get());

		if (terminal == nullptr)
			return;

		auto zoneServer = player->getZoneServer();

		if (zoneServer == nullptr)
			return;

		MissionManager* missionManager = zoneServer->getMissionManager();

		if (missionManager == nullptr)
			return;

		missionManager->handleMissionListRequest(terminal, player, 0);
	}
};

#endif /* MISSIONDIRECTIONSUICALLBACK_H_ */

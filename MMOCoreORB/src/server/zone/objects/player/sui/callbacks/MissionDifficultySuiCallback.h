/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef MISSIONDIFFICULTYSUICALLBACK_H_
#define MISSIONDIFFICULTYSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/terminal/mission/MissionTerminal.h"
#include "server/zone/managers/mission/MissionManager.h"
#include "server/zone/ZoneServer.h"

/**
 * Applies the mission difficulty tier chosen from a mission terminal radial.
 *
 * The chosen offset is added to the player's effective level when destroy missions
 * select a lair, which lets a solo player reach tiers that would otherwise require a
 * group. After storing it the terminal's mission list is regenerated immediately so
 * the player sees the new tier without walking away and back.
 */
class MissionDifficultySuiCallback : public SuiCallback {
	// Offsets must line up with the rows added in MissionTerminalImplementation.
	//
	// Player level is capped at 25 and a lair is only offered when
	// minDifficulty <= level + 5, so an offset of 58 is the minimum that reaches the
	// difficulty 88 boss lairs (Ancient Bull Rancor on Dathomir). 65 is used to leave
	// headroom to minDifficulty 95 and cover the whole 88-92 band.
	//
	// Note the other half of the filter: maxDifficulty >= min(level - 5, ceiling).
	// At Heroic that resolves to the planet's minLevelCeiling, so lairs whose
	// maxDifficulty falls below it drop out and the tier shows only harder content.
	static const int SOLO_MODIFIER = 0;
	static const int GROUP_MODIFIER = 15;
	static const int HEROIC_MODIFIER = 65;

public:
	MissionDifficultySuiCallback(ZoneServer* server) : SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		if (cancelPressed || player == nullptr || args == nullptr || args->size() <= 0)
			return;

		if (!suiBox->isListBox())
			return;

		int selection = Integer::valueOf(args->get(0).toString());

		int modifier;
		String label;

		switch (selection) {
		case 0:
			modifier = SOLO_MODIFIER;
			label = "Solo";
			break;
		case 1:
			modifier = GROUP_MODIFIER;
			label = "Group";
			break;
		case 2:
			modifier = HEROIC_MODIFIER;
			label = "Heroic";
			break;
		default:
			return;
		}

		ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

		if (ghost == nullptr)
			return;

		ghost->setMissionDifficultyModifier(modifier);

		StringBuffer msg;
		msg << "Mission difficulty set to " << label;

		if (modifier > 0)
			msg << " (+" << modifier << ").";
		else
			msg << ".";

		player->sendSystemMessage(msg.toString());

		// Regenerate the visible list at the new tier. The using object is the terminal
		// the radial was opened on.
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

#endif /* MISSIONDIFFICULTYSUICALLBACK_H_ */

/*
 * MissionTerminalImplementation.cpp
 *
 *  Created on: 03/05/11
 *      Author: polonel
 */

#include "server/zone/objects/tangible/terminal/mission/MissionTerminal.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/packets/object/ObjectMenuResponse.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/managers/city/CityRemoveAmenityTask.h"
#include "server/zone/objects/player/sessions/SlicingSession.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/callbacks/MissionDifficultySuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/MissionDirectionSuiCallback.h"
#include "server/zone/managers/radial/RadialOptions.h"

void MissionTerminalImplementation::fillObjectMenuResponse(ObjectMenuResponse* menuResponse, CreatureObject* player) {
	TerminalImplementation::fillObjectMenuResponse(menuResponse, player);

	// Mission tuning options. Offered on every mission terminal on every planet, and
	// deliberately not gated on terminal type -- bounty terminals share this handler
	// but ignore the settings, which is harmless.
	menuResponse->addRadialMenuItem(RadialOptions::SERVER_MENU1, 3, "Set Mission Difficulty");
	menuResponse->addRadialMenuItem(RadialOptions::SERVER_MENU3, 3, "Set Mission Direction");

	ManagedReference<CityRegion*> city = player->getCityRegion().get();

	if (city != nullptr && city->isMayor(player->getObjectID()) && getParent().get() == nullptr) {

		menuResponse->addRadialMenuItem(72, 3, "@city/city:mt_remove"); // Remove

		menuResponse->addRadialMenuItem(73, 3, "@city/city:align"); // Align
		menuResponse->addRadialMenuItemToRadialID(73, 74, 3, "@city/city:north"); // North
		menuResponse->addRadialMenuItemToRadialID(73, 75, 3, "@city/city:east"); // East
		menuResponse->addRadialMenuItemToRadialID(73, 76, 3, "@city/city:south"); // South
		menuResponse->addRadialMenuItemToRadialID(73, 77, 3, "@city/city:west"); // West
	}
}

int MissionTerminalImplementation::handleObjectMenuSelect(CreatureObject* player, byte selectedID) {
	ManagedReference<CityRegion*> city = player->getCityRegion().get();

	if (selectedID == RadialOptions::SERVER_MENU1) {
		sendMissionDifficultyBox(player);
		return 0;
	}

	if (selectedID == RadialOptions::SERVER_MENU3) {
		sendMissionDirectionBox(player);
		return 0;
	}

	if (selectedID == 69 && player->hasSkill("combat_smuggler_slicing_01")) {
		if (isBountyTerminal())
			return 0;

		if (city != nullptr && !city->isClientRegion() && city->isBanned(player->getObjectID())) {
			player->sendSystemMessage("@city/city:banned_services"); // You are banned from using this city's services.
			return 0;
		}

		if (player->containsActiveSession(SessionFacadeType::SLICING)) {
			player->sendSystemMessage("@slicing/slicing:already_slicing");
			return 0;
		}

		if (!player->checkCooldownRecovery("slicing.terminal")) {
			StringIdChatParameter message;
			message.setStringId("@slicing/slicing:not_yet"); // You will be able to hack the network again in %DI seconds.
			message.setDI(player->getCooldownTime("slicing.terminal")->getTime() - Time().getTime());
			player->sendSystemMessage(message);
			return 0;
		}

		//Create Session
		ManagedReference<SlicingSession*> session = new SlicingSession(player);
		session->initalizeSlicingMenu(player, _this.getReferenceUnsafeStaticCast());

		return 0;

	} else if (selectedID == 72) {

		if (city != nullptr && city->isMayor(player->getObjectID())) {
			CityRemoveAmenityTask* task = new CityRemoveAmenityTask(_this.getReferenceUnsafeStaticCast(), city);
			task->execute();

			player->sendSystemMessage("@city/city:mt_removed"); // The object has been removed from the city.
		}

		return 0;

	} else if (selectedID == 74 || selectedID == 75 || selectedID == 76 || selectedID == 77) {

		CityManager* cityManager = getZoneServer()->getCityManager();
		cityManager->alignAmenity(city, player, _this.getReferenceUnsafeStaticCast(), selectedID - 74);

		return 0;
	}

	return TangibleObjectImplementation::handleObjectMenuSelect(player, selectedID);
}

String MissionTerminalImplementation::getTerminalName() {
	String name = "@terminal_name:terminal_mission";

	if (terminalType == "artisan" || terminalType == "entertainer" || terminalType == "bounty" || terminalType == "imperial" || terminalType == "rebel" || terminalType == "scout")
		name = name + "_" + terminalType;

	return name;
}

void MissionTerminalImplementation::sendMissionDifficultyBox(CreatureObject* player) {
	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE);
	box->setCallback(new MissionDifficultySuiCallback(player->getZoneServer()));
	box->setPromptTitle("Mission Difficulty");
	box->setPromptText("Choose the difficulty tier for missions offered by this terminal. "
		"A higher tier raises your effective level when missions are generated, so a solo "
		"player can reach tiers that normally require a group.\n\nCurrent modifier: +"
		+ String::valueOf(ghost->getMissionDifficultyModifier()));

	// Row order must match MissionDifficultySuiCallback.
	box->addMenuItem("Solo (+0)");
	box->addMenuItem("Group (+15)");
	box->addMenuItem("Heroic (+65)");

	box->setUsingObject(_this.getReferenceUnsafeStaticCast());
	box->setForceCloseDistance(16.f);

	ghost->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

void MissionTerminalImplementation::sendMissionDirectionBox(CreatureObject* player) {
	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	if (ghost == nullptr)
		return;

	ManagedReference<SuiListBox*> box = new SuiListBox(player, SuiWindowType::NONE);
	box->setCallback(new MissionDirectionSuiCallback(player->getZoneServer()));
	box->setPromptTitle("Mission Direction");
	box->setPromptText("Choose which direction missions should send you. Targets are "
		"generated within a 45 degree sector on that bearing from your position.");

	// Row order must match MissionDirectionSuiCallback.
	box->addMenuItem("Any Direction");
	box->addMenuItem("North");
	box->addMenuItem("Northeast");
	box->addMenuItem("East");
	box->addMenuItem("Southeast");
	box->addMenuItem("South");
	box->addMenuItem("Southwest");
	box->addMenuItem("West");
	box->addMenuItem("Northwest");

	box->setUsingObject(_this.getReferenceUnsafeStaticCast());
	box->setForceCloseDistance(16.f);

	ghost->addSuiBox(box);
	player->sendMessage(box->generateMessage());
}

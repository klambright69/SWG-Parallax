/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef CHARACTERBUILDERACCESS_H_
#define CHARACTERBUILDERACCESS_H_

#include "conf/ConfigManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"

/**
 * Whether this player may use a character builder ("Blue Frog") terminal.
 *
 * Core3.CharacterBuilderEnabled governs the public feature: with it off,
 * PlanetManager stops spawning the terminals on every planet. Privileged players
 * keep access regardless of that flag, so staff can carry a terminal in their
 * inventory and use it while the world terminals stay gone.
 *
 * Shared by the terminal itself and by SuiManager, so the radial, the menu and
 * the SUI callback all agree -- a mismatch there would either leave a usable
 * radial that does nothing, or a callback still reachable by packet after the
 * radial was withdrawn.
 */
inline bool canUseCharacterBuilder(CreatureObject* player) {
	if (ConfigManager::instance()->getCharacterBuilderEnabled())
		return true;

	if (player == nullptr)
		return false;

	ManagedReference<PlayerObject*> ghost = player->getPlayerObject();

	return ghost != nullptr && ghost->isPrivileged();
}

#endif /* CHARACTERBUILDERACCESS_H_ */

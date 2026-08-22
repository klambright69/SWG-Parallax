/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef MOUNTWEAPONSTOW_H_
#define MOUNTWEAPONSTOW_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/tangible/weapon/WeaponObject.h"
#include "server/zone/ZoneServer.h"

/**
 * Stows a rider's drawn weapon while mounted, and gives it back on dismount.
 *
 * The client picks its animation set from posture, locomotion and the weapon
 * being held. A rider still holding a weapon is drawn standing rather than in
 * the riding pose. Retail hides the weapon when you mount, which is why the
 * problem does not exist there; Core3 left it in hold_r.
 *
 * The weapon is moved to the inventory rather than merely hidden, because the
 * client decides the animation from what is actually in the hold_r slot -- there
 * is no separate "holstered" flag to set.
 *
 * The object id is remembered in screen play data rather than a transient field
 * so it survives a relog while mounted. If it cannot be restored the weapon is
 * simply left in the inventory: never destroyed, and the player can re-equip it
 * by hand.
 */
namespace MountWeaponStow {
	static const char* const SCREENPLAY = "mount_weapon_stow";
	static const char* const VARIABLE = "stowedWeapon";

	/**
	 * Moves any drawn weapon into the rider's inventory. Safe to call when
	 * nothing is held. Returns true when a weapon was stowed.
	 */
	inline bool stow(CreatureObject* creature) {
		if (creature == nullptr)
			return false;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return false;

		// Only the right hand matters. Instruments also live in hold_r, so the
		// object is checked for being a weapon rather than assumed.
		ManagedReference<SceneObject*> held = creature->getSlottedObject("hold_r");

		if (held == nullptr || !held->isWeaponObject())
			return false;

		ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

		if (inventory == nullptr)
			return false;

		if (inventory->isContainerFullRecursive()) {
			// Leaving the weapon drawn is better than failing the mount, so this
			// is reported but not treated as an error.
			creature->sendSystemMessage("@error_message:inv_full"); // Your inventory is full.
			return false;
		}

		uint64 weaponID = held->getObjectID();

		if (!inventory->transferObject(held, -1, true))
			return false;

		ghost->setScreenPlayData(SCREENPLAY, VARIABLE, String::valueOf(weaponID));

		return true;
	}

	/**
	 * Re-equips whatever stow() put away. Safe to call when nothing was stowed.
	 */
	inline void restore(CreatureObject* creature) {
		if (creature == nullptr)
			return;

		ManagedReference<PlayerObject*> ghost = creature->getPlayerObject();

		if (ghost == nullptr)
			return;

		String stored = ghost->getScreenPlayData(SCREENPLAY, VARIABLE);

		if (stored.isEmpty())
			return;

		// Clear first. If anything below fails the weapon stays in the inventory
		// rather than leaving a stale id that would be retried on every dismount.
		ghost->deleteScreenPlayData(SCREENPLAY, VARIABLE);

		uint64 weaponID = UnsignedLong::valueOf(stored);

		if (weaponID == 0)
			return;

		ManagedReference<ZoneServer*> zoneServer = creature->getZoneServer();

		if (zoneServer == nullptr)
			return;

		ManagedReference<SceneObject*> weapon = zoneServer->getObject(weaponID);

		if (weapon == nullptr || !weapon->isWeaponObject())
			return;

		// Only put it back if the player still has it. They may have dropped,
		// sold or destroyed it while riding.
		ManagedReference<SceneObject*> inventory = creature->getSlottedObject("inventory");

		if (inventory == nullptr || weapon->getParent().get() != inventory)
			return;

		// Something else may have been equipped while mounted.
		if (creature->getSlottedObject("hold_r") != nullptr)
			return;

		creature->transferObject(weapon, 4, true);
	}
}

#endif /* MOUNTWEAPONSTOW_H_ */

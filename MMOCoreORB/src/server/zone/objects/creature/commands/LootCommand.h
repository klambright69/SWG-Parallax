/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef LOOTCOMMAND_H_
#define LOOTCOMMAND_H_

#include "server/zone/objects/scene/SceneObject.h"
#include "server/zone/managers/player/PlayerManager.h"
#include "server/zone/managers/group/GroupLootTask.h"
#include "server/zone/objects/transaction/TransactionLog.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
#include "server/zone/CloseObjectsVector.h"
#include "server/zone/Zone.h"

class LootCommand : public QueueCommand {

public:
	enum {
		NOPICKUPITEMS = 0,
		ITEMFOROTHER = 1,
		PICKEDANDREMAINING = 2,
		PICKEDANDEMPTY = 3
	};

	// "/loot area" sweeps every corpse the player may loot within this radius. The
	// single-target path allows 16m, so this stays just inside it and no corpse is
	// reachable by the sweep that could not be looted one at a time.
	static constexpr float AREALOOTRANGE = 32.f;

	// Defensive bound on a single sweep so an AoE grinder standing in a pile of
	// corpses cannot stall the command queue. Whatever is left over is reported and
	// picked up by running the command again.
	static constexpr int AREALOOTMAXCORPSES = 50;

	LootCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		ZoneServer* zoneServer = server->getZoneServer();

		if (zoneServer == nullptr)
			return GENERALERROR;

		// "/loot area" works off the player's position rather than the selected
		// target, so it is handled before the target is resolved. A player with no
		// target selected can still use it.
		if (arguments.toString().trim().toLowerCase().beginsWith("area"))
			return doAreaLoot(creature);

		ManagedReference<SceneObject*> targetObject = zoneServer->getObject(target);

		if (targetObject == nullptr || !targetObject->isAiAgent())
			return INVALIDTARGET;

		AiAgent* agent = targetObject.castTo<AiAgent*>();

		if (agent == nullptr)
			return INVALIDTARGET;

		Locker locker(agent, creature);

		if (!agent->isDead() || creature->isDead())
			return GENERALERROR;

		if (!checkDistance(agent, creature, 32)) {
			creature->sendSystemMessage("@error_message:target_out_of_range"); //"Your target is out of range for this action."
			return GENERALERROR;
		}

		bool lootAll = arguments.toString().beginsWith("all");

		// Get the corpse's inventory.
		SceneObject* lootContainer = agent->getSlottedObject("inventory");

		if (lootContainer == nullptr) {
			return GENERALERROR;
		}

		PlayerManager* playerManager = zoneServer->getPlayerManager();

		if (playerManager == nullptr)
			return GENERALERROR;

		const ContainerPermissions* permissions = lootContainer->getContainerPermissions();

		if (permissions == nullptr)
			return GENERALERROR;

		// Determine the loot rights.
		uint64 ownerID = permissions->getOwnerID();

		bool looterIsOwner = (ownerID == creature->getObjectID());
		bool groupIsOwner = (ownerID == creature->getGroupID());

		// Allow player to loot the corpse if they own it.
		if (looterIsOwner) {
			if (lootAll) {
				playerManager->lootAll(creature, agent);
			} else {
				//Check if the corpse's inventory contains any items.
				if (lootContainer->getContainerObjectsSize() < 1) {
  					creature->sendSystemMessage("@error_message:corpse_empty"); //"You find nothing else of value on the selected corpse."
  					playerManager->rescheduleCorpseDestruction(creature, agent);
  				} else {
					agent->notifyObservers(ObserverEventType::LOOTCREATURE, creature, 0);
					lootContainer->openContainerTo(creature);
				}
			}

			return SUCCESS;
		}

		// If player and their group don't own the corpse, pick up any owned items left on corpse due to full inventory, then fail.
		if (!groupIsOwner) {
			int pickupResult = pickupOwnedItems(agent, creature, lootContainer);
			if (pickupResult < 2) { //Player didn't pickup an item nor is one available for them.
				StringIdChatParameter noPermission("error_message","no_corpse_permission"); //"You do not have permission to access this corpse."
				creature->sendSystemMessage(noPermission);
				return GENERALERROR;
			} else if (pickupResult == PICKEDANDEMPTY) {
				playerManager->rescheduleCorpseDestruction(creature, agent);
				return SUCCESS;
			}

			return SUCCESS;
		}

		// If looter's group is the owner, attempt to pick up any owned items, then process group loot rule.
		int pickupResult = pickupOwnedItems(agent, creature, lootContainer);

		switch (pickupResult) {
		case NOPICKUPITEMS: //No items available for anyone to pickup.
			break;
		case ITEMFOROTHER: //No items available for looter to pickup, but one is available for someone else.
			agent->notifyObservers(ObserverEventType::LOOTCREATURE, creature, 0);
			lootContainer->openContainerTo(creature);
			return SUCCESS;
		case PICKEDANDREMAINING: //An item was available for the looter, there are items remaining.
			return SUCCESS;
		case PICKEDANDEMPTY: //An item was available for the looter, there are NO items remaining.
			playerManager->rescheduleCorpseDestruction(creature, agent);
			return SUCCESS;
		default:
			break;
		}

		ManagedReference<GroupObject*> group = creature->getGroup();

		if (group == nullptr)
			return GENERALERROR;

		GroupLootTask* task = new GroupLootTask(group, creature, agent, lootAll);

		if (task != nullptr)
			task->execute();

		return SUCCESS;
	}

	/**
	 * Loots every corpse within AREALOOTRANGE that the player has rights to.
	 *
	 * Each corpse is run through the same ownership rules as a single-target loot:
	 * corpses the player owns are looted outright, corpses owned by the player's
	 * group go through GroupLootTask so the group's loot rule still decides, and
	 * anything else only gives up items already assigned to the player. Corpses the
	 * player has no claim on are skipped silently rather than spamming one
	 * permission error per body.
	 */
	int doAreaLoot(CreatureObject* creature) const {
		ZoneServer* zoneServer = server->getZoneServer();

		if (zoneServer == nullptr)
			return GENERALERROR;

		PlayerManager* playerManager = zoneServer->getPlayerManager();

		if (playerManager == nullptr)
			return GENERALERROR;

		Zone* zone = creature->getZone();

		if (zone == nullptr || creature->isDead())
			return GENERALERROR;

		// Snapshot the nearby creatures first. Looting cross-locks each corpse with
		// the player, so nothing may be held on the close objects vector while it
		// happens.
		SortedVector<TreeEntry*> closeObjects(512, 512);
		CloseObjectsVector* closeObjectsVector = (CloseObjectsVector*)creature->getCloseObjects();

		if (closeObjectsVector == nullptr) {
			zone->getInRangeObjects(creature->getPositionX(), creature->getPositionZ(), creature->getPositionY(), AREALOOTRANGE, &closeObjects, true);
		} else {
			closeObjectsVector->safeCopyReceiversTo(closeObjects, CloseObjectsVector::CREOTYPE);
		}

		Vector<ManagedReference<AiAgent*> > corpses;
		int beyondLimit = 0;

		for (int i = 0; i < closeObjects.size(); ++i) {
			SceneObject* object = static_cast<SceneObject*>(closeObjects.get(i));

			if (object == nullptr || object == creature || !object->isAiAgent())
				continue;

			AiAgent* agent = object->asAiAgent();

			if (agent == nullptr || !agent->isDead())
				continue;

			if (!checkDistance(creature, agent, AREALOOTRANGE))
				continue;

			if (corpses.size() >= AREALOOTMAXCORPSES) {
				++beyondLimit;
				continue;
			}

			corpses.add(agent);
		}

		if (corpses.size() == 0) {
			creature->sendSystemMessage("There are no corpses within range to loot.");
			return GENERALERROR;
		}

		int looted = 0;

		for (int i = 0; i < corpses.size(); ++i) {
			AiAgent* agent = corpses.get(i);

			if (agent == nullptr)
				continue;

			if (lootCorpseInArea(creature, agent, playerManager))
				++looted;
		}

		StringBuffer msg;

		if (looted == 0) {
			msg << "You do not have permission to loot any of the " << corpses.size();
			msg << (corpses.size() == 1 ? " corpse" : " corpses") << " within range.";
		} else {
			msg << "Looted " << looted << (looted == 1 ? " corpse" : " corpses") << " within range.";
		}

		if (beyondLimit > 0)
			msg << " " << beyondLimit << " more were left out of this sweep; run the command again to continue.";

		creature->sendSystemMessage(msg.toString());

		return SUCCESS;
	}

	/**
	 * Applies one corpse's worth of area looting. Returns true when the player was
	 * entitled to the corpse, whether or not it actually held anything.
	 */
	bool lootCorpseInArea(CreatureObject* creature, AiAgent* agent, PlayerManager* playerManager) const {
		uint64 ownerID = 0;
		bool emptyCorpse = false;

		{
			Locker locker(agent, creature);

			if (!agent->isDead() || creature->isDead())
				return false;

			SceneObject* lootContainer = agent->getSlottedObject("inventory");

			if (lootContainer == nullptr)
				return false;

			const ContainerPermissions* permissions = lootContainer->getContainerPermissions();

			if (permissions == nullptr)
				return false;

			ownerID = permissions->getOwnerID();

			bool looterIsOwner = (ownerID == creature->getObjectID());
			bool groupIsOwner = (ownerID == creature->getGroupID());

			// No claim on this corpse: take only items already assigned to this
			// player and leave the rest alone.
			if (!looterIsOwner && !groupIsOwner) {
				int pickupResult = pickupOwnedItems(agent, creature, lootContainer);

				if (pickupResult < PICKEDANDREMAINING)
					return false;

				if (pickupResult == PICKEDANDEMPTY) {
					locker.release();
					playerManager->rescheduleCorpseDestruction(creature, agent);
				}

				return true;
			}

			if (looterIsOwner)
				emptyCorpse = (lootContainer->getContainerObjectsSize() < 1) && (agent->getCashCredits() < 1);
		}

		// Both branches below take their own locks on the corpse, so the block above
		// has to have released first.
		if (ownerID == creature->getObjectID()) {
			if (emptyCorpse) {
				playerManager->rescheduleCorpseDestruction(creature, agent);
				return true;
			}

			playerManager->lootAll(creature, agent);

			return true;
		}

		ManagedReference<GroupObject*> group = creature->getGroup();

		if (group == nullptr)
			return false;

		// Honour the group's loot rule exactly as "/loot all" would on this corpse.
		GroupLootTask* task = new GroupLootTask(group, creature, agent, true);

		task->execute();

		return true;
	}

	int pickupOwnedItems(AiAgent* ai, CreatureObject* creature, SceneObject* lootContainer) const {
		/* Return codes:
		 * NOPICKUPITEMS: No items available for anyone to pickup.
		 * ITEMFOROTHER: No items available for looter to pickup, but one is available for someone else.
		 * PICKEDANDREMAINING: An item was available for the looter, there are items remaining.
		 * PICKEDANDEMPTY: An item was available for the looter, there are NO items remaining.
		 */

		bool attemptedPickup = false;
		bool pickupAvailableOther = false;

		int totalItems = lootContainer->getContainerObjectsSize();
		if (totalItems < 1) return NOPICKUPITEMS;

		ContainerPermissions* contPerms = lootContainer->getContainerPermissionsForUpdate();
		if (contPerms == nullptr) {
			return NOPICKUPITEMS;
		}

		SceneObject* playerInventory = creature->getSlottedObject("inventory");
		if (playerInventory == nullptr) {
			return NOPICKUPITEMS;
		}

		// Check each loot item to see if the player owns it.
		for (int i = totalItems - 1; i >= 0; --i) {
			SceneObject* object = lootContainer->getContainerObject(i);
			if (object == nullptr) continue;

			ContainerPermissions* itemPerms = object->getContainerPermissionsForUpdate();
			if (itemPerms == nullptr) continue;

			//Check if player owns the loot item.
			uint64 itemOwnerID = itemPerms->getOwnerID();
			if (itemOwnerID == creature->getObjectID()) {

				// Attempt to transfer the item to the player.
				attemptedPickup = true;
				if (playerInventory->isContainerFullRecursive()) {
					StringIdChatParameter full("group", "you_are_full"); //"Your Inventory is full."
					creature->sendSystemMessage(full);
					return PICKEDANDREMAINING;
				}

				uint64 originalOwner = contPerms->getOwnerID();
				contPerms->setOwner(creature->getObjectID());
				TransactionLog trx(ai, creature, object, TrxCode::NPCLOOTCLAIM);

				if (creature->getZoneServer()->getObjectController()->transferObject(object, playerInventory, -1, true)) {
					itemPerms->clearDenyPermission("player", ContainerPermissions::OPEN);
					itemPerms->clearDenyPermission("player", ContainerPermissions::MOVECONTAINER);
					trx.commit();
				} else {
					trx.abort() << "Failed to transferObject to player";
				}

				contPerms->setOwner(originalOwner);

			} else if (itemOwnerID != 0)
				pickupAvailableOther = true;
		}

		//Determine which result code to return.
		if (attemptedPickup) {
			if (lootContainer->getContainerObjectsSize() > 0)
				return PICKEDANDREMAINING;
			else
				return PICKEDANDEMPTY;
		}

		if (pickupAvailableOther)
			return ITEMFOROTHER;

		return NOPICKUPITEMS;
	}
};
#endif //LOOTCOMMAND_H_

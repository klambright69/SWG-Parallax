/*
 * StructureZoneComponent.cpp
 *
 *  Created on: Apr 15, 2012
 *      Author: TragD
 */

#include "StructureZoneComponent.h"
#include "server/zone/Zone.h"
#include "server/zone/objects/building/BuildingObject.h"
#include "server/zone/managers/creature/CreatureManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/creature/ai/AiAgent.h"
// 10/04/26 - AI / klambright
// Includes city-rank definitions and child-terminal permission types used by the startup bank configuration.
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/scene/variables/ContainerPermissions.h"
// --->END OF MODIFICATION<--
#include "templates/SharedObjectTemplate.h"

void StructureZoneComponent::notifyInsertToZone(SceneObject* sceneObject, Zone* zone) const {
	GroundZoneComponent::notifyInsertToZone(sceneObject, zone);

	// 10/04/26 - AI / klambright
	// Handles player-city bank installations directly because they are not BuildingObject instances and do not parse childCreatureObjects.
	// 10/11/26 AI / klambright - Aligns player-city bank junk-dealer access with the renamed rank-5 threshold; this runs during StructureZoneComponent::notifyInsertToZone for player-city bank templates.
	// --->END OF MODIFICATION<--
	// At server startup, Spaceport Township (rank 5) cities hide the persistent third-position bank terminal and spawn one junk dealer.
	// Below level 5, the dealer is removed and a bank terminal is restored if an older saved bank no longer has one.
	// CreatureManager handles dealer creation, and tracking it in the structure child list prevents duplicates on zone re-entry.
	// Rechecking the maintained city rank after restart makes the third position persistent with the city's current rank.
	const SharedObjectTemplate* objectTemplate = sceneObject->getObjectTemplate();
	if (objectTemplate != nullptr) {
		const String& templateName = objectTemplate->getFullTemplateString();
		bool isPlayerCityBank = templateName == "object/building/player/city/bank_corellia.iff"
			|| templateName == "object/building/player/city/bank_naboo.iff"
			|| templateName == "object/building/player/city/bank_tatooine.iff";

		if (isPlayerCityBank) {
			ManagedReference<CityRegion*> city = sceneObject->getCityRegion().get();
			// 10/11/26 AI / klambright - Checks against the canonical Spaceport Township rank constant, preserving the junk-dealer gate at rank 5 without depending on the legacy METROPOLIS alias.
			bool hasJunkDealerAccess = city != nullptr && city->getCityRank() >= CityRegion::RANK_SPACEPORT_TOWNSHIP;
			//--->END OF MODIFICATION<--
			SortedVector<ManagedReference<SceneObject*> >* children = sceneObject->getChildObjects();
			Vector3 bankPosition = sceneObject->getWorldPosition();
			float bankAngle = sceneObject->getDirection()->getRadians();
			Vector3 dealerPosition(
				bankPosition.getX() + Math::cos(bankAngle),
				bankPosition.getY() - Math::sin(bankAngle),
				bankPosition.getZ()
			);

			// 10/08/26 - AI / klambright
			// At city rank 5+, remove the position-3 banking terminal from both the live world and the saved structure children/database.
			// A world-only removal allowed the saved terminal to return during restart while the dealer was spawned again;
			// below rank 5, the existing restoration path recreates this terminal from the bank's saved structure context.
			bool bankTerminalFound = false;
			for (int i = 0; i < children->size();) {
				ManagedReference<SceneObject*> child = children->get(i);

				if (child == nullptr || child->getObjectTemplate() == nullptr
						|| child->getObjectTemplate()->getFullTemplateString() != "object/tangible/terminal/terminal_bank.iff") {
					++i;
					continue;
				}

				Vector3 childPosition = child->getPosition();
				float dx = childPosition.getX() - dealerPosition.getX();
				float dy = childPosition.getY() - dealerPosition.getY();
				float dz = childPosition.getZ() - dealerPosition.getZ();

				if ((dx * dx) + (dy * dy) + (dz * dz) > 0.0625f) {
					++i;
					continue;
				}

				bankTerminalFound = true;

				if (hasJunkDealerAccess) {
					Locker childLocker(child, sceneObject);
					children->drop(child);
					child->destroyObjectFromDatabase(true);
					child->destroyObjectFromWorld(true);
					continue;
				}

				++i;
			}
			// --->END OF MODIFICATION<--

			for (int i = 0; i < children->size();) {
				ManagedReference<SceneObject*> child = children->get(i);
				if (child != nullptr && child->isCreatureObject() && child->getObjectTemplate() != nullptr
						&& child->getObjectTemplate()->getFullTemplateString().contains("object/mobile/junk_")) {
					if (!hasJunkDealerAccess) {
						Locker childLocker(child, sceneObject);
						children->drop(child);
						child->destroyObjectFromWorld(true);
						continue;
					}
				}

				++i;
			}

			if (!hasJunkDealerAccess && !bankTerminalFound) {
				ZoneServer* zoneServer = zone->getZoneServer();
				if (zoneServer != nullptr) {
					ManagedReference<SceneObject*> bankTerminal = zoneServer->createObject(
						STRING_HASHCODE("object/tangible/terminal/terminal_bank.iff"), sceneObject->getPersistenceLevel());

					if (bankTerminal != nullptr) {
						Locker terminalLocker(bankTerminal, sceneObject);
						bankTerminal->initializePosition(dealerPosition.getX(), dealerPosition.getZ(), dealerPosition.getY());
						bankTerminal->updateDirection(bankAngle + Math::PI / 2.0f);

						if (zone->transferObject(bankTerminal, -1, true)) {
							ContainerPermissions* permissions = bankTerminal->getContainerPermissionsForUpdate();
							permissions->setOwner(sceneObject->getObjectID());
							permissions->setInheritPermissionsFromParent(false);
							permissions->setDefaultDenyPermission(ContainerPermissions::MOVECONTAINER);
							permissions->setDenyPermission("owner", ContainerPermissions::MOVECONTAINER);
							sceneObject->addChildObject(bankTerminal);
							bankTerminal->initializeChildObject(sceneObject);
						} else {
							bankTerminal->destroyObjectFromDatabase(true);
							error() << "Failed to place position-3 bank terminal for player-city bank "
								<< sceneObject->getObjectID();
						}
					} else {
						error() << "Failed to create position-3 bank terminal for player-city bank "
							<< sceneObject->getObjectID();
					}
				} else {
					error() << "Unable to restore position-3 bank terminal without a zone server for player-city bank "
						<< sceneObject->getObjectID();
				}
			}

			bool dealerAlreadyTracked = false;
			for (int i = 0; i < children->size(); ++i) {
				ManagedReference<SceneObject*> child = children->get(i);
				if (child != nullptr && child->isCreatureObject() && child->getObjectTemplate() != nullptr
						&& child->getObjectTemplate()->getFullTemplateString().contains("object/mobile/junk_")) {
					dealerAlreadyTracked = true;
					break;
				}
			}

			if (hasJunkDealerAccess && !dealerAlreadyTracked) {
				CreatureManager* creatureManager = zone->getCreatureManager();
				if (creatureManager != nullptr) {
					CreatureObject* dealer = creatureManager->spawnCreatureWithAi(STRING_HASHCODE("junk_dealer"),
						dealerPosition.getX(), dealerPosition.getZ(), dealerPosition.getY(), 0, false);

					if (dealer != nullptr) {
						Locker dealerLocker(dealer, sceneObject);
						dealer->updateDirection(bankAngle + Math::PI / 2.0f);
						if (dealer->isAiAgent()) {
							cast<AiAgent*>(dealer)->setRespawnTimer(60);
						}
						sceneObject->addChildObject(dealer);
					}
				}
			}
		}
	}
	// --->END OF MODIFICATION<--

	if (sceneObject->isBuildingObject()) {
		ManagedReference<BuildingObject*> building = cast<BuildingObject*>(sceneObject);
		if (building->hasTemplateChildCreatures()) {
			building->spawnChildCreaturesFromTemplate();
		}
	}
}

void StructureZoneComponent::notifyRemoveFromZone(SceneObject* sceneObject) const {
	GroundZoneComponent::notifyRemoveFromZone(sceneObject);

	//moved to StructureManager::destroyStructure
}

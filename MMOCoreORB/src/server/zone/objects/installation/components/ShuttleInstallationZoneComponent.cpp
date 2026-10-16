/*
 * ShuttleInstallationZoneComponent.cpp
 *
 * Created on: Apr 7, 2012
 *      Author: TragD
 */

#include "server/zone/objects/installation/components/ShuttleInstallationZoneComponent.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/planet/PlanetManager.h"
#include "server/zone/objects/structure/StructureObject.h"
#include "server/zone/objects/installation/InstallationObject.h"
#include "server/zone/objects/region/CityRegion.h"

void ShuttleInstallationZoneComponent::notifyInsertToZone(SceneObject* sceneObject, Zone* zone) const {
	StructureZoneComponent::notifyInsertToZone(sceneObject, zone);

	if (zone == nullptr) {
		return;
	}

	int bootDelay = ConfigManager::instance()->getInt("Core3.ShuttleZoneComponent.BootDelay", 5 * 60 * 1000);
	Reference<SceneObject*> sceneRef = sceneObject;
	Reference<Zone*> zoneRef = zone;

	// Re-Schedule the registering of player city shuttles with the map after the shuttles have started post boot delay
	Core::getTaskManager()->scheduleTask([sceneRef, zoneRef] () {
		if (sceneRef == nullptr || zoneRef == nullptr) {
			return;
		}

		Locker lock(sceneRef);

		zoneRef->unregisterObjectWithPlanetaryMap(sceneRef);
		zoneRef->registerObjectWithPlanetaryMap(sceneRef);

	}, "UpdateShuttleportMapLambda", bootDelay);
}

void ShuttleInstallationZoneComponent::notifyRemoveFromZone(SceneObject* sceneObject) const {
	StructureZoneComponent::notifyRemoveFromZone(sceneObject);
}

void ShuttleInstallationZoneComponent::destroyObjectFromWorld(SceneObject* sceneObject, bool sendSelfDestroy) const {
	if (sceneObject->isStructureObject()) {

		StructureObject* structureObject = cast<StructureObject*>(sceneObject);
		ManagedReference<Zone*> zone = sceneObject->getZone();

		if (zone != nullptr && structureObject->isInstallationObject()) {

			ManagedReference<InstallationObject*> installationObject = cast<InstallationObject*>(structureObject);

			if (installationObject->isShuttleInstallation()) {

				ManagedReference<CityRegion*> cityRegion = structureObject->getCityRegion().get();
				ManagedReference<PlanetManager*> planetManager = zone->getPlanetManager();

				if (cityRegion != nullptr) {
					// 10/12/26 klambright - Captures and clears the destroyed shuttle's ID under the city lock, then removes only its named travel point so one remaining shuttle keeps its route available.
					String travelPointName;
					{
						Locker clocker(cityRegion, sceneObject);
						travelPointName = cityRegion->getShuttleTravelPointName(sceneObject->getObjectID());
						cityRegion->removeShuttleInstallation(sceneObject->getObjectID());
					}
					planetManager->removePlayerCityTravelPoint(travelPointName);
					//--->END OF MODIFICATION - kl<--
				}

				SortedVector < ManagedReference<SceneObject*> > *childObjects = structureObject->getChildObjects();

				ManagedReference<CreatureObject*> shuttle = nullptr;

				for (int i = 0; i < childObjects->size(); ++i) {

					if (!childObjects->get(i)->isTerminal()) {
						shuttle = cast<CreatureObject*>(childObjects->get(i).get());
						break;
					}
				}

				if (shuttle != nullptr)
					planetManager->removeShuttle(shuttle);

			}
		}
	}

	GroundZoneComponent::destroyObjectFromWorld(sceneObject, sendSelfDestroy);
}

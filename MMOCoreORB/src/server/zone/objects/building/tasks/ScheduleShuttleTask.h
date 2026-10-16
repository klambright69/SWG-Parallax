
#ifndef SCHEDULESHUTTLETASK_H_
#define SCHEDULESHUTTLETASK_H_

#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/managers/planet/PlanetManager.h"
// 10/14/26 AI / klambright - Includes CityManager's complete generated interface because this task calls scheduleExtraShuttleCleanup; the PlanetManager include only forward-declares CityManager.
#include "server/zone/managers/city/CityManager.h"
//--->END OF MODIFICATION<--
// 10/14/26 AI / klambright - Includes child permissions so outdoor shuttle NPCs can resolve their owning port structure by the owner ID assigned during child creation.
#include "server/zone/objects/scene/variables/ContainerPermissions.h"
//--->END OF MODIFICATION<--
// 10/14/26 AI / klambright - Includes the structure definition needed to store each city shuttleport structure ID instead of its child shuttle-creature ID.
#include "server/zone/objects/structure/StructureObject.h"
//--->END OF MODIFICATION<--

class ScheduleShuttleTask : public Task, public Logger {
	ManagedWeakReference<CreatureObject*> shuttleObject;
	Zone* zone;

public:
	ScheduleShuttleTask(CreatureObject* shuttle, Zone* zon) : Task() {
		shuttleObject = shuttle;
		zone = zon;

		Logger::setLoggingName("ScheduleShuttleTask");
	}

	void run() {
		if (zone == nullptr) {
			error() << " zone has a nullptr.";
			return;
		}

		auto zoneServer = zone->getZoneServer();

		if (zoneServer == nullptr) {
			error() << " zoneServer is nullptr.";
			return;
		}

		if (zoneServer->isServerLoading()) {
			schedule(1000);
			return;
		}

		ManagedReference<CreatureObject*> strongShuttle = shuttleObject.get();

		if (strongShuttle == nullptr) {
			error() << " Shuttle strongShuttle has a nullptr in Zone: " << zone->getZoneName();
			return;
		}

		Locker lock(strongShuttle);

		ManagedReference<PlanetManager*> planetManager = zone->getPlanetManager();

		if (planetManager == nullptr) {
			zone->error() << " planetManager has a nullptr in Zone: " << zone->getZoneName();
			return;
		}

		ManagedReference<CityRegion*> cityRegion = strongShuttle->getCityRegion().get();

		// Player City
		if ((cityRegion != nullptr) && !cityRegion->isClientRegion()) {
			// 10/14/26 AI / klambright - Resolves the outdoor shuttle NPC's owning shuttleport from its container-permission owner ID; outdoor child NPCs do not have a SceneObject parent link.
			const ContainerPermissions* shuttlePermissions = strongShuttle->getContainerPermissions();
			uint64 shuttleportID = shuttlePermissions == nullptr ? 0 : shuttlePermissions->getOwnerID();
			ManagedReference<SceneObject*> shuttleportObject = nullptr;
			if (shuttleportID != 0)
				shuttleportObject = zoneServer->getObject(shuttleportID);
			StructureObject* shuttleport = shuttleportObject != nullptr && shuttleportObject->isStructureObject()
					? shuttleportObject.castTo<StructureObject*>()
					: nullptr;
			// 10/14/26 AI / klambright - Finds the shuttleport from its configured shuttle-NPC position when persisted child owner permissions do not resolve to the structure.
			ManagedReference<StructureObject*> matchingShuttleport = shuttleport;
			float closestDistanceSquared = 10000.0f;
			auto considerShuttleport = [&](StructureObject* candidate) {
				if (candidate == nullptr || !candidate->isShuttleInstallation())
					return;

				float deltaX = candidate->getWorldPositionX() - strongShuttle->getWorldPositionX();
				float deltaY = candidate->getWorldPositionY() - strongShuttle->getWorldPositionY();
				float distanceSquared = (deltaX * deltaX) + (deltaY * deltaY);
				if (distanceSquared < closestDistanceSquared) {
					closestDistanceSquared = distanceSquared;
					matchingShuttleport = candidate;
				}
			};

			if (matchingShuttleport == nullptr || !matchingShuttleport->isShuttleInstallation()) {
				matchingShuttleport = nullptr;
				for (int i = 0; i < cityRegion->getStructuresCount(); ++i)
					considerShuttleport(cityRegion->getCivicStructure(i));

				SortedVector<ManagedReference<TreeEntry*>> nearbyObjects;
				zone->getInRangeObjects(strongShuttle->getWorldPositionX(), 0, strongShuttle->getWorldPositionY(), 64, &nearbyObjects, true, false);
				for (int i = 0; i < nearbyObjects.size(); ++i) {
					SceneObject* nearbyObject = nearbyObjects.get(i).castTo<SceneObject*>();
					if (nearbyObject != nullptr && nearbyObject->isStructureObject())
						considerShuttleport(cast<StructureObject*>(nearbyObject));
				}
			}
			shuttleport = matchingShuttleport;
			//--->END OF MODIFICATION<--

			if (shuttleport == nullptr || !shuttleport->isShuttleInstallation()) {
				error() << " Unable to resolve owning city shuttleport structure for shuttle " << strongShuttle->getObjectID()
						<< " in " << zone->getZoneName() << "; permission owner ID " << shuttleportID << ", city civic structure count " << cityRegion->getStructuresCount();
				return;
			}
			//--->END OF MODIFICATION<--

			float x = strongShuttle->getWorldPositionX();
			float y = strongShuttle->getWorldPositionY();
			float z = strongShuttle->getWorldPositionZ();

			Vector3 arrivalVector(x, y, z);

			String zoneName = zone->getZoneName();

			Locker clocker(cityRegion, strongShuttle);

			// 10/14/26 AI / klambright - Registers the structure ID and migrates legacy NPC IDs, ensuring contraction cleanup and travel-point naming target the right shuttleport.
			cityRegion->setShuttleID(shuttleport->getObjectID(), strongShuttle->getObjectID());
			String travelPointName = cityRegion->getShuttleTravelPointName(shuttleport->getObjectID());
			// 10/14/26 AI / klambright - Restarts removal grace in Rank-8 cities with two shuttleports when a previous failed cleanup cleared the deadline.
			bool startMissingCleanup = cityRegion->getCityRank() < CityRegion::RANK_PLANETARY_CAPITAL
					&& cityRegion->getShuttleCount() > 1
					&& cityRegion->getExtraShuttleGraceDeadline() == 0;
			if (startMissingCleanup)
				cityRegion->setExtraShuttleGraceDeadline(System::getTime() + 1 * 1 * 20 * 60);
			//--->END OF MODIFICATION<--
			clocker.release();

			// klambright - Registers each city shuttle using its distinct travel-point name while preserving the original city-name destination for the primary shuttle.
			PlanetTravelPoint* planetTravelPoint = new PlanetTravelPoint(zoneName, travelPointName, arrivalVector, arrivalVector, strongShuttle, 6.f);

			planetManager->addPlayerCityTravelPoint(planetTravelPoint);
			planetManager->scheduleShuttle(strongShuttle, PlanetManager::SHUTTLEPORT);
			// 10/14/26 AI / klambright - Schedules recovered Rank-8 cleanup after releasing the city lock; persisted active deadlines keep their existing schedule.
			if (startMissingCleanup)
				zoneServer->getCityManager()->scheduleExtraShuttleCleanup(cityRegion);
			//--->END OF MODIFICATION<--
			//--->END OF MODIFICATION - kl<--
		} else {
			Reference<PlanetTravelPoint*> travelPoint = planetManager->getNearestPlanetTravelPoint(strongShuttle, 128.f);

			if (travelPoint == nullptr) {
				error() << " Planet Travel Point (travelPoint) has a nullptr in Zone: " << zone->getZoneName();
				return;
			}

			auto oldShuttle = travelPoint->getShuttle();

			if (oldShuttle == nullptr) {
				travelPoint->setShuttle(strongShuttle);

				if (travelPoint->isInterplanetary()) {
					planetManager->scheduleShuttle(strongShuttle, PlanetManager::STARPORT);
				} else {
					planetManager->scheduleShuttle(strongShuttle, PlanetManager::SHUTTLEPORT);
				}
			} else if (oldShuttle != strongShuttle) {
				strongShuttle->destroyObjectFromWorld(true);
				strongShuttle->destroyObjectFromDatabase(true);
			}
		}
	}
};

#endif /* SCHEDULESHUTTLETASK_H_ */

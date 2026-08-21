/*
 * PlaceDecorationComponent.cpp
 *
 *  Created on: Apr 8, 2013
 *      Author: root
 */

#include "PlaceDecorationComponent.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/managers/structure/StructureManager.h"

int PlaceDecorationComponent::placeStructure(StructureDeed* deed, CreatureObject* creature, float x, float y, int angle) const {
	if(creature == nullptr || creature->getZoneServer() == nullptr)
		return 1;

	ManagedReference<CityRegion*> city = creature->getCityRegion().get();

	if (city == nullptr) {
		// Decorations -- gardens, statues, fountains and the rest of the 54 deeds
		// using this component -- may only be placed inside city limits.
		//
		// This used to return silently. PlaceStructureCommand discards the return
		// value of placeStructure and reports SUCCESS regardless, so the deed
		// simply did nothing and the player was given no reason at all. The
		// equivalent check in StructureManager::placeStructureFromDeed already
		// sends this same string, but decorations are rejected here and never
		// reach it.
		creature->sendSystemMessage("@city/city:build_no_city"); // You must be in a city to place that structure.
		return 1;
	}

	CityManager* cityManager = creature->getZoneServer()->getCityManager();

	if (cityManager == nullptr) {
		creature->error("null cityManager in PlaceDecorationComponent::placeStructure");
		return 1;
	}

	if(!cityManager->canSupportMoreDecorations(city)) {
		StringIdChatParameter param("city/city", "no_more_decos");
		creature->sendSystemMessage(param);
		return 1;
	}

	StructureManager::instance()->placeStructureFromDeed(creature, deed, x, y, angle);

	return 0;
}

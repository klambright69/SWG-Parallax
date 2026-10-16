/*
 * CitySpecializationSessionImplementation.cpp
 *
 *  Created on: Feb 13, 2012
 *      Author: xyborn
 */

// 10/10/26 klambright - Reworks the existing city specialization SUI into a bounded toggle/apply selection flow. It preserves mayor-learned-ability gating, permits rank-appropriate subsets, uses server-only combination labels, and persists only a compact combination key through CityManager.
#include "server/zone/objects/player/sessions/CitySpecializationSession.h"
#include "server/zone/managers/city/CityManager.h"
#include "server/zone/objects/creature/CreatureObject.h"
#include "server/zone/objects/player/PlayerObject.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/objects/player/sui/SuiWindowType.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sui/messagebox/SuiMessageBox.h"
#include "server/zone/objects/player/variables/AbilityList.h"
#include "server/zone/objects/player/variables/Ability.h"
#include "server/zone/objects/player/sui/callbacks/CitySpecializationSuiCallback.h"
#include "server/zone/objects/player/sui/callbacks/CitySpecializationConfirmSuiCallback.h"
// klambright - Resolves existing base-specialization labels into server text for mixed prompt strings; new composite labels stay literal and require no client TRE entry.
#include "server/zone/managers/stringid/StringIdManager.h"

// klambright - Counts the fixed eight specialization bits for rank-limit display and server-side selection validation.
static int countSelectedSpecializations(uint16 mask) {
	int count = 0;

	while (mask != 0) {
		count += mask & 1;
		mask >>= 1;
	}

	return count;
}

// klambright - Converts legacy client string IDs only when embedding them in literal server-generated selection prompts.
static String resolveSpecializationDisplayName(const String& displayName) {
	if (displayName.beginsWith("@"))
		return StringIdManager::instance()->getStringId(displayName.hashCode()).toString();

	return displayName;
}

// klambright - Maps legacy trained city-specialization ability names to their stable bit values so menu options remain selectable even if localization labels differ from map keys.
static uint16 getSpecializationMaskForAbilityName(const String& abilityName) {
	if (abilityName == "city_spec_sample_rich")
		return 1;
	else if (abilityName == "city_spec_industry")
		return 2;
	else if (abilityName == "city_spec_doctor")
		return 4;
	else if (abilityName == "city_spec_cloning")
		return 8;
	else if (abilityName == "city_spec_research")
		return 16;
	else if (abilityName == "city_spec_missions")
		return 32;
	else if (abilityName == "city_spec_entertainer")
		return 64;
	else if (abilityName == "city_spec_stronghold")
		return 128;

	return 0;
}

// klambright - Uses the legacy base key for a one-bit selection and the generated mask key only for multi-specialization combinations.
static String getSpecializationKeyForMask(uint16 mask) {
	if (mask == 1)
		return "@city/city:city_spec_sample_rich";
	else if (mask == 2)
		return "@city/city:city_spec_industry";
	else if (mask == 4)
		return "@city/city:city_spec_doctor";
	else if (mask == 8)
		return "@city/city:city_spec_cloning";
	else if (mask == 16)
		return "@city/city:city_spec_research";
	else if (mask == 32)
		return "@city/city:city_spec_missions";
	else if (mask == 64)
		return "@city/city:city_spec_entertainer";
	else if (mask == 128)
		return "@city/city:city_spec_stronghold";

	return mask == 0 ? "" : "city_combo_" + String::valueOf(mask);
}

int CitySpecializationSessionImplementation::getMaximumSpecializations() {
	byte rank = cityRegion->getCityRank();

	if (rank == CityRegion::RANK_SPACEPORT_TOWNSHIP) {
		return 1;
	} else if (rank == CityRegion::RANK_INDUSTRIAL_NEO_CITY) {
		return 2;
	} else if (rank == CityRegion::RANK_UPPER_CITY_SPIRE) {
		return 4;
	} else if (rank == CityRegion::RANK_HIGH_SECTOR_CITADEL) {
		return 6;
	} else if (rank == CityRegion::RANK_PLANETARY_CAPITAL) {
		return 8;
	}

	return 0;
}

int CitySpecializationSessionImplementation::initializeSession() {
	PlayerObject* ghost = creatureObject->getPlayerObject();

	if (ghost == nullptr)
		return cancelSession();

	if (!cityRegion->isMayor(creatureObject->getObjectID()) && !ghost->isAdmin())
		return cancelSession();

	if (cityRegion->getCityRank() < CityRegion::RANK_SPACEPORT_TOWNSHIP) {
		creatureObject->sendSystemMessage("@city/city:no_rank_spec");
		return cancelSession();
	}

	CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();
	const CitySpecialization* currentSpec = cityManager->getCitySpecialization(cityRegion->getCitySpecialization());
	specializationMask = currentSpec == nullptr ? 0 : currentSpec->getSelectionMask();
	selectionCleared = false;

	return showSelectionMenu();
}

int CitySpecializationSessionImplementation::showSelectionMenu() {
	PlayerObject* ghost = creatureObject->getPlayerObject();

	if (ghost == nullptr)
		return cancelSession();

	ManagedReference<SuiListBox*> sui = new SuiListBox(creatureObject, SuiWindowType::CITY_SPEC, 0x00);
	sui->setPromptTitle("@city/city:city_specs_t");
	sui->setCallback(new CitySpecializationSuiCallback(creatureObject->getZoneServer()));
	sui->setUsingObject(terminalObject);
	sui->setForceCloseDistance(16.f);

	CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();
	String currentKey = getSpecializationKeyForMask(specializationMask);
	// klambright - Resolves the pending menu label by its established canonical key first; the direct mask API remains a fallback, avoiding false lookup failures between the session and the generated CityManager facade.
	const CitySpecialization* currentSpec = specializationMask == 0
			? nullptr : cityManager->getCitySpecialization(currentKey);
	if (currentSpec == nullptr && specializationMask != 0)
		currentSpec = cityManager->getCitySpecializationByMask(specializationMask);
	// klambright - Shows the selected base key when a legacy map entry is unavailable instead of incorrectly reporting None for a nonzero pending mask.
	String currentName = currentSpec == nullptr
			? (specializationMask == 0 ? "None" : resolveSpecializationDisplayName(currentKey))
			: resolveSpecializationDisplayName(currentSpec->getDisplayName());
	// continue
	sui->setPromptText("Toggle trained specializations, then apply. Selected: " + currentName
			+ " (" + String::valueOf(countSelectedSpecializations(specializationMask))
			+ "/" + String::valueOf(getMaximumSpecializations()) + ")");

	const AbilityList* abilityList = nullptr;

	if (cityRegion->isMayor(creatureObject->getObjectID())) {
		abilityList = ghost->getAbilityList();
	} else {
		ManagedReference<CreatureObject*> mayor = creatureObject->getZoneServer()->getObject(cityRegion->getMayorID()).castTo<CreatureObject*>();

		if (mayor != nullptr) {
			PlayerObject* mayorGhost = mayor->getPlayerObject();

			if (mayorGhost != nullptr)
				abilityList = mayorGhost->getAbilityList();
		}
	}

	int optionCount = 0;
	if (abilityList != nullptr) {
		for (int i = 0; i < abilityList->size(); ++i) {
			Reference<const Ability*> ability = abilityList->getSafe(i);
			const String& abilityName = ability->getAbilityName();

			if (!abilityName.beginsWith("city_spec"))
				continue;

			String specKey = "@city/city:" + abilityName;
			const CitySpecialization* spec = cityManager->getCitySpecialization(specKey);

			// 10/12/26 klambright - Derives selectable menu bits from the known trained ability rather than Lua-loaded record metadata, keeping the pending mask aligned with the canonical eight-specialization order.
			uint16 selectionBit = getSpecializationMaskForAbilityName(abilityName);
			if (selectionBit != 0) {
				sui->addMenuItem(spec == nullptr ? specKey : spec->getDisplayName(), selectionBit);
				++optionCount;
			}
			// continue
		}
	}

	if (optionCount == 0 && specializationMask == 0 && !selectionCleared) {
		creatureObject->sendSystemMessage("@city/city:no_specs");
		return cancelSession();
	}

	// 10/10/26 AI / klambright - Retains the prior explicit clear-specialization option, including when a new mayor has not learned the city's currently selected abilities.
	if (specializationMask != 0)
		sui->addMenuItem("Clear all specializations");
	// continue

	sui->addMenuItem("Apply selected specializations");
	ghost->addSuiBox(sui);
	creatureObject->sendMessage(sui->generateMessage());

	return 1;
}

int CitySpecializationSessionImplementation::toggleSpecialization(const String& choice) {
	if (cityRegion->getCityRank() < CityRegion::RANK_SPACEPORT_TOWNSHIP) {
		creatureObject->sendSystemMessage("@city/city:no_rank_spec");
		return 0;
	}

	uint16 selectionBit = 0;
	if (choice.beginsWith("MASK:")) {
		selectionBit = Integer::valueOf(choice.subString(5));
	} else {
		CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();
		const CitySpecialization* spec = cityManager->getCitySpecialization(choice);
		if (spec != nullptr)
			selectionBit = spec->getSelectionMask();
	}

	if (selectionBit == 0 || (selectionBit & (selectionBit - 1)) != 0 || selectionBit > 128)
		return showSelectionMenu();

	uint16 nextMask = specializationMask ^ selectionBit;
	int selectedCount = countSelectedSpecializations(nextMask);

	if (selectedCount > getMaximumSpecializations()) {
		creatureObject->sendSystemMessage("This city rank supports at most "
				+ String::valueOf(getMaximumSpecializations()) + " specializations.");
		return showSelectionMenu();
	}

	specializationMask = nextMask;
	return showSelectionMenu();
}

int CitySpecializationSessionImplementation::sendConfirmationBox(const String& choice) {
	PlayerObject* ghost = creatureObject->getPlayerObject();

	if (ghost == nullptr)
		return cancelSession();

	// 10/10/26 AI / klambright - Lets the mayor clear all current selections through the existing menu before confirming the empty set.
	if (choice == "Clear all specializations") {
		specializationMask = 0;
		selectionCleared = true;
		return showSelectionMenu();
	}
	// continue

	if (choice != "Apply selected specializations")
		return toggleSpecialization(choice);

	if (cityRegion->getCityRank() < CityRegion::RANK_SPACEPORT_TOWNSHIP) {
		creatureObject->sendSystemMessage("@city/city:no_rank_spec");
		return cancelSession();
	}

	if (specializationMask != 0 && !creatureObject->checkCooldownRecovery("city_specialization")) {
		StringIdChatParameter params("city/city", "spec_time");
		const Time* timeRemaining = creatureObject->getCooldownTime("city_specialization");
		params.setTO(String::valueOf(round(fabs(timeRemaining->miliDifference() / 1000.f))) + " seconds");
		creatureObject->sendSystemMessage(params);
		return cancelSession();
	}

	// klambright - Sends the selected bitmask to CityManager for canonical map resolution; the manager persists the resolved key rather than this transient selector.
	specialization = specializationMask == 0 ? "" : "city_mask_" + String::valueOf(specializationMask);
	CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();
	// klambright - Uses the same canonical persistence key used by terminal/report paths before falling back to mask lookup, so valid single and combined records are not rejected by the pre-confirmation UI check.
	const CitySpecialization* selectedSpec = specializationMask == 0
			? nullptr : cityManager->getCitySpecialization(getSpecializationKeyForMask(specializationMask));
	if (selectedSpec == nullptr && specializationMask != 0)
		selectedSpec = cityManager->getCitySpecializationByMask(specializationMask);
	// continue
	if (specializationMask != 0 && selectedSpec == nullptr) {
		creatureObject->sendSystemMessage("Unable to resolve the selected city specialization mask.");
		return showSelectionMenu();
	}

	String displayName = selectedSpec == nullptr
			? "None" : resolveSpecializationDisplayName(selectedSpec->getDisplayName());
	String confirmationText = resolveSpecializationDisplayName("@city/city:confirm_spec_d");

	SuiMessageBox* confirm = new SuiMessageBox(creatureObject, SuiWindowType::CITY_SPEC_CONFIRM);
	confirm->setPromptTitle("@city/city:confirm_spec_t");
	confirm->setPromptText(displayName + "\n\n" + confirmationText);
	confirm->setOkButton(true, "@yes");
	confirm->setCancelButton(true, "@no");
	confirm->setCallback(new CitySpecializationConfirmSuiCallback(creatureObject->getZoneServer()));

	ghost->addSuiBox(confirm);
	creatureObject->sendMessage(confirm->generateMessage());
	
	return 1;
}

int CitySpecializationSessionImplementation::acceptChoice() {
	CityManager* cityManager = creatureObject->getZoneServer()->getCityManager();
	cityManager->changeCitySpecialization(cityRegion, creatureObject, specialization);

	return cancelSession();
}
//--->END OF MODIFICATION- kl<--

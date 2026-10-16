/*
 * CitySpecialization.h
 *
 *  Created on: Jul 20, 2012
 *      Author: swgemu
 */

#ifndef CITYSPECIALIZATION_H_
#define CITYSPECIALIZATION_H_

class CitySpecialization : public Object {
	// 10/11/26 klambright - Stores display text, masks, and minimum eligible rank; the rank/mask matrix supplies combo names and final discounted costs while base-specialization persistence keys remain unchanged.
	String name;
	String displayName;
	int cost;
	int minimumCityRank;
	uint16 selectionMask;
	VectorMap<String, int> skillMods;
	// continue

public:
	CitySpecialization() {
		cost = 0;
		minimumCityRank = 0;
		selectionMask = 0;
		skillMods.setNoDuplicateInsertPlan();
		skillMods.setNullValue(0);
	}

	// 10/11/26 klambright - Stores matrix-provided rank eligibility and finalized cost with each generated combination so runtime city logic does not recalculate combo pricing.
	CitySpecialization(const String& name, const String& displayName, int cost, uint16 selectionMask, int minimumCityRank = 5) {
		this->name = name;
		this->displayName = displayName;
		this->cost = cost;
		this->minimumCityRank = minimumCityRank;
		this->selectionMask = selectionMask;
		skillMods.setNoDuplicateInsertPlan();
		skillMods.setNullValue(0);
	}

	// klambright - Copies only the base display/key/cost/mask and skill-mod data; combination labels now come from the separate mask matrix.
	CitySpecialization(const CitySpecialization& spec) : Object() {
		name = spec.name;
		displayName = spec.displayName;
		cost = spec.cost;
		minimumCityRank = spec.minimumCityRank;
		selectionMask = spec.selectionMask;
		skillMods = spec.skillMods;
	}

	CitySpecialization& operator=(const CitySpecialization& spec) {
		if (this == &spec)
			return *this;

		name = spec.name;
		displayName = spec.displayName;
		cost = spec.cost;
		minimumCityRank = spec.minimumCityRank;
		selectionMask = spec.selectionMask;
		skillMods = spec.skillMods;

		return *this;
	}

	// klambright - Assigns each base specialization its authoritative one-hot bit from the stable CitySpecializations array order, independent of stale, missing, or incorrect Lua id values; the ordered bits are required to resolve every generated combination mask.
	void readObject(LuaObject* luaObject, uint16 fallbackSelectionMask = 0) {
		name = luaObject->getStringField("name");
		displayName = luaObject->getStringField("displayName");
		cost = luaObject->getIntField("cost");
		minimumCityRank = luaObject->getIntField("minimumRank", 5);
		selectionMask = fallbackSelectionMask != 0
				? fallbackSelectionMask : luaObject->getIntField("id");

		LuaObject smods = luaObject->getObjectField("skillMods");

		for (int i = 1; i <= smods.getTableSize(); ++i) {
			LuaObject mod = smods.getObjectAt(i);

			if (mod.isValidTable()) {
				String k = mod.getStringAt(1);
				int v = mod.getIntAt(2);

				skillMods.put(k, v);
			}

			mod.pop();
		}

		smods.pop();
	}
	// continue

	inline const String& getName() const {
		return name;
	}

	inline const String& getDisplayName() const {
		return displayName;
	}

	inline int getCost() const {
		return cost;
	}

	inline int getMinimumCityRank() const {
		return minimumCityRank;
	}

	inline uint16 getSelectionMask() const {
		return selectionMask;
	}

	inline const VectorMap<String, int>* getSkillMods() const {
		return &skillMods;
	}

	inline void addSkillMod(const String& name, int value) {
		skillMods.put(name, skillMods.get(name) + value);
	}

	// 10/11/26 klambright - Updates all mask-matrix metadata together when a generated specialization combination is configured.
	inline void setCombinationData(const String& comboName, const String& comboDisplayName, int comboCost, uint16 comboMask, int comboMinimumRank) {
		name = comboName;
		displayName = comboDisplayName;
		cost = comboCost;
		selectionMask = comboMask;
		minimumCityRank = comboMinimumRank;
	}
};
//--->END OF MODIFICATION - kl<--

#endif /* CITYSPECIALIZATION_H_ */

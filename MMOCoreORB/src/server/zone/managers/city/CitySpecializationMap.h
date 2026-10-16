/*
 * CitySpecializationMap.h
 *
 *  Created on: Jul 20, 2012
 *      Author: swgemu
 */

#ifndef CITYSPECIALIZATIONMAP_H_
#define CITYSPECIALIZATIONMAP_H_

#include "server/ServerCore.h"
#include "CitySpecialization.h"

// 10/11/26 klambright
//  ***Heavily modified throughout***
//  Adds the server logger required to report invalid or incomplete Lua specialization matrix records while loading this map.
class CitySpecializationMap : public HashTable<String, CitySpecialization>, public Logger {
	// klambright - Retains the small base set for one-time generation of all valid selection masks, avoiding per-player allocation and repeated combinatorial work.
	Vector<CitySpecialization> baseSpecializations;
	
public:
	// klambright - Labels map validation errors with the specialization map's logger name.
	CitySpecializationMap() {
		setLoggingName("CitySpecializationMap");
	}
	
	// klambright - Resolves base entries by their original Lua key even if a hash-table lookup misses, and resolves any valid selection mask to its stable base or combo record.
	const CitySpecialization* getByName(const String& name) {
		if (containsKey(name))
			return &get(name);

		for (int i = 0; i < baseSpecializations.size(); ++i) {
			const CitySpecialization& base = baseSpecializations.get(i);
			if (base.getName() == name)
				return &base;
		}

		return nullptr;
	}

	const CitySpecialization* getBySelectionMask(uint16 mask) {
		if (mask == 0 || mask > 255)
			return nullptr;

		if ((mask & (mask - 1)) == 0) {
			for (int i = 0; i < baseSpecializations.size() && i < 8; ++i)
				if (mask == (1U << i))
					return &baseSpecializations.get(i);

			return nullptr;
		}

		StringBuffer comboKey;
		comboKey << "city_combo_" << mask;
		return getByName(comboKey.toString());
	}
	
	// klambright - Reads base records while CitySpecializations is the Lua stack top; LuaObject field access is stack-top-relative, so the matrix must be loaded in a separate call.
	void readBaseSpecializations(LuaObject* luaObject) {
		if (luaObject == nullptr || !luaObject->isValidTable())
			return;

		if (baseSpecializations.size() > 0)
			return;

		for (int i = 1; i <= luaObject->getTableSize(); ++i) {
			LuaObject spec = luaObject->getObjectAt(i);

			if (spec.isValidTable()) {
				CitySpecialization citySpec;
				// klambright - Supplies the authoritative one-hot mask from the established eight-entry Lua order so stale or malformed configured IDs cannot invalidate all combination records.
				uint16 fallbackMask = i <= 8 ? static_cast<uint16>(1 << (i - 1)) : 0;
				citySpec.readObject(&spec, fallbackMask);
				// continue

				put(citySpec.getName(), citySpec);
				baseSpecializations.add(citySpec);
			}

			spec.pop();
		}

		if (baseSpecializations.size() != 8) {
			error() << "Expected 8 base city specializations but loaded " << baseSpecializations.size()
					<< "; city specializations are unavailable.";
		}
		// continue
	}

	// 10/12/26 klambright - Builds all 247 combination records only while CitySpecializationsMatrix is the Lua stack top; sequential loading avoids LuaObject reading a different table than the one it wraps.
	void readSpecializationMatrix(LuaObject* specializationMatrix) {
		if (specializationMatrix == nullptr || !specializationMatrix->isValidTable())
			return;

		if (baseSpecializations.size() != 8) {
			error() << "Cannot build city specialization combinations without exactly 8 base records; loaded "
					<< baseSpecializations.size() << ".";
			return;
		}
		// continue

		for (uint16 mask = 1; mask <= 255; ++mask) {
			if ((mask & (mask - 1)) == 0)
				continue;

			StringBuffer comboKey;
			comboKey << "city_combo_" << mask;
			LuaObject comboData = specializationMatrix->getObjectField(String::valueOf(mask));
			if (!comboData.isValidTable()) {
				error() << "Missing city specialization matrix record for mask " << mask;
				comboData.pop();
				continue;
			}

			String comboDisplayName = comboData.getStringField("displayName");
			int comboCost = comboData.getIntField("cost");
			int minimumCityRank = comboData.getIntField("minimumRank");
			comboData.pop();

			if (comboDisplayName.isEmpty() || comboCost <= 0 || minimumCityRank < 6 || minimumCityRank > 9) {
				error() << "Invalid city specialization matrix record for mask " << mask;
				continue;
			}

			CitySpecialization combo(comboKey.toString(), comboDisplayName, comboCost, mask, minimumCityRank);

			for (int i = 0; i < baseSpecializations.size(); ++i) {
				uint16 baseBit = static_cast<uint16>(1U << i);
				if ((mask & baseBit) == 0)
					continue;

				const CitySpecialization& base = baseSpecializations.get(i);

				const VectorMap<String, int>* mods = base.getSkillMods();

				for (int j = 0; j < mods->size(); ++j) {
					const VectorMapEntry<String, int>& entry = mods->elementAt(j);
					combo.addSkillMod(entry.getKey(), entry.getValue());
				}
			}

			put(combo.getName(), combo);
		}
	}
};
//--->END OF MODIFICATION - kl<--

#endif /* CITYSPECIALIZATIONMAP_H_ */

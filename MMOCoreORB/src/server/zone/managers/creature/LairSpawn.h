/*
 * LairSpawn.h
 *
 *  Created on: 11/12/2011
 *      Author: victor
 */

#ifndef LAIRSPAWN_H_
#define LAIRSPAWN_H_

#include "engine/engine.h"

namespace server {
namespace zone {
namespace managers {
namespace creature {

	class LairSpawn : public Object {
	protected:
		int spawnLimit;
		int minDifficulty;
		int maxDifficulty;
		int numberToSpawn;
		int weighting;
		float size;

		// Multiplies the destroy mission credit reward for this lair only. Base reward
		// is difficulty * destroyMissionDifficultyRewardFactor, and difficulty is capped
		// by player/group level (max group level is 120), so a boss lair cannot pay past
		// that ceiling by difficulty alone. 1.0 leaves the reward untouched.
		float rewardMultiplier;

		String lairTemplateName;

	public:
		LairSpawn() : Object() {
			spawnLimit = -1;
			minDifficulty = 1;
			maxDifficulty = 1;
			numberToSpawn = 0;
			weighting = 1;
			size = 25;
			rewardMultiplier = 1.f;
		}

		LairSpawn(const LairSpawn& sp) : Object() {
			spawnLimit = sp.spawnLimit;
			minDifficulty = sp.minDifficulty;
			maxDifficulty = sp.maxDifficulty;
			numberToSpawn = sp.numberToSpawn;
			weighting = sp.weighting;
			size = sp.size;
			rewardMultiplier = sp.rewardMultiplier;

			lairTemplateName = sp.lairTemplateName;
		}

		LairSpawn& operator=(const LairSpawn& sp) {
			if (this == &sp)
				return *this;

			spawnLimit = sp.spawnLimit;
			minDifficulty = sp.minDifficulty;
			maxDifficulty = sp.maxDifficulty;
			numberToSpawn = sp.numberToSpawn;
			weighting = sp.weighting;
			size = sp.size;
			rewardMultiplier = sp.rewardMultiplier;

			lairTemplateName = sp.lairTemplateName;

			return *this;
		}

		void readObject(LuaObject& obj) {
			spawnLimit = obj.getIntField("spawnLimit");
			minDifficulty = obj.getIntField("minDifficulty");
			maxDifficulty = obj.getIntField("maxDifficulty");
			numberToSpawn = obj.getIntField("numberToSpawn");
			weighting = obj.getIntField("weighting");
			size = obj.getFloatField("size");
			rewardMultiplier = obj.getFloatField("rewardMultiplier");

			// Absent in lua reads back as 0; treat that as "leave the reward alone" so
			// every existing lair definition keeps exactly its current payout.
			if (rewardMultiplier <= 0.f)
				rewardMultiplier = 1.f;

			lairTemplateName = obj.getStringField("lairTemplateName");
		}

		float getRewardMultiplier() const {
			return rewardMultiplier;
		}

		int getSpawnLimit() const {
			return spawnLimit;
		}

		int getMinDifficulty() const {
			return minDifficulty;
		}

		int getMaxDifficulty() const {
			return maxDifficulty;
		}

		int getNumberToSpawn() const {
			return numberToSpawn;
		}

		int getWeighting() const {
			return weighting;
		}

		float getSize() const {
			return size;
		}

		const String& getLairTemplateName() const {
			return lairTemplateName;
		}
	};

}
}
}
}

using namespace server::zone::managers::creature;


#endif /* LAIRSPAWN_H_ */

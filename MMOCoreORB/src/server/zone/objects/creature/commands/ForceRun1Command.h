/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions. */

#ifndef FORCERUN1COMMAND_H_
#define FORCERUN1COMMAND_H_

#include "JediQueueCommand.h"

class ForceRun1Command : public JediQueueCommand {
public:

	ForceRun1Command(const String& name, ZoneProcessServer* server)
	: JediQueueCommand(name, server) {
		// BuffCRC's, first one is used.
		buffCRC = BuffCRC::JEDI_FORCE_RUN_1;
    
        // If these are active they will block buff use
		blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_2);
		blockingCRCs.add(BuffCRC::JEDI_FORCE_RUN_3);
    
    
		// Skill mods.
		skillMods.put("force_run", 1);
		skillMods.put("slope_move", 33);
	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		// Reactivating force run while it is already up cancels it rather than
		// erroring. removeBuff cascades to the buff's secondary CRCs, so the paired
		// private_damage_divisor buff on force run 2 and 3 comes off with it, and the
		// buff's own "@jedi_spam:remove_<name>" end message announces it to the player.
		if (creature->hasBuff(buffCRC)) {
			creature->removeBuff(buffCRC);
			return SUCCESS;
		}

		int res = doJediSelfBuffCommand(creature);
		// Return if something is in error.
		if (res != SUCCESS) {
			return res;
		}

		// SPECIAL - For Force Run.
		if (creature->hasBuff(STRING_HASHCODE("burstrun")) || creature->hasBuff(STRING_HASHCODE("retreat"))) {
			creature->removeBuff(STRING_HASHCODE("burstrun"));
			creature->removeBuff(STRING_HASHCODE("retreat"));
		}

		// Return.
		return SUCCESS;
	}

};

#endif //FORCERUN1COMMAND_H_

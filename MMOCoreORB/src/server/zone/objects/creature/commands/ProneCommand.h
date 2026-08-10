/*
				Copyright <SWGEmu>
		See file COPYING for copying conditions.*/

#ifndef PRONECOMMAND_H_
#define PRONECOMMAND_H_

#include "server/zone/objects/creature/commands/StandCommand.h"

class ProneCommand : public QueueCommand {
public:
	// Server tuning: was 1200. These per-command floors matched the retail
	// posture animation lengths, so they gated posture changes server side and
	// would override any client side animation speed modification. Lowered to
	// match StandCommand's 100ms, which stays as a spam guard rather than a
	// pacing mechanism.
	const static int MINDELTA = 100;

	ProneCommand(const String& name, ZoneProcessServer* server)
		: QueueCommand(name, server) {

	}

	int doQueueCommand(CreatureObject* creature, const uint64& target, const UnicodeString& arguments) const {
		if (!checkStateMask(creature))
			return INVALIDSTATE;

		if (!checkInvalidLocomotions(creature))
			return INVALIDLOCOMOTION;

		if (creature->isAiAgent()) {
			return setAiAgentPosture(creature);
		}

		if (creature->isPlayerCreature()) {
			return setPlayerPosture(creature);
		}

		creature->setPosture(CreaturePosture::PRONE);
		return SUCCESS;
	}

	int setAiAgentPosture(CreatureObject* creature) const {
		if (creature->isNonPlayerCreatureObject() && creature->isDizzied() && System::random(100) < 85) {
			creature->queueDizzyFallEvent();
			return SUCCESS;
		}

		creature->setPosture(CreaturePosture::PRONE);
		return SUCCESS;
	}

	int setPlayerPosture(CreatureObject* creature) const {
		const String& commandName = getQueueCommandName();

		if (creature->getQueueCommandDeltaTime("setPosture") < StandCommand::MINDELTA) {
			return GENERALERROR;
		}

		if (creature->getQueueCommandDeltaTime(commandName) < ProneCommand::MINDELTA) {
			return GENERALERROR;
		}

		if (creature->isDizzied() && System::random(100) < 85) {
			creature->queueDizzyFallEvent();
			return SUCCESS;
		}

		creature->setQueueCommandDeltaTime(commandName, "setPosture");
		creature->setPosture(CreaturePosture::PRONE);
		return SUCCESS;
	}
};

#endif //PRONECOMMAND_H_

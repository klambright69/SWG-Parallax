/*
 * CitySpecializationSuiCallback.h
 *
 *  Created on: Feb 13, 2012
 *      Author: xyborn
 */

#ifndef CITYSPECIALIZATIONSUICALLBACK_H_
#define CITYSPECIALIZATIONSUICALLBACK_H_

#include "server/zone/objects/player/sui/SuiCallback.h"
#include "server/zone/objects/player/sui/listbox/SuiListBox.h"
#include "server/zone/objects/player/sessions/CitySpecializationSession.h"

class CitySpecializationSuiCallback : public SuiCallback {
public:
	CitySpecializationSuiCallback(ZoneServer* server)
		: SuiCallback(server) {
	}

	void run(CreatureObject* player, SuiBox* suiBox, uint32 eventIndex, Vector<UnicodeString>* args) {
		bool cancelPressed = (eventIndex == 1);

		ManagedReference<CitySpecializationSession*> session = player->getActiveSession(SessionFacadeType::CITYSPEC).castTo<CitySpecializationSession*>();

		if (session == nullptr)
			return;

		if (!suiBox->isListBox() || cancelPressed || args->size() <= 0) {
			session->cancelSession();
			return;
		}

		int index = Integer::valueOf(args->get(0).toString());

		SuiListBox* listBox = cast<SuiListBox*>(suiBox);

		// 10/10/26 klambright - Rejects the end-exclusive list index before resolving a menu item, preventing an invalid SUI selection from reaching the toggle handler.
		if (index < 0 || index >= listBox->getMenuSize()) {
			session->cancelSession();
			return;
		}

		// klambright - Routes specialization rows by their stable bit value instead of their localized display label; action rows retain their textual commands.
		unsigned long long selectionBit = listBox->getMenuObjectID(index);
		if (selectionBit != 0)
			session->toggleSpecialization("MASK:" + String::valueOf(selectionBit));
		else
			session->sendConfirmationBox(listBox->getMenuItemName(index));
		//--->END OF MODIFICATION- kl<--
	}
};

#endif /* CITYSPECIALIZATIONSUICALLBACK_H_ */

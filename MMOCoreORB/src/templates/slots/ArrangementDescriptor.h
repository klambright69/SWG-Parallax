/*
 * ArrangementDescriptor.h
 *
 *  Created on: May 25, 2011
 *      Author: crush
 */

#ifndef ARRANGEMENTDESCRIPTOR_H_
#define ARRANGEMENTDESCRIPTOR_H_

#include "templates/IffTemplate.h"

class ArrangementDescriptor : public IffTemplate {
	Vector< Vector<String> > arrangementSlots;

public:
	ArrangementDescriptor() {
	}

	void readObject(IffStream* iffStream) {
		iffStream->openForm('ARGD');
		uint32 version = iffStream->getNextFormType();
		Chunk* versionForm = iffStream->openForm(version);

		switch (version) {
		case '0000':
		{
			for (int i = 0; i < versionForm->getChunksSize(); ++i) {
				Chunk* arg = iffStream->openChunk('ARG ');
				Vector<String>  slot;

				while (arg->hasData()) {
					String slotName;
					arg->readString(slotName);

					slot.add(slotName);
				}

				arrangementSlots.add(slot);

				iffStream->closeChunk('ARG ');
			}
		}

		break;
		}

		iffStream->closeForm(version);
		iffStream->closeForm('ARGD');
	}

	void clone(Vector< Vector<String> >& copyVec) const {
		arrangementSlots.clone(copyVec);
	}

	/**
	 * Returns a copy of this descriptor with the named slots dropped from every
	 * arrangement.
	 *
	 * Descriptors are cached by filename in TemplateManager and therefore shared by
	 * every object template that names the same arrangement file, so a template that
	 * wants to occupy fewer slots has to filter a copy instead of editing this one.
	 */
	/**
	 * Builds a descriptor with a single arrangement occupying exactly the given
	 * slots, for templates that need to claim something other than what their
	 * client arrangement file says.
	 */
	static Reference<ArrangementDescriptor*> fromSlots(const Vector<String>& slots) {
		Reference<ArrangementDescriptor*> descriptor = new ArrangementDescriptor();

		descriptor->arrangementSlots.add(slots);

		return descriptor;
	}

	Reference<ArrangementDescriptor*> cloneWithoutSlots(const Vector<String>& removedSlots) const {
		Reference<ArrangementDescriptor*> copy = new ArrangementDescriptor();

		for (int i = 0; i < arrangementSlots.size(); ++i) {
			const Vector<String>& slots = arrangementSlots.get(i);
			Vector<String> keptSlots;

			for (int j = 0; j < slots.size(); ++j) {
				const String& slot = slots.get(j);

				if (!removedSlots.contains(slot))
					keptSlots.add(slot);
			}

			copy->arrangementSlots.add(keptSlots);
		}

		return copy;
	}

	const Vector< Vector<String> >& getArrangementSlots() const {
		return arrangementSlots;
	}
};

#endif /* ARRANGEMENTDESCRIPTOR_H_ */

/*
 * IsVendorOwnerMessageCallback.h
 *
 *  Created on: 30/01/2010
 *      Author: victor
 */

#ifndef ISVENDOROWNERMESSAGECALLBACK_H_
#define ISVENDOROWNERMESSAGECALLBACK_H_

#include "server/zone/packets/MessageCallback.h"

#include "IsVendorOwnerResponseMessage.h"
#include "server/zone/objects/region/CityRegion.h"
#include "server/zone/Zone.h"

class IsVendorOwnerMessageCallback : public MessageCallback {
	uint64 oid;

public:
	IsVendorOwnerMessageCallback(ZoneClientSession* client, ZoneProcessServer* server) :
		MessageCallback(client, server) {

		oid = 0;
	}

	void parse(Message* message) {
		oid = message->parseLong();
	}

	void run() {
		ManagedReference<SceneObject*> sceno = server->getZoneServer()->getObject(oid);

		if (sceno == nullptr)
			return;

		Zone* zone = sceno->getZone();

		if (zone == nullptr)
			return;

		ManagedReference<CreatureObject*> player = client->getPlayer();

		if (player == nullptr)
			return;

		String planetString = zone->getZoneName();
		String vendorRegion = zone->getZoneName();


		ManagedReference<CityRegion*> cityRegion = sceno->getCityRegion().get();
		if (cityRegion != nullptr)
			vendorRegion = cityRegion->getCityRegionName();

		// 09/26/26 - AI / klambright: Tracks the Bazaar/vendor preflight request and its response for Dathomir so the market UI handshake can be separated from the later auction-query packet; interacts with object-menu market startup and IsVendorOwnerResponseMessage.
		bool villageBazaarDiagnostic = zone->getZoneName() == "dathomir";
		if (villageBazaarDiagnostic) {
			auto diagnostic = Logger::console.info(true);
			diagnostic << "[VillageBazaarDiagnostic] Vendor preflight received: object=" << oid << ", bazaar=" << sceno->isBazaarTerminal();
			diagnostic.flush();
		}
		// --->END OF MODIFICATION<---

		IsVendorOwnerResponseMessage* msg = new IsVendorOwnerResponseMessage(sceno, player, planetString, vendorRegion);
		client->sendMessage(msg);
		// 09/26/26 - AI / klambright: Confirms the server sent the market-availability/ownership preflight response for the Dathomir object; interacts with the client handoff that precedes Bazaar search.
		if (villageBazaarDiagnostic) {
			auto diagnostic = Logger::console.info(true);
			diagnostic << "[VillageBazaarDiagnostic] Vendor preflight response sent: object=" << oid << ", marketEnabled=" << player->getZoneServer()->getAuctionManager()->isMarketEnabled();
			diagnostic.flush();
		}
		// --->END OF MODIFICATION<---
	}
};


#endif /* ISVENDOROWNERMESSAGECALLBACK_H_ */

-- 09/25/26 - AI / klambright: Defines a Dathomir-specific shuttleport from the shared general shuttleport appearance with standard NPC shuttle, ticket terminal, and ticket collector child objects; this interacts with the building object registry, Dathomir Village screenplay, and normal shuttle travel behavior.
object_building_dathomir_shuttleport_dathomir = object_building_general_shared_shuttleport_general:new {
	planetMapCategory = "shuttleport",
	childObjects = {
		{templateFile = "object/tangible/terminal/terminal_travel.iff", x = -13, z = 0.6, y = -10, ox = 0, oy = -0.707107, oz = 0, ow = 0.707107, cellid = -1, containmentType = -1},
		{templateFile = "object/tangible/travel/ticket_collector/ticket_collector.iff", x = -13, z = 0.6, y = 10, ox = 0, oy = -0.707107, oz = 0, ow = 0.707107, cellid = -1, containmentType = -1},
		{templateFile = "object/creature/npc/theme_park/player_shuttle.iff", x = 0, z = 0.6, y = 0, ox = 0, oy = 1, oz = 0, ow = 0, cellid = -1, containmentType = -1}
	}
}

ObjectTemplates:addTemplate(object_building_dathomir_shuttleport_dathomir, "object/building/dathomir/shuttleport_dathomir.iff")

-- 09/25/26 - AI / klambright: Defines a Dantooine-specific shuttleport wrapper using the existing generic shuttleport building and standard child-object layout, without changing the shared generic template used elsewhere; this interacts with the Abandoned Rebel Base screenplay, travel routing, shuttle, ticket terminal, and ticket collector systems.
object_building_dantooine_shuttleport_dantooine = object_building_general_shared_shuttleport_general:new {
	planetMapCategory = "shuttleport",
	childObjects = {
		{templateFile = "object/tangible/terminal/terminal_travel.iff", x = -13, z = 0.6, y = -10, ox = 0, oy = -0.707107, oz = 0, ow = 0.707107, cellid = -1, containmentType = -1},
		{templateFile = "object/tangible/travel/ticket_collector/ticket_collector.iff", x = -13, z = 0.6, y = 10, ox = 0, oy = -0.707107, oz = 0, ow = 0.707107, cellid = -1, containmentType = -1},
		{templateFile = "object/creature/npc/theme_park/player_shuttle.iff", x = 0, z = 0.6, y = 0, ox = 0, oy = 1, oz = 0, ow = 0, cellid = -1, containmentType = -1}
	}
}
--->END OF MODIFICATION<---

ObjectTemplates:addTemplate(object_building_dantooine_shuttleport_dantooine, "object/building/dantooine/shuttleport_dantooine.iff")

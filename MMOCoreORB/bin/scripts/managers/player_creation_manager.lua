--Should all created players start with God Mode? 1 = yes, 0 = no
freeGodMode = 0;
--How many cash credits new characters start with after creating a character (changed during test phase, normal value is 100)
startingCash = 100000
--startingCash = 100000
--How many bank credits new characters start with after creating a character (changed during test phase, normal value is 1000)
startingBank = 1000000
--startingBank = 100000
--How many skill points a new characters start with
skillPoints = 250

professions = {
	"combat_brawler",
	"combat_marksman",
	"crafting_artisan",
	"outdoors_scout",
	"science_medic",
	"social_entertainer"
}

marksmanPistol = "object/weapon/ranged/pistol/pistol_cdef.iff"
	
marksmanRifle = "object/weapon/ranged/rifle/rifle_cdef.iff"

marksmanCarbine = "object/weapon/ranged/carbine/carbine_cdef.iff"

brawlerOneHander = "object/weapon/melee/knife/knife_stone.iff"

brawlerTwoHander = "object/weapon/melee/axe/axe_heavy_duty.iff"

brawlerPolearm = "object/weapon/melee/polearm/lance_staff_wood_s1.iff"

survivalKnife = "object/weapon/melee/knife/knife_survival.iff"

genericTool = "object/tangible/crafting/station/generic_tool.iff"

foodTool = "object/tangible/crafting/station/food_tool.iff"

mineralTool = "object/tangible/survey_tool/survey_tool_mineral.iff"

chemicalTool = "object/tangible/survey_tool/survey_tool_liquid.iff"

slitherhorn = "object/tangible/instrument/slitherhorn.iff"

marojMelon = "object/tangible/food/foraged/foraged_fruit_s1.iff"

x31Speeder = "object/tangible/deed/vehicle_deed/landspeeder_x31_deed.iff"

-- commonStartingItems below has always listed "swoopDeed", but the variable was
-- never defined, so it evaluated to nil and Lua's table length stopped short of
-- it -- new characters silently got no vehicle at all. Defined here so the entry
-- finally does something.
swoopDeed = "object/tangible/deed/vehicle_deed/speederbike_swoop_deed.iff"

-- Starting armour. Handed out in the inventory rather than worn, so the combined
-- encumbrance never blocks character creation -- the player equips what their HAM
-- pools can carry. These templates already carry usable stats (75 kinetic/energy,
-- 30000 condition); their own comment calls them "default Blue Frog stats".
--
-- Composite is 9 pieces and has no belt. It is NOT universal: its playerRaces
-- list omits Wookiees and Ithorians, so those two get their own sets below.
compositeHelmet     = "object/tangible/wearables/armor/composite/armor_composite_helmet.iff"
compositeChestPlate = "object/tangible/wearables/armor/composite/armor_composite_chest_plate.iff"
compositeLeggings   = "object/tangible/wearables/armor/composite/armor_composite_leggings.iff"
compositeBoots      = "object/tangible/wearables/armor/composite/armor_composite_boots.iff"
compositeGloves     = "object/tangible/wearables/armor/composite/armor_composite_gloves.iff"
compositeBicepL     = "object/tangible/wearables/armor/composite/armor_composite_bicep_l.iff"
compositeBicepR     = "object/tangible/wearables/armor/composite/armor_composite_bicep_r.iff"
compositeBracerL    = "object/tangible/wearables/armor/composite/armor_composite_bracer_l.iff"
compositeBracerR    = "object/tangible/wearables/armor/composite/armor_composite_bracer_r.iff"

-- Ithorian Sentinel: the ith_armor_s03 set, the only Ithorian line whose stats
-- match composite exactly (75 kinetic / 75 energy / 30000 condition). Also 9
-- pieces, so Ithorians get full parity.
ithSentinelHelmet     = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_helmet.iff"
ithSentinelChestPlate = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_chest_plate.iff"
ithSentinelLeggings   = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_leggings.iff"
ithSentinelBoots      = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_boots.iff"
ithSentinelGloves     = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_gloves.iff"
ithSentinelBicepL     = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bicep_l.iff"
ithSentinelBicepR     = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bicep_r.iff"
ithSentinelBracerL    = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bracer_l.iff"
ithSentinelBracerR    = "object/tangible/wearables/armor/ithorian_sentinel/ith_armor_s03_bracer_r.iff"

-- Kashyyykian Hunting: the closest Wookiee equivalent (80 kinetic / 75 energy /
-- 30000 condition). Only 4 pieces exist -- Wookiee armour has no helmet, boots,
-- gloves or biceps in the game data at all, so this IS a full Wookiee set.
kashHuntingChestPlate = "object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_chest_plate.iff"
kashHuntingLeggings   = "object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_leggings.iff"
kashHuntingBracerL    = "object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_bracer_l.iff"
kashHuntingBracerR    = "object/tangible/wearables/armor/kashyyykian_hunting/armor_kashyyykian_hunting_bracer_r.iff"

professionSpecificItems = {
	combat_brawler = { brawlerOneHander, brawlerTwoHander, brawlerPolearm },
	combat_marksman = { marksmanPistol, marksmanCarbine, marksmanRifle },
	crafting_artisan = { genericTool, mineralTool, chemicalTool },
	outdoors_scout = { genericTool },
	science_medic = { foodTool },
	social_entertainer = { slitherhorn }
}

-- NOTE: nil entries silently truncate this list, because the C++ side walks it
-- with getTableSize() (Lua '#'), which stops at the first nil. Every name here
-- must be defined above.
commonStartingItems = { marojMelon, survivalKnife, swoopDeed }

-- Starting items that depend on species. Keyed by the species part of the player
-- template ("object/creature/player/wookiee_male.iff" -> "wookiee"); any species
-- with no entry here falls back to "default".
--
-- This table exists because wearables are gated by their playerRaces list, so a
-- flat handout gives some species items they can never equip.
speciesSpecificItems = {
	default = {
		compositeHelmet, compositeChestPlate, compositeLeggings,
		compositeBoots, compositeGloves,
		compositeBicepL, compositeBicepR,
		compositeBracerL, compositeBracerR
	},

	ithorian = {
		ithSentinelHelmet, ithSentinelChestPlate, ithSentinelLeggings,
		ithSentinelBoots, ithSentinelGloves,
		ithSentinelBicepL, ithSentinelBicepR,
		ithSentinelBracerL, ithSentinelBracerR
	},

	wookiee = {
		kashHuntingChestPlate, kashHuntingLeggings,
		kashHuntingBracerL, kashHuntingBracerR
	}
}

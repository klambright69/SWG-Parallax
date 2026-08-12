--This setting determines if apprenticeship points are awarded for a player teaching another player a skill.
apprenticeshipEnabled = 1
-- Extra skill modifiers layered on top of the client datatable definitions.
-- SkillManager applies these after skills.iff and scripts/skills are loaded, so a
-- skill keeps every field from its normal definition and only gains the listed mod.
-- Overwrites the mod if the skill already defines it.
--
-- FRS ranks that grant a new robe also grant force power regen. Only the ranks
-- whose robe differs from the previous rank qualify: 0, 1, 5, 8 and 10. Ranks
-- 2-4 reuse the s02 robe, 6-7 reuse s03, 9 reuses s04 and 11 reuses s05.
-- Rank skills are cumulative -- FrsManager awards every rank skill at or below the
-- player's rank -- so these stack to +25 force power regen at rank 10.
additionalSkillModifiers = {
	{ skill = "force_rank_light_novice",  mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_light_rank_01", mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_light_rank_05", mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_light_rank_08", mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_light_rank_10", mod = "jedi_force_power_regen", value = 5 },

	{ skill = "force_rank_dark_novice",   mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_dark_rank_01",  mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_dark_rank_05",  mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_dark_rank_08",  mod = "jedi_force_power_regen", value = 5 },
	{ skill = "force_rank_dark_rank_10",  mod = "jedi_force_power_regen", value = 5 },
}

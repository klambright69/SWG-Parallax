dathomir_destroy_missions = {
	minLevelCeiling = 45,

	lairSpawns = {
		{
			lairTemplateName = "dathomir_brackaset_pigmy_neutral_small",
			minDifficulty = 8,
			maxDifficulty = 12,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_kwi_lair_neutral_small",
			minDifficulty = 8,
			maxDifficulty = 12,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_purbole_lair_neutral_medium_boss_01",
			minDifficulty = 14,
			maxDifficulty = 18,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_verne_bull_lair_neutral_large",
			minDifficulty = 14,
			maxDifficulty = 19,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_baz_nitch_lair_neutral_small",
			minDifficulty = 18,
			maxDifficulty = 22,
			size = 20,
		},
		{
			lairTemplateName = "dathomir_reptilian_mature_flyer_lair_neutral_large",
			minDifficulty = 18,
			maxDifficulty = 22,
			size = 30,
		},
		{
			lairTemplateName = "dathomir_malkloc_lair_neutral_large",
			minDifficulty = 19,
			maxDifficulty = 23,
			size = 35,
		},
		{
			lairTemplateName = "dathomir_bolma_lair_neutral_medium_boss_01",
			minDifficulty = 19,
			maxDifficulty = 27,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_malkloc_bull_lair_neutral_large",
			minDifficulty = 22,
			maxDifficulty = 28,
			size = 30,
		},
		{
			lairTemplateName = "dathomir_reptilian_ancient_flyer_lair_neutral_large",
			minDifficulty = 23,
			maxDifficulty = 27,
			size = 30,
		},
		{
			lairTemplateName = "dathomir_brackaset_lair_neutral_medium",
			minDifficulty = 24,
			maxDifficulty = 28,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_gaping_spider_lair_neutral_medium_boss_01",
			minDifficulty = 24,
			maxDifficulty = 28,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_stallion_bolma_lair_neutral_medium",
			minDifficulty = 27,
			maxDifficulty = 33,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_mutant_baz_nitch_lair_neutral_small",
			minDifficulty = 28,
			maxDifficulty = 32,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_giant_baz_nitch_lair_neutral_medium",
			minDifficulty = 33,
			maxDifficulty = 37,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_rhoa_kwi_lair_neutral_medium",
			minDifficulty = 33,
			maxDifficulty = 37,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_gaping_spider_recluse_lair_neutral_medium",
			minDifficulty = 42,
			maxDifficulty = 46,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_kamurith_snapper_lair_neutral_medium",
			minDifficulty = 42,
			maxDifficulty = 46,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_brackaset_surefoot_lair_neutral_medium",
			minDifficulty = 44,
			maxDifficulty = 48,
			size = 35,
		},
		{
			lairTemplateName = "dathomir_kamurith_nocuous_lair_neutral_medium",
			minDifficulty = 44,
			maxDifficulty = 48,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_bolma_craggy_lair_neutral_medium",
			minDifficulty = 45,
			maxDifficulty = 49,
			size = 25,
		},
		{
			lairTemplateName = "dathomir_kamurith_defiler_lair_neutral_medium_boss_01",
			minDifficulty = 48,
			maxDifficulty = 52,
			size = 35,
		},
		{
			lairTemplateName = "dathomir_rancor_lair_neutral_large",
			minDifficulty = 48,
			maxDifficulty = 52,
			size = 35,
		},
		{
			lairTemplateName = "dathomir_rancor_bull_lair_neutral_large",
			minDifficulty = 63,
			maxDifficulty = 67,
			size = 35,
		},
		{
			lairTemplateName = "dathomir_rancor_enraged_lair_neutral_large",
			minDifficulty = 78,
			maxDifficulty = 82,
			size = 35,
		},
		{
			lairTemplateName = "dathomir_rancor_enraged_bull_lair_neutral_large_boss_01",
			minDifficulty = 87,
			maxDifficulty = 91,
			size = 35,
		},
		{
			-- Ancient Bull Rancor. Difficulty is kept in line with the other rancor
			-- boss lairs because destroy missions are only offered when
			-- minDifficulty <= playerLevel + 5, and group level tops out around 120 --
			-- a difficulty high enough to pay 60k on its own would never be offered.
			-- rewardMultiplier lifts the payout instead:
			--   375 * 88..92 (+ small random) * 1.75  ~=  57,750 - 62,790 credits
			lairTemplateName = "dathomir_rancor_ancient_bull_lair_neutral_large",
			minDifficulty = 88,
			maxDifficulty = 92,
			rewardMultiplier = 1.75,
			size = 35,
		}
	}
}

addDestroyMissionGroup("dathomir_destroy_missions", dathomir_destroy_missions);

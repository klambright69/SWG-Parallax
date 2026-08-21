--Copyright (C) 2007 <SWGEmu>

--This File is part of Core3.

--This program is free software; you can redistribute
--it and/or modify it under the terms of the GNU Lesser
--General Public License as published by the Free Software
--Foundation; either version 2 of the License,
--or (at your option) any later version.

--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--See the GNU Lesser General Public License for
--more details.

--You should have received a copy of the GNU Lesser General
--Public License along with this program; if not, write to
--the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

--Linking Engine3 statically or dynamically with other modules
--is making a combined work based on Engine3.
--Thus, the terms and conditions of the GNU Lesser General Public License
--cover the whole combination.

--In addition, as a special exception, the copyright holders of Engine3
--give you permission to combine Engine3 program with free software
--programs or libraries that are released under the GNU LGPL and with
--code included in the standard release of Core3 under the GNU LGPL
--license (or modified versions of such code, with unchanged license).
--You may copy and distribute such a system following the terms of the
--GNU LGPL for Engine3 and the licenses of the other code concerned,
--provided that you include the source code of that other code when
--and as the GNU LGPL requires distribution of source code.

--Note that people who make modified versions of Engine3 are not obligated
--to grant this special exception for their modified versions;
--it is their choice whether to do so. The GNU Lesser General Public License
--gives permission to release a modified version without this exception;
--this exception also makes it possible to release a modified version
--which carries forward this exception.
-- Core3 Config File
-- 0 = false, 1 = true

Core3 = {
	------Server Make Options------
	MakeLogin = 1,
	MakeZone = 1,
	MakePing = 1,
	MakeStatus = 1,
	MakeWeb = 0,

	------ORB Server Config------
	ORB = "",
	ORBPort = 44419,

	------Main Database Config------
	DBHost = "127.0.0.1",
	DBPort = 3306,
	DBName = "swgemu",
	DBUser = "swgemu",
	DBPass = "123456",
	DBInstances = 2,
	DBSecret = "swgemus3cr37!", -- Change this! This value should be unique and of reasonable length.

	------Login Server Config------
	LoginPort = 44453,
	LoginProcessingThreads = 1,
	LoginAllowedConnections = 3000,
	LoginRequiredVersion = "20050408-18:00",

	------Mantis Database Config------
	MantisHost = "127.0.0.1",
	MantisPort = 3306,
	MantisName = "swgemu",
	MantisUser = "swgemu",
	MantisPass = "123456",
	MantisPrfx = "mantis_", -- The prefix for your mantis tables.

	------Metrics Server Config------
	MetricsHost = "localhost",
	MetricsPort = 8125,
	MetricsPrefix = "",

	------Ping Server Config------
	PingPort = 44462,
	PingAllowedConnections = 3000,

	------Zone Server config------
	ZoneProcessingThreads = 10,
	ZoneAllowedConnections = 30000,
	ZoneGalaxyID = 2, --The actual zone server's galaxyID. Should coordinate with your login server.

	-------- GROUND ZONES -------
	ZonesEnabled = {

	"corellia",
	"dantooine",
	"dathomir",
	"dungeon1",
	"endor",
	"lok",
	"naboo",
	"rori",
	"talus",
	"tatooine",
	"tutorial",
	"yavin4"
	-------- TEST ZONES -------
	--"09",
	--"10",
	--"11",
	--"character_farm",
	--"cinco_city_test_m5",
	--"creature_test",
	--"endor_asommers",
	--"floratest",
	--"godclient_test",
	--"otoh_gunga",
	--"rivertest",
	--"runtimerules",
	--"simple",
	--"taanab",
	--"test_wearables",
	--"umbra",
	--"watertabletest",
	},
	-------- SPACE ZONES -------
	SpaceZonesEnabled = {
		"space_corellia",
		"space_dantooine",
		"space_dathomir",
		"space_endor",
		"space_heavy1",
		"space_light1",
		"space_lok",
		"space_naboo",
		"space_tatooine",
		"space_yavin4"
		---- TEST ZONES ----
		--"space_09",
		--"space_corellia_2",
		--"space_env",
		--"space_halos",
		--"space_naboo_2",
		--"space_tatooine_2",
	},

	------TRE config------
	TrePath = "/home/ubuntu/Desktop/SWGEmu",
	TreFiles = {
		"default_patch.tre",
		"patch_sku1_14_00.tre",
		"patch_14_00.tre",
		"patch_sku1_13_00.tre",
		"patch_13_00.tre",
		"patch_sku1_12_00.tre",
		"patch_12_00.tre",
		"patch_11_03.tre",
		"data_sku1_07.tre",
		"patch_11_02.tre",
		"data_sku1_06.tre",
		"patch_11_01.tre",
		"patch_11_00.tre",
		"data_sku1_05.tre",
		"data_sku1_04.tre",
		"data_sku1_03.tre",
		"data_sku1_02.tre",
		"data_sku1_01.tre",
		"data_sku1_00.tre",
		"patch_10.tre",
		"patch_09.tre",
		"patch_08.tre",
		"patch_07.tre",
		"patch_06.tre",
		"patch_05.tre",
		"patch_04.tre",
		"patch_03.tre",
		"patch_02.tre",
		"patch_01.tre",
		"patch_00.tre",
		"data_other_00.tre",
		"data_static_mesh_01.tre",
		"data_static_mesh_00.tre",
		"data_texture_07.tre",
		"data_texture_06.tre",
		"data_texture_05.tre",
		"data_texture_04.tre",
		"data_texture_03.tre",
		"data_texture_02.tre",
		"data_texture_01.tre",
		"data_texture_00.tre",
		"data_skeletal_mesh_01.tre",
		"data_skeletal_mesh_00.tre",
		"data_animation_00.tre",
		"data_sample_04.tre",
		"data_sample_03.tre",
		"data_sample_02.tre",
		"data_sample_01.tre",
		"data_sample_00.tre",
		"data_music_00.tre",
		"bottom.tre"
	},

	------Status Server Config------
	StatusPort = 44455,
	StatusAllowedConnections = 500,
	StatusInterval = 30, -- interval to check if zone is locked up (in seconds)

	------Web Server Config------
	WebPorts = 44460, -- Can be multiple ports 44460,44461
	WebAccessLog = "../log/webaccess.log",
	WebErrorLog = "../log/weberror.log",
	WebSessionTimeout = 600, -- Length that inactive web sessions expire

	------Logging Config------
	LogFile = "log/core3.log",
	LogFileLevel = 4, -- -1 NONE, 0 FATAL, 1 ERROR, 2 WARNING, 3 LOG, 4 INFO, 5 DEBUG
	LogJSON = 0, -- global log output in JSON format
	LogSync = 0, -- flush global log file after each write
	LuaLogJSON = 0,
	PathfinderLogJSON = 0,
	PlayerLogLevel = 4, -- -1 NONE, 0 FATAL, 1 ERROR, 2 WARNING, 3 LOG, 4 INFO, 5 DEBUG
	MaxLogLines = 1000000, -- how often to rotate log (currently only log/player.log rotates)

	------REST Server Config------
	RESTServerPort = 0,

	------Account Config------
	InactiveAccountTitle = "Account Disabled",
	InactiveAccountText = "The server administrators have disabled your account.",

	------Character Config------
	CleanupMailCount = 25000,
	DeleteCharacters = 10, -- How often in minutes to purge deleted characters

	------Extra Config ------
	MaxNavMeshJobs = 6,
	MaxAuctionSearchJobs = 1,
	DumpObjFiles = 1,
	ProgressMonitors = "true",
	UnloadContainers = 1, -- Whether to unload container contents from RAM after the container hasn't been accessed for a time

	------Server Config------
	-- Everyone who damaged a creature earns the full experience award for the kill
	-- instead of a slice proportional to their share of the damage. A player who
	-- lands a few hits earns the same as one who did most of the work.
	--
	-- Only affects how the award is divided between attackers. The per-level cap
	-- (playerLevel * 300), the group bonus and the GCW bonus all still apply, and
	-- a player still earns nothing from a creature they never touched.
	FullExperienceCredit = "true",

	AiAgent = {
		-- How long a fleeing creature actually runs, in milliseconds. This is
		-- separate from the per-behaviour "delay" in scripts/ai/default.lua, which
		-- remains the cooldown controlling how soon that creature may flee again
		-- (Flee = 60s, RunAway = 30s). Before this existed the run time was derived
		-- from that same delay and worked out to delay-minus-6-seconds.
		FleeRunDurationMs = 10000,
	},

	-- The "Survey Event" minigame that interrupts sampling with a popup offering to
	-- focus the device on a concentrated node. False skips the popup and takes a
	-- normal sample instead; the code behind it is left intact, so setting this
	-- back to true restores it without a rebuild.
	SurveyMinigameEnabled = "false",

	-- Planets on which any structure may be built, ignoring the per-template
	-- allowedZones list. Applies to every structure placed from a deed: player
	-- houses, city buildings, faction headquarters and the rest.
	--
	-- These seven are the union of every structure template's own allowedZones, so
	-- the list adds no planet that refused structures before -- dathomir, endor and
	-- yavin4 permit none and stay that way. It only removes the restriction on
	-- which STYLE goes where, so a Naboo house can be built on Tatooine and a
	-- Corellian city hall on Naboo.
	--
	-- Widening only: a template's own allowedZones is checked first, so a planet a
	-- structure already permitted stays permitted. An empty list restores stock
	-- behaviour.
	StructurePlacementZones = {"corellia", "dantooine", "lok", "naboo", "rori", "talus", "tatooine"},

	-- Maximum units a factory run may pack into a single crate, overriding the
	-- per-schematic factoryCrateSize (which ships as 1 to 100). 0 keeps each
	-- schematic's own value. Schematics with a size of 1 still produce loose
	-- items rather than crates regardless of this setting.
	FactoryCrateSize = 1000,

	-- Character Builder ("Blue Frog") terminals. False removes all 28 of them from
	-- every planet: PlanetManager skips the planetObjects entries at load, and the
	-- terminal itself refuses both its radial and its SUI, so any copy placed by
	-- other means is inert too.
	CharacterBuilderEnabled = "false",
	AutoReg = 1,

	------Player Manager Config------
	PlayerManager = {
		-- Group invites work galaxy wide. /invite <name> resolves the target by name
		-- through the PlayerManager instead of requiring them in the inviter's scene,
		-- and group system messages switch from object IDs to names so distant
		-- clients can render them. Inviting your own pet still requires 120m.
		GalaxyWideGrouping = true,
	},

	------Shuttle Config------
	ShuttleZoneComponent = {
		-- Milliseconds after server start before shuttles register with their travel
		-- points. Until this elapses travel points have no shuttle, and ticket
		-- purchase fails silently in PurchaseTicketCommand. Stock is 5 minutes, which
		-- makes travel look broken after every restart.
		BootDelay = 30000,
	},

	------TOS Config------
	TermsOfServiceVersion = 0,
	TermsOfService = "",
}

-- NOTE: conf/config-local.lua is parsed after this file if it exists

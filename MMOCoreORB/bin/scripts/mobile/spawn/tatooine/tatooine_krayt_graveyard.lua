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

-- Krayt Dragon Graveyard, Tatooine (6650,4260) to (7680,5000).
--
-- Every krayt lair template in the game, and nothing else. The surrounding spawn
-- areas (north_eastern_krayt_background, eastern_dune_sea and the planet world
-- spawner) are carved or blocked around this box so that only these lairs can
-- spawn inside it.
--
-- Between them these six templates cover all krayt types:
--   canyon, juvenile canyon, giant canyon, adolescent, grand, ancient.

tatooine_krayt_graveyard = {
	lairSpawns = {
		{
			lairTemplateName = "tatooine_canyon_krayt_dragon_pack_neutral_none",
			spawnLimit = 6,
			minDifficulty = 122,
			maxDifficulty = 276,
			numberToSpawn = 0,
			weighting = 30,
			size = 20
		},
		{
			lairTemplateName = "tatooine_canyon_krayt_dragon_lair_neutral_large",
			spawnLimit = 4,
			minDifficulty = 122,
			maxDifficulty = 276,
			numberToSpawn = 0,
			weighting = 15,
			size = 30
		},
		{
			lairTemplateName = "tatooine_giant_canyon_krayt_dragon_pack_neutral_none",
			spawnLimit = 5,
			minDifficulty = 275,
			maxDifficulty = 304,
			numberToSpawn = 0,
			weighting = 20,
			size = 20
		},
		{
			lairTemplateName = "tatooine_giant_canyon_krayt_dragon_lair_neutral_large",
			spawnLimit = 3,
			minDifficulty = 275,
			maxDifficulty = 304,
			numberToSpawn = 0,
			weighting = 10,
			size = 30
		},
		{
			lairTemplateName = "tatooine_krayt_dragon_grand_neutral_none",
			spawnLimit = 3,
			minDifficulty = 320,
			maxDifficulty = 350,
			numberToSpawn = 0,
			weighting = 13,
			size = 20
		},
		{
			lairTemplateName = "tatooine_krayt_dragon_ancient_neutral_none",
			spawnLimit = 3,
			minDifficulty = 320,
			maxDifficulty = 350,
			numberToSpawn = 0,
			weighting = 12,
			size = 20
		},
	}
}

addSpawnGroup("tatooine_krayt_graveyard", tatooine_krayt_graveyard)

-- *** created exclusively for SWG Parallax use *** 
--
-- 10/11/26 architected by klambright, coded by VSCode (Github) AI
--
-- Defines city-rank names and deterministically builds the 247
-- specialization-combination records at server startup, from
-- the 8 base specializations. Source  vocabularies and mask
-- iteration keep display names identical across restarts and reboots;
-- persisted CityRegion state stores the city_combo_<mask> key,
-- which CitySpecializationMap resolves to the stable display name,
-- cost, and minimum rank. No per-boot randomness or per-city name
-- allocation is used.  Through associate file and code changes, this
-- information supercedes city.stf data as necessary and overrides 
-- tre file data for same.
--
-- For reference, the modified files for the matrix use are as follows:
--	city_manager.lua
--	CityManager.idl
--	CityManagerImplementation.cpp
--	CitySpecialization.h
--	CitySpecializationMap.h
--	CitySpecializationSession.idl
--	CitySpecializationSessionImplementation.cpp
--	CitySpecializationSuiCallback.h
--	CityRegion.idl
--	CityRegionImplementation.cpp

local SAMPLE_RICH          = 1
local MANUFACTURING_CENTER = 2
local MEDICAL_CENTER       = 4
local CLONE_LAB            = 8
local RESEARCH_CENTER      = 16
local IMPROVED_JOB_MARKET  = 32
local ENTERTAINMENT_DIST   = 64
local STRONGHOLD           = 128


--  Keeps server rank names consistent with CityManager and CityRegion; combo records use the minimum rank that allows their selected-specialization count.
CitySpecializationRankNames = {
	[1] = "Outpost",
	[2] = "Waystation Encampment",
	[3] = "Homestead Sector",
	[4] = "Guild Borough",
	[5] = "Spaceport Township",
	[6] = "Industrial Neo-City",
	[7] = "Upper City Spire",
	[8] = "High Sector Citadel",
	[9] = "Planetary Capital"
}

-- Defines distinct, readable, single-word prefixes 
-- specialization prefixes.  These words remain separate
-- from specialization-derived suffixes.

local PREFIXES_BY_RANK = {
	[6] = {
		"Industrial", "Foundry", "Refinery", "Reactor", "Catalyst", "Isotope", "Alloy",
		"Assembly", "Molecular", "Plasma", "Fusion", "Precision", "Automation", "Synthesis",
		"Transducer", "Substrate", "Metallurgy", "Hydraulics", "Kinetics", "Powerplant",
		"Production", "Polymer", "Machinery", "Fabrication", "Engineering", "Manufacturing",
		"Materials", "Fabricator"
	},
	[7] = {
		"Spire", "Apex", "Crown", "Pinnacle", "Summit", "Zenith", "Crest", "Highrise",
		"Skyscraper", "Arcology", "Megatower", "Tiered", "Stratified", "Vertical", "Ascendant", "Elevated",
		"Upper", "Overlook", "Penthouse", "Terrace", "Mezzanine", "Atrium", "Arcade", "Concourse",
		"Promenade", "Colonnade", "Rotunda", "Gallery", "Plaza", "Forum", "Esplanade", "Pavilion",
		"Balcony", "Veranda", "Catwalk", "Walkway", "Skybridge", "Midlevel", "Interlevel", "Sublevel",
		"Undercity", "Underworld", "Lower", "Foundational", "Subterranean", "Deep", "Sunken", "Nocturnal",
		"Shadowed", "Neon", "Luminous", "Fluorescent", "Bioluminescent", "Holo-lit", "Chromed", "Chrome",
		"Durasteel", "Transparisteel", "Glass", "Glazed", "Mirrored", "Polished", "Gleaming", "Prismatic",
		"Opulent", "Gilded", "Affluent", "Plush", "Regal", "Elite", "Luxe", "Prestige",
		"Sleek", "Modernist", "Streamlined", "Monolithic", "Monumental", "Spacious", "Ornate", "Civic",
		"Metropolitan", "Urban", "Congested", "Teeming", "Crowded", "Labyrinthine", "Warren", "Alley",
		"Backstreet", "Laneway", "Market", "Bazaar", "Arcaded", "Gritty", "Shadow", "Sump",
		"Service", "Utility", "Transit", "Elevator", "Lift", "Conduit", "Transitway", "Skyrail",
		"Tramline", "Causeway", "Overpass", "Underpass", "Crossway", "Connector", "Linkway", "Interchange",
		"Stacked", "Layered", "Stratum", "Strata", "Duplex", "Duality", "Contrasting", "Parallax",
		"Threshold", "Frontier", "Facade", "Canopy", "Rooftop", "Overhead"
	},
	[8] = {
		"Citadel", "Aegis", "Bastion", "Rampart", "Bulwark", "Sentinel", "Shielded", "Redoubt",
		"Guardian", "Watchful", "Fortress", "Fortification", "Stronghold", "Keep", "Bunker", "Battlement",
		"Parapet", "Embrasure", "Ramparting", "Palisade", "Stockade", "Blockhouse", "Redan", "Ravelin",
		"Outwork", "Barbican", "Curtain", "Motte", "Bailey", "Turreted", "Armored", "Armoured",
		"Defender", "Protector", "Warden", "Sentry", "Watchtower", "Guardhouse", "Garrison", "Armory",
		"Arsenal", "Ordnance", "Ballistic", "Tactical", "Strategic", "Security", "Perimeter", "Patrol",
		"Countermeasure", "Surveillance", "Command", "Deterrence", "Combat", "Warfare", "Barrier", "Shielding",
		"Forcefield", "Deflector", "Rayshield", "Particle", "Energy", "Ion", "Electromagnetic", "Kinetic",
		"Blastproof", "Reinforced", "Hardened", "Sealed", "Fortified", "Protected", "Impervious", "Resistant",
		"Invulnerable", "Impenetrable", "Secure", "Vigilant", "Watch", "Guard", "Defense", "Defence",
		"Sanctuary", "Haven", "Refuge", "Safehold"
	},
	[9] = {
		"Planetary", "Capital", "Coreward", "Worldline", "Systemic",
		"Central", "Sovereign", "Primacy", "Conclave"
	}
}

--  Uses complete technical terms associated with selected benefits
--  as suffixes, avoiding abbreviation fragments and nonsensical
--  concatenated phrases.

local THEMES_BY_SPECIALIZATION = {
	[SAMPLE_RICH] = {
		"Resource", "Survey", "Prospecting", "Geology", "Mineralogy", "Extraction", "Isotope", "Deposit", "Strata", "Assay",
		"Cartography", "Topography", "Seismic", "Spectrometry", "Geochemical", "Ore", "Crystallography", "Core-sampling",
		"Subsurface", "Resonance", "Radiometry", "Sedimentology", "Terraforming", "Hydrology", "Prospectus", "Fieldwork"
	},
	[MANUFACTURING_CENTER] = {
		"Fabrication", "Materials", "Alloy", "Assembly", "Foundry", "Metallurgy", "Polymer", "Machining", "Production", "Industrial",
		"Synthesis", "Engineering", "Mechanics", "Automation", "Toolmaking", "Forging", "Casting", "Refinement", "Nanofabrication",
		"Precision", "Isotope", "Powerplant", "Reactor", "Transmutation", "Composites", "Manufacture"
	},
	[MEDICAL_CENTER] = {
		"Clinical", "Biomedical", "Pathology", "Therapeutics", "Diagnostics", "Physiology", "Triage", "Surgery", "Pharmacology", "Anatomy",
		"Immunology", "Medtech", "Rejuvenation", "Bacta", "Treatment", "Neurobiology", "Tissue", "Regeneration", "Epidemiology",
		"Biochemistry", "Prosthetics", "Traumatology", "Wellness", "Cellular", "Care", "Medicine"
	},
	[CLONE_LAB] = {
		"Genomic", "Genetic", "Replication", "Heredity", "Cellular", "Chromosomal", "Sequencing", "Biometric", "Somatic", "Nucleic",
		"Inheritance", "Clone", "Biogenesis", "Genome", "Mitosis", "Phenotype", "Genotype", "Recombination", "Cytology", "Embryonic",
		"Organism", "Viability", "Lineage", "Biotech", "Transcription", "Cloning"
	},
	[RESEARCH_CENTER] = {
		"Scientific", "Analytical", "Experimental", "Hypothesis", "Empirical", "Quantum", "Hyperwave", "Data", "Theoretical", "Laboratory",
		"Observation", "Synthesis", "Discovery", "Investigation", "Modeling", "Simulation", "Computation", "Astrophysics", "Xenology",
		"Instrumentation", "Inference", "Research", "Spectral", "Applied", "Cognitive", "Mathematics"
	},
	[IMPROVED_JOB_MARKET] = {
		"Trade", "Commerce", "Logistics", "Supply", "Exchange", "Procurement", "Distribution", "Tariff", "Merchant", "Contract",
		"Employment", "Economic", "Bourse", "Consignment", "Freight", "Labor", "Accord", "Brokerage", "Enterprise", "Revenue",
		"Commodity", "Market", "Cargo", "Resource", "Guild", "Tradecraft"
	},
	[ENTERTAINMENT_DIST] = {
		"Holographic", "Performance", "Cultural", "Dramaturgy", "Broadcast", "Spectacle", "Choreography", "Acoustics", "Projection", "Arts",
		"Cantina", "Holonet", "Repertoire", "Resonance", "Presentation", "Theatrical", "Recreation", "Entertainment", "Narrative",
		"Composition", "Entertainment", "Spectral", "Orchestration", "Festival", "Illusion", "Artistry"
	},
	[STRONGHOLD] = {
		"Defensive", "Tactical", "Security", "Shielding", "Fortification", "Ballistic", "Garrison", "Armament", "Sentinel", "Countermeasure",
		"Perimeter", "Bastion", "Strategic", "Aegis", "Deterrence", "Ordnance", "Surveillance", "Command", "Warfare", "Protection",
		"Combat", "Containment", "Watchtower", "Barrier", "Patrol", "Sentry"
	}
}

local TECHNICAL_DESCRIPTORS = {
	"Complex", "Systems", "Protocol", "Network", "Matrix", "Synthesis", "Array", "Lattice", "Conduit", "Interface",
	"Framework", "Facility", "Institute", "Consortium", "Exchange", "Operations", "Program", "Initiative", "Design", "Analysis",
	"Development", "Technology", "Engineering", "Dynamics", "Architecture", "Infrastructure", "Method", "Practice", "Theory", "Process",
	"Module", "Platform", "Circuit", "Mechanism", "Procedure", "Standard", "Instrument", "Apparatus", "Generator", "Regulator",
	"Converter", "Amplifier", "Transducer", "Emitter", "Catalyst", "Integration", "Coordination", "Calibration", "Optimization", "Simulation",
	"Modeling", "Diagnostics", "Telemetry", "Control", "Guidance", "Navigation", "Ecology", "Education", "Diplomacy", "Stewardship",
	"Preservation", "Restoration", "Directorate", "Collective", "Consortium", "Archive", "Dossier", "Bureau", "Mandate", "Charter",
	"Expedition", "Observatory", "Repository", "Conservatory", "Academy", "Armature", "Emitter", "Dynamo", "Regulator", "Transceiver",
	"Relay", "Gateway", "Terminal", "Engine", "Drive", "Generator", "Computation", "Sequencer", "Fabricator", "Regeneration"
}

-- Supplies distinct, technical closing nouns for four-word
-- specialization names so added length reads as an established
-- facility or system rather than arbitrary concatenation.

local TECHNICAL_TERMINALS = {
	"Systems", "Network", "Operations", "Array", "Complex", "Protocol", "Infrastructure", "Facility",
	"Program", "Initiative", "Consortium", "Institute", "Exchange", "Matrix", "Platform", "Framework",
	"Lattice", "Interface", "Development", "Technology", "Engineering", "Architecture", "Process",
	"Module", "Circuit", "Apparatus", "Generator", "Regulator", "Converter", "Amplifier", "Integration",
	"Coordination", "Calibration", "Optimization", "Telemetry", "Control", "Guidance", "Navigation",
	"Directorate", "Collective", "Archive", "Bureau", "Mandate", "Charter", "Observatory", "Repository",
	"Academy", "Dynamo", "Transceiver", "Relay", "Gateway", "Terminal", "Engine", "Drive", "Sequencer"
}

local function removeDuplicateWords(words)
	local output = {}
	local seen = {}

	for _, word in ipairs(words) do
		if not seen[word] then
			seen[word] = true
			output[#output + 1] = word
		end
	end

	return output
end

TECHNICAL_DESCRIPTORS = removeDuplicateWords(TECHNICAL_DESCRIPTORS)

local SPECIALIZATION_COSTS = {}
local BASE_SPECIALIZATION_MASK = 0
local VALID_SPECIALIZATION_IDS = {
	[SAMPLE_RICH] = true,
	[MANUFACTURING_CENTER] = true,
	[MEDICAL_CENTER] = true,
	[CLONE_LAB] = true,
	[RESEARCH_CENTER] = true,
	[IMPROVED_JOB_MARKET] = true,
	[ENTERTAINMENT_DIST] = true,
	[STRONGHOLD] = true
}

for _, specialization in ipairs(CitySpecializations) do
	assert(VALID_SPECIALIZATION_IDS[specialization.id], "Invalid city specialization bit id: " .. tostring(specialization.id))
	assert(not SPECIALIZATION_COSTS[specialization.id], "Duplicate city specialization id: " .. tostring(specialization.id))
	SPECIALIZATION_COSTS[specialization.id] = specialization.cost
	BASE_SPECIALIZATION_MASK = BASE_SPECIALIZATION_MASK + specialization.id
end

assert(BASE_SPECIALIZATION_MASK == 255, "City specialization ids must define all eight mask bits")

local function countSelected(mask)
	local count = 0

	for bit = 0, 7 do
		if math.floor(mask / (2 ^ bit)) % 2 == 1 then
			count = count + 1
		end
	end

	return count
end

local function getMinimumRank(selectedCount)
	if selectedCount == 2 then
		return 6
	elseif selectedCount <= 4 then
		return 7
	elseif selectedCount <= 6 then
		return 8
	end

	return 9
end

local function getWordRoot(word)
	local lowerWord = word:lower()
	local knownRoots = {
		industrial = "industr",
		industry = "industr",
		industrialization = "industr",
		fabrication = "fabric",
		fabricator = "fabric",
		fabricate = "fabric",
		fabric = "fabric",
		manufacture = "manufactur",
		manufacturing = "manufactur",
		medical = "medic",
		medicine = "medic",
		medic = "medic",
		genomic = "gene",
		genetic = "gene",
		genetics = "gene",
		genome = "gene",
		gene = "gene",
		defensive = "defend",
		defense = "defend",
		defend = "defend",
		research = "research",
		researcher = "research",
		sample = "sample",
		sampling = "sample",
		holographic = "holo",
		hologram = "holo",
		holography = "holo",
		entertainment = "entertain",
		entertainer = "entertain",
		commerce = "commerc",
		commercial = "commerc",
		cultural = "culture",
		culture = "culture",
		clinical = "clinic",
		clinic = "clinic",
		biometric = "biometr",
		biometry = "biometr",
		resource = "resource",
		resources = "resource"
	}

	return knownRoots[lowerWord] or lowerWord
end

local function areSameRoot(firstWord, secondWord)
	return getWordRoot(firstWord) == getWordRoot(secondWord)
end

-- Tracks common adjective forms, including the rank-7
-- architectural, affluent, and undercity descriptors, so
-- generated names place descriptive terms before their nouns
-- instead of producing awkward adjective-noun reversals.

local PREFIX_ADJECTIVES = {
	Industrial = true, Molecular = true, Catalytic = true, Automated = true, Metallurgic = true,
	Kinetic = true, Aerial = true, Skyward = true, Elevated = true, Vertical = true, Ascendant = true,
	Tiered = true, Aeriform = true, Upward = true, Airborne = true, Windward = true, Leeward = true,
	Thermal = true, Boreal = true, Solar = true, Lunar = true, Stellar = true, Celestial = true,
	Galactic = true, Cosmic = true, Interstellar = true, Stratified = true, Turreted = true,
	Armored = true, Armoured = true, Ballistic = true, Tactical = true, Strategic = true,
	Electromagnetic = true, Blastproof = true, Reinforced = true, Hardened = true, Sealed = true,
	Fortified = true, Protected = true, Impervious = true, Resistant = true, Invulnerable = true,
	Impenetrable = true, Secure = true, Vigilant = true, Upper = true, Lower = true,
	Foundational = true, Subterranean = true, Nocturnal = true, Shadowed = true, Shadow = true, Deep = true,
	Sunken = true, Arcaded = true, Neon = true,
	Luminous = true, Fluorescent = true, Bioluminescent = true, ["Holo-lit"] = true, Chromed = true,
	Glazed = true, Mirrored = true, Polished = true, Gleaming = true, Prismatic = true, Opulent = true,
	Gilded = true, Affluent = true, Plush = true, Regal = true, Elite = true, Luxe = true, Sleek = true,
	Modernist = true, Streamlined = true, Monolithic = true, Monumental = true, Spacious = true,
	Ornate = true, Civic = true, Metropolitan = true, Urban = true, Congested = true, Teeming = true,
	Crowded = true, Labyrinthine = true, Gritty = true, Stacked = true, Layered = true, Contrasting = true
}

local THEME_ADJECTIVES = {
	Geological = true, Mineralogical = true, Seismic = true, Geochemical = true, Subsurface = true,
	Biomedical = true, Clinical = true, Diagnostic = true, Cellular = true, Embryonic = true,
	Genomic = true, Genetic = true, Chromosomal = true, Biometric = true, Somatic = true,
	Nucleic = true, Scientific = true, Analytical = true, Experimental = true, Empirical = true,
	Quantum = true, Hyperwave = true, Theoretical = true, Spectral = true, Applied = true,
	Economic = true, Cultural = true, Holographic = true, Theatrical = true, Defensive = true,
	Tactical = true, Strategic = true, Ballistic = true, Industrial = true, Molecular = true,
	Precision = true, Plasma = true, Fusion = true, Automated = true, Metallurgic = true,
}

local function getAvailableThemeWords(mask, usedThemes, rankThemes)
	local candidates = {}
	local seen = {}

	for _, id in ipairs({
		SAMPLE_RICH,
		MANUFACTURING_CENTER,
		MEDICAL_CENTER,
		CLONE_LAB,
		RESEARCH_CENTER,
		IMPROVED_JOB_MARKET,
		ENTERTAINMENT_DIST,
		STRONGHOLD
	}) do
		if math.floor(mask / id) % 2 == 1 then
			for _, theme in ipairs(THEMES_BY_SPECIALIZATION[id]) do
				if not seen[theme] then
					seen[theme] = true
					candidates[#candidates + 1] = theme
				end
			end
		end
	end

	local available = {}
	local startIndex = (mask % #candidates) + 1

	for offset = 0, #candidates - 1 do
		local index = ((startIndex + offset - 1) % #candidates) + 1
		local theme = candidates[index]

		if (usedThemes[theme] or 0) < 3 and not rankThemes[theme] then
			available[#available + 1] = theme
		end
	end

	return available
end

--  Arranges rank prefixes, specialization themes, and technical
--  terms into readable two-, three-, or four-word display names
--  with optional ampersand separators.

local function formatSpecializationName(prefix, theme, descriptor, terminal, contentWordCount, useAmpersand)
	local separator = useAmpersand and " & " or " "

	if contentWordCount == 4 then
		if PREFIX_ADJECTIVES[prefix] then
			return prefix .. " " .. theme .. separator .. descriptor .. " " .. terminal
		elseif THEME_ADJECTIVES[theme] then
			return theme .. " " .. prefix .. separator .. descriptor .. " " .. terminal
		end

		return theme .. separator .. descriptor .. " " .. prefix .. " " .. terminal
	elseif contentWordCount == 3 then
		if PREFIX_ADJECTIVES[prefix] then
			return prefix .. " " .. theme .. separator .. descriptor
		elseif THEME_ADJECTIVES[theme] then
			return theme .. " " .. prefix .. separator .. descriptor
		end

		return theme .. separator .. descriptor .. " " .. prefix
	elseif not PREFIX_ADJECTIVES[prefix] and not THEME_ADJECTIVES[theme] and useAmpersand then
		return prefix .. " & " .. theme
	elseif THEME_ADJECTIVES[theme] and not PREFIX_ADJECTIVES[prefix] then
		return theme .. " " .. prefix
	end

	return prefix .. " " .. theme
end

--  Builds longer labels from distinct selected-specialization themes
--  plus one technical terminal, preferring an ampersand when available
--  and rejecting names over 50 characters.

local function makeSuffix(mask, minimumRank, contentWordCount, useAmpersand, usedThemes, rankThemes, usedDescriptors, prefix)
	local themes = getAvailableThemeWords(mask, usedThemes, rankThemes)

	for _, theme in ipairs(themes) do
		if not areSameRoot(prefix, theme)
				and not (PREFIX_ADJECTIVES[prefix] and THEME_ADJECTIVES[theme]) then
			if contentWordCount == 2 then
				local displayName = formatSpecializationName(prefix, theme, nil, nil, contentWordCount, useAmpersand)
				if #displayName > 50 and useAmpersand then
					displayName = formatSpecializationName(prefix, theme, nil, nil, contentWordCount, false)
				end
				if #displayName <= 50 then
					usedThemes[theme] = (usedThemes[theme] or 0) + 1
					rankThemes[theme] = true
					return theme, nil, nil, displayName, displayName:find("&", 1, true) ~= nil
				end
			elseif contentWordCount == 3 then
				local startIndex = (mask % #TECHNICAL_DESCRIPTORS) + 1
				for offset = 0, #TECHNICAL_DESCRIPTORS - 1 do
					local index = ((startIndex + offset - 1) % #TECHNICAL_DESCRIPTORS) + 1
					local descriptor = TECHNICAL_DESCRIPTORS[index]

					if (usedDescriptors[descriptor] or 0) < 3
							and not areSameRoot(theme, descriptor)
							and not areSameRoot(prefix, descriptor) then
						if contentWordCount == 3 then
							local displayName = formatSpecializationName(prefix, theme, descriptor, nil, contentWordCount, useAmpersand)
							if #displayName > 50 and useAmpersand then
								displayName = formatSpecializationName(prefix, theme, descriptor, nil, contentWordCount, false)
							end
							if #displayName <= 50 then
								usedThemes[theme] = (usedThemes[theme] or 0) + 1
								rankThemes[theme] = true
								usedDescriptors[descriptor] = (usedDescriptors[descriptor] or 0) + 1
								return theme, descriptor, nil, displayName, displayName:find("&", 1, true) ~= nil
							end
						end
					end
				end
			elseif contentWordCount == 4 then
				local terminalStart = (mask % #TECHNICAL_TERMINALS) + 1
				for _, secondTheme in ipairs(themes) do
					if secondTheme ~= theme
							and not areSameRoot(theme, secondTheme)
							and not areSameRoot(prefix, secondTheme) then
						for terminalOffset = 0, #TECHNICAL_TERMINALS - 1 do
							local terminalIndex = ((terminalStart + terminalOffset - 1) % #TECHNICAL_TERMINALS) + 1
							local terminal = TECHNICAL_TERMINALS[terminalIndex]

							if (usedDescriptors[terminal] or 0) < 3
									and not areSameRoot(theme, terminal)
									and not areSameRoot(prefix, terminal)
									and not areSameRoot(secondTheme, terminal) then
								local displayName = formatSpecializationName(prefix, theme, secondTheme,
									terminal, contentWordCount, useAmpersand)
								if #displayName > 50 and useAmpersand then
									displayName = formatSpecializationName(prefix, theme, secondTheme,
										terminal, contentWordCount, false)
								end
								if #displayName <= 50 then
									usedThemes[theme] = (usedThemes[theme] or 0) + 1
									usedThemes[secondTheme] = (usedThemes[secondTheme] or 0) + 1
									rankThemes[theme] = true
									rankThemes[secondTheme] = true
									usedDescriptors[terminal] = (usedDescriptors[terminal] or 0) + 1
									return theme, secondTheme, terminal, displayName,
										displayName:find("&", 1, true) ~= nil
								end
							end
						end
					end
				end
			end
		end
	end

	assert(false, "No valid synergy suffix remains for city rank " .. tostring(minimumRank) .. " mask " .. tostring(mask))
end

-- Preserves each rank-themed prefix as a separate readable word,
-- validates uniqueness across all ranks, and supplies one stable
-- prefix per mask.

local function makePrefixMap()
	local prefixMap = {}
	local usedPrefixes = {}

	for _, rank in ipairs({6, 7, 8, 9}) do
		for _, prefix in ipairs(PREFIXES_BY_RANK[rank]) do
			assert(not prefix:find("%s"), "City specialization prefix must be one word: " .. prefix)
			assert(not usedPrefixes[prefix:lower()], "Duplicate city specialization prefix: " .. prefix)
			usedPrefixes[prefix:lower()] = true
			prefixMap[rank] = prefixMap[rank] or {}
			prefixMap[rank][#prefixMap[rank] + 1] = prefix
		end
	end

	return prefixMap
end

--  Generates one static name and discounted cost for each eligible
--  specialization mask. Enforces the two-, three-, and four-word
--  distribution, a 50-character limit, a maximum 50% ampersand use,
--  no more than three uses of any word, and no repeated suffix
--  theme within a rank.

CitySpecializationsMatrix = {}
local prefixesByRank = makePrefixMap()
local prefixIndexByRank = {[6] = 0, [7] = 0, [8] = 0, [9] = 0}
local nameCount = 0
local usedNames = {}
local wordUses = {}
local ampersandQuotas = {[6] = 24, [7] = 50, [8] = 24, [9] = 4}
local ampersandCounts = {[6] = 0, [7] = 0, [8] = 0, [9] = 0}
local rankThemes = {[6] = {}, [7] = {}, [8] = {}, [9] = {}}
local threeWordQuotas = {[6] = 14, [7] = 63, [8] = 42, [9] = 5}
local fourWordQuotas = {[6] = 6, [7] = 25, [8] = 17, [9] = 1}
local threeWordCounts = {[6] = 0, [7] = 0, [8] = 0, [9] = 0}
local fourWordCounts = {[6] = 0, [7] = 0, [8] = 0, [9] = 0}
local twoWordCount = 0
local threeWordCount = 0
local fourWordCount = 0

for _, prefixes in pairs(prefixesByRank) do
	for _, prefix in ipairs(prefixes) do
		wordUses[prefix] = (wordUses[prefix] or 0) + 1
	end
end

for selectedCount = 8, 2, -1 do
	for mask = 1, 255 do
		if countSelected(mask) == selectedCount then
			local minimumRank = getMinimumRank(selectedCount)
			local rankPrefixes = prefixesByRank[minimumRank]
			local prefixIndex = prefixIndexByRank[minimumRank] + 1
			local prefix = rankPrefixes[prefixIndex]

			assert(prefix ~= nil, "Not enough rank-specific prefixes for city rank " .. tostring(minimumRank))
			prefixIndexByRank[minimumRank] = prefixIndex

			local contentWordCount
			if fourWordCounts[minimumRank] < fourWordQuotas[minimumRank] then
				contentWordCount = 4
			elseif threeWordCounts[minimumRank] < threeWordQuotas[minimumRank] then
				contentWordCount = 3
			else
				contentWordCount = 2
			end
			local useAmpersand = ampersandCounts[minimumRank] < ampersandQuotas[minimumRank]
			local theme, descriptor, terminal, displayName, usedAmpersand = makeSuffix(mask,
				minimumRank, contentWordCount, useAmpersand,
				wordUses, rankThemes[minimumRank], wordUses, prefix)
			if usedAmpersand then
				ampersandCounts[minimumRank] = ampersandCounts[minimumRank] + 1
			end
			if contentWordCount == 4 then
				fourWordCounts[minimumRank] = fourWordCounts[minimumRank] + 1
				fourWordCount = fourWordCount + 1
			elseif contentWordCount == 3 then
				threeWordCounts[minimumRank] = threeWordCounts[minimumRank] + 1
				threeWordCount = threeWordCount + 1
			else
				twoWordCount = twoWordCount + 1
			end
			local baseCost = 0

			for _, id in ipairs({
				SAMPLE_RICH,
				MANUFACTURING_CENTER,
				MEDICAL_CENTER,
				CLONE_LAB,
				RESEARCH_CENTER,
				IMPROVED_JOB_MARKET,
				ENTERTAINMENT_DIST,
				STRONGHOLD
			}) do
				if math.floor(mask / id) % 2 == 1 then
					baseCost = baseCost + SPECIALIZATION_COSTS[id]
				end
			end

			local discount = selectedCount == 2 and 10
				or selectedCount <= 4 and 15
				or selectedCount <= 6 and 20
				or 25
			local totalCost = math.floor(baseCost * (100 - discount) / 100)

			assert(#displayName <= 50, "City specialization display name exceeds 50 characters: " .. displayName)
			assert(not usedNames[displayName], "Duplicate city specialization display name: " .. displayName)
			local wordCount = 0
			for _ in displayName:gmatch("%S+") do
				if _ ~= "&" then
					wordCount = wordCount + 1
				end
			end
			assert(wordCount == contentWordCount, "Unexpected word count for city specialization: " .. displayName)

			usedNames[displayName] = true
			CitySpecializationsMatrix[tostring(mask)] = {
				minimumRank = minimumRank,
				rankName = CitySpecializationRankNames[minimumRank],
				prefix = prefix,
				suffix = table.concat({theme, descriptor or "", terminal or ""}, " "):gsub("%s+$", ""),
				displayName = displayName,
				cost = totalCost
			}
			nameCount = nameCount + 1
		end
	end
end

for rank, prefixes in pairs(prefixesByRank) do
	assert(prefixIndexByRank[rank] == #prefixes, "Unused city specialization prefixes for rank " .. tostring(rank))
	assert(threeWordCounts[rank] == threeWordQuotas[rank], "Unexpected three-word name count for rank " .. tostring(rank))
	assert(fourWordCounts[rank] == fourWordQuotas[rank], "Unexpected four-word name count for rank " .. tostring(rank))
end

assert(nameCount == 247, "City specialization matrix must contain 247 combinations")
assert(twoWordCount == 74 and threeWordCount == 124 and fourWordCount == 49,
	"City specialization names must use the requested 30/50/20 word-count distribution")
local ampersandCount = 0
for _, rankCount in pairs(ampersandCounts) do
	ampersandCount = ampersandCount + rankCount
end
assert(ampersandCount <= math.floor(nameCount * 0.5), "City specialization ampersand usage exceeds 50%")


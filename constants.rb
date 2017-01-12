require 'yaml'
require 'pp'
require 'pry'
skills = YAML.load_file('skills.yaml')
spells = YAML.load_file('spells.yaml')
CONSTANTS = {
  attributes: %i(Body Quickness Strength Charisma Intelligence Willpower),
  attrinfo: [:BA, :RM, :CM, :BM, :MM, :ACT, :Points],
  gender: [:Male, :Female],
  metatypes: YAML.load_file('metas.yaml'),
  cyberware: YAML.load_file('cyberyaml'),
  weapons: YAML.load_file('gearyaml'),
  armors: YAML.load_file('armoryaml'),
  magetypes: {
    None: { Points: 0, Spellpoints: 0 },
    'Full Magician': { Points: 30, Spellpoints: 25 },
    'Full Shaman': { Points: 30, Spellpoints: 25 },
    'Conjurer Mage': { Points: 25, Spellpoints: 0 },
    'Conjurer Shaman': { Points: 25, Spellpoints: 0 },
    Elementalist: { Points: 25, Spellpoints: 35 },
    Shamanist: { Points: 25, Spellpoints: 35 },
    'Sorcerer Mage': { Points: 25, Spellpoints: 35 },
    'Sorcerer Shaman': { Points: 25, Spellpoints: 35 },
    Adept: { Points: 25, Spellpoints: 0 },
    'Adept Magician': { Points: 30, Spellpoints: 0 }
  },
  subspelltypes: {Manipulation: [:Telekinetic,:Control,
                                    :Transformation,:Elemental],
                  Illusion: [:Direct, :Indirect]},

  spelltypes: {
     Combat: spells["Combat"], Detection: spells["Detection"],
    Health: spells["Health"],
    Illusion: {Direct: spells["Illusion"]["Direct"], 
                  Indirect: spells["Illusion"]["Indirect"]},
    Manipulation: {Telekinetic: spells["Manipulation"]["Telekinetic"],
                      Control: spells["Manipulation"]["Control"], 
                      Transformation: spells["Manipulation"]["Transformation"],
                      Elemental: spells["Manipulation"]["Elemental"] }
  },
  nuyen: {
    -5 => 500, 0 => 5000, 5 => 20_000, 10 => 90_000, 15 => 200_000,
    20 => 400_000, 25 => 650_000, 30 => 1_000_000
  },
  grades: {
    Normal: { Price: 1, Essence: 1, Avail: [['*', 1], ['*', 1]], Space: 1 },
    Alpha: { Price: 2, Essence: 0.8, Avail: [['*', 1], ['*', 1]], Space: 0.9 },
    Beta: { Price: 4, Essence: 0.6, Avail: [['+', 5], ['*', 1.5]], Space: 0.8 },
    Delta: { Price: 8, Essence: 0.5, Avail: [['+', 9], ['*', 3]], Space: 0.75 },
    Used: { Price: 0.5, Essence: 1, Avail: [['*', 1], ['*', 1]], Space: 1 }
  },
  derived: {
    Reaction: [:Base, :CBM, :Rigg, :Deck, :Astral],
    Initiative: [:Base, :CBM, :Rigg, :Deck, :Astral],
    Pools: [:'Combat Pool', :'Astral Pool', :'Magic Pool',
            :'Hacking Pool', :'Control Pool']
  },
  special: [:Essence, :'Body Index', :Magic],
  activeskills: skills,
  totems: {
    animal: {
      badger: {
        environment: 'Forest', spells: [[:Combat, 2]], spirits: [[:Forest, 1]],
        desc: 'May go berserk in combat like Bear shaman',
        properties: 'Curious, Fighter, Hunter, Fierce Defender of Property'
      },
      bat: {
        environment: 'Anywhere', spells: [[:Detection, 2], [:Manipulation, 2]],
        spirits: [[:Sky, 1]], desc: '+2 to all magical TN in direct sunlight',
        properties: 'Adaptable, Restless, Seeker'
      },
      bear: {
        environment: 'Forest', spells: [[:Health, 2]], spirits: [[:Prairie, 2]],
        desc: 'May go berserk in combat. Willpower(4) test if wounded, Berserk
  		  rage lasts for 3 turns, every success on test substracts a turn, rage
  		  can be avoided with 3 successes. Berserk Bear will attack whoever is
  		  closest with most powerful weapons, rage ends if target is
  		  incapacitated',
        properties: 'Slow Moving, Easy Going, Healers, Savage When Angered'
      },
      boar: {
        environment: 'Forest', spells: [[:Combat, 2], [:Illusion, -1]],
        desc: '+1 service from any summoned spirit for Combat purposes,
  		Willpower(6) test to withdraw from conflict',
        properties: 'Aggressive, Territorial, Blatant, Not A Real Thinker'
      },
      buffalo: {
        environment: 'Plains', spells: [[:Health, 2], [:Illusion, -1]],
        spirits: [[:Prairie, 2]],
        properties: 'Healers, Helpers, Self-Sacrificing'
      },
      bull: {
        environment: 'Forest,Mountains,Plains', req: [[:Charisma, 4]],
        spells: [[:Health, 2], [:Detection, 1], [:Combat, 1]],
        properties: 'Proud, Protector, Leader, Generous to Freinds,
  		Aggressive to Those Who Threaten Herd'
      },
      cat: {
        environment: 'Urban', spells: [[:Illusion, 2]], spirits: [[:City, 2]],
        desc: '+1 all Mental target numbers if not clean. Unwounded Shaman make
  		  Willpower(6) test to cast damaging spell, cast least-damaging spell at
  		  1/2 force if it fails. Ignore if wounded',
        properties: 'Vain, Sly, Clean, Aloof, Toy with Prey'
      },
      cheetah: {
        environment: 'Savannah', req: [[:Reaction, 4]],
        spells: [[:Combat, 2], [:Health, -1]], spirits: [[:Prairie, 2]],
        properties: 'Fast, Multi-skilled, Warrior'
      },
      coyote: {
        environment: 'Anywhere on land',
        properties: 'Unpredictable, Trickster, Curious'
      },
      crab: {
        environment: 'On or by the sea', spells: [[:Illusion, -1]],
        spirits: [[:Sea, 2]], desc: '+1 die for all damage resistance tests
  		  including drain, willpower(6) test to change mind, complex
  		  action',
        properties: 'Grumpy, Steadfast in his ways, work focussed'
      },
      crocodile: {
        environment: 'On or by the sea', spells: [[:Combat, 2], [:Illusion, 1]],
        spirits: [[:Sea, 2]], desc: 'May go berserk like Shark shaman',
        properties: 'Savage Hunter, Wanderer'
      },
      dog: {
        environment: 'Urban', spells: [[:Detection, 2]],
        spirits: [[:Field, 2], [:Hearth, 2]], desc: 'Willpower(6) test to 
        change course of action, complex action',
        properties: 'Loyal, Generous, Stubborn, Savage Defender of Home'
      },
      dolphin: {
        environment: 'On or by the sea', spells: [[:Combat, -1], 
        [:Detection, 2]], spirits: [[:Sea, 2]],
        properties: 'Playful, Wise, Protectors, Helpers, Anti-Evil'
      },
      dove: {
        environment: 'Forests', spells: [[:Health, 2], [:Detection, 1]],
        spirits: [[:Sky, 1]], desc: 'Cannot cast Combat spells, Willpower(6) 
        Test to purposefully inflict harm on a metahuman',
        properties: 'Peaceful, Mediator, Martyr'
      },
      eagle: {
        environment: 'Mountains', spells: [[:Detection, 2]],
        spirits: [[:Sky, 2]], desc: 'Double Essence loss for Cyberware',
        properties: 'Noble, Proud, Solitary, Naturalist'
      },
      elk: {
        environment: 'Plains, Forest, Tundra',
        spells: [[:Health, 1], [:Combat, -2]], spirits: [[:Land, 2]],
        desc: '1 Die for Spell Defense',
        properties: 'Gentle, Wise, Protector, Majestic'
      },
      fish: {
        environment: 'On or near water', spells: [[:Detection, 2], 
        [:Combat, -1]], spirits: [[:Choose, [[:Water, 1]]]], desc: 'Choose 1 
        spirit of water', properties: 'Clever, Quick, Insightful'
      },
      fox: {
        environment: 'Anywhere on land', spells: [[:Illusion, 2], 
        [:Combat, -1]], spirits: [[:Choose, [[:Land1, 2], [:Man1, 2]]]], desc: 
        'Willpower(6) Test to spare fallen enemy, Choose one Spirit of Land or 
        Man', properties: 'Sly, Clever, Thief, Trickster'
      },
      gator: {
        environment: 'Swamp,River,Urban',
        spells: [[:Combat, 2], [:Detection, 2], [:Illusion, -1]],
        spirits: [[:Choose, [[:Swamp, 2], [:Lake, 2], [:River, 2], [:City, 2]]]], 
        desc: 'Willpower(6) Test to break off fight or  conflict, as wilderness
        totem +2 to Swamp, Lake or River spirits, as urban totem +2 to city
        spirits',
        properties: 'Lazy, Bad Tempered, Glutton, Good Fighter'
      },
      gecko: {
        environment: 'Anywhere', spells: [[:Choose, [[:Illusion, 2],
        [:Manipulation, 2]]], [:Combat, -1]], desc: '+2 to Illusion or 
        Manipulation spells, +1 to resist Poison',
        properties: 'Fast, Adaptable, Trickster, Hardy'
      },
      goose: {
        environment: 'Anywhere near water', spells: [[:Combat, 1], 
        [:Detection, 2]], spirits: [[:Choose, [[:Land1, 1], [:Sky1, 1], 
        [:Water1, 1]]]], desc: '+1 for a single Land, Sky or Water spirit, +2 to 
        all Magical TNs away from home/city region, 28 days to reset',
        properties: 'Proud, Territorial, Loud When Bothered'
      },
      horse: {
        environment: 'Prairie', spells: [[:Health, 2]], spirits: [[:Prairie]],
        desc: '-1 die resisting Combat or Illusion spells, can learn Movement
  		  critter power as Metamagic',
        properties: 'Swift, Noble, Strong, Loves Her Freedom'
      },
      hyena: {
        environment: 'Savannah', spells: [[:Combat, 2], [:Health, -1]],
        desc: '+2 dice to banish any spirit, Willpower(6) to perform any action
  		  with no benefit to self',
        properties: 'Aggressive, Cunning, Easily Angered, Self Serving'
      },
      jackal: {
        environment: 'Savannah', spells: [[:Combat, -1], [:Detection, 2], 
        [:Illusion, 2]], spirits: [[:Prairie, 2]],
        properties: 'Selfish, Thief, Unconventional, Stealthy'
      },
      jaguar: {
        environment: 'Jungle', spells: [[:Detection, 2], [:Health, -1]],
        spirits: [[:Forest, 2]],
        properties: 'Jack of All Trades, Stealthy, Stalker'
      },
      leopard: {
        environment: 'Forest and Savannah', desc: '+2 dice for Combat and 
        Health spells and all nature spirits at night, -1 die for resisting 
        illusion spells', properties: 'Fast over Short Distances, Loner, Fierce 
        When Cornered, Easily Angered, Intensely Protective of Family'
      },
      lion: {
        environment: 'Prairie', spells: [[:Combat, 2], [:Health, -1]],
        spirits: [[:Prairie, 2]],
        properties: 'Powerful, Noble, Brave, Protective of Family, Proud'
      },
      lizard: {
        environment: 'Desert, Forest, Mountain', spells: [[:Health, 2]],
        spirits: [[:Choose, [[:Desert, 2], [:Forest, 2], [:Mountain, 2]]]], 
        desc: '+2 to all TNs in tight quarters. When trapped with no clear 
        view of the sky, shaman must make Willpower(6) Test or fly into panic 
        for 3 turns, -1/success, will do everything to escape.',
        properties: 'Lazy at Times, Can Move Quickly, Thoughtful in Stillness'
      },
      monkey: {
        environment: 'Forest', spells: [[:Manipulation, 2], [:Combat, -1]],
        spirits: [[:Man, 2]],
        properties: 'Clever, Playful, Good Climber, Enjoys Taunting People'
      },
      mouse: {
        environment: 'Urban,Fields', spells: [[:Detection, 2], [:Health, 2],
        [:Combat, -1]], spirits: [[:Hearth, 2], [:Field, 2]],
        properties: 'Clever, Resourceful, Curious, Likes to Collect Things'
      },
      otter: {
        environment: 'On or near water', spells: [[:Illusion, 2], 
        [:Combat, -1]], spirits: [[:Choose, [[:River, 2], [:Sea, 2]]]],
        properties: 'Playful, Clever, Energetic, Enjoys Playing Tricks'
      },
      owl: {
        environment: 'Anywhere',
        desc: '+2 dice for Sorcery and Conjuring at night,
        +2 to ALL magical TNs during daytime',
        properties: 'Wise, Nocturnal, Loner, Hunter'
      },
      parrot: {
        environment: 'Jungle', spells: [[:Illusion, 2]], spirits: [[:Jungle, 2]],
        desc: '+1 modifier to all magical TNs if Parrots magical actions
        arent witnessed by someone who could be impressed by it.',
        description: 'Wise Guy, Show Off, Egotistical'
      },
      polecat: {
        environment: 'Anywhere on land', spells: [[:Combat, 1], [:Health, -1]],
        spirits: [[:Land, 2]], desc: 'At night +,-2 Dice, Willpower(6) Test to
        break off single-minded attack on opponen in comabt. They go until the
        opponent is downed, ignoring other enemies',
        properties: 'Clever, Good Hunter, Sleek, Plays Rough'
      },
      prairiedog: {
        environment: 'Anywhere on land', spells: [[:Detection, 2], 
        [:Illusion, 1], [:Combat, -2]], spirits: [[:Land, 2]], 
        req: [[:Charisma, 4]], properties: 'Friendly, Playful, Loves Having 
        Large Group of Friends'
      },
      puma: {
        environment: 'Any Isolated Wilderness except Desert',
        spells: [[:Illusion, 2]], spirits: [[:Mountain, 2]],
        desc: '+2 to All Magical TNs when in direct sunlight or crowds',
        properties: 'Loner, Stalker, Nocturnal Hunter'
      },
      python: {
        environment: 'Jungle', spells: [[:Health, 2], [:Control, 2]],
        spirits: [[:Forest, 2]], desc: 'Willpower(6) Test to break off combat
        or other sustained activity',
        properties: 'Slow, Strong, Hardy'
      },
      raccoon: {
        environment: 'Anywhere but the Desert',
        spells: [[:Manipulation, 2], [:Combat, -1]], spirits: [[:City, 2]],
        properties: 'Cunning, Thief, Curious'
      },
      rat: {
        environment: 'Urban', spells: [[:Detection, 2], [:Illusion, 2],
        [:Combat, -1]], spirits: [[:City, 2]],
        properties: 'Thief, Selfish, Coward, Dirty'
      },
      raven: {
        environment: 'Anywhere under an open sky', spells: [[:Manipulation, 2]],
        spritis: [[:Sky, 2]], desc: '+1 To All Magical TNs when not under an
        open sky', properties: 'Loves Food, Trickster, Opportunistic'
      },
      scorpion: {
        environment: 'Desert', spells: [[:Combat, 2], [:Illusion, 2]],
        desc: 'May milk venom from any scorpion, scorpion venom never does
        more than light damage to them, +2 to All Magical TNs during day,
        irritable and depressed when away from desert for +1 to
        shamans magical TNs per day up to +6',
        description: 'Swift Killers, Poisonous and Deadly, Fearless'
      },
      shark: {
        environment: 'On or by the sea', spells: [[:Combat, 2], 
        [:Detection, 2]], spirits: [[:Sea, 2]], desc: 'When wounded or kill an 
        opponent can go Berserk, rage lasts 3 turns, every success on 
        Willpower(4) test substracts a turn from the rage, avoided with 3 
        success, will attack closest with most powerful weapons, can choose to 
        attack body of last victim instead of living person',
        properties: 'Merciless, Frenzied Attacker, Fierce'
      },
      snake: {
        environment: 'Anywhere on land', spells: [[:Detection, 2], [:Health, 2],
        [:Illusion, 2]], spirits: [[:Choose, [[:Land1, 2], [:Man1, 2]]]],
        desc: '-1 die for ALL spells cast during combat',
        properties: 'Wise, Pacifist, Loves Learning Secrets'
      },
      spider: {
        environment: 'Quiet Dark Places where others seldom look',
        spells: [[:Illusion, 2]], spirits: [[:Nature, 1]],
        desc: '+2 To ALL Magical TNs when in open or away from shelter, +1 to 
        ALL TNs if he doesnt have time to plan a situation',
        properties: 'Patient, Symbol of Change and Cycle of life'
      },
      stag: {
        environment: 'Forest', spells: [[:Health, 2], [:Illusion, 2],
        [:Manipulation, -1]], spirits: [[:Forest, 2]],
        properties: 'Swift, Noble, Wise, Proud'
      },
      turtle: {
        environment: 'On or near water', spells: [[:Combat, -2], 
        [:Illusion, 2]], spirits: [[:Water1, 2]],
        properties: 'Detached, doesnt protect others, lack of curiosity'
      },
      whale: {
        environment: 'On or near sea', spells: [[:Combat, 2], [:Illusion, -1]],
        spirits: [[:Sea, 2]],
        properties: 'Loyal, Slow to Anger, Must Keep Oaths, Protector of
      Friends, Fierce Fighter When Attacked'
      },
      wolf: {
        environment: 'Forest,Prairie,Mountains', spells: [[:Combat, 2],
        [:Detection, 2]], spirits: [[:Choose, [[:Forest, 2], [:Prairie, 2],
        [:Mountain, 2]]]], desc: 'May go berserk like bear shaman',
        properties: 'Hunter, Warrior, Loyal'
      }
    },
    nature: {
      moon: {
        environment: 'Wild place far from civilization,hidden corners of city',
        spells: [[:Illusion, 2], [:Transformation, 2], [:Detection, 1], 
        [:Combat, -1]], spirits: [[:Water, 1]], desc: 'Willpower(6) test to 
        engage in direct confrontation', properties: 'Secretive, Ever-Changing'
      },
      mountain: {
        environment: 'Mountain', spells: [[:Manipulation, 2], [:Illusion, -1]],
        spirits: [[:Mountan, 2]], desc: 'Willpower(6) Test to change course of
        action once set', properties: 'Inflexible, Strong, Stubborn'
      },
      oak: {
        environment: 'Forest', spells: [[:Health, 2]], spirits: [[:Forest, 2],
        [:Hearth, 2]], req: [[:Body, 4], [:Strength, 4]],
        properties: 'Patient, Noble, Protector'
      },
      sea: {
        environment: 'On or near the sea', spells: [[:Health, 2],
        [:Transformation, 2]], spirits: [[:Sea, 2], [:Hearth, 2]],
        desc: 'Cannot give anything away for free, Willpower(6) Test to back
        down from insults',
        properties: 'Possessive, Deep, Proud, Ever-Changing'
      },
      stream: {
        environment: 'Near shores of river/stream', spells: [[:Combat, -1],
        [:Health, 2]], spirits: [[:River, 2]],
        properties: 'Steady, Balanced, Peaceful, Harmonious'
      },
      sun: {
        environment: 'Anywhere under the open sky', desc: '+2 dice with
        Comabt, Detection and Health spells and +2 dive for any Spirit
        while in direct sunlight, +2 to ALL conjuring numbers at night',
        req: [[:Charisma, 4]], properties: 'Noble, Brave, Charismatic'
      },
      wind: {
        environment: 'Anyhwere under the open sky', spells: [[:Detection, 2]],
        spirits: [[:Sky, 2]], desc: '+2 to all Magcial TNs when not under
        open sky', properties: 'Chaotic, Unrestrained'
      }
    },
    idol: {
      adversary: {
        environment: 'Everywhere', spells: [[:Combat, 2], [:Manipulation, 2]],
        desc: 'If wounded, berserk like bear, willpower(8) test to be
        friendly and civil to authority figures',
        properties: 'Rebel, Cruel, Willful, Cynic'
      },
      bacchus: {
        environment: 'Anywhere on land', spells: [[:Illusion, 2]],
        spirits: [[:Man, 2]], desc: 'Willpower(6) test to continue course
        of action if something more interesting/prettier/relaxing presents
        itself, -1 perception in presence of beauty/art/etc',
        properties: 'Passionate, partying, easily distracted, not good
    with long term obligations'
      },
      creator: {
        environment: 'Urban,Forest', spells: [[:Combat, -1]],
        spirits: [[:City, 2], [:Hearth, 2]], desc: '+2 Enchanting,
        Willpower(4) test to avoid astrally perceiving something new,
        distracted for 3 turns, -1 per success',
        properties: 'Enjoys creating, trusting, not familiar with deceit'
      },
      darkking: {
        environment: 'Natural Caves', spells: [[:Health, 2]],
        spirits: [[:Man, 2]], desc: 'Must sacrifice 1 point from starting
        physical attribute', properties: 'Grim, Dark, Secretive,
        Physically Weak From Suffering, Symbol of Underworld'
      },
      dragonslayer: {
        environment: 'Anywhere on land', spells: [[:Combat, 3],
        [:Illusion, -1], [:Detection, -1]], spirits: [[:Hearth, 1]],
        properties: 'Heroic, Fun-loving, Honorable, Respectful'
      },
      firebringer: {
        environment: 'Urban', spells: [[:Detection, 2], [:Manipulation, 2],
        [:Illusion, -1]], spirits: [[:Man, 2]],
        properties: 'Kind, Humanitarian, Creator'
      },
      greatmother: {
        environment: 'Anywhere', spells: [[:Health, 2]], spirits: [[:Field, 2],
        [:Forest, 2], [:Water, 2]], desc: '-2 dice in presence of corruption',
        properties: 'Generous, Healer, Protective of Family, Moral Code'
      },
      hornedman: {
        environment: 'Anywhere on land', spells: [[:Combat, 2]],
        spirits: [[:Land, 2]], desc: 'Willpower(6) test to refuse fight or
        physical contest, willpower test vs twice seducer charisma to refuse
        advances', properties: 'Wild, Fertile, Instinctive, Masculine'
      },
      lover: {
        environment: 'Urban', spells: [[:Illusion, 2], [:Control, 2]],
        spirits: [[:Water, 2]], req: [[:Charisma, 6]],
        properties: 'Beautiful, Jealous, Irrational, Proud, Vain,
        Tpyically Female'
      },
      moonmaiden: {
        environment: 'Anywhere', properties: 'Moody, Emotional, Ever-Changing,
        Mysterious, Symbol of Night Sky, Mostly Female Followers'
      },
      seaking: {
        environment: 'Anwhere near the sea', spells: [[:Manipulation, 2],
        [:Combat, -1]], spirits: [[:Sea, 2]], properties: '
        Ever-Changing, Ruler of Sea, Generous, Great Temper when Angered'
      },
      seductress: {
        environment: 'Urban', spells: [[:Illusion, 2], [:Control, 2]],
        spirits: [[:Man, 2]], req: [[:Charisma, 6]], desc: 'Willpower(6) test
        to resist a vice or corruption when offered', properties: '
        Jealous, Greedy, Corrupt, Exploits Others'
      },
      siren: {
        environment: 'Sea', spells: [[:Illusion, 2], [:Control, 2]],
        spirits: [[:Sea, 2]], req: [[:Charisma, 6]], desc: '+1 spellcasting
        TN modifier when attacked by more than one foe', properties: '
        Manipulator, Enjoys Sacrificial Rites, Loves to Destroy Others'
      },
      skyfather: {
        environment: 'Anywhere under the open sky', spells: [[:Detection, 2],
        [:Manipulation, 2]], spirits: [[:Storm, 2]], desc: '+2 to ALL Tns if
        entrapped or bound in any way', properties: '
        Counterpart of Great Mother, Observant, Patriarchal'
      },
      trickster: {
        environment: 'Anywhere', properties: '
        Clever, Deceptive, Prankster, Theif, Master of Disguise'
      },
      wildhuntsman: {
        environment: 'Forest,Mountains,Plains', spells: [[:Detection, 2],
        [:Illusion, 2]], spirits: [[:Storm, 2]], desc: 'May go berserk in same 
        manner as Bear', properties: ' Artistic, Mystical, Unpredictable, Half 
        Crazy, Shaggy'
      },
      wisewarrior: {
        environment: 'Urban', spells: [[:Combat, 2], [:Detection, 2],
        [:Illusion, -1]], desc: '+2 for resisting all damaging spells',
        properties: 'Warrior, Strategic, Wise, Honorable'
      }
    },
    mythic: {
      fenrir: {
        environment: 'Forest', spells: [[:Combat, 3]], spirits: [[:Forest, 1]],
        desc: 'Willpower(8) test to back down or flee from confrontation, if 
        wounded goes berserk like bear', properties: '
        Fearless, Aggressive, Ruthless, Easily Angered'
      },
      gargoyle: {
        environment: 'Urban', spells: [[:Detection, 1], [:Illusion,1]],
        spirits: [[:City, 2], [:Water, -1]], desc: 'Must live in a skyscraper
        or castlelike structure up high', properties: '
        Patient, Observant, Fierce Fighter'
      },
      griffin: {
        environment: 'Mountains', spells: [[:Combat]], spirits: [[:Sky, 2]],
        desc: 'Willpower(6) test if insulted/offended, flies into rage if
        it fails attacking the target', properties: '
        Wise, Proud, Honorable'
      },
      leviathan: {
        environment: 'On or near the sea', spells: [[:Health, 1],
        [:Manipulation, 1], [:Illusion, -1]], spirits: [[:Sea, 2]], properties:
        'Graceful, Wise, Calm, Takes time to act'
      },
      pegasus: {
        environment: 'Rural area under open sky', spells: [[:Detection, 2],
        [:Health, 2]], spirits: [[:Sky, 2]], desc: 'Death frenzy if trapped
        indoors, MITS 159', properties: '
        Wild, Free, Sky, Fierce Fighter'
      },
      phoenix: {
        environment: 'Desert,Fields', spells: [[:Health, 1], [:Illusion, 1]],
        spirits: [[:Flame, 2]], desc: 'Can survive physical overflow damage
        of body x2, each time overflow occurs reduce total by 1, may not
        summon Spirits of Man, must know creative performance skill which
        may be used for geasa or centering', req: [[:Charisma, 4]],
        properties: 'Proud, Artistic, Symbol of beauty and rebirth'
      },
      plumedspirit: {
        environment: 'Anywhere in Atzlan', spells: [[:Detection, 2]],
        spirits: [[:Sky, 2]], desc: '+2 to all magical TN outside Atzlan',
        properties: 'Warrior, Proud, Considered, Honors Homeland'
      },
      thunderbird: {
        environment: 'Under the open sky', spells: [[:Combat, 2],
        [:Detection, 2]], spirits: [[:Storm, 1]], desc: '-1 die for magical
        tests when not under open sky, moody and subject to bouts of fury
        like Shark, berserking when wounded or kill an opponent',
        properties: 'Primal, Majestic, Symbol of storm'
      },
      unicorn: {
        environment: 'Forest', spells: [[:Health, 2], [:Illusion, 2]],
        spirits: [[:Land, 2]], desc: 'Receive Aura reading for free at
        1/2 starting intelligence, Double all essence losses from cyber',
        properties: 'Sky, Natualist, Strict moral code'
      },
      wyrm: {
        environment: 'Mountains', spells: [[:Health, 2], [:Manipulation, 2]],
        spirits: [[:Mountain, 2]], desc: 'Willpower(6) test to quit a task
        and do something else, sleeps average of 70 hours a week',
        properties: 'Slow, Lazy, Isolative, Strong body and will'
      }
    },
    loa: {
      agwe: {
        environment: 'Everywhere', spells: [[:Illusion, 2], [:Combat, -1]],
        properties: 'Strong, Gentle, Capable of Violence, Diplomatic, Proud'
      },
      azaca: {
        environment: 'Everywhere', spells: [[:Health, 2]], desc: '
    Willpower(6) test to avoid taking impuslive actions', properties: '
    Impulsive, Caretaker of rural land'
      },
      damballah: {
        environment: 'Everywhere', spells: [[:Detection, 2], 
        [:Manipulation, 2]], desc: 'Willpower(6) test to reveal good 
        information', properties: 'Graceful, Slow, Wise, Avoids Human Speech, 
        Strict Morals, Enjoys Riddles and Metaphors'
      },
      erzulie: {
        environment: 'Everywhere', spells: [[:Illusion, 2], [:Control, 2]],
        desc: 'Must have middle+ lifestyle, +1 TN to all magical tests if
        unkempt or less than stylish', properties: '
        Beatiful, Desirable, Enjoys fine clothing'
      },
      ghede: {
        environment: 'Everywhere', spells: [[:Health, 2], [:Manipulation, 2]],
        desc: 'Willpower(6) test to avoid playing a trick in inappropriate
        situation', properties: 'Trickster, Morbid Humor, Glutton'
      },
      legba: {
        environment: 'Everywhere', spells: [[:Detection, 2], [:Manipulation, 2],
        [:Combat, -1]], req: [[:Charisma, 4]], properties: '
        Wise, Respected, Leader'
      },
      obatala: {
        environment: 'Everywhere', spells: [[:Detection, 2], [:Health, 2],
        [:Control, 2]], desc: 'May not cast combat spells, +2 tn to all
        magical tests when not wearing at least one white clothing',
        properties: 'Peaceful, Harmonious, Mediator, Opposed to evil and
    Corruption, Protector of the weak'
      },
      ogoun: {
        environment: 'Everywhere', spells: [[:Combat, 2], [:Illusion, -1]],
        desc: 'Willpower(6) test to back down from insult to honor or
        prowess', properties: 'Proud, Warrior, Leader'
      },
      shango: {
        environment: 'Everywhere', spells: [[:Fire, 2], [:Lightning, 2]],
        desc: 'May go berserk as bear', properties: '
        Warrior, Tense Energy, Associated with guns'
      }
    }
  },
  spirits: {
    Nature: {
      Water: [:Sea, :River, :Lake, :Swamp],
      Sky: [:Fog, :Storm, :Mist, :Wind],
      Land: [:Prairie, :Desert, :Forest, :Mountain, :Jungle],
      Man: [:City, :Street, :Hearth, :Field]
    },
    Elemental: [:Fire, :Water, :Air, :Earth]
  },
  elements: {
    Fire: { spells: [[:Combat,2]], spirits: [[:Fire,2]], desc: 'Fire fiery'},
    Earth: { spells: [[:Manipulation,2]], spirits: [[:Earth,2]], desc: 'Earth stony'},
    Air: { spells: [[:Detection,2]], spirits: [[:Air,2]], desc: 'Air lofty'},
    Water: { spells: [[:Illusion,2]], spirits: [[:Water,2]], desc: 'Water gentle'}
  },
  senses: [
    :'Thermographic Vision',:'Low-Light Vision',:'Microscopic Vision',:'Magnification Vision',
    :'Flare-Compensation Vision',:'Improved Hearing',:'High-Frequency Hearing',:'Low-Frequency Hearing',
    :'Dampening Hearing',:'Improved Scent',:'Improved Taste']

}

#binding.pry

CONSTANTS[:totems].keys.each do |x|
  CONSTANTS[:totems][x].keys.each do |y|
    CONSTANTS[:totems][x][y][:desc] = CONSTANTS[:totems][x][y][:desc].delete("\n\t").squeeze(" ") if CONSTANTS[:totems][x][y][:desc]
    CONSTANTS[:totems][x][y][:properties] = CONSTANTS[:totems][x][y][:properties].delete("\n\t").squeeze(" ") if CONSTANTS[:totems][x][y][:properties]

  end
end
File.open('./constants.yaml', 'w+') << YAML.dump(CONSTANTS)

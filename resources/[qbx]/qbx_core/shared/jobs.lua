---Job names must be lower case (top level table key)
---@type table<string, Job>
return {
    ['unemployed'] = {
        label = 'Civilian',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Freelancer',
                payment = 10
            },
        },
    },
    ['police'] = {
        label = 'LSPD',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 800
            },
            [1] = {
                name = 'Officer',
                payment = 1075
            },
            [2] = {
                name = 'Officer 2',
                payment = 1100
            },
            [3] = {
                name = 'Officer 3',
                payment = 1200
            },
            [4] = {
                name = 'IA',
                isboss = true,
                bankAuth = true,
                payment = 4000
            },
            [5] = {
                name = 'Supervisor',
                payment = 1350
            },
            [6] = {
                name = 'Lieutenant',
                isboss = true,
                payment = 1500
            },
            [7] = {
                name = 'Captain',
                isboss = true,
                payment = 1700
            },
            [8] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 1875
            },
            [9] = {
                name = 'Management',
                isboss = true,
                bankAuth = true,
                payment = 7000
            },
        },
    },
    ['bcso'] = {
        label = 'BCSO',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 500
            },
            [1] = {
                name = 'Officer',
                payment = 875
            },
            [2] = {
                name = 'Sergeant',
                payment = 1200
            },
            [3] = {
                name = 'Lieutenant',
                payment = 1500
            },
            [4] = {
                name = 'Captain',
                payment = 1700
            },
            [5] = {
                name = 'Sheriff',
                isboss = true,
                bankAuth = true,
                payment = 1900
            },
        },
    },
    ['marshals'] = {
        label = 'U.S Marshals',
        type = 'leo',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'New Agent Trainee',
                payment = 1900
            },
            [1] = {
                name = 'Special Agent',
                payment = 2500
            },
            [2] = {
                name = 'Special Agents in Charge',
                payment = 3000
            },
            [3] = {
                name = 'Deputy Director',
                isboss = true,
                bankAuth = true,
                payment = 3500
            },
            [4] = {
                name = 'Director',
                isboss = true,
                bankAuth = true,
                payment = 4000
            },
        },
    },
    ['ambulance'] = {
        label = 'EMS',
        type = 'ems',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Cadet',
                payment = 1000
            },
            [1] = {
                name = 'EMS',
                payment = 1200
            },
            [2] = {
                name = 'A-EMT',
                payment = 1400
            },
            [3] = {
                name = 'Paramedic',
                payment = 1575
            },
            [3] = {
                name = 'Senior Paramedic',
                payment = 1750
            },
            [4] = {
                name = 'Lieutenant',
                payment = 1975
            },
            [5] = {
                name = 'Captain',
                payment = 2150
            },
            [6] = {
                name = 'Supervisor',
                isboss = true,
                payment = 2250
            },
            [7] = {
                name = 'Commander',
                isboss = true,
                payment = 2550
            },
            [8] = {
                name = 'Deputy Chief',
                isboss = true,
                payment = 2950
            },
            [9] = {
                name = 'Chief',
                isboss = true,
                bankAuth = true,
                payment = 3500
            },
        },
    },
    ['realestate'] = {
        label = 'Real Estate',
        type = 'realestate',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 450
            },
            [1] = {
                name = 'House Sales',
                payment = 575
            },
            [2] = {
                name = 'Business Sales',
                payment = 800
            },
            [3] = {
                name = 'Broker',
                payment = 1025
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 1800
            },
        },
    },
    ['taxi'] = {
        label = 'Taxi',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Driver',
                payment = 75
            },
            [2] = {
                name = 'Event Driver',
                payment = 100
            },
            [3] = {
                name = 'Sales',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['bus'] = {
        label = 'Bus',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['cardealer'] = {
        label = 'Vehicle Dealer',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Showroom Sales',
                payment = 75
            },
            [2] = {
                name = 'Business Sales',
                payment = 100
            },
            [3] = {
                name = 'Finance',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['mechanic'] = {
        label = 'Mechanic',
        type = 'mechanic',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Novice',
                payment = 75
            },
            [2] = {
                name = 'Experienced',
                payment = 100
            },
            [3] = {
                name = 'Advanced',
                payment = 125
            },
            [4] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['redline'] = {
        label = 'Redline',
        type = 'redline',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Trainee',
                payment = 50
            },
            [1] = {
                name = 'Mechanic',
                payment = 75
            },
            [2] = {
                name = 'Supervisor',
                payment = 100
            },
            [3] = {
                name = 'Manager',
                payment = 125
            },
            [4] = {
                name = 'Owner',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },
    ['judge'] = {
        label = 'Honorary',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Judge',
                payment = 100
            },
        },
    },
    ['lawyer'] = {
        label = 'Law Firm',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Associate',
                payment = 50
            },
        },
    },
    ['reporter'] = {
        label = 'Reporter',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Journalist',
                payment = 50
            },
        },
    },
    ['trucker'] = {
        label = 'Trucker',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['tow'] = {
        label = 'Towing',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Driver',
                payment = 50
            },
        },
    },
    ['garbage'] = {
        label = 'Garbage',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Collector',
                payment = 50
            },
        },
    },
    ['vineyard'] = {
        label = 'Vineyard',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Picker',
                payment = 50
            },
        },
    },
    ['hotdog'] = {
        label = 'Hotdog',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Sales',
                payment = 50
            },
        },
    },
    ['koi'] = {
        label = 'Koi',
        type = 'business',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Waiter',
                payment = 450
            },
            [1] = {
                name = 'Host',
                payment = 650
            },
            [2] = {
                name = 'Cook',
                payment = 800
            },
            [3] = {
                name = 'ShiftLeader',
                payment = 1000
            },
            [4] = {
                name = 'HeadCheif',
                payment = 1200
            },
            [5] = {
                name = 'Manager',
                isboss = true,
                payment = 1400
            },
            [6] = {
                name = 'GeneralManager',
                isboss = true,
                payment = 1700
            },
            [7] = {
                name = 'Owner',
                isboss = true,
                payment = 1800
            },
        },
    },

    ['upnatom'] = {
		label = "Up n Atom",
        type = 'business',
		defaultDuty = true,
        offDutyPay = false,
		grades = {
            [0] = { 
                name = 'Recruit',
                 payment = 200 
                },
			[1] = { 
                name = 'Novice',
                 payment = 400
                 },
			[2] = { 
                name = 'Experienced',
                 payment = 600 
                },
			[3] = { 
                name = 'Advanced', 
                payment = 1000 
            },
			[4] = { 
                name = 'Manager', 
                isboss = true, 
                payment = 1200 },
            [5] = { 
                name = 'Owner', 
                isboss = true, 
                payment = 1800 
            },
        },
	},
	['hornys'] = {
		label = "Horny's",
        type = 'business',
		defaultDuty = true,
        offDutyPay = false,
		grades = {
            [0] = { 
                name = 'Novice', 
                payment = 200
             },
			[1] = { 
                name = 'Experienced',
                 payment = 400
                 },
			[2] = { 
                name = 'Advanced', 
                payment = 500 
            },
			[3] = { 
                name = 'Manager', 
                payment = 750 
            },
			[4] = { 
                name = 'Head Manager',
                 isboss = true, 
                 payment = 1000 
                },
            [5] = { 
                name = 'Owner',
                 isboss = true, 
                 payment = 1800 
                },
        },
	},
    ['beanmachine'] = {
		label = 'Bean Machine',
        type = 'business',
		defaultDuty = true,
        offDutyPay = false,
		grades = {
            [0] = { 
                name = 'Recruit', 
                payment = 200 
            },
			[1] = { 
                name = 'Novice', 
                payment = 400 
            },
			[2] = { 
                name = 'Experienced', 
                payment = 600 
            },
			[3] = { 
                name = 'Advanced', 
                payment = 1000 
            },
			[4] = { 
                name = 'Manager', 
                isboss = true, 
                payment = 1250 
            },
            [5] = { 
                name = 'Owner', 
                isboss = true, 
                payment = 1800 
            },
        },
	},
    ['burgershot'] = {
		label = 'BurgerShot',
        type = 'business',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = { 
                name = 'Recruit', 
                payment = 200 
            },
			[1] = { 
                name = 'Novice',
                 payment = 400 
                },
			[2] = { 
                name = 'Experienced', 
                payment = 600 
            },
			[3] = { 
                name = 'Advanced', 
                payment = 1000 
            },
			[4] = { 
                name = 'Manager', 
                isboss = true, 
                payment = 1250
             },
             [5] = { 
                name = 'Owner', 
                isboss = true, 
                payment = 1800
             },
        },
	},
    
    ['catcafe'] = {
		label = 'Cat Cafe',
        type = 'business',
		defaultDuty = true,
        offDutyPay = false,
		grades = {
            [0] = { 
                name = 'Recruit', 
                payment = 200 
            },
			[1] = { 
                name = 'Novice', 
                payment = 400 
            },
			[2] = { 
                name = 'Experienced',
                 payment = 600 
                },
			[3] = { 
                name = 'Advanced', 
                payment = 1000 
            },
			[4] = { 
                name = 'Manager', 
                isboss = true, 
                payment = 1250 
            },
            [5] = { 
                name = 'Owner', 
                isboss = true, 
                payment = 1800
             },
        },
	},
    ['pizzathis'] = {
		label = 'Pizza This',
        type = 'business',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = { 
                name = 'Trainee', 
                payment = 200 
            },
			[1] = {
                 name = 'Worker', 
                 payment = 400 
                },
			[2] = { 
                name = 'Supervisor', 
                payment = 600 
            },
			[3] = { 
                name = 'Manager', 
                isboss = true, 
                payment = 1000 
            },
			[4] = { 
                name = 'Owner',
                 isboss = true, 
                 payment = 1800 
                },
        },
	},
    ['lscustoms'] = {
		label = 'LS Customs',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 300
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['redline'] = {
		label = 'Redline Mechanic',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Trainee',
                payment = 350
            },
			[1] = {
                name = 'Mechanic',
                payment = 750
            },
			[2] = {
                name = 'Dealers',
                payment = 250
            },
            [3] = {
                name = 'Supervisors',
                payment = 1000
            },
			[4] = {
                name = 'Manager',
                isboss = true,
                payment = 1200
            },
			[5] = {
                name = 'Owner',
		        isboss = true,
      		    payment = 1800
            },
        },
	},    
    ['ottos'] = {
		label = 'Ottos Autos',
        type = 'mechanic',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [1] = {
                name = 'Trainee',
                payment = 350
            },
			[2] = {
                name = 'Mechanic',
                payment = 750
            },
            [3] = {
                name = 'Supervisors',
                payment = 1000
            },
			[4] = {
                name = 'Manager',
                isboss = true,
                payment = 1200
            },
			[5] = {
                name = 'Owner',
		        isboss = true,
      		    payment = 3000
            },
        },
	},
     ['standcustoms'] = {
		label = 'Stand Customs',
        type = 'mechanic',
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [1] = {
                name = 'Trainee',
                payment = 350
            },
			[2] = {
                name = 'Mechanic',
                payment = 750
            },
            [3] = {
                name = 'Supervisors',
                payment = 1000
            },
			[4] = {
                name = 'Manager',
                isboss = true,
                payment = 1200
            },
			[5] = {
                name = 'Owner',
		        isboss = true,
      		    payment = 3000
            },
        },
	},
    ['eastcustoms'] = {
		label = 'East Customs',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['beekers'] = {
		label = 'Beekers',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['bennys'] = {
		label = 'Bennys',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['tunershop'] = {
		label = 'Tunershop',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['importshop'] = {
		label = 'Importshop',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['hayes'] = {
		label = 'Hayes',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 600
            },
            [3] = {
                name = 'Advanced',
                payment = 750
            },
			[4] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[5] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['reaper'] = {
		label = 'Reaper Mechanic',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},
    ['harmony'] = {
		label = 'Harmony',
        type = "mechanic",
		defaultDuty = true,
		offDutyPay = false,
		grades = {
            [0] = {
                name = 'Recruit',
                payment = 350
            },
			[1] = {
                name = 'Novice',
                payment = 500
            },
			[2] = {
                name = 'Experienced',
                payment = 750
            },
			[3] = {
                name = 'Manager',
                isboss = true,
                payment = 1000
            },
			[4] = {
                name = 'Owner',
				isboss = true,
                payment = 1800
            },
        },
	},



['exotic'] = {
    label = 'Exotics',
    type = "mechanic",
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = {
            name = 'Recruit',
            payment = 350
        },
        [1] = {
            name = 'Novice',
            payment = 500
        },
        [2] = {
            name = 'Experienced',
            payment = 750
        },
        [3] = {
            name = 'Manager',
            isboss = true,
            payment = 1000
        },
        [4] = {
            name = 'Owner',
            isboss = true,
            payment = 1800
        },
    },
},



['dreamworks'] = {
    label = 'Dreamwork Customs',
    type = "mechanic",
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = {
            name = 'Recruit',
            payment = 350
        },
        [1] = {
            name = 'Novice',
            payment = 500
        },
        [2] = {
            name = 'Experienced',
            payment = 750
        },
        [3] = {
            name = 'Manager',
            isboss = true,
            payment = 1000
        },
        [4] = {
            name = 'Owner',
            isboss = true,
            payment = 1800
        },
    },
},

['mirrorparkmech'] = {
    label = 'Mirrior Park Customs',
    type = "mechanic",
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = {
            name = 'Recruit',
            payment = 350
        },
        [1] = {
            name = 'Novice',
            payment = 500
        },
        [2] = {
            name = 'Experienced',
            payment = 750
        },
        [3] = {
            name = 'Manager',
            isboss = true,
            payment = 1000
        },
        [4] = {
            name = 'Owner',
            isboss = true,
            payment = 1800
        },
    },
},



['thommy'] = {
    label = 'Thommy',
    type = "mechanic",
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = {
            name = 'Owner',
            isboss = true,
            payment = 1000
        },
    },
},



['youtuber'] = {
    label = 'Rockstar',
    type = "mechanic",
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = {
            name = 'Owner',
            isboss = true,
            payment = 0
        },
    },
},
['customped'] = {
        label = 'Custom Ped',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Customer',
                payment = 0
            },
        },
    },
    ['pdm'] = {
        label = 'Premium Deluxe Motorsport',
        defaultDuty = true,
        offDutyPay = false,
        grades = {
            [0] = {
                name = 'Recruit',
                payment = 50
            },
            [1] = {
                name = 'Worker',
                payment = 75
            },
            [2] = {
                name = 'Manager',
                isboss = true,
                bankAuth = true,
                payment = 100
            },
            [3] = {
                name = 'Boss',
                isboss = true,
                bankAuth = true,
                payment = 150
            },
        },
    },

}
return {
    addressDatabase = {
        grove = {name = "MYSTIC GROVE", inputName = "grove", code = {9,23,4,5,7,8,20,27,0}, displayCode = "9,23,4,5,7,8,20,27", page = 1},
        lootDim = {name = "LOOT DIMENSION", inputName = "lootDim", code = {8,1,22,19,12,28,2,3,0}, displayCode = "8,1,22,19,12,28,2,3", page = 1},
        abydos = {name = "ABYDOS", inputName = "abydos", code = {26,6,14,31,11,29,0}, displayCode = "26,6,14,31,11,29", page = 1},
        chulak = {name = "CHULAK", inputName = "chulak", code = {8,1,22,14,36,19,0}, displayCode = "8,1,22,14,36,19", page = 1},
        cavum = {name = "CAVUM", inputName = "chulak", code = {18,7,3,36,25,15,0}, displayCode = "18,7,3,36,25,15", page = 1},
        nether = {name = "NETHER", inputName = "nether", code = {27,23,4,34,12,28,0}, displayCode = "27,23,4,34,12,28", page = 1},
        theEnd = {name = "END", inputName = "end", code = {13,24,2,19,3,30,0}, displayCode = "13,24,2,19,3,30", page = 1},
        glacio = {name = "GLACIO", inputName = "glacio", code = {26,20,4,36,9,27,0}, displayCode = "26,20,4,36,9,27", page = 1},
        spires = {name = "SPIRES", inputName = "spires", code = {4,11,16,2,18,34,23,6,0}, displayCode = "4,11,16,2,18,34,23,6", page = 1},
        doge = {name = "DOGE'S BASE", inputName = "doge", code = {16,1,11,23,20,7,6,25,0}, displayCode = "16,1,11,23,20,7,6,25", page = 1},
        temple = {name = "TEMPLE OF TIME", inputName = "temple", code = {8,13,35,2,3,5,6,7,0}, displayCode = "8,13,35,2,3,5,6,7", page = 1},
        factory = {name = "KRAN'S FACTORY", inputName = "factory", code = {17,12,29,21,27,20,23,14,0}, displayCode = "17,12,29,21,27,20,23,14", page = 1},
        sgc = {name = "SGC", inputName = "sgc", code = {8,13,1,24,12,28,10,22,0}, displayCode = "8,13,1,24,12,28,10,22", page = 1},
        otherside = {name = "OTHERSIDE", inputName = "otherside", code = {32,8,4,31,22,7,0}, displayCode = "32,8,4,31,22,7", page = 1},
        moon = {name = "MOON", inputName = "moon", code = {12,33,26,6,18,3,14,19,0}, displayCode = "12,33,26,6,18,3,14,19" , page = 1},
        mars = {name = "MARS", inputName = "mars", code = {13,30,23,6,12,20,4,5,0}, displayCode = "13,30,23,6,12,20,4,5", page = 1},
        venus = {name = "VENUS", inputName = "venus", code = {19,32,1,33,2,12,31,17,0}, displayCode = "19,32,1,33,2,12,31,17", page = 2},
        offSite = {name = "APEX OFFSITE STATION", inputName = "offSite", code = {30,18,22,28,23,27,2,34,0}, displayCode = "30,18,22,28,23,27,2,34", page = 2},
        gem = {name = "GEM'S BASE", inputName = "gem", code = {34,4,27,14,31,33,13,35,0}, displayCode = "34,4,27,14,31,33,13,35", page = 2},
        mainSite = {name = "APEX MAIN STATION", inputName = "mainSite", code = {14,32,34,35,24,23,28,11,0}, displayCode = "14,32,34,35,24,23,28,11", page = 2 },
        rj = {name = "RJ'S BASE", inputName = "rj", code = {33,9,2,27,31,21,24,25,0}, displayCode = "33,9,2,27,31,21,24,25", page = 2},
        doum = {name = "DOUM'S BASE", inputName = "doum", code = {8,1,6,26,21,12,30,25,0}, displayCode = "8,1,6,26,21,12,30,25", page = 2},
        jaja = {name = "JAJA'S BASE", inputName = "jaja", code = {11,31,4,32,34,26,5,9,0}, displayCode = "11,31,4,32,34,26,5,9", page = 2},
        kuro = {name = "KURO'S BASE", inputName = "kuro", code = {31,34,22,24,17,20,19,23,0}, displayCode = "31,34,22,24,17,20,19,23", page = 2},
        rfGate = {name = "RF GATE", inputName = "rfGate", code = {5,33,6,35,1,24,10,16,0}, displayCode = "5,33,6,35,1,24,10,16", page = 2},
        aspect = {name = "ASPECT'S BASE", inputName = "aspect", code = {4,20,5,3,27,15,8,18,0}, displayCode = "4,20,5,3,27,15,8,18", page = 2},
        outpost = {name = "ABYDOS OUTPOST", inputName = "outpost", code = {3,12,29,10,14,19,33,32,0}, displayCode = "3,12,29,10,14,19,33,32", page = 2},
        destiny = {name = "DESTINY", inputName = "destiny", code = {28,25,14,35,16,31,19,10,0}, displayCode = "28,25,14,35,16,31,19,10", page = 2}
    }
}
--[[
To add a new address:
copy this table into "addressDatabase":

gate = {name = "GATE", inputName = "gate", code = {1,2,3,4,5,6,7,8,0}, displayCode = "1,2,3,4,5,6,7,8", page = 2}

what is what for editing:
"name" is the name that will be displayed on the monitor when dialing
"inputName" is what you type after "dial" to dial the address
"code" is the stargate address
"displayCode" is that address without the "0" tat will display when you input the view command
dont worry about the "page" variable.
]]
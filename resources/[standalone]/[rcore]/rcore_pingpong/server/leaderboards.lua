if not Config.UseLeaderboard then
    return
end
Leaderboards = {}
Leaderboards.Loaded = false
Leaderboards.Tops = {}
Leaderboards.Changed = false

function Leaderboards:Load()
    local content = LoadResourceFile(GetCurrentResourceName(), "server/leaderboards.json")
    if content then
        Leaderboards.Data = json.decode(content)
    else
        Leaderboards.Data = {}
    end
    if not Leaderboards.Data then
        Leaderboards.Data = {}
    end
    Leaderboards.Loaded = true
end

function Leaderboards:Save()
    if not Leaderboards.Loaded then
        return
    end
    SaveResourceFile(GetCurrentResourceName(), "server/leaderboards.json", json.encode(Leaderboards.Data, {
        indent = true
    }), -1)
end

local function UpdateScorePoints(p, oP, isWin)
    Leaderboards.Changed = true
    if not p.scorePoints then
        p.scorePoints = 1200
    end
    if not oP.scorePoints then
        oP.scorePoints = 1200
    end

    local k = 32
    local expectedScore = 1 / (1 + 10 ^ ((oP.scorePoints - p.scorePoints) / 400))
    local result = isWin and 1 or 0

    p.scorePoints = p.scorePoints + k * (result - expectedScore)
    oP.scorePoints = oP.scorePoints + k * ((1 - result) - (1 - expectedScore))
end

local function EnsurePlayer(license)
    if not Leaderboards.Data[license] then
        Leaderboards.Data[license] = {
            wins = 0,
            losses = 0,
            scorePoints = 1200
        }
    end
end

function Leaderboards:RefreshTOP()
    if not Leaderboards.Loaded then
        return
    end

    local sortedEntries = {}
    for _, data in pairs(Leaderboards.Data) do
        table.insert(sortedEntries, {
            wins = data.wins,
            losses = data.losses,
            name = data.name,
            mug = data.mug
        })
    end
    table.sort(sortedEntries, function(a, b)
        return a.wins > b.wins
    end)

    local tops = {}
    for i = 1, math.min(100, #sortedEntries) do
        table.insert(tops, sortedEntries[i])
    end
    Leaderboards.Tops = tops
end

function Leaderboards:AddWin(winner, loser)
    EnsurePlayer(winner.license)
    EnsurePlayer(loser.license)
    local p = Leaderboards.Data[winner.license]
    local oP = Leaderboards.Data[loser.license]
    p.name = winner.name
    p.mug = winner.mugShot
    oP.name = loser.name
    oP.mug = loser.mugShot
    p.wins = p.wins + 1
    UpdateScorePoints(p, oP, true)
    Leaderboards:RefreshTOP()
end

function Leaderboards:AddLoss(loser, winner)
    EnsurePlayer(loser.license)
    EnsurePlayer(winner.license)
    local p = Leaderboards.Data[loser.license]
    local oP = Leaderboards.Data[winner.license]
    p.name = loser.name
    oP.name = winner.name
    p.mug = loser.mugShot
    oP.mug = winner.mugShot
    p.losses = p.losses + 1
    UpdateScorePoints(p, oP, false)
end

function Leaderboards:GetRank(license)
    if not Leaderboards.Data[license] then
        return 0
    end
    return Leaderboards.Data[license].scorePoints
end

function Leaderboards:GetRankNumber(license)
    if not Leaderboards.Data[license] or not Leaderboards.Data[license].scorePoints then
        return 0
    end
    local scalingFactor = 0.01
    return math.floor(Leaderboards.Data[license].scorePoints * scalingFactor)
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        Leaderboards:Save()
    end
end)

CreateThread(function()
    Leaderboards:Load()
    Leaderboards:RefreshTOP()
    while true do
        if Leaderboards.Changed then
            Leaderboards:RefreshTOP()
            Leaderboards:Save()
            Leaderboards.Changed = false
        end
        Wait(60000 * 30)
    end
end, "LeaderboardsRefresh")

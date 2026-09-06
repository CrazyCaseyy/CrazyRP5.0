local nearbyLobbyMenuName = nil
local canPurchaseMembership = false

---@type GameData?
LobbyData = nil
---@type table<string, boolean>
IsInsideGrounds = {}

---@param lobbyCoords vector3
local function DrawLobbyMarker(lobbyCoords)
    DrawMarker(
        27,
        lobbyCoords.x, lobbyCoords.y, lobbyCoords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 1.0,
        255, 0, 0, 255,
        false, false, 2, true, nil, nil, false
    )
end

---@param membershipPurchaseCoords vector3
local function DrawMembershipMarker(membershipPurchaseCoords)
    DrawMarker(
        27,
        membershipPurchaseCoords.x, membershipPurchaseCoords.y, membershipPurchaseCoords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        1.0, 1.0, 1.0,
        255, 0, 0, 255,
        false, false, 2, true, nil, nil, false
    )
end

---@param lobbyCoords vector3
---@param locationName string
local function UpdateLobbyStart(lobbyCoords, locationName)
    local dist = #(LocalPedCoords - lobbyCoords)
    if dist <= 30.0 then
        DrawLobbyMarker(lobbyCoords)
        if dist <= 1.2 and not isNuiOpen() and not IsPauseMenuActive() then
            if not CaddyCreated then
                ShowHelpTextThisFrame("RGOLF_LOBBY", false)
            end
            nearbyLobbyMenuName = locationName
        else
            nearbyLobbyMenuName = nil
        end
    else
        nearbyLobbyMenuName = nil
        Wait(1000)
    end
end

---@param membershipPurchaseCoords vector3
local function UpdateMembership(membershipPurchaseCoords)

    local dist = #(LocalPedCoords - membershipPurchaseCoords)
    if dist <= 30.0 then
        DrawMembershipMarker(membershipPurchaseCoords)
        if dist <= 1.2 and not isNuiOpen() and not IsPauseMenuActive() then
            ShowHelpTextThisFrame("RGOLF_PURCHASE_MEMBERSHIP", false)
            if not canPurchaseMembership then
                canPurchaseMembership = true
            end
        else
            if canPurchaseMembership then
                canPurchaseMembership = false
            end
        end
    else
        if canPurchaseMembership then
            canPurchaseMembership = false
        end
    end
end

---@param locationConfig LocationConfig
local function IsLocationAvailable(locationConfig)
    if locationConfig.requiredResource and GetResourceState(locationConfig.requiredResource) ~= "started" then
        return false
    end
    return true
end

Citizen.CreateThread(function()
    AddTextEntry("RGOLF_LOBBY", string.format(Texts.openLobby, string.format("~INPUT_%08X~", GetHashKey(Texts.openLobbyCommand))))

    AddTextEntry("RGOLF_SHOW_SCORECARD", Texts.openScorecard)
    AddTextEntry("RGOLF_RETURN_BOUNDS", Texts.returnToBounds)
    AddTextEntry("RGOLF_START_SHOT", Texts.startShot)
    AddTextEntry("RGOLF_CADDY_SPAWNED", Texts.caddySpawned)

    if Config.MembershipEnabled then
        AddTextEntry("RGOLF_PURCHASE_MEMBERSHIP", string.format(Texts.purchaseMembership, string.format("~INPUT_%08X~", GetHashKey(Texts.openLobbyCommand)), Texts.currency..tostring(Config.MembershipPrice)))
    end

    for _, locationConfig in pairs(LocationsConfig) do
        if locationConfig.AddMapBlip then
            local blip = AddBlipForCoord(locationConfig.LobbyCoords.x, locationConfig.LobbyCoords.y, locationConfig.LobbyCoords.z)
            SetBlipSprite(blip, Config.BlipOptions.blipId)
            if Config.BlipOptions.colour then
                SetBlipColour(blip, Config.BlipOptions.colour)
            end
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Texts.golfBlip or "Golf")
            EndTextCommandSetBlipName(blip)
            SetBlipAsShortRange(blip, true)
            locationConfig.blip = blip
        end
    end

    while true do
        LocalPed = PlayerPedId()
        LocalPedCoords = GetEntityCoords(LocalPed)

        local inAnyLocation = false
        for locationName, locationConfig in pairs(LocationsConfig) do
            if IsLocationAvailable(locationConfig) then
                local inGrounds = false

                for _, boundInfo in pairs(locationConfig.MainBounds) do
                    if #(LocalPedCoords - boundInfo[1]) < boundInfo[2] then
                        inGrounds = true
                        break
                    end
                end

                if inGrounds and not IsInsideGrounds[locationName] then
                    TriggerServerEvent("rcore_golf:setSubscribedToCourse", locationName, true)
                elseif IsInsideGrounds[locationName] and not inGrounds then
                    TriggerServerEvent("rcore_golf:setSubscribedToCourse", locationName, false)
                end

                IsInsideGrounds[locationName] = inGrounds

                if inGrounds then
                    UpdateLobbyStart(locationConfig.LobbyCoords, locationConfig.name)
                    if Config.MembershipEnabled then
                        UpdateMembership(locationConfig.MembershipPurchaseCoords)
                    end
                    inAnyLocation = true
                end

                SetBlipDisplay(locationConfig.blip, 2)
            else
                SetBlipDisplay(locationConfig.blip, 0)
            end
        end

        Wait(inAnyLocation and 0 or 1000)
    end
end)

RegisterKeyMapping(Texts.openLobbyCommand, Texts.openLobbyCommandDescription, "KEYBOARD", Config.Keys.openLobbyKey)
RegisterCommand(Texts.openLobbyCommand, function()
    if not nearbyLobbyMenuName then return end
    toggleNuiFrame(true, nearbyLobbyMenuName)
end, false)



if Config.MembershipEnabled then
    local membershipCooldown = false
    RegisterKeyMapping(Texts.purchaseMembershipCommand, Texts.purchaseMembershipCommandDescription, "KEYBOARD", Config.Keys.openLobbyKey)
    RegisterCommand(Texts.purchaseMembershipCommand, function()
        if membershipCooldown or not canPurchaseMembership then return end
        membershipCooldown = true
        Citizen.SetTimeout(3000, function() membershipCooldown = false end)
        TriggerServerEvent("rcore_golf:purchaseMembership")
    end, false)
end

RegisterNetEvent("rcore_golf:sendLobbyData", function(lobbyData)
    LobbyData = lobbyData
    SetLobbyDataForNUI(LobbyData)
    InitMainThread()

    if lobbyData == nil and Config.DeleteCaddyAfterLeavingGame then
        local delay = Config.DeleteCaddyAfterLeavingDelay or 0
        Citizen.CreateThread(function()
            Wait(delay)
            DeleteEntity(vehicleCaddy)
            TriggerServerEvent("rcore_golf:deleteCaddy", vehicleCaddyNetId)
        end)
    end
end)

RegisterNetEvent("rcore_golf:displayNotification", function(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end)
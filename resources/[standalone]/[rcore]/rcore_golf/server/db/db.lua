Citizen.CreateThread(function()
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `golf_memberships` (
            `user` varchar(255) NOT NULL,
            `membershipEndTime` varchar(32) NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
    ]])
end)

function AddPlayerToMembership(playerIdentifier)
    MySQL.Sync.execute([[
        INSERT INTO golf_memberships
        (`user`, `membershipEndTime`)
        VALUES (@user, @membershipEndTime)
    ]], {
        ['@user'] = playerIdentifier,
        ['@membershipEndTime'] = os.time(os.date("!*t")) + Config.MembershipLength,
    })
end

function DeleteMembership(playerIdentifier, endTime)
    MySQL.Sync.execute([[
        DELETE FROM golf_memberships
        WHERE user=@user AND membershipEndTime=@membershipEndTime
    ]], {
        ['@user'] = playerIdentifier,
        ['@membershipEndTime'] = endTime,
    })
end

function IsMembershipFinished(userMemberships)
    currentTime = os.time(os.date("!*t"))
    for index, membershipData in pairs(userMemberships) do
        local endTime = tonumber(membershipData.membershipEndTime)
        if currentTime > endTime then
            DeleteMembership(membershipData.user, membershipData.membershipEndTime)
            userMemberships[index] = nil
        end
    end
    return #userMemberships > 0
end

function DoesPlayerHaveMembership(playerIdentifier)
    local userMemberships = MySQL.Sync.fetchAll([[
        SELECT user, membershipEndTime
        FROM golf_memberships WHERE user=@user
    ]], {
        ['@user'] = playerIdentifier,
    })
    
    if #userMemberships == 0 then return false end
    local hasRemainingMembership = IsMembershipFinished(userMemberships)
    return hasRemainingMembership
end
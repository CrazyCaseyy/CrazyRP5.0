-- Initialize translations
Translation = {}
function Translation.Get(str)
    if not Translation[Config.Locale] then
        print(string.format("[%s] The language does not exists: %s", GetCurrentResourceName(), Config.Locale))
        return DefaultLocales[str]
    end
    if not Translation[Config.Locale][str] then
        print(string.format("[%s] The translation does not exists: %s", GetCurrentResourceName(), str))
        return DefaultLocales[str]
    end
    if Config.ForceNormalKeyLabels and ReplaceKeyString then
        return ReplaceKeyString(Translation[Config.Locale][str])
    end
    return Translation[Config.Locale][str]
end

-- Get core object for ESX / QBCore
function GetCoreObject(framework, resourceName, callBack)
    -- ES_EXTENDED
    if framework == 1 then
        xpcall(function()
            callBack(exports[resourceName or 'es_extended']['getSharedObject']())
        end, function(error)
            CreateThread(function()
                local tries = 10
                local ESX
                while not ESX do
                    Wait(100)
                    TriggerEvent("esx:getSharedObject", function(obj)
                        ESX = obj
                    end)
                    tries = tries - 1
                    if tries == 0 then
                        print("You forgot to change ESX shared object in config, please do it now or the script wont work properly.")
                        return
                    end
                end
                callBack(ESX)
            end)
        end)
    end

    -- QBCORE / custom
    if framework == 2 then
        xpcall(function()
            callBack(exports[resourceName or 'qb-core']['GetCoreObject']())
        end, function(error)
            xpcall(function()
                callBack(exports[resourceName or 'qb-core']['GetSharedObject']())
            end, function(error)
                CreateThread(function()
                    local tries = 10
                    local QBC
                    while not QBC do
                        Wait(100)
                        TriggerEvent("QBCore:GetObject", function(obj)
                            QBC = obj
                        end)
                        tries = tries - 1
                        if tries == 0 then
                            print("You forgot to change QBC shared object in config, please do it now or the script wont work properly.")
                            return
                        end
                    end
                    callBack(QBC)
                end)
            end)
        end)
    end
end
local CountdownScaleform = nil

Citizen.CreateThread(function()
    AddTextEntry('CNTDWN_C_GO', LANGUAGE.GO)
end)

local lastAudibleNum = nil

function DisplayCountdown(num)
    if not CountdownScaleform then
        CountdownScaleform = RequestScaleformMovie("COUNTDOWN");
    end

    if HasScaleformMovieLoaded(CountdownScaleform) then

        if lastAudibleNum ~= num then
            lastAudibleNum = num

            if num > 0 then
                PlaySoundFrontend(-1, "3_2_1", "321_GO_LOW_VOL_SOUNDSET", 1)
                if num == 1 then
                    Citizen.SetTimeout(500, function()
                        PlaySoundFrontend(-1, "GO", "321_GO_LOW_VOL_SOUNDSET", 1)
                    end)
                end
            end
        end

        BeginScaleformMovieMethod(CountdownScaleform, "SET_MESSAGE");

        if num == 0 then
            BeginTextCommandScaleformString("CNTDWN_C_GO");
            EndTextCommandScaleformString()
        else
            BeginTextCommandScaleformString("NUMBER");
            AddTextComponentInteger(num)
            EndTextCommandScaleformString()
        end

        local wantedColor = COUNTDOWN_COLOR

        if num == 0 then
            wantedColor = GO_COLOR
        end

        ScaleformMovieMethodAddParamInt(wantedColor.r);
        ScaleformMovieMethodAddParamInt(wantedColor.g);
        ScaleformMovieMethodAddParamInt(wantedColor.b);
        ScaleformMovieMethodAddParamBool(true);
        EndScaleformMovieMethod()

        DrawScaleformMovie(CountdownScaleform, 0.5, 0.5, 1.0, 1.0, 255, 255, 255, 100, 0)
    end
end

function CleanupScaleform()
    if CountdownScaleform then
        SetScaleformMovieAsNoLongerNeeded(CountdownScaleform)
        CountdownScaleform = nil
    end
end

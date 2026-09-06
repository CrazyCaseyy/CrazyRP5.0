function InstructionalButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function InstructionalButton(ControlButton)
    ScaleformMovieMethodAddParamPlayerNameString(ControlButton)
end

-- Citizen.CreateThread(function()
--     local instructScaleform = setupInstructionalScaleform("instructional_buttons")

--     while true do Wait(0)
--     DrawScaleformMovieFullscreen(instructScaleform, 255, 255, 255, 255, 0)
--     end
-- end)

function setupInstructionalScaleform(scaleform)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end

    PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(1)
    InstructionalButton(GetControlInstructionalButton(2, CONTROLS.MASH_A.CONTROL, true))
    InstructionalButton(GetControlInstructionalButton(2, CONTROLS.MASH_B.CONTROL, true))
    InstructionalButtonMessage(CONTROLS.MASH_A.TEXT)
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(0)
    InstructionalButton(GetControlInstructionalButton(2, CONTROLS.QUIT.CONTROL, true))
    InstructionalButtonMessage(CONTROLS.QUIT.TEXT)
    PopScaleformMovieFunctionVoid()
    


    PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleform
end
RegisterNUICallback('config', function(_data, cb)
    cb({
        mainColor = GetConvar('qbx_chat:mainColor', '#141517'),
        -- Grey 3D-bevel border, same tone used on every other redesigned
        -- resource's panels (ox_lib, crazy-hud, crazy-multichar, ox_target,
        -- ps-dispatch, ps-mdt).
        borderColor = GetConvar('qbx_chat:borderColor', 'rgba(140, 140, 150, 0.55)'),
        textColor = GetConvar('qbx_chat:textColor', '#ffffff'),
        faintColor = GetConvar('qbx_chat:faintColor', '#c1c2c5'),

        -- Same display font used everywhere else on the server. Console/
        -- suggestion text stays monospace on purpose - that's what keeps
        -- command argument columns lined up, not a branding choice.
        fontFamily = GetConvar('qbx_chat:fontFamily', "'Geom Graphic W03', 'Segoe UI', Arial, Helvetica, sans-serif"),
        consoleFontFamily = GetConvar('qbx_chat:consoleFontFamily', "'Roboto Mono', monospace"),
        suggestionFontFamily = GetConvar('qbx_chat:suggestionFontFamily', "'Roboto Mono', monospace"),

        inputIconUrl = GetConvar('qbx_chat:inputIconUrl', 'https://cfx-nui-qbx_chat_theme/theme/icons/duck.png'),
        messageIconUrl = GetConvar('qbx_chat:messageIconUrl', 'https://cfx-nui-qbx_chat_theme/theme/icons/message.svg'),
        consoleIconUrl = GetConvar('qbx_chat:consoleIconUrl', 'https://cfx-nui-qbx_chat_theme/theme/icons/console.svg'),
        joinIconUrl = GetConvar('qbx_chat:joinIconUrl', 'https://cfx-nui-qbx_chat_theme/theme/icons/join.svg'),
        quitIconUrl = GetConvar('qbx_chat:quitIconUrl', 'https://cfx-nui-qbx_chat_theme/theme/icons/quit.svg'),
        userIconUrl = GetConvar('qbx_chat:userIconUrl', 'https://cfx-nui-qbx_chat_theme/theme/icons/user.svg'),
    })
end)

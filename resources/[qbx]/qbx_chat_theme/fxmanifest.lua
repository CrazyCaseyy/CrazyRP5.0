fx_version 'cerulean'
game 'common'

name 'qbx_chat_theme'
description 'mantine-styled theme for the chat resource.'
version '1.0.0'
author 'um - d4 | <qbox team>'
repository 'https://github.com/Qbox-project/qbx_chat_theme'

-- we need chat to be able to access this resource's callbacks
nui_callback_strict_mode 'false'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/config.lua',
    'client/auto-command.lua',
}

server_scripts {
    'server/join-messages.lua',
    'server/user.lua',
    'server/message-filter.lua',
}

files {
    'theme/**',
}

-- need extra spans around {0} and {1} because of a bug in chat
-- see https://github.com/citizenfx/fivem/pull/3705
-- ?cb=N cache-busters on both paths below - the chat NUI caches these by
-- exact URL, so editing app.css/app.js content alone (even with a full
-- resource restart) silently keeps serving the stale cached version unless
-- this number changes. Bump it on every future edit to either file.
chat_theme 'qbox_chat' {
    styleSheet = 'theme/app.css?cb=2',
    script = 'theme/app.js?cb=2',
    msgTemplates = {
        default = '<p class="message-wrapper"><span class="author alt"><span>{0}</span></span><span><span>{1}</span></span></p>',
        defaultAlt = '<p class="message-wrapper"><span class="alt"><span>{0}</span></span></p>',
        print = '<p class="message-wrapper"><span class="author console">Console</span><span class="print color-7"><span>{0}</span></span></p>',

        join = '<p class="message-wrapper"><span class="join"><span>{0}</span></span></p>',
        quit = '<p class="message-wrapper"><span class="quit"><span>{0}</span></span></p>',
        user = '<p class="message-wrapper"><span class="author user"><span>{0}</span></span><span><span>{1}</span></span></p>',
    },
}

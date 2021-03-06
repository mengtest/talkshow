
local pairs = pairs
local ipairs = ipairs

local type_msg = {
    [1000] = {
        "error_code",
        "notify_info",
        "logout",
        "heart_beat",
        "heart_beat_response",
        "response",
    },

    [2000] = {
        "user_info",
        "user_all",
        "info_all",
        "update_user",
        "get_role",
        "role_info",
        "room_info",
        "room_user",
        "room_all",
        "room_list_info",
    },

    [2100] = {
        "enter_game",
    },

    [2200] = {
        "test_update_day",
    },

    [2300] = {
        "new_room",
        "join",
        "iap",
        "update_day",
        "charge",
        "charge_ret",
        "room_list",
        "get_room_list",
        "change_user",
    },
    
    [20000] = {
        "quit",
        "change_room",
        "show",
        "speak",
        "stage",
        "unstage",
    },
}

local msg = {}
local name_msg = {}

for k, v in pairs(type_msg) do
    for k1, v1 in ipairs(v) do
        local i = k + k1
        msg[i] = v1
        name_msg[v1] = i
    end
end

local proto = {
    msg = msg,
    name_msg = name_msg,
}

function proto.get_id(name)
    return name_msg[name]
end

function proto.get_name(id)
    return msg[id]
end

return proto

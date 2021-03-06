local msgserver = require "snax.msgserver"
local skynet = require "skynet"

local error = error
local assert = assert
local string = string

local loginservice = tonumber(...)

local server = {}
local users = {}
local username_map = {}
local internal_id = 0
local agent_mgr

-- login server disallow multi login, so login_handler never be reentry
-- call by login server
function server.login_handler(info)
	local id = info.id
	if users[id] then
		error(string.format("%d is already login", id))
	end

	internal_id = internal_id + 1
	local sid = internal_id	-- don't use internal_id directly
	local sname = info.server
	local username = msgserver.username(id, sid, sname)

	-- you can use a pool to alloc new agent
    local agent = skynet.call(agent_mgr, "lua", "get")
	local u = {
		username = username,
		agent = agent,
		id = id,
		subid = sid,
        server = sname,
        serverid = info.serverid,
	}

	-- trash subid (no used)
	info.gate = skynet.self()
	info.subid = sid
	skynet.call(agent, "lua", "login", info)

	users[id] = u
	username_map[username] = u

	msgserver.login(username, info.secret)

	-- you should return unique subid
	return sid
end

-- call by agent
function server.logout_handler(id)
	local u = users[id]
	if u then
		local username = msgserver.username(u.id, u.subid, u.server)
		assert(u.username == username)
		msgserver.logout(username)
		users[id] = nil
		username_map[username] = nil
		skynet.call(loginservice, "lua", "logout", id)
        skynet.call(agent_mgr, "lua", "free", u.agent)
	end
end

-- call by login server
function server.kick_handler(id)
    skynet.error(string.format("kick user %d.", id))
	local u = users[id]
	if u then
		local username = msgserver.username(u.id, u.subid, u.server)
		assert(u.username == username)
        skynet.call(u.agent, "lua", "logout")
	end
end

function server.shutdown_handler()
    for k, v in pairs(users) do
        skynet.call(v.agent, "lua", "logout")
    end
end

-- call by self (when socket disconnect)
function server.disconnect_handler(username)
	local u = username_map[username]
	if u then
		skynet.call(u.agent, "lua", "afk")
	end
end

function server.connect_handler(username, addr)
    local u = username_map[username]
    if u then
        addr = addr:match("^(.*):")
        skynet.call(u.agent, "lua", "btk", addr)
    end
end

-- call by self (when recv a request from client)
function server.request_handler(username, msg)
	local u = username_map[username]
	return skynet.tostring(skynet.rawcall(u.agent, "client", msg))
end

-- call by self (when gate open)
function server.register_handler(conf)
    agent_mgr = skynet.queryservice("agent_mgr")
	skynet.call(loginservice, "lua", "register_gate", conf, skynet.self())
    local server_mgr = skynet.queryservice("server_mgr")
    skynet.call(server_mgr, "lua", "register_gate", skynet.self())
end

msgserver.start(server)


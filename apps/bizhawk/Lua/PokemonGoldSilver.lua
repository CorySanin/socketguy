--Pokemon Gold and Silver for socketguy by Cory Sanin
--Works in BizHawk with necessary files
--For more info, go to https://github.com/corysanin/socketguy
package.cpath = ";../?.dll;"
package.path = ";../socket/?.lua;./lib/?.lua;"
socket = require('socket')
json = require('json')
fifo = require('fifo')
local con = socket.udp()
con:setsockname("*", 0)
con:setpeername("127.0.0.1", 3616)
con:settimeout(5)
-- find out which port we're using
local ip, port = con:getsockname()
-- Output the port we're using
print("Port: " .. port)

local payload = {}
payload.id = -1
payload.message = 0

queue = fifo()

memory.usememorydomain("System Bus")

function inBattle()
    memory.usememorydomain("System Bus")
    return memory.readbyte(0xD116) ~= 0
end

function battleReady()
    memory.usememorydomain("System Bus")
    return bit.bor(memory.readbyte(0xCB1C), memory.readbyte(0xCB1D)) ~= 0x00
end

function setName(baseaddress, maxlength, name)
    memory.usememorydomain("System Bus")
    name = string.upper(name)
    for i = 0,maxlength-1,1
    do
        c = string.byte(name, i+1)
        if c == nil then
            c = 0x50
        elseif c == 32 then
            c = 0x7F
        elseif c == 33 then
            c = 0xE7
        elseif c == 63 then
            c = 0xE6
        else
            c = math.max(c - 65, 0) % 26 + 0x80
        end
        memory.writebyte(baseaddress + i, c)
    end
end

function convertString(name)
    --name = string.upper(name)
    local out = ""
    for i = 0,string.len(name)-1,1
    do
        c = string.byte(name, i+1)
        if c == nil then
            c = "50 "
        elseif c == 32 then
            c = "7F "
        elseif c == 33 then
            c = "E7 "
        elseif c == 63 then
            c = "E6 "
        else
            if c > 96 then
                c = string.format("%x", (math.max(c - 97, 0) + 0xA0)) .. " "
            else
                c = string.format("%x", (math.max(c - 65, 0) + 0x80)) .. " "
            end
        end
        out = out .. c
    end
    return string.upper(out)
end

function setPokemonName(p, name)
    setName(0xDB8C + 0xB * (p % 6), 10, name)
end

function setTrainerName(name)
    setName(0xD1A3, 7, name)
end

function setRivalName(name)
    setName(0xD1B5, 7, name)
end

function statusToValue(status)
    memory.usememorydomain("System Bus")
    v = nil
    if status == "sleep" then
        v = math.random(0x1,0x3)
    elseif status == "poison" then
        v = 0x8
    elseif status == "burn" then
        v = 0x10
    elseif status == "freeze" then
        v = 0x20
    elseif status == "paralyze" then
        v = 0x40
    elseif status == "fullheal" then
        v = 0x00
    else
        print("WARNING: status was '" .. status .. "' and couldn't match")
    end
    return v
end

function setStatus(status)
    v = statusToValue(status)
    memory.usememorydomain("System Bus")
    -- if v ~= 0 then
    --     v = bit.bor(v, memory.readbyte(0xCB1A))
    -- end
    memory.writebyte(0xCB1A, v)
end

function setEnemyStatus(status)
    v = statusToValue(status)
    memory.usememorydomain("System Bus")
    -- if v ~= 0 then
    --     v = bit.bor(v, memory.readbyte(0xD0FD))
    -- end
    memory.writebyte(0xD0FD, v)
end

function updateScene(inbattle)
    local s = "default"
    if inbattle then
        s = "battle"
    end
    local p = {id = payload.id, message = { scene = s}}
    con:send(json.encode(p))
end

con:send(json.encode(payload))
print("Waiting for response...")
payload.id = json.decode(con:receive()).id
print("ID received: " .. payload.id)

con:settimeout(0)

wasinbattle = inBattle()
inbattle = wasinbattle

updateScene(inbattle)

while true do
    if emu.framecount() % 4 == 0 then
        if emu.framecount() % 12 == 0 then
            -- keep connection alive
            con:send(json.encode(payload))
            payload.message = 0
            -- handle queue
            if queue:length() > 0 then
                command = queue:pop()
                msg = {user = command.participant, transactionID = command.transactionID, text = nil}
                m = string.match(command.control,"name%-(.+)")
                if m ~= nil then
                    if m == "rival" then
                        setRivalName(command.message)
                        msg.text = "Set rival's name to " .. command.message
                    else
                        m = tonumber(string.match(m, "pokemon(%d)"))
                        setPokemonName(m - 1, command.message)
                        msg.text = "Set Pokemon " .. m .. "'s name to " .. command.message
                    end
                elseif battleReady() then
                    m = string.match(command.control,"player%-(.+)")
                    if m ~= nil then
                        setStatus(m)
                        msg.text = "Set player status"
                    else
                        m = string.match(command.control,"op%-(.+)")
                        setEnemyStatus(m)
                        msg.text = "Set enemy status"
                    end
                else
                    queue:push(command)
                end
                if msg.text ~= nil then
                    payload.message = msg
                end
            end
        else
            inst = con:receive()
            if inst ~= nil then
                queue:push(json.decode(inst))
            end
        end
    end

    inbattle = inBattle()
    if inbattle ~= wasinbattle then
        updateScene(inbattle)
        wasinbattle = inbattle
    end

    emu.frameadvance()
end	
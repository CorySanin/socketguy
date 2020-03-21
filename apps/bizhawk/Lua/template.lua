--Template by Cory Sanin
--Works in BizHawk with necessary files
--For more info, go to https://github.com/corysanin/socketguy
package.cpath = ";../?.dll;"
package.path = ";../socket/?.lua;"
socket = require('socket')
json = require('json')
fifo = require('fifo')
local con = socket.udp()
con:setsockname("*", 0)
con:setpeername("127.0.0.1", 3616)
-- find out which port we're using
local ip, port = con:getsockname()
-- Output the port we're using
print("Port: " .. port)

local payload = {}
payload.id = -1
payload.message = 0

queue = fifo()

con:send(json.encode(payload))
print("Waiting for response...")
payload.id = json.decode(con:receive()).id
print("ID received: " .. payload.id)

local inst
while true do
    if emu.framecount() % 4 == 0 then
        if emu.framecount() % 12 == 0 then
            -- keep connection alive - send 0 if no message to display
            con:send(json.encode(payload))
            payload.message = 0
            -- handle queue
            if queue:length() > 0 then
                command = queue:pop()
                msg = {user = command.participant, transactionID = command.transactionID, text = "Input received: " .. command.control}
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
    emu.frameadvance()
end	
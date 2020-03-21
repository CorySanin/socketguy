--Super Mario Bros 3 for socketguy by Cory Sanin
--Works in BizHawk with necessary files
--For more info, go to https://github.com/corysanin/socketguy
package.cpath = ";../?.dll;"
package.path = ";../socket/?.lua;./lib/?.lua;"
socket = require('socket')
json = require('json')
local con = socket.udp()
con:setsockname("*", 0)
con:setpeername("127.0.0.1", 3616)
con:settimeout(10);
-- find out which port we're using
local ip, port = con:getsockname()
-- Output the port we're using
print("Port: " .. port)
local inst
local buttid
local inlevel = false
local payload = {}
payload.message = 0
payload.id = -1

--Queue from http://stackoverflow.com/questions/37245889/lua-queue-implementation/37250097
--sorry, I'm not super fluent in Lua, so I copied this to save time.
dataQ = {}
dataQ.first = 0
dataQ.last = -1
dataQ.data = {}

function insert(q, val)
  q.last = q.last + 1
  q.data[q.last] = val
end

function remove(q)
    rval = 0
    if (q.first > q.last) then 
      rval = -1
    else
      rval = q.data[q.first]
      q.data[q.first] = nil
      q.first = q.first + 1
    end
    return rval
end

--You can all this from the console to empty your inventory
function clearInventory()
    memory.writebyte(32128,0)
    memory.writebyte(32129,0)
    memory.writebyte(32130,0)
    memory.writebyte(32131,0)
    memory.writebyte(32132,0)
    memory.writebyte(32133,0)
    memory.writebyte(32134,0)
    memory.writebyte(32135,0)
    memory.writebyte(32136,0)
    memory.writebyte(32137,0)
    memory.writebyte(32138,0)
    memory.writebyte(32139,0)
    memory.writebyte(32140,0)
    memory.writebyte(32141,0)
    memory.writebyte(32142,0)
    memory.writebyte(32143,0)
    memory.writebyte(32144,0)
    memory.writebyte(32145,0)
    memory.writebyte(32146,0)
    memory.writebyte(32147,0)
    memory.writebyte(32148,0)
    memory.writebyte(32149,0)
    memory.writebyte(32150,0)
    memory.writebyte(32151,0)
    memory.writebyte(32152,0)
    memory.writebyte(32153,0)
    memory.writebyte(32154,0)
    memory.writebyte(32155,0)
    print("Inventory Emptied")
end
--alt command
function emptyInventory()
    clearInventory()
end

--Some memory is on SRAM
memory.usememorydomain("System Bus")

con:send(json.encode(payload));
print("Waiting for response...")
payload.id = json.decode(con:receive()).id
print("ID received: " .. payload.id)

con:settimeout(0);

while true do
    if emu.framecount() % 12 == 0 then
        if emu.framecount() % 60 == 0 then
            --Send "0" if just requesting buttons,\
            --or a message if requesting buttons AND want to display the message
            con:send(json.encode(payload));
            payload.message = "0"
            
            --Gives lives if running out
            --You can get rid of this if you want to be able to lose
            if mainmemory.readbyte(1846) <= 1 then
                mainmemory.writebyte(1846,2)
            end
        else
            inst = con:receive()
            if inst ~= nil then
                print("received UDP:" .. inst)
                inst = json.decode(inst)
                
                insert(dataQ,inst)
            end
        end
    end
    --Process what's in the queue
    if emu.framecount() % 5 == 0 and dataQ.first <= dataQ.last then
        --There's something in the queue
        butt = remove(dataQ)
        msg = {user = butt.participant, transactionID = butt.transactionID, text = nil}
        inlevel = (memory.readbyte(32252) == 54 and memory.readbyte(32253) == 39)
        if inlevel and butt.control == "pswitch" then
            --press P switch
            mainmemory.writebyte(1383,128)
            mainmemory.writebyte(1247,27)
            msg.text = "P Switch Activated"
            print(msg.text)
        else
            buttid = tonumber(butt.control)
            if buttid > 0 and buttid <= 6 then
                if inlevel then
                    mainmemory.writebyte(1400,buttid + 1)
                    mainmemory.writebyte(1364,20)
                    msg.text = "Item Equipped"
                else
                    mainmemory.writebyte(1862,buttid)
                    msg.text = "Item Will Be Equipped"
                end
                print(msg.text)
            elseif buttid > 6 and buttid <= 19 then
                --
                msg.text = "Item Added to Inventory"
                if memory.readbyte(32128) == 0 then
                    memory.writebyte(32128,buttid - 6)
                elseif memory.readbyte(32129) == 0 then
                    memory.writebyte(32129,buttid - 6)
                elseif memory.readbyte(32130) == 0 then
                    memory.writebyte(32130,buttid - 6)
                elseif memory.readbyte(32131) == 0 then
                    memory.writebyte(32131,buttid - 6)
                elseif memory.readbyte(32132) == 0 then
                    memory.writebyte(32132,buttid - 6)
                elseif memory.readbyte(32133) == 0 then
                    memory.writebyte(32133,buttid - 6)
                elseif memory.readbyte(32134) == 0 then
                    memory.writebyte(32134,buttid - 6)
                elseif memory.readbyte(32135) == 0 then
                    memory.writebyte(32135,buttid - 6)
                elseif memory.readbyte(32136) == 0 then
                    memory.writebyte(32136,buttid - 6)
                elseif memory.readbyte(32137) == 0 then
                    memory.writebyte(32137,buttid - 6)
                elseif memory.readbyte(32138) == 0 then
                    memory.writebyte(32138,buttid - 6)
                elseif memory.readbyte(32139) == 0 then
                    memory.writebyte(32139,buttid - 6)
                elseif memory.readbyte(32140) == 0 then
                    memory.writebyte(32140,buttid - 6)
                elseif memory.readbyte(32141) == 0 then
                    memory.writebyte(32141,buttid - 6)
                elseif memory.readbyte(32142) == 0 then
                    memory.writebyte(32142,buttid - 6)
                elseif memory.readbyte(32143) == 0 then
                    memory.writebyte(32143,buttid - 6)
                elseif memory.readbyte(32144) == 0 then
                    memory.writebyte(32144,buttid - 6)
                elseif memory.readbyte(32145) == 0 then
                    memory.writebyte(32145,buttid - 6)
                elseif memory.readbyte(32146) == 0 then
                    memory.writebyte(32146,buttid - 6)
                elseif memory.readbyte(32147) == 0 then
                    memory.writebyte(32147,buttid - 6)
                elseif memory.readbyte(32148) == 0 then
                    memory.writebyte(32148,buttid - 6)
                elseif memory.readbyte(32149) == 0 then
                    memory.writebyte(32149,buttid - 6)
                elseif memory.readbyte(32150) == 0 then
                    memory.writebyte(32150,buttid - 6)
                elseif memory.readbyte(32151) == 0 then
                    memory.writebyte(32151,buttid - 6)
                elseif memory.readbyte(32152) == 0 then
                    memory.writebyte(32152,buttid - 6)
                elseif memory.readbyte(32153) == 0 then
                    memory.writebyte(32153,buttid - 6)
                elseif memory.readbyte(32154) == 0 then
                    memory.writebyte(32154,buttid - 6)
                elseif memory.readbyte(32155) == 0 then
                    memory.writebyte(32155,buttid - 6)
                else
                    msg = {user = nil, transactionID = nil, text = "Inventory is full"}
                end
                print(msg.message)
            else
                insert(dataQ,buttid)
            end
        end
        if msg.text ~= nil then
            payload.message = msg
        end
    end
	emu.frameadvance()
end	
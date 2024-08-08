-- Setup QL1
ipaddress = "10.1.2.18"
port = 49280

--Open TCP Conection and print returned messages to debug
ql1 = TcpSocket.New()
ql1:Connect(ipaddress, port)

-- ### Q-SYS to QL1 ###
--Button / GPI for input i toggle ch i-1
for i = 1, 20 do
    Controls.mute[i].EventHandler = function()
        if Controls.mute[i].Boolean == true then
            ql1:Write(table.concat({ tostring('set MIXER:Current/InCh/Fader/On '), tostring(i - 1), tostring(' 0 1\n') }))
            --ql1:Write('set MIXER:Current/InCh/Fader/On 0 0 1\n')
        elseif Controls.mute[i].Boolean == false then
            ql1:Write(table.concat({ tostring('set MIXER:Current/InCh/Fader/On '), tostring(i - 1), tostring(' 0 0\n') }))
            --ql1:Write('set MIXER:Current/InCh/Fader/On 0 0 0\n')
        end
    end
end

-- ### QL1 to Q-Sys ###
ql1.EventHandler = function(socket, event, err)
    --print(ql1:ReadLine(TcpSocket.EOL.Any))
    ql1Status = (ql1:ReadLine(TcpSocket.EOL.Any))
    if ql1Status == nil then
        ql1:Write("devstatus runmode \n")
    else
        print(ql1Status)

        if string.find(ql1Status, "MIXER:Current/InCh/Fader/On") then -- is it a Channel Mute thing
            --print ("It's a Mute thing")
            channel = tonumber(string.sub(ql1Status, string.find(ql1Status, "/On") + 4, string.find(ql1Status, "/On") + 5))
            ---print("chanel: "..channel)
            if string.find(ql1Status, "NOTIFY") then -- is it a 'NOTIFY' thing take the digit from before the "O of "OFF"/"ON"
                muteStatus = string.sub(ql1Status, string.find(ql1Status, '"O') - 2, string.find(ql1Status, '"O') - 1)
                --end
            elseif string.find(ql1Status, "set") then -- is it a 'set' thing take the digit from before the "O of "OFF"/"ON"
                muteStatus = string.sub(ql1Status, string.find(ql1Status, '"O') - 2, string.find(ql1Status, '"O') - 1)
                --end
            elseif string.find(ql1Status, "get") then -- is it a 'get' thing take last digit of string -- get message does not contian "ON"/"OFF"
                muteStatus = string.sub(ql1Status, -2, -1)
            end
            --print("muteStatus: "..muteStatus)
            if channel <= 19 then -- ignore mute commands for greater than Channel 20
                if string.find(muteStatus, "1") then
                    --print("is On")
                    Controls.mute[channel + 1].Legend = 'On'
                    Controls.mute[channel + 1].Color = '#33cc00'
                elseif string.find(muteStatus, "0") then
                    --print("is off")
                    Controls.mute[channel + 1].Legend = 'Off'
                    Controls.mute[channel + 1].Color = '#333333'
                end
            else
                return
            end
        else
            getStatus()
        end
    end
end

-- ### Get Status of desk mutes ### --
-- get status function
function getStatus()
    -- Establish timer - used to rate limit flow
    timer0 = Timer.New()
    -- when active the timer does:
    timer0.EventHandler = function()
        message = "get MIXER:Current/InCh/Fader/On " .. loopIndex .. " 0\n"
        print(message)
        ql1:Write(message)
        loopIndex = loopIndex + 1
        if loopIndex > 19 then
            timer0:Stop()
        end
    end
    loopIndex = 0 -- start point index loop
    timer0:Start(.01) -- 'tick interval' to send get status messages
end

-- listen for getStatus Button Press
Controls.getStatus.EventHandler = function()
    if Controls.getStatus.Boolean == true then
        print("getStatus pressed")
        getStatus()
    elseif Controls.getStatus.Boolean == false then
        print("getStatus is not true")
    end
end

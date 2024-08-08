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
    end

    if ql1Status == nil then
        return
    else
        if string.find(ql1Status, "MIXER:Current/InCh/Fader/On") then -- is it a Channel Mute thing
            --print ("It's a Mute thing")
            channel = tonumber(string.sub(ql1Status, string.find(ql1Status, "/On") + 4, string.find(ql1Status, "/On") + 5))
            --print("chanel: "..channel)
            muteStatus = string.sub(ql1Status, string.find(ql1Status, '"O') - 2, string.find(ql1Status, '"O') - 1)
            --print("muteStatus: "..muteStatus)

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
            print("It's somthing else")
        end
    end
end

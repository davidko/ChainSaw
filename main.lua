XcChain = {}

XcChain.state = false -- Not shooting

XcChain.count = 0

function XcChain:shoot(enable)
    -- if enable, begin chainfiring.
    if enable then
        -- If we are already shooting, ignore this one
        if XcChain.state then
            return
        else
            XcChain.state = true
        end
    end
end

timer = Timer()

period = 0.25 * 1000

function myTimeout()
    if XcChain.count % 2 == 0 then
        print('Enable left')
        ConfigureWeaponGroup(0, {2})
    else
        print('Enable Right')
        ConfigureWeaponGroup(0, {3})
    end
    XcChain.count = XcChain.count + 1
    if XcChain.state then
        timer:SetTimeout(period, myTimeout)
    end
end

RegisterUserCommand('xcchain.test1', function(_, args) 
    myTimeout()
end)

RegisterUserCommand('xcchain.shoot', function(_, args) 
    if args[1] == "on" then
        if(XcChain.state) then
            return
        end
        print('Enable fire')
        XcChain.state = true
        myTimeout()
    else
        print('Disable fire')
        XcChain.state = false 
        XcChain.count = 0
        timer:Kill()
    end
end)

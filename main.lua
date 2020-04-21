XcChain = {}

XcChain.state = false -- Not shooting
XcChain.enabled = false

XcChain.count = 1
XcChain.period = 1 -- seconds
XcChain.ports = {} -- List of ports to chainfire

XcChain._firingPorts = {}

XcChain._stopTimers = {}
XcChain._timers = {}

XcChain._userWeaponGroups = {}

function XcChain:enable()
    -- We need to get a list of all ports with energy weapons, as well as the
    -- weapon with the highest period of fire
    XcChain.ports = {}
    local maxDelay = 0
    for i=1,6 do
        local itemId = GetActiveShipItemIDAtPort(i)
        if itemId ~= nil then
            -- Get the item description
            local desc = GetInventoryItemLongDesc(itemId)
            -- Make sure there's no "Capacity"
            if string.find(desc, "Capacity") == nil then
                print('Adding port '..i..' with item desc: '..desc)
                table.insert(XcChain.ports, i)
                local delay_str = string.match(desc, "Delay:([%d .]+)s")
                local delay = tonumber(delay_str)
                if delay > maxDelay then
                    maxDelay = delay
                end
            end
        end
    end
    if table.getn(XcChain.ports) > 0 then
        XcChain.period = maxDelay / table.getn(XcChain.ports)
    else
        XcChain.period = 1
    end


    -- Configure the weapon groups now
    for i=1,table.getn(XcChain.ports) do
        ConfigureWeaponGroup(i-1, {XcChain.ports[i]})
    end

end

timer = Timer()

function XcChain_shoot()
    if table.getn(XcChain.ports) == 0 then
        return
    end
    local index = (XcChain.count % table.getn(XcChain.ports)) + 1
    print('index: '..index)
    print('Enable weapon group:'..index)
    gkinterface.GKProcessCommand('Weapon'..index)
    XcChain.count = XcChain.count + 1
    if XcChain.state then
        timer:SetTimeout(XcChain.period*1000*1.1, XcChain_shoot)
    end
end

RegisterUserCommand('xcchain.toggle', function()
    XcChain.enabled = not XcChain.enabled
    if XcChain.enabled then
        print('Chain fire enabled.')
        XcChain:enable()
    else
        print('Chain fire disabled.')
    end
end)

RegisterUserCommand('xcchain.shoot', function(_, args) 
    if args[1] == "on" then
        if(XcChain.state) then
            return
        end
        print('Enable fire')
        XcChain.state = true
        gkinterface.GKProcessCommand('+Shoot2')
        timer:SetTimeout(XcChain.period*1000*1.1, XcChain_shoot)
        -- XcChain_shoot()
    else
        print('Disable fire')
        gkinterface.GKProcessCommand('+Shoot2 0')
        gkinterface.GKProcessCommand('Weapon1')
        XcChain.state = false 
        XcChain.count = 1
        -- timer:Kill()
    end
end)

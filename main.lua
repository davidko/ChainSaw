XcChain = {}

XcChain.state = false -- Not shooting
XcChain.enabled = false

XcChain.count = 0
XcChain.period = 1 -- seconds
XcChain.ports = {} -- List of ports to chainfire

XcChain._firingPorts = {}

XcChain._stopTimers = {}
XcChain._timers = {}

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
    print('Max delay: '..maxDelay)
    if table.getn(XcChain.ports) > 0 then
        XcChain.period = maxDelay / table.getn(XcChain.ports)
    else
        XcChain.period = 1
    end
    for i=1, table.getn(XcChain.ports) do
        table.insert(XcChain._timers, Timer())
        table.insert(XcChain._stopTimers, Timer())
    end
end

-- timer = Timer()

function XcChain_shoot()
    if table.getn(XcChain.ports) == 0 then
        return
    end
    local index = XcChain.count + 2
    print('index: '..index)
    local port = XcChain.ports[index]
    if port == nil then
        return
    end
    print('Enable ports: '..port)
    table.insert(XcChain._firingPorts, port)
    --ConfigureWeaponGroup(0, XcChain._firingPorts)
    print('Add weapon to group: '..XcChain.count)
    ConfigureWeaponGroup(XcChain.count, {port}, function()
        print('Done configuring weapon group.')
    end)
    gkinterface.GKProcessCommand('+Shoot2')
    XcChain.count = XcChain.count + 1
    if XcChain.state then
        -- timer:SetTimeout(XcChain.period*1000, XcChain_shoot)
    end
end

RegisterUserCommand('xcchain.toggle', function()
    XcChain.enabled = not XcChain.enabled
    if XcChain.enabled then
        print('Chain fire enabled.')
        ConfigureWeaponGroup(0, {})
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
        -- gkinterface.GKProcessCommand('+Shoot2')
        local period = XcChain.period*1000
        if period < 0 then
            period = 1
        end
        XcChain_shoot()
        for i=1, table.getn(XcChain.ports)-1 do
            --XcChain._stopTimers[i]:SetTimeout(period*i-(period/2), function()
              --  gkinterface.GKProcessCommand('+Shoot2 0')
            --end)
            XcChain._timers[i]:SetTimeout(period*i, XcChain_shoot)
        end
    else
        print('Disable fire')
        gkinterface.GKProcessCommand('+Shoot2 0')
        XcChain._firingPorts = {}
        local port = XcChain.ports[1]
        if port ~= nil then
            XcChain._firingPorts = {port}
            ConfigureWeaponGroup(0, {port})
        end
        XcChain.state = false 
        XcChain.count = 0
        -- timer:Kill()
    end
end)

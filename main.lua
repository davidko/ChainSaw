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

XcChain._safetyFactor = 1.2 -- Increase the delay just a little to ensure
                             -- every weapon group fires

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
                local delay_str = string.match(desc, "Delay:([%d .]+)s")
                if delay_str ~= nil then
                    print('Adding port '..i..' with item desc: '..desc)
                    table.insert(XcChain.ports, i)
                    local delay = tonumber(delay_str)
                    if delay > maxDelay then
                        maxDelay = delay
                    end
                end
            end
        end
    end
    if table.getn(XcChain.ports) > 0 then
        XcChain.period = maxDelay / table.getn(XcChain.ports)
    else
        XcChain.period = 1
    end

    -- Save the user's weapon groups
    for i=0, 17 do
        local group = GetActiveShipWeaponGroup(i)
        local ports = {}
        for k,v in pairs(group) do
            if v then
                table.insert(ports, k)
                print('Save port '..k..' to group '..i)
            end
        end
        XcChain._userWeaponGroups[i] = ports
        console_print('Group: '..i)
        printtable(ports)
    end
        
    -- Configure the new weapon groups now
    for i=1,table.getn(XcChain.ports) do
        ConfigureWeaponGroup(i-1, {XcChain.ports[i]})
    end
end

function XcChain:disable()
    -- Configure the user's old weapon groups
    for i=0,17 do
        ConfigureWeaponGroup(i, XcChain._userWeaponGroups[i])
    end
    gkinterface.GKProcessCommand('Weapon1')
end

timer = Timer()

function XcChain_shoot()
    if table.getn(XcChain.ports) == 0 then
        return
    end
    local index = (XcChain.count % table.getn(XcChain.ports)) + 1
    gkinterface.GKProcessCommand('Weapon'..index)
    XcChain.count = XcChain.count + 1
    if XcChain.state then
        timer:SetTimeout(XcChain.period*1000*XcChain._safetyFactor, XcChain_shoot)
    end
end

RegisterUserCommand('xcchain.toggle', function()
    XcChain.enabled = not XcChain.enabled
    if XcChain.enabled then
        print('Chain fire enabled.')
        XcChain:enable()
    else
        print('Chain fire disabled.')
        XcChain:disable()
    end
end)

RegisterUserCommand('xcchain.enable', function()
    if not XcChain.enabled then
        XcChain:enable()
        XcChain.enabled = true
    end
end)

RegisterUserCommand('xcchain.disable', function()
    if XcChain.enabled then
        XcChain:disable()
        XcChain.enabled = false
    end
end)

RegisterUserCommand('xcchain.shoot', function(_, args) 
    if args[1] == "on" then
        if not XcChain.enabled then
            gkinterface.GKProcessCommand('+Shoot2')
            return
        end
        if(XcChain.state) then
            return
        end
        XcChain.state = true
        gkinterface.GKProcessCommand('+Shoot2')
        timer:SetTimeout(XcChain.period*1000*XcChain._safetyFactor, XcChain_shoot)
    else
        if not XcChain.enabled then
            gkinterface.GKProcessCommand('+Shoot2 0')
            return
        end
        gkinterface.GKProcessCommand('+Shoot2 0')
        gkinterface.GKProcessCommand('Weapon1')
        XcChain.state = false 
        XcChain.count = 1
    end
end)

-- If we are enabled, re-enable every time we leave a station in case our loadout changed
RegisterEvent( function()
    if XcChain.enabled then
        XcChain:enable()
    end
end, 'LEAVING_STATION')

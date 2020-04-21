ChainSaw = {}

ChainSaw.initialized = false
ChainSaw.state = false -- Not shooting
ChainSaw.enabled = false

ChainSaw.count = 1
ChainSaw.period = 1 -- seconds
ChainSaw.ports = {} -- List of ports to chainfire

ChainSaw._firingPorts = {}

ChainSaw._stopTimers = {}
ChainSaw._timers = {}

ChainSaw._userWeaponGroups = {}

ChainSaw._safetyFactor = 1.2 -- Increase the delay just a little to ensure
                             -- every weapon group fires

function ChainSaw:enable()
    -- We need to get a list of all ports with energy weapons, as well as the
    -- weapon with the highest period of fire
    ChainSaw.ports = {}
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
                    -- print('Adding port '..i..' with item desc: '..desc)
                    table.insert(ChainSaw.ports, i)
                    local delay = tonumber(delay_str)
                    if delay > maxDelay then
                        maxDelay = delay
                    end
                end
            end
        end
    end
    if table.getn(ChainSaw.ports) > 0 then
        ChainSaw.period = maxDelay / table.getn(ChainSaw.ports)
    else
        ChainSaw.period = 1
    end

    -- Save the user's weapon groups
    for i=0, 17 do
        local group = GetActiveShipWeaponGroup(i)
        local ports = {}
        for k,v in pairs(group) do
            if v then
                table.insert(ports, k)
            end
        end
        ChainSaw._userWeaponGroups[i] = ports
    end
        
    -- Configure the new weapon groups now
    for i=1,table.getn(ChainSaw.ports) do
        ConfigureWeaponGroup(i-1, {ChainSaw.ports[i]})
    end
end

function ChainSaw:disable()
    -- Configure the user's old weapon groups
    for i=0,17 do
        ConfigureWeaponGroup(i, ChainSaw._userWeaponGroups[i])
    end
    gkinterface.GKProcessCommand('Weapon1')
end

timer = Timer()

function ChainSaw_shoot()
    if table.getn(ChainSaw.ports) == 0 then
        return
    end
    local index = (ChainSaw.count % table.getn(ChainSaw.ports)) + 1
    gkinterface.GKProcessCommand('Weapon'..index)
    ChainSaw.count = ChainSaw.count + 1
    if ChainSaw.state then
        timer:SetTimeout(ChainSaw.period*1000*ChainSaw._safetyFactor, ChainSaw_shoot)
    end
end

RegisterUserCommand('chainsaw.toggle', function()
    ChainSaw.enabled = not ChainSaw.enabled
    if ChainSaw.enabled then
        print('Chain fire enabled.')
        ChainSaw:enable()
    else
        print('Chain fire disabled.')
        ChainSaw:disable()
    end
end)

RegisterUserCommand('chainsaw.enable', function()
    if not ChainSaw.enabled then
        ChainSaw:enable()
        ChainSaw.enabled = true
    end
end)

RegisterUserCommand('chainsaw.disable', function()
    if ChainSaw.enabled then
        ChainSaw:disable()
        ChainSaw.enabled = false
    end
end)

RegisterUserCommand('chainsaw.shoot', function(_, args) 
    if args[1] == "on" then
        if not ChainSaw.enabled then
            gkinterface.GKProcessCommand('+Shoot2')
            return
        end
        if(ChainSaw.state) then
            return
        end
        ChainSaw.state = true
        gkinterface.GKProcessCommand('+Shoot2')
        timer:SetTimeout(ChainSaw.period*1000*ChainSaw._safetyFactor, ChainSaw_shoot)
    else
        if not ChainSaw.enabled then
            gkinterface.GKProcessCommand('+Shoot2 0')
            return
        end
        gkinterface.GKProcessCommand('+Shoot2 0')
        gkinterface.GKProcessCommand('Weapon1')
        ChainSaw.state = false 
        ChainSaw.count = 1
    end
end)

-- If we are enabled, re-enable every time we leave a station in case our loadout changed
RegisterEvent( function()
    if ChainSaw.enabled then
        ChainSaw:enable()
    end
end, 'LEAVING_STATION')

RegisterEvent( function()
    if not ChainSaw.initialized then
        -- Load the alias config file
        print('Loading chainsaw config file...')
        gkinterface.GKProcessCommand('load chainsaw.cfg')
        ChainSaw.initialized = true
    end
end, 'PLAYER_ENTERED_GAME')

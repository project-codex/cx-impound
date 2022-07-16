local QBCore = exports['qb-core']:GetCoreObject()

local function buyoutMenu(officer, citizen, vehicle, plate, price, impoundTime)

    local buyoutMenu = {{
        header = "Impounded by",
        txt = officer,
        isMenuHeader = true
    }, {
        header = "Owned by",
        txt = citizen,
        isMenuHeader = true
    }, {
        header = "Vehicle",
        txt = vehicle,
        isMenuHeader = true
    }, {
        header = "Plate",
        txt = plate,
        isMenuHeader = true
    }, {
        header = "Buyout price",
        txt = price,
        isMenuHeader = true
    }, {
        header = "Impound time",
        txt = impoundTime .. " minutes",
        isMenuHeader = true
    }, {
        header = "Un-impound",
        txt = "Un-impound impounded vehicle!",
        params = {
            event = "cx-impound:client:buyoutVehicle"
        }
    }, {
        header = "⬅ Back",
        txt = "",
        params = {
            event = "qb-menu:closeMenu"
        }
    }}

    exports['qb-menu']:openMenu(buyoutMenu)
end

local function impoundedVehicles(vehicles)
    local allVehicles = {{
        header = "Impounded Vehicles",
        isMenuHeader = true
    }}

    for k, v in pairs(vehicles) do
        table.insert(allVehicles, {
            header = QBCore.Shared.Vehicles[v.vehicle].name .. " " .. QBCore.Shared.Vehicles[v.vehicle].brand,
            txt = v.plate,
            params = {
                isServer = true
            }
        })
    end

    allVehicles[#allVehicles + 1] = {
        header = "⬅ Back",
        txt = "",
        params = {
            event = "qb-menu:closeMenu"
        }
    }

    exports['qb-menu']:openMenu(allVehicles)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()

    TriggerServerEvent('cx-impound:server:spawnVehicles')

    exports['qb-target']:SpawnPed({
        model = 'cs_casey',
        coords = Config.PedLocation,
        minusOne = true,
        freeze = true,
        invincible = true,
        blockevents = true,
        animDict = 'abigail_mcs_1_concat-0',
        anim = 'csb_abigail_dual-0',
        flag = 1,
        scenario = 'WORLD_HUMAN_AA_COFFEE',
        target = {
            options = {{
                type = "server",
                event = "cx-impound:server:impoundedVehicles",
                icon = 'fas fa-car',
                label = 'Impounded Vehicles'
            }},
            distance = 2.5
        }
    })
end)

RegisterNetEvent('cx-impound:client:impoundedVehicles', function(vehicles)
    impoundedVehicles(vehicles)
end)

RegisterNetEvent('cx-impound:client:checkVehicle', function()
    local closestVehicle = QBCore.Functions.GetClosestVehicle();
    local vehicleHash = GetEntityModel(closestVehicle)
    local modelName = string.lower(GetDisplayNameFromVehicleModel(vehicleHash))
    local plate = GetVehicleNumberPlateText(closestVehicle)
    local vehicle = QBCore.Shared.Vehicles[modelName]

    if vehicle ~= 0 and vehicle then
        local player = PlayerPedId()
        local playerPos = GetEntityCoords(player)
        local vehiclePos = GetEntityCoords(closestVehicle)
        if #(playerPos - vehiclePos) < 3.0 and not IsPedInAnyVehicle(player) then
            TriggerServerEvent('cx-impound:server:checkVehicle', vehicle, plate)
        else
            TriggerEvent('DoLongHudText',
                "You are not allowed to be in vehicle or maybe there is no vehicle close to you!", 2)
        end
    end
end)

RegisterNetEvent('cx-impound:client:impoundVehicle', function(vehicle, hash, plate, depot_price)
    local dialog = exports['qb-input']:ShowInput({
        header = "Impound Vehicle",
        submitText = "Submit",
        inputs = {{
            type = 'number',
            isRequired = true,
            name = 'impoundTime',
            text = 'Impound time in minutes.'
        }, {
            type = 'number',
            isRequired = true,
            name = 'depotPrice',
            text = 'Depot price without decimals.'
        }}
    })
    if dialog then
        if not dialog then
            return
        end
        local closestVehicle = QBCore.Functions.GetClosestVehicle()
        QBCore.Functions.DeleteVehicle(closestVehicle)
        TriggerServerEvent('cx-impound:server:impoundVehicle', vehicle, hash, plate, dialog.depotPrice,
            dialog.impoundTime)
    end
end)

RegisterNetEvent('cx-impound:client:setVehProperties', function(net, vehicleData)
    local veh = NetworkGetEntityFromNetworkId(net)
    QBCore.Functions.SetVehicleProperties(veh, vehicleData.mods)

    SetEntityCanBeDamaged(veh, false)
    SetEntityInvincible(veh, true)
    FreezeEntityPosition(veh, true)
    SetVehicleDoorsLocked(veh, 2)
    SetVehicleNumberPlateText(veh, vehicleData.plate)
    SetVehicleOnGroundProperly(veh)
end)

RegisterNetEvent('cx-impound:client:buyoutVehicle', function()
    local closestVehicle = QBCore.Functions.GetClosestVehicle();
    local plate = GetVehicleNumberPlateText(closestVehicle)
    local closestPlayer, distance = QBCore.Functions.GetClosestPlayer()

    if (distance ~= -1 and distance < 3.0) then
        TriggerServerEvent('cx-impound:server:buyoutVehicle', plate, GetPlayerServerId(closestPlayer))
    else
        TriggerEvent('DoLongHudText', "There are no citizens near by!", 2)
    end
end)

RegisterNetEvent('cx-impound:client:buyOutData', function()
    local closestVehicle = QBCore.Functions.GetClosestVehicle();
    local plate = GetVehicleNumberPlateText(closestVehicle)

    TriggerServerEvent('cx-impound:server:buyOutData', plate)
end)

RegisterNetEvent('cx-impound:client:openMenu', function(officer, owner, vehicle, plate, buyOutPrice, impoundTime)
    buyoutMenu(officer, owner, vehicle, plate, buyOutPrice, impoundTime)
end)

RegisterNetEvent('cx-impound:client:successfulBuyout', function(vehPlate)
    for k, v in pairs(Config.VehicleSpawns) do
        local closestVeh = GetClosestVehicle(v.x, v.y, v.z, 2.5, 0, 70)
        local plate = QBCore.Functions.GetPlate(closestVeh)
        if plate == vehPlate then
            SetEntityCanBeDamaged(closestVeh, true)
            SetEntityInvincible(closestVeh, false)
            FreezeEntityPosition(closestVeh, false)
            TriggerServerEvent('cx-impound:server:spawnVehicles', k)
            break
        end
    end
end)

-- adds keys to target player
RegisterNetEvent('cx-impound:client:addKeys', function(vehPlate)
    for k, v in pairs(Config.VehicleSpawns) do
        local closestVeh = GetClosestVehicle(v.x, v.y, v.z, 2.5, 0, 70)
        local plate = QBCore.Functions.GetPlate(closestVeh)
        if plate == vehPlate then
            TriggerEvent("keys:addNew", plate)
            break
        end
    end
end)

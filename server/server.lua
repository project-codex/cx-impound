local QBCore = exports['qb-core']:GetCoreObject()

local vehicleEntities = {}

RegisterServerEvent('cx-impound:server:spawnVehicles')
AddEventHandler('cx-impound:server:spawnVehicles', function(pos)
    local vehicles = allVehicles()
    local spawnPos = Config.VehicleSpawns

    if next(vehicleEntities) ~= nil then
        for i = 1, #vehicleEntities do
            local vehEntity = NetworkGetEntityFromNetworkId(vehicleEntities[i])
            if pos ~= i then
                DeleteEntity(vehEntity)
            end
        end
    end

    vehicleEntities = {}

    if next(vehicles) ~= nil then
        for i = 1, #spawnPos do
            if i ~= pos then
                local vehicle = CreateVehicle(vehicles[i].vehicle, spawnPos[i].x, spawnPos[i].y, spawnPos[i].z,
                    spawnPos[i].w, true, true)

                while not DoesEntityExist(vehicle) do
                    Wait(0)
                end

                local net = NetworkGetNetworkIdFromEntity(vehicle)
                vehicleEntities[#vehicleEntities + 1] = net

                TriggerClientEvent('cx-impound:client:setVehProperties', -1, net, vehicles[i])
            end
            if i == #vehicles then
                break
            end
        end
    end
end)

RegisterNetEvent('cx-impound:server:impound')
AddEventHandler('cx-impound:server:impound', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    if player.PlayerData.job.name == "police" then
        TriggerClientEvent('cx-impound:client:checkVehicle', src)
    else
        TriggerClientEvent('DoLongHudText', src, 'For on-duty police only', 2)
    end
end)

RegisterServerEvent('cx-impound:server:checkVehicle')
AddEventHandler('cx-impound:server:checkVehicle', function(vehicle, plate)
    local src = source

    MySQL.Async.fetchAll("SELECT * FROM player_vehicles WHERE plate=?;", {plate}, function(playerVehicle)
        if playerVehicle[1] then
            if not isImpounded(plate) then
                TriggerClientEvent('cx-impound:client:impoundVehicle', src, vehicle.model, vehicle.hash, plate,
                    vehicle.price)
            else
                TriggerClientEvent('DoLongHudText', src, 'Vehicle is already impounded', 2)
            end
        else
            TriggerClientEvent('DoLongHudText', src, 'This vehicle isn\'t registered on any citizen\'s name', 2)
        end
    end)
end)

RegisterServerEvent('cx-impound:server:impoundVehicle')
AddEventHandler('cx-impound:server:impoundVehicle', function(vehicle, hash, plate, depotPrice, impoundTime)
    local src = source
    local vehicleOwner = vehicleOwner(plate)
    local policeOfficer = QBCore.Functions.GetPlayer(src).PlayerData.citizenid

    MySQL.Async.insert(
        'INSERT INTO impounded_vehicles (pd_cid, cid, vehicle, hash, plate, depot_price, impound_time) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {policeOfficer, vehicleOwner.citizenid, vehicle, hash, plate, depotPrice, impoundTime})

    Citizen.Wait(1000)
    TriggerEvent('cx-impound:server:spawnVehicles')
    TriggerClientEvent('DoLongHudText', src, 'Vehicle impounded successfully', 1)

    TriggerEvent('qb-phone:server:sendNewMailToOffline', vehicleOwner.citizenid, {
        sender = "Los Santos Police Department",
        subject = "Vehicle impound",
        message = "Your vehicle just got impounded</br>Vehicle: " .. vehicleFullName(vehicle) .. "</br>Plate: " .. plate ..
            "</br>Impound Cost: " .. depotPrice .. "$</br>Impound Time: " .. impoundTime .. " minutes</br>"
    })
end)

RegisterServerEvent('cx-impound:server:buyoutVehicle')
AddEventHandler('cx-impound:server:buyoutVehicle', function(plate, targetPlayer)
    local src = source
    local vehicle = vehicle(plate)
    local player = QBCore.Functions.GetPlayer(src)
    local targetPlayer = QBCore.Functions.GetPlayer(targetPlayer)

    if vehicle.cid == targetPlayer.PlayerData.citizenid then
        if targetPlayer.PlayerData.money["cash"] >= vehicle.depot_price then
            targetPlayer.Functions.RemoveMoney('cash', vehicle.depot_price)
            if vehicle.impound_time <= 0 then
                removeFromImpound(plate)
                TriggerClientEvent('cx-impound:client:successfulBuyout', src, plate)
                TriggerClientEvent('cx-impound:client:addKeys', targetPlayer.PlayerData.source, plate)

                TriggerEvent('qb-phone:server:sendNewMailToOffline', targetPlayer.PlayerData.citizenid, {
                    sender = "Los Santos Police Department",
                    subject = "Vehicle impound",
                    message = "Dear " .. targetPlayer.PlayerData.charinfo.lastname ..
                        ",<br/><br />Your vehicle just got un-impounded!<br/>Vehicle: " ..
                        vehicleFullName(vehicle.vehicle) .. "<br/>Plate: " .. vehicle.plate ..
                        "<br/>Un-impound cost: <strong>$" .. vehicle.depot_price .. "</strong>!<br/>"
                })

                TriggerClientEvent('DoLongHudText', src, 'Vehicle un-impounded successfully', 1)
            else
                TriggerClientEvent('DoLongHudText', src, 'You are not able to un-impound this vehicle. Time left: ' ..
                    vehicle.impound_time .. ' minutes', 2)
            end
        else
            TriggerClientEvent('DoLongHudText', targetPlayer.PlayerData.source, 'You don\'t have enough cash', 2)
            TriggerClientEvent('DoLongHudText', src, 'This citizen does\'nt have enough cash...', 2)
        end
    else
        TriggerClientEvent('DoLongHudText', src, 'This citizen does\'nt match vehicle owner...', 2)
    end
end)

RegisterServerEvent('cx-impound:server:buyOutData')
AddEventHandler('cx-impound:server:buyOutData', function(plate)
    local src = source
    local vehicle = vehicle(plate)
    local ownerCid = vehicleOwner(plate)
    local officerCid = impoundedBy(vehicle.pd_cid)

    local buyOutPrice = vehicle.depot_price
    local owner = QBCore.Functions.GetPlayerByCitizenId(ownerCid.citizenid)
    local ownerFullName = owner.PlayerData.charinfo.firstname .. " " .. owner.PlayerData.charinfo.lastname
    local officer = QBCore.Functions.GetPlayerByCitizenId(officerCid.citizenid)
    local officerFullName = officer.PlayerData.charinfo.firstname .. " " .. officer.PlayerData.charinfo.lastname
    local vehicleFullName = vehicleFullName(vehicle.vehicle)

    TriggerClientEvent('cx-impound:client:openMenu', src, officerFullName, ownerFullName, vehicleFullName, plate,
        buyOutPrice, vehicle.impound_time)
end)

RegisterServerEvent('cx-impound:server:impoundedVehicles')
AddEventHandler('cx-impound:server:impoundedVehicles', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    local vehicles = citizenImpoundedVehicles(player.PlayerData.citizenid)

    TriggerClientEvent('cx-impound:client:impoundedVehicles', src, vehicles)
end)

function vehicleOwner(plate)
    local citizen = MySQL.Sync.fetchAll("SELECT * FROM player_vehicles WHERE plate=? LIMIT 1;", {plate})

    return citizen[1]
end

function impoundedBy(citizenid)
    local officer = MySQL.Sync.fetchAll("SELECT * FROM players WHERE citizenid=? LIMIT 1;", {citizenid})

    return officer[1]
end

function isImpounded(plate)
    local vehicle = MySQL.Sync.fetchAll("SELECT * FROM impounded_vehicles WHERE plate=? LIMIT 1;", {plate})

    local found

    if vehicle[1] ~= nil then
        found = true
    else
        found = false
    end

    return found
end

function allVehicles()
    local vehicles = MySQL.Sync.fetchAll("SELECT * FROM impounded_vehicles;", {})

    for k, v in pairs(vehicles) do
        vehicles[k].mods = vehicleMods(v.plate)
    end

    return vehicles
end

function vehicle(plate)
    local vehicle = MySQL.Sync.fetchAll("SELECT * FROM impounded_vehicles WHERE plate=? LIMIT 1;", {plate})

    return vehicle[1]
end

function vehicleMods(plate)
    local vehicleMods = MySQL.Sync.fetchAll("SELECT mods FROM player_vehicles WHERE plate=? LIMIT 1;", {plate})

    return json.decode(vehicleMods[1].mods)
end

function removeFromImpound(plate)
    MySQL.Sync.fetchAll("DELETE FROM impounded_vehicles WHERE plate=?;", {plate})
end

function citizenImpoundedVehicles(cid)
    local vehicles = MySQL.Sync.fetchAll("SELECT * FROM impounded_vehicles WHERE cid=?;", {cid})

    return vehicles
end

function vehicleFullName(vehicle)
    return QBCore.Shared.Vehicles[vehicle].name .. " " .. QBCore.Shared.Vehicles[vehicle].brand
end

Citizen.CreateThread(function()
    while true do
        local vehicles = allVehicles()

        for k, v in pairs(vehicles) do
            if v.impound_time > 0 then
                MySQL.Sync.fetchAll("UPDATE impounded_vehicles SET impound_time=impound_time-1 WHERE plate=?;",
                    {v.plate})
            end
        end
        Citizen.Wait(60000)
    end
end)

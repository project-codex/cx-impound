

<div align="center">
    <img src="https://i.ibb.co/pZK668M/banner-1-1.png">
</div>

# A better impound lot for police officers & citizens

# ***STILL IN DEVELOPMENT***

## Dependencies
* [qb-core](https://github.com/qbcore-framework/qb-core)
* [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v2.3.4)
* [qb-vehiclekeys](https://github.com/qbcore-framework/qb-vehiclekeys)
* [qb-target](https://github.com/qbcore-framework/qb-target)
* [qb-menu](https://github.com/qbcore-framework/qb-menu)

## Installation
* Download the ZIP file and extract it in your resources folder
* Run the SQL file
* Add ensure cx-impound to your server.cfg

## QB-Target installation
#### Add vehicle interaction to bones in config
````lua
Config.TargetBones = {
    ["bones"] = {
        bones = {
            "door_dside_f",
            "door_dside_r",
            "door_pside_f",
            "door_pside_r",
            'boot',
            'rudder',
            'rudder2',
            'petrolcap',
            'petroltank',
            'petroltank_l',
            'petroltank_r',
        },
        options = {
            {
                type = "client",
                event = "qb-target:client:vehicleVehicleOptions",
                icon = "fas fa-sign-in-alt",
                label = "Vehicle options",
            },
        }
    },
}
````
#### Add vehicle interactions in config
````lua
Config.VehicleInteractions = {
    {
        requiredJob = "police",
        menu = {
            header = "Unimpound Vehicle",
            txt = "Unimpound the impounded vehicle.",
            params = {
                event = "cx-impound:client:buyOutData"
            }
        }
    },
    {
        requiredJob = "police",
        menu = {
            header = "Impound",
            txt = "Impound vehicle.",
            params = {
                isServer = true,
                event = "cx-impound:server:impound",
            }
        }
    },
}
````
#### Register vehicle options event in qb-target/client/main.lua
````lua
RegisterNetEvent('qb-target:client:vehicleVehicleOptions', function ()
    vehicleOptionsMenu()
end)
````

#### Create vehicle options menu function in qb-target/client/main.lua
````lua
local function vehicleOptionsMenu()

    local playerData = QBCore.Functions.GetPlayerData()
    local vehicleInteractions = {
        {
            header = "Vehicle Options",
            isMenuHeader = true,
            txt = ""
        }
    }

    for k, v in pairs(Config.VehicleInteractions) do
        if v.requiredJob == playerData.job.name or v.requiredJob == 'all' then
			vehicleInteractions[#vehicleInteractions + 1] = v.menu
        end
    end
    exports['qb-menu']:openMenu(vehicleInteractions)
end
````

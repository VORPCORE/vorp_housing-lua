local Lib = Import "blips"
local Blips = Lib.Blips --[[@as MAP]]

local rooms = {}
local houses = {}

local function idNotExists(id, tbl)
    for _, v in ipairs(tbl) do
        if v.id == id then
            return false
        end
    end
    return true
end


local function loadrooms()
    LIB.CORE.RpcCall("Vorp_housing:getrooms", function(result)
        if result == nil then
            if Config.debug then
                print("ROOMS NOT LOADED")
            end
        else
            rooms = result
            if Config.debug then
                print("ROOMS LOADED")
            end
        end
    end, nil)
end

local function loadBlips(house)
    for _, v in ipairs(Config.Houses) do
        local sprite = "blip_ambient_quartermaster"
        for _, vv in ipairs(house) do
            if v.Id == vv.id then
                sprite = "blip_proc_home"
                break
            end
        end
        if not v.BlipHandle then
            local blip = Blips:Create('coords', {
                Pos = vector3(v.text.x, v.text.y, v.text.z),
                Blip = 1664425300,
                Options = {
                    sprite = sprite,
                    name = v.Name,
                },
            })
            v.BlipHandle = blip:GetHandle()
        else
            RemoveBlip(v.BlipHandle)
            local blip = Blips:Create('coords', {
                Pos = vector3(v.text.x, v.text.y, v.text.z),
                Blip = 1664425300,
                Options = {
                    sprite = sprite,
                    name = v.Name,
                },
            })
            v.BlipHandle = blip:GetHandle()
        end
    end
end


local function loadhouses()
    LIB.CORE.RpcCall("Vorp_housing:gethouses", function(result)
        if result == nil then
            if Config.debug then
                print("HOUSES NOT LOADED")
            end
            loadBlips({})
        else
            houses = result
            loadBlips(houses)

            if Config.debug then
                print("HOUSES LOADED")
            end
        end
    end, nil)
end

local function DrawTxt(str, x, y, w, h, enableShadow, col1, col2, col3, a, centre)
    local str = VarString(10, "LITERAL_STRING", str)
    SetTextScale(w, h)
    BgSetTextColor(math.floor(col1), math.floor(col2), math.floor(col3), math.floor(a))
    SetTextCentre(centre)
    if enableShadow then SetTextDropshadow(1, 0, 0, 0, 255) end
    Citizen.InvokeNative(0xADA9255D, 1);
    BgDisplayText(str, x, y)
    if Config.OpenInventoryTextSprite then
        DrawSprite("feeds", "toast_bg", x + 0.0050, y + 0.0170, 0.190, 0.060, 0.1, 20, 20, 20, 200, 0)
    end
end

local function DrawText3Ds(x, y, z, text)
    local _, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(9)
    BgSetTextColor(255, 255, 255, 215)
    local str = VarString(10, 'LITERAL_STRING', text, Citizen.ResultAsLong())
    SetTextCentre(1)
    BgDisplayText(str, _x, _y)
end
-------- Get all rooms and set blip -------------------
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        loadrooms()
        loadhouses()
        Wait(60000 * Config.UpdateTime)
    end
end)

local args = {}
-------- Show Text -------
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        local letSleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, v in ipairs(Config.Rooms) do
            local distance = #(playerCoords - v.text)
            local idistance = #(playerCoords - v.Inventory)

            if idistance < 2 then
                letSleep = 0
                DrawTxt(_U("openinventory"), 0.50, 0.90, Config.OpenInventoryTextSize, Config.OpenInventoryTextSize, true,
                    255, 255, 255, 255, true)
                if IsControlJustPressed(0, Config.BuyHouseKey) then
                    TriggerServerEvent("Vorp_housing:GetInventoryRooms", v.Id)
                end
            end

            if distance < 2 then
                letSleep = 0
                local message = ""
                local canbuy2 = false
                if idNotExists(v.Id, rooms) then
                    message = _U("buy") .. v.Price .. "$\n" .. _U("pressenterroom")
                    args = v
                    canbuy2 = true
                end

                DrawText3Ds(v.text.x, v.text.y, v.text.z, message)
                if IsControlJustPressed(0, Config.BuyHouseKey) and canbuy2 then
                    LIB.CORE.RpcCall("Vorp_housing:buyrooms", function(result)
                        if result == 1 then
                            LIB.NOTIFY:RightTip(_U("boughtroom"), 4000)
                            loadrooms()
                        elseif result == 2 then
                            LIB.NOTIFY:RightTip(_U("notsellable"), 4000)
                            loadrooms()
                        elseif result == 3 then
                            LIB.NOTIFY:RightTip(_U("nomoney"), 4000)
                        end
                    end, args)
                end
            end
        end



        for _, v in ipairs(Config.Houses) do
            local distance2 = #(playerCoords - v.text)
            local idistance2 = #(playerCoords - v.Inventory)

            if idistance2 < 2.0 then
                letSleep = 0
                DrawTxt(_U("openinventory"), 0.50, 0.90, Config.OpenInventoryTextSize, Config.OpenInventoryTextSize, true,
                    255, 255, 255, 255, true)
                if IsControlJustPressed(0, Config.BuyHouseKey) then
                    TriggerServerEvent("Vorp_housing:GetInventoryHouses", v.Id)
                end
            end

            if distance2 < 2 then
                letSleep = 0
                local message = ""
                local canbuy = false
                if idNotExists(v.Id, houses) then
                    message = _U("buy") .. v.Price .. "$\n" .. _U("pressenterhouse")
                    args = v
                    canbuy = true
                end
                DrawText3Ds(v.text.x, v.text.y, v.text.z, message)
                if IsControlJustPressed(0, Config.BuyHouseKey) and canbuy then
                    LIB.CORE.RpcCall("Vorp_housing:buyhouse", function(result)
                        if result == 1 then
                            LIB.NOTIFY:RightTip(_U("boughthouse"), 4000)
                            loadhouses()
                        elseif result == 2 then
                            LIB.NOTIFY:RightTip(_U("notsellable"), 4000)
                            loadhouses()
                        elseif result == 3 then
                            LIB.NOTIFY:RightTip(_U("nomoney"), 4000)
                        end
                    end, args)
                end
            end
        end

        Wait(letSleep)
    end
end)

RegisterNetEvent("vorp:SelectedCharacter", function(charid)
    loadrooms()
    loadhouses()
    TriggerServerEvent('Vorp_housing:Load')
end)


-------------------- Refresh client side ---------------
RegisterNetEvent("vorp_housing:refreshall", function()
    loadrooms()
    loadhouses()
    TriggerServerEvent('Vorp_housing:Load')
end)

--------------- Command give near house key --------------
RegisterCommand(Config.MyKey, function()
    local playerCoords = GetEntityCoords(PlayerPedId())

    for _, v in ipairs(Config.Rooms) do
        local distance = #(playerCoords - v.text)
        if distance < 2 then
            TriggerServerEvent("Vorp_housing:givekeys", v.Id)
        end
    end
    for _, v in ipairs(Config.Houses) do
        local distance2 = #(playerCoords - v.text)
        if distance2 < 2 then
            TriggerServerEvent("Vorp_housing:givekeys", v.Id)
        end
    end
end, false)

--------------- Command sell near house --------------
RegisterCommand(Config.SellHouse, function()
    local playerCoords = GetEntityCoords(PlayerPedId())

    for _, v in ipairs(Config.Rooms) do
        local distance = #(playerCoords - v.text)
        if distance < 2 then
            TriggerServerEvent("Vorp_housing:sellhouse", v.Id)
        end
    end
    for _, v in ipairs(Config.Houses) do
        local distance2 = #(playerCoords - v.text)
        if distance2 < 2 then
            TriggerServerEvent("Vorp_housing:sellhouse", v.Id)
        end
    end
end, false)
-------------------------------------- Doors ------------------------------------

----------------- Houses --------------
CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        local sleep = 800
        local playerCoords = GetEntityCoords(PlayerPedId())
        for k, v in ipairs(Config.Houses) do
            for k2, doorID in ipairs(v.Doors) do
                local distance = #(playerCoords - doorID.objCoords)

                if distance < 10 then
                    sleep = 0
                    if doorID.locked then
                        if DoorSystemGetOpenRatio(doorID.object) ~= 0.0 then
                            DoorSystemSetOpenRatio(doorID.object, 0.0, true)
                            local object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object, 0)
                            SetEntityRotation(object, 0.0, 0.0, doorID.objYaw, 2, true)
                            if doorID.object2 ~= nil then
                                DoorSystemSetOpenRatio(doorID.object2, 0.0, true)
                                object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object2, 0)
                                SetEntityRotation(object, 0.0, 0.0, doorID.objYaw2, 2, true)
                            end
                        end
                        if DoorSystemGetDoorState(doorID.object) ~= 1 then
                            CreateThread(function()
                                Citizen.InvokeNative(0xD99229FE93B46286, doorID.object, 1, 1, 0, 0, 0, 0)
                            end)
                            local object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object, 0)
                            Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object, doorID.locked)
                            SetEntityRotation(object, 0.0, 0.0, doorID.objYaw, 2, true)
                            if doorID.object2 ~= nil then
                                CreateThread(function()
                                    Citizen.InvokeNative(0xD99229FE93B46286, doorID.object2, 1, 1, 0, 0, 0, 0)
                                end)
                                object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object2, 0)
                                Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object2, doorID.locked)
                                SetEntityRotation(object, 0.0, 0.0, doorID.objYaw2, 2, true)
                            end
                        end
                    else
                        if DoorSystemGetDoorState(doorID.object) ~= 0 then
                            CreateThread(function()
                                Citizen.InvokeNative(0xD99229FE93B46286, doorID.object, 1, 1, 0, 0, 0, 0)
                            end)
                            Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object, doorID.locked)
                            if doorID.object2 ~= nil then
                                CreateThread(function()
                                    Citizen.InvokeNative(0xD99229FE93B46286, doorID.object2, 1, 1, 0, 0, 0, 0)
                                end)
                                Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object2, doorID.locked)
                            end
                        end
                    end
                end

                if distance < 2.0 then
                    sleep = 0
                    DrawText3D(doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z + 0.2, _U("opendoor"),
                        doorID.locked)

                    if IsControlJustPressed(2, Config.OpenDoorKey) then
                        LIB.CORE.RpcCall("Vorp_housing:checkkey", function(result)
                            if result then
                                TriggerEvent("Vorp_housing:changedoorhouse", k, k2)
                            else
                                TriggerEvent("vorp:TipBottom", _U("havekey"), 2000)
                            end
                        end, v.key)
                        OpenDoors(PlayerPedId(), doorID.objCoords)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)


----------------------- Rooms ----------------------

CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        local sleep = 800
        local playerCoords = GetEntityCoords(PlayerPedId())
        for k, v in ipairs(Config.Rooms) do
            for k2, doorID in ipairs(v.Doors) do
                local distance = #(playerCoords - doorID.objCoords)


                if distance < 10 then
                    sleep = 0
                    if doorID.locked then
                        if DoorSystemGetOpenRatio(doorID.object) ~= 0.0 then
                            DoorSystemSetOpenRatio(doorID.object, 0.0, true)
                            local object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object, 0)
                            SetEntityRotation(object, 0.0, 0.0, doorID.objYaw, 2, true)
                            if doorID.object2 ~= nil then
                                DoorSystemSetOpenRatio(doorID.object2, 0.0, true)
                                object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object2, 0)
                                SetEntityRotation(object, 0.0, 0.0, doorID.objYaw2, 2, true)
                            end
                        end
                        if DoorSystemGetDoorState(doorID.object) ~= 1 then
                            CreateThread(function()
                                Citizen.InvokeNative(0xD99229FE93B46286, doorID.object, 1, 1, 0, 0, 0, 0)
                            end)
                            local object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object, 0)
                            Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object, doorID.locked)
                            SetEntityRotation(object, 0.0, 0.0, doorID.objYaw, 2, true)
                            if doorID.object2 ~= nil then
                                CreateThread(function()
                                    Citizen.InvokeNative(0xD99229FE93B46286, doorID.object2, 1, 1, 0, 0, 0, 0)
                                end)
                                object = Citizen.InvokeNative(0xF7424890E4A094C0, doorID.object2, 0)
                                Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object2, doorID.locked)
                                SetEntityRotation(object, 0.0, 0.0, doorID.objYaw2, 2, true)
                            end
                        end
                    else
                        if DoorSystemGetDoorState(doorID.object) ~= 0 then
                            CreateThread(function()
                                Citizen.InvokeNative(0xD99229FE93B46286, doorID.object, 1, 1, 0, 0, 0, 0)
                            end)
                            Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object, doorID.locked)
                            if doorID.object2 ~= nil then
                                CreateThread(function()
                                    Citizen.InvokeNative(0xD99229FE93B46286, doorID.object2, 1, 1, 0, 0, 0, 0)
                                end)
                                Citizen.InvokeNative(0x6BAB9442830C7F53, doorID.object2, doorID.locked)
                            end
                        end
                    end
                end

                if distance < 2.0 then
                    sleep = 0
                    DrawText3D(doorID.objCoords.x, doorID.objCoords.y, doorID.objCoords.z + 0.2, "press alt to open door",
                        doorID.locked)
                    if IsControlJustPressed(2, 0xE8342FF2) then -- Hold ALT
                        LIB.CORE.RpcCall("Vorp_housing:checkkey", function(result)
                            if result then
                                TriggerEvent("Vorp_housing:changedoorroom", k, k2)
                                OpenDoors(PlayerPedId(), doorID.objCoords)
                            else
                                TriggerEvent("vorp:TipBottom", _U("havekey"), 2000)
                            end
                        end, v.key)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    repeat Wait(5000) until LocalPlayer.state.IsInSession
    while true do
        local sleep = 800
        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, v in ipairs(Config.Rooms) do
            for _, doorID in ipairs(v.Doors) do
                local distance = #(playerCoords - doorID.objCoords)

                if distance < 2.0 then
                    sleep = 0
                    TriggerServerEvent("Vorp_housing:Load")
                    Wait(10000)
                end
            end
        end

        for _, v in ipairs(Config.Houses) do
            for _, doorID in ipairs(v.Doors) do
                local distance = #(playerCoords - doorID.objCoords)
                if distance < 2.0 then
                    sleep = 0
                    TriggerServerEvent("Vorp_housing:Load")
                    Wait(10000)
                end
            end
        end

        Wait(sleep)
    end
end)

function DrawText3D(x, y, z, text, state)
    local ismapact = IsUiappActiveByHash(`MAP`)
    if ismapact == 0 then
        local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        BgSetTextColor(255, 255, 255, 215)
        local str = VarString(10, "LITERAL_STRING", text)
        SetTextCentre(1)
        BgDisplayText(str, _x, _y)
        if state then
            DrawSprite("generic_textures", "lock", _x, _y + 0.0125, 0.04, 0.045, 0.1, 255, 0, 0, 255, false)
        else
            DrawSprite("inventory_items", "consumable_lock_breaker", _x, _y + 0.0125, 0.04, 0.05, 0.1, 1, 255, 1, 255,
                false)
        end
    end
end

function OpenDoors(entity1, coords)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = coords
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
    Wait(100)
    ClearPedTasks(entity1)
    local prop_name = 'P_KEY02X'
    local ped = entity1
    local x, y, z = table.unpack(GetEntityCoords(ped, true))


    local prop = CreateObject(GetHashKey(prop_name), x, y, z + 0.2, true, true, true)
    local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_Finger12")
    local key = false
    if not IsEntityPlayingAnim(ped, "script_common@jail_cell@unlock@key", "action", 3) then
        local waiting = 0
        RequestAnimDict("script_common@jail_cell@unlock@key")
        while not HasAnimDictLoaded("script_common@jail_cell@unlock@key") do
            waiting = waiting + 100
            Wait(100)
            if waiting > 5000 then
                break
            end
        end
        Wait(100)
        TaskPlayAnim(ped, 'script_common@jail_cell@unlock@key', 'action', 8.0, -8.0, 2500, 31, 0, true, 0, false, "",
            false)
        Wait(750)
        AttachEntityToEntity(prop, ped, boneIndex, 0.02, 0.0120, -0.00850, 0.024, -160.0, 200.0, true, true, false, true,
            1, true, false, false)
        key = true

        while key do
            if IsEntityPlayingAnim(ped, "script_common@jail_cell@unlock@key", "action", 3) then
                Wait(100)
            else
                ClearPedSecondaryTask(ped)
                DeleteObject(prop)
                RemoveAnimDict("script_common@jail_cell@unlock@key")
                key = false

                break
            end
        end
    end
end

RegisterNetEvent('Vorp_housing:changedoorhouse', function(k, k2)
    local name = Config.Houses[k].Doors[k2]
    name.locked = not name.locked
    TriggerServerEvent('Vorp_housing:updateStatehouse', k, k2, name.locked)
end)

RegisterNetEvent('Vorp_housing:changedoorroom', function(k, k2)
    local name = Config.Rooms[k].Doors[k2]
    name.locked = not name.locked
    TriggerServerEvent('Vorp_housing:updateStateroom', k, k2, name.locked)
end)

RegisterNetEvent('Vorp_housing:setStateHouse', function(k, k2, state)
    Config.Houses[k].Doors[k2].locked = state
end)

RegisterNetEvent('Vorp_housing:setStateRoom', function(k, k2, state)
    Config.Rooms[k].Doors[k2].locked = state
end)

RegisterNetEvent('Vorp_housing:setStateHouse2', function(Doorinfo)
    for k, v in ipairs(Doorinfo) do
        for kk, vv in ipairs(v.Doors) do
            Config.Houses[k].Doors[kk].locked = vv.locked
        end
    end
end)

RegisterNetEvent('Vorp_housing:setStateRoom2', function(Doorinfo)
    for k, v in ipairs(Doorinfo) do
        for kk, vv in ipairs(v.Doors) do
            Config.Rooms[k].Doors[kk].locked = vv.locked
        end
    end
end)

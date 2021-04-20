ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(10)
	end

	ScriptLoaded()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

function ScriptLoaded()
	Citizen.Wait(1000)
	LoadMarkers()
end

local AnimalPositions = {
	{ x = -1505.2, y = 4887.39, z = 78.38 },
	{ x = -1164.68, y = 4806.76, z = 223.11 },
	{ x = -1410.63, y = 4730.94, z = 44.0369 },
	{ x = -1377.29, y = 4864.31, z = 134.162 },
	{ x = -1697.63, y = 4652.71, z = 22.2442 },
	{ x = -1259.99, y = 5002.75, z = 151.36 },
	{ x = -960.91, y = 5001.16, z = 183.0 },
}

local AnimalsInSession = {}

local OnGoingHuntSession = false

function LoadMarkers()
	LoadModel('a_c_deer')
	LoadAnimDict('amb@medic@standing@kneel@base')
	LoadAnimDict('anim@gangops@facility@servers@bodysearch@')
end

RegisterCommand('avcılıkstart', function()
	ESX.TriggerServerCallback('efe-hunting:checkMeat', function(quantity)
		if quantity > 0 then
			if not OnGoingHuntSession then
				StartHuntingSession()
				TriggerEvent('mythic_notify:client:SendAlert', { type = 'inform', text = 'Avcılık başlatıldı, avlar haritada berilecek.'})
			else
				for index, value in ipairs(AnimalsInSession) do
					if not DoesEntityExist(value.id) then
						OnGoingHuntSession = false
						StartHuntingSession()
						TriggerEvent('mythic_notify:client:SendAlert', { type = 'inform', text = 'Avcılık başlatıldı, avlar haritada berilecek.'})
					else
						TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'Zaten avdasın.'})
					end
				end
			end
		else
			TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'Avcılık kartına sahip değilsin.'})
		end
	end, 'avciliklisans')
end)

function StartHuntingSession()
	LoadModel('a_c_deer')
	LoadAnimDict('amb@medic@standing@kneel@base')
	LoadAnimDict('anim@gangops@facility@servers@bodysearch@')
	OnGoingHuntSession = true

	Citizen.CreateThread(function()
				
		for index, value in pairs(AnimalPositions) do
			local Animal = CreatePed(5, GetHashKey('a_c_deer'), value.x, value.y, value.z, 0.0, true, false)
			TaskWanderStandard(Animal, true, true)
			SetEntityAsMissionEntity(Animal, true, true)

			local AnimalBlip = AddBlipForEntity(Animal)
			SetBlipSprite(AnimalBlip, 153)
			SetBlipColour(AnimalBlip, 1)
			SetBlipScale(AnimalBlip, 0.6)
			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString('Av')
			EndTextCommandSetBlipName(AnimalBlip)


			table.insert(AnimalsInSession, {id = Animal, x = value.x, y = value.y, z = value.z, Blipid = AnimalBlip})
		end

		while OnGoingHuntSession do
			local sleep = 500
			for index, value in ipairs(AnimalsInSession) do
				if DoesEntityExist(value.id) then
					local AnimalCoords = GetEntityCoords(value.id)
					local PlyCoords = GetEntityCoords(PlayerPedId())
					local AnimalHealth = GetEntityHealth(value.id)
					local PlyToAnimal = GetDistanceBetweenCoords(PlyCoords, AnimalCoords, true)

					if AnimalHealth <= 0 then
						SetBlipColour(value.Blipid, 3)
						if PlyToAnimal < 2.0 then
							sleep = 5

							DrawText3D(AnimalCoords.x,AnimalCoords.y, AnimalCoords.z + 1, '[E] - Etleri Topla')

							if IsControlJustReleased(0, 38) then
								if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey('WEAPON_KNIFE')  then
									if DoesEntityExist(value.id) then
										table.remove(AnimalsInSession, index)
										SlaughterAnimal(value.id)
									end
								else
									TriggerEvent('mythic_notify:client:SendAlert', { type = 'error', text = 'Elinde bıçak olmalı.'})
								end
							end
						end
					end
				end
			end
			Citizen.Wait(sleep)
		end		
	end)
end

function SlaughterAnimal(AnimalId)

	TaskPlayAnim(PlayerPedId(), "amb@medic@standing@kneel@base" ,"base" ,8.0, -8.0, -1, 1, 0, false, false, false )
	TaskPlayAnim(PlayerPedId(), "anim@gangops@facility@servers@bodysearch@" ,"player_search" ,8.0, -8.0, -1, 48, 0, false, false, false )

	exports["np-taskbar"]:taskBar(5000,"Etleri Topluyorsun..")
	Citizen.Wait(2000)

	ClearPedTasksImmediately(PlayerPedId())

	local AnimalWeight = math.random(10, 160) / 10

	TriggerServerEvent('efe-hunting:reward', AnimalWeight)

	DeleteEntity(AnimalId)
end


function LoadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(10)
    end    
end

function LoadModel(model)
    while not HasModelLoaded(model) do
          RequestModel(model)
          Citizen.Wait(10)
    end
end

function DrawText3D(x, y, z, text)
	local onScreen, _x, _y = World3dToScreen2d(x,y,z)
	if onScreen then
		local factor = #text / 350
		SetTextScale(0.30, 0.30)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 215)
		SetTextEntry('STRING')
		SetTextCentre(1)
		AddTextComponentString(text)
		DrawText(_x, _y)
		DrawRect(_x, _y + 0.0120, 0.006 + factor, 0.024, 0, 0, 0, 155)
	end
end
local targetPed;
local useLocalPed = true;
local isRunning = false;
local scriptVersion = "1.5.6";
local animStates = {};
local displayingPluginScreen = false;
local radioVolume = 0;
local nuiLoaded = false;


voipCore = nil;




local function clientProcessing()
	local playerList = voipCore.playerList;
	local usersdata = {};
	local localHeading;

	if voipCore.headingType == 1 then
			localHeading = math.rad(getElementRotation(localPlayer).z)
	else
			localHeading = math.rad(Vector3(getElementRotation(getCamera())).z % 360)
	end
	
	local localPos
	if useLocalPed then
			localPos = Vector3(getPedBonePosition(localPlayer, 8))
	else
			localPos = Vector3(getPedBonePosition(localPlayer, 8))
	end
	
	local usersdata = {}
	
	for _, player in ipairs(getElementsByType("player")) do
			local playerTalking = getElementData(player, "voip:talking")
			
			if voipCore.serverId ~= player and playerTalking ~= 0 then
					local playerPos = Vector3(getPedBonePosition(player, 8))
					local dist = math.floor(getDistanceBetweenPoints3D(localPos.x, localPos.y, localPos.z, playerPos.x, playerPos.y, playerPos.z))
					
					if dist <= voipCore.distance[3] then
							local mode = tonumber(getElementData(player, "voip:mode")) or 1
							local volume = -30 + (30 - dist / voipCore.distance[mode] * 30)
							
							if volume >= 0 then
									volume = 0
							end
							
							local angleToTarget = localHeading - math.atan2(playerPos.y - localPos.y, playerPos.x - localPos.x)
							
							local userData = {
									uuid = getElementData(player, "voip:pluginUUID"),
									volume = volume,
									muted = 1,
									radioEffect = false,
									posX = voipCore.plugin_data.enableStereoAudio and math.cos(angleToTarget) * dist or 0,
									posY = voipCore.plugin_data.enableStereoAudio and math.sin(angleToTarget) * dist or 0,
									posZ = voipCore.plugin_data.enableStereoAudio and playerPos.z or 0
							}
							
							if dist < voipCore.distance[mode] then
									userData.muted = 0
									userData.volume = volume
							end
							
							table.insert(usersdata, userData)
					end
			end
	end

	for _, channel in pairs(voipCore.myChannels) do
			for _, subscriber in pairs(channel.subscribers) do
					if (subscriber == voipCore.serverId) then
							-- Skip to the next iteration of the loop
					else
							local remotePlayerUsingRadio = getElementData(subscriber, "radio:talking");
							local remotePlayerChannel = getElementData(subscriber, "radio:channel");

							if (remotePlayerUsingRadio and remotePlayerChannel == channel.id) then
									local remotePlayerUuid = getElementData(subscriber, "voip:pluginUUID");

									local userData = {
											uuid = remotePlayerUuid,
											radioEffect = false,
											muted = false,
											volume = radioVolume,
											posX = 0,
											posY = 0,
											posZ = voipCore.plugin_data.enableStereoAudio and localPos.z or 0
									};

									if ((type(remotePlayerChannel) == "number" and remotePlayerChannel <= voipCore.config.radioClickMaxChannel) or channel.radio) then
											userData.radioEffect = true;
									end

									local found = false;
									for k, v in pairs(usersdata) do
											if (v.uuid == remotePlayerUuid) then
													usersdata[k] = userData;
													found = true;
													break;
											end
									end

									if not found then
											usersdata[#usersdata + 1] = userData;
									end
							end
					end
			end
	end

	voipCore.plugin_data.Users = usersdata; -- Update TokoVoip's data
	voipCore.plugin_data.posX = 0;
	voipCore.plugin_data.posY = 0;
	voipCore.plugin_data.posZ = voipCore.plugin_data.enableStereoAudio and localPos.z or 0;
end



addEventHandler("onClientResourceStart", resourceRoot, function () 
  voipCore = voip:create(VoiceSettings); 

  voipCore.plugin_data.Users = {};
	voipCore.plugin_data.radioTalking = false;
	voipCore.plugin_data.radioChannel = -1;
	voipCore.plugin_data.localRadioClicks = false;
	voipCore.mode = 1;
	voipCore.talking = false;
	voipCore.pluginStatus = -1;
	voipCore.pluginVersion = "0";
	voipCore.serverId = localPlayer;

  -- Radio channels
	voipCore.myChannels = {};

	-- Player data shared on the network
	setElementData(voipCore.serverId, "voip:mode", voipCore.mode, true);
	setElementData(voipCore.serverId, "voip:talking", voipCore.talking, true);
	setElementData(voipCore.serverId, "radio:channel", voipCore.plugin_data.radioChannel, true);
	setElementData(voipCore.serverId, "radio:talking", voipCore.plugin_data.radioTalking, true);
	setElementData(voipCore.serverId, "voip:pluginStatus", voipCore.pluginStatus, true);
	setElementData(voipCore.serverId, "voip:pluginVersion", voipCore.pluginVersion, true);


	
  voipCore:initialize();
	
	setTimer(function () 
		voipCore.processFunction = clientProcessing;
		voipCore:loop();
	end, 250, 0)
end)
local channels = VoiceSettings.channels;
local serverId = "rocketmta"


function addPlayerToRadio(channelId, player, radio)
	if (not channels[channelId]) then
		if(radio) then
			channels[channelId] = {id = channelId, name = channelId .. " Mhz", subscribers = {}};
		else
			channels[channelId] = {id = channelId, name = "Call with " .. channelId, subscribers = {}};
		end
	end
	if (not channels[channelId].id) then
		channels[channelId].id = channelId;
	end

	channels[channelId].subscribers[player] = player;
	iprint("Added [" .. getPlayerName(player) .. "] " .. (getPlayerName(player) or "") .. " to channel " .. channelId);

	for _, subscriberServerId in pairs(channels[channelId].subscribers) do
		if (subscriberServerId ~= player) then
			network:emit("pw_voice:onPlayerJoinChannel", true, false, subscriberServerId, channelId, player);
		else
			-- Send whole channel data to new subscriber
			network:emit("pw_voice:onPlayerJoinChannel", true, false, subscriberServerId, channelId, player, channels[channelId]);
		end
	end
end


function removePlayerFromRadio(channelId, player)
	if (channels[channelId] and channels[channelId].subscribers[player]) then
		channels[channelId].subscribers[player] = nil;
		if (channelId > 100) then
			if (tablelength(channels[channelId].subscribers) == 0) then
				channels[channelId] = nil;
			end
		end
		print("Removed [" .. player .. "] " .. (getPlayerName(player) or "") .. " from channel " .. channelId);

		-- Tell unsubscribed player he's left the channel as well
		network:emit("TokoVoip:onPlayerLeaveChannel", true, false, player, channelId, player);

		-- Channel does not exist, no need to update anyone else
		if (not channels[channelId]) then return end

		for _, subscriberServerId in pairs(channels[channelId].subscribers) do
			network:emit("TokoVoip:onPlayerLeaveChannel", true, false, subscriberServerId, channelId, player);
		end
	end
end


function removePlayerFromAllRadio(player)
	for channelId, channel in pairs(channels) do
		if (channel.subscribers[player]) then
			removePlayerFromRadio(channelId, player);
		end
	end
end
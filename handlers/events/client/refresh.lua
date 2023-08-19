network:fetch("pw_voice:onPlayerJoinChannel", true):on(addPlayerToRadio);
network:fetch("pw_voice:onPlayerLeaveChannel", true):on(removePlayerFromRadio);
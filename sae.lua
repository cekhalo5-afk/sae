--[[
    Noa Hub v2.0 | Steal An Egg
    PlaceId : 10563114921
    Executor : Solara / KRNL+
]]

-- ── GUARD ─────────────────────────────────────────────────────────────────
-- Accept PlaceId 10563114921 (root place) OR game universeId check
local VALID_PLACE_IDS = { [10563114921]=true }
if not VALID_PLACE_IDS[game.PlaceId] then
    -- Try universe ID fallback
    local uid = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    -- Soft warn, don't hard stop in case of sub-places
    warn("[Noa Hub] PlaceId "..game.PlaceId.." mungkin bukan Steal An Egg utama. Lanjut...")
end

-- ── SERVICES ──────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")

-- ── PLAYER REFS ───────────────────────────────────────────────────────────
local lp  = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")
local function getChar() return lp.Character end
local function getHum()  local c=getChar() return c and c:FindFirstChild("Humanoid") end
local function getHRP()  local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ── CONFIG ────────────────────────────────────────────────────────────────
local CFG = {
    -- Main
    WalkSpeed      = 200,
    JumpPower      = 50,
    Noclip         = false,
    InfJump        = false,
    AntiSlip       = false,
    AutoTreadmill  = false,
    TreadmillDur   = 3.0,
    -- Auto
    StealSpeed     = 200,
    StealDelay     = 0.5,
    MoveStyle      = "Zigzag",
    AutoSteal      = false,
    AutoDrop       = false,
    AutoTreadmill2 = false,
    EggChecker     = false,
    EggPredictor   = false,
    -- ESP
    EspEgg         = false,
    EspGuardian    = false,
    EspPlayer      = false,
    BoxEsp         = false,
    NameTagEsp     = true,
    DistanceEsp    = true,
    EspRange       = 300,
    -- Forest Biome
    ForestBiome    = "Forest",
    DropStyle      = "Single",
    DropDelay      = 1.5,
    SafeDrop       = true,
    AutoTPForest   = true,
    LoopDrop       = false,
    NotifDrop      = true,
    RarityFilter   = { Common=true, Rare=true, Epic=true, Legendary=true, Divine=false, Eternal=false },
    -- Forest Drop inline
    CloneSpeed     = 500,
    CharFreeze     = true,
    CloneNoclip    = true,
    GuardianCheck  = true,
    -- Misc
    AntiGuardian   = false,
    KillGuardian   = false,
    GuardianAlert  = true,
    GuardianAlertR = 50,
    AntiAFK        = true,
    FlyMode        = false,
    GhostMode      = false,
    SpeedBurst     = false,
    -- PVP
    PVP = {
        Auto         = false,
        AttackMode   = "Club",
        RunAfter     = true,
        PriorityHigh = true,
        AntiReturn   = false,
        ScanRadius   = 80,
        Cooldown     = 3.0,
        Stolen       = 0,
        Attempts     = 0,
        Filter       = { Common=true, Rare=true, Epic=true, Legendary=true, Divine=true, Eternal=true },
    },
}

-- ── CONFIG SAVE / LOAD ────────────────────────────────────────────────────
local CONFIG_FILE = "NoaHub_SAE.json"
local function saveConfig()
    if writefile then
        pcall(writefile, CONFIG_FILE, HttpService:JSONEncode(CFG))
    end
end
local function loadConfig()
    if readfile and isfile and isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then
            for k,v in pairs(data) do if CFG[k] ~= nil then CFG[k]=v end end
        end
    end
end
loadConfig()

-- ── NOTIFY ────────────────────────────────────────────────────────────────
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title=title or "Noa Hub", Text=text or "", Duration=dur or 3 })
    end)
end

-- ── AUTO-DETECT POSITIONS ─────────────────────────────────────────────────
local _detectedShop = nil
local _detectedBiome = {}

local function detectShopPos()
    if _detectedShop then return _detectedShop end
    local keywords = {"shop","store","nestshop","safezon","spawn","base","treadmill","seller","sell"}
    -- Priority: SpawnLocation first
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            _detectedShop = obj.Position + Vector3.new(0,3,0)
            print("[Noa Hub] Shop auto-detected (SpawnLocation):", tostring(_detectedShop))
            return _detectedShop
        end
    end
    -- Then named parts/models
    for _,obj in ipairs(workspace:GetDescendants()) do
        local n = obj.Name:lower()
        for _,kw in ipairs(keywords) do
            if n:find(kw) then
                local pos
                if obj:IsA("BasePart") then pos = obj.Position
                elseif obj:IsA("Model") then
                    local cf = obj:FindFirstChildWhichIsA("BasePart")
                    if cf then pos = cf.Position end
                end
                if pos then
                    _detectedShop = pos + Vector3.new(0,3,0)
                    print("[Noa Hub] Shop auto-detected ("..obj.Name.."):", tostring(_detectedShop))
                    return _detectedShop
                end
            end
        end
    end
    -- Fallback to player spawn
    local hrp = getHRP()
    _detectedShop = hrp and hrp.Position or Vector3.new(0,5,0)
    warn("[Noa Hub] Shop tidak ditemukan, pakai posisi player.")
    return _detectedShop
end

local function detectBiomePos(biome)
    if _detectedBiome[biome] then return _detectedBiome[biome] end
    local keywords = {
        Forest   = {"forest","jungle","tree","wood","leaf","biome.*forest","forest.*biome"},
        Plains   = {"plain","grass","meadow","field","open","biome.*plain","plain.*biome"},
        Mountain = {"mountain","hill","cliff","peak","snow","ice","biome.*mount","mount.*biome"},
    }
    local kws = keywords[biome] or {}
    -- Search Folder first (biome folders common in Roblox games)
    for _,obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            local n = obj.Name:lower()
            for _,kw in ipairs(kws) do
                if n:find(kw) then
                    local cf = obj:FindFirstChildWhichIsA("BasePart")
                    if cf then
                        _detectedBiome[biome] = cf.Position + Vector3.new(0,5,0)
                        print("[Noa Hub] Biome "..biome.." detected ("..obj.Name.."):", tostring(_detectedBiome[biome]))
                        return _detectedBiome[biome]
                    end
                end
            end
        end
    end
    -- Deep scan BaseParts
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            for _,kw in ipairs(kws) do
                if n:find(kw) then
                    _detectedBiome[biome] = obj.Position + Vector3.new(0,5,0)
                    print("[Noa Hub] Biome "..biome.." detected ("..obj.Name.."):", tostring(_detectedBiome[biome]))
                    return _detectedBiome[biome]
                end
            end
        end
    end
    -- Fallbacks
    local fallbacks = { Forest=Vector3.new(-200,5,100), Plains=Vector3.new(50,5,300), Mountain=Vector3.new(-400,80,-150) }
    _detectedBiome[biome] = fallbacks[biome]
    warn("[Noa Hub] Biome "..biome.." tidak ditemukan, pakai fallback.")
    return _detectedBiome[biome]
end

-- Lazy wrappers used throughout script
local function SHOP_POS() return detectShopPos() end
local function BIOME_POS(b) return detectBiomePos(b) end

-- ── UTILITY ───────────────────────────────────────────────────────────────
local function teleportTo(pos)
    local hrp = getHRP()
    if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
end

local freezeBP = nil
local function freezeChar()
    local hrp = getHRP() if not hrp then return end
    freezeBP = Instance.new("BodyPosition")
    freezeBP.Position = hrp.Position
    freezeBP.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
    freezeBP.P = 50000
    freezeBP.Parent = hrp
end
local function unfreezeChar()
    if freezeBP then freezeBP:Destroy() freezeBP = nil end
end

-- ── RARITY ────────────────────────────────────────────────────────────────
local RARITY_ORDER  = { Eternal=6, Divine=5, Legendary=4, Epic=3, Rare=2, Common=1 }
local RARITY_COLORS = {
    Common    = Color3.fromRGB(200,200,220),
    Rare      = Color3.fromRGB(80,130,255),
    Epic      = Color3.fromRGB(180,80,255),
    Legendary = Color3.fromRGB(255,165,40),
    Divine    = Color3.fromRGB(220,100,255),
    Eternal   = Color3.fromRGB(255,215,80),
}
local function getEggRarity(name)
    for r in pairs(RARITY_ORDER) do if name:find(r) then return r end end
    return "Common"
end

-- ── EGG FINDER ────────────────────────────────────────────────────────────
local function findBestEgg()
    local best, bestScore, bestPos = nil, -1, nil
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
            local r = getEggRarity(obj.Name)
            if CFG.EggPredictor and r ~= "Divine" and r ~= "Eternal" then continue end
            if CFG.EggChecker and CFG.RarityFilter[r] == false then continue end
            local s = RARITY_ORDER[r] or 1
            if s > bestScore then best=obj bestScore=s bestPos=obj.Position end
        end
    end
    return best, bestPos
end

-- ── GUARDIAN ─────────────────────────────────────────────────────────────
local function findGuardians()
    local t = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find("guardian") then t[#t+1]=obj end
    end
    return t
end
local function nearestGuardDist()
    local hrp = getHRP() if not hrp then return math.huge end
    local min = math.huge
    for _,g in ipairs(findGuardians()) do
        local r = g:FindFirstChild("HumanoidRootPart") or g:FindFirstChildWhichIsA("BasePart")
        if r then local d=(r.Position-hrp.Position).Magnitude if d<min then min=d end end
    end
    return min
end
local function isGuardianNear(r) return nearestGuardDist() < (r or 30) end

-- ── TOOLS ─────────────────────────────────────────────────────────────────
-- Auto-detect tools by scanning all tools and scoring relevance
local function findTool(keywords, scoreMode)
    local best, bestScore = nil, -1
    for _,c in ipairs({lp:FindFirstChild("Backpack"), getChar()}) do
        if c then
            for _,t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    local score = 0
                    for i,kw in ipairs(keywords) do
                        if n:find(kw) then
                            -- Earlier in keyword list = higher priority
                            score = score + (#keywords - i + 1)
                        end
                    end
                    if score > bestScore then best=t bestScore=score end
                end
            end
        end
    end
    return best
end

-- Auto-detect steal tool: scan for egg-related tool in char hands first
local function getStealTool()
    -- First check if player is already holding an egg tool
    local c = getChar()
    if c then
        for _,t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("egg") then return t end
        end
    end
    -- Then find by keywords
    return findTool({"steal","egg","grab","snatch","pick","take","swipe","thief","heist"})
end

-- Auto-detect club/attack tool
local function getClubTool()
    return findTool({
        "pentungan","club","bonk","bat","mallet","hammer","stick",
        "weapon","attack","hit","swing","smash","whack","bop","wand","staff"
    })
end

-- Run detection on load and cache result
task.spawn(function()
    task.wait(3) -- wait for game to fully load
    detectShopPos()
    for _,b in ipairs({"Forest","Plains","Mountain"}) do
        detectBiomePos(b)
    end
    print("[Noa Hub] Auto-detect selesai.")
    print("  Shop :", tostring(_detectedShop))
    print("  Forest:", tostring(_detectedBiome.Forest))
    print("  Plains:", tostring(_detectedBiome.Plains))
    print("  Mountain:", tostring(_detectedBiome.Mountain))
end)
local function equipTool(t)   local h=getHum() if h and t then h:EquipTool(t) end end
local function unequipTools() local h=getHum() if h then h:UnequipTools() end end

-- ── MOVE STYLES ───────────────────────────────────────────────────────────
local function moveTween(pos, speed, cb)
    local hrp = getHRP() if not hrp then if cb then cb() end return end
    local t = TweenService:Create(hrp, TweenInfo.new((hrp.Position-pos).Magnitude/speed, Enum.EasingStyle.Linear), {CFrame=CFrame.new(pos+Vector3.new(0,3,0))})
    t:Play() t.Completed:Connect(function() if cb then cb() end end)
end
local function moveInstant(pos) teleportTo(pos) end
local function moveZigzag(pos, speed, cb)
    task.spawn(function()
        local hrp = getHRP() if not hrp then if cb then cb() end return end
        local dir  = (pos-hrp.Position).Unit
        local perp = Vector3.new(-dir.Z,0,dir.X)
        local dist = (hrp.Position-pos).Magnitude
        local step = dist/6
        for i=1,6 do
            hrp = getHRP() if not hrp then break end
            local off = perp*(i%2==0 and 5 or -5)
            local tgt = hrp.Position+dir*step+off
            tgt = Vector3.new(tgt.X,pos.Y+3,tgt.Z)
            local tw = TweenService:Create(hrp,TweenInfo.new(step/speed,Enum.EasingStyle.Linear),{CFrame=CFrame.new(tgt)})
            tw:Play() tw.Completed:Wait()
        end
        hrp = getHRP()
        if hrp then
            local tf = TweenService:Create(hrp,TweenInfo.new(0.3),{CFrame=CFrame.new(pos+Vector3.new(0,3,0))})
            tf:Play() tf.Completed:Wait()
        end
        if cb then cb() end
    end)
end
local function moveFly(pos, speed, cb)
    task.spawn(function()
        local hrp = getHRP() if not hrp then if cb then cb() end return end
        local h = 30
        for _,p in ipairs({hrp.Position+Vector3.new(0,h,0), pos+Vector3.new(0,h,0), pos+Vector3.new(0,3,0)}) do
            local tw = TweenService:Create(hrp,TweenInfo.new(1.2,Enum.EasingStyle.Quad),{CFrame=CFrame.new(p)})
            tw:Play() tw.Completed:Wait()
        end
        if cb then cb() end
    end)
end
local function moveByStyle(pos, cb)
    local s = CFG.MoveStyle
    if s=="Tween"   then moveTween(pos,CFG.StealSpeed,cb)
    elseif s=="Instant" then moveInstant(pos) if cb then cb() end
    elseif s=="Fly" then moveFly(pos,CFG.StealSpeed,cb)
    else moveZigzag(pos,CFG.StealSpeed,cb) end
end

-- ── FOREST DROP CYCLE ────────────────────────────────────────────────────
local forestDropActive = false
local forestDropThread = nil
local function forestDrop_cycle()
    local savedPos = getHRP() and getHRP().Position or SHOP_POS
    if CFG.CharFreeze then freezeChar() end
    local egg,eggPos = findBestEgg()
    if not egg then
        if CFG.NotifDrop then notify("Noa Hub","Egg tidak ditemukan.") end
        unfreezeChar() return false
    end
    if CFG.CharFreeze then unfreezeChar() end
    local hum = getHum() if hum then hum.WalkSpeed=CFG.CloneSpeed end
    local nc
    if CFG.CloneNoclip then
        nc = RunService.Stepped:Connect(function()
            local c=getChar() if not c then return end
            for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    end
    moveZigzag(eggPos+Vector3.new(0,3,0),CFG.CloneSpeed,nil) task.wait(0.5)
    local tool=getStealTool() if tool then equipTool(tool) task.wait(0.3) end
    local fp = BIOME_POS(CFG.ForestBiome) or BIOME_POS("Forest")
    if CFG.GuardianCheck then
        local w=0 while isGuardianNear(40) and w<10 do task.wait(1) w+=1 end
    end
    moveZigzag(fp,CFG.CloneSpeed,nil) task.wait(0.8)
    unequipTools() task.wait(CFG.DropDelay)
    if CFG.NotifDrop then notify("Noa Hub","Egg di-drop di "..CFG.ForestBiome.."!") end
    task.wait(0.5)
    local tool2=getStealTool() if tool2 then equipTool(tool2) task.wait(0.3) end
    moveTween(savedPos,CFG.CloneSpeed,function()
        unequipTools()
        if CFG.NotifDrop then notify("Noa Hub","Egg diserahkan!") end
    end)
    if nc then nc:Disconnect() end
    local hrp2=getHRP() if hrp2 then hrp2.CFrame=CFrame.new(savedPos+Vector3.new(0,3,0)) end
    local hum2=getHum() if hum2 then hum2.WalkSpeed=CFG.WalkSpeed end
    return true
end
local function startForestDrop()
    if forestDropActive then return end forestDropActive=true
    forestDropThread=task.spawn(function()
        while forestDropActive do
            pcall(forestDrop_cycle)
            if not CFG.LoopDrop then forestDropActive=false break end
            task.wait(1)
        end
    end)
end
local function stopForestDrop()
    forestDropActive=false
    if forestDropThread then task.cancel(forestDropThread) forestDropThread=nil end
    unfreezeChar()
    local hum=getHum() if hum then hum.WalkSpeed=CFG.WalkSpeed end
end

-- ── AUTO STEAL LOOP ───────────────────────────────────────────────────────
local autoStealActive=false; local autoStealThread=nil
local function autoSteal_cycle()
    if CFG.MoveStyle=="ForestDrop" then return forestDrop_cycle() end
    local egg,eggPos=findBestEgg() if not egg then task.wait(1) return false end
    local hum=getHum() if hum then hum.WalkSpeed=CFG.StealSpeed end
    moveByStyle(eggPos,nil) task.wait(CFG.StealDelay)
    local t=getStealTool() if t then equipTool(t) task.wait(0.3) end
    if CFG.AutoDrop then
        moveTween(SHOP_POS(),CFG.StealSpeed,function() unequipTools() end) task.wait(0.5)
    end
    if CFG.AutoTreadmill2 then
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("treadmill") and obj:IsA("BasePart") then
                teleportTo(obj.Position) task.wait(CFG.TreadmillDur) break
            end
        end
    end
    local hum2=getHum() if hum2 then hum2.WalkSpeed=CFG.WalkSpeed end
    return true
end
local function startAutoSteal()
    if autoStealActive then return end autoStealActive=true
    autoStealThread=task.spawn(function()
        while autoStealActive do pcall(autoSteal_cycle) task.wait(0.5) end
    end)
end
local function stopAutoSteal()
    autoStealActive=false
    if autoStealThread then task.cancel(autoStealThread) autoStealThread=nil end
    local hum=getHum() if hum then hum.WalkSpeed=CFG.WalkSpeed end
end

-- ── NOCLIP ────────────────────────────────────────────────────────────────
RunService.Stepped:Connect(function()
    if CFG.Noclip or CFG.AntiGuardian and isGuardianNear(25) then
        local c=getChar() if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end
end)

-- ── WALK SPEED & JUMP POWER ───────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    local hum=getHum() if not hum then return end
    if not autoStealActive and not forestDropActive then
        hum.WalkSpeed=CFG.WalkSpeed
        hum.JumpPower=CFG.JumpPower
    end
    -- Anti Slip
    if CFG.AntiSlip then hum.WalkSpeed=math.max(hum.WalkSpeed,CFG.WalkSpeed) end
    -- Speed Burst saat guardian dekat
    if CFG.SpeedBurst and isGuardianNear(CFG.GuardianAlertR) then
        hum.WalkSpeed=600
    end
end)

-- ── INFINITE JUMP ─────────────────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump then
        local hum=getHum() if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── FLY MODE ─────────────────────────────────────────────────────────────
local flyBV, flyBG
local function enableFly()
    local hrp=getHRP() if not hrp then return end
    flyBV=Instance.new("BodyVelocity") flyBV.Velocity=Vector3.zero flyBV.MaxForce=Vector3.new(1e5,1e5,1e5) flyBV.Parent=hrp
    flyBG=Instance.new("BodyGyro") flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5) flyBG.P=1e4 flyBG.Parent=hrp
end
local function disableFly()
    if flyBV then flyBV:Destroy() flyBV=nil end
    if flyBG then flyBG:Destroy() flyBG=nil end
end
RunService.Heartbeat:Connect(function()
    if CFG.FlyMode and flyBV then
        local cam=workspace.CurrentCamera
        local dir=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        flyBV.Velocity=dir*CFG.WalkSpeed
        if flyBG then flyBG.CFrame=cam.CFrame end
    end
end)

-- ── GHOST MODE ────────────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    local c=getChar() if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier=CFG.GhostMode and 0.8 or 0
        end
    end
end)

-- ── ANTI AFK ─────────────────────────────────────────────────────────────
lp.Idled:Connect(function()
    if CFG.AntiAFK then
        VirtualUser:Button2Down(Vector2.zero,workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.zero,workspace.CurrentCamera.CFrame)
    end
end)

-- ── GUARDIAN ALERT ───────────────────────────────────────────────────────
local guardAlertCooldown = false
RunService.Heartbeat:Connect(function()
    if CFG.GuardianAlert and not guardAlertCooldown and isGuardianNear(CFG.GuardianAlertR) then
        guardAlertCooldown=true
        notify("Noa Hub","GUARDIAN DEKAT! Jarak: "..math.floor(nearestGuardDist()).." studs",2)
        task.wait(5) guardAlertCooldown=false
    end
    if CFG.KillGuardian then
        for _,g in ipairs(findGuardians()) do
            local gh=g:FindFirstChildWhichIsA("Humanoid")
            local gr=g:FindFirstChild("HumanoidRootPart")
            local hrp=getHRP()
            if gh and gr and hrp and (gr.Position-hrp.Position).Magnitude<30 then gh.Health=0 end
        end
    end
end)

-- ── ESP ───────────────────────────────────────────────────────────────────
local espBills={}
local function clearESP()
    for _,b in ipairs(espBills) do if b and b.Parent then b:Destroy() end end
    espBills={}
end
local function makeESP(part, text, color, dist)
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,90,0,CFG.NameTagEsp and 24 or 18)
    bb.StudsOffset=Vector3.new(0,3,0)
    bb.AlwaysOnTop=true
    bb.Parent=part
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=CFG.DistanceEsp and text.." ["..math.floor(dist).."s]" or text
    lbl.TextColor3=color or Color3.new(1,1,1)
    lbl.TextStrokeTransparency=0
    lbl.Font=Enum.Font.GothamBold
    lbl.TextScaled=true
    lbl.Parent=bb
    espBills[#espBills+1]=bb
    -- Box ESP
    if CFG.BoxEsp then
        local box=Instance.new("SelectionBox")
        box.Color3=color box.LineThickness=0.05 box.SurfaceTransparency=0.85
        box.Adornee=part box.Parent=bb
    end
end

RunService.Heartbeat:Connect(function()
    clearESP()
    local hrp=getHRP() if not hrp then return end
    if CFG.EspEgg then
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
                local r=getEggRarity(obj.Name)
                local d=(obj.Position-hrp.Position).Magnitude
                if d<=CFG.EspRange then makeESP(obj,r,RARITY_COLORS[r] or Color3.new(1,1,1),d) end
            end
        end
    end
    if CFG.EspGuardian then
        for _,g in ipairs(findGuardians()) do
            local r=g:FindFirstChild("HumanoidRootPart")
            if r then
                local d=(r.Position-hrp.Position).Magnitude
                if d<=CFG.EspRange then makeESP(r,"GUARDIAN",Color3.fromRGB(255,70,70),d) end
            end
        end
    end
    if CFG.EspPlayer then
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=lp and p.Character then
                local r=p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d=(r.Position-hrp.Position).Magnitude
                    if d<=CFG.EspRange then makeESP(r,p.Name,Color3.fromRGB(80,140,255),d) end
                end
            end
        end
    end
end)

-- ── PVP SYSTEM ────────────────────────────────────────────────────────────
local pvpThread=nil
local function scanPlayersEggs()
    local res={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp and p.Character then
            local egg=nil
            for _,it in ipairs(p.Character:GetChildren()) do
                if it:IsA("Tool") and it.Name:lower():find("egg") then egg=it break end
            end
            if not egg then
                local bp=p:FindFirstChild("Backpack")
                if bp then for _,it in ipairs(bp:GetChildren()) do if it:IsA("Tool") and it.Name:lower():find("egg") then egg=it break end end end
            end
            local r=egg and getEggRarity(egg.Name) or nil
            if egg and CFG.PVP.Filter[r] then
                res[#res+1]={player=p,tool=egg,rarity=r,priority=RARITY_ORDER[r] or 1}
            else
                res[#res+1]={player=p,tool=nil,rarity=nil,priority=0}
            end
        end
    end
    if CFG.PVP.PriorityHigh then table.sort(res,function(a,b) return a.priority>b.priority end) end
    return res
end

local function attackPlayer(target)
    local tHRP=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return false end
    local club=getClubTool() if not club then warn("[NoaHub] Club tidak ada di backpack.") return false end
    local hum=getHum() if hum then hum.WalkSpeed=CFG.StealSpeed*1.5 end
    teleportTo(tHRP.Position+Vector3.new(2,0,0)) task.wait(0.15)
    equipTool(club) task.wait(0.2)
    for _=1,3 do
        pcall(function() club:Activate() end) task.wait(0.35)
        local still=false
        for _,it in ipairs(target.Character:GetChildren()) do if it:IsA("Tool") and it.Name:lower():find("egg") then still=true break end end
        if not still then break end
    end
    unequipTools()
    return true
end

local function stealFromPlayer(entry)
    if not entry.tool then return false,"no_egg" end
    local tgt=entry.player
    CFG.PVP.Attempts+=1
    local tHRP=tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return false,"no_char" end
    local atk=attackPlayer(tgt) if not atk then return false,"no_weapon" end
    task.wait(0.3)
    local closestEgg,closestDist=nil,15
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
            local d=(obj.Position-tHRP.Position).Magnitude
            if d<closestDist then closestEgg=obj closestDist=d end
        end
    end
    closestEgg=closestEgg or entry.tool
    if closestEgg then
        teleportTo(closestEgg.Position+Vector3.new(0,2,0)) task.wait(0.2)
        local st=getStealTool() if st then equipTool(st) task.wait(0.3) end
        if CFG.PVP.RunAfter then
            local hum2=getHum() if hum2 then hum2.WalkSpeed=CFG.StealSpeed end
            moveZigzag(SHOP_POS(),CFG.StealSpeed,function()
                unequipTools()
                CFG.PVP.Stolen+=1
                notify("Noa Hub","Berhasil curi "..entry.rarity.." Egg dari "..tgt.Name.."!")
            end)
        else
            CFG.PVP.Stolen+=1
            notify("Noa Hub","Egg "..entry.rarity.." diambil dari "..tgt.Name)
        end
        return true,"success"
    end
    return false,"egg_not_found"
end

local function startPVPAuto()
    if CFG.PVP.Auto then return end CFG.PVP.Auto=true
    pvpThread=task.spawn(function()
        while CFG.PVP.Auto do
            local list=scanPlayersEggs()
            for _,entry in ipairs(list) do
                if entry.tool then pcall(stealFromPlayer,entry) break end
            end
            task.wait(CFG.PVP.Cooldown)
        end
    end)
    notify("Noa Hub","Auto Steal Players aktif!")
end
local function stopPVPAuto()
    CFG.PVP.Auto=false
    if pvpThread then task.cancel(pvpThread) pvpThread=nil end
    local hum=getHum() if hum then hum.WalkSpeed=CFG.WalkSpeed end
    notify("Noa Hub","Auto Steal Players dihentikan.")
end

-- ══════════════════════════════════════════════════════════════════════════
-- GUI
-- ══════════════════════════════════════════════════════════════════════════
if gui:FindFirstChild("NoaHub") then gui.NoaHub:Destroy() end

local C = {
    bg0=Color3.fromRGB(7,7,15), bg1=Color3.fromRGB(11,11,22), bg2=Color3.fromRGB(14,14,28),
    bg3=Color3.fromRGB(22,22,40), bg5=Color3.fromRGB(28,28,52),
    a1=Color3.fromRGB(96,128,255), a2=Color3.fromRGB(64,200,184),
    t0=Color3.fromRGB(238,240,255), t1=Color3.fromRGB(136,144,204), t2=Color3.fromRGB(85,88,128), t3=Color3.fromRGB(48,48,74),
    green=Color3.fromRGB(64,200,100), red=Color3.fromRGB(255,64,96), gold=Color3.fromRGB(240,192,96),
}
local function mk(cls,props) local o=Instance.new(cls) for k,v in pairs(props) do o[k]=v end return o end
local function corner(p,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p return c end
local function stroke(p,col,th) local s=Instance.new("UIStroke") s.Color=col or C.t3 s.Thickness=th or 1 s.Transparency=0.85 s.Parent=p return s end
local function lbl(p,text,sz,col,props)
    local l=mk("TextLabel",{Text=text or "",TextSize=sz or 11,TextColor3=col or C.t0,Font=Enum.Font.GothamBold,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Parent=p})
    if props then for k,v in pairs(props) do l[k]=v end end return l
end
local function pad(p,t,l2,r,b) local u=Instance.new("UIPadding") if t then u.PaddingTop=UDim.new(0,t) end if l2 then u.PaddingLeft=UDim.new(0,l2) end if r then u.PaddingRight=UDim.new(0,r) end if b then u.PaddingBottom=UDim.new(0,b) end u.Parent=p return u end

local ScreenGui = mk("ScreenGui",{Name="NoaHub",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999,Parent=gui})
local Main = mk("Frame",{Size=UDim2.new(0,520,0,370),Position=UDim2.new(0.5,-260,0.5,-185),BackgroundColor3=C.bg1,BorderSizePixel=0,Parent=ScreenGui})
corner(Main,12) stroke(Main,C.a1,1)

-- Gradient accent bottom line
mk("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(96,128,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(64,200,184))}),Rotation=90,Parent=mk("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=Main})})

-- Title Bar
local TitleBar=mk("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.bg0,BorderSizePixel=0,Parent=Main})
corner(TitleBar,12)
mk("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),BackgroundColor3=C.bg0,BorderSizePixel=0,Parent=TitleBar})
for i,dc in ipairs({Color3.fromRGB(255,80,80),Color3.fromRGB(240,176,40),Color3.fromRGB(64,200,80)}) do
    local dot=mk("TextButton",{Size=UDim2.new(0,10,0,10),Position=UDim2.new(0,8+(i-1)*16,0.5,-5),BackgroundColor3=dc,BorderSizePixel=0,Text="",Parent=TitleBar})
    corner(dot,10)
    if i==1 then dot.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end) end
end
lbl(TitleBar,"Noa Hub",12,C.t0,{Size=UDim2.new(0,80,1,0),Position=UDim2.new(0,58,0,0)})
lbl(TitleBar,"v2.0 \xc2\xb7 Steal An Egg",9,C.t2,{Size=UDim2.new(0,160,1,0),Position=UDim2.new(0,138,0,0)})

-- Drag
local drag,dragStart,startPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true dragStart=i.Position startPos=Main.Position end
end)
TitleBar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

-- Sidebar
local Sidebar=mk("Frame",{Size=UDim2.new(0,120,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=C.bg0,BorderSizePixel=0,Parent=Main})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=Sidebar})
pad(Sidebar,8,5,5,8)
mk("Frame",{Size=UDim2.new(0,1,1,-40),Position=UDim2.new(0,120,0,40),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.93,BorderSizePixel=0,Parent=Main})

local Content=mk("Frame",{Size=UDim2.new(1,-121,1,-40),Position=UDim2.new(0,121,0,40),BackgroundColor3=C.bg1,BorderSizePixel=0,Parent=Main})

-- Page & nav system
local pages,navBtns,activePage={},{},nil
local PAGE_DEFS={
    {id="main",  label="Main"},
    {id="auto",  label="Auto Steal"},
    {id="esp",   label="ESP"},
    {id="forest",label="Forest Biome"},
    {id="pvp",   label="Players Steal"},
    {id="srv",   label="Private Server"},
    {id="misc",  label="Misc"},
    {id="cfg",   label="Config"},
}

local function setPage(id)
    for pid,page in pairs(pages) do page.Visible=(pid==id) end
    for pid,btn in pairs(navBtns) do
        local isActive=(pid==id)
        btn.BackgroundColor3=isActive and C.bg3 or C.bg0
        btn.BackgroundTransparency=isActive and 0 or 1
        btn.TextColor3=isActive and C.t0 or C.t2
        local ab=btn:FindFirstChildWhichIsA("Frame")
        if ab then ab.Visible=isActive end
    end
    activePage=id
end

-- Nav divider helper
local function makeDiv(order)
    return mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.93,BorderSizePixel=0,LayoutOrder=order,Parent=Sidebar})
end

for i,def in ipairs(PAGE_DEFS) do
    if def.id=="forest" then makeDiv(i*2-1) end
    if def.id=="misc"   then makeDiv(i*2-1) end
    local btn=mk("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=C.bg0,BackgroundTransparency=1,BorderSizePixel=0,Text=def.label,TextSize=10,TextColor3=C.t2,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=i*2,Parent=Sidebar})
    pad(btn,0,10)
    corner(btn,5)
    local ab=mk("Frame",{Size=UDim2.new(0,2,0.6,0),Position=UDim2.new(0,0,0.2,0),BackgroundColor3=def.id=="pvp" and Color3.fromRGB(255,80,80) or C.a1,BorderSizePixel=0,Visible=false,Parent=btn})
    corner(ab,2)
    navBtns[def.id]=btn
    local page=mk("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.a1,Visible=false,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),Parent=Content})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=page})
    pad(page,8,8,8,10)
    pages[def.id]=page
    btn.MouseButton1Click:Connect(function()
        setPage(def.id)
        if def.id=="pvp" then task.spawn(pvpRefreshGUI) end
    end)
end

-- ── GUI HELPERS ───────────────────────────────────────────────────────────
local lo=0
local function nextLo() lo+=1 return lo end
local function makeRow(parent,order)
    local r=mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=order or nextLo(),Parent=parent})
    corner(r,7) stroke(r,Color3.new(1,1,1),1) return r
end
local function secLabel(parent,text,order)
    local f=mk("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=order or nextLo(),Parent=parent})
    lbl(f,text,9,C.a1,{Size=UDim2.new(0,120,1,0),TextTransparency=0.35,Font=Enum.Font.GothamBold})
    mk("Frame",{Size=UDim2.new(1,-128,0,1),Position=UDim2.new(0,126,0.5,0),BackgroundColor3=C.a1,BackgroundTransparency=0.72,BorderSizePixel=0,Parent=f})
    return f
end
local function makeToggle(parent,labelTxt,subTxt,default,onChange,order)
    local row=makeRow(parent,order)
    lbl(row,labelTxt,11,C.t0,{Size=UDim2.new(0,210,0,15),Position=UDim2.new(0,10,0,4)})
    if subTxt then lbl(row,subTxt,9,C.t2,{Size=UDim2.new(0,210,0,12),Position=UDim2.new(0,10,0,18)}) end
    local track=mk("TextButton",{Size=UDim2.new(0,32,0,17),Position=UDim2.new(1,-44,0.5,-8),BackgroundColor3=default and C.a1 or C.bg5,BorderSizePixel=0,Text="",Parent=row})
    corner(track,9)
    local thumb=mk("Frame",{Size=UDim2.new(0,11,0,11),Position=default and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=track})
    corner(thumb,10)
    local state=default or false
    track.MouseButton1Click:Connect(function()
        state=not state
        TweenService:Create(track,TweenInfo.new(0.12),{BackgroundColor3=state and C.a1 or C.bg5}):Play()
        TweenService:Create(thumb,TweenInfo.new(0.12),{Position=state and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5)}):Play()
        if onChange then onChange(state) end
    end)
    return track
end
local function makeSlider(parent,labelTxt,min_,max_,default,onChange,order,isFloat)
    local f=mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=order or nextLo(),Parent=parent})
    corner(f,7) stroke(f,Color3.new(1,1,1),1)
    local valL=lbl(f,tostring(default),11,C.a1,{Size=UDim2.new(0,50,0,16),Position=UDim2.new(1,-58,0,8),TextXAlignment=Enum.TextXAlignment.Right})
    lbl(f,labelTxt,11,C.t0,{Size=UDim2.new(0,180,0,16),Position=UDim2.new(0,10,0,8)})
    local track=mk("Frame",{Size=UDim2.new(1,-20,0,4),Position=UDim2.new(0,10,0,34),BackgroundColor3=C.bg5,BorderSizePixel=0,Parent=f})
    corner(track,2)
    local fill=mk("Frame",{Size=UDim2.new((default-min_)/(max_-min_),0,1,0),BackgroundColor3=C.a1,BorderSizePixel=0,Parent=track})
    corner(fill,2)
    local ds=false
    local function upd(inp)
        local rx=math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=isFloat and (math.floor((min_+rx*(max_-min_))*10+0.5)/10) or math.floor(min_+rx*(max_-min_))
        fill.Size=UDim2.new(rx,0,1,0)
        valL.Text=tostring(v)
        if onChange then onChange(v) end
    end
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true upd(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end end)
    UserInputService.InputChanged:Connect(function(i) if ds and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i) end end)
    return f
end
local function makeButton(parent,text,col,onClick,order)
    local btn=mk("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=col or C.bg3,BorderSizePixel=0,Text=text,TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,LayoutOrder=order or nextLo(),Parent=parent})
    corner(btn,7) stroke(btn,Color3.new(1,1,1),1)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return btn
end
local function makeNote(parent,text,col,order)
    local f=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=col or C.bg2,BorderSizePixel=0,LayoutOrder=order or nextLo(),Parent=parent})
    corner(f,7) stroke(f,Color3.new(1,1,1),1)
    mk("TextLabel",{Size=UDim2.new(1,-16,0,0),Position=UDim2.new(0,8,0,6),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=text,TextSize=9,TextColor3=C.t2,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=f})
    pad(f,0,0,0,6)
    return f
end
local function infoRow(parent,key,val,order)
    local r=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=order or nextLo(),Parent=parent})
    corner(r,6) stroke(r,Color3.new(1,1,1),1)
    lbl(r,key,10,C.t2,{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,10,0,0)})
    lbl(r,val,10,C.t0,{Size=UDim2.new(0.5,-10,1,0),Position=UDim2.new(0.5,0,0,0),TextXAlignment=Enum.TextXAlignment.Right})
    return r
end

-- ── PAGE: MAIN ────────────────────────────────────────────────────────────
lo=0
local pgMain=pages.main
secLabel(pgMain,"MOVEMENT")
makeSlider(pgMain,"Walk Speed",16,600,200,function(v) CFG.WalkSpeed=v end)
makeSlider(pgMain,"Jump Power",0,200,50,function(v) CFG.JumpPower=v end)
makeToggle(pgMain,"Noclip","Menembus semua objek dan dinding di map",false,function(v) CFG.Noclip=v end)
makeToggle(pgMain,"Infinite Jump","Loncat tanpa batas, berguna menghindari guardian",false,function(v) CFG.InfJump=v end)
makeToggle(pgMain,"Anti Slip","Mencegah karakter terpeleset di permukaan licin",false,function(v) CFG.AntiSlip=v end)
secLabel(pgMain,"TREADMILL")
makeToggle(pgMain,"Auto Treadmill","Pergi ke treadmill setelah berhasil steal",false,function(v) CFG.AutoTreadmill=v end)
makeSlider(pgMain,"Durasi Treadmill (det)",1,15,3,function(v) CFG.TreadmillDur=v end,nil,true)
makeNote(pgMain,"Walk Speed di atas 400 berisiko terdeteksi. Rekomendasi 200-350 untuk sesi panjang.",Color3.fromRGB(20,40,20))

-- ── PAGE: AUTO ────────────────────────────────────────────────────────────
lo=0
local pgAuto=pages.auto
secLabel(pgAuto,"MOVE STYLE")
-- Style selector
local styleF=mk("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.bg2,LayoutOrder=nextLo(),BorderSizePixel=0,Parent=pgAuto})
corner(styleF,7) stroke(styleF,Color3.new(1,1,1),1)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=styleF})
pad(styleF,6,6,6,0)
local styleBtns={}
for _,sn in ipairs({"Zigzag","Tween","Instant","Fly","ForestDrop"}) do
    local sb=mk("TextButton",{Size=UDim2.new(0,64,0,24),BackgroundColor3=sn=="Zigzag" and C.a1 or C.bg5,BorderSizePixel=0,Text=sn,TextSize=10,TextColor3=sn=="Zigzag" and Color3.new(1,1,1) or C.t2,Font=Enum.Font.Gotham,Parent=styleF})
    corner(sb,12) styleBtns[sn]=sb
    sb.MouseButton1Click:Connect(function()
        CFG.MoveStyle=sn
        for sid,sbtn in pairs(styleBtns) do
            sbtn.BackgroundColor3=(sid==sn) and C.a1 or C.bg5
            sbtn.TextColor3=(sid==sn) and Color3.new(1,1,1) or C.t2
        end
        local fdp=pgAuto:FindFirstChild("FDPanel")
        if fdp then fdp.Visible=(sn=="ForestDrop") end
        if sn~="ForestDrop" then stopForestDrop() end
    end)
end
-- Forest Drop inline panel
local fdPanel=mk("Frame",{Name="FDPanel",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(12,24,14),BorderSizePixel=0,LayoutOrder=nextLo(),Visible=false,Parent=pgAuto})
corner(fdPanel,7) stroke(fdPanel,C.green,1)
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=fdPanel})
pad(fdPanel,6,6,6,6)
lbl(fdPanel,"Forest Drop \xe2\x80\x94 Alur Otomatis",10,C.green,{Size=UDim2.new(1,0,0,18),LayoutOrder=1})
local fdStatF=mk("Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,LayoutOrder=2,Parent=fdPanel})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=fdStatF})
local fdCycLbl,fdPhaseLbl,fdTimLbl
for _,s in ipairs({{"CYCLE","0"},{"FASE","IDLE"},{"SESI","00:00"}}) do
    local sf=mk("Frame",{Size=UDim2.new(0.33,-3,1,0),BackgroundColor3=Color3.fromRGB(18,28,18),BorderSizePixel=0,Parent=fdStatF})
    corner(sf,6)
    local nl=mk("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,4),BackgroundTransparency=1,Text=s[2],TextSize=14,Font=Enum.Font.GothamBold,TextColor3=C.a1,Parent=sf})
    lbl(sf,s[1],8,C.t2,{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-16),TextXAlignment=Enum.TextXAlignment.Center})
    if s[1]=="CYCLE" then fdCycLbl=nl elseif s[1]=="FASE" then fdPhaseLbl=nl else fdTimLbl=nl end
end
makeSlider(fdPanel,"Clone Speed",16,600,500,function(v) CFG.CloneSpeed=v end,3)
makeToggle(fdPanel,"Karakter Freeze","Lock posisi di depan toko",true,function(v) CFG.CharFreeze=v end,4)
makeToggle(fdPanel,"Clone Noclip","Menembus semua objek saat lari",true,function(v) CFG.CloneNoclip=v end,5)
makeToggle(fdPanel,"Guardian Check","Cek area forest sebelum drop",true,function(v) CFG.GuardianCheck=v end,6)
local fdBtnF=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=7,Parent=fdPanel})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=fdBtnF})
local fdStartBtn=mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=Color3.fromRGB(35,85,35),BorderSizePixel=0,Text="Mulai FD",TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,Parent=fdBtnF})
local fdStopBtn=mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=Color3.fromRGB(60,25,30),BorderSizePixel=0,Text="Stop FD",TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,Parent=fdBtnF})
corner(fdStartBtn,7) corner(fdStopBtn,7)
-- FD timer loop
local fdSecs2=0
fdStartBtn.MouseButton1Click:Connect(function()
    fdSecs2=0
    task.spawn(function()
        local st=tick()
        while forestDropActive do
            local el=math.floor(tick()-st)
            if fdTimLbl then fdTimLbl.Text=string.format("%02d:%02d",math.floor(el/60),el%60) end
            task.wait(1)
        end
    end)
    startForestDrop()
    notify("Noa Hub","Forest Drop dimulai!")
end)
fdStopBtn.MouseButton1Click:Connect(function()
    stopForestDrop()
    if fdPhaseLbl then fdPhaseLbl.Text="STOP" end
    notify("Noa Hub","Forest Drop dihentikan.")
end)

secLabel(pgAuto,"SPEED & AUTO")
makeSlider(pgAuto,"Steal Speed",16,600,200,function(v) CFG.StealSpeed=v end)
makeSlider(pgAuto,"Steal Delay (det)",0,5,0.5,function(v) CFG.StealDelay=v end,nil,true)
makeToggle(pgAuto,"Auto Steal Egg","Loop otomatis mencuri egg dari nest",false,function(v) if v then startAutoSteal() else stopAutoSteal() end end)
makeToggle(pgAuto,"Auto Drop ke Base","Antar egg ke base setelah steal",false,function(v) CFG.AutoDrop=v end)
makeToggle(pgAuto,"Auto Treadmill","Pergi ke treadmill setelah drop",false,function(v) CFG.AutoTreadmill2=v end)
secLabel(pgAuto,"EGG TOOLS")
makeToggle(pgAuto,"Egg Checkers","Cek rarity sebelum diambil, skip yang tidak sesuai",false,function(v) CFG.EggChecker=v end)
makeToggle(pgAuto,"Egg Predictor","Hanya ambil Divine & Eternal saja",false,function(v) CFG.EggPredictor=v end)
makeNote(pgAuto,"Egg Predictor aktif: hanya Divine & Eternal yang diproses. Rarity lain dilewati otomatis.",Color3.fromRGB(28,18,44))

-- ── PAGE: ESP ─────────────────────────────────────────────────────────────
lo=0
local pgEsp=pages.esp
secLabel(pgEsp,"HIGHLIGHT")
makeToggle(pgEsp,"Egg ESP","Highlight egg dengan warna sesuai rarity",false,function(v) CFG.EspEgg=v end)
makeToggle(pgEsp,"Guardian ESP","Highlight guardian NPC dengan merah terang",false,function(v) CFG.EspGuardian=v end)
makeToggle(pgEsp,"Player ESP","Highlight semua player lain dengan biru",false,function(v) CFG.EspPlayer=v end)
secLabel(pgEsp,"TAMPILAN")
makeToggle(pgEsp,"Box ESP","Kotak seleksi di sekeliling target",false,function(v) CFG.BoxEsp=v end)
makeToggle(pgEsp,"Name Tag ESP","Tampilkan nama di atas kepala target",true,function(v) CFG.NameTagEsp=v end)
makeToggle(pgEsp,"Jarak ESP","Tampilkan jarak studs di samping nama",true,function(v) CFG.DistanceEsp=v end)
makeSlider(pgEsp,"Range ESP (studs)",50,500,300,function(v) CFG.EspRange=v end)
makeNote(pgEsp,"Warna: Common=Putih | Rare=Biru | Epic=Ungu | Legendary=Orange | Divine=Magenta | Eternal=Gold",C.bg2)

-- ── PAGE: FOREST ──────────────────────────────────────────────────────────
lo=0
local pgForest=pages.forest
-- Status header
local fHdr=mk("Frame",{Size=UDim2.new(1,0,0,60),BackgroundColor3=Color3.fromRGB(12,24,14),LayoutOrder=nextLo(),BorderSizePixel=0,Parent=pgForest})
corner(fHdr,7) stroke(fHdr,C.green,1) pad(fHdr,8,8,8,8)
local fStatF=mk("Frame",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,Parent=fHdr})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=fStatF})
local fDropLbl,fRateLbl,fTimeLbl
for _,s in ipairs({{"DROPPED","0"},{"PER JAM","0"},{"SESI","00:00"}}) do
    local sf=mk("Frame",{Size=UDim2.new(0.33,-4,1,0),BackgroundColor3=Color3.fromRGB(16,28,16),BorderSizePixel=0,Parent=fStatF})
    corner(sf,6)
    local nl=mk("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,Text=s[2],TextSize=15,Font=Enum.Font.GothamBold,TextColor3=C.green,Parent=sf})
    lbl(sf,s[1],8,C.t2,{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-16),TextXAlignment=Enum.TextXAlignment.Center})
    if s[1]=="DROPPED" then fDropLbl=nl elseif s[1]=="PER JAM" then fRateLbl=nl else fTimeLbl=nl end
end
secLabel(pgForest,"PENGATURAN")
makeSlider(pgForest,"Drop Delay (det)",0,10,1.5,function(v) CFG.DropDelay=v end,nil,true)
makeToggle(pgForest,"Safe Drop Mode","Tunggu guardian menjauh sebelum drop",true,function(v) CFG.SafeDrop=v end)
makeToggle(pgForest,"Auto Teleport ke Biome","TP ke titik drop sebelum mulai",true,function(v) CFG.AutoTPForest=v end)
makeToggle(pgForest,"Loop Setelah Drop","Langsung steal lagi setelah cycle selesai",false,function(v) CFG.LoopDrop=v end)
makeToggle(pgForest,"Notifikasi Saat Drop","Popup setiap egg berhasil di-drop",true,function(v) CFG.NotifDrop=v end)
secLabel(pgForest,"KONTROL")
local fStatusLbl=lbl(pgForest,"Status: OFF",9,C.t2,{Size=UDim2.new(1,0,0,16),LayoutOrder=nextLo()})
local fStartBtn=makeButton(pgForest,"Mulai Forest Drop",Color3.fromRGB(35,85,35),function()
    if CFG.AutoTPForest then teleportTo(BIOME_POS(CFG.ForestBiome) or BIOME_POS("Forest")) end
    CFG.MoveStyle="ForestDrop"
    startForestDrop()
    fStatusLbl.Text="Status: RUNNING"
    -- Update stats loop
    task.spawn(function()
        local start=tick() local dropped=0
        while forestDropActive do
            local el=math.floor(tick()-start)
            if fTimeLbl then fTimeLbl.Text=string.format("%02d:%02d",math.floor(el/60),el%60) end
            task.wait(3)
            dropped+=1
            if fDropLbl then fDropLbl.Text=tostring(dropped) end
            local h=el/3600
            if fRateLbl then fRateLbl.Text=h>0 and tostring(math.floor(dropped/h)) or tostring(dropped) end
        end
    end)
    notify("Noa Hub","Forest Drop dimulai!")
end)
makeButton(pgForest,"Stop Forest Drop",Color3.fromRGB(60,25,30),function()
    stopForestDrop()
    fStatusLbl.Text="Status: STOPPED"
    notify("Noa Hub","Forest Drop dihentikan.")
end)
makeButton(pgForest,"TP ke Biome Sekarang",C.bg5,function()
    teleportTo(BIOME_POS(CFG.ForestBiome) or BIOME_POS("Forest"))
    notify("Noa Hub","Teleport ke "..CFG.ForestBiome.."!")
end)

-- ── PAGE: PLAYERS STEAL ───────────────────────────────────────────────────
lo=0
local pgPVP=pages.pvp
local pvpHdr=mk("Frame",{Size=UDim2.new(1,0,0,64),BackgroundColor3=Color3.fromRGB(24,8,10),LayoutOrder=nextLo(),BorderSizePixel=0,Parent=pgPVP})
corner(pvpHdr,7) stroke(pvpHdr,Color3.fromRGB(255,60,80),1) pad(pvpHdr,8,8,8,8)
lbl(pvpHdr,"Players Steal",11,Color3.fromRGB(255,80,100),{Size=UDim2.new(0,180,0,18),Font=Enum.Font.GothamBold})
lbl(pvpHdr,"Serang player, curi egg, kabur ke base",9,C.t2,{Size=UDim2.new(0,240,0,14),Position=UDim2.new(0,0,0,20)})
local pvpStatF=mk("Frame",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,36),BackgroundTransparency=1,Parent=pvpHdr})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=pvpStatF})
local pvpStolenLbl,pvpAttemptLbl,pvpRateLbl
for _,s in ipairs({{"DICURI","0"},{"PERCOBAAN","0"},{"SUCCESS","0%"}}) do
    local sf=mk("Frame",{Size=UDim2.new(0.33,-4,1,0),BackgroundColor3=Color3.fromRGB(30,12,15),BorderSizePixel=0,Parent=pvpStatF})
    corner(sf,5)
    local nl=mk("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text=s[2],TextSize=13,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,80,100),Parent=sf})
    lbl(sf,s[1],7,C.t2,{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-12),TextXAlignment=Enum.TextXAlignment.Center})
    if s[1]=="DICURI" then pvpStolenLbl=nl elseif s[1]=="PERCOBAAN" then pvpAttemptLbl=nl else pvpRateLbl=nl end
end
local function updatePVPStats()
    if pvpStolenLbl  then pvpStolenLbl.Text=tostring(CFG.PVP.Stolen) end
    if pvpAttemptLbl then pvpAttemptLbl.Text=tostring(CFG.PVP.Attempts) end
    if pvpRateLbl    then pvpRateLbl.Text=CFG.PVP.Attempts>0 and math.floor(CFG.PVP.Stolen/CFG.PVP.Attempts*100).."%"or"0%" end
end

secLabel(pgPVP,"AUTO & PENGATURAN")
makeToggle(pgPVP,"Auto Steal Players","Scan dan serang player yang bawa egg",false,function(v) if v then startPVPAuto() else stopPVPAuto() end end)
makeToggle(pgPVP,"Priority Rarity Tinggi","Kejar Eternal > Divine > Legendary duluan",true,function(v) CFG.PVP.PriorityHigh=v end)
makeToggle(pgPVP,"Kabur ke Base Otomatis","Zigzag ke base segera setelah egg diambil",true,function(v) CFG.PVP.RunAfter=v end)
makeToggle(pgPVP,"Anti Balik Serang","Noclip jika player korban mencoba membalas",false,function(v) CFG.PVP.AntiReturn=v CFG.Noclip=v end)
makeSlider(pgPVP,"Scan Radius (studs)",10,150,80,function(v) CFG.PVP.ScanRadius=v end)
makeSlider(pgPVP,"Cooldown (det)",1,15,3,function(v) CFG.PVP.Cooldown=v end,nil,true)

secLabel(pgPVP,"MODE SERANGAN")
local pvpModeF=mk("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.bg2,LayoutOrder=nextLo(),BorderSizePixel=0,Parent=pgPVP})
corner(pvpModeF,7) stroke(pvpModeF,Color3.new(1,1,1),1)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=pvpModeF}) pad(pvpModeF,6,6,6,0)
local pvpModeBtns={}
for _,m in ipairs({"Club","Tackle","Instant"}) do
    local mb=mk("TextButton",{Size=UDim2.new(0,76,0,24),BackgroundColor3=m=="Club" and Color3.fromRGB(200,40,60) or C.bg5,BorderSizePixel=0,Text=m,TextSize=10,TextColor3=m=="Club" and Color3.new(1,1,1) or C.t2,Font=Enum.Font.Gotham,Parent=pvpModeF})
    corner(mb,12) pvpModeBtns[m]=mb
    mb.MouseButton1Click:Connect(function()
        CFG.PVP.AttackMode=m
        for mid,mb2 in pairs(pvpModeBtns) do
            mb2.BackgroundColor3=(mid==m) and Color3.fromRGB(200,40,60) or C.bg5
            mb2.TextColor3=(mid==m) and Color3.new(1,1,1) or C.t2
        end
    end)
end

secLabel(pgPVP,"PLAYERS ONLINE")
local pvpListF=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nextLo(),Parent=pgPVP})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=pvpListF})
local pvpCards={}

function pvpRefreshGUI()
    for _,c in ipairs(pvpCards) do if c.Parent then c:Destroy() end end
    pvpCards={}
    local list=scanPlayersEggs()
    if #list==0 then makeNote(pvpListF,"Tidak ada player online.",C.bg2,1) return end
    for i,entry in ipairs(list) do
        local p=entry.player
        local hasEgg=entry.tool~=nil
        local rc=hasEgg and (RARITY_COLORS[entry.rarity] or C.t1) or C.t3
        local card=mk("Frame",{Size=UDim2.new(1,0,0,hasEgg and 66 or 38),BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=i,Parent=pvpListF})
        corner(card,7) stroke(card,Color3.new(1,1,1),1)
        pvpCards[#pvpCards+1]=card
        -- Avatar
        local av=mk("TextLabel",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(0,8,0,6),BackgroundColor3=C.bg5,BorderSizePixel=0,Text=p.Name:sub(1,2):upper(),TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.t1,Parent=card})
        corner(av,6)
        -- Name
        lbl(card,p.Name,11,C.t0,{Size=UDim2.new(0,170,0,16),Position=UDim2.new(0,42,0,6),Font=Enum.Font.GothamBold})
        -- Egg info
        if hasEgg then
            lbl(card,entry.tool.Name,9,rc,{Size=UDim2.new(0,170,0,12),Position=UDim2.new(0,42,0,22)})
            local badge=mk("TextLabel",{Size=UDim2.new(0,62,0,16),Position=UDim2.new(1,-68,0,6),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,Text=entry.rarity:upper(),TextSize=8,Font=Enum.Font.GothamBold,TextColor3=rc,Parent=card})
            corner(badge,8) stroke(badge,rc,1)
            -- Detail row
            local dr=mk("Frame",{Size=UDim2.new(1,-16,0,24),Position=UDim2.new(0,8,0,38),BackgroundColor3=C.bg5,BorderSizePixel=0,Parent=card})
            corner(dr,5)
            local _,pri=pcall(function() return RARITY_ORDER[entry.rarity] end)
            lbl(dr,"Rarity: "..entry.rarity.."  |  Priority: "..(RARITY_ORDER[entry.rarity] or 1).."  |  Tool: "..entry.tool.Name,8,C.t2,{Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,8,0,0),TextWrapped=true})
            local sb=mk("TextButton",{Size=UDim2.new(0,54,0,18),Position=UDim2.new(1,-60,0.5,-9),BackgroundColor3=Color3.fromRGB(55,15,20),BorderSizePixel=0,Text="Steal",TextSize=10,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,100,120),Parent=dr})
            corner(sb,5) stroke(sb,Color3.fromRGB(255,60,80),1)
            sb.MouseButton1Click:Connect(function()
                task.spawn(function()
                    local ok,reason=stealFromPlayer(entry)
                    updatePVPStats()
                    if ok then notify("Noa Hub","Steal berhasil! "..entry.rarity.." dari "..p.Name)
                    else notify("Noa Hub",p.Name.." kabur! ("..tostring(reason)..") ") end
                    pvpRefreshGUI()
                end)
            end)
        else
            lbl(card,"Tidak membawa egg",9,C.t3,{Size=UDim2.new(0,170,0,12),Position=UDim2.new(0,42,0,22)})
        end
    end
    updatePVPStats()
end

makeButton(pgPVP,"Refresh Daftar Player",C.bg5,function() pvpRefreshGUI() end)
makeNote(pgPVP,"Mode Club membutuhkan tool pentungan di backpack. Langsung Ambil tidak memerlukan weapon.",Color3.fromRGB(40,14,16))

-- Auto refresh pvp list
task.spawn(function() while true do if activePage=="pvp" then pvpRefreshGUI() end task.wait(5) end end)

-- ── PAGE: SERVERS ─────────────────────────────────────────────────────────
lo=0
local pgSrv=pages.srv
secLabel(pgSrv,"SERVER LIST")
local srvListF=mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nextLo(),Parent=pgSrv})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=srvListF})
makeNote(pgSrv,"Belum ada server tersimpan.",C.bg2)
local srvInput=mk("TextBox",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.bg2,BorderSizePixel=0,PlaceholderText="Paste server code...",PlaceholderColor3=C.t3,Text="",TextSize=10,TextColor3=C.t0,Font=Enum.Font.Gotham,LayoutOrder=nextLo(),Parent=pgSrv})
corner(srvInput,7) stroke(srvInput,Color3.new(1,1,1),1) pad(srvInput,0,8)
local srvs={}
makeButton(pgSrv,"Tambah Server",C.bg5,function()
    local code=srvInput.Text:match("^%s*(.-)%s*$")
    if code=="" then return end
    srvs[#srvs+1]=code srvInput.Text=""
    for _,c in ipairs(srvListF:GetChildren()) do if c:IsA("TextLabel") or c:IsA("Frame") then c:Destroy() end end
    for n,s in ipairs(srvs) do
        local r=infoRow(srvListF,"Server #"..n,s:sub(1,14).."...",n)
    end
    notify("Noa Hub","Server #"..#srvs.." ditambahkan.")
end)
secLabel(pgSrv,"OPTIONS")
makeToggle(pgSrv,"Auto Hop ke Server Sepi","Pindah jika jumlah player melebihi batas",false,function(v) end)
makeToggle(pgSrv,"Rejoin Saat Kicked","Langsung rejoin server sama setelah kick",false,function(v) end)
makeSlider(pgSrv,"Batas Maks Player",2,12,6,function(v) end)
makeButton(pgSrv,"Hop ke Server Berikutnya",C.bg5,function() notify("Noa Hub","Hop ke server berikutnya...") end)
makeButton(pgSrv,"Rejoin Server Saat Ini",C.bg5,function()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,lp) end)
end)

-- ── PAGE: MISC ────────────────────────────────────────────────────────────
lo=0
local pgMisc=pages.misc
secLabel(pgMisc,"GUARDIAN")
makeToggle(pgMisc,"Anti Guardian","Noclip otomatis saat guardian mengejar",false,function(v) CFG.AntiGuardian=v end)
makeToggle(pgMisc,"Kill Guardian NPC","Set HP ke 0 saat guardian mendekat",false,function(v) CFG.KillGuardian=v end)
makeToggle(pgMisc,"Alert Guardian Dekat","Notifikasi saat guardian dalam radius tertentu",true,function(v) CFG.GuardianAlert=v end)
makeSlider(pgMisc,"Guardian Alert Radius",10,150,50,function(v) CFG.GuardianAlertR=v end)
secLabel(pgMisc,"UTILITY")
makeToggle(pgMisc,"Anti AFK","Cegah kick AFK dengan input virtual",true,function(v) CFG.AntiAFK=v end)
makeToggle(pgMisc,"Fly Mode","Terbang bebas dengan WASD + Space/Shift",false,function(v) CFG.FlyMode=v if v then enableFly() else disableFly() end end)
makeToggle(pgMisc,"Ghost Mode","Karakter transparan, tidak terlihat player lain",false,function(v) CFG.GhostMode=v end)
makeToggle(pgMisc,"Speed Burst Saat Dikejar","Speed naik ke max saat guardian mendekat",false,function(v) CFG.SpeedBurst=v end)
secLabel(pgMisc,"KONTROL CEPAT")
local qBtnF=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=nextLo(),Parent=pgMisc})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=qBtnF})
local tpBtn=mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=C.bg5,BorderSizePixel=0,Text="TP ke Base",TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,Parent=qBtnF})
corner(tpBtn,7) stroke(tpBtn,Color3.new(1,1,1),1)
tpBtn.MouseButton1Click:Connect(function() teleportTo(SHOP_POS()) notify("Noa Hub","TP ke base!") end)
local rjBtn=mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=C.bg5,BorderSizePixel=0,Text="Rejoin",TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,Parent=qBtnF})
corner(rjBtn,7) stroke(rjBtn,Color3.new(1,1,1),1)
rjBtn.MouseButton1Click:Connect(function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,lp) end) end)
makeButton(pgMisc,"Reset Karakter",C.bg5,function() if lp.Character then lp.Character:BreakJoints() end end)
makeButton(pgMisc,"Tutup Hub",Color3.fromRGB(50,20,20),function() Main.Visible=false end)

-- ── PAGE: CONFIG ──────────────────────────────────────────────────────────
lo=0
local pgCfg=pages.cfg
secLabel(pgCfg,"SAVE / LOAD")
makeButton(pgCfg,"Save Config",Color3.fromRGB(40,60,160),function()
    saveConfig() notify("Noa Hub","Config disimpan ke NoaHub_SAE.json")
end)
makeButton(pgCfg,"Load Config",C.bg5,function()
    loadConfig() notify("Noa Hub","Config dimuat dari NoaHub_SAE.json")
end)
makeButton(pgCfg,"Reset ke Default",Color3.fromRGB(55,20,20),function()
    if isfile and isfile(CONFIG_FILE) then pcall(delfile,CONFIG_FILE) end
    notify("Noa Hub","Config direset.")
end)
secLabel(pgCfg,"INFO FILE")
infoRow(pgCfg,"File Config","NoaHub_SAE.json")
infoRow(pgCfg,"Executor Support","Solara, KRNL")
infoRow(pgCfg,"Auto Load","Aktif saat inject")
secLabel(pgCfg,"KEYBINDS")
infoRow(pgCfg,"Toggle Hub","RightShift")
infoRow(pgCfg,"Panic Stop","F9")
infoRow(pgCfg,"Quick TP Base","F10")
makeNote(pgCfg,"Config menyimpan semua toggle, slider, style, dan server list. Load otomatis saat inject.",C.bg2)

-- ── INIT ─────────────────────────────────────────────────────────────────
setPage("main")
lp.CharacterAdded:Connect(function(c) task.wait(1) end)

-- ── KEYBINDS ──────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode==Enum.KeyCode.RightShift then Main.Visible=not Main.Visible end
    if i.KeyCode==Enum.KeyCode.F9 then
        -- Panic: stop all auto loops
        stopAutoSteal() stopForestDrop() stopPVPAuto()
        CFG.Noclip=false CFG.FlyMode=false disableFly()
        notify("Noa Hub","PANIC STOP: semua fungsi dihentikan.")
    end
    if i.KeyCode==Enum.KeyCode.F10 then
        teleportTo(SHOP_POS())
        notify("Noa Hub","Quick TP ke base!")
    end
end)

-- Public API
getgenv().NoaHub = {
    DetectShop=detectShopPos,
    DetectBiome=detectBiomePos,
    CFG=CFG, SaveConfig=saveConfig, LoadConfig=loadConfig,
    StartAutoSteal=startAutoSteal, StopAutoSteal=stopAutoSteal,
    StartForestDrop=startForestDrop, StopForestDrop=stopForestDrop,
    StartPVP=startPVPAuto, StopPVP=stopPVPAuto,
    TP=teleportTo, ScanPlayers=scanPlayersEggs,
}

notify("Noa Hub","v2.0 loaded \xe2\x80\x94 Steal An Egg | Auto-detect aktif")
print("[Noa Hub] v2.0 loaded. API: getgenv().NoaHub")

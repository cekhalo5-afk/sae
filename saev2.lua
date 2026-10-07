--[[
    Noa Hub v2.0 | Steal An Egg
    PlaceId : 10563114921
    Executor : Solara / KRNL+
    Author   : Noa
    
    FEATURES:
    - Auto Steal V1 / V2 dengan 5 Move Style
    - Forest Drop Mode (clone 5-fase)
    - Auto Treadmill / Upgrade Base / Treadmill / Trails
    - Auto Favorite / Index
    - Wisp Event (Update 7) — auto speed boost
    - Scramble Event — Dr. Scramble full auto
    - ESP (Egg / Guardian / Player / Box / Distance)
    - Players Steal (PVP) dengan auto mode
    - Fly Mode, Ghost Mode, Speed Burst
    - Anti Guardian, Kill Guardian, Alert
    - Anti AFK, Infinite Jump, Noclip
    - Config save/load JSON
    - Auto-detect Shop, Biome, Tools
]]

-- ══════════════════════════════════════════════════════════════════════
-- GUARD
-- ══════════════════════════════════════════════════════════════════════
local VALID = { [10563114921] = true }
if not VALID[game.PlaceId] then
    warn("[NoaHub] PlaceId " .. game.PlaceId .. " bukan Steal An Egg utama. Lanjut...")
end

-- ══════════════════════════════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")

-- ══════════════════════════════════════════════════════════════════════
-- PLAYER
-- ══════════════════════════════════════════════════════════════════════
local lp  = Players.LocalPlayer
local gui = lp:WaitForChild("PlayerGui")
local function getChar() return lp.Character end
local function getHum()  local c = getChar() return c and c:FindFirstChild("Humanoid") end
local function getHRP()  local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end

-- ══════════════════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════════════════
local CFG = {
    -- Steal
    WalkSpeed      = 200,
    JumpPower      = 50,
    Noclip         = false,
    InfJump        = false,
    AntiSlip       = false,
    StealSpeed     = 200,
    StealDelay     = 0.5,
    MoveStyle      = "Zigzag",
    AutoSteal      = false,  -- V1: no treadmill
    AutoStealV2    = false,  -- V2: with treadmill
    EggChecker     = false,
    EggPredictor   = false,
    RarityTarget   = "All",
    EggNameTarget  = "All Eggs",
    -- Auto
    AutoTreadmill  = false,
    TreadmillDur   = 3.0,
    AutoUpgradeBase      = false,
    MaxLevelBase         = 10,
    AutoUpgradeTreadmill = false,
    MaxLevelTreadmill    = 10,
    AutoUpgradeTrails    = false,
    AutoFavorite   = false,
    AutoIndex      = false,
    AutoCollectRewards = false,
    AutoEquipBestTrail = true,
    -- Forest Drop
    CloneSpeed     = 500,
    CharFreeze     = true,
    CloneNoclip    = true,
    GuardianCheck  = true,
    ForestBiome    = "Forest",
    DropStyle      = "Single",
    DropDelay      = 1.5,
    SafeDrop       = true,
    AutoTPForest   = true,
    LoopDrop       = false,
    NotifDrop      = true,
    -- ESP
    EspEgg         = false,
    EspGuardian    = false,
    EspPlayer      = false,
    BoxEsp         = false,
    NameTagEsp     = true,
    DistanceEsp    = true,
    EspRange       = 300,
    -- Misc
    AntiGuardian   = false,
    KillGuardian   = false,
    GuardianAlert  = true,
    GuardianAlertR = 50,
    AntiAFK        = true,
    FlyMode        = false,
    GhostMode      = false,
    SpeedBurst     = false,
    -- Wisp Event
    Wisp = {
        AutoCompleteQuests   = false,
        AutoClaimNet         = false,
        PrioritizeEnchanted  = true,
        AutoButterflyBloom   = false,
        AutoCatchButterflies = false,
        AutoTradeUpButterfly = true,
        AutoCraftEssence     = false,
        AutoUseEssence       = false,
        AutoWisp             = false,
        AutoBanjoCricket     = false,
        AutoHarvestBeanstalk = false,
        AutoMechBoss         = false,
        AutoClaimMastery     = false,
        ButterflyPriority    = "Radiant First",
        -- Speed: jika WalkSpeed kurang, boost otomatis
        MinSpeedRequired     = 2e10,  -- 20B
        BoostSpeed           = 5e10,  -- 50B boost sementara
    },
    -- Scramble Event
    Scramble = {
        AutoBossScramble     = false,
        AutoTradeOnce        = false,
        AutoReroll           = false,
        AutoHuntDrones       = false,
        AutoCollectParts     = false,
        AutoMastery          = false,
        WaitLastPity         = true,
        AutoPlaceEggs        = false,
        AutoBuyShop          = false,
        StockEggs            = true,
        FeedMutations        = false,
        Priority             = "Boss First",
    },
    -- PVP
    PVP = {
        Auto         = false,
        AttackMode   = "Club",
        RunAfter     = true,
        PriorityHigh = true,
        ScanRadius   = 80,
        Cooldown     = 3.0,
        Stolen       = 0,
        Attempts     = 0,
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- SAVE / LOAD
-- ══════════════════════════════════════════════════════════════════════
local CFG_FILE = "NoaHub_SAE.json"
local function saveConfig()
    if writefile then pcall(writefile, CFG_FILE, HttpService:JSONEncode(CFG)) end
end
local function loadConfig()
    if readfile and isfile and isfile(CFG_FILE) then
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
        if ok and type(d) == "table" then
            for k, v in pairs(d) do if CFG[k] ~= nil then CFG[k] = v end end
        end
    end
end
loadConfig()

-- ══════════════════════════════════════════════════════════════════════
-- NOTIFY
-- ══════════════════════════════════════════════════════════════════════
local function notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "NoaHub", Text = text or "", Duration = dur or 3
        })
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- AUTO-DETECT: SHOP & BIOME
-- ══════════════════════════════════════════════════════════════════════
local _shopPos, _biomePosCache = nil, {}

local function detectShopPos()
    if _shopPos then return _shopPos end
    -- SpawnLocation (highest priority)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("SpawnLocation") then
            _shopPos = o.Position + Vector3.new(0,3,0)
            print("[NoaHub] Shop: SpawnLocation at", _shopPos)
            return _shopPos
        end
    end
    local kw = {"shop","store","nestshop","safezone","spawn","base","treadmill","seller"}
    for _, o in ipairs(workspace:GetDescendants()) do
        local n = o.Name:lower()
        for _, k in ipairs(kw) do
            if n:find(k) then
                local p = o:IsA("BasePart") and o.Position
                    or (o:FindFirstChildWhichIsA("BasePart") or {}).Position
                if p then
                    _shopPos = p + Vector3.new(0,3,0)
                    print("[NoaHub] Shop detected:", o.Name, _shopPos)
                    return _shopPos
                end
            end
        end
    end
    local hrp = getHRP()
    _shopPos = hrp and hrp.Position or Vector3.new(0,5,0)
    warn("[NoaHub] Shop fallback to player pos")
    return _shopPos
end

local BIOME_KW = {
    Forest   = {"forest","jungle","tree","wood","enchant","leaf"},
    Plains   = {"plain","grass","meadow","field","open"},
    Mountain = {"mountain","hill","cliff","peak","snow","ice"},
}
local BIOME_FALL = {
    Forest = Vector3.new(-200,5,100),
    Plains = Vector3.new(50,5,300),
    Mountain = Vector3.new(-400,80,-150),
}

local function detectBiomePos(biome)
    if _biomePosCache[biome] then return _biomePosCache[biome] end
    local kws = BIOME_KW[biome] or {}
    for _, o in ipairs(workspace:GetChildren()) do
        if o:IsA("Folder") or o:IsA("Model") then
            local n = o.Name:lower()
            for _, k in ipairs(kws) do
                if n:find(k) then
                    local cf = o:FindFirstChildWhichIsA("BasePart")
                    if cf then
                        _biomePosCache[biome] = cf.Position + Vector3.new(0,5,0)
                        return _biomePosCache[biome]
                    end
                end
            end
        end
    end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            local n = o.Name:lower()
            for _, k in ipairs(kws) do
                if n:find(k) then
                    _biomePosCache[biome] = o.Position + Vector3.new(0,5,0)
                    return _biomePosCache[biome]
                end
            end
        end
    end
    _biomePosCache[biome] = BIOME_FALL[biome]
    return _biomePosCache[biome]
end

local function SHOP() return detectShopPos() end
local function BIOME(b) return detectBiomePos(b) end

-- ══════════════════════════════════════════════════════════════════════
-- AUTO-DETECT: TOOLS (scoring-based)
-- ══════════════════════════════════════════════════════════════════════
local function findTool(keywords)
    local best, bestScore = nil, -1
    for _, c in ipairs({ lp:FindFirstChild("Backpack"), getChar() }) do
        if c then
            for _, t in ipairs(c:GetChildren()) do
                if t:IsA("Tool") then
                    local n, score = t.Name:lower(), 0
                    for i, kw in ipairs(keywords) do
                        if n:find(kw) then score = score + (#keywords - i + 2) end
                    end
                    if score > bestScore then best, bestScore = t, score end
                end
            end
        end
    end
    return best
end

local function getStealTool()
    local c = getChar()
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("egg") then return t end
        end
    end
    return findTool({"steal","egg","grab","snatch","pick","take","swipe"})
end

local function getClubTool()
    return findTool({"pentungan","club","bonk","bat","mallet","hammer",
        "stick","weapon","attack","hit","swing","smash","whack","bop","wand","staff"})
end

local function getNetTool()
    return findTool({"net","butterfly","catch","bug","enchant"})
end

local function equipTool(t)
    local h = getHum() if h and t then h:EquipTool(t) end
end
local function unequipTools()
    local h = getHum() if h then h:UnequipTools() end
end

-- ══════════════════════════════════════════════════════════════════════
-- RARITY
-- ══════════════════════════════════════════════════════════════════════
local RARITY_PRI = { Eternal=6, Divine=5, Legendary=4, Epic=3, Rare=2, Common=1 }
local RARITY_COL = {
    Common=Color3.fromRGB(200,200,220), Rare=Color3.fromRGB(80,130,255),
    Epic=Color3.fromRGB(180,80,255), Legendary=Color3.fromRGB(255,165,40),
    Divine=Color3.fromRGB(220,100,255), Eternal=Color3.fromRGB(255,215,80),
}
local function getRarity(name)
    for r in pairs(RARITY_PRI) do if name:find(r) then return r end end
    return "Common"
end

-- ══════════════════════════════════════════════════════════════════════
-- EGG FINDER
-- ══════════════════════════════════════════════════════════════════════
local function findBestEgg(filterOverride)
    local best, bestScore, bestPos = nil, -1, nil
    local enchantedFirst = CFG.Wisp.PrioritizeEnchanted
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find("egg") then
            local r = getRarity(o.Name)
            local isEnchanted = o.Name:lower():find("enchant") and true or false
            -- Predictor filter
            if CFG.EggPredictor and r ~= "Divine" and r ~= "Eternal" then continue end
            -- Rarity target filter
            if CFG.RarityTarget ~= "All" and r ~= CFG.RarityTarget then continue end
            -- Name filter
            if CFG.EggNameTarget ~= "All Eggs" and not o.Name:lower():find(CFG.EggNameTarget:lower()) then continue end
            -- Manual override
            if filterOverride and not filterOverride(o, r, isEnchanted) then continue end
            local score = (RARITY_PRI[r] or 1) + (enchantedFirst and isEnchanted and 10 or 0)
            if score > bestScore then
                best, bestScore, bestPos = o, score, o.Position
            end
        end
    end
    return best, bestPos
end

-- ══════════════════════════════════════════════════════════════════════
-- GUARDIAN
-- ══════════════════════════════════════════════════════════════════════
local function findGuardians()
    local t = {}
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and o.Name:lower():find("guardian") then t[#t+1] = o end
    end
    return t
end
local function guardDist()
    local hrp = getHRP() if not hrp then return math.huge end
    local min = math.huge
    for _, g in ipairs(findGuardians()) do
        local r = g:FindFirstChild("HumanoidRootPart") or g:FindFirstChildWhichIsA("BasePart")
        if r then local d = (r.Position-hrp.Position).Magnitude if d < min then min = d end end
    end
    return min
end
local function guardNear(r) return guardDist() < (r or 30) end

-- ══════════════════════════════════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════════════════════════════════
local function teleportTo(pos)
    local hrp = getHRP() if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
end

local freezeBP = nil
local function freezeChar()
    local hrp = getHRP() if not hrp then return end
    if freezeBP then freezeBP:Destroy() end
    freezeBP = Instance.new("BodyPosition")
    freezeBP.Position = hrp.Position
    freezeBP.MaxForce = Vector3.new(1e9,1e9,1e9)
    freezeBP.P = 50000
    freezeBP.Parent = hrp
end
local function unfreezeChar()
    if freezeBP then freezeBP:Destroy() freezeBP = nil end
end

-- ProximityPrompt trigger (generic)
local function triggerPrompt(part, timeout)
    timeout = timeout or 3
    if not part then return false end
    local pp = part:FindFirstChildWhichIsA("ProximityPrompt")
        or part.Parent and part.Parent:FindFirstChildWhichIsA("ProximityPrompt")
    if not pp then
        for _, d in ipairs(part:GetDescendants()) do
            if d:IsA("ProximityPrompt") then pp = d break end
        end
    end
    if pp then
        fireproximityprompt(pp)
        return true
    end
    return false
end

-- Find NPC by name keywords
local function findNPC(keywords)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") then
            local n = o.Name:lower()
            for _, k in ipairs(keywords) do
                if n:find(k) then return o end
            end
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════════
-- MOVE STYLES
-- ══════════════════════════════════════════════════════════════════════
local function moveTween(pos, speed, cb)
    local hrp = getHRP() if not hrp then if cb then cb() end return end
    local d = (hrp.Position - pos).Magnitude
    local t = TweenService:Create(hrp, TweenInfo.new(d / speed, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(pos + Vector3.new(0,3,0)) })
    t:Play()
    t.Completed:Connect(function() if cb then cb() end end)
end

local function moveInstant(pos, cb)
    teleportTo(pos)
    if cb then cb() end
end

local function moveZigzag(pos, speed, cb)
    task.spawn(function()
        local hrp = getHRP() if not hrp then if cb then cb() end return end
        local dir  = (pos - hrp.Position).Unit
        local perp = Vector3.new(-dir.Z, 0, dir.X)
        local dist = (hrp.Position - pos).Magnitude
        local step = math.max(dist / 6, 1)
        for i = 1, 6 do
            hrp = getHRP() if not hrp then break end
            local off = perp * (i % 2 == 0 and 5 or -5)
            local tgt = hrp.Position + dir * step + off
            tgt = Vector3.new(tgt.X, pos.Y + 3, tgt.Z)
            local tw = TweenService:Create(hrp, TweenInfo.new(step / speed,
                Enum.EasingStyle.Linear), { CFrame = CFrame.new(tgt) })
            tw:Play() tw.Completed:Wait()
        end
        hrp = getHRP()
        if hrp then
            local tf = TweenService:Create(hrp, TweenInfo.new(0.3),
                { CFrame = CFrame.new(pos + Vector3.new(0,3,0)) })
            tf:Play() tf.Completed:Wait()
        end
        if cb then cb() end
    end)
end

local function moveFly(pos, speed, cb)
    task.spawn(function()
        local hrp = getHRP() if not hrp then if cb then cb() end return end
        local h = 30
        local pts = {
            hrp.Position + Vector3.new(0, h, 0),
            pos + Vector3.new(0, h, 0),
            pos + Vector3.new(0, 3, 0),
        }
        for _, p in ipairs(pts) do
            local tw = TweenService:Create(hrp, TweenInfo.new(1.2, Enum.EasingStyle.Quad),
                { CFrame = CFrame.new(p) })
            tw:Play() tw.Completed:Wait()
        end
        if cb then cb() end
    end)
end

local function moveByStyle(pos, cb)
    local s, sp = CFG.MoveStyle, CFG.StealSpeed
    if s == "Tween"   then moveTween(pos, sp, cb)
    elseif s == "Instant" then moveInstant(pos, cb)
    elseif s == "Fly" then moveFly(pos, sp, cb)
    else moveZigzag(pos, sp, cb) end
end

-- ══════════════════════════════════════════════════════════════════════
-- FOREST DROP CYCLE
-- ══════════════════════════════════════════════════════════════════════
local forestDropActive = false
local forestDropThread = nil

local function forestDrop_cycle()
    local savedPos = getHRP() and getHRP().Position or SHOP()
    if CFG.CharFreeze then freezeChar() end

    local egg, eggPos = findBestEgg()
    if not egg then
        notify("NoaHub", "Egg tidak ditemukan.")
        unfreezeChar() return false
    end

    unfreezeChar()
    local hum = getHum()
    if hum then hum.WalkSpeed = CFG.CloneSpeed end

    local nc
    if CFG.CloneNoclip then
        nc = RunService.Stepped:Connect(function()
            local c = getChar() if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end)
    end

    moveZigzag(eggPos + Vector3.new(0,3,0), CFG.CloneSpeed, nil) task.wait(0.5)
    local tool = getStealTool() if tool then equipTool(tool) task.wait(0.3) end

    local fp = BIOME(CFG.ForestBiome)
    if CFG.GuardianCheck then
        local w = 0 while guardNear(40) and w < 10 do task.wait(1) w += 1 end
    end

    moveZigzag(fp, CFG.CloneSpeed, nil) task.wait(0.8)
    unequipTools() task.wait(CFG.DropDelay)
    if CFG.NotifDrop then notify("NoaHub", "Egg di-drop di " .. CFG.ForestBiome .. "!") end

    task.wait(0.5)
    local tool2 = getStealTool() if tool2 then equipTool(tool2) task.wait(0.3) end

    local style = CFG.MoveStyle
    CFG.MoveStyle = "Tween"
    moveByStyle(savedPos, function()
        unequipTools()
        if CFG.NotifDrop then notify("NoaHub", "Egg diserahkan!") end
    end)
    CFG.MoveStyle = style

    if nc then nc:Disconnect() end
    local hrp2 = getHRP()
    if hrp2 then hrp2.CFrame = CFrame.new(savedPos + Vector3.new(0,3,0)) end
    local hum2 = getHum()
    if hum2 then hum2.WalkSpeed = CFG.WalkSpeed end
    return true
end

local function startForestDrop()
    if forestDropActive then return end forestDropActive = true
    forestDropThread = task.spawn(function()
        while forestDropActive do
            pcall(forestDrop_cycle)
            if not CFG.LoopDrop then forestDropActive = false break end
            task.wait(1)
        end
    end)
end
local function stopForestDrop()
    forestDropActive = false
    if forestDropThread then task.cancel(forestDropThread) forestDropThread = nil end
    unfreezeChar()
    local h = getHum() if h then h.WalkSpeed = CFG.WalkSpeed end
end

-- ══════════════════════════════════════════════════════════════════════
-- AUTO STEAL V1 / V2
-- ══════════════════════════════════════════════════════════════════════
local autoStealActive = false
local autoStealThread = nil

local function doTreadmill()
    for _, o in ipairs(workspace:GetDescendants()) do
        if o.Name:lower():find("treadmill") and o:IsA("BasePart") then
            teleportTo(o.Position)
            task.wait(CFG.TreadmillDur)
            return
        end
    end
end

local function autoSteal_cycle(withTreadmill)
    if CFG.MoveStyle == "ForestDrop" then
        return forestDrop_cycle()
    end
    local egg, eggPos = findBestEgg()
    if not egg then task.wait(1) return false end

    local h = getHum() if h then h.WalkSpeed = CFG.StealSpeed end
    moveByStyle(eggPos, nil) task.wait(CFG.StealDelay)

    local t = getStealTool() if t then equipTool(t) task.wait(0.3) end

    moveTween(SHOP(), CFG.StealSpeed, function() unequipTools() end)
    task.wait(0.5)

    if withTreadmill then doTreadmill() end

    local h2 = getHum() if h2 then h2.WalkSpeed = CFG.WalkSpeed end
    return true
end

local function startAutoSteal(v2)
    if autoStealActive then return end autoStealActive = true
    autoStealThread = task.spawn(function()
        while autoStealActive do
            pcall(autoSteal_cycle, v2 or false)
            task.wait(0.5)
        end
    end)
end
local function stopAutoSteal()
    autoStealActive = false
    if autoStealThread then task.cancel(autoStealThread) autoStealThread = nil end
    local h = getHum() if h then h.WalkSpeed = CFG.WalkSpeed end
end

-- ══════════════════════════════════════════════════════════════════════
-- NOCLIP / SPEED / JUMP
-- ══════════════════════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if CFG.Noclip or (CFG.AntiGuardian and guardNear(25)) then
        local c = getChar() if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local h = getHum() if not h then return end
    if not autoStealActive and not forestDropActive then
        h.WalkSpeed = CFG.WalkSpeed
        h.JumpPower = CFG.JumpPower
    end
    if CFG.SpeedBurst and guardNear(CFG.GuardianAlertR) then h.WalkSpeed = 600 end
end)

UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump then
        local h = getHum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- FLY MODE
-- ══════════════════════════════════════════════════════════════════════
local flyBV, flyBG
local function enableFly()
    local hrp = getHRP() if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5,1e5,1e5) flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5) flyBG.P = 1e4
    flyBG.Parent = hrp
end
local function disableFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end
RunService.Heartbeat:Connect(function()
    if not CFG.FlyMode or not flyBV then return end
    local cam = workspace.CurrentCamera
    local dir = Vector3.zero
    local KD = UserInputService.IsKeyDown
    local UIS = UserInputService
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
    flyBV.Velocity = dir * CFG.WalkSpeed
    if flyBG then flyBG.CFrame = cam.CFrame end
end)

-- ══════════════════════════════════════════════════════════════════════
-- GHOST MODE
-- ══════════════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    local c = getChar() if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = CFG.GhostMode and 0.8 or 0
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- ANTI AFK
-- ══════════════════════════════════════════════════════════════════════
lp.Idled:Connect(function()
    if not CFG.AntiAFK then return end
    VirtualUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
end)

-- ══════════════════════════════════════════════════════════════════════
-- GUARDIAN SYSTEMS
-- ══════════════════════════════════════════════════════════════════════
local guardAlertCD = false
RunService.Heartbeat:Connect(function()
    if CFG.GuardianAlert and not guardAlertCD and guardNear(CFG.GuardianAlertR) then
        guardAlertCD = true
        notify("NoaHub", "⚠ GUARDIAN DEKAT! " .. math.floor(guardDist()) .. " studs", 2)
        task.wait(5) guardAlertCD = false
    end
    if CFG.KillGuardian then
        for _, g in ipairs(findGuardians()) do
            local gh = g:FindFirstChildWhichIsA("Humanoid")
            local gr = g:FindFirstChild("HumanoidRootPart")
            local hrp = getHRP()
            if gh and gr and hrp and (gr.Position-hrp.Position).Magnitude < 30 then
                gh.Health = 0
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- AUTO PAGE FEATURES
-- ══════════════════════════════════════════════════════════════════════
-- Auto Treadmill (standalone loop)
local autoTreadmillThread = nil
local function startAutoTreadmill()
    if autoTreadmillThread then return end
    autoTreadmillThread = task.spawn(function()
        while CFG.AutoTreadmill do
            doTreadmill()
            task.wait(1)
        end
        autoTreadmillThread = nil
    end)
end

-- Auto Upgrade: finds ProximityPrompts near upgrade UI
local function findUpgradePrompt(keywords)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ProximityPrompt") then
            local n = o.ActionText:lower() .. (o.ObjectText and o.ObjectText:lower() or "")
                .. (o.Parent and o.Parent.Name:lower() or "")
            for _, k in ipairs(keywords) do
                if n:find(k) then return o end
            end
        end
    end
    return nil
end

local upgradeThread = nil
local function runAutoUpgrade()
    if upgradeThread then return end
    upgradeThread = task.spawn(function()
        while CFG.AutoUpgradeBase or CFG.AutoUpgradeTreadmill or CFG.AutoUpgradeTrails do
            if CFG.AutoUpgradeBase then
                local pp = findUpgradePrompt({"upgrade","base","upgrade base"})
                if pp then
                    local lvlPart = pp.Parent and pp.Parent:FindFirstChild("Level")
                    local lvl = lvlPart and tonumber(lvlPart.Value) or 0
                    if lvl < CFG.MaxLevelBase then
                        pcall(fireproximityprompt, pp)
                        task.wait(0.5)
                    end
                end
            end
            if CFG.AutoUpgradeTreadmill then
                local pp = findUpgradePrompt({"upgrade","treadmill"})
                if pp then
                    local lvlPart = pp.Parent and pp.Parent:FindFirstChild("Level")
                    local lvl = lvlPart and tonumber(lvlPart.Value) or 0
                    if lvl < CFG.MaxLevelTreadmill then
                        pcall(fireproximityprompt, pp)
                        task.wait(0.5)
                    end
                end
            end
            if CFG.AutoUpgradeTrails then
                local pp = findUpgradePrompt({"trail","upgrade trail"})
                if pp then pcall(fireproximityprompt, pp) task.wait(0.5) end
            end
            task.wait(2)
        end
        upgradeThread = nil
    end)
end

-- Auto Favorite: marks eggs with rarity >= threshold
local function autoFavorite()
    task.spawn(function()
        while CFG.AutoFavorite do
            local c = getChar()
            if c then
                for _, t in ipairs(c:GetChildren()) do
                    if t:IsA("Tool") and t.Name:lower():find("egg") then
                        local r = getRarity(t.Name)
                        if (RARITY_PRI[r] or 0) >= (RARITY_PRI["Legendary"] or 4) then
                            local fav = t:FindFirstChild("Favorite")
                            if fav then fav.Value = true end
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end

-- Auto Index: claim index rewards
local function autoIndex()
    task.spawn(function()
        while CFG.AutoIndex do
            local pp = findUpgradePrompt({"index","claim","reward"})
            if pp then pcall(fireproximityprompt, pp) task.wait(1) end
            task.wait(5)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- WISP EVENT SYSTEM (Update 7 — Enchanted Forest)
-- ══════════════════════════════════════════════════════════════════════

-- Speed booster: if WalkSpeed < minRequired, boost temporarily
local wispSpeedBoosted = false
local function ensureWispSpeed()
    local h = getHum()
    if not h then return function() end end
    if h.WalkSpeed < CFG.Wisp.MinSpeedRequired then
        local original = CFG.WalkSpeed
        h.WalkSpeed = CFG.Wisp.BoostSpeed
        wispSpeedBoosted = true
        notify("NoaHub", "Speed di-boost ke " .. string.format("%.0fB", CFG.Wisp.BoostSpeed/1e9) .. " untuk Wisp!", 3)
        return function()
            -- Restore after use
            if wispSpeedBoosted then
                local h2 = getHum()
                if h2 then h2.WalkSpeed = original end
                wispSpeedBoosted = false
            end
        end
    end
    return function() end -- no-op restore
end

-- Find Wisp NPC
local function findWispNPC()
    return findNPC({"wisp","enchant.*npc","forest.*npc","spirit"})
end

-- Auto Wisp: approach and interact
local function autoWisp_step()
    local restore = ensureWispSpeed()
    local npc = findWispNPC()
    if npc then
        local root = npc:FindFirstChild("HumanoidRootPart")
            or npc:FindFirstChildWhichIsA("BasePart")
        if root then
            teleportTo(root.Position)
            task.wait(0.3)
            triggerPrompt(root)
            task.wait(0.5)
        end
    else
        -- Go to Enchanted Forest area and scan
        teleportTo(BIOME("Forest"))
        task.wait(1)
        npc = findWispNPC()
        if npc then
            local root = npc:FindFirstChildWhichIsA("BasePart")
            if root then teleportTo(root.Position) task.wait(0.3) triggerPrompt(root) end
        end
    end
    restore()
end

-- Auto Complete Wisp Quests:
-- Quest 1: steal 20 enchanted eggs
-- Quest 2: fuse 1 enchanted pet at Fuse Machine
-- Quest 3: steal 1 Eternal egg
local wispQuestsDone = { 0, false, false }

local function autoCompleteWispQuests()
    task.spawn(function()
        while CFG.Wisp.AutoCompleteQuests do
            -- Quest 1: steal enchanted eggs
            if wispQuestsDone[1] < 20 then
                local restore = ensureWispSpeed()
                local egg, pos = findBestEgg(function(o, r, isEnchanted)
                    return isEnchanted
                end)
                if egg and pos then
                    moveZigzag(pos, CFG.CloneSpeed, nil) task.wait(0.5)
                    local t = getStealTool() if t then equipTool(t) task.wait(0.3) end
                    moveTween(SHOP(), CFG.StealSpeed, function() unequipTools() end)
                    task.wait(0.5)
                    wispQuestsDone[1] += 1
                    notify("NoaHub", "Enchanted egg stolen: " .. wispQuestsDone[1] .. "/20")
                end
                restore()
            end
            -- Quest 2: fuse at Fuse Machine
            if not wispQuestsDone[2] then
                local fuseMachine = findNPC({"fuse","fusion","machine"})
                if fuseMachine then
                    local root = fuseMachine:FindFirstChildWhichIsA("BasePart")
                    if root then
                        teleportTo(root.Position) task.wait(0.3)
                        triggerPrompt(root)
                        task.wait(1)
                        wispQuestsDone[2] = true
                        notify("NoaHub", "Fuse Machine quest done!")
                    end
                end
            end
            -- Quest 3: steal Eternal egg
            if not wispQuestsDone[3] then
                local egg, pos = findBestEgg(function(o, r) return r == "Eternal" end)
                if egg and pos then
                    moveZigzag(pos, CFG.CloneSpeed, nil) task.wait(0.5)
                    local t = getStealTool() if t then equipTool(t) task.wait(0.3) end
                    moveTween(SHOP(), CFG.StealSpeed, function() unequipTools() end)
                    task.wait(0.5)
                    wispQuestsDone[3] = true
                    notify("NoaHub", "Eternal egg quest done!")
                end
            end
            -- All done → claim net
            if wispQuestsDone[1] >= 20 and wispQuestsDone[2] and wispQuestsDone[3] then
                if CFG.Wisp.AutoClaimNet then
                    local tree = findNPC({"enchant.*tree","wisp.*tree","butterfly.*tree"})
                    if tree then
                        local root = tree:FindFirstChildWhichIsA("BasePart")
                        if root then
                            teleportTo(root.Position) task.wait(0.3)
                            triggerPrompt(root) task.wait(1)
                            notify("NoaHub", "Butterfly Net claimed!")
                        end
                    end
                end
            end
            task.wait(2)
        end
    end)
end

-- Butterfly Bloom: catch butterflies with net
local butterflyCounts = { Emerald=0, Sapphire=0, Amethyst=0, Radiant=0 }

local function catchButterfly(butterfly)
    local root = butterfly:FindFirstChildWhichIsA("BasePart") or butterfly
    if not root then return end
    local restore = ensureWispSpeed()
    teleportTo(root.Position) task.wait(0.2)
    local net = getNetTool()
    if net then
        equipTool(net) task.wait(0.2)
        pcall(function() net:Activate() end)
        task.wait(0.3)
        -- Detect butterfly tier from name
        local n = butterfly.Name:lower()
        if n:find("radiant") then butterflyCounts.Radiant += 1
        elseif n:find("amethyst") then butterflyCounts.Amethyst += 1
        elseif n:find("sapphire") then butterflyCounts.Sapphire += 1
        else butterflyCounts.Emerald += 1 end
    end
    unequipTools()
    restore()
end

local function autoCatchButterflies()
    task.spawn(function()
        while CFG.Wisp.AutoCatchButterflies do
            local kws = {"butterfly","butterfli","moth","wisp.*fly"}
            -- Priority order based on CFG.Wisp.ButterflyPriority
            local priority = CFG.Wisp.ButterflyPriority
            local found = {}
            for _, o in ipairs(workspace:GetDescendants()) do
                if (o:IsA("Model") or o:IsA("BasePart")) then
                    local n = o.Name:lower()
                    for _, k in ipairs(kws) do
                        if n:find(k) then found[#found+1] = o break end
                    end
                end
            end
            -- Sort by priority
            table.sort(found, function(a, b)
                local function score(obj)
                    local n = obj.Name:lower()
                    if priority == "Radiant First" then
                        if n:find("radiant") then return 4
                        elseif n:find("amethyst") then return 3
                        elseif n:find("sapphire") then return 2
                        else return 1 end
                    end
                    return 1
                end
                return score(a) > score(b)
            end)
            for _, b in ipairs(found) do
                if not CFG.Wisp.AutoCatchButterflies then break end
                pcall(catchButterfly, b)
                task.wait(0.5)
            end
            task.wait(2)
        end
    end)
end

-- Auto Trade Up Butterflies: 10 Emerald→Sapphire, 10 Sapphire→Amethyst, 50 Amethyst→Radiant
local function autoTradeUpButterflies()
    task.spawn(function()
        while CFG.Wisp.AutoTradeUpButterfly do
            local shrine = findNPC({"shrine","butterfly.*trade","trade.*butterfly","wisp.*shrine"})
            if shrine then
                local root = shrine:FindFirstChildWhichIsA("BasePart")
                if root then
                    teleportTo(root.Position) task.wait(0.3)
                    -- Trade Emerald → Sapphire (10:1)
                    while butterflyCounts.Emerald >= 10 do
                        triggerPrompt(root) task.wait(0.3)
                        butterflyCounts.Emerald -= 10
                        butterflyCounts.Sapphire += 1
                    end
                    -- Trade Sapphire → Amethyst (10:1)
                    while butterflyCounts.Sapphire >= 10 do
                        triggerPrompt(root) task.wait(0.3)
                        butterflyCounts.Sapphire -= 10
                        butterflyCounts.Amethyst += 1
                    end
                    -- Trade Amethyst → Radiant (50:1)
                    while butterflyCounts.Amethyst >= 50 do
                        triggerPrompt(root) task.wait(0.3)
                        butterflyCounts.Amethyst -= 50
                        butterflyCounts.Radiant += 1
                    end
                end
            end
            task.wait(5)
        end
    end)
end

-- Auto Craft Essence: 240 Emerald + 115 Sapphire + 40 Amethyst + 1 Radiant = 1 Essence
local essenceCrafted = 0
local function autoCraftEssence()
    task.spawn(function()
        while CFG.Wisp.AutoCraftEssence do
            local canCraft = butterflyCounts.Emerald >= 240
                and butterflyCounts.Sapphire >= 115
                and butterflyCounts.Amethyst >= 40
                and butterflyCounts.Radiant >= 1
            if canCraft then
                local shrine = findNPC({"shrine","essence","craft","enchant.*craft"})
                if shrine then
                    local root = shrine:FindFirstChildWhichIsA("BasePart")
                    if root then
                        teleportTo(root.Position) task.wait(0.3)
                        triggerPrompt(root) task.wait(0.5)
                        butterflyCounts.Emerald -= 240
                        butterflyCounts.Sapphire -= 115
                        butterflyCounts.Amethyst -= 40
                        butterflyCounts.Radiant -= 1
                        essenceCrafted += 1
                        notify("NoaHub", "Enchanted Essence #" .. essenceCrafted .. " crafted!")
                    end
                end
            end
            task.wait(3)
        end
    end)
end

-- Auto Use Enchanted Essence (100% mutation)
local mutationsDone = 0
local function autoUseEssence()
    task.spawn(function()
        while CFG.Wisp.AutoUseEssence do
            if essenceCrafted > 0 then
                local shrine = findNPC({"mutation.*shrine","enchant.*shrine","use.*essence"})
                if shrine then
                    local root = shrine:FindFirstChildWhichIsA("BasePart")
                    if root then
                        teleportTo(root.Position) task.wait(0.3)
                        triggerPrompt(root) task.wait(1)
                        essenceCrafted -= 1
                        mutationsDone += 1
                        notify("NoaHub", "Enchanted mutation #" .. mutationsDone .. " applied!")
                    end
                end
            end
            task.wait(5)
        end
    end)
end

-- Auto Banjo Cricket
local function autoBanjoCricket()
    task.spawn(function()
        while CFG.Wisp.AutoBanjoCricket do
            local npc = findNPC({"banjo","cricket","banjo.*cricket"})
            if npc then
                local root = npc:FindFirstChildWhichIsA("BasePart")
                if root then
                    teleportTo(root.Position) task.wait(0.3)
                    triggerPrompt(root) task.wait(2)
                end
            end
            task.wait(10)
        end
    end)
end

-- Auto Harvest Giant Beanstalk
local function autoHarvestBeanstalk()
    task.spawn(function()
        while CFG.Wisp.AutoHarvestBeanstalk do
            local bean = findNPC({"beanstalk","bean","giant.*bean","harvest"})
            if not bean then
                for _, o in ipairs(workspace:GetDescendants()) do
                    if o:IsA("BasePart") and o.Name:lower():find("bean") then
                        bean = o break
                    end
                end
            end
            if bean then
                local root = bean:IsA("Model") and bean:FindFirstChildWhichIsA("BasePart") or bean
                if root then
                    teleportTo(root.Position) task.wait(0.3)
                    triggerPrompt(root) task.wait(2)
                    notify("NoaHub", "Giant Beanstalk harvested!")
                end
            end
            task.wait(15)
        end
    end)
end

-- Auto Mech Boss (Wisp)
local function autoMechBoss()
    task.spawn(function()
        while CFG.Wisp.AutoMechBoss do
            local boss = findNPC({"mech","mech.*boss","robot.*boss","mechanic"})
            if boss then
                local root = boss:FindFirstChild("HumanoidRootPart")
                    or boss:FindFirstChildWhichIsA("BasePart")
                if root then
                    local restore = ensureWispSpeed()
                    teleportTo(root.Position + Vector3.new(5,3,0))
                    -- Attack with available tool
                    local atk = getClubTool()
                    if atk then
                        equipTool(atk) task.wait(0.2)
                        for _ = 1, 10 do
                            pcall(function() atk:Activate() end)
                            task.wait(0.4)
                            local bHum = boss:FindFirstChildWhichIsA("Humanoid")
                            if bHum and bHum.Health <= 0 then break end
                        end
                        unequipTools()
                    end
                    restore()
                    task.wait(2)
                end
            end
            task.wait(5)
        end
    end)
end

-- Master Wisp loop
local wispThread = nil
local function startWispEvent()
    if wispThread then return end
    wispThread = task.spawn(function()
        notify("NoaHub", "Wisp Event dimulai!")
        -- Start all enabled sub-features concurrently
        if CFG.Wisp.AutoWisp then task.spawn(function()
            while CFG.Wisp.AutoWisp do autoWisp_step() task.wait(10) end
        end) end
        if CFG.Wisp.AutoCompleteQuests then autoCompleteWispQuests() end
        if CFG.Wisp.AutoCatchButterflies then autoCatchButterflies() end
        if CFG.Wisp.AutoTradeUpButterfly then autoTradeUpButterflies() end
        if CFG.Wisp.AutoCraftEssence then autoCraftEssence() end
        if CFG.Wisp.AutoUseEssence then autoUseEssence() end
        if CFG.Wisp.AutoBanjoCricket then autoBanjoCricket() end
        if CFG.Wisp.AutoHarvestBeanstalk then autoHarvestBeanstalk() end
        if CFG.Wisp.AutoMechBoss then autoMechBoss() end
    end)
end
local function stopWispEvent()
    if wispThread then task.cancel(wispThread) wispThread = nil end
    notify("NoaHub", "Wisp Event dihentikan.")
end

-- ══════════════════════════════════════════════════════════════════════
-- SCRAMBLE EVENT SYSTEM
-- ══════════════════════════════════════════════════════════════════════
local scramblesThread = nil
local scrambleStats = { boss=0, drone=0, parts=0, trade=0 }

-- Auto Boss Scramble
local function autoBossScramble()
    local boss = findNPC({"dr.*scramble","scramble.*boss","scramble","doctor.*scram"})
    if not boss then return false end
    local root = boss:FindFirstChild("HumanoidRootPart")
        or boss:FindFirstChildWhichIsA("BasePart")
    if not root then return false end
    teleportTo(root.Position + Vector3.new(4,3,0))
    task.wait(0.3)
    local club = getClubTool()
    if club then
        equipTool(club) task.wait(0.2)
        local bHum = boss:FindFirstChildWhichIsA("Humanoid")
        for _ = 1, 15 do
            if bHum and bHum.Health <= 0 then break end
            pcall(function() club:Activate() end)
            task.wait(0.35)
        end
        unequipTools()
        if bHum and bHum.Health <= 0 then
            scrambleStats.boss += 1
            notify("NoaHub", "Boss Scramble #" .. scrambleStats.boss .. " defeated!")
            return true
        end
    else
        -- No club — try proximity prompt
        triggerPrompt(root) task.wait(1)
    end
    return false
end

-- Auto Hunt Drones
local function autoHuntDrones()
    local droneKW = {"drone","scramble.*drone","flying.*part","mech.*drone"}
    local found = {}
    for _, o in ipairs(workspace:GetDescendants()) do
        local n = o.Name:lower()
        for _, k in ipairs(droneKW) do
            if n:find(k) and (o:IsA("Model") or o:IsA("BasePart")) then
                found[#found+1] = o break
            end
        end
    end
    for _, d in ipairs(found) do
        local root = d:IsA("Model") and d:FindFirstChildWhichIsA("BasePart") or d
        if root then
            teleportTo(root.Position) task.wait(0.2)
            triggerPrompt(root)
            scrambleStats.drone += 1
            task.wait(0.5)
        end
    end
end

-- Auto Collect Lost Parts
local function autoCollectLostParts()
    local partKW = {"lost.*part","scramble.*part","part.*scramble","lost","broken.*part"}
    for _, o in ipairs(workspace:GetDescendants()) do
        local n = o.Name:lower()
        for _, k in ipairs(partKW) do
            if n:find(k) and o:IsA("BasePart") then
                teleportTo(o.Position) task.wait(0.2)
                triggerPrompt(o)
                scrambleStats.parts += 1
                task.wait(0.3)
                break
            end
        end
    end
end

-- Auto Trade in Lab
local function autoTradeInOnce()
    local lab = findNPC({"lab","scramble.*lab","dr.*lab","machine.*lab"})
    if not lab then return end
    local root = lab:FindFirstChildWhichIsA("BasePart")
    if root then
        teleportTo(root.Position) task.wait(0.3)
        -- Wait at last pity if enabled
        if CFG.Scramble.WaitLastPity then
            local pityVal = 0
            local pityObj = lab:FindFirstChild("Pity") or lab:FindFirstChild("PityValue")
            if pityObj then pityVal = tonumber(pityObj.Value) or 0 end
            -- If not at pity, trade normally; if WaitLastPity and low pity, hold
            if pityVal < 90 and CFG.Scramble.WaitLastPity then
                -- Continue trading until near pity
            end
        end
        triggerPrompt(root) task.wait(1)
        scrambleStats.trade += 1
        notify("NoaHub", "Lab trade #" .. scrambleStats.trade .. " done!")
    end
end

-- Master Scramble loop
local function startScrambleEvent()
    if scramblesThread then return end
    scramblesThread = task.spawn(function()
        notify("NoaHub", "Scramble Event dimulai!")
        while true do
            -- Priority system
            local prio = CFG.Scramble.Priority
            if prio == "Boss First" then
                if CFG.Scramble.AutoBossScramble then pcall(autoBossScramble) task.wait(1) end
                if CFG.Scramble.AutoHuntDrones then pcall(autoHuntDrones) task.wait(1) end
                if CFG.Scramble.AutoCollectParts then pcall(autoCollectLostParts) task.wait(1) end
                if CFG.Scramble.AutoTradeOnce then pcall(autoTradeInOnce) task.wait(1) end
            elseif prio == "Drone First" then
                if CFG.Scramble.AutoHuntDrones then pcall(autoHuntDrones) task.wait(1) end
                if CFG.Scramble.AutoBossScramble then pcall(autoBossScramble) task.wait(1) end
                if CFG.Scramble.AutoCollectParts then pcall(autoCollectLostParts) task.wait(1) end
                if CFG.Scramble.AutoTradeOnce then pcall(autoTradeInOnce) task.wait(1) end
            elseif prio == "Trade First" then
                if CFG.Scramble.AutoTradeOnce then pcall(autoTradeInOnce) task.wait(1) end
                if CFG.Scramble.AutoBossScramble then pcall(autoBossScramble) task.wait(1) end
                if CFG.Scramble.AutoHuntDrones then pcall(autoHuntDrones) task.wait(1) end
                if CFG.Scramble.AutoCollectParts then pcall(autoCollectLostParts) task.wait(1) end
            elseif prio == "Parts First" then
                if CFG.Scramble.AutoCollectParts then pcall(autoCollectLostParts) task.wait(1) end
                if CFG.Scramble.AutoBossScramble then pcall(autoBossScramble) task.wait(1) end
                if CFG.Scramble.AutoHuntDrones then pcall(autoHuntDrones) task.wait(1) end
                if CFG.Scramble.AutoTradeOnce then pcall(autoTradeInOnce) task.wait(1) end
            else -- Balanced
                if CFG.Scramble.AutoBossScramble then pcall(autoBossScramble) task.wait(0.5) end
                if CFG.Scramble.AutoHuntDrones then pcall(autoHuntDrones) task.wait(0.5) end
                if CFG.Scramble.AutoCollectParts then pcall(autoCollectLostParts) task.wait(0.5) end
                if CFG.Scramble.AutoTradeOnce then pcall(autoTradeInOnce) task.wait(0.5) end
            end
            -- Other features
            if CFG.Scramble.AutoMastery then
                local pp = findUpgradePrompt({"mastery","scramble.*mastery","claim"})
                if pp then pcall(fireproximityprompt, pp) task.wait(0.5) end
            end
            if CFG.Scramble.AutoBuyShop then
                local shop = findNPC({"scramble.*shop","event.*shop","mutation.*shop"})
                if shop then
                    local root = shop:FindFirstChildWhichIsA("BasePart")
                    if root then
                        teleportTo(root.Position) task.wait(0.3)
                        triggerPrompt(root) task.wait(0.5)
                    end
                end
            end
            task.wait(3)
        end
    end)
end
local function stopScrambleEvent()
    if scramblesThread then task.cancel(scramblesThread) scramblesThread = nil end
    notify("NoaHub", "Scramble Event dihentikan.")
end

-- ══════════════════════════════════════════════════════════════════════
-- ESP
-- ══════════════════════════════════════════════════════════════════════
local espBills = {}
local function clearESP()
    for _, b in ipairs(espBills) do if b and b.Parent then b:Destroy() end end
    espBills = {}
end
local function makeESP(part, text, color, dist)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 90, 0, 22)
    bb.StudsOffset = Vector3.new(0,4,0)
    bb.AlwaysOnTop = true
    bb.Parent = part
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = CFG.DistanceEsp and (text .. " [" .. math.floor(dist) .. "s]") or text
    lbl.TextColor3 = color or Color3.new(1,1,1)
    lbl.TextStrokeTransparency = 0
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.Parent = bb
    espBills[#espBills+1] = bb
    if CFG.BoxEsp then
        local box = Instance.new("SelectionBox")
        box.Color3 = color box.LineThickness = 0.05
        box.SurfaceTransparency = 0.85
        box.Adornee = part box.Parent = bb
    end
end

RunService.Heartbeat:Connect(function()
    clearESP()
    local hrp = getHRP() if not hrp then return end
    if CFG.EspEgg then
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and o.Name:lower():find("egg") then
                local r = getRarity(o.Name)
                local d = (o.Position - hrp.Position).Magnitude
                if d <= CFG.EspRange then
                    makeESP(o, r, RARITY_COL[r] or Color3.new(1,1,1), d)
                end
            end
        end
    end
    if CFG.EspGuardian then
        for _, g in ipairs(findGuardians()) do
            local r = g:FindFirstChild("HumanoidRootPart") or g:FindFirstChildWhichIsA("BasePart")
            if r then
                local d = (r.Position - hrp.Position).Magnitude
                if d <= CFG.EspRange then makeESP(r, "GUARDIAN", Color3.fromRGB(255,70,70), d) end
            end
        end
    end
    if CFG.EspPlayer then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (r.Position - hrp.Position).Magnitude
                    if d <= CFG.EspRange then makeESP(r, p.Name, Color3.fromRGB(80,140,255), d) end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- PVP SYSTEM
-- ══════════════════════════════════════════════════════════════════════
local pvpThread = nil

local function scanPlayersEggs()
    local res = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local egg = nil
            for _, it in ipairs(p.Character:GetChildren()) do
                if it:IsA("Tool") and it.Name:lower():find("egg") then egg = it break end
            end
            if not egg then
                local bp = p:FindFirstChild("Backpack")
                if bp then
                    for _, it in ipairs(bp:GetChildren()) do
                        if it:IsA("Tool") and it.Name:lower():find("egg") then egg = it break end
                    end
                end
            end
            local r = egg and getRarity(egg.Name)
            res[#res+1] = { player=p, tool=egg, rarity=r, priority=egg and (RARITY_PRI[r] or 1) or 0 }
        end
    end
    if CFG.PVP.PriorityHigh then
        table.sort(res, function(a,b) return a.priority > b.priority end)
    end
    return res
end

local function stealFromPlayer(entry)
    if not entry.tool then return false, "no_egg" end
    local tgt = entry.player
    CFG.PVP.Attempts += 1
    local tHRP = tgt.Character and tgt.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return false, "no_char" end
    -- Attack
    local club = getClubTool()
    if club then
        local h = getHum() if h then h.WalkSpeed = CFG.StealSpeed * 1.5 end
        teleportTo(tHRP.Position + Vector3.new(2,0,0)) task.wait(0.15)
        equipTool(club) task.wait(0.2)
        for _ = 1, 3 do
            pcall(function() club:Activate() end) task.wait(0.35)
            local still = false
            for _, it in ipairs(tgt.Character:GetChildren()) do
                if it:IsA("Tool") and it.Name:lower():find("egg") then still=true break end
            end
            if not still then break end
        end
        unequipTools()
    else
        teleportTo(tHRP.Position) task.wait(0.2)
    end
    -- Find dropped egg
    local closestEgg, closestDist = entry.tool, 15
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find("egg") then
            local d = (o.Position - tHRP.Position).Magnitude
            if d < closestDist then closestEgg = o closestDist = d end
        end
    end
    if closestEgg then
        teleportTo(closestEgg.Position) task.wait(0.2)
        local st = getStealTool() if st then equipTool(st) task.wait(0.3) end
        if CFG.PVP.RunAfter then
            local h2 = getHum() if h2 then h2.WalkSpeed = CFG.StealSpeed end
            moveZigzag(SHOP(), CFG.StealSpeed, function()
                unequipTools()
                CFG.PVP.Stolen += 1
                notify("NoaHub", "Curi " .. (entry.rarity or "?") .. " dari " .. tgt.Name)
            end)
        else
            CFG.PVP.Stolen += 1
        end
        return true, "success"
    end
    return false, "egg_not_found"
end

local function startPVPAuto()
    if CFG.PVP.Auto then return end CFG.PVP.Auto = true
    pvpThread = task.spawn(function()
        while CFG.PVP.Auto do
            local list = scanPlayersEggs()
            for _, e in ipairs(list) do
                if e.tool then pcall(stealFromPlayer, e) break end
            end
            task.wait(CFG.PVP.Cooldown)
        end
    end)
    notify("NoaHub", "Auto PVP aktif!")
end
local function stopPVPAuto()
    CFG.PVP.Auto = false
    if pvpThread then task.cancel(pvpThread) pvpThread = nil end
    local h = getHum() if h then h.WalkSpeed = CFG.WalkSpeed end
    notify("NoaHub", "Auto PVP dihentikan.")
end

-- ══════════════════════════════════════════════════════════════════════
-- GUI CONSTANTS & HELPERS
-- ══════════════════════════════════════════════════════════════════════
if gui:FindFirstChild("NoaHub") then gui.NoaHub:Destroy() end

local C = {
    bg0=Color3.fromRGB(7,7,15),   bg1=Color3.fromRGB(11,11,22),
    bg2=Color3.fromRGB(14,14,28), bg3=Color3.fromRGB(22,22,40),
    bg5=Color3.fromRGB(28,28,52),
    a1=Color3.fromRGB(96,128,255), a2=Color3.fromRGB(64,200,184),
    t0=Color3.fromRGB(238,240,255), t1=Color3.fromRGB(136,144,204),
    t2=Color3.fromRGB(85,88,128), t3=Color3.fromRGB(48,48,74),
    green=Color3.fromRGB(64,200,100), red=Color3.fromRGB(255,64,96),
    gold=Color3.fromRGB(240,192,96), wisp=Color3.fromRGB(96,224,160),
    scramble=Color3.fromRGB(240,160,64),
}

local function mk(cls, props)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    return o
end
local function corner(p, r)
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0,r or 8) c.Parent = p return c
end
local function stk(p, col, th)
    local s = Instance.new("UIStroke") s.Color = col or C.t3 s.Thickness = th or 1
    s.Transparency = 0.85 s.Parent = p return s
end
local function lbl(p, text, sz, col, props)
    local l = mk("TextLabel",{Text=text or "",TextSize=sz or 11,TextColor3=col or C.t0,
        Font=Enum.Font.GothamBold,BackgroundTransparency=1,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=p})
    if props then for k,v in pairs(props) do l[k]=v end end
    return l
end
local function pad(p, t, l2, r, b)
    local u = Instance.new("UIPadding")
    if t then u.PaddingTop=UDim.new(0,t) end if l2 then u.PaddingLeft=UDim.new(0,l2) end
    if r then u.PaddingRight=UDim.new(0,r) end if b then u.PaddingBottom=UDim.new(0,b) end
    u.Parent = p return u
end

-- ══════════════════════════════════════════════════════════════════════
-- SCREEN GUI & MAIN FRAME
-- ══════════════════════════════════════════════════════════════════════
local ScreenGui = mk("ScreenGui",{
    Name="NoaHub",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    DisplayOrder=999,Parent=gui
})

local Main = mk("Frame",{
    Size=UDim2.new(0,520,0,375),Position=UDim2.new(0.5,-260,0.5,-187.5),
    BackgroundColor3=C.bg1,BorderSizePixel=0,Parent=ScreenGui
})
corner(Main,12) stk(Main,C.a1,1)

-- accent line bottom
mk("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(96,128,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(64,200,184))
}),Rotation=90,Parent=mk("Frame",{
    Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=Main
})})

-- NH Toggle Button
local NHBtn = mk("TextButton",{
    Size=UDim2.new(0,42,0,90),Position=UDim2.new(0,-52,0.5,-45),
    BackgroundColor3=C.bg0,BorderSizePixel=0,Text="",Parent=Main
})
corner(NHBtn,12)
stk(NHBtn,C.a1,1)
lbl(NHBtn,"N",15,C.a1,{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,10),
    TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold})
lbl(NHBtn,"H",15,C.a2,{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,44),
    TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBold})
local nhDot = mk("Frame",{Size=UDim2.new(0,7,0,7),Position=UDim2.new(0.5,-3.5,1,-14),
    BackgroundColor3=C.green,BorderSizePixel=0,Parent=NHBtn})
corner(nhDot,10)

-- Title Bar
local TitleBar = mk("Frame",{
    Size=UDim2.new(1,0,0,40),BackgroundColor3=C.bg0,BorderSizePixel=0,Parent=Main
})
corner(TitleBar,12)
mk("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=C.bg0,BorderSizePixel=0,Parent=TitleBar})
-- accent line
mk("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=C.a1,BorderSizePixel=0,BackgroundTransparency=0.55,Parent=TitleBar})

for i,dc in ipairs({Color3.fromRGB(255,80,80),Color3.fromRGB(240,176,40),Color3.fromRGB(64,200,80)}) do
    local dot = mk("TextButton",{Size=UDim2.new(0,10,0,10),
        Position=UDim2.new(0,8+(i-1)*16,0.5,-5),
        BackgroundColor3=dc,BorderSizePixel=0,Text="",Parent=TitleBar})
    corner(dot,10)
    if i == 1 then dot.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end) end
end

lbl(TitleBar,"Noa Hub",12,C.t0,{Size=UDim2.new(0,80,1,0),Position=UDim2.new(0,58,0,0)})
lbl(TitleBar,"v2.0 \xc2\xb7 Steal An Egg",9,C.t2,{Size=UDim2.new(0,160,1,0),Position=UDim2.new(0,140,0,0)})

-- Close button (minus)
local CloseBtn = mk("TextButton",{
    Size=UDim2.new(0,30,0,22),Position=UDim2.new(1,-38,0.5,-11),
    BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,
    BorderSizePixel=0,Text="\xe2\x80\x94",TextSize=12,TextColor3=C.t2,
    Font=Enum.Font.GothamBold,Parent=TitleBar
})
corner(CloseBtn,6) stk(CloseBtn,Color3.new(1,1,1),1)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible=not Main.Visible end)
CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3=Color3.fromRGB(80,20,24) CloseBtn.BackgroundTransparency=0.4
    CloseBtn.TextColor3=Color3.fromRGB(255,120,130)
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3=Color3.fromRGB(0,0,0) CloseBtn.BackgroundTransparency=0.5
    CloseBtn.TextColor3=C.t2
end)

-- NH toggle
NHBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    nhDot.BackgroundColor3 = Main.Visible and C.green or C.t3
end)

-- Drag
local drag,dragStart,startPos
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag=true dragStart=i.Position startPos=Main.Position
    end
end)
TitleBar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- SIDEBAR & CONTENT
-- ══════════════════════════════════════════════════════════════════════
local Sidebar = mk("Frame",{
    Size=UDim2.new(0,120,1,-40),Position=UDim2.new(0,0,0,40),
    BackgroundColor3=C.bg0,BorderSizePixel=0,Parent=Main
})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2),Parent=Sidebar})
pad(Sidebar,8,5,5,8)
mk("Frame",{Size=UDim2.new(0,1,1,-40),Position=UDim2.new(0,120,0,40),
    BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.93,BorderSizePixel=0,Parent=Main})

local Content = mk("Frame",{
    Size=UDim2.new(1,-121,1,-40),Position=UDim2.new(0,121,0,40),
    BackgroundColor3=C.bg1,BorderSizePixel=0,Parent=Main
})

local pages,navBtns,activePage = {},{},nil
local PAGE_DEFS = {
    {id="main",   label="Main"},
    {id="auto2",  label="Auto"},
    {id="esp",    label="ESP"},
    {id="forest", label="Forest Biome"},
    {id="pvp",    label="Players Steal"},
    {id="event",  label="Event"},
    {id="srv",    label="Private Server"},
    {id="misc",   label="Misc"},
    {id="cfg",    label="Config"},
}

local function setPage(id)
    for pid,page in pairs(pages) do page.Visible=(pid==id) end
    for pid,btn in pairs(navBtns) do
        local on = (pid==id)
        btn.BackgroundColor3 = on and C.bg3 or C.bg0
        btn.BackgroundTransparency = on and 0 or 1
        btn.TextColor3 = on and C.t0 or C.t2
        local ab = btn:FindFirstChildWhichIsA("Frame")
        if ab then ab.Visible=on end
    end
    activePage=id
end

local function makeDiv(order)
    return mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.new(1,1,1),
        BackgroundTransparency=0.93,BorderSizePixel=0,LayoutOrder=order,Parent=Sidebar})
end

for i,def in ipairs(PAGE_DEFS) do
    if def.id=="forest" or def.id=="srv" then makeDiv(i*2-1) end
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,28),BackgroundColor3=C.bg0,BackgroundTransparency=1,
        BorderSizePixel=0,Text=def.label,TextSize=10,TextColor3=C.t2,
        Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,
        LayoutOrder=i*2,Parent=Sidebar
    })
    pad(btn,0,10)
    corner(btn,5)
    local accentColor = (def.id=="pvp") and Color3.fromRGB(255,80,80)
        or (def.id=="event") and C.gold
        or C.a1
    local ab = mk("Frame",{Size=UDim2.new(0,2,0.6,0),Position=UDim2.new(0,0,0.2,0),
        BackgroundColor3=accentColor,BorderSizePixel=0,Visible=false,Parent=btn})
    corner(ab,2)
    navBtns[def.id]=btn
    local page = mk("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
        ScrollBarThickness=3,ScrollBarImageColor3=C.a1,Visible=false,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0),Parent=Content
    })
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=page})
    pad(page,8,8,8,10)
    pages[def.id]=page
    btn.MouseButton1Click:Connect(function()
        setPage(def.id)
        if def.id=="pvp" then task.spawn(pvpRefreshGUI) end
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- UI COMPONENT HELPERS
-- ══════════════════════════════════════════════════════════════════════
local lo = 0
local function nlo() lo+=1 return lo end

local function secLabel(parent, text, accentCol, order)
    local f = mk("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=order or nlo(),Parent=parent})
    lbl(f,text,9,accentCol or C.a1,{Size=UDim2.new(0,130,1,0),TextTransparency=0.3,Font=Enum.Font.GothamBold})
    mk("Frame",{Size=UDim2.new(1,-138,0,1),Position=UDim2.new(0,136,0.5,0),
        BackgroundColor3=accentCol or C.a1,BackgroundTransparency=0.72,BorderSizePixel=0,Parent=f})
    return f
end

local function makeToggle(parent, labelTxt, subTxt, default, onChange, order)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=order or nlo(),Parent=parent})
    corner(row,7) stk(row,Color3.new(1,1,1),1)
    lbl(row,labelTxt,11,C.t0,{Size=UDim2.new(0,220,0,15),Position=UDim2.new(0,10,0,4)})
    if subTxt then lbl(row,subTxt,9,C.t2,{Size=UDim2.new(0,220,0,12),Position=UDim2.new(0,10,0,18)}) end
    local track = mk("TextButton",{
        Size=UDim2.new(0,32,0,17),Position=UDim2.new(1,-44,0.5,-8),
        BackgroundColor3=default and C.a1 or C.bg5,BorderSizePixel=0,Text="",Parent=row
    })
    corner(track,9)
    local thumb = mk("Frame",{
        Size=UDim2.new(0,11,0,11),
        Position=default and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=track
    })
    corner(thumb,10)
    local state = default or false
    track.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track,TweenInfo.new(0.12),{BackgroundColor3=state and C.a1 or C.bg5}):Play()
        TweenService:Create(thumb,TweenInfo.new(0.12),{Position=state and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5)}):Play()
        if onChange then onChange(state) end
    end)
    return track
end

local function makeSlider(parent, labelTxt, min_, max_, default, onChange, order, isFloat)
    local f = mk("Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=order or nlo(),Parent=parent})
    corner(f,7) stk(f,Color3.new(1,1,1),1)
    local valL = lbl(f,tostring(default),11,C.a1,{Size=UDim2.new(0,55,0,16),Position=UDim2.new(1,-63,0,8),TextXAlignment=Enum.TextXAlignment.Right})
    lbl(f,labelTxt,11,C.t0,{Size=UDim2.new(0,190,0,16),Position=UDim2.new(0,10,0,8)})
    local track = mk("Frame",{Size=UDim2.new(1,-20,0,4),Position=UDim2.new(0,10,0,34),BackgroundColor3=C.bg5,BorderSizePixel=0,Parent=f})
    corner(track,2)
    local fill = mk("Frame",{Size=UDim2.new((default-min_)/(max_-min_),0,1,0),BackgroundColor3=C.a1,BorderSizePixel=0,Parent=track})
    corner(fill,2)
    local ds = false
    local function upd(inp)
        local rx = math.clamp((inp.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v = isFloat and (math.floor((min_+rx*(max_-min_))*10+0.5)/10) or math.floor(min_+rx*(max_-min_))
        fill.Size = UDim2.new(rx,0,1,0)
        valL.Text = tostring(v)
        if onChange then onChange(v) end
    end
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true upd(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end end)
    UserInputService.InputChanged:Connect(function(i) if ds and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i) end end)
    return f
end

local function makeButton(parent, text, col, onClick, order)
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,30),BackgroundColor3=col or C.bg3,BorderSizePixel=0,
        Text=text,TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,
        LayoutOrder=order or nlo(),Parent=parent
    })
    corner(btn,7) stk(btn,Color3.new(1,1,1),1)
    btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return btn
end

local function makeNote(parent, text, col, order)
    local f = mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=col or C.bg2,BorderSizePixel=0,LayoutOrder=order or nlo(),Parent=parent})
    corner(f,7) stk(f,Color3.new(1,1,1),1)
    mk("TextLabel",{Size=UDim2.new(1,-16,0,0),Position=UDim2.new(0,8,0,6),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,Text=text,TextSize=9,TextColor3=C.t2,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Parent=f})
    pad(f,0,0,0,6)
    return f
end

local function infoRow(parent, key, val, order)
    local r = mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=order or nlo(),Parent=parent})
    corner(r,6) stk(r,Color3.new(1,1,1),1)
    lbl(r,key,10,C.t2,{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,10,0,0)})
    lbl(r,val,10,C.t0,{Size=UDim2.new(0.5,-10,1,0),Position=UDim2.new(0.5,0,0,0),TextXAlignment=Enum.TextXAlignment.Right})
    return r
end

-- Expandable section button
local function makeSectionBtn(parent, text, panelId, col, order)
    local btn = mk("TextButton",{
        Size=UDim2.new(1,0,0,34),BackgroundColor3=C.bg2,BorderSizePixel=0,
        Text=text,TextSize=11,TextColor3=col or C.t0,Font=Enum.Font.GothamBold,
        LayoutOrder=order or nlo(),Parent=parent
    })
    corner(btn,7)
    mk("UIStroke",{Color=col or C.a1,Thickness=1,Transparency=0.6,Parent=btn})
    mk("Frame",{Size=UDim2.new(0,2,0.6,0),Position=UDim2.new(0,0,0.2,0),
        BackgroundColor3=col or C.a1,BorderSizePixel=0,Parent=btn})
    local arrL = lbl(btn,"\xe2\x96\xbc",10,col or C.a1,{
        Size=UDim2.new(0,18,1,0),Position=UDim2.new(1,-20,0,0),
        TextXAlignment=Enum.TextXAlignment.Center
    })
    return btn, arrL
end

local function makePanel(parent, col, order)
    local panel = mk("Frame",{
        Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=C.bg0,BorderSizePixel=0,LayoutOrder=order or nlo(),
        Visible=false,Parent=parent
    })
    corner(panel,7)
    mk("UIStroke",{Color=col or C.a1,Thickness=1,Transparency=0.75,Parent=panel})
    mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=panel})
    pad(panel,7,7,7,7)
    return panel
end

local function connectSectionToggle(btn, panel, arrL)
    btn.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
        if arrL then
            arrL.Text = panel.Visible and "\xe2\x96\xb2" or "\xe2\x96\xbc"
        end
    end)
end

-- Toggle row for dark panels
local function makeToggleSub(parent, labelTxt, subTxt, default, onChange, order)
    local row = mk("Frame",{Size=UDim2.new(1,0,0,32),BackgroundColor3=Color3.fromRGB(20,20,36),
        BorderSizePixel=0,LayoutOrder=order or nlo(),Parent=parent})
    corner(row,6) stk(row,Color3.new(1,1,1),1)
    lbl(row,labelTxt,11,C.t0,{Size=UDim2.new(0,215,0,15),Position=UDim2.new(0,9,0,4)})
    if subTxt then lbl(row,subTxt,9,C.t2,{Size=UDim2.new(0,215,0,12),Position=UDim2.new(0,9,0,18)}) end
    local track = mk("TextButton",{
        Size=UDim2.new(0,32,0,17),Position=UDim2.new(1,-42,0.5,-8),
        BackgroundColor3=default and C.a1 or C.bg5,BorderSizePixel=0,Text="",Parent=row
    })
    corner(track,9)
    local thumb = mk("Frame",{
        Size=UDim2.new(0,11,0,11),
        Position=default and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=track
    })
    corner(thumb,10)
    local state = default or false
    track.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track,TweenInfo.new(0.12),{BackgroundColor3=state and C.a1 or C.bg5}):Play()
        TweenService:Create(thumb,TweenInfo.new(0.12),{Position=state and UDim2.new(1,-14,0.5,-5) or UDim2.new(0,3,0.5,-5)}):Play()
        if onChange then onChange(state) end
    end)
    return track
end

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: MAIN
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgMain = pages.main

-- Steal Menu (collapsible)
local stealBtn, stealArr = makeSectionBtn(pgMain,"  Steal Menu",nil,C.a1)
local stealPanel = makePanel(pgMain,C.a1)
connectSectionToggle(stealBtn,stealPanel,stealArr)

-- Steal Move selector
local stealMoveVal = "Zigzag"
local moveLabel = lbl(stealPanel,"Steal Move",11,C.t0,{Size=UDim2.new(0.5,0,0,28),Position=UDim2.new(0,0,0,0),LayoutOrder=nlo()})
local moveStyles = {"Zigzag","Tween","Instant","Fly","Forest Drop"}
local moveStyleF = mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=stealPanel})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=moveStyleF})
local moveBtns = {}
for _, sn in ipairs(moveStyles) do
    local sb = mk("TextButton",{Size=UDim2.new(0,62,0,24),BackgroundColor3=sn=="Zigzag" and C.a1 or C.bg5,
        BorderSizePixel=0,Text=sn,TextSize=9,TextColor3=sn=="Zigzag" and Color3.new(1,1,1) or C.t2,
        Font=Enum.Font.Gotham,Parent=moveStyleF})
    corner(sb,12) moveBtns[sn]=sb
    sb.MouseButton1Click:Connect(function()
        stealMoveVal = sn
        CFG.MoveStyle = sn == "Forest Drop" and "ForestDrop" or sn
        for sid,sbtn in pairs(moveBtns) do
            sbtn.BackgroundColor3=(sid==sn) and C.a1 or C.bg5
            sbtn.TextColor3=(sid==sn) and Color3.new(1,1,1) or C.t2
        end
    end)
end

local divRow1 = mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.9,BorderSizePixel=0,LayoutOrder=nlo(),Parent=stealPanel})

makeToggleSub(stealPanel,"Auto Steal","Mencuri telur tetapi tidak langsung treadmill",false,function(v)
    CFG.AutoSteal=v
    if v then startAutoSteal(false) else stopAutoSteal() end
end)
makeToggleSub(stealPanel,"Auto Steal V2","Mencuri telur dan langsung treadmill setelah mencuri",false,function(v)
    CFG.AutoStealV2=v
    if v then startAutoSteal(true) else stopAutoSteal() end
end)

local divRow2 = mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.9,BorderSizePixel=0,LayoutOrder=nlo(),Parent=stealPanel})

-- Rarity Steal selector
local rarityF = mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=stealPanel})
lbl(rarityF,"Rarity Steal",11,C.t0,{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,0,0,0)})
local rarities = {"All","Common","Rare","Epic","Legendary","Divine","Eternal"}
local rarIdx = 1
local rarBadge = mk("TextButton",{Size=UDim2.new(0.5,-5,0,22),Position=UDim2.new(0.5,0,0.5,-11),
    BackgroundColor3=Color3.fromRGB(20,20,40),BorderSizePixel=0,Text="[ Unknown ]",
    TextSize=10,TextColor3=C.a1,Font=Enum.Font.GothamBold,Parent=rarityF})
corner(rarBadge,6) stk(rarBadge,C.a1,1)
rarBadge.MouseButton1Click:Connect(function()
    rarIdx = (rarIdx % #rarities) + 1
    CFG.RarityTarget = rarities[rarIdx]
    rarBadge.Text = "[ " .. rarities[rarIdx] .. " ]"
end)

-- Name Egg selector
local nameF = mk("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=stealPanel})
lbl(nameF,"Name Egg",11,C.t0,{Size=UDim2.new(0.5,0,1,0),Position=UDim2.new(0,0,0,0)})
local eggNames = {"All Eggs","Common Egg","Rare Egg","Epic Egg","Legendary Egg","Divine Egg","Eternal Egg","Enchanted Egg"}
local eggIdx = 1
local eggBadge = mk("TextButton",{Size=UDim2.new(0.5,-5,0,22),Position=UDim2.new(0.5,0,0.5,-11),
    BackgroundColor3=Color3.fromRGB(20,20,40),BorderSizePixel=0,Text="[ Unknown ]",
    TextSize=10,TextColor3=C.a1,Font=Enum.Font.GothamBold,Parent=nameF})
corner(eggBadge,6) stk(eggBadge,C.a1,1)
eggBadge.MouseButton1Click:Connect(function()
    eggIdx = (eggIdx % #eggNames) + 1
    CFG.EggNameTarget = eggNames[eggIdx]
    eggBadge.Text = "[ " .. eggNames[eggIdx] .. " ]"
end)

-- Movement
secLabel(pgMain,"MOVEMENT")
makeSlider(pgMain,"Walk Speed",16,600,200,function(v) CFG.WalkSpeed=v end)
makeSlider(pgMain,"Jump Power",0,200,50,function(v) CFG.JumpPower=v end)
makeToggle(pgMain,"Noclip","Menembus semua objek dan dinding di map",false,function(v) CFG.Noclip=v end)
makeToggle(pgMain,"Infinite Jump","Loncat tanpa batas",false,function(v) CFG.InfJump=v end)
makeToggle(pgMain,"Anti Slip","Cegah karakter terpeleset",false,function(v) CFG.AntiSlip=v end)

secLabel(pgMain,"TREADMILL")
makeToggle(pgMain,"Auto Treadmill","Ke treadmill setelah steal",false,function(v)
    CFG.AutoTreadmill=v if v then startAutoTreadmill() end
end)
makeSlider(pgMain,"Durasi Treadmill (det)",1,15,3,function(v) CFG.TreadmillDur=v end,nil,true)

makeNote(pgMain,"Walk Speed 200-350 untuk aman. Speed di-boost otomatis saat Wisp Event aktif jika kurang dari 20B.")

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: AUTO
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgAuto = pages.auto2
secLabel(pgAuto,"TREADMILL")
makeToggle(pgAuto,"Auto Treadmill","Pergi ke treadmill otomatis setelah steal",false,function(v)
    CFG.AutoTreadmill=v if v then startAutoTreadmill() end
end)
makeSlider(pgAuto,"Durasi di Treadmill (det)",1,15,3,function(v) CFG.TreadmillDur=v end,nil,true)

secLabel(pgAuto,"UPGRADE")
makeToggle(pgAuto,"Auto Upgrade Base","Upgrade base otomatis saat resource tersedia",false,function(v)
    CFG.AutoUpgradeBase=v if v then runAutoUpgrade() end
end)
makeSlider(pgAuto,"Max Level Base",1,20,10,function(v) CFG.MaxLevelBase=v end)
makeToggle(pgAuto,"Auto Upgrade Treadmill","Upgrade treadmill otomatis",false,function(v)
    CFG.AutoUpgradeTreadmill=v if v then runAutoUpgrade() end
end)
makeSlider(pgAuto,"Max Level Treadmill",1,20,10,function(v) CFG.MaxLevelTreadmill=v end)
makeToggle(pgAuto,"Auto Upgrade Trails","Beli dan upgrade trail terbaik",false,function(v)
    CFG.AutoUpgradeTrails=v if v then runAutoUpgrade() end
end)

secLabel(pgAuto,"COLLECT & INDEX")
makeToggle(pgAuto,"Auto Favorite","Favorite egg Legendary+ otomatis",false,function(v)
    CFG.AutoFavorite=v if v then autoFavorite() end
end)
makeToggle(pgAuto,"Auto Index","Claim Index reward otomatis",false,function(v)
    CFG.AutoIndex=v if v then autoIndex() end
end)
makeToggle(pgAuto,"Auto Collect Rewards","Ambil semua reward harian dan quest",false,function(v) CFG.AutoCollectRewards=v end)
makeToggle(pgAuto,"Auto Equip Best Trail","Selalu pakai trail nilai terbaik",true,function(v) CFG.AutoEquipBestTrail=v end)

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: ESP
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgEsp = pages.esp
secLabel(pgEsp,"HIGHLIGHT")
makeToggle(pgEsp,"Egg ESP","Warna sesuai rarity",false,function(v) CFG.EspEgg=v end)
makeToggle(pgEsp,"Guardian ESP","Highlight guardian merah",false,function(v) CFG.EspGuardian=v end)
makeToggle(pgEsp,"Player ESP","Highlight player biru",false,function(v) CFG.EspPlayer=v end)
secLabel(pgEsp,"TAMPILAN")
makeToggle(pgEsp,"Box ESP","Kotak seleksi di sekeliling target",false,function(v) CFG.BoxEsp=v end)
makeToggle(pgEsp,"Name Tag","Tampilkan nama di atas target",true,function(v) CFG.NameTagEsp=v end)
makeToggle(pgEsp,"Jarak ESP","Tampilkan jarak studs",true,function(v) CFG.DistanceEsp=v end)
makeSlider(pgEsp,"Range ESP (studs)",50,500,300,function(v) CFG.EspRange=v end)
makeNote(pgEsp,"Common=Putih | Rare=Biru | Epic=Ungu | Legendary=Orange | Divine=Magenta | Eternal=Gold | Enchanted=Teal")

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: FOREST BIOME
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgForest = pages.forest
local fHdr = mk("Frame",{Size=UDim2.new(1,0,0,52),BackgroundColor3=Color3.fromRGB(12,24,14),
    LayoutOrder=nlo(),BorderSizePixel=0,Parent=pgForest})
corner(fHdr,7) stk(fHdr,C.green,1) pad(fHdr,6,8,8,6)
local fStatRow = mk("Frame",{Size=UDim2.new(1,0,0,36),BackgroundTransparency=1,Parent=fHdr})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=fStatRow})
local fDropLbl,fRateLbl,fTimeLbl
for _,s in ipairs({{"DROPPED","0"},{"PER JAM","0"},{"SESI","00:00"}}) do
    local sf = mk("Frame",{Size=UDim2.new(0.33,-4,1,0),BackgroundColor3=Color3.fromRGB(16,28,16),BorderSizePixel=0,Parent=fStatRow})
    corner(sf,5)
    local nl = mk("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,
        Text=s[2],TextSize=14,Font=Enum.Font.GothamBold,TextColor3=C.green,Parent=sf})
    lbl(sf,s[1],8,C.t2,{Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,1,-14),TextXAlignment=Enum.TextXAlignment.Center})
    if s[1]=="DROPPED" then fDropLbl=nl elseif s[1]=="PER JAM" then fRateLbl=nl else fTimeLbl=nl end
end

secLabel(pgForest,"PENGATURAN",C.green)
makeSlider(pgForest,"Drop Delay (det)",0,10,1.5,function(v) CFG.DropDelay=v end,nil,true)
makeToggle(pgForest,"Safe Drop","Tunggu guardian pergi dulu",true,function(v) CFG.SafeDrop=v end)
makeToggle(pgForest,"Auto TP ke Biome","TP sebelum mulai",true,function(v) CFG.AutoTPForest=v end)
makeToggle(pgForest,"Loop Setelah Drop","Steal lagi setelah cycle",false,function(v) CFG.LoopDrop=v end)
makeToggle(pgForest,"Notifikasi Drop","Popup tiap berhasil drop",true,function(v) CFG.NotifDrop=v end)

secLabel(pgForest,"KONTROL",C.green)
makeButton(pgForest,"Mulai Forest Drop",Color3.fromRGB(35,85,35),function()
    if CFG.AutoTPForest then teleportTo(BIOME(CFG.ForestBiome)) end
    startForestDrop()
    local start=tick()
    task.spawn(function()
        local cnt=0
        while forestDropActive do
            cnt+=1 if fDropLbl then fDropLbl.Text=tostring(cnt) end
            local el=math.floor(tick()-start)
            if fTimeLbl then fTimeLbl.Text=string.format("%02d:%02d",el//60,el%60) end
            local h=el/3600
            if fRateLbl then fRateLbl.Text=h>0 and tostring(math.floor(cnt/h)) or tostring(cnt) end
            task.wait(3)
        end
    end)
    notify("NoaHub","Forest Drop dimulai!")
end)
makeButton(pgForest,"Stop Forest Drop",Color3.fromRGB(60,25,30),function()
    stopForestDrop()
    notify("NoaHub","Forest Drop dihentikan.")
end)
makeButton(pgForest,"TP ke Biome Sekarang",C.bg5,function()
    teleportTo(BIOME(CFG.ForestBiome))
    notify("NoaHub","Teleport ke " .. CFG.ForestBiome)
end)

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: PLAYERS STEAL (PVP)
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgPVP = pages.pvp

local pvpHdr = mk("Frame",{Size=UDim2.new(1,0,0,54),BackgroundColor3=Color3.fromRGB(24,8,10),
    LayoutOrder=nlo(),BorderSizePixel=0,Parent=pgPVP})
corner(pvpHdr,7) stk(pvpHdr,C.red,1) pad(pvpHdr,6,8,8,6)
lbl(pvpHdr,"Players Steal",11,Color3.fromRGB(255,80,100),{Size=UDim2.new(0.6,0,0,18),Font=Enum.Font.GothamBold})
lbl(pvpHdr,"Serang, curi egg, kabur",9,C.t2,{Size=UDim2.new(0.6,0,0,14),Position=UDim2.new(0,0,0,20)})
local pvpStatRow = mk("Frame",{Size=UDim2.new(0.38,0,1,-6),Position=UDim2.new(0.62,0,0,3),BackgroundTransparency=1,Parent=pvpHdr})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=pvpStatRow})
local pvpStolenLbl,pvpAttemptLbl,pvpRateLbl
for _,s in ipairs({{"CURI","0"},{"COBA","0"},{"OK","0%"}}) do
    local sf = mk("Frame",{Size=UDim2.new(0.33,-3,1,0),BackgroundColor3=Color3.fromRGB(30,12,14),BorderSizePixel=0,Parent=pvpStatRow})
    corner(sf,5)
    local nl = mk("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,
        Text=s[2],TextSize=13,Font=Enum.Font.GothamBold,TextColor3=C.red,Parent=sf})
    lbl(sf,s[1],7,C.t2,{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-13),TextXAlignment=Enum.TextXAlignment.Center})
    if s[1]=="CURI" then pvpStolenLbl=nl elseif s[1]=="COBA" then pvpAttemptLbl=nl else pvpRateLbl=nl end
end

local function updatePVPStats()
    if pvpStolenLbl then pvpStolenLbl.Text=tostring(CFG.PVP.Stolen) end
    if pvpAttemptLbl then pvpAttemptLbl.Text=tostring(CFG.PVP.Attempts) end
    if pvpRateLbl then pvpRateLbl.Text=CFG.PVP.Attempts>0 and math.floor(CFG.PVP.Stolen/CFG.PVP.Attempts*100).."%"or"0%" end
end

secLabel(pgPVP,"AUTO & PENGATURAN",C.red)
makeToggle(pgPVP,"Auto Steal Players","Cari dan serang player yang bawa egg",false,function(v)
    if v then startPVPAuto() else stopPVPAuto() end
end)
makeToggle(pgPVP,"Priority Rarity Tinggi","Eternal > Divine > Legendary duluan",true,function(v) CFG.PVP.PriorityHigh=v end)
makeToggle(pgPVP,"Kabur ke Base Otomatis","Lari setelah dapat egg",true,function(v) CFG.PVP.RunAfter=v end)
makeSlider(pgPVP,"Scan Radius (studs)",10,150,80,function(v) CFG.PVP.ScanRadius=v end)
makeSlider(pgPVP,"Cooldown (det)",1,15,3,function(v) CFG.PVP.Cooldown=v end,nil,true)

secLabel(pgPVP,"PLAYERS ONLINE",C.red)
local pvpListF = mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,LayoutOrder=nlo(),Parent=pgPVP})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=pvpListF})
local pvpCards = {}

function pvpRefreshGUI()
    for _,c in ipairs(pvpCards) do if c.Parent then c:Destroy() end end
    pvpCards = {}
    local list = scanPlayersEggs()
    if #list==0 then makeNote(pvpListF,"Tidak ada player online.",C.bg2,1) return end
    for i,entry in ipairs(list) do
        local p = entry.player
        local rc = entry.rarity and (RARITY_COL[entry.rarity] or C.t1) or C.t3
        local card = mk("Frame",{Size=UDim2.new(1,0,0,entry.tool and 58 or 36),
            BackgroundColor3=C.bg2,BorderSizePixel=0,LayoutOrder=i,Parent=pvpListF})
        corner(card,6) stk(card,Color3.new(1,1,1),1)
        pvpCards[#pvpCards+1]=card
        local av = mk("TextLabel",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(0,7,0,5),
            BackgroundColor3=C.bg5,BorderSizePixel=0,Text=p.Name:sub(1,2):upper(),
            TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.t1,Parent=card})
        corner(av,6)
        lbl(card,p.Name,11,C.t0,{Size=UDim2.new(0,170,0,16),Position=UDim2.new(0,41,0,5),Font=Enum.Font.GothamBold})
        if entry.tool then
            lbl(card,entry.tool.Name,9,rc,{Size=UDim2.new(0,170,0,12),Position=UDim2.new(0,41,0,21)})
            local badge = mk("TextLabel",{Size=UDim2.new(0,62,0,15),Position=UDim2.new(1,-68,0,5),
                BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,
                Text=(entry.rarity or "?"):upper(),TextSize=8,Font=Enum.Font.GothamBold,TextColor3=rc,Parent=card})
            corner(badge,8) stk(badge,rc,1)
            local dr = mk("Frame",{Size=UDim2.new(1,-14,0,22),Position=UDim2.new(0,7,0,34),
                BackgroundColor3=C.bg5,BorderSizePixel=0,Parent=card})
            corner(dr,5)
            lbl(dr,"Rarity: "..(entry.rarity or "?").."  |  Priority: "..(RARITY_PRI[entry.rarity]or 1),8,C.t2,
                {Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,7,0,0),TextWrapped=true})
            local sb = mk("TextButton",{Size=UDim2.new(0,52,0,18),Position=UDim2.new(1,-58,0.5,-9),
                BackgroundColor3=Color3.fromRGB(55,15,20),BorderSizePixel=0,Text="Steal",
                TextSize=10,Font=Enum.Font.GothamBold,TextColor3=Color3.fromRGB(255,100,120),Parent=dr})
            corner(sb,5) stk(sb,C.red,1)
            sb.MouseButton1Click:Connect(function()
                task.spawn(function()
                    local ok,reason = stealFromPlayer(entry)
                    updatePVPStats()
                    notify("NoaHub",ok and "Steal berhasil dari "..p.Name or p.Name.." kabur! ("..tostring(reason)..")")
                    pvpRefreshGUI()
                end)
            end)
        else
            lbl(card,"Tidak membawa egg",9,C.t3,{Size=UDim2.new(0,170,0,12),Position=UDim2.new(0,41,0,21)})
        end
    end
    updatePVPStats()
end

makeButton(pgPVP,"Refresh Daftar Player",C.bg5,function() pvpRefreshGUI() end)
task.spawn(function() while true do if activePage=="pvp" then pvpRefreshGUI() end task.wait(5) end end)

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: EVENT
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgEvent = pages.event

-- Wisp Event Section
local wispBtn, wispArr = makeSectionBtn(pgEvent,"  Wisp Event (Update 7)",nil,C.wisp)
local wispPanel = makePanel(pgEvent,C.wisp)
connectSectionToggle(wispBtn,wispPanel,wispArr)

lbl(wispPanel,"Enchanted Forest \xe2\x80\x94 Update 7",10,C.wisp,{Size=UDim2.new(1,0,0,18),LayoutOrder=nlo()})

-- Note about speed
makeNote(wispPanel,"Speed otomatis di-boost jika WalkSpeed < 20B saat Wisp aktif. Tidak perlu setting manual.",Color3.fromRGB(8,20,14))

local wispSections = {
    {"WISP QUESTS",{
        {"Auto Complete Wisp Quests","3 quest: steal 20 enchanted egg, fuse 1 enchanted pet, steal 1 Eternal",false,function(v) CFG.Wisp.AutoCompleteQuests=v if v then autoCompleteWispQuests() end end},
        {"Auto Claim Butterfly Net","Ambil net dari Enchanted Tree setelah semua quest selesai",false,function(v) CFG.Wisp.AutoClaimNet=v end},
        {"Prioritize Enchanted Egg","Utamakan Enchanted Forest egg saat auto steal",true,function(v) CFG.Wisp.PrioritizeEnchanted=v end},
    }},
    {"BUTTERFLY BLOOM",{
        {"Auto Butterfly Bloom","Tangkap kupu-kupu saat event Butterfly Bloom (tiap 30 mnt)",false,function(v) CFG.Wisp.AutoButterflyBloom=v end},
        {"Auto Catch Butterflies","Kejar semua kupu-kupu di Enchanted Forest",false,function(v) CFG.Wisp.AutoCatchButterflies=v if v then autoCatchButterflies() end end},
        {"Auto Trade Up Butterflies","10 Emerald\xe2\x86\x92Sapphire \xe2\x80\xa6 50 Amethyst\xe2\x86\x92Radiant",true,function(v) CFG.Wisp.AutoTradeUpButterfly=v if v then autoTradeUpButterflies() end end},
        {"Auto Craft Essence","240 Emerald + 115 Sapphire + 40 Amethyst + 1 Radiant = 1 Essence",false,function(v) CFG.Wisp.AutoCraftEssence=v if v then autoCraftEssence() end end},
        {"Auto Use Enchanted Essence","Gunakan Essence ke shrine (mutation 100% berhasil)",false,function(v) CFG.Wisp.AutoUseEssence=v if v then autoUseEssence() end end},
    }},
    {"ENCHANTED FOREST",{
        {"Auto Wisp","Temukan Wisp NPC (speed di-boost jika kurang)",false,function(v) CFG.Wisp.AutoWisp=v end},
        {"Auto Banjo Cricket","Interaksi dengan Banjo Cricket NPC",false,function(v) CFG.Wisp.AutoBanjoCricket=v if v then autoBanjoCricket() end end},
        {"Auto Harvest Giant Beanstalk","Panen Giant Beanstalk di Enchanted Forest",false,function(v) CFG.Wisp.AutoHarvestBeanstalk=v if v then autoHarvestBeanstalk() end end},
        {"Auto Mech Boss","Lawan Mech Boss di Enchanted Forest",false,function(v) CFG.Wisp.AutoMechBoss=v if v then autoMechBoss() end end},
        {"Auto Claim Mastery","Claim reward mastery Enchanted Forest",false,function(v) CFG.Wisp.AutoClaimMastery=v end},
    }},
}
for _,sec in ipairs(wispSections) do
    local divW = mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.wisp,BackgroundTransparency=0.82,BorderSizePixel=0,LayoutOrder=nlo(),Parent=wispPanel})
    local secLblW = lbl(wispPanel,sec[1],9,C.wisp,{Size=UDim2.new(1,0,0,18),LayoutOrder=nlo()})
    secLblW.TextTransparency=0.35
    for _,row in ipairs(sec[2]) do
        makeToggleSub(wispPanel,row[1],row[2],row[3],row[4])
    end
end

-- Wisp start/stop
local wispBtnRow = mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=wispPanel})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=wispBtnRow})
local wStartBtn = mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=Color3.fromRGB(28,80,48),
    BorderSizePixel=0,Text="Mulai Wisp",TextSize=11,TextColor3=C.wisp,Font=Enum.Font.GothamBold,Parent=wispBtnRow})
corner(wStartBtn,7) stk(wStartBtn,C.wisp,1)
wStartBtn.MouseButton1Click:Connect(function() startWispEvent() end)
local wStopBtn = mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=Color3.fromRGB(55,20,25),
    BackgroundTransparency=0.4,BorderSizePixel=0,Text="Stop Wisp",TextSize=11,TextColor3=C.red,Font=Enum.Font.GothamBold,Parent=wispBtnRow})
corner(wStopBtn,7) stk(wStopBtn,C.red,1)
wStopBtn.MouseButton1Click:Connect(function() stopWispEvent() end)

-- Wisp stats
local wStatRow = mk("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=wispPanel})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=wStatRow})
local wQuestLbl,wBflyLbl,wEssLbl,wMutLbl
for _,s in ipairs({{"QUESTS","0/3"},{"BUTTERFLIES","0"},{"ESSENCE","0"},{"MUTATIONS","0"}}) do
    local sf = mk("Frame",{Size=UDim2.new(0.25,-3,1,0),BackgroundColor3=Color3.fromRGB(8,22,14),BorderSizePixel=0,Parent=wStatRow})
    corner(sf,6) stk(sf,C.wisp,1)
    local nl = mk("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,
        Text=s[2],TextSize=12,Font=Enum.Font.GothamBold,TextColor3=C.wisp,Parent=sf})
    lbl(sf,s[1],7,C.t2,{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-13),TextXAlignment=Enum.TextXAlignment.Center})
    if s[1]=="QUESTS" then wQuestLbl=nl elseif s[1]=="BUTTERFLIES" then wBflyLbl=nl
    elseif s[1]=="ESSENCE" then wEssLbl=nl else wMutLbl=nl end
end

-- Scramble Event Section
local div1 = mk("Frame",{Size=UDim2.new(1,0,0,5),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=pgEvent})

local scramBtn, scramArr = makeSectionBtn(pgEvent,"  Scramble Event (Dr. Scramble)",nil,C.scramble)
local scramPanel = makePanel(pgEvent,C.scramble)
connectSectionToggle(scramBtn,scramPanel,scramArr)

lbl(scramPanel,"Dr. Scramble \xe2\x80\x94 Boss, Lab, Drones, Lost Parts",10,C.scramble,{Size=UDim2.new(1,0,0,18),LayoutOrder=nlo()})

local scramSections = {
    {"BOSS & FIELD",{
        {"Auto Boss Scramble","Lawan boss Dr. Scramble otomatis",false,function(v) CFG.Scramble.AutoBossScramble=v end},
        {"Auto Hunt Drones","Berburu drone event di map",false,function(v) CFG.Scramble.AutoHuntDrones=v end},
        {"Auto Collect Lost Parts","Kumpulkan Lost Parts tersebar di map",false,function(v) CFG.Scramble.AutoCollectParts=v end},
    }},
    {"LAB & TRADE",{
        {"Auto Trade in Once","Tukar egg ke lab sekali per cycle",false,function(v) CFG.Scramble.AutoTradeOnce=v end},
        {"Auto Reroll","Reroll mutasi Scramble otomatis",false,function(v) CFG.Scramble.AutoReroll=v end},
        {"Wait at Last Pity","Tunggu di pity terakhir sebelum trade",true,function(v) CFG.Scramble.WaitLastPity=v end},
        {"Auto Place Scramble Eggs","Taruh egg hasil lab ke plot",false,function(v) CFG.Scramble.AutoPlaceEggs=v end},
        {"Stock Eggs","Siapkan egg untuk resep lab berikutnya",true,function(v) CFG.Scramble.StockEggs=v end},
        {"Feed Mutations","Feed egg bermutasi untuk bonus pity",false,function(v) CFG.Scramble.FeedMutations=v end},
    }},
    {"SHOP & REWARD",{
        {"Auto Buy Shop","Beli mutasi dan booster dari toko event",false,function(v) CFG.Scramble.AutoBuyShop=v end},
        {"Auto Mastery","Claim Scramble Mastery reward",false,function(v) CFG.Scramble.AutoMastery=v end},
    }},
}
for _,sec in ipairs(scramSections) do
    local dv = mk("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.scramble,BackgroundTransparency=0.82,BorderSizePixel=0,LayoutOrder=nlo(),Parent=scramPanel})
    local sl2 = lbl(scramPanel,sec[1],9,C.scramble,{Size=UDim2.new(1,0,0,18),LayoutOrder=nlo()})
    sl2.TextTransparency=0.35
    for _,row in ipairs(sec[2]) do
        makeToggleSub(scramPanel,row[1],row[2],row[3],row[4])
    end
end

-- Scramble start/stop
local sBtnRow = mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=scramPanel})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=sBtnRow})
local sStartBtn = mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=Color3.fromRGB(60,32,8),
    BorderSizePixel=0,Text="Mulai Scramble",TextSize=11,TextColor3=C.scramble,Font=Enum.Font.GothamBold,Parent=sBtnRow})
corner(sStartBtn,7) stk(sStartBtn,C.scramble,1)
sStartBtn.MouseButton1Click:Connect(function() startScrambleEvent() end)
local sStopBtn = mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=Color3.fromRGB(55,20,25),
    BackgroundTransparency=0.4,BorderSizePixel=0,Text="Stop Scramble",TextSize=11,TextColor3=C.red,Font=Enum.Font.GothamBold,Parent=sBtnRow})
corner(sStopBtn,7) stk(sStopBtn,C.red,1)
sStopBtn.MouseButton1Click:Connect(function() stopScrambleEvent() end)

-- Scramble stats
local sStatRow = mk("Frame",{Size=UDim2.new(1,0,0,42),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=scramPanel})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=sStatRow})
local sBossLbl,sDroneLbl,sPartsLbl,sTradeLbl
for _,s in ipairs({{"BOSS","0"},{"DRONES","0"},{"PARTS","0"},{"TRADES","0"}}) do
    local sf = mk("Frame",{Size=UDim2.new(0.25,-3,1,0),BackgroundColor3=Color3.fromRGB(22,14,4),BorderSizePixel=0,Parent=sStatRow})
    corner(sf,6) stk(sf,C.scramble,1)
    local nl = mk("TextLabel",{Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,
        Text=s[2],TextSize=12,Font=Enum.Font.GothamBold,TextColor3=C.scramble,Parent=sf})
    lbl(sf,s[1],7,C.t2,{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-13),TextXAlignment=Enum.TextXAlignment.Center})
    if s[1]=="BOSS" then sBossLbl=nl elseif s[1]=="DRONES" then sDroneLbl=nl
    elseif s[1]=="PARTS" then sPartsLbl=nl else sTradeLbl=nl end
end

-- Update scramble stats from tracker
task.spawn(function()
    while true do
        if activePage=="event" then
            if sBossLbl then sBossLbl.Text=tostring(scrambleStats.boss) end
            if sDroneLbl then sDroneLbl.Text=tostring(scrambleStats.drone) end
            if sPartsLbl then sPartsLbl.Text=tostring(scrambleStats.parts) end
            if sTradeLbl then sTradeLbl.Text=tostring(scrambleStats.trade) end
            if wBflyLbl then
                wBflyLbl.Text=tostring(butterflyCounts.Emerald+butterflyCounts.Sapphire+butterflyCounts.Amethyst+butterflyCounts.Radiant)
            end
            if wEssLbl then wEssLbl.Text=tostring(essenceCrafted) end
            if wMutLbl then wMutLbl.Text=tostring(mutationsDone) end
            local q=0
            if wispQuestsDone[1]>=20 then q+=1 end
            if wispQuestsDone[2] then q+=1 end
            if wispQuestsDone[3] then q+=1 end
            if wQuestLbl then wQuestLbl.Text=q.."/3" end
        end
        task.wait(2)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: SERVERS
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgSrv = pages.srv
secLabel(pgSrv,"SERVER LIST")
local srvListF = mk("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1,LayoutOrder=nlo(),Parent=pgSrv})
mk("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=srvListF})
makeNote(pgSrv,"Belum ada server tersimpan.",C.bg2)
local srvInput = mk("TextBox",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.bg2,BorderSizePixel=0,
    PlaceholderText="Paste server code...",PlaceholderColor3=C.t3,Text="",
    TextSize=10,TextColor3=C.t0,Font=Enum.Font.Gotham,LayoutOrder=nlo(),Parent=pgSrv})
corner(srvInput,7) stk(srvInput,Color3.new(1,1,1),1) pad(srvInput,0,8)
local srvs = {}
makeButton(pgSrv,"Tambah Server",C.bg5,function()
    local code = srvInput.Text:match("^%s*(.-)%s*$")
    if code=="" then return end
    srvs[#srvs+1]=code srvInput.Text=""
    for _,c in ipairs(srvListF:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for n,s in ipairs(srvs) do infoRow(srvListF,"Server #"..n,s:sub(1,16).."...",n) end
    notify("NoaHub","Server #"..#srvs.." ditambahkan.")
end)
secLabel(pgSrv,"OPTIONS")
makeToggle(pgSrv,"Auto Hop ke Server Sepi","Pindah jika player > batas",false,function(v) end)
makeToggle(pgSrv,"Rejoin Saat Kicked","Langsung rejoin setelah kick",false,function(v) end)
makeSlider(pgSrv,"Batas Maks Player",2,12,6,function(v) end)
makeButton(pgSrv,"Rejoin Server Saat Ini",C.bg5,function()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,lp) end)
end)

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: MISC
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgMisc = pages.misc
secLabel(pgMisc,"GUARDIAN")
makeToggle(pgMisc,"Anti Guardian","Noclip saat dikejar",false,function(v) CFG.AntiGuardian=v end)
makeToggle(pgMisc,"Kill Guardian","HP 0 saat mendekat",false,function(v) CFG.KillGuardian=v end)
makeToggle(pgMisc,"Alert Guardian","Notif saat guardian dekat",true,function(v) CFG.GuardianAlert=v end)
makeSlider(pgMisc,"Alert Radius (studs)",10,150,50,function(v) CFG.GuardianAlertR=v end)
secLabel(pgMisc,"UTILITY")
makeToggle(pgMisc,"Anti AFK","Input virtual cegah kick",true,function(v) CFG.AntiAFK=v end)
makeToggle(pgMisc,"Fly Mode","Terbang bebas WASD+Space",false,function(v) CFG.FlyMode=v if v then enableFly() else disableFly() end end)
makeToggle(pgMisc,"Ghost Mode","Karakter transparan",false,function(v) CFG.GhostMode=v end)
makeToggle(pgMisc,"Speed Burst Saat Dikejar","Speed max saat guardian dekat",false,function(v) CFG.SpeedBurst=v end)
secLabel(pgMisc,"KONTROL CEPAT")
local qBF = mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=nlo(),Parent=pgMisc})
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5),Parent=qBF})
local tpB = mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=C.bg5,BorderSizePixel=0,
    Text="TP ke Base",TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,Parent=qBF})
corner(tpB,7) stk(tpB,Color3.new(1,1,1),1)
tpB.MouseButton1Click:Connect(function() teleportTo(SHOP()) notify("NoaHub","TP ke base!") end)
local rjB = mk("TextButton",{Size=UDim2.new(0.5,-3,1,0),BackgroundColor3=C.bg5,BorderSizePixel=0,
    Text="Rejoin",TextSize=11,TextColor3=C.t0,Font=Enum.Font.GothamBold,Parent=qBF})
corner(rjB,7) stk(rjB,Color3.new(1,1,1),1)
rjB.MouseButton1Click:Connect(function() pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId,lp) end) end)
makeButton(pgMisc,"Reset Karakter",C.bg5,function() if lp.Character then lp.Character:BreakJoints() end end)
makeButton(pgMisc,"Tutup Hub",Color3.fromRGB(50,20,20),function() Main.Visible=false end)

-- ══════════════════════════════════════════════════════════════════════
-- PAGE: CONFIG
-- ══════════════════════════════════════════════════════════════════════
lo=0
local pgCfg = pages.cfg
secLabel(pgCfg,"SAVE / LOAD")
makeButton(pgCfg,"Save Config",Color3.fromRGB(38,55,140),function()
    saveConfig() notify("NoaHub","Config disimpan ke NoaHub_SAE.json")
end)
makeButton(pgCfg,"Load Config",C.bg5,function()
    loadConfig() notify("NoaHub","Config dimuat dari NoaHub_SAE.json")
end)
makeButton(pgCfg,"Reset ke Default",Color3.fromRGB(55,20,20),function()
    if isfile and isfile(CFG_FILE) then pcall(delfile,CFG_FILE) end
    notify("NoaHub","Config direset.")
end)
secLabel(pgCfg,"INFO FILE")
infoRow(pgCfg,"File Config","NoaHub_SAE.json")
infoRow(pgCfg,"Executor Support","Solara, KRNL")
infoRow(pgCfg,"Auto Load","Aktif saat inject")
infoRow(pgCfg,"Auto-Detect","Shop / Biome / Tool")
secLabel(pgCfg,"KEYBINDS")
infoRow(pgCfg,"Toggle Hub","RightShift")
infoRow(pgCfg,"Panic Stop","F9")
infoRow(pgCfg,"Quick TP Base","F10")
makeNote(pgCfg,"Config menyimpan semua toggle, slider, style, dan server list. Wisp speed auto-boost tidak butuh config manual.")

-- ══════════════════════════════════════════════════════════════════════
-- KEYBINDS
-- ══════════════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
        nhDot.BackgroundColor3 = Main.Visible and C.green or C.t3
    end
    if i.KeyCode == Enum.KeyCode.F9 then
        stopAutoSteal() stopForestDrop() stopPVPAuto() stopWispEvent() stopScrambleEvent()
        CFG.Noclip=false CFG.FlyMode=false disableFly()
        notify("NoaHub","PANIC STOP: semua fungsi dihentikan.",3)
    end
    if i.KeyCode == Enum.KeyCode.F10 then
        teleportTo(SHOP()) notify("NoaHub","Quick TP ke base!",2)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════════════════════════════════
setPage("main")
lp.CharacterAdded:Connect(function(c) task.wait(1) end)

-- Auto-detect on load
task.spawn(function()
    task.wait(3)
    detectShopPos()
    for _,b in ipairs({"Forest","Plains","Mountain"}) do detectBiomePos(b) end
    print("[NoaHub] Auto-detect selesai.")
    print("  Shop:", tostring(_shopPos))
end)

-- Public API
getgenv().NoaHub = {
    CFG=CFG,
    StartAutoSteal=startAutoSteal, StopAutoSteal=stopAutoSteal,
    StartForestDrop=startForestDrop, StopForestDrop=stopForestDrop,
    StartWisp=startWispEvent, StopWisp=stopWispEvent,
    StartScramble=startScrambleEvent, StopScramble=stopScrambleEvent,
    StartPVP=startPVPAuto, StopPVP=stopPVPAuto,
    TP=teleportTo, SHOP=SHOP, BIOME=BIOME,
    DetectShop=detectShopPos, DetectBiome=detectBiomePos,
    Save=saveConfig, Load=loadConfig,
    PanicStop=function()
        stopAutoSteal() stopForestDrop() stopPVPAuto()
        stopWispEvent() stopScrambleEvent()
        CFG.FlyMode=false disableFly()
        notify("NoaHub","Panic Stop via API.")
    end,
}

notify("NoaHub","v2.0 loaded \xe2\x80\x94 Steal An Egg | Auto-detect aktif",4)
print("[NoaHub] v2.0 loaded. API: getgenv().NoaHub | F9=PanicStop | F10=TP Base | RShift=Toggle")

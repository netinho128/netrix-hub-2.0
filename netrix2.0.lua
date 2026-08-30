-- NETRIX HUB FLUXO PVP 2.0 (Tudo Desativado por Padrão & Correção de Mortos no Chão)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Criando a Janela Principal
local Window = Fluent:CreateWindow({
    Title = "NETRIX HUB FLUXO PVP 2.0",
    SubTitle = "by Netrix",
    TabWidth = 140,
    Size = UDim2.fromOffset(530, 360),
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Criando as Abas
local Tabs = {
    Combat = Window:AddTab({ Title = "Combate", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals (ESP)", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movimento", Icon = "gauge" }),
    Discord = Window:AddTab({ Title = "Discord", Icon = "disc" })
}

-- Serviços do Roblox
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    Aimbot = false,
    IgnoreDead = false, -- Desativado por padrão
    FOVSize = 100,
    ShowFOV = false,
    
    ESP_Master = false,
    ESP_Boxes = false,
    ESP_Lines = false,
    ESP_Names = false,
    ESP_Player = false,
    
    Spinbot = false,
    EnableSpeed = false,
    Speed = 16
}

-- Círculo do FOV
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Visible = false

-- ==========================================
-- BOTÃO FLUTUANTE CUSTOMIZADO
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NetrixFloatingButtonGui"
ScreenGui.ResetOnSpawn = false

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game.CoreGui
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = game.CoreGui
end

local FloatButton = Instance.new("ImageButton")
FloatButton.Name = "NetrixFloatBtn"
FloatButton.Parent = ScreenGui
FloatButton.Size = UDim2.new(0, 55, 0, 55)
FloatButton.Position = UDim2.new(0.05, 0, 0.2, 0)
FloatButton.Image = "rbxassetid://113224789128479"
FloatButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FloatButton.BackgroundTransparency = 0.2
FloatButton.BorderSizePixel = 0
FloatButton.Active = true
FloatButton.Draggable = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = FloatButton

FloatButton.MouseButton1Click:Connect(function()
    if Window then
        Window:Minimize()
    end
end)

-- ==========================================
-- GERENCIAMENTO DE VELOCIDADE
-- ==========================================
local function ApplySpeed()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if Settings.EnableSpeed then
                humanoid.WalkSpeed = Settings.Speed
            else
                humanoid.WalkSpeed = 16
            end
        end
    end
end

Services.RunService.Stepped:Connect(function()
    if Settings.EnableSpeed then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.WalkSpeed ~= Settings.Speed then
                humanoid.WalkSpeed = Settings.Speed
            end
        end
    end
end)

-- ==========================================
-- LÓGICA DE ALVO COM FILTRO REAL DE MORTOS NO CHÃO
-- ==========================================
local function GetClosestPlayer()
    local Target = nil
    local MaxDistance = Settings.FOVSize
    local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local head = char:FindFirstChild("Head")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local rootPart = char:FindFirstChild("HumanoidRootPart")

            if head and humanoid and rootPart then
                -- Se a opção de ignorar mortos estiver ligada, faz a varredura rigorosa
                if Settings.IgnoreDead then
                    if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead or not char:IsDescendantOf(workspace) then
                        continue
                    end
                else
                    -- Mesmo com o botão desligado, o Aimbot nunca deve travar em quem já está morto com 0 de vida
                    if humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
                        continue
                    end
                end

                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distance = (Vector2.new(headPos.X, headPos.Y) - CenterScreen).Magnitude

                    if distance <= MaxDistance then
                        MaxDistance = distance
                        Target = player
                    end
                end
            end
        end
    end
    return Target
end

-- ==========================================
-- ESP COMPLETO
-- ==========================================
local CyanColor = Color3.fromRGB(0, 255, 255)
local ESPDrawings = {}

local function CreateESP(player)
    if ESPDrawings[player] then return end

    local drawings = {
        Box = Drawing.new("Square"),
        Line = Drawing.new("Line"),
        Name = Drawing.new("Text")
    }
    
    drawings.Box.Color = CyanColor
    drawings.Box.Thickness = 1.5
    drawings.Box.Filled = false
    
    drawings.Line.Color = CyanColor
    drawings.Line.Thickness = 1
    
    drawings.Name.Color = CyanColor
    drawings.Name.Size = 13
    drawings.Name.Center = true
    drawings.Name.Outline = true

    ESPDrawings[player] = drawings
end

local function RemoveESP(player)
    if ESPDrawings[player] then
        for _, v in pairs(ESPDrawings[player]) do
            v:Remove()
        end
        ESPDrawings[player] = nil
    end
    
    if player.Character and player.Character:FindFirstChild("NetrixChams") then
        player.Character.NetrixChams:Destroy()
    end
end

Services.Players.PlayerRemoving:Connect(RemoveESP)

-- ==========================================
-- LOOP PRINCIPAL (RENDERSTEPPED)
-- ==========================================
Services.RunService.RenderStepped:Connect(function()
    local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = CenterScreen
    FOVCircle.Radius = Settings.FOVSize
    FOVCircle.Visible = Settings.ShowFOV

    -- Aimbot Validado
    if Settings.Aimbot then
        local target = GetClosestPlayer()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            
            if head and humanoid and humanoid.Health > 0 then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
    
    -- Spinbot Rápido
    if Settings.Spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(150), 0)
    end

    -- ESP Visuals
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESPDrawings[player] then CreateESP(player) end
            
            local drawings = ESPDrawings[player]
            local char = player.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            
            if Settings.ESP_Master and char and humanoid and humanoid.Health > 0 then
                local cframe, size = char:GetBoundingBox()
                local screenPos, onScreen = Camera:WorldToViewportPoint(cframe.Position)
                
                if onScreen then
                    local topWorld = cframe.Position + Vector3.new(0, size.Y / 2, 0)
                    local bottomWorld = cframe.Position - Vector3.new(0, size.Y / 2, 0)
                    
                    local topScreen = Camera:WorldToViewportPoint(topWorld)
                    local bottomScreen = Camera:WorldToViewportPoint(bottomWorld)
                    
                    local height = math.abs(topScreen.Y - bottomScreen.Y)
                    local width = height / 1.6

                    if Settings.ESP_Boxes then
                        drawings.Box.Size = Vector2.new(width, height)
                        drawings.Box.Position = Vector2.new(screenPos.X - width / 2, topScreen.Y)
                        drawings.Box.Visible = true
                    else
                        drawings.Box.Visible = false
                    end

                    if Settings.ESP_Lines then
                        drawings.Line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                        drawings.Line.To = Vector2.new(screenPos.X, topScreen.Y)
                        drawings.Line.Visible = true
                    else
                        drawings.Line.Visible = false
                    end

                    if Settings.ESP_Names then
                        drawings.Name.Text = player.Name
                        drawings.Name.Position = Vector2.new(screenPos.X, topScreen.Y - 16)
                        drawings.Name.Visible = true
                    else
                        drawings.Name.Visible = false
                    end

                    if Settings.ESP_Player then
                        local highlight = char:FindFirstChild("NetrixChams")
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "NetrixChams"
                            highlight.FillColor = CyanColor
                            highlight.OutlineColor = CyanColor
                            highlight.FillTransparency = 0.5
                            highlight.OutlineTransparency = 0
                            highlight.Parent = char
                        end
                        highlight.Enabled = true
                    else
                        if char:FindFirstChild("NetrixChams") then
                            char.NetrixChams.Enabled = false
                        end
                    end
                else
                    drawings.Box.Visible = false
                    drawings.Line.Visible = false
                    drawings.Name.Visible = false
                    if char:FindFirstChild("NetrixChams") then char.NetrixChams.Enabled = false end
                end
            else
                drawings.Box.Visible = false
                drawings.Line.Visible = false
                drawings.Name.Visible = false
                if char and char:FindFirstChild("NetrixChams") then char.NetrixChams.Enabled = false end
            end
        end
    end
end)

-- ==========================================
-- CONTROLES DA GUI (TUDO DESATIVADO POR PADRÃO)
-- ==========================================

-- COMBATE
Tabs.Combat:AddToggle("Aimbot", { Title = "Aimbot Gruda na Cabeça", Default = false, Callback = function(v) Settings.Aimbot = v end })
Tabs.Combat:AddToggle("IgnoreDead", { Title = "Ignorar Mortos no Chão", Default = false, Callback = function(v) Settings.IgnoreDead = v end })
Tabs.Combat:AddToggle("ShowFOV", { Title = "Mostrar FOV", Default = false, Callback = function(v) Settings.ShowFOV = v end })

Tabs.Combat:AddSlider("FOVSize", {
    Title = "Tamanho do FOV",
    Min = 30,
    Max = 500,
    Default = 100,
    Rounding = 0,
    Callback = function(v) 
        Settings.FOVSize = v 
    end
})

-- VISUAIS
Tabs.Visuals:AddToggle("ESPMaster", { Title = "Ativar ESP (Master)", Default = false, Callback = function(v) Settings.ESP_Master = v end })
Tabs.Visuals:AddToggle("ESPPlayer", { Title = "ESP Player", Default = false, Callback = function(v) Settings.ESP_Player = v end })
Tabs.Visuals:AddToggle("ESPBoxes", { Title = "ESP Boxes", Default = false, Callback = function(v) Settings.ESP_Boxes = v end })
Tabs.Visuals:AddToggle("ESPLines", { Title = "ESP Lines", Default = false, Callback = function(v) Settings.ESP_Lines = v end })
Tabs.Visuals:AddToggle("ESPNames", { Title = "ESP Name", Default = false, Callback = function(v) Settings.ESP_Names = v end })

-- MOVIMENTO
Tabs.Movement:AddToggle("EnableSpeed", { Title = "Ativar Velocidade", Default = false, Callback = function(v) 
    Settings.EnableSpeed = v 
    ApplySpeed()
end })

Tabs.Movement:AddSlider("Speed", {
    Title = "Aumentar Velocidade",
    Min = 16,
    Max = 300,
    Default = 16,
    Rounding = 0,
    Callback = function(v) 
        Settings.Speed = v 
        ApplySpeed()
    end
})

Tabs.Movement:AddToggle("Spinbot", { Title = "Spinbot", Default = false, Callback = function(v) Settings.Spinbot = v end })

-- OTIMIZAÇÃO DE TOUCH DOS SLIDERS
task.spawn(function()
    task.wait(1)
    for _, gui in pairs(game.CoreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:find("Fluent") then
            for _, v in pairs(gui:GetDescendants()) do
                if v:IsA("Frame") and (v.Name:find("Slider") or v.Name:find("Bar")) then
                    v.Active = true
                end
            end
        end
    end
end)

-- DISCORD
Tabs.Discord:AddButton({
    Title = "Copiar Link do Discord",
    Description = "https://discord.gg/5TFHuucxgw",
    Callback = function()
        setclipboard("https://discord.gg/5TFHuucxgw")
        Fluent:Notify({
            Title = "NETRIX HUB",
            Content = "Link do Discord copiado!",
            Duration = 4
        })
    end
})

Window:SelectTab(1)


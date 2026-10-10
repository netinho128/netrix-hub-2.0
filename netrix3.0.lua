-- NETRIX HUB FLUXO PVP 2.0 (Visual Remodelado)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local IMAGE_ID = "rbxassetid://99262930883927"
local BG_TRANSPARENCY = 0.88 -- 0 = imagem forte | 1 = invisível (ajuste a gosto)

-- ==========================================
-- JANELA PRINCIPAL
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "🔥 NETRIX HUB",
    SubTitle = "Fluxo PVP 2.0  •  YouTube: @Netrix ofc",
    TabWidth = 150,
    Size = UDim2.fromOffset(580, 400),
    Acrylic = true,
    Theme = "Amethyst", -- Dark, Darker, Light, Aqua, Amethyst, Rose
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Imagem de fundo semi-transparente dentro do painel
task.spawn(function()
    pcall(function()
        local Root = Window.Root
        local Background = Instance.new("ImageLabel")
        Background.Name = "NetrixBackground"
        Background.Parent = Root
        Background.AnchorPoint = Vector2.new(0.5, 0.5)
        Background.Position = UDim2.fromScale(0.5, 0.5)
        Background.Size = UDim2.fromScale(1, 1)
        Background.BackgroundTransparency = 1
        Background.Image = IMAGE_ID
        Background.ImageTransparency = BG_TRANSPARENCY
        Background.ScaleType = Enum.ScaleType.Crop
        Background.ZIndex = 50
        Background.Active = false -- não bloqueia cliques

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = Background
    end)
end)

local Tabs = {
    Combat = Window:AddTab({ Title = "Combate", Icon = "crosshair" }),
    Visuals = Window:AddTab({ Title = "Visuals (ESP)", Icon = "eye" }),
    Movement = Window:AddTab({ Title = "Movimento", Icon = "gauge" }),
    Discord = Window:AddTab({ Title = "Discord", Icon = "disc" })
}

-- ==========================================
-- SERVIÇOS E CONFIGURAÇÕES
-- ==========================================
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService")
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    Aimbot = false,
    IgnoreDead = true,
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

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Visible = false

-- ==========================================
-- BOTÃO FLUTUANTE (QUADRADO ARREDONDADO)
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
FloatButton.AnchorPoint = Vector2.new(0.5, 0.5)
FloatButton.Size = UDim2.fromOffset(64, 64)
FloatButton.Position = UDim2.new(0.06, 0, 0.2, 0)
FloatButton.Image = IMAGE_ID
FloatButton.BackgroundTransparency = 1 -- sem cor ao redor
FloatButton.BorderSizePixel = 0
FloatButton.AutoButtonColor = false
FloatButton.ScaleType = Enum.ScaleType.Crop -- preenche o quadrado todo
FloatButton.Active = true
FloatButton.Draggable = true

-- Quadrado meio redondo (aumente o 16 para ficar mais redondo, diminua para mais quadrado)
local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(0, 16)
FloatCorner.Parent = FloatButton

local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

FloatButton.MouseEnter:Connect(function()
    Services.TweenService:Create(FloatButton, tweenInfo, { Size = UDim2.fromOffset(72, 72) }):Play()
end)

FloatButton.MouseLeave:Connect(function()
    Services.TweenService:Create(FloatButton, tweenInfo, { Size = UDim2.fromOffset(64, 64) }):Play()
end)

FloatButton.MouseButton1Down:Connect(function()
    Services.TweenService:Create(FloatButton, tweenInfo, { Size = UDim2.fromOffset(58, 58) }):Play()
end)

FloatButton.MouseButton1Up:Connect(function()
    Services.TweenService:Create(FloatButton, tweenInfo, { Size = UDim2.fromOffset(72, 72) }):Play()
end)

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
            humanoid.WalkSpeed = Settings.EnableSpeed and Settings.Speed or 16
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
-- DETECÇÃO DE JOGADORES VIVOS
-- ==========================================
local function IsPlayerAlive(player)
    if not player or player == LocalPlayer then return false end

    local char = player.Character
    if not char or not char:IsDescendantOf(workspace) then return false end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not head or not root then return false end
    if humanoid.Health <= 0 then return false end

    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.Physics then
        return false
    end

    return true
end

local function GetClosestPlayer()
    local Target = nil
    local MaxDistance = Settings.FOVSize
    local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Services.Players:GetPlayers()) do
        if IsPlayerAlive(player) then
            local head = player.Character.Head
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
    return Target
end

-- ==========================================
-- SISTEMA ESP
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
-- LOOP PRINCIPAL
-- ==========================================
Services.RunService.RenderStepped:Connect(function()
    local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Position = CenterScreen
    FOVCircle.Radius = Settings.FOVSize
    FOVCircle.Visible = Settings.ShowFOV

    if Settings.Aimbot then
        local target = GetClosestPlayer()
        if target and target.Character then
            local head = target.Character:FindFirstChild("Head")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end

    if Settings.Spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(150), 0)
    end

    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESPDrawings[player] then CreateESP(player) end

            local drawings = ESPDrawings[player]
            local isAlive = IsPlayerAlive(player)

            if Settings.ESP_Master and isAlive then
                local char = player.Character
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
                if player.Character and player.Character:FindFirstChild("NetrixChams") then
                    player.Character.NetrixChams.Enabled = false
                end
            end
        end
    end
end)

-- ==========================================
-- INTERFACE: ABA COMBATE
-- ==========================================
Tabs.Combat:AddSection("🎯 Mira")

Tabs.Combat:AddToggle("Aimbot", {
    Title = "Aimbot",
    Description = "Trava a mira na cabeça do alvo mais próximo",
    Default = false,
    Callback = function(v) Settings.Aimbot = v end
})

Tabs.Combat:AddToggle("IgnoreDead", {
    Title = "Ignorar Mortos",
    Description = "Não mira em jogadores que já morreram",
    Default = true,
    Callback = function(v) Settings.IgnoreDead = v end
})

Tabs.Combat:AddSection("⭕ Campo de Visão (FOV)")

Tabs.Combat:AddToggle("ShowFOV", {
    Title = "Mostrar Círculo de FOV",
    Default = false,
    Callback = function(v) Settings.ShowFOV = v end
})

Tabs.Combat:AddSlider("FOVSize", {
    Title = "Tamanho do FOV",
    Min = 30,
    Max = 500,
    Default = 100,
    Rounding = 0,
    Callback = function(v) Settings.FOVSize = v end
})

-- ==========================================
-- INTERFACE: ABA VISUALS
-- ==========================================
Tabs.Visuals:AddSection("👁️ ESP")

Tabs.Visuals:AddToggle("ESPMaster", {
    Title = "Ativar ESP (Master)",
    Description = "Liga ou desliga todos os recursos visuais",
    Default = false,
    Callback = function(v) Settings.ESP_Master = v end
})

Tabs.Visuals:AddSection("✨ Estilos")

Tabs.Visuals:AddToggle("ESPPlayer", { Title = "Chams (Realce de Player)", Default = false, Callback = function(v) Settings.ESP_Player = v end })
Tabs.Visuals:AddToggle("ESPBoxes", { Title = "Caixas (Boxes)", Default = false, Callback = function(v) Settings.ESP_Boxes = v end })
Tabs.Visuals:AddToggle("ESPLines", { Title = "Linhas", Default = false, Callback = function(v) Settings.ESP_Lines = v end })
Tabs.Visuals:AddToggle("ESPNames", { Title = "Nomes", Default = false, Callback = function(v) Settings.ESP_Names = v end })

-- ==========================================
-- INTERFACE: ABA MOVIMENTO
-- ==========================================
Tabs.Movement:AddSection("⚡ Velocidade")

Tabs.Movement:AddToggle("EnableSpeed", {
    Title = "Ativar Velocidade",
    Default = false,
    Callback = function(v)
        Settings.EnableSpeed = v
        ApplySpeed()
    end
})

Tabs.Movement:AddSlider("Speed", {
    Title = "Valor da Velocidade",
    Min = 16,
    Max = 300,
    Default = 16,
    Rounding = 0,
    Callback = function(v)
        Settings.Speed = v
        ApplySpeed()
    end
})

Tabs.Movement:AddSection("🌀 Extras")

Tabs.Movement:AddToggle("Spinbot", { Title = "Spinbot", Default = false, Callback = function(v) Settings.Spinbot = v end })

-- ==========================================
-- INTERFACE: ABA DISCORD
-- ==========================================
Tabs.Discord:AddSection("💬 Comunidade")

Tabs.Discord:AddParagraph({
    Title = "Entre no nosso Discord!",
    Content = "Novidades, suporte e atualizações do NETRIX HUB."
})

Tabs.Discord:AddButton({
    Title = "Copiar Link do Discord",
    Description = "https://discord.gg/yQyvXYM2CK",
    Callback = function()
        setclipboard("https://discord.gg/yQyvXYM2CK")
        Fluent:Notify({
            Title = "NETRIX HUB",
            Content = "Link do Discord copiado!",
            Duration = 4
        })
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "NETRIX HUB",
    Content = "Script carregado com sucesso! 🔥",
    Duration = 5
})

---@type Mq
local mq = require('mq')
---@type ImGui
local imgui = require 'ImGui'

-- Variables
local configFile
local textFieldValues = {
    dbName = "",
    dbBuffKeyword = "",
    dbBuffKeywordtarget = ""
}

local editedSettings = {}

local isRunning = false
local isDebugOn = false
local showSavedSettings = false
local showHelp = false
local showEditINI = false
local showAddBuff = false
local indexKey = "Index"

-- Plugin commands and description
local pluginCommands = {
    { command = "/ab", buttonText = "Start", description = "Pause/restart processing of the buff queue & buff requests." },
    { command = "/db", buttonText = "Que Buff", description = "Add a buff to the queue for <name>.", requiresTextField = true },
    { command = "/tb", buttonText = "Que Target Buff", description = "Queue buff for your target.", requiresTextField = true },
    { command = "/dq", buttonText = "List Buffs", description = "Lists buffs in the queue." },
    { command = "/cq", buttonText = "Clear Queue", description = "Clears the buff queue." },
    { command = "/abc", buttonText = "User Control", description = "Displays the status screen for authorized users control." },
}

-- Function to dynamically generate the configuration file path
local function getConfigFilePath()
    local serverName = mq.TLO.MacroQuest.Server
    local charName = mq.TLO.Me.Name()
    return string.format("%s/%s_%s.ini", mq.configDir, serverName, charName)
end

-- Function to save settings to the .ini file specifically for the [MQ2AutoBuff] section
local function saveSettings(settings)
    local configFile = getConfigFilePath()
    local newConfigContent = {}

    -- Open existing INI file for reading
    local f = io.open(configFile, "r")
    if not f then
        -- Create file if it does not exist
        f = io.open(configFile, "w")
        f:close()
        f = io.open(configFile, "r")
    end

    local foundSection = false
    for line in f:lines() do
        if line:match("%[MQ2AutoBuff%]") then
            foundSection = true
            table.insert(newConfigContent, line)
            for key, value in pairs(settings) do
                table.insert(newConfigContent, string.format("%s=%s", key, value))
            end
        else
            table.insert(newConfigContent, line)
        end
    end
    f:close()

    if not foundSection then
        table.insert(newConfigContent, "[MQ2AutoBuff]")
        for key, value in pairs(settings) do
            table.insert(newConfigContent, string.format("%s=%s", key, value))
        end
    end

    -- Write back to the INI file
    f = io.open(configFile, "w")
    for _, line in ipairs(newConfigContent) do
        f:write(line .. "\n")
    end
    f:close()
end

-- Load settings from the .ini file specifically from the [MQ2AutoBuff] section
local function loadSettings()
    local configFile = getConfigFilePath()
    local settings = {}
    local currentSection = nil

    local f = io.open(configFile, "r")
    if not f then
        print("Error: Unable to open config file for reading.")
        return settings
    end

    for line in f:lines() do
        local section = line:match("^%[%s*(%w+)%s*%]$")
        if section then
            currentSection = section
        else
            local key, value = line:match("^%s*(%S+)%s*=%s*(.+)%s*$")
            if key and value and currentSection == "MQ2AutoBuff" then
                settings[key] = value
            end
        end
    end
    f:close()
    return settings
end

-- Function to handle plugin commands with appropriate keyword usage
local function handlePluginCommand(command, requiresTextField, ...)
    print("Executing command: " .. command)
    
    local buffKeyword = textFieldValues.dbBuffKeyword
    local name = textFieldValues.dbName

    if command == "/ab" then
        isRunning = not isRunning
        return 
    end

    if command == "/tb" then 
        buffKeyword = textFieldValues.dbBuffKeywordtarget
    end

    if requiresTextField then
        if command == "/tb" and not (buffKeyword and buffKeyword ~= "") then
            print("Error: Buff keyword for target is required.")
            return
        elseif (not command == "/tb") and not (name and name ~= "" and buffKeyword and buffKeyword ~= "") then
            print("Error: Both name and buff keyword are required.")
            return
        end

        -- -- Load existing settings
        -- local settings = loadSettings({})
        -- local nextIndex = 1
        -- while settings["Keys"..nextIndex] do
        --     nextIndex = nextIndex + 1
        -- end

        -- -- Update settings with the new entries
        -- settings["Keys"..nextIndex] = buffKeyword
        -- if not command == "/tb" then  -- Only set name for non-target commands
        --     settings["Name"..nextIndex] = name
        -- end
        -- saveSettings(settings)

        local fullCommand = string.format(command, ...)
        mq.cmdf(fullCommand)
    else
        mq.cmdf(command)
    end
end

-- Function to create a button with dynamic width based on text content
local function dynamicButton(text, padding, minHeight)
    local textWidth, textHeight = imgui.CalcTextSize(text)
    local buttonWidth = math.max(200 * 0.6, textWidth + padding) -- Ensure a minimum button width and add some padding
    local buttonHeight = math.max(50, textHeight, minHeight) -- Ensure a minimum button height
    if imgui.Button(text, buttonWidth, buttonHeight) then
        return true
    else
        return false
    end
end

local function drawAddBuffSection()
    imgui.SetCursorPosY(imgui.GetCursorPosY() - 255)
    imgui.SetCursorPosX(imgui.GetWindowWidth() - 247)
    imgui.BeginGroup()

    local indexKey = "Index"
    local keysKey = "Keys"
    local nameKey = "Name"
    local typeKey = "Type"

    -- Initialize the index and load settings if not already done
    textFieldValues[indexKey] = textFieldValues[indexKey] or 1
    local settings = loadSettings()
    while settings[keysKey .. textFieldValues[indexKey]] do
        textFieldValues[indexKey] = textFieldValues[indexKey] + 1
    end

    -- Text fields for data input
    imgui.Text(keysKey .. textFieldValues[indexKey])
    imgui.SameLine()
    imgui.PushItemWidth(190)
    textFieldValues[keysKey .. textFieldValues[indexKey]] = imgui.InputText("##" .. keysKey .. textFieldValues[indexKey], textFieldValues[keysKey .. textFieldValues[indexKey]] or "")
    imgui.PopItemWidth()

    imgui.SetCursorPosX(imgui.GetWindowWidth() - 254)
    imgui.Text(nameKey .. textFieldValues[indexKey])
    imgui.SameLine()
    imgui.PushItemWidth(190)
    textFieldValues[nameKey .. textFieldValues[indexKey]] = imgui.InputText("##" .. nameKey .. textFieldValues[indexKey], textFieldValues[nameKey .. textFieldValues[indexKey]] or "")
    imgui.PopItemWidth()

    imgui.Text(typeKey .. textFieldValues[indexKey])
    imgui.SameLine()
    imgui.PushItemWidth(190)
    textFieldValues[typeKey .. textFieldValues[indexKey]] = imgui.InputText("##" .. typeKey .. textFieldValues[indexKey], textFieldValues[typeKey .. textFieldValues[indexKey]] or "")
    imgui.PopItemWidth()

    imgui.SetCursorPosX(imgui.GetWindowWidth() - 165)

    -- Check if any text field is not empty
    local anyFieldNotEmpty = false
    for i = 1, textFieldValues[indexKey] - 1 do
        if textFieldValues[keysKey .. i] ~= "" or textFieldValues[nameKey .. i] ~= "" or textFieldValues[typeKey .. i] ~= "" then
            anyFieldNotEmpty = true
            break
        end
    end

    -- Show the "Add" button only if any field is not empty
    if anyFieldNotEmpty then
        if imgui.Button("Add", 120, 20) then
            imgui.OpenPopup("Confirmation") -- Open the confirmation popup when the "Add" button is clicked
        end
    end

    -- Popup Modal for Confirmation
    if imgui.BeginPopupModal("Confirmation", nil, ImGuiWindowFlags.AlwaysAutoResize) then
        imgui.Text("Are you sure you want to add these entries?")
        if imgui.Button("Yes") then
            for i = 1, textFieldValues[indexKey] - 1 do
                if textFieldValues[keysKey .. i] ~= "" or textFieldValues[nameKey .. i] ~= "" or textFieldValues[typeKey .. i] ~= "" then
                    settings[keysKey .. i] = textFieldValues[keysKey .. i]
                    settings[nameKey .. i] = textFieldValues[nameKey .. i]
                    settings[typeKey .. i] = textFieldValues[typeKey .. i]
                end
            end
            saveSettings(settings)
            for i = 1, textFieldValues[indexKey] - 1 do
                textFieldValues[keysKey .. i] = ""
                textFieldValues[nameKey .. i] = ""
                textFieldValues[typeKey .. i] = ""
            end
            textFieldValues[indexKey] = 1
            imgui.CloseCurrentPopup()
        end
        imgui.SameLine()
        if imgui.Button("No") then
            imgui.CloseCurrentPopup()
        end
        imgui.EndPopup()
    end

    imgui.EndGroup()
end

function GUIAutoBuff(open)
    local main_viewport = imgui.GetMainViewport()
    imgui.SetNextWindowPos(main_viewport.WorkPos.x + 650, main_viewport.WorkPos.y + 20, ImGuiCond.FirstUseEver)
    imgui.SetNextWindowSize(600, 300, ImGuiCond.FirstUseEver)

    open, show = imgui.Begin("GUIAutoBuff", open)
    if not show then
        imgui.End()
        return open
    end
    
    -- Display status
    local textWidth = imgui.CalcTextSize("RUNNING")
    imgui.SetCursorPosX((imgui.GetWindowWidth() - textWidth) * 0.5)  -- Center text horizontally
    if isRunning then
        imgui.TextColored(0, 1, 0, 1, "RUNNING")  -- Green color for running
    else
        imgui.TextColored(1, 0, 0, 1, "PAUSED")  -- Red color for paused
    end
    
    if imgui.Button("Reload INI", 120, 20) then
        handlePluginCommand("/readini")
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip("Reload INI file.")
    end
        
    -- Debug status toggle
    local debugText = isDebugOn and "Debug ON" or "Debug OFF"
    
    -- Set button color dynamically
    if isDebugOn then
        imgui.PushStyleColor(ImGuiCol.Button, 0, 1, 0, 1)  -- Green color
    else
        imgui.PushStyleColor(ImGuiCol.Button, 1, 0, 0, 1)  -- Red color
    end
    
    -- Align to right side
    imgui.SetCursorPosX(imgui.GetWindowWidth() - 130)
    if imgui.Button(debugText, 120, 20) then
        isDebugOn = not isDebugOn
        handlePluginCommand("/abd")
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip("Toggle Debug ON and OFF")
    end
    
    imgui.PopStyleColor()  -- Reset button color
    
    imgui.SameLine()  -- Place next item on the same line
    
    -- Set cursor position to the left side
    imgui.SetCursorPosX(8)
    
    -- "Show INI Settings" button on the left side
    if imgui.Button("Show INI Settings", 120, 20) then
        showSavedSettings = true
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip("Displays the [MQ2AutoBuff] section of the INI file.")
    end

    -- New button to open the INI edit window
    if imgui.Button("Edit INI", 120, 20) then
        showEditINI = true
        editedSettings = loadSettings() -- Load the current settings into editedSettings table
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip("Open a window to edit [MQ2AutoBuff] section of the INI file.")
    end

    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetWindowWidth() - 130)
    if imgui.Button("Help Screen", 120, 20) then
        showHelp = true
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip("Displays the help screen.")
    end
        
    ImGui.Separator()

    imgui.SetCursorPosX(imgui.GetWindowWidth() - 185)
    if dynamicButton("Add Buff", 120, 20) then
        textFieldValues[indexKey] = textFieldValues[indexKey] or 1
        
        local anyFieldNotEmpty = false
        for i = 1, textFieldValues[indexKey] do
            if textFieldValues["Keys" .. i] ~= "" or textFieldValues["Name" .. i] ~= "" or textFieldValues["Type" .. i] ~= "" then
                anyFieldNotEmpty = true
                break
            end
        end
    
        --print("anyFieldNotEmpty:", anyFieldNotEmpty)
        -- Open the confirmation popup only if any field is not empty
        if anyFieldNotEmpty and showAddBuff then
            showAddBuff = not showAddBuff
            imgui.OpenPopup("Confirmation")
        else
            showAddBuff = not showAddBuff
        end

        if not anyFieldNotEmpty and not showAddBuff then
            showAddBuff = not showAddBuff
        end

        --print("showAddBuff:", showAddBuff)
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip("Show a textfields to add new Buffs")
    end

    -- Loop over each command in pluginCommands
    imgui.SetCursorPosY(imgui.GetCursorPosY() - 55)
    for _, cmd in ipairs(pluginCommands) do
        if cmd.command == "/db" then
            if dynamicButton(cmd.buttonText, 20, 50) then
                handlePluginCommand(cmd.command, true, textFieldValues.dbName, textFieldValues.dbBuffKeyword)
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(cmd.description)
            end
            imgui.SameLine()
            imgui.BeginGroup()
            imgui.PushItemWidth(200 * 0.5)
            textFieldValues.dbName = imgui.InputText("Name##db", textFieldValues.dbName)
            imgui.PopItemWidth()
            imgui.PushItemWidth(200 * 0.5)
            textFieldValues.dbBuffKeyword = imgui.InputText("Buff Name##db", textFieldValues.dbBuffKeyword)
            imgui.PopItemWidth()
            imgui.EndGroup()
        elseif cmd.command == "/tb" then
            imgui.BeginGroup() -- Start a new group for layout
            if dynamicButton(cmd.buttonText, 20, 50) then
                handlePluginCommand("/tb", textFieldValues.dbBuffKeywordtarget)
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(cmd.description)
            end
            imgui.SameLine()
            imgui.PushItemWidth(200 * 0.5)
            imgui.SetCursorPosY(imgui.GetCursorPosY() + 27)
            textFieldValues.dbBuffKeywordtarget = imgui.InputText("Buff Name##tb", textFieldValues.dbBuffKeywordtarget)
            imgui.PopItemWidth()
            imgui.EndGroup() -- End the group
        else
            if dynamicButton(cmd.buttonText, 20, 50) then
                handlePluginCommand(cmd.command)
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip(cmd.description)
            end
        end
    end
    
    if showAddBuff then
        drawAddBuffSection()
    end
    
    -- Popup window to show [MQ2AutoBuff] section of the ini file
    if showSavedSettings then
        imgui.SetNextWindowSize(400, 400, ImGuiCond.Appearing)
        imgui.Begin("Saved INI File Settings", showSavedSettings, ImGuiWindowFlags.NoResize)
        local settings = loadSettings({})
        for key, value in pairs(settings) do
            imgui.Text(key .. ": " .. value)
        end
        if imgui.Button("Close") then
            showSavedSettings = false 
        end
        imgui.End()
    end
    
    -- Popup window to edit the [MQ2AutoBuff] section of the ini file
    if showEditINI then
        imgui.SetNextWindowSize(400, 400, ImGuiCond.Appearing)
        imgui.Begin("Edit INI File", showEditINI, ImGuiWindowFlags.NoResize)
        for key, value in pairs(editedSettings) do
            editedSettings[key] = imgui.InputText(key, value)
        end
        if imgui.Button("Save and Close") then
            saveSettings(editedSettings)
            showEditINI = false
        end
        imgui.End()
    end
    
    -- Popup window to display help information for each command
    if showHelp then
        imgui.SetNextWindowSize(400, 400, ImGuiCond.Appearing)
        imgui.Begin("Help Commands", showHelp, ImGuiWindowFlags.NoResize)
        imgui.Text("/ab will pause/restart processing of the buff queue & buff requests.")
        imgui.Text("/db <name> <buff keyword> will add a buff to the queue for <name>.")
        imgui.Text("/tb <buff keyword> will add a buff to the queue for your target.")
        imgui.Text("/dq lists buffs in the queue.")
        imgui.Text("/cq clears the buff queue.")
        imgui.Text("/abd turns debugging messages on or off.")
        imgui.Text("/readini reloads your options from INI file.")
        imgui.Text("/abhelp displays the help screen (command list summary).")
        imgui.Text("/abc displays the status screen for authorized users control.")
        
        if imgui.Button("Close") then
            showHelp = false
        end
        imgui.End()
    end
    
    imgui.End()
    return open
end

local openGUI = true

ImGui.Register('GUIAutoBuff', function()
    openGUI = GUIAutoBuff(openGUI)
end)

while openGUI do
    mq.delay(1000)
end

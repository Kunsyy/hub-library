import os

file_path = "C:/Project/hub-library/NewLibrary.lua"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace the 2-column layout in Setup:CreateTab
old_cols = """    local colLeft = Instance.new("Frame")
    colLeft.Size = UDim2.new(0.5,-5,0,0); colLeft.Position = UDim2.fromScale(0,0); colLeft.AutomaticSize = Enum.AutomaticSize.Y
    colLeft.BackgroundTransparency = 1; colLeft.Parent = holder
    local llL = Instance.new("UIListLayout", colLeft); llL.Padding = UDim.new(0,10)

    local colRight = Instance.new("Frame")
    colRight.Size = UDim2.new(0.5,-5,0,0); colRight.Position = UDim2.new(0.5,5,0,0); colRight.AutomaticSize = Enum.AutomaticSize.Y
    colRight.BackgroundTransparency = 1; colRight.Parent = holder
    local llR = Instance.new("UIListLayout", colRight); llR.Padding = UDim.new(0,10)

    local tab = setmetatable({}, Tab)
    tab._lib = self._lib; tab._page = page; tab._colLeft = colLeft; tab._colRight = colRight"""

new_cols = """    local colMain = Instance.new("Frame")
    colMain.Size = UDim2.new(1, 0, 0, 0); colMain.Position = UDim2.fromScale(0,0); colMain.AutomaticSize = Enum.AutomaticSize.Y
    colMain.BackgroundTransparency = 1; colMain.Parent = holder
    local llM = Instance.new("UIListLayout", colMain); llM.Padding = UDim.new(0,10)

    local tab = setmetatable({}, Tab)
    tab._lib = self._lib; tab._page = page; tab._colMain = colMain"""

content = content.replace(old_cols, new_cols)

# Also update the way sections are added to the column in Tab:CreateSection
old_add_sec = """    self._count = (self._count or 0) + 1
    local column = (self._count % 2 == 1) and self._colLeft or self._colRight"""

new_add_sec = """    local column = self._colMain"""
content = content.replace(old_add_sec, new_add_sec)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

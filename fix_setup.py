import os

file_path = "C:/Project/hub-library/NewLibrary.lua"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Revert Initialize to Setup so the user's test script doesn't break
content = content.replace("Library:Initialize", "Library:Setup")
content = content.replace("function Library:Initialize", "function Library:Setup")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

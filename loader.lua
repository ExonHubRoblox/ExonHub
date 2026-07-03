local url = "https://raw.githubusercontent.com/ExonHubRoblox/ExonHub/refs/heads/main/ExonHub.Lua"
local src = game:HttpGet(url)
local a, b, c = src:byte(1, 3)
if a == 0xEF and b == 0xBB and c == 0xBF then
	src = src:sub(4)
end
local fn, err = loadstring(src)
if not fn then
	warn("[ExonHub] load failed:", err)
	return
end
fn()

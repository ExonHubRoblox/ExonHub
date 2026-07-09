local MAIN_URL = "https://raw.githubusercontent.com/ExonHubRoblox/ExonHub/refs/heads/main/ExonHub.Lua"

local function getLoadFn()
	if type(loadstring) == "function" then
		return loadstring
	end
	if type(load) == "function" then
		return load
	end
	return nil
end

local function httpGet(url)
	local ok, body = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end

	local requestFn = (syn and syn.request)
		or (http and http.request)
		or request
		or (fluxus and fluxus.request)
		or (krnl and krnl.request)

	if type(requestFn) == "function" then
		local reqOk, res = pcall(requestFn, {
			Url = url,
			url = url,
			Method = "GET",
			method = "GET",
		})
		if reqOk and type(res) == "table" then
			local responseBody = res.Body or res.body
			if type(responseBody) == "string" and responseBody ~= "" then
				return responseBody
			end
		end
	end

	return nil
end

local function fail(message)
	warn("[ExonHub] " .. message)
	local players = game:GetService("Players")
	local lp = players.LocalPlayer
	if lp then
		pcall(function()
			lp:Kick("[ExonHub] " .. message)
		end)
	end
end

local loadFn = getLoadFn()
if not loadFn then
	return fail("Executor missing loadstring/load. Update executor or use Delta, Wave, Solara, etc.")
end

local src = httpGet(MAIN_URL)
if not src then
	return fail("Failed to download ExonHub. Enable HTTP in your executor.")
end

local a, b, c = src:byte(1, 3)
if a == 0xEF and b == 0xBB and c == 0xBF then
	src = src:sub(4)
end

if src:sub(1, 1) == "<" and src:lower():find("<!doctype", 1, true) then
	return fail("Download returned HTML (wrong URL or GitHub blocked).")
end

local fn, err = loadFn(src)
if type(fn) ~= "function" then
	return fail("Compile failed: " .. tostring(err))
end

local runOk, runErr = pcall(fn)
if not runOk then
	warn("[ExonHub] Runtime error:", runErr)
end

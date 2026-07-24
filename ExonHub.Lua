					local Players = game:GetService("Players")

					do
						if not _G.__ExonHubRealPrint then
							_G.__ExonHubRealPrint = print
							_G.__ExonHubRealWarn = warn
						end
						local realPrint = _G.__ExonHubRealPrint
						local realWarn = _G.__ExonHubRealWarn

						local function combineExonHubArgs(...)
							local count = select("#", ...)
							if count == 0 then
								return ""
							end
							local parts = {}
							for i = 1, count do
								parts[i] = tostring(select(i, ...))
							end
							return table.concat(parts, " ")
						end

						local function keepExonHubLine(line)
							return line:find("[ExonHub] Loading", 1, true) ~= nil
								or line:find("[ExonHub] Loaded", 1, true) ~= nil
								or line:find("[ExonHub] Key system ", 1, true) ~= nil
						end

						local function filteredPrint(...)
							local line = combineExonHubArgs(...)
							if line:find("[ExonHub]", 1, true) and not keepExonHubLine(line) then
								return
							end
							realPrint(...)
						end

						local function filteredWarn(...)
							local line = combineExonHubArgs(...)
							if line:find("[ExonHub]", 1, true) then
								return
							end
							realWarn(...)
						end

						print = filteredPrint
						warn = filteredWarn
						_G.print = filteredPrint
						_G.warn = filteredWarn
						if type(getgenv) == "function" then
							local genv = getgenv()
							if type(genv) == "table" then
								genv.print = filteredPrint
								genv.warn = filteredWarn
							end
						end
						if type(getrenv) == "function" then
							pcall(function()
								local renv = getrenv()
								if type(renv) == "table" then
									renv.print = filteredPrint
									renv.warn = filteredWarn
								end
							end)
						end
					end

					print("[ExonHub] Loading")

					local ALLOWED_PLACE_ID = 12645083079 -- Giant Simulator REBORN

					local EXONHUB_SESSION_KEY = "__ExonHubSession_v1"

					do
						local bag = _G[EXONHUB_SESSION_KEY]
						if type(bag) == "table" and type(bag.connections) == "table" then
							for _, conn in ipairs(bag.connections) do
								pcall(function()
									if conn and conn.Disconnect then
										conn:Disconnect()
									end
								end)
							end
						end
						_G[EXONHUB_SESSION_KEY] = { connections = {} }
					end

					local function trackExonHubConnection(conn)
						local bag = _G[EXONHUB_SESSION_KEY]
						if bag and conn then
							table.insert(bag.connections, conn)
						end
						return conn
					end

					local function getLoadFn()
						return loadstring or load
					end

					local function getHttpGetFn()
						return game.HttpGet
							or (syn and syn.request and function(url)
								local res = syn.request({ Url = url, Method = "GET" })
								return res and res.Body
							end)
							or (http and http.request and function(url)
								local res = http.request({ Url = url, Method = "GET" })
								return res and res.Body
							end)
							or (request and function(url)
								local ok, res = pcall(request, { Url = url, Method = "GET" })
								if ok and res then
									return res.Body
								end
								return nil
							end)
					end

					local function failStartup(message)
						warn("[ExonHub] " .. message)
						local lp = Players.LocalPlayer
						if lp then
							pcall(function()
								lp:Kick("[ExonHub] " .. message)
							end)
						end
						error(message, 0)
					end
					local function refService(serviceName)
						local service = game:GetService(serviceName)
						if typeof(cloneref) == "function" then
							local ok, wrapped = pcall(cloneref, service)
							if ok and wrapped then
								return wrapped
							end
						end
						return service
					end
					local VirtualUser = refService("VirtualUser")
					local VirtualInputManager = refService("VirtualInputManager")
					local UserInputService = game:GetService("UserInputService")
					local TweenService = game:GetService("TweenService")
					local RunService = game:GetService("RunService")
					local CollectionService = game:GetService("CollectionService")

					if game.PlaceId ~= ALLOWED_PLACE_ID then
						local player = Players.LocalPlayer
						if player then
							player:Kick("Wrong game — ExonHub only works in Giant Simulator REBORN.")
						end
						return
					end

					local player = Players.LocalPlayer
					if not player then
						player = Players.PlayerAdded:Wait()
					end

					local playerGui = player:WaitForChild("PlayerGui", 30)
					if not playerGui then
						failStartup("PlayerGui not found — rejoin the game and try again.")
					end

					if type(getLoadFn()) ~= "function" then
						failStartup("Your executor is missing loadstring/load. Update executor or use Delta, Wave, Solara, etc.")
					end

					if type(getHttpGetFn()) ~= "function" and type(game.HttpGet) ~= "function" then
						failStartup("Your executor cannot HttpGet. Enable HTTP or use a different executor.")
					end

					-- remove old UI from previous run (PlayerGui / gethui / CoreGui)
					local OLD_UI_NAMES = {
						"Exon",
						"ExonHubUI",
						"ExonHubFloatingToggle",
						"ExonHubMinimizedClone",
						"ExonHubMinimizedGui",
						"ExonHubQtyPrompt",
						"WindUI",
						"ExonHub",
					}

					local function destroyNamedChildren(parent)
						if not parent then
							return
						end
						for _, name in ipairs(OLD_UI_NAMES) do
							local old = parent:FindFirstChild(name)
							if old then
								pcall(function()
									old:Destroy()
								end)
							end
						end
					end

					destroyNamedChildren(playerGui)
					pcall(function()
						if typeof(gethui) == "function" then
							destroyNamedChildren(gethui())
						end
					end)
					pcall(function()
						local CoreGui = game:GetService("CoreGui")
						destroyNamedChildren(CoreGui)
					end)

					local NODES_PATH = { "Scene", "ResourceNodes1" }
					local FOLDER_WAIT = 30
					local COLLECT_POLL = 0.1
					local COLLECT_WAIT = 0.3
					local COLLECT_RADIUS = 8
					local ORB_FOLLOW_SPEED = 300
					local ORB_COLLECT_PAUSE_MIN = 0.3
					local ORB_COLLECT_PAUSE_MAX = 0.3
					local MISC_TP_LOCATIONS = {
						{ label = "Ground", position = Vector3.new(1303.301, 103.754, -71.574) },
						{ label = "Cave", position = Vector3.new(2078.066, 218.596, -981.986) },
						{ label = "Borock Boss", position = Vector3.new(15238.000, -10.113, -939.500) },
						{ label = "Temple", position = Vector3.new(11463.500, -456.873, -1506.500) },
						{ label = "Temple Crates", position = Vector3.new(11627.379, -399.517, -1326.282) },
						{ label = "Temple Artifacts", position = Vector3.new(11060.464, -429.295, -1460.073) },
						{ label = "Demon King", position = Vector3.new(11372.628, -417.547, -1811.071) },
						{ label = "Beach", position = Vector3.new(19507.498, 686.537, -2002.500) },
						{ label = "Shell Race", position = Vector3.new(20450.500, 690.165, -1687.000) },
					}
					local GOLDEN_EGG_NAME = "Egg"
					local GOLDEN_EGG_TP_OFFSET = Vector3.new(0, 3, 0)
					-- Paste your Discord channel webhook URL here (Server Settings → Integrations → Webhooks)
					local EXONHUB_DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1530229428678955139/Alfc3awXiSif5tYQS2aDxPtRnJDu21XWaiTMAMg7l_pwAomuMx5IW25P1Aoju4hFzt9T"
					local EXONHUB_DISCORD_BOT_NAME = "Exon Hub"
					local EXONHUB_ICON_ASSET_ID = 131372483038871
					local EXONHUB_ICON_ASSET = "rbxassetid://" .. tostring(EXONHUB_ICON_ASSET_ID)
					local EXONHUB_ICON_URL = "https://cdn.discordapp.com/attachments/1522686323234832526/1522695144611123250/bce603ec-f4f6-458d-ad80-226aee524ea5.png"
					local EXONHUB_DISCORD_ICON_URL = EXONHUB_ICON_URL
					-- Discord gate: set this to your bot URL (must be https — use ngrok or Railway).
					local EXONHUB_GATE_API = "https://skeletal-showbiz-drop-down.ngrok-free.dev"
					local EXONHUB_DISCORD_INVITE = "https://discord.gg/exonhub"
					local EXONHUB_LAUNCH_CHANNEL = "〔🚀〕launch"
					local EXONHUB_GATE_POLL_SECONDS = 2
					local EXONHUB_GATE_TTL_SECONDS = 6 * 60 * 60
					local EXONHUB_GATE_FILE = "ExonHub/discord_gate.json"
					local EXONHUB_GATE_ALWAYS_VERIFY = false -- false = skip gate for 6h after verify (same account + PC)
					local EXONHUB_GATE_SKIP_IF_OFFLINE = true -- if bot/ngrok is down, open hub without verify
					local EXONHUB_USAGE_DIR = "ExonHub/usage"
					local EXONHUB_SETTINGS_DIR = "ExonHub/settings"
					local EXONHUB_MINIMIZED_PULSE = 0.05
					local EXONHUB_MINIMIZED_SIZE = UDim2.new(0.0637589768, 0, 0.113416299, 0)
					local EXONHUB_MINIMIZED_POSITION = UDim2.new(0.467708319 + 0.0637589768 * 0.5, 0, 0.0692661181, 0)
					local EXONHUB_TOPBAR_ICON_SIZE = 56
					local EXONHUB_ICON_ROTATION_SPEED = 90

					local MAX_FAILS_BEFORE_SKIP = 3
					local SKIP_SECONDS = 32

					local H = {}
					local S = {
						running = false,
						isProcessing = false,
						farmLoopActive = false,
						skipUntil = {},
						failCount = {},
						orbFirstSnapDone = false,
						orbFollowTween = nil,
						goldenEggTpInitialized = false,
						goldenEggTpIndex = 1,
						goldenEggTpCount = 0,
						clickerRunning = false,
						clickerLoopActive = false,
						autoRebirthRunning = false,
						autoRebirthLoopActive = false,
						autoMassUpgradeRunning = false,
						massUpgradeLoopActive = false,
						autoUpgradeRunning = false,
						autoUpgradeLoopActive = false,
						autoUpgradeFailStreak = 0,
						autoUpgradeLastRebirthCount = nil,
						autoUpgradeLastPlayerLevel = nil,
						autoUpgradeRebirthWatchConns = nil,
						upgradeInventorySnapshots = {
							weapon = nil,
							skin = nil,
							weaponAt = 0,
							skinAt = 0,
						},
						autoUpgradeTargets = {
							primary_weapon = true,
							secondary_weapon = true,
							skin = true,
						},
						autoBossRunning = false,
						autoBossLoopActive = false,
					autoBossSwingActive = false,
					autoBossFollowTween = nil,
					autoBossFollowConnection = nil,
					autoBossFollowDefId = nil,
					autoGoalsRunning = false,
						autoGoalsLoopActive = false,
						autoFishRunning = false,
						autoFishLoopActive = false,
						autoFishPhase = 0,
						autoFishPhaseConn = nil,
						suppressAutoFishSync = false,
						autoMineRaceRunning = false,
						autoKothRunning = false,
						autoKothLoopActive = false,
						autoKothLastSwingAt = 0,
						autoKothHoldConn = nil,
						kothMovementBackup = nil,
						autoGoalsKickBusy = false,
						cachedKothFloorPart = nil,
						kothSelfLevelCache = nil,
						kothSelfListener = nil,
						kothCharacterConn = nil,
						kothRagdollListener = nil,
						kothDefendBusy = false,
						kothRecoverUntil = 0,
						kothIdleSpinAngle = 0,
						kothMeleeHitboxActive = false,
						autoMineRaceLoopActive = false,
						autoMineRaceSessionId = 0,
						autoMineRaceTween = nil,
						autoMineRaceMined = {},
						autoMineRaceRowSaved = {},
						suppressAutoMineRaceSync = false,
						autoQuestRunning = false,
						autoQuestLoopActive = false,
						autoQuestTween = nil,
						autoQuestVisitedEggs = {},
						autoQuestBossHits = 0,
						autoQuestOrbHits = 0,
						autoQuestEggHits = 0,
						autoQuestLastKind = nil,
						autoQuestLastTarget = nil,
						autoQuestLastQuestKey = nil,
						autoQuestEggAreaReady = false,
						autoQuestWasAttackingBoss = false,
						autoQuestBossFollowTween = nil,
						autoQuestBossFollowConnection = nil,
						autoQuestBossFollowDefId = nil,
						autoQuestBossSwingActive = false,
						autoQuestBossWaitTpDone = false,
						autoQuestOrbGroundReady = false,
						autoQuestDeleteRewards = false,
						autoQuestEnabledFish = false,
						autoQuestEnabledClicker = false,
						autoQuestEnabledKill = false,
						orbGroundTeleported = false,
						suppressAutoQuestSync = false,
						suppressAutoQuestDeleteSync = false,
						automationCharacterCollisionBackup = nil,
						autoSaveSettingsEnabled = true,
						minimizeHotkey = "LeftAlt",
						settingsSavePending = false,
						suppressSettingsPersist = false,
						suppressSettingsDropdownSync = false,
						pendingSettingsRestore = nil,
						suppressAutoSaveSettingsSync = false,
						autoUpgradeRodRunning = false,
						autoUpgradeRodLoopActive = false,
						autoUpgradeRodPending = false,
						suppressAutoUpgradeRodSync = false,
						autoGoalsScoredBalls = {},
						autoGoalsBallSpawns = {},
						autoGoalsLastKickBallName = nil,
						autoGoalsLastKickGoalName = nil,
						autoGoalsGoalListener = nil,
						autoGoalsRawGoalListener = nil,
						autoGoalsLastGoalConfirmAt = 0,
						autoGoalsLastGoalConfirmBall = nil,
						clickerHadAeroAuto = false,
						silentTrainModeActive = false,
					autoGoalsBallCollisionBackup = {},
					autoGoalsCollisionReady = false,
					autoGoalsCollisionUnsupported = false,
					autoGoalsPhantomConn = nil,
						autoGoalsPhantomBall = nil,
						autoBossTargets = {
							borock = true,
							demon_king = true,
						},
						autoSellChestRunning = false,
						autoSellChestLoopActive = false,
						autoOpenChestRunning = false,
						autoOpenChestLoopActive = false,
						caveAutoOpenLoopActive = false,
						shellEggAutoOpenLoopActive = false,
						equipBestSwordRunning = false,
						equipBestSwordLoopActive = false,
						equipBestSkinRunning = false,
						equipBestSkinLoopActive = false,
						autoEvolvePetsRunning = false,
						autoEvolvePetsLoopActive = false,
						autoEvolveArtifactsRunning = false,
						autoEvolveArtifactsLoopActive = false,
						autoDeleteWeaponsRunning = false,
						autoDeleteWeaponsLoopActive = false,
						autoDeleteSkinsRunning = false,
						autoDeleteSkinsLoopActive = false,
						autoOpenLastChestType = "skin",
						weaponSortStat = "XP",
						skinSortStat = "XP",
						maxOutRunning = false,
						maxOutTier = "Common",
						maxOutLoopActive = false,
						maxOutPhase = "idle",
					maxOutManagedChest = false,
					maxOutManagedCaveSlots = {},
					maxOutNeedWeaponCrates = false,
					maxOutNeedSkinCrates = false,
					maxOutEnabledClicker = false,
					maxOutEnabledFarm = false,
					maxOutEnabledChest = false,
					maxOutEnabledCaveSlots = {},
					maxOutEnabledUpgrade = false,
					maxOutStopping = false,
					maxOutManagedUpgrade = false,
						maxOutLastComplete = false,
						suppressMaxOutSync = false,
						suppressMaxOutToggleSync = false,
						autoRebirthTargetLevel = 100,
						lastRebirthAttemptAt = 0,
						autoRebirthLevelConn = nil,
						suppressToggleSync = false,
						suppressClickerSync = false,
						suppressAutoRebirthSync = false,
						suppressAutoMassUpgradeSync = false,
						suppressAutoUpgradeSync = false,
						suppressAutoBossSync = false,
						suppressAutoGoalsSync = false,
						suppressAutoSellChestSync = false,
						suppressAutoOpenChestSync = false,
						suppressCaveAutoOpenSync = false,
						suppressAutoOpenShellEggSync = false,
						caveAutoOpenSlots = {},
						autoOpenShellEggSlots = {},
						crateAutoDeleteIds = {},
						crateAutoDeleteLabels = {},
						crateHuntTargets = {},
						crateHuntLabels = {},
						minimizedDragConns = nil,
						suppressAutoRebirthLevelSync = false,
						suppressEquipBestSwordSync = false,
						suppressEquipBestSkinSync = false,
						suppressAutoEvolvePetsSync = false,
						suppressAutoEvolveArtifactsSync = false,
						suppressAutoDeleteWeaponsSync = false,
						suppressAutoDeleteSkinsSync = false,
						suppressAutoKillSync = false,
						suppressAntiAfkSync = false,
						suppressStreamerModeSync = false,
						autoKillRunning = false,
						autoKillLoopActive = false,
						autoKillFollowTween = nil,
						autoKillFollowConnection = nil,
						antiAfkRunning = false,
						antiAfkIdledConnection = nil,
						antiAfkLoopActive = false,
						antiAfkSessionId = 0,
						antiAfkPulseIndex = 0,
						streamerModeRunning = false,
						streamerModeLoopActive = false,
						streamerModeCharacterConn = nil,
						streamerModeBackup = nil,
						cachedSafeZoneRegions = nil,
						suppressAutoKothSync = false,
						usageStats = nil,
						usageLastCheckpoint = nil,
						usageTrackingActive = false,
						topbarIconRotationConn = nil,
						minimizedIconRotationConn = nil,
					}
					local UI = {
						caveAutoOpenToggles = {},
						shellEggAutoOpenToggles = {},
						crateDeleteDropdowns = {},
						crateHuntDropdowns = {},
					}
					local C = {
						sharedConstants = nil,
						crates = nil,
						weapons = nil,
						skins = nil,
						massUpgradeSkills = nil,
						openCrateInvoker = nil,
						originalStartCratePopup = nil,
						pets = nil,
						artifacts = nil,
						petsInited = nil,
						zapClient = nil,
						fishingRodsData = nil,
					}
					local MIN_REBIRTH_TARGET_LEVEL = 100
					local TRAIN_INTERVAL = 0.16
					local TRAIN_BURST_SWINGS = 2
					local TRAIN_BURST_GAP = 0.035
					local TRAIN_REMOTE_SETTLE = 0.02
					local MASS_UPGRADE_INTERVAL = 0.75
					local AUTO_SELL_CHEST_INTERVAL = 0.75
					local REBIRTH_POLL_INTERVAL = 0.15
					local REBIRTH_ATTEMPT_COOLDOWN = 0.2
					local EQUIP_BEST_INTERVAL = 2
					local AUTO_EVOLVE_INTERVAL = 0.75
					local AUTO_DELETE_INTERVAL = 2.5
					local ANTI_AFK_BACKUP_INTERVAL = 30
					local AUTO_UPGRADE_IDLE_WAIT = 0.01
					local AUTO_UPGRADE_MAX_STEPS = 10000
					local AUTO_UPGRADE_CATCHUP_GAP = 5
					local AUTO_UPGRADE_BULK_MAX_LEVELS = 1000
					local AUTO_UPGRADE_FAIL_REFRESH_AFTER = 3
					local AUTO_UPGRADE_POST_REBIRTH_WAIT = 0.35
					local AUTO_UPGRADE_INVENTORY_SNAPSHOT_TTL = 0.4
					local AUTO_UPGRADE_SLOT_LABELS = { "Primary Weapon", "Secondary Weapon", "Skin" }
					local AUTO_UPGRADE_LABEL_TO_ID = {
						["Primary Weapon"] = "primary_weapon",
						["Secondary Weapon"] = "secondary_weapon",
						["Skin"] = "skin",
					}
					local MAX_OUT_OPTIONS = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
					local MAX_OUT_RARITY_RANK = {
						Common = 1,
						Rare = 2,
						Epic = 3,
						Legendary = 4,
						Mythic = 5,
					}
					local MAX_OUT_RARITY_ALIASES = {
						Common = { COMMON = true, UNCOMMON = true },
						Rare = { RARE = true },
						Epic = { EPIC = true },
						Legendary = { LEGENDARY = true },
						Mythic = { MYTHIC = true },
					}
					-- Exact XP-best targets from game dump (prefer these names over loose rarity ranking)
					local MAX_OUT_PREFERRED = {
						Common = {
							weapons = { "Training Sword", "Silence" },
							skins = { "Gothic Gargoyle" },
						},
						Rare = {
							weapons = { "Scar", "Thunderfury Axe", "Ashrune" },
							skins = { "The Harbinger", "Sun Wukong", "Grizzly Warrior" },
						},
						Epic = {
							weapons = { "Pride", "Unholy Glass Battle Axe" },
							skins = { "Blazeburner" },
						},
						Legendary = {
							weapons = { "Lighthunter", "Blade of Kings" },
							skins = { "Elemental Crystal Golem" },
						},
						Mythic = {
							weapons = { "Scythe of Prophecy", "Reaper's Reach" },
							skins = { "Bec the Fire God" },
						},
					}
					local MAX_OUT_POLL = 0.25
					local MAX_OUT_CAVE_SLOTS = {
						Legendary = { "legendary_weapon", "legendary_skin" },
						Mythic = { "mythic_weapon", "mythic_skin" },
					}
					local AUTO_BOSS_POLL = 0.2
					local AUTO_BOSS_SWING_INTERVAL = 0.52
					local AUTO_BOSS_APPROACH_OFFSET = 7
					local AUTO_KILL_POLL = 0.35
					local AUTO_KILL_SWING_INTERVAL = 0.5
					local AUTO_KILL_TP_OFFSET = Vector3.new(0, 0, 2.5)
					local AUTO_KILL_FOLLOW_TWEEN_TIME = 0.05
					local AUTO_KILL_FOLLOW_MAX_SPEED = 450
					local AUTO_KILL_GROUND_RADIUS = 48
					local AUTO_KILL_GROUND_MAX_HEIGHT = 80
					local AUTO_KOTH_POLL = 0.1
					local AUTO_KOTH_SWING_INTERVAL = 0.5
					local AUTO_KOTH_DEFEND_SWING_INTERVAL = 0.16
					local AUTO_KOTH_CONTESTED_SWING_INTERVAL = 0.1
					local AUTO_KOTH_BLITZ_SWINGS = 3
					local AUTO_KOTH_MULTI_BLITZ_SWINGS = 2
					local AUTO_KOTH_DEFEND_BEHIND_OFFSET = 5
					local AUTO_KOTH_RECOVER_SECONDS = 4
					local AUTO_KOTH_IDLE_SPIN_SPEED = 1080
					local AUTO_KOTH_HILL_STAND_OFFSET = 4
					local AUTO_KOTH_HILL_PADDING = 12
					local AUTO_KOTH_KING_LEVEL = 2
					local AUTO_KOTH_SNAP_DISTANCE = 8
					local AUTO_KOTH_HOLD_LERP = 0.55
					local KOTH_HITBOX_SCALE = 20
					local KOTH_HITBOX_PADDING = 12
					local KOTH_HITBOX_MIN_SIZE = 32
					local KOTH_HITBOX_FORWARD_EXTEND = 70
					local KOTH_HITBOX_RADIUS = 95
					local KOTH_HITBOX_MAX_SIZE = 200
					-- Snapshot of Workspace.Scene.Ground.GroundPart (hardcoded — part may not exist in live game)
					local PVP_GROUND_CFRAME = CFrame.new(1303.301, 74.194, -71.574)
					local PVP_GROUND_SIZE = Vector3.new(1330.600, 17.119, 2047.687)
					local SAFE_ZONE_HUB_PADDING = Vector3.new(24, 50, 24)
					local AUTO_GOALS_POLL = 0.18
					local AUTO_GOALS_TOUCH_SETTLE = 0.08
					local AUTO_GOALS_AFTER_TOUCH_DELAY = 0.55
					local AUTO_GOALS_POST_KICK_SETTLE = 0.12
					local AUTO_GOALS_BALL_ATTEMPT_TIMEOUT = 3
					local AUTO_GOALS_NEAR_PLAYER_RADIUS = 16
					local AUTO_GOALS_BALL_TO_PLAYER_STEPS = 10
					local AUTO_GOALS_BALL_TO_PLAYER_STEP_WAIT = 0.03
					local AUTO_GOALS_BALL_INSIDE_HOLD = 0.5
					local AUTO_GOALS_BALL_INSIDE_SMOOTH_STEPS = 12
					local AUTO_GOALS_BALL_INSIDE_SMOOTH_STEP_WAIT = 0.025
					local AUTO_GOALS_BALL_ON_PLAYER_EMBED = 0.65
					local AUTO_GOALS_UNDERGROUND_DEPTH = 28
					local AUTO_GOALS_UNDERGROUND_DROP_STEPS = 8
					local AUTO_GOALS_UNDERGROUND_TRAVEL_STEPS = 22
					local AUTO_GOALS_UNDERGROUND_RISE_STEPS = 14
					local AUTO_GOALS_UNDERGROUND_STEP_WAIT = 0.03
					local AUTO_GOALS_GOAL_SLIDE_STEPS = 18
					local AUTO_GOALS_GOAL_SLIDE_STEP_WAIT = 0.035
					local AUTO_GOALS_SCORE_RADIUS = 20
					local AUTO_GOALS_SPAWN_RADIUS = 28
					local AUTO_GOALS_TOUCH_FORWARD_OFFSET = 2
					local AUTO_GOALS_MIDFIELD_POSITION = Vector3.new(19380, 686.659, -1985.6)
					local FISHING_ZONE_TAG = "FishingZone"
					local FISHING_ZONE_Y_TOLERANCE = 6
					local FISHING_PHASE_IDLE = 0
					local FISHING_PHASE_CAST = 1
					local FISHING_PHASE_WAITING = 2
					local FISHING_PHASE_REELING = 3
					local FISHING_PHASE_CATCH = 4
					local AUTO_FISH_POLL = 0.35
					local AUTO_FISH_CAST_TIMEOUT = 45
					local AUTO_MINE_RACE_SPEED = 100
					local AUTO_MINE_RACE_RESPAWN = Vector3.new(20433.5, 702.222, -1688.27)
					local AUTO_MINE_RACE_COLOR_TOL = 20
					local AUTO_MINE_RACE_MINE_RGB = { 255, 99, 99 }
					local AUTO_MINE_RACE_SAFE_RGB = { 109, 193, 0 }
					local AUTO_MINE_RACE_GRAY_RGB = { 60, 61, 74 }
					local AUTO_MINE_RACE_ROW_COUNT = 20
					local AUTO_MINE_RACE_RESET_WAIT = 3.5
					local AUTO_MINE_RACE_FINISH_WAIT = 10.5
					local AUTO_MINE_RACE_POLL = 0.02
					local AUTO_QUEST_ORB_MESH_ID = "7036884767"
					local AUTO_QUEST_TWEEN_SPEED = 250
					local AUTO_QUEST_EGG_TELEPORT = CFrame.new(1910.08, 204.22, -976.7)
					local AUTO_QUEST_POLL = 0.05
					local AUTO_QUEST_EGG_VISITED_TTL = 3
					local QUEST_PET_HATCH_SLOT = {
						id = "pet_1",
						kind = "pet",
						index = 1,
						title = "Pet 1",
						desc = "5,000 gold — Cave crate",
					}
					local QUEST_KEY_TO_KIND = {
						orb_quest = "Orb",
						egg_collection_quest = "Egg",
						dungeon_boss_quest = "Boss",
						temple_boss_quest = "Boss",
						fishing_quest = "Fishing",
						pet_hatch_quest = "PetHatch",
						chest_quest = "Chest",
						upgrade_quest = "Upgrade",
						swing_quest = "Swing",
						city_routine_quest = "CityRoutine",
						kill_quest = "ArenaKill",
						arena_wins_quest = "Arena",
						arena_quest = "Arena",
					}
					local QUEST_KEY_TO_TARGET = {
						dungeon_boss_quest = "Borock",
						temple_boss_quest = "DemonKing",
					}
					local NEWBIE_STAGE_KIND = {
						swing = "Swing",
						chest = "Chest",
						equip = "ItemEquip",
						orbs = "Orb",
						upgrade = "Upgrade",
						hatch = "PetHatch",
						petequip = "PetEquip",
						accept = "QuestAccept",
						turnin = "QuestTurnIn",
						arena = "Arena",
						fish = "Fishing",
					}
					local AUTO_UPGRADE_ROD_POLL = 1.5
					local AUTO_UPGRADE_ROD_BUY_COOLDOWN = 1.3
					local AUTO_GOALS_BALL_ORDER = { "Ball2", "Ball1", "Ball" }
					local AUTO_GOALS_BALL_COLLISION_GROUP = "ExonHubBeachBall"
					local BEACH_BALLS_PATH = { "Scene", "Beach", "Beachballs" }
					local BEACH_GOALS_PATH = { "Scene", "Beach", "Goals" }
					local FISH_AREA_PATH = { "Scene", "Beach", "FishArea" }
					local AUTO_BOSS_OPTION_LABELS = { "Borock", "Demon King" }
					local AUTO_BOSS_LABEL_TO_ID = {
						["Borock"] = "borock",
						["Demon King"] = "demon_king",
					}
					local AUTO_BOSS_DEFS = {
						borock = {
							id = "borock",
							label = "Borock",
							folderPath = { "NPC", "Boss" },
							modelName = "Borock",
							useBossVals = true,
						},
						demon_king = {
							id = "demon_king",
							label = "Demon King",
							folderPath = { "NPC", "DemonKing" },
							modelName = "DemonKing",
							useBossVals = false,
						},
					}
					local AUTO_BOSS_ORDER = { "borock", "demon_king" }

					local ReplicatedStorage = game:GetService("ReplicatedStorage")

					function H.getGlobal()
						if getrenv then
							local ok, env = pcall(getrenv)
							if ok and type(env) == "table" and type(env._G) == "table" then
								return env._G
							end
						end
						return _G
					end

					function H.setStatus(_text)
						-- status is UI-only; never spam F9
					end

					function H.truncateText(text, maxLen)
						text = tostring(text or "")
						if #text <= maxLen then
							return text
						end
						return text:sub(1, maxLen - 3) .. "..."
					end

					function H.disconnectUiRotation(which)
						local key = which == "topbar" and "topbarIconRotationConn" or "minimizedIconRotationConn"
						local conn = S[key]
						if conn then
							pcall(function()
								conn:Disconnect()
							end)
							S[key] = nil
						end
					end

					function H.startUiRotation(guiObject, speedDegreesPerSecond, ownerKey)
						if not guiObject then
							return nil
						end

						if ownerKey == "topbar" then
							H.disconnectUiRotation("topbar")
						elseif ownerKey == "minimized" then
							H.disconnectUiRotation("minimized")
						end

						local speed = speedDegreesPerSecond or EXONHUB_ICON_ROTATION_SPEED
						local conn
						conn = RunService.Heartbeat:Connect(function(dt)
							local ok = pcall(function()
								if not guiObject.Parent then
									if conn then
										pcall(function()
											conn:Disconnect()
										end)
									end
									return
								end
								guiObject.Rotation = (guiObject.Rotation + speed * dt) % 360
							end)
							if not ok and conn then
								pcall(function()
									conn:Disconnect()
								end)
								if ownerKey == "topbar" then
									S.topbarIconRotationConn = nil
								elseif ownerKey == "minimized" then
									S.minimizedIconRotationConn = nil
								end
							end
						end)

						trackExonHubConnection(conn)
						if ownerKey == "topbar" then
							S.topbarIconRotationConn = conn
						elseif ownerKey == "minimized" then
							S.minimizedIconRotationConn = conn
						end
						return conn
					end

					function H.applyExonHubWindowIcon(window)
						task.spawn(function()
							pcall(function()
								local ContentProvider = game:GetService("ContentProvider")
								ContentProvider:PreloadAsync({ EXONHUB_ICON_ASSET })
							end)

							pcall(function()
								if window.SetIconSize then
									window:SetIconSize(EXONHUB_TOPBAR_ICON_SIZE)
								end
							end)

							for _ = 1, 15 do
								task.wait(0.25)
								local topbarLeft
								pcall(function()
									topbarLeft = window.UIElements.Main.Main.Topbar.Left
								end)
								if not topbarLeft then
									continue
								end

								local iconHolder = topbarLeft:FindFirstChild("ExonHubIcon")
								local imageLabel = iconHolder and iconHolder:FindFirstChildWhichIsA("ImageLabel", true)

								if not iconHolder then
									iconHolder = Instance.new("Frame")
									iconHolder.Name = "ExonHubIcon"
									iconHolder.BackgroundTransparency = 1
									iconHolder.LayoutOrder = 0
									iconHolder.Parent = topbarLeft
								end

								iconHolder.Size = UDim2.fromOffset(EXONHUB_TOPBAR_ICON_SIZE, EXONHUB_TOPBAR_ICON_SIZE)
								iconHolder.AnchorPoint = Vector2.new(0.5, 0.5)

								if not imageLabel then
									imageLabel = Instance.new("ImageLabel")
									imageLabel.BackgroundTransparency = 1
									imageLabel.Size = UDim2.fromScale(1, 1)
									imageLabel.ScaleType = Enum.ScaleType.Fit
									imageLabel.Parent = iconHolder
								end

								imageLabel.Image = EXONHUB_ICON_ASSET
								imageLabel.ImageColor3 = Color3.new(1, 1, 1)
								imageLabel.ImageTransparency = 0
								imageLabel.Visible = true

								H.startUiRotation(iconHolder, EXONHUB_ICON_ROTATION_SPEED, "topbar")

								return
							end
						end)
					end

					function H.buildExonHubMinimizedUi()
						local gui = Instance.new("ScreenGui")
						gui.Name = "ExonHubMinimizedGui"
						gui.ResetOnSpawn = false
						gui.IgnoreGuiInset = false
						gui.DisplayOrder = 999999
						gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

						local minimized = Instance.new("ImageLabel")
						minimized.Name = "ExonHubMinimized"
						minimized.Size = EXONHUB_MINIMIZED_SIZE
						minimized.Position = EXONHUB_MINIMIZED_POSITION
						minimized.AnchorPoint = Vector2.new(0.5, 0.5)
						minimized.BackgroundColor3 = Color3.new(0, 0, 0.22352942824363708)
						minimized.BackgroundTransparency = 0
						minimized.BorderSizePixel = 0
						minimized.Image = EXONHUB_ICON_ASSET
						minimized.ImageColor3 = Color3.new(1, 1, 1)
						minimized.ImageTransparency = 0
						minimized.ScaleType = Enum.ScaleType.Fit
						minimized.ZIndex = 1000000000
						minimized.LayoutOrder = 1
						minimized.Active = true
						minimized.Interactable = true
						minimized.Visible = false
						minimized.Parent = gui

						local corner = Instance.new("UICorner")
						corner.CornerRadius = UDim.new(1, 0)
						corner.Parent = minimized

						local aspect = Instance.new("UIAspectRatioConstraint")
						aspect.AspectRatio = 1.0003353357315064
						aspect.AspectType = Enum.AspectType.FitWithinMaxSize
						aspect.DominantAxis = Enum.DominantAxis.Width
						aspect.Parent = minimized

						local strokeCenter = Instance.new("UIStroke")
						strokeCenter.Color = Color3.new(0, 0, 0.13333334028720856)
						strokeCenter.Thickness = 0.019999999552965165
						strokeCenter.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
						strokeCenter.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
						strokeCenter.BorderStrokePosition = Enum.BorderStrokePosition.Center
						strokeCenter.Transparency = 0
						strokeCenter.LineJoinMode = Enum.LineJoinMode.Round
						strokeCenter.Parent = minimized

						local strokeInner = Instance.new("UIStroke")
						strokeInner.Color = Color3.new(1, 1, 1)
						strokeInner.Thickness = 0.05000000074505806
						strokeInner.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
						strokeInner.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
						strokeInner.BorderStrokePosition = Enum.BorderStrokePosition.Inner
						strokeInner.Transparency = 0.8299999833106995
						strokeInner.LineJoinMode = Enum.LineJoinMode.Round
						strokeInner.Parent = minimized

						local strokeOuter = Instance.new("UIStroke")
						strokeOuter.Color = Color3.new(0, 0, 0)
						strokeOuter.Thickness = 0.05000000074505806
						strokeOuter.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
						strokeOuter.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
						strokeOuter.BorderStrokePosition = Enum.BorderStrokePosition.Outer
						strokeOuter.Transparency = 0.8299999833106995
						strokeOuter.LineJoinMode = Enum.LineJoinMode.Round
						strokeOuter.Parent = minimized

						local uiScale = Instance.new("UIScale")
						uiScale.Name = "PulseScale"
						uiScale.Scale = 1
						uiScale.Parent = minimized

						local guiParent = playerGui
						pcall(function()
							if typeof(gethui) == "function" then
								local hui = gethui()
								if hui then
									guiParent = hui
								end
							end
						end)
						gui.Parent = guiParent
						return minimized, gui, {
							uiScale = uiScale,
							strokes = { strokeCenter, strokeInner, strokeOuter },
							strokeRestTransparency = { 0, 0.8299999833106995, 0.8299999833106995 },
						}
					end

					function H.disconnectMinimizedDragConns()
						if type(S.minimizedDragConns) ~= "table" then
							S.minimizedDragConns = nil
							return
						end
						for _, conn in ipairs(S.minimizedDragConns) do
							pcall(function()
								if conn and conn.Disconnect then
									conn:Disconnect()
								end
							end)
						end
						S.minimizedDragConns = nil
					end

					function H.createExonHubFloatingToggle(window)
						local TweenService = game:GetService("TweenService")
						local UserInputService = game:GetService("UserInputService")

						H.disconnectMinimizedDragConns()

						local minimized, gui, uiMeta = H.buildExonHubMinimizedUi()

						minimized.Visible = false
						minimized.Active = true
						minimized.Interactable = true

						local toggleVisible = false
						local windowDestroyed = false
						local allowMinimized = true
						local dragging = false
						local dragStartPos = nil
						local dragStartElementPos = nil
						local savedPosition = minimized.Position
						local savedSize = minimized.Size
						local savedAnchorPoint = minimized.AnchorPoint
						local savedZIndex = minimized.ZIndex
						local strokes = uiMeta.strokes
						local strokeRest = uiMeta.strokeRestTransparency
						local pulseScale = uiMeta.uiScale
						local pulseConn = nil
						local fadeInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

						local function stopPulse()
							if pulseConn then
								pulseConn:Disconnect()
								pulseConn = nil
							end
							if pulseScale then
								pulseScale.Scale = 1
							end
						end

						local function startPulse()
							stopPulse()
							if not pulseScale then
								return
							end
							local baseTime = os.clock()
							pulseConn = trackExonHubConnection(RunService.Heartbeat:Connect(function()
								local ok = pcall(function()
									if not toggleVisible or not minimized.Parent then
										stopPulse()
										return
									end
									local elapsed = os.clock() - baseTime
									pulseScale.Scale = 1 + math.sin(elapsed * 3.2) * EXONHUB_MINIMIZED_PULSE
								end)
								if not ok then
									stopPulse()
								end
							end))
						end

						H.startUiRotation(minimized, EXONHUB_ICON_ROTATION_SPEED, "minimized")

						local function destroyMinimizedUi()
							allowMinimized = false
							toggleVisible = false
							stopPulse()
							H.disconnectMinimizedDragConns()
							minimized.Visible = false
							if gui and gui.Parent then
								gui:Destroy()
							end
							UI.floatingToggle = nil
							UI.floatingToggleGui = nil
						end

						local function isWindowOpen()
							local isOpen = false
							pcall(function()
								local main = window.UIElements and window.UIElements.Main
								if main then
									isOpen = main.Visible == true
								end
							end)
							return isOpen
						end

						local function tweenFade(show)
							local imageGoal = show and 0 or 1
							local bgGoal = show and 0 or 1

							TweenService:Create(minimized, fadeInfo, {
								ImageTransparency = imageGoal,
								BackgroundTransparency = bgGoal,
							}):Play()

							for index, stroke in ipairs(strokes) do
								local restTransparency = strokeRest[index] or 0
								local strokeGoal = show and restTransparency or 1
								TweenService:Create(stroke, fadeInfo, {
									Transparency = strokeGoal,
								}):Play()
							end
						end

						local function showToggle()
							if not allowMinimized or windowDestroyed or toggleVisible then
								return
							end
							toggleVisible = true
							minimized.Position = savedPosition
							minimized.Size = savedSize
							minimized.AnchorPoint = savedAnchorPoint
							minimized.ZIndex = savedZIndex
							minimized.Visible = true
							minimized.ImageTransparency = 1
							minimized.BackgroundTransparency = 1
							for _, stroke in ipairs(strokes) do
								stroke.Transparency = 1
							end
							tweenFade(true)
							startPulse()
						end

						local function hideToggle()
							if not toggleVisible then
								return
							end
							toggleVisible = false
							stopPulse()
							tweenFade(false)
							task.delay(0.3, function()
								if not toggleVisible then
									minimized.Visible = false
								end
							end)
						end

						local function openWindow()
							pcall(function()
								if window.Open then
									window:Open()
								elseif window.Toggle then
									window:Toggle()
								end
							end)
						end

						local function onPointerDown(input)
							if
								input.UserInputType ~= Enum.UserInputType.MouseButton1
								and input.UserInputType ~= Enum.UserInputType.Touch
							then
								return
							end
							dragging = true
							dragStartPos = input.Position
							dragStartElementPos = minimized.Position
						end

						local function onPointerMove(input)
							if not dragging then
								return
							end
							if
								input.UserInputType ~= Enum.UserInputType.MouseMovement
								and input.UserInputType ~= Enum.UserInputType.Touch
							then
								return
							end
							local delta = input.Position - dragStartPos
							minimized.Position = UDim2.new(
								dragStartElementPos.X.Scale,
								dragStartElementPos.X.Offset + delta.X,
								dragStartElementPos.Y.Scale,
								dragStartElementPos.Y.Offset + delta.Y
							)
						end

						local function onPointerUp(input)
							if
								input.UserInputType ~= Enum.UserInputType.MouseButton1
								and input.UserInputType ~= Enum.UserInputType.Touch
							then
								return
							end
							if not dragging then
								return
							end

							local moved = dragStartPos and (input.Position - dragStartPos).Magnitude or 999
							dragging = false
							savedPosition = minimized.Position

							if moved < 8 then
								openWindow()
							end
						end

						S.minimizedDragConns = {
							minimized.InputBegan:Connect(onPointerDown),
							UserInputService.InputChanged:Connect(onPointerMove),
							minimized.InputEnded:Connect(onPointerUp),
							UserInputService.InputEnded:Connect(onPointerUp),
						}

						pcall(function()
							window:OnOpen(function()
								hideToggle()
							end)
							window:OnClose(function()
								if allowMinimized and not windowDestroyed then
									showToggle()
								end
							end)
							window:OnDestroy(function()
								windowDestroyed = true
								destroyMinimizedUi()
							end)
						end)

						pcall(function()
							if window.EditOpenButton then
								window:EditOpenButton({ Enabled = false })
							end
						end)

						task.spawn(function()
							local lastOpen = isWindowOpen()
							while not windowDestroyed and allowMinimized do
								task.wait(0.12)
								if windowDestroyed or not allowMinimized then
									break
								end
								local isOpen = isWindowOpen()
								if isOpen == lastOpen then
									continue
								end
								lastOpen = isOpen
								if isOpen then
									hideToggle()
								else
									showToggle()
								end
							end
						end)

						UI.floatingToggle = minimized
						UI.floatingToggleGui = gui
					end

					function H.httpRequest(url, method, headers, body)
						local HttpService = game:GetService("HttpService")
						local requestFunc = (syn and syn.request)
							or (http and http.request)
							or request
							or (fluxus and fluxus.request)
							or (krnl and krnl.request)

						if type(requestFunc) == "function" then
							local ok, response = pcall(function()
								return requestFunc({
									Url = url,
									url = url,
									Method = method or "GET",
									method = method or "GET",
									Headers = headers or {},
									headers = headers or {},
									Body = body,
									body = body,
								})
							end)
							if ok and type(response) == "table" then
								local status = response.StatusCode or response.Status or response.statusCode
								local responseBody = response.Body or response.body
								local success = (status and status >= 200 and status < 300) or response.Success == true

								if success then
									if method == "POST" then
										if type(responseBody) == "string" and responseBody ~= "" then
											return responseBody
										end
										return true
									end
									if type(responseBody) == "string" and responseBody ~= "" then
										return responseBody
									end
									return true
								end

								if type(responseBody) == "string" and responseBody ~= "" then
									return responseBody
								end
							end
						end

						if method == "POST" and body then
							local ok = pcall(function()
								HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
							end)
							if ok then
								return true
							end
						end

						local ok, result = pcall(function()
							return HttpService:GetAsync(url, true, headers or {})
						end)
						if ok then
							return result
						end
						return nil
					end

					function H.postDiscordWebhook(webhook, payload)
						local HttpService = game:GetService("HttpService")
						local ok, json = pcall(function()
							return HttpService:JSONEncode(payload)
						end)
						if not ok or not json then
							warn("[ExonHub] Discord payload encode failed:", json)
							return false
						end

						local result = H.httpRequest(webhook, "POST", { ["Content-Type"] = "application/json" }, json)
						if result then
							return true
						end

						local posted, err = pcall(function()
							HttpService:PostAsync(webhook, json, Enum.HttpContentType.ApplicationJson)
						end)
						if not posted then
							warn("[ExonHub] Discord webhook failed:", err)
						end
						return posted
					end

					function H.tryCaptureScreenshot()
						local function normalizeCapture(result)
							if type(result) ~= "string" or #result <= 128 then
								return nil
							end
							if result:sub(1, 8) == "iVBORw0K" then
								local decoded = game:GetService("HttpService"):Base64Decode(result)
								if type(decoded) == "string" and #decoded > 128 then
									return decoded, "screenshot.png", "image/png"
								end
							end
							if result:sub(1, 4) == "\137PNG" or result:sub(1, 2) == "\255\216" then
								local ext = result:sub(1, 4) == "\137PNG" and "png" or "jpg"
								return result, "screenshot." .. ext, ext == "png" and "image/png" or "image/jpeg"
							end
							return nil
						end

						local function tryPathCapture(path)
							if not H.canFilesystemPersist() or not isfile or not readfile then
								return nil
							end
							if makefolder then
								pcall(makefolder, "ExonHub")
							end
							local ok = pcall(function()
								if type(screenshot) == "function" then
									screenshot(path)
								elseif type(getscreenshot) == "function" then
									getscreenshot(path)
								elseif syn and type(syn.capture) == "function" then
									syn.capture(path)
								elseif type(capture_screen) == "function" then
									capture_screen(path)
								else
									error("no path screenshot api")
								end
							end)
							if not ok then
								return nil
							end
							task.wait(0.15)
							if isfile(path) then
								local readOk, data = pcall(readfile, path)
								if readOk and type(data) == "string" and #data > 128 then
									return data, "screenshot.png", "image/png"
								end
							end
							return nil
						end

						local candidates = {
							function()
								if type(screenshot) == "function" then
									return screenshot()
								end
							end,
							function()
								if type(getscreenshot) == "function" then
									return getscreenshot()
								end
							end,
							function()
								if syn and type(syn.capture) == "function" then
									return syn.capture()
								end
							end,
							function()
								if type(capture_screen) == "function" then
									return capture_screen()
								end
							end,
							function()
								if fluxus and type(fluxus.capture) == "function" then
									return fluxus.capture()
								end
							end,
							function()
								if krnl and type(krnl.capture) == "function" then
									return krnl.capture()
								end
							end,
						}

						for _, fn in ipairs(candidates) do
							local ok, result = pcall(fn)
							if ok then
								local data, name, mime = normalizeCapture(result)
								if data then
									return data, name, mime
								end
							end
						end

						local pathCandidates = {
							"ExonHub/discord_screenshot.png",
							"discord_screenshot.png",
							"screenshot.png",
							"ExonHub/screenshot.png",
							"workspace/screenshot.png",
						}

						for _, path in ipairs(pathCandidates) do
							local data, name, mime = tryPathCapture(path)
							if data then
								return data, name, mime
							end
						end

						if H.canFilesystemPersist() and isfile and readfile then
							for _, path in ipairs(pathCandidates) do
								local existsOk, exists = pcall(isfile, path)
								if existsOk and exists then
									local readOk, data = pcall(readfile, path)
									if readOk and type(data) == "string" and #data > 128 then
										return data, "screenshot.png", "image/png"
									end
								end
							end
						end

						local executorName = select(1, H.getExecutorInfo()) or "Unknown"
						warn("[ExonHub] Discord log screenshot skipped —", executorName, "has no screenshot API (log still sends with headshot)")
						return nil
					end

					function H.postDiscordWebhookWithFile(webhook, payload, fileName, fileData, contentType)
						local HttpService = game:GetService("HttpService")
						if type(fileData) ~= "string" or fileData == "" then
							return H.postDiscordWebhook(webhook, payload)
						end

						local okJson, json = pcall(function()
							return HttpService:JSONEncode(payload)
						end)
						if not okJson or not json then
							return false
						end

						local boundary = "----ExonHubBoundary" .. tostring(os.time())
						local body = table.concat({
							"--" .. boundary,
							'Content-Disposition: form-data; name="payload_json"',
							"",
							json,
							"--" .. boundary,
							'Content-Disposition: form-data; name="files[0]"; filename="' .. fileName .. '"',
							"Content-Type: " .. (contentType or "application/octet-stream"),
							"",
							fileData,
							"--" .. boundary .. "--",
							"",
						}, "\r\n")

						local requestFunc = (syn and syn.request)
							or (http and http.request)
							or request
							or (fluxus and fluxus.request)
							or (krnl and krnl.request)

						if type(requestFunc) ~= "function" then
							return H.postDiscordWebhook(webhook, payload)
						end

						local posted, response = pcall(function()
							return requestFunc({
								Url = webhook,
								url = webhook,
								Method = "POST",
								method = "POST",
								Headers = {
									["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
								},
								headers = {
									["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
								},
								Body = body,
								body = body,
							})
						end)

						if posted and type(response) == "table" then
							local status = response.StatusCode or response.Status or response.statusCode
							if (status and status >= 200 and status < 300) or response.Success == true then
								return true
							end
						end

						return H.postDiscordWebhook(webhook, payload)
					end

					function H.getExecutorInfo()
						local name = "Unknown"
						if type(identifyexecutor) == "function" then
							local ok, a, b = pcall(identifyexecutor)
							if ok then
								name = tostring(b or a or name)
							end
						elseif type(getexecutorname) == "function" then
							local ok, result = pcall(getexecutorname)
							if ok and result then
								name = tostring(result)
							end
						end

						local hwid = nil
						if type(gethwid) == "function" then
							local ok, result = pcall(gethwid)
							if ok and result then
								hwid = tostring(result)
							end
						end

						return name, hwid
					end

					function H.generateGateCode()
						local chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
						local code = "EXON-"
						for _ = 1, 6 do
							local index = math.random(1, #chars)
							code = code .. string.sub(chars, index, index)
						end
						return code
					end

					function H.getGateHwid()
						local _, hwid = H.getExecutorInfo()
						if type(hwid) == "string" and hwid ~= "" then
							return hwid
						end
						return tostring(player.UserId)
					end

					function H.loadGateSession()
						if not H.canFilesystemPersist() or not isfile(EXONHUB_GATE_FILE) then
							return nil
						end
						local ok, raw = pcall(readfile, EXONHUB_GATE_FILE)
						if not ok or type(raw) ~= "string" or raw == "" then
							return nil
						end
						local HttpService = game:GetService("HttpService")
						local decodeOk, data = pcall(function()
							return HttpService:JSONDecode(raw)
						end)
						if decodeOk and type(data) == "table" then
							return data
						end
						return nil
					end

					function H.saveGateSession(data)
						if not H.canFilesystemPersist() or type(data) ~= "table" then
							return false
						end
						if makefolder then
							pcall(makefolder, "ExonHub")
						end
						local HttpService = game:GetService("HttpService")
						local ok, json = pcall(function()
							return HttpService:JSONEncode(data)
						end)
						if not ok or not json then
							return false
						end
						return pcall(writefile, EXONHUB_GATE_FILE, json)
					end

					function H.isGateSessionValid(session)
						if type(session) ~= "table" then
							return false
						end
						if session.userId ~= player.UserId then
							return false
						end
						if tostring(session.hwid or "") ~= tostring(H.getGateHwid()) then
							return false
						end
						local expiresAt = tonumber(session.expiresAt)
						if not expiresAt or os.time() >= expiresAt then
							return false
						end
						return session.verified == true and type(session.discordUserId) == "string" and session.discordUserId ~= ""
					end

					function H.applyGateSessionToState(session)
						if type(session) ~= "table" then
							return
						end
						S.discordGate = {
							discordUserId = session.discordUserId,
							discordUsername = session.discordUsername,
							discordGlobalName = session.discordGlobalName,
							discordDisplayName = session.discordDisplayName,
						}
					end

					function H.buildGateSessionFromDiscord(discordInfo, code, expiresAtOverride)
						local expiresAt = tonumber(expiresAtOverride) or (os.time() + EXONHUB_GATE_TTL_SECONDS)
						local session = {
							userId = player.UserId,
							hwid = H.getGateHwid(),
							code = code,
							verified = true,
							expiresAt = expiresAt,
							discordUserId = tostring(discordInfo.userId or discordInfo.id or ""),
							discordUsername = tostring(discordInfo.username or ""),
							discordGlobalName = tostring(discordInfo.globalName or discordInfo.displayName or ""),
							discordDisplayName = tostring(discordInfo.displayName or discordInfo.globalName or ""),
							savedAt = os.time(),
						}
						H.saveGateSession(session)
						H.applyGateSessionToState(session)
						return session
					end

					function H.copyToClipboard(text)
						if type(setclipboard) == "function" then
							pcall(setclipboard, text)
							return true
						end
						if type(toclipboard) == "function" then
							pcall(toclipboard, text)
							return true
						end
						return false
					end

					function H.getGateApiHeaders(extra)
						local headers = {
							["Content-Type"] = "application/json",
							["ngrok-skip-browser-warning"] = "1",
						}
						if type(extra) == "table" then
							for key, value in pairs(extra) do
								headers[key] = value
							end
						end
						return headers
					end

					function H.isGateApiOnline()
						local api = EXONHUB_GATE_API
						if type(api) ~= "string" or api == "" then
							return false
						end
						api = api:gsub("/+$", "")
						local body = H.httpRequest(api .. "/health", "GET", H.getGateApiHeaders())
						if type(body) ~= "string" or body == "" then
							return false
						end
						local HttpService = game:GetService("HttpService")
						local ok, data = pcall(function()
							return HttpService:JSONDecode(body)
						end)
						return ok and type(data) == "table" and data.ok == true
					end

					function H.registerGateSession()
						local HttpService = game:GetService("HttpService")
						local api = EXONHUB_GATE_API
						if type(api) ~= "string" or api == "" then
							return false, "Gate API URL not set in ExonHub.Lua (EXONHUB_GATE_API)."
						end
						api = api:gsub("/+$", "")
						local payload = HttpService:JSONEncode({
							userId = player.UserId,
							hwid = H.getGateHwid(),
							username = player.Name,
							displayName = player.DisplayName,
							forceNew = EXONHUB_GATE_ALWAYS_VERIFY == true,
						})
						local body = H.httpRequest(api .. "/api/register", "POST", H.getGateApiHeaders(), payload)
						if body == true then
							return false, "Empty response from gate server."
						end
						if type(body) ~= "string" or body == "" then
							return false, "Could not reach Discord gate bot. Check EXONHUB_GATE_API."
						end
						local ok, data = pcall(function()
							return HttpService:JSONDecode(body)
						end)
						if not ok or type(data) ~= "table" or data.ok ~= true then
							return false, "Gate server rejected registration."
						end
						return true, data
					end

					function H.checkGateCode(code)
						local HttpService = game:GetService("HttpService")
						local api = EXONHUB_GATE_API:gsub("/+$", "")
						local url = api .. "/api/check?code=" .. HttpService:UrlEncode(code)
						local body = H.httpRequest(url, "GET", H.getGateApiHeaders())
						if type(body) ~= "string" or body == "" then
							return false, nil
						end
						local ok, data = pcall(function()
							return HttpService:JSONDecode(body)
						end)
						if ok and type(data) == "table" and data.verified == true then
							return true, data.discord
						end
						return false, nil
					end

					function H.destroyGateUi()
						if UI.gateConns then
							for _, conn in ipairs(UI.gateConns) do
								pcall(function()
									if conn and conn.Disconnect then
										conn:Disconnect()
									end
								end)
							end
							UI.gateConns = nil
						end
						if UI.gateGui then
							pcall(function()
								UI.gateGui:Destroy()
							end)
							UI.gateGui = nil
						end
						UI.gateStatusLabel = nil
						UI.gateCodeLabel = nil
						UI.gateStatusDot = nil
						if UI.gateLoadingGui then
							pcall(function()
								UI.gateLoadingGui:Destroy()
							end)
							UI.gateLoadingGui = nil
						end
						if UI.gateWindow then
							pcall(function()
								if UI.gateWindow.Destroy then
									UI.gateWindow:Destroy()
								end
							end)
							UI.gateWindow = nil
						end
						UI.windUI = nil
						local gate = playerGui:FindFirstChild("ExonHubDiscordGate")
						if gate then
							pcall(function()
								gate:Destroy()
							end)
						end
					end

					function H.setGateStatus(text)
						if UI.gateStatusLabel then
							UI.gateStatusLabel.Text = text
						end
					end

					function H.trackGateConn(conn)
						if not UI.gateConns then
							UI.gateConns = {}
						end
						table.insert(UI.gateConns, conn)
						return conn
					end

					function H.tweenGate(instance, props, duration, style, direction)
						local tween = TweenService:Create(
							instance,
							TweenInfo.new(duration or 0.22, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
							props
						)
						tween:Play()
						return tween
					end

					function H.makeGateDraggable(frame, handle)
						local dragging = false
						local dragStart = nil
						local startPos = nil

						local function onDragInput(input)
							if not dragging then
								return
							end
							if input.UserInputType ~= Enum.UserInputType.MouseMovement
								and input.UserInputType ~= Enum.UserInputType.Touch then
								return
							end
							local delta = input.Position - dragStart
							frame.Position = UDim2.new(
								startPos.X.Scale,
								startPos.X.Offset + delta.X,
								startPos.Y.Scale,
								startPos.Y.Offset + delta.Y
							)
						end

						H.trackGateConn(handle.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1
								or input.UserInputType == Enum.UserInputType.Touch then
								dragging = true
								dragStart = input.Position
								startPos = frame.Position
							end
						end))
						H.trackGateConn(UserInputService.InputChanged:Connect(onDragInput))
						H.trackGateConn(UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1
								or input.UserInputType == Enum.UserInputType.Touch then
								dragging = false
							end
						end))
					end

					function H.makeGateActionRow(parent, layoutOrder, title, subtitle, onClick)
						local row = Instance.new("TextButton")
						row.Name = "Action" .. tostring(layoutOrder)
						row.Size = UDim2.new(1, 0, 0, 48)
						row.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
						row.BackgroundTransparency = 0
						row.BorderSizePixel = 0
						row.AutoButtonColor = false
						row.Text = ""
						row.LayoutOrder = layoutOrder
						row.Parent = parent

						local corner = Instance.new("UICorner")
						corner.CornerRadius = UDim.new(0, 8)
						corner.Parent = row

						local stroke = Instance.new("UIStroke")
						stroke.Color = Color3.fromRGB(45, 45, 45)
						stroke.Transparency = 0.2
						stroke.Parent = row

						local titleLabel = Instance.new("TextLabel")
						titleLabel.BackgroundTransparency = 1
						titleLabel.Position = UDim2.fromOffset(12, 7)
						titleLabel.Size = UDim2.new(1, -24, 0, 16)
						titleLabel.Font = Enum.Font.GothamMedium
						titleLabel.TextSize = 14
						titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
						titleLabel.TextXAlignment = Enum.TextXAlignment.Left
						titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
						titleLabel.Text = title
						titleLabel.Parent = row

						local descLabel = Instance.new("TextLabel")
						descLabel.BackgroundTransparency = 1
						descLabel.Position = UDim2.fromOffset(12, 25)
						descLabel.Size = UDim2.new(1, -24, 0, 14)
						descLabel.Font = Enum.Font.Gotham
						descLabel.TextSize = 12
						descLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
						descLabel.TextXAlignment = Enum.TextXAlignment.Left
						descLabel.TextTruncate = Enum.TextTruncate.AtEnd
						descLabel.Text = subtitle
						descLabel.Parent = row

						H.trackGateConn(row.MouseEnter:Connect(function()
							H.tweenGate(row, { BackgroundColor3 = Color3.fromRGB(36, 36, 36) }, 0.12)
						end))
						H.trackGateConn(row.MouseLeave:Connect(function()
							H.tweenGate(row, { BackgroundColor3 = Color3.fromRGB(28, 28, 28) }, 0.12)
						end))
						H.trackGateConn(row.MouseButton1Click:Connect(function()
							if onClick then
								onClick()
							end
						end))

						return row
					end

					function H.createDiscordGateUi(code)
						H.destroyGateUi()

						local startCommand = "/start key:" .. code
						local theme = {
							window = Color3.fromRGB(12, 12, 12),
							sidebar = Color3.fromRGB(16, 16, 16),
							accent = Color3.fromRGB(88, 101, 242),
							code = Color3.fromRGB(130, 170, 255),
							dim = Color3.fromRGB(140, 140, 140),
						}

						local gui = Instance.new("ScreenGui")
						gui.Name = "ExonHubDiscordGate"
						gui.ResetOnSpawn = false
						gui.DisplayOrder = 999
						gui.Parent = playerGui

						local root = Instance.new("Frame")
						root.Name = "Window"
						root.AnchorPoint = Vector2.new(0.5, 0.5)
						root.Size = UDim2.fromOffset(540, 460)
						root.Position = UDim2.new(0.5, 0, 0.5, 0)
						root.BackgroundColor3 = theme.window
						root.BorderSizePixel = 0
						root.Parent = gui

						local rootScale = Instance.new("UIScale")
						rootScale.Scale = 0.96
						rootScale.Parent = root

						local rootCorner = Instance.new("UICorner")
						rootCorner.CornerRadius = UDim.new(0, 12)
						rootCorner.Parent = root

						local rootStroke = Instance.new("UIStroke")
						rootStroke.Color = Color3.fromRGB(55, 55, 55)
						rootStroke.Transparency = 0.35
						rootStroke.Parent = root

						H.tweenGate(rootScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

						local topBar = Instance.new("Frame")
						topBar.Name = "TopBar"
						topBar.Size = UDim2.new(1, 0, 0, 42)
						topBar.BackgroundTransparency = 1
						topBar.BorderSizePixel = 0
						topBar.Parent = root

						local topTitle = Instance.new("TextLabel")
						topTitle.BackgroundTransparency = 1
						topTitle.Position = UDim2.fromOffset(14, 10)
						topTitle.Size = UDim2.new(1, -28, 0, 22)
						topTitle.Font = Enum.Font.GothamBold
						topTitle.TextSize = 17
						topTitle.TextColor3 = Color3.new(1, 1, 1)
						topTitle.TextXAlignment = Enum.TextXAlignment.Left
						topTitle.Text = "Exon Hub"
						topTitle.Parent = topBar

						local dragHint = Instance.new("TextLabel")
						dragHint.BackgroundTransparency = 1
						dragHint.Position = UDim2.new(1, -110, 0, 12)
						dragHint.Size = UDim2.fromOffset(96, 18)
						dragHint.Font = Enum.Font.Gotham
						dragHint.TextSize = 11
						dragHint.TextColor3 = Color3.fromRGB(90, 90, 90)
						dragHint.TextXAlignment = Enum.TextXAlignment.Right
						dragHint.Text = "drag to move"
						dragHint.Parent = topBar

						H.makeGateDraggable(root, topBar)

						local body = Instance.new("Frame")
						body.Size = UDim2.new(1, -16, 1, -50)
						body.Position = UDim2.fromOffset(8, 42)
						body.BackgroundTransparency = 1
						body.Parent = root

						local sidebar = Instance.new("Frame")
						sidebar.Size = UDim2.new(0, 132, 1, 0)
						sidebar.BackgroundColor3 = theme.sidebar
						sidebar.BorderSizePixel = 0
						sidebar.Parent = body

						local sidebarCorner = Instance.new("UICorner")
						sidebarCorner.CornerRadius = UDim.new(0, 10)
						sidebarCorner.Parent = sidebar

						local launchLabel = Instance.new("TextLabel")
						launchLabel.BackgroundTransparency = 1
						launchLabel.Position = UDim2.fromOffset(10, 8)
						launchLabel.Size = UDim2.new(1, -12, 0, 12)
						launchLabel.Font = Enum.Font.GothamBold
						launchLabel.TextSize = 10
						launchLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
						launchLabel.TextXAlignment = Enum.TextXAlignment.Left
						launchLabel.Text = "LAUNCH"
						launchLabel.Parent = sidebar

						local navActive = Instance.new("Frame")
						navActive.Size = UDim2.new(1, -12, 0, 32)
						navActive.Position = UDim2.fromOffset(6, 28)
						navActive.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
						navActive.BorderSizePixel = 0
						navActive.Parent = sidebar

						local navCorner = Instance.new("UICorner")
						navCorner.CornerRadius = UDim.new(0, 6)
						navCorner.Parent = navActive

						local navAccent = Instance.new("Frame")
						navAccent.Size = UDim2.new(0, 2, 1, -6)
						navAccent.Position = UDim2.fromOffset(3, 3)
						navAccent.BackgroundColor3 = theme.accent
						navAccent.BorderSizePixel = 0
						navAccent.Parent = navActive

						local navAccentCorner = Instance.new("UICorner")
						navAccentCorner.CornerRadius = UDim.new(1, 0)
						navAccentCorner.Parent = navAccent

						local navLabel = Instance.new("TextLabel")
						navLabel.BackgroundTransparency = 1
						navLabel.Position = UDim2.fromOffset(12, 0)
						navLabel.Size = UDim2.new(1, -14, 1, 0)
						navLabel.Font = Enum.Font.GothamMedium
						navLabel.TextSize = 12
						navLabel.TextColor3 = Color3.new(1, 1, 1)
						navLabel.TextXAlignment = Enum.TextXAlignment.Left
						navLabel.Text = "Discord Verify"
						navLabel.Parent = navActive

						local content = Instance.new("Frame")
						content.Size = UDim2.new(1, -144, 1, 0)
						content.Position = UDim2.fromOffset(144, 0)
						content.BackgroundTransparency = 1
						content.BorderSizePixel = 0
						content.Parent = body

						local sectionTitle = Instance.new("TextLabel")
						sectionTitle.BackgroundTransparency = 1
						sectionTitle.Position = UDim2.fromOffset(4, 4)
						sectionTitle.Size = UDim2.new(1, -8, 0, 18)
						sectionTitle.Font = Enum.Font.GothamBold
						sectionTitle.TextSize = 14
						sectionTitle.TextColor3 = Color3.new(1, 1, 1)
						sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
						sectionTitle.Text = "Your Code"
						sectionTitle.Parent = content

						local codeBox = Instance.new("Frame")
						codeBox.Size = UDim2.new(1, -8, 0, 64)
						codeBox.Position = UDim2.fromOffset(4, 28)
						codeBox.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
						codeBox.BorderSizePixel = 0
						codeBox.Parent = content

						local codeCorner = Instance.new("UICorner")
						codeCorner.CornerRadius = UDim.new(0, 8)
						codeCorner.Parent = codeBox

						local codeStroke = Instance.new("UIStroke")
						codeStroke.Color = theme.accent
						codeStroke.Transparency = 0.65
						codeStroke.Parent = codeBox

						local codeCaption = Instance.new("TextLabel")
						codeCaption.BackgroundTransparency = 1
						codeCaption.Position = UDim2.fromOffset(12, 8)
						codeCaption.Size = UDim2.new(1, -24, 0, 12)
						codeCaption.Font = Enum.Font.Gotham
						codeCaption.TextSize = 11
						codeCaption.TextColor3 = theme.dim
						codeCaption.TextXAlignment = Enum.TextXAlignment.Left
						codeCaption.Text = "Session key"
						codeCaption.Parent = codeBox

						local codeLabel = Instance.new("TextLabel")
						codeLabel.Name = "Code"
						codeLabel.BackgroundTransparency = 1
						codeLabel.Position = UDim2.fromOffset(12, 24)
						codeLabel.Size = UDim2.new(1, -24, 0, 28)
						codeLabel.Font = Enum.Font.GothamBold
						codeLabel.TextSize = 22
						codeLabel.TextColor3 = theme.code
						codeLabel.TextXAlignment = Enum.TextXAlignment.Left
						codeLabel.Text = code
						codeLabel.Parent = codeBox

						local list = Instance.new("Frame")
						list.Size = UDim2.new(1, -8, 0, 212)
						list.Position = UDim2.fromOffset(4, 104)
						list.BackgroundTransparency = 1
						list.Parent = content

						local listLayout = Instance.new("UIListLayout")
						listLayout.Padding = UDim.new(0, 6)
						listLayout.SortOrder = Enum.SortOrder.LayoutOrder
						listLayout.Parent = list

						local function flashCopied(label)
							H.setGateStatus("Copied — " .. label)
							if UI.gateStatusDot then
								UI.gateStatusDot.BackgroundColor3 = Color3.fromRGB(87, 242, 135)
							end
							task.delay(1.6, function()
								if UI.gateGui then
									H.setGateStatus("Waiting for /start in " .. EXONHUB_LAUNCH_CHANNEL)
									if UI.gateStatusDot then
										UI.gateStatusDot.BackgroundColor3 = theme.accent
									end
								end
							end)
						end

						H.makeGateActionRow(list, 1, "Copy session key", code, function()
							if H.copyToClipboard(code) then
								flashCopied(code)
							end
						end)

						H.makeGateActionRow(list, 2, "Copy /start command", startCommand, function()
							if H.copyToClipboard(startCommand) then
								flashCopied("/start command")
							end
						end)

						H.makeGateActionRow(list, 3, "Join ExonHub Discord", "discord.gg/exonhub", function()
							if H.copyToClipboard(EXONHUB_DISCORD_INVITE) then
								flashCopied("Discord invite")
							end
						end)

						H.makeGateActionRow(list, 4, "Open launch channel", startCommand, function()
							if H.copyToClipboard(startCommand) then
								flashCopied("/start command")
							end
						end)

						local statusRow = Instance.new("Frame")
						statusRow.Size = UDim2.new(1, -8, 0, 24)
						statusRow.Position = UDim2.new(0, 4, 1, -28)
						statusRow.BackgroundTransparency = 1
						statusRow.Parent = content

						local statusDot = Instance.new("Frame")
						statusDot.Size = UDim2.fromOffset(6, 6)
						statusDot.Position = UDim2.fromOffset(0, 9)
						statusDot.BackgroundColor3 = theme.accent
						statusDot.BorderSizePixel = 0
						statusDot.Parent = statusRow

						local dotCorner = Instance.new("UICorner")
						dotCorner.CornerRadius = UDim.new(1, 0)
						dotCorner.Parent = statusDot

						local status = Instance.new("TextLabel")
						status.Name = "Status"
						status.BackgroundTransparency = 1
						status.Position = UDim2.fromOffset(12, 0)
						status.Size = UDim2.new(1, -12, 1, 0)
						status.Font = Enum.Font.Gotham
						status.TextSize = 12
						status.TextColor3 = theme.dim
						status.TextXAlignment = Enum.TextXAlignment.Left
						status.TextTruncate = Enum.TextTruncate.AtEnd
						status.Text = "Waiting for /start in " .. EXONHUB_LAUNCH_CHANNEL
						status.Parent = statusRow

						UI.gateGui = gui
						UI.gateStatusLabel = status
						UI.gateCodeLabel = codeLabel
						UI.gateStatusDot = statusDot
					end

					function H.loadWindUI()
						if UI.windUI then
							return true, UI.windUI
						end

						local WINDUI_URLS = {
							"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
							"https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua",
						}

						local loadFn = getLoadFn()
						if type(loadFn) ~= "function" then
							return false, "loadstring/load missing"
						end

						local httpGet = getHttpGetFn()
						local lastErr = "unknown"
						for _, url in ipairs(WINDUI_URLS) do
							local ok, result = pcall(function()
								local source
								if game.HttpGet then
									source = game:HttpGet(url)
								elseif httpGet then
									source = httpGet(url)
								end
								if type(source) ~= "string" or source == "" then
									error("empty WindUI response")
								end
								local compiled = loadFn(source)
								if type(compiled) ~= "function" then
									error("WindUI compile failed")
								end
								return compiled()
							end)
							if ok and result then
								UI.windUI = result
								return true, result
							end
							lastErr = tostring(result)
							warn("[ExonHub] WindUI URL failed:", url, lastErr)
						end
						return false, lastErr
					end

					function H.printKeySystemStatus(status)
						if status == "skipped" or status == "loaded" or status == "completed" then
							print("[ExonHub] Key system " .. status)
						end
					end

					function H.waitForDiscordGate()
						if type(EXONHUB_GATE_API) ~= "string" or EXONHUB_GATE_API == "" then
							if EXONHUB_GATE_SKIP_IF_OFFLINE then
								H.printKeySystemStatus("skipped")
								return
							end
							failStartup("Discord gate is enabled but EXONHUB_GATE_API is empty. Set your bot URL in ExonHub.Lua.")
						end

						if not H.isGateApiOnline() then
							if EXONHUB_GATE_SKIP_IF_OFFLINE then
								H.printKeySystemStatus("skipped")
								return
							end
							failStartup("Discord gate bot is offline. Start Exon Manager 1 and 2, or set EXONHUB_GATE_SKIP_IF_OFFLINE = true.")
						end

						if EXONHUB_GATE_ALWAYS_VERIFY then
							pcall(function()
								if delfile and isfile and isfile(EXONHUB_GATE_FILE) then
									delfile(EXONHUB_GATE_FILE)
								elseif writefile then
									writefile(EXONHUB_GATE_FILE, "{}")
								end
							end)
						else
							local saved = H.loadGateSession()
							if H.isGateSessionValid(saved) then
								H.destroyGateUi()
								H.applyGateSessionToState(saved)
								H.printKeySystemStatus("skipped")
								return
							end
						end

						local registered, regData = H.registerGateSession()
						if not registered then
							if EXONHUB_GATE_SKIP_IF_OFFLINE then
								H.printKeySystemStatus("skipped")
								return
							end
							failStartup(regData or "Failed to register Discord gate session.")
						end

						if not EXONHUB_GATE_ALWAYS_VERIFY and regData.skip == true and type(regData.discord) == "table" then
							H.destroyGateUi()
							H.buildGateSessionFromDiscord(regData.discord, regData.code, regData.expiresAt)
							H.printKeySystemStatus("skipped")
							return
						end

						local code = tostring(regData.code or "")
						if code == "" then
							failStartup("Gate server did not return a code.")
						end

						if EXONHUB_GATE_ALWAYS_VERIFY then
							local preVerified = H.checkGateCode(code)
							if preVerified then
								for _ = 1, 5 do
									task.wait(0.4)
									preVerified = H.checkGateCode(code)
									if not preVerified then
										break
									end
								end
							end
						end

						H.createDiscordGateUi(code)
						H.printKeySystemStatus("loaded")

						while true do
							task.wait(EXONHUB_GATE_POLL_SECONDS)
							local verified, discordInfo = H.checkGateCode(code)
							if verified then
								local discordName = discordInfo and (discordInfo.displayName or discordInfo.username) or "Discord user"
								H.printKeySystemStatus("completed")
								H.setGateStatus("Verified as " .. discordName .. " — opening hub...")
								H.buildGateSessionFromDiscord(discordInfo or {}, code)
								task.wait(0.5)
								H.destroyGateUi()
								return
							end
						end
					end

					function H.getNetworkPing()
						local ping = 0
						pcall(function()
							local network = game:GetService("Stats").Network
							ping = math.floor(network.ServerStatsItem["Data Ping"]:GetValue())
						end)
						return ping
					end

					function H.getRobloxHeadshotUrl(userId)
						return ("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png"):format(userId)
					end

					function H.getIpInfo()
						local HttpService = game:GetService("HttpService")
						local body = H.httpRequest("http://ip-api.com/json/?fields=status,message,query,country,regionName,city,isp,proxy,mobile")
						if not body then
							return nil
						end
						local ok, data = pcall(function()
							return HttpService:JSONDecode(body)
						end)
						if ok and type(data) == "table" and data.status == "success" then
							return data
						end
						return nil
					end

					function H.formatDiscordNumber(value)
						local numberValue = tonumber(value) or 0
						local absValue = math.abs(numberValue)
						if absValue >= 1e12 then
							return string.format("%.2fT", numberValue / 1e12)
						elseif absValue >= 1e9 then
							return string.format("%.2fB", numberValue / 1e9)
						elseif absValue >= 1e6 then
							return string.format("%.2fM", numberValue / 1e6)
						elseif absValue >= 1e3 then
							return string.format("%.2fK", numberValue / 1e3)
						end
						return tostring(math.floor(numberValue))
					end

					function H.collectDiscordGameStats()
						local stats = H.getClientStats()
						if not stats then
							return nil
						end

						local snapshot = {
							level = H.getStatValue(stats, "level"),
							gold = H.getGoldAmount(),
							tokens = H.getStatValue(stats, "tokens"),
							quest_points = H.getCurrencyAmount("quest_points"),
							shells = H.getCurrencyAmount("shells"),
							size = H.getStatValue(stats, "size"),
							xp_skill = H.getStatValue(stats, "xp_skill"),
							speed_skill = H.getStatValue(stats, "speed_skill"),
							gold_skill = H.getStatValue(stats, "gold_skill"),
							crit_skill = H.getStatValue(stats, "crit_skill"),
							dual_skill = H.getStatValue(stats, "dual_skill"),
						}

						for _, key in ipairs({ "rebirth", "rebirths", "rebirth_count" }) do
							local value = H.getStatValue(stats, key)
							if value > 0 then
								snapshot.rebirths = value
								break
							end
						end

						return snapshot
					end

					function H.getUsageStatsFile(userId)
						return EXONHUB_USAGE_DIR .. "/" .. tostring(userId) .. ".json"
					end

					function H.loadUsageStats(userId)
						local defaultStats = { executions = 0, totalSeconds = 0 }
						if not readfile or not isfile then
							return defaultStats
						end

						local path = H.getUsageStatsFile(userId)
						if not isfile(path) then
							return defaultStats
						end

						local ok, raw = pcall(readfile, path)
						if not ok or type(raw) ~= "string" or raw == "" then
							return defaultStats
						end

						local HttpService = game:GetService("HttpService")
						local decodeOk, data = pcall(function()
							return HttpService:JSONDecode(raw)
						end)
						if decodeOk and type(data) == "table" then
							return {
								executions = tonumber(data.executions) or 0,
								totalSeconds = tonumber(data.totalSeconds) or 0,
							}
						end

						return defaultStats
					end

					function H.saveUsageStats(userId, stats)
						if not writefile or not makefolder or not isfolder then
							return false
						end

						pcall(function()
							if not isfolder("ExonHub") then
								makefolder("ExonHub")
							end
							if not isfolder(EXONHUB_USAGE_DIR) then
								makefolder(EXONHUB_USAGE_DIR)
							end
						end)

						local HttpService = game:GetService("HttpService")
						local ok, json = pcall(function()
							return HttpService:JSONEncode({
								executions = stats.executions,
								totalSeconds = math.floor(stats.totalSeconds),
								lastUpdated = os.time(),
							})
						end)
						if not ok or not json then
							return false
						end

						local saved = pcall(writefile, H.getUsageStatsFile(userId), json)
						return saved
					end

					function H.canFilesystemPersist()
						return type(writefile) == "function"
							and type(readfile) == "function"
							and type(isfolder) == "function"
							and type(makefolder) == "function"
					end

					local EXONHUB_RESET_FOLDERS = { "ExonHub", "WindUI" }

					function H.canFilesystemDelete()
						return type(delfile) == "function" or type(delfolder) == "function"
					end

					function H.normalizeExecutorChildPath(parent, entry)
						if type(entry) ~= "string" or entry == "" then
							return nil
						end
						if string.find(entry, ":", 1, true) or string.sub(entry, 1, 1) == "/" then
							return entry
						end
						if string.find(entry, "/", 1, true) then
							return entry
						end
						parent = tostring(parent or "")
						if parent == "" then
							return entry
						end
						if string.sub(parent, -1) == "/" then
							return parent .. entry
						end
						return parent .. "/" .. entry
					end

					function H.deleteExecutorPath(path)
						if type(path) ~= "string" or path == "" then
							return false
						end
						if not H.canFilesystemDelete() then
							return false
						end

						local isDir = false
						if type(isfolder) == "function" then
							local ok, result = pcall(isfolder, path)
							isDir = ok and result == true
						end

						if isDir then
							if type(listfiles) == "function" then
								local ok, entries = pcall(listfiles, path)
								if ok and type(entries) == "table" then
									for _, entry in ipairs(entries) do
										local child = H.normalizeExecutorChildPath(path, entry)
										if child then
											H.deleteExecutorPath(child)
										end
									end
								end
							end
							if type(delfolder) == "function" then
								return pcall(delfolder, path)
							end
							return false
						end

						if type(isfile) == "function" and type(delfile) == "function" then
							local ok, exists = pcall(isfile, path)
							if ok and exists then
								return pcall(delfile, path)
							end
						end

						return false
					end

					function H.deleteExecutorResetFolders()
						local removed = {}
						local failed = {}

						for _, folder in ipairs(EXONHUB_RESET_FOLDERS) do
							local hadSomething = false
							if type(isfolder) == "function" then
								local ok, exists = pcall(isfolder, folder)
								hadSomething = ok and exists == true
							end
							if not hadSomething and type(isfile) == "function" then
								local ok, exists = pcall(isfile, folder)
								hadSomething = ok and exists == true
							end

							if hadSomething then
								if H.deleteExecutorPath(folder) then
									table.insert(removed, folder)
								else
									table.insert(failed, folder)
								end
							end
						end

						return removed, failed
					end

					function H.destroyExonHubUiRoots()
						local uiNames = {
							"Exon",
							"ExonHubUI",
							"ExonHubFloatingToggle",
							"ExonHubMinimizedClone",
							"ExonHubMinimizedGui",
							"ExonHubQtyPrompt",
							"WindUI",
							"ExonHub",
							"ExonHubError",
						}

						local function destroyIn(parent)
							if not parent then
								return
							end
							for _, name in ipairs(uiNames) do
								local inst = parent:FindFirstChild(name)
								if inst then
									pcall(function()
										inst:Destroy()
									end)
								end
							end
						end

						destroyIn(playerGui)
						pcall(function()
							if typeof(gethui) == "function" then
								destroyIn(gethui())
							end
						end)
						pcall(function()
							destroyIn(game:GetService("CoreGui"))
						end)
					end

					function H.stopAllExonHubActivity()
						S.suppressSettingsPersist = true

						local toggles = {
							{ "setAutoClicker", false },
							{ "setRunning", false },
							{ "setAutoQuest", false },
							{ "setMaxOut", false },
							{ "setAutoUpgrade", false },
							{ "setAutoRebirth", false },
							{ "setAutoMassUpgrade", false },
							{ "setAutoBoss", false },
							{ "setAutoKill", false },
							{ "setAutoFish", false },
							{ "setAutoGoals", false },
							{ "setAutoKoth", false },
							{ "setAutoMineRace", false },
							{ "setAutoSellChest", false },
							{ "setAutoOpenChest", false },
							{ "setAutoUpgradeRod", false },
							{ "setAutoEvolvePets", false },
							{ "setAutoEvolveArtifacts", false },
							{ "setAutoDeleteWeapons", false },
							{ "setAutoDeleteSkins", false },
							{ "setAntiAfk", false },
							{ "setStreamerMode", false },
						}

						for _, entry in ipairs(toggles) do
							local fn = H[entry[1]]
							if fn then
								pcall(fn, entry[2], false)
							end
						end

						H.disconnectUiRotation("topbar")
						H.disconnectUiRotation("minimized")
						H.disconnectMinimizedDragConns()
						H.teardownFishingPhaseListener()
						H.destroyExonHubQtyPrompt()
					end

					function H.performExonHubReset()
						H.stopAllExonHubActivity()

						local removed, failed = H.deleteExecutorResetFolders()
						S.pendingSettingsRestore = nil
						S.autoSaveSettingsEnabled = false

						local bag = _G[EXONHUB_SESSION_KEY]
						if type(bag) == "table" and type(bag.connections) == "table" then
							for _, conn in ipairs(bag.connections) do
								pcall(function()
									if conn and conn.Disconnect then
										conn:Disconnect()
									end
								end)
							end
							bag.connections = {}
						end

						local summary = "ExonHub has been reset."
						if #removed > 0 then
							summary = summary .. "\n\nRemoved: " .. table.concat(removed, ", ")
						else
							summary = summary .. "\n\nNo saved executor folders were found."
						end
						if #failed > 0 then
							summary = summary .. "\n\nCould not delete: " .. table.concat(failed, ", ")
						end
						summary = summary .. "\n\nRe-execute the script to load fresh defaults."

						print("[ExonHub] Reset complete")
						H.setStatus("Reset complete — re-execute ExonHub")

						local function finishResetUi()
							H.destroyExonHubUiRoots()
							if UI.window and UI.window.Destroy then
								pcall(function()
									UI.window:Destroy()
								end)
							end
							UI.window = nil
							UI.windUI = nil
							UI.floatingToggle = nil
							UI.floatingToggleGui = nil
						end

						if UI.window and UI.window.Dialog then
							local okDialog = pcall(function()
								UI.window:Dialog({
									Title = "Reset Complete",
									Icon = "solar:check-circle-bold",
									Width = 380,
									Content = summary,
									Buttons = {
										{
											Title = "OK",
											Variant = "Primary",
											Callback = finishResetUi,
										},
									},
								})
							end)
							if not okDialog then
								finishResetUi()
							end
						else
							warn("[ExonHub]", summary)
							finishResetUi()
						end
					end

					function H.promptResetExonHub()
						if not UI.window or not UI.window.Dialog then
							warn("[ExonHub] Reset requires WindUI Dialog")
							return
						end

						if not H.canFilesystemDelete() then
							pcall(function()
								UI.window:Dialog({
									Title = "Reset Unavailable",
									Icon = "solar:shield-warning-bold",
									Width = 360,
									Content = "Your executor does not support deleting files (delfile/delfolder).\n\nCannot reset saved data.",
									Buttons = {
										{
											Title = "OK",
											Variant = "Primary",
										},
									},
								})
							end)
							return
						end

						pcall(function()
							UI.window:Dialog({
								Title = "Reset ExonHub",
								Icon = "solar:restart-bold",
								Width = 390,
								Content = "Delete ALL ExonHub and WindUI saved files from your executor?\n\nThis removes saved settings, configs, and keys. All toggles return to defaults.\n\nThis cannot be undone.",
								Buttons = {
									{
										Title = "Cancel",
										Variant = "Tertiary",
									},
									{
										Title = "Reset Everything",
										Variant = "Primary",
										Callback = function()
											task.defer(H.performExonHubReset)
										end,
									},
								},
							})
						end)
					end

					function H.ensureSettingsDir()
						if not H.canFilesystemPersist() then
							return false
						end

						pcall(function()
							if not isfolder("ExonHub") then
								makefolder("ExonHub")
							end
							if not isfolder(EXONHUB_SETTINGS_DIR) then
								makefolder(EXONHUB_SETTINGS_DIR)
							end
						end)

						return true
					end

					function H.getMinimizeHotkeyName()
						local name = S.minimizeHotkey
						if type(name) == "string" and Enum.KeyCode[name] then
							return name
						end
						return "LeftAlt"
					end

					function H.getMinimizeHotkeyEnum()
						return Enum.KeyCode[H.getMinimizeHotkeyName()]
					end

					function H.syncMinimizeHotkeyKeybind(keyName)
						if S.suppressSettingsDropdownSync or not UI.minimizeHotkeyKeybindElement then
							return
						end
						if UI.minimizeHotkeyKeybindElement.Set then
							pcall(function()
								UI.minimizeHotkeyKeybindElement:Set(keyName)
							end)
						end
					end

					function H.setMinimizeHotkey(keyName, fromKeybind)
						if type(keyName) ~= "string" or not Enum.KeyCode[keyName] then
							return
						end

						S.minimizeHotkey = keyName

						if UI.window and UI.window.SetToggleKey then
							pcall(function()
								UI.window:SetToggleKey(Enum.KeyCode[keyName])
							end)
						end

						if not fromKeybind then
							H.syncMinimizeHotkeyKeybind(keyName)
						end

						H.scheduleSettingsSave()
					end

					function H.getSettingsFile()
						return EXONHUB_SETTINGS_DIR .. "/" .. tostring(player.UserId) .. ".json"
					end

					function H.getAutoBossTargetLabels()
						local labels = {}
						for _, label in ipairs(AUTO_BOSS_OPTION_LABELS) do
							local bossId = AUTO_BOSS_LABEL_TO_ID[label]
							if bossId and S.autoBossTargets[bossId] then
								table.insert(labels, label)
							end
						end
						return labels
					end

					function H.getAutoUpgradeTargetLabels()
						local labels = {}
						for _, label in ipairs(AUTO_UPGRADE_SLOT_LABELS) do
							local slotId = AUTO_UPGRADE_LABEL_TO_ID[label]
							if slotId and S.autoUpgradeTargets[slotId] then
								table.insert(labels, label)
							end
						end
						return labels
					end

					function H.serializeCrateAutoDeleteIds()
						local serialized = {}
						for slotId, deleteSet in pairs(S.crateAutoDeleteIds) do
							local ids = {}
							for key, enabled in pairs(deleteSet) do
								local id = tonumber(key)
								if enabled and id then
									table.insert(ids, id)
								end
							end
							if #ids > 0 then
								serialized[slotId] = ids
							end
						end
						return serialized
					end

					function H.applySerializedCrateAutoDeleteIds(serialized)
						if type(serialized) ~= "table" then
							return
						end

						for slotId, ids in pairs(serialized) do
							local deleteSet = {}
							if type(ids) == "table" then
								for _, id in ipairs(ids) do
									local numericId = tonumber(id)
									if numericId then
										deleteSet[numericId] = true
										deleteSet[tostring(numericId)] = true
									end
								end
							end
							S.crateAutoDeleteIds[slotId] = deleteSet
						end
					end

					function H.copyBoolMap(source)
						local copy = {}
						if type(source) ~= "table" then
							return copy
						end
						for key, value in pairs(source) do
							copy[key] = value == true
						end
						return copy
					end

					function H.copyStringList(source)
						local copy = {}
						if type(source) ~= "table" then
							return copy
						end
						for index, value in ipairs(source) do
							if type(value) == "string" then
								copy[index] = value
							end
						end
						return copy
					end

					function H.applyTargetBoolMap(target, source, knownKeys)
						for _, key in ipairs(knownKeys) do
							target[key] = false
						end
						if type(source) ~= "table" then
							return
						end
						for _, key in ipairs(knownKeys) do
							if source[key] ~= nil then
								target[key] = source[key] == true
							end
						end
					end

					function H.applyAutoUpgradeTargetsFromLabels(labels)
						H.applyTargetBoolMap(S.autoUpgradeTargets, {}, { "primary_weapon", "secondary_weapon", "skin" })
						for _, label in ipairs(H.normalizeDropdownSelection(labels)) do
							local slotId = AUTO_UPGRADE_LABEL_TO_ID[label]
							if slotId then
								S.autoUpgradeTargets[slotId] = true
							end
						end
					end

					function H.applyAutoBossTargetsFromLabels(labels)
						H.applyTargetBoolMap(S.autoBossTargets, {}, { "borock", "demon_king" })
						for _, label in ipairs(H.normalizeDropdownSelection(labels)) do
							local bossId = AUTO_BOSS_LABEL_TO_ID[label]
							if bossId then
								S.autoBossTargets[bossId] = true
							end
						end
					end

					function H.serializeCrateAutoDeleteLabels()
						local serialized = {}
						if type(S.crateAutoDeleteLabels) ~= "table" then
							return serialized
						end
						for slotId, labels in pairs(S.crateAutoDeleteLabels) do
							if type(labels) == "table" and #labels > 0 then
								serialized[slotId] = H.copyStringList(labels)
							end
						end
						return serialized
					end

					function H.getCrateAutoDeleteLabels(slotId)
						local labels = S.crateAutoDeleteLabels and S.crateAutoDeleteLabels[slotId]
						if type(labels) == "table" then
							return H.copyStringList(labels)
						end
						return {}
					end

					function H.serializeCrateHuntTargets()
						local serialized = {}
						if type(S.crateHuntTargets) ~= "table" then
							return serialized
						end
						for slotId, targets in pairs(S.crateHuntTargets) do
							if type(targets) == "table" then
								local slotOut = {}
								for itemKey, entry in pairs(targets) do
									if type(entry) == "table" then
										local needed = math.max(1, math.floor(tonumber(entry.needed) or 1))
										slotOut[tostring(itemKey)] = {
											label = type(entry.label) == "string" and entry.label or tostring(itemKey),
											needed = needed,
											obtained = 0,
										}
									end
								end
								if next(slotOut) ~= nil then
									serialized[slotId] = slotOut
								end
							end
						end
						return serialized
					end

					function H.applySerializedCrateHuntTargets(serialized)
						if type(serialized) ~= "table" then
							return
						end
						S.crateHuntTargets = {}
						for slotId, targets in pairs(serialized) do
							if type(targets) == "table" then
								local slotTargets = {}
								for itemKey, entry in pairs(targets) do
									if type(entry) == "table" then
										local needed = math.max(1, math.floor(tonumber(entry.needed) or 1))
										slotTargets[tostring(itemKey)] = {
											label = type(entry.label) == "string" and entry.label or tostring(itemKey),
											needed = needed,
											obtained = 0,
										}
									end
								end
								S.crateHuntTargets[slotId] = slotTargets
							end
						end
					end

					function H.serializeCrateHuntLabels()
						local serialized = {}
						if type(S.crateHuntLabels) ~= "table" then
							return serialized
						end
						for slotId, labels in pairs(S.crateHuntLabels) do
							if type(labels) == "table" and #labels > 0 then
								serialized[slotId] = H.copyStringList(labels)
							end
						end
						return serialized
					end

					function H.getCrateHuntLabels(slotId)
						local labels = S.crateHuntLabels and S.crateHuntLabels[slotId]
						if type(labels) == "table" then
							return H.copyStringList(labels)
						end
						return {}
					end

					function H.resetCrateHuntObtained(slotId)
						local targets = S.crateHuntTargets and S.crateHuntTargets[slotId]
						if type(targets) ~= "table" then
							return
						end
						for _, entry in pairs(targets) do
							if type(entry) == "table" then
								entry.obtained = 0
							end
						end
					end

					function H.preparePendingSettingsRestore()
						local data = H.loadStoredSettings()
						if not data or data.autoSaveSettings ~= true then
							S.pendingSettingsRestore = nil
							return false
						end

						S.pendingSettingsRestore = data
						S.autoSaveSettingsEnabled = true
						S.suppressSettingsPersist = true

						local values = type(data.values) == "table" and data.values or {}

						if values.autoRebirthTargetLevel then
							local level = tonumber(values.autoRebirthTargetLevel)
							if level then
								S.autoRebirthTargetLevel = math.max(MIN_REBIRTH_TARGET_LEVEL, math.floor(level))
							end
						end
						if type(values.weaponSortStat) == "string" then
							S.weaponSortStat = values.weaponSortStat
						end
						if type(values.skinSortStat) == "string" then
							S.skinSortStat = values.skinSortStat
						end
						if type(values.minimizeHotkey) == "string" and Enum.KeyCode[values.minimizeHotkey] then
							S.minimizeHotkey = values.minimizeHotkey
						end
						if type(values.maxOutTier) == "string" then
							local tier = H.normalizeMaxOutTier(values.maxOutTier)
							if tier then
								S.maxOutTier = tier
							end
						end

						if type(values.autoUpgradeTargetMap) == "table" then
							H.applyTargetBoolMap(
								S.autoUpgradeTargets,
								values.autoUpgradeTargetMap,
								{ "primary_weapon", "secondary_weapon", "skin" }
							)
						elseif type(values.autoUpgradeTargets) == "table" then
							H.applyAutoUpgradeTargetsFromLabels(values.autoUpgradeTargets)
						end

						if type(values.autoBossTargetMap) == "table" then
							H.applyTargetBoolMap(S.autoBossTargets, values.autoBossTargetMap, { "borock", "demon_king" })
						elseif type(values.autoBossTargets) == "table" then
							H.applyAutoBossTargetsFromLabels(values.autoBossTargets)
						end

						H.applySerializedCrateAutoDeleteIds(data.crateAutoDeleteIds)

						if type(data.crateAutoDeleteLabels) == "table" then
							S.crateAutoDeleteLabels = {}
							for slotId, labels in pairs(data.crateAutoDeleteLabels) do
								if type(labels) == "table" then
									S.crateAutoDeleteLabels[slotId] = H.copyStringList(labels)
								end
							end
						end

						H.applySerializedCrateHuntTargets(data.crateHuntTargets)

						if type(data.crateHuntLabels) == "table" then
							S.crateHuntLabels = {}
							for slotId, labels in pairs(data.crateHuntLabels) do
								if type(labels) == "table" then
									S.crateHuntLabels[slotId] = H.copyStringList(labels)
								end
							end
						end

						if type(data.caveAutoOpenSlots) == "table" then
							S.caveAutoOpenSlots = H.copyBoolMap(data.caveAutoOpenSlots)
						end
						if type(data.shellEggAutoOpenSlots) == "table" then
							S.autoOpenShellEggSlots = H.copyBoolMap(data.shellEggAutoOpenSlots)
						end

						return true
					end

					function H.buildSettingsSnapshot()
						return {
							version = 1,
							autoSaveSettings = S.autoSaveSettingsEnabled == true,
							toggles = {
								clicker = S.clickerRunning == true,
								farm = S.running == true,
								autoQuest = S.autoQuestRunning == true,
								autoQuestDeleteRewards = S.autoQuestDeleteRewards == true,
								autoUpgrade = S.autoUpgradeRunning == true,
								equipBestSword = S.equipBestSwordRunning == true,
								equipBestSkin = S.equipBestSkinRunning == true,
								autoEvolvePets = S.autoEvolvePetsRunning == true,
								autoEvolveArtifacts = S.autoEvolveArtifactsRunning == true,
								autoDeleteWeapons = S.autoDeleteWeaponsRunning == true,
								autoDeleteSkins = S.autoDeleteSkinsRunning == true,
								autoRebirth = S.autoRebirthRunning == true,
								autoMassUpgrade = S.autoMassUpgradeRunning == true,
								autoSellChest = S.autoSellChestRunning == true,
								autoOpenChest = S.autoOpenChestRunning == true,
								autoBoss = S.autoBossRunning == true,
								antiAfk = S.antiAfkRunning == true,
								autoKill = S.autoKillRunning == true,
								streamerMode = S.streamerModeRunning == true,
								autoFish = S.autoFishRunning == true,
								autoUpgradeRod = S.autoUpgradeRodRunning == true,
								autoGoals = S.autoGoalsRunning == true,
								autoKoth = S.autoKothRunning == true,
								autoMineRace = S.autoMineRaceRunning == true,
								maxOut = S.maxOutRunning == true,
							},
							values = {
								autoRebirthTargetLevel = S.autoRebirthTargetLevel,
								weaponSortStat = S.weaponSortStat,
								skinSortStat = S.skinSortStat,
								autoBossTargets = H.getAutoBossTargetLabels(),
								autoBossTargetMap = H.copyBoolMap(S.autoBossTargets),
								autoUpgradeTargets = H.getAutoUpgradeTargetLabels(),
								autoUpgradeTargetMap = H.copyBoolMap(S.autoUpgradeTargets),
								minimizeHotkey = H.getMinimizeHotkeyName(),
								maxOutTier = S.maxOutTier,
							},
							caveAutoOpenSlots = H.copyBoolMap(S.caveAutoOpenSlots),
							shellEggAutoOpenSlots = H.copyBoolMap(S.autoOpenShellEggSlots),
							crateAutoDeleteIds = H.serializeCrateAutoDeleteIds(),
							crateAutoDeleteLabels = H.serializeCrateAutoDeleteLabels(),
							crateHuntTargets = H.serializeCrateHuntTargets(),
							crateHuntLabels = H.serializeCrateHuntLabels(),
						}
					end

					function H.saveSettingsSnapshot(force)
						if not H.canFilesystemPersist() then
							return false
						end
						if not force and not S.autoSaveSettingsEnabled then
							return false
						end

						H.ensureSettingsDir()

						local HttpService = game:GetService("HttpService")
						local ok, json = pcall(function()
							return HttpService:JSONEncode(H.buildSettingsSnapshot())
						end)
						if not ok or not json then
							return false
						end

						return pcall(writefile, H.getSettingsFile(), json)
					end

					function H.loadStoredSettings()
						if not H.canFilesystemPersist() then
							return nil
						end

						local path = H.getSettingsFile()
						if not isfile(path) then
							return nil
						end

						local ok, raw = pcall(readfile, path)
						if not ok or type(raw) ~= "string" or raw == "" then
							return nil
						end

						local HttpService = game:GetService("HttpService")
						local decodeOk, data = pcall(function()
							return HttpService:JSONDecode(raw)
						end)
						if decodeOk and type(data) == "table" then
							return data
						end

						return nil
					end

					function H.scheduleSettingsSave()
						if S.suppressSettingsPersist or not S.autoSaveSettingsEnabled then
							return
						end
						if S.settingsSavePending then
							return
						end

						S.settingsSavePending = true
						task.delay(0.35, function()
							S.settingsSavePending = false
							H.saveSettingsSnapshot()
						end)
					end

					function H.setDropdownSelection(element, value)
						if element and element.Set then
							pcall(function()
								element:Set(value)
							end)
						end
					end

					function H.applyStoredToggle(toggles, key, setter)
						if toggles and toggles[key] and setter then
							setter(true, false)
						end
					end

					function H.restoreSavedSettingsOnLoad()
						local data = S.pendingSettingsRestore or H.loadStoredSettings()
						if not data or data.autoSaveSettings ~= true then
							S.pendingSettingsRestore = nil
							return false
						end

						S.autoSaveSettingsEnabled = true
						H.syncAutoSaveSettingsToggle(true)
						S.suppressSettingsPersist = true
						S.suppressSettingsDropdownSync = true

						H.syncAutoRebirthLevelInput(S.autoRebirthTargetLevel)
						H.setDropdownSelection(UI.weaponSortDropdownElement, S.weaponSortStat)
						H.setDropdownSelection(UI.skinSortDropdownElement, S.skinSortStat)
						H.setDropdownSelection(UI.autoBossDropdownElement, H.getAutoBossTargetLabels())
						H.setDropdownSelection(UI.autoUpgradeDropdownElement, H.getAutoUpgradeTargetLabels())
						H.setDropdownSelection(UI.maxOutDropdownElement, S.maxOutTier)
						H.setMinimizeHotkey(H.getMinimizeHotkeyName(), false)

						if type(data.crateAutoDeleteLabels) == "table" then
							for slotId, labels in pairs(data.crateAutoDeleteLabels) do
								if type(labels) == "table" then
									H.setDropdownSelection(UI.crateDeleteDropdowns[slotId], labels)
								end
							end
						end

						if type(data.crateHuntLabels) == "table" then
							for slotId, labels in pairs(data.crateHuntLabels) do
								if type(labels) == "table" then
									H.setDropdownSelection(UI.crateHuntDropdowns[slotId], labels)
								end
							end
						elseif type(S.crateHuntLabels) == "table" then
							for slotId, labels in pairs(S.crateHuntLabels) do
								if type(labels) == "table" then
									H.setDropdownSelection(UI.crateHuntDropdowns[slotId], labels)
								end
							end
						end

						if type(data.caveAutoOpenSlots) == "table" then
							for slotId, enabled in pairs(data.caveAutoOpenSlots) do
								H.setCaveAutoOpenSlot(slotId, enabled == true, false)
							end
						end

						if type(data.shellEggAutoOpenSlots) == "table" then
							for slotId, enabled in pairs(data.shellEggAutoOpenSlots) do
								H.setAutoOpenShellEggSlot(slotId, enabled == true, false)
							end
						end

						local toggles = data.toggles
						H.applyStoredToggle(toggles, "clicker", H.setAutoClicker)
						H.applyStoredToggle(toggles, "farm", H.setRunning)
						H.applyStoredToggle(toggles, "autoQuest", H.setAutoQuest)
						H.applyStoredToggle(toggles, "autoQuestDeleteRewards", H.setAutoQuestDeleteRewards)
						H.applyStoredToggle(toggles, "autoUpgrade", H.setAutoUpgrade)
						H.applyStoredToggle(toggles, "equipBestSword", H.setEquipBestSword)
						H.applyStoredToggle(toggles, "equipBestSkin", H.setEquipBestSkin)
						H.applyStoredToggle(toggles, "autoEvolvePets", H.setAutoEvolvePets)
						H.applyStoredToggle(toggles, "autoEvolveArtifacts", H.setAutoEvolveArtifacts)
						H.applyStoredToggle(toggles, "autoDeleteWeapons", H.setAutoDeleteWeapons)
						H.applyStoredToggle(toggles, "autoDeleteSkins", H.setAutoDeleteSkins)
						H.applyStoredToggle(toggles, "autoRebirth", H.setAutoRebirth)
						H.applyStoredToggle(toggles, "autoMassUpgrade", H.setAutoMassUpgrade)
						H.applyStoredToggle(toggles, "autoSellChest", H.setAutoSellChest)
						H.applyStoredToggle(toggles, "autoOpenChest", H.setAutoOpenChest)
						H.applyStoredToggle(toggles, "autoBoss", H.setAutoBoss)
						if H.setAntiAfk then
							if toggles and toggles.antiAfk == false then
								H.setAntiAfk(false, false)
							else
								H.setAntiAfk(true, false)
							end
						end
						H.applyStoredToggle(toggles, "autoKill", H.setAutoKill)
						H.applyStoredToggle(toggles, "streamerMode", H.setStreamerMode)
						H.applyStoredToggle(toggles, "autoFish", H.setAutoFish)
						H.applyStoredToggle(toggles, "autoUpgradeRod", H.setAutoUpgradeRod)
						H.applyStoredToggle(toggles, "autoGoals", H.setAutoGoals)
						H.applyStoredToggle(toggles, "autoKoth", H.setAutoKoth)
						H.applyStoredToggle(toggles, "autoMineRace", H.setAutoMineRace)
						H.applyStoredToggle(toggles, "maxOut", H.setMaxOut)

						S.suppressSettingsDropdownSync = false
						S.suppressSettingsPersist = false
						S.pendingSettingsRestore = nil
						H.saveSettingsSnapshot(true)
						return true
					end

					function H.formatUsageDuration(totalSeconds)
						local seconds = math.max(0, math.floor(totalSeconds or 0))
						local days = math.floor(seconds / 86400)
						seconds = seconds % 86400
						local hours = math.floor(seconds / 3600)
						seconds = seconds % 3600
						local mins = math.floor(seconds / 60)
						return string.format("%d days : %d hours : %d mins", days, hours, mins)
					end

					function H.getCurrentUsageSeconds()
						if not S.usageStats then
							return 0
						end
						local sessionElapsed = 0
						if S.usageLastCheckpoint then
							sessionElapsed = os.clock() - S.usageLastCheckpoint
						end
						return S.usageStats.totalSeconds + sessionElapsed
					end

					function H.checkpointUsageTime()
						if not S.usageStats or not S.usageLastCheckpoint then
							return
						end
						local elapsed = os.clock() - S.usageLastCheckpoint
						if elapsed <= 0 then
							return
						end
						S.usageStats.totalSeconds = S.usageStats.totalSeconds + elapsed
						S.usageLastCheckpoint = os.clock()
						H.saveUsageStats(player.UserId, S.usageStats)
					end

					function H.initUsageTracking()
						S.usageStats = H.loadUsageStats(player.UserId)
						S.usageStats.executions = S.usageStats.executions + 1
						S.usageLastCheckpoint = os.clock()
						H.saveUsageStats(player.UserId, S.usageStats)

						if S.usageTrackingActive then
							return
						end
						S.usageTrackingActive = true

						task.spawn(function()
							while S.usageTrackingActive do
								task.wait(60)
								H.checkpointUsageTime()
							end
						end)
					end

					function H.getDiscordUsageInfo()
						local executions = S.usageStats and S.usageStats.executions or 1
						local totalSeconds = H.getCurrentUsageSeconds()
						return string.format(
							"Executions: **%d**\nTotal Usage: **%s**",
							executions,
							H.formatUsageDuration(totalSeconds)
						)
					end

					function H.sendDiscordExecuteLog()
						local webhook = EXONHUB_DISCORD_WEBHOOK
						if type(webhook) ~= "string" or webhook == "" or not webhook:find("discord%.com/api/webhooks") then
							return
						end

						local hasRequest = (syn and syn.request)
							or (http and http.request)
							or request
							or (fluxus and fluxus.request)
							or (krnl and krnl.request)
						if type(hasRequest) ~= "function" then
							warn("[ExonHub] Discord log skipped: executor has no syn.request / request API")
						end

						task.spawn(function()
							local ok, err = pcall(function()
								task.wait(2)

								local UserInputService = game:GetService("UserInputService")
								local MarketplaceService = game:GetService("MarketplaceService")
								local Players = game:GetService("Players")

								local userId = player.UserId
								local profileUrl = ("https://www.roblox.com/users/%d/profile"):format(userId)
								local headshotUrl = H.getRobloxHeadshotUrl(userId)
								local executorName, hwid = H.getExecutorInfo()
								local ipInfo = H.getIpInfo()
								local gameStats = H.collectDiscordGameStats()

								local gameName = "Unknown"
								local gameCreator = "Unknown"
								pcall(function()
									local info = MarketplaceService:GetProductInfo(game.PlaceId)
									gameName = info.Name or gameName
									gameCreator = info.Creator and info.Creator.Name or gameCreator
								end)

								local premium = "Free"
								pcall(function()
									if player.MembershipType == Enum.MembershipType.Premium then
										premium = "Premium"
									end
								end)

								local locale = "Unknown"
								local country = "Unknown"
								pcall(function()
									locale = tostring(player.LocaleId)
								end)
								pcall(function()
									country = tostring(player.CountryRegionCode)
								end)

								local platform = tostring(UserInputService:GetPlatform())
								local ping = H.getNetworkPing()
								local playerCount = #Players:GetPlayers()

								local accountInfo = string.format(
									"Age: **%d days**\nPremium: **%s**\nLocale: `%s`\nRegion: `%s`",
									player.AccountAge,
									premium,
									locale,
									country
								)

								local clientInfo = string.format(
									"Platform: `%s`\nExecutor: `%s`\nPing: **%d ms**",
									platform,
									executorName,
									ping
								)

								local sessionInfo = string.format(
									"**%s** by %s\nPlace: `%d` | Universe: `%d`\nPlayers: **%d**\nJob: `%s`",
									gameName,
									gameCreator,
									game.PlaceId,
									game.GameId,
									playerCount,
									H.truncateText(game.JobId, 180)
								)

								local usageInfo = H.getDiscordUsageInfo()

								local gateSession = S.discordGate or H.loadGateSession()

								local fields = {
									{ name = "Username", value = "`" .. player.Name .. "`", inline = true },
									{ name = "Display Name", value = player.DisplayName, inline = true },
									{ name = "User ID", value = tostring(userId), inline = true },
									{ name = "Profile", value = "[Open Roblox Profile](" .. profileUrl .. ")", inline = false },
								}

								if gateSession and gateSession.discordUserId then
									local discordMention = "<@" .. tostring(gateSession.discordUserId) .. ">"
									table.insert(fields, {
										name = "Discord User ID",
										value = "`" .. tostring(gateSession.discordUserId) .. "`",
										inline = true,
									})
									table.insert(fields, {
										name = "Discord Username",
										value = "`" .. tostring(gateSession.discordUsername or "Unknown") .. "`",
										inline = true,
									})
									table.insert(fields, {
										name = "Discord Display",
										value = tostring(gateSession.discordGlobalName or gateSession.discordDisplayName or "Unknown"),
										inline = true,
									})
									table.insert(fields, {
										name = "Discord",
										value = discordMention,
										inline = false,
									})
								else
									table.insert(fields, {
										name = "Discord",
										value = "_Not linked this session_",
										inline = false,
									})
								end

								table.insert(fields, { name = "Account", value = accountInfo, inline = false })
								table.insert(fields, { name = "Client", value = clientInfo, inline = false })
								table.insert(fields, { name = "Session", value = sessionInfo, inline = false })
								table.insert(fields, { name = "Exon Hub Usage", value = usageInfo, inline = false })

								if hwid then
									table.insert(fields, {
										name = "HWID",
										value = "`" .. H.truncateText(hwid, 950) .. "`",
										inline = false,
									})
								end

								if ipInfo then
									table.insert(fields, {
										name = "Network",
										value = string.format(
											"IP: `%s`\nLocation: **%s, %s, %s**\nISP: %s\nProxy/VPN: **%s** | Mobile: **%s**",
											tostring(ipInfo.query),
											ipInfo.city or "?",
											ipInfo.regionName or "?",
											ipInfo.country or "?",
											H.truncateText(ipInfo.isp or "Unknown", 200),
											ipInfo.proxy and "Yes" or "No",
											ipInfo.mobile and "Yes" or "No"
										),
										inline = false,
									})
								end

								if gameStats then
									local progress = string.format(
										"Level **%s** | Gold **%s** | Tokens **%s**\nQuest **%s** | Shells **%s** | Size **%s**",
										H.formatDiscordNumber(gameStats.level),
										H.formatDiscordNumber(gameStats.gold),
										H.formatDiscordNumber(gameStats.tokens),
										H.formatDiscordNumber(gameStats.quest_points),
										H.formatDiscordNumber(gameStats.shells),
										H.formatDiscordNumber(gameStats.size)
									)
									if gameStats.rebirths then
										progress ..= "\nRebirths **" .. H.formatDiscordNumber(gameStats.rebirths) .. "**"
									end
									progress ..= string.format(
										"\nSkills: XP `%s` | Speed `%s` | Gold `%s` | Crit `%s` | Dual `%s`",
										H.formatDiscordNumber(gameStats.xp_skill),
										H.formatDiscordNumber(gameStats.speed_skill),
										H.formatDiscordNumber(gameStats.gold_skill),
										H.formatDiscordNumber(gameStats.crit_skill),
										H.formatDiscordNumber(gameStats.dual_skill)
									)
									table.insert(fields, { name = "Progress", value = progress, inline = false })
								end

								local screenshotData, screenshotName, screenshotType = H.tryCaptureScreenshot()
								local embed = {
									author = {
										name = EXONHUB_DISCORD_BOT_NAME,
										icon_url = EXONHUB_DISCORD_ICON_URL,
									},
									title = "New Script Execution",
									description = string.format(
										"**[%s](%s)** (`%s`) loaded **Exon Hub**.",
										player.DisplayName,
										profileUrl,
										player.Name
									),
									color = 5793266,
									thumbnail = { url = headshotUrl },
									fields = fields,
									footer = {
										text = EXONHUB_DISCORD_BOT_NAME .. " • User ID " .. tostring(userId),
										icon_url = EXONHUB_DISCORD_ICON_URL,
									},
									timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
								}

								if screenshotData and screenshotName then
									embed.image = { url = "attachment://" .. screenshotName }
								end

								local payload = {
									username = EXONHUB_DISCORD_BOT_NAME,
									avatar_url = EXONHUB_DISCORD_ICON_URL,
									embeds = { embed },
								}

								local sent = false
								if screenshotData and screenshotName then
									sent = H.postDiscordWebhookWithFile(
										webhook,
										payload,
										screenshotName,
										screenshotData,
										screenshotType
									)
								else
									sent = H.postDiscordWebhook(webhook, payload)
								end

								if not sent then
									local fallback = {
										username = EXONHUB_DISCORD_BOT_NAME,
										content = string.format(
											"**%s** (`%s`) | ID `%d` | %s\n%s",
											player.DisplayName,
											player.Name,
											userId,
											gameName,
											usageInfo:gsub("%*%*", "")
										),
									}
									H.postDiscordWebhook(webhook, fallback)
								end
							end)

							if not ok then
								warn("[ExonHub] Discord log error:", err)
							end
						end)
					end

					function H.syncMaxOutToggle(state)
						if S.suppressMaxOutToggleSync or not UI.maxOutToggleElement or not UI.maxOutToggleElement.Set then
							return
						end
						S.suppressMaxOutToggleSync = true
						pcall(function()
							UI.maxOutToggleElement:Set(state)
						end)
						S.suppressMaxOutToggleSync = false
					end

					function H.syncFarmToggle(state)
						if S.suppressToggleSync or not UI.farmToggleElement or not UI.farmToggleElement.Set then
							return
						end
						S.suppressToggleSync = true
						pcall(function()
							UI.farmToggleElement:Set(state)
						end)
						S.suppressToggleSync = false
					end

					function H.syncClickerToggle(state)
						if S.suppressClickerSync or not UI.clickerToggleElement or not UI.clickerToggleElement.Set then
							return
						end
						S.suppressClickerSync = true
						pcall(function()
							UI.clickerToggleElement:Set(state)
						end)
						S.suppressClickerSync = false
					end

					function H.syncAutoRebirthToggle(state)
						if S.suppressAutoRebirthSync or not UI.autoRebirthToggleElement or not UI.autoRebirthToggleElement.Set then
							return
						end
						S.suppressAutoRebirthSync = true
						pcall(function()
							UI.autoRebirthToggleElement:Set(state)
						end)
						S.suppressAutoRebirthSync = false
					end

					function H.syncAutoMassUpgradeToggle(state)
						if S.suppressAutoMassUpgradeSync or not UI.autoMassUpgradeToggleElement or not UI.autoMassUpgradeToggleElement.Set then
							return
						end
						S.suppressAutoMassUpgradeSync = true
						pcall(function()
							UI.autoMassUpgradeToggleElement:Set(state)
						end)
						S.suppressAutoMassUpgradeSync = false
					end

					function H.syncAutoUpgradeToggle(state)
						if S.suppressAutoUpgradeSync or not UI.autoUpgradeToggleElement or not UI.autoUpgradeToggleElement.Set then
							return
						end
						S.suppressAutoUpgradeSync = true
						pcall(function()
							UI.autoUpgradeToggleElement:Set(state)
						end)
						S.suppressAutoUpgradeSync = false
					end

					function H.syncAutoBossToggle(state)
						if S.suppressAutoBossSync or not UI.autoBossToggleElement or not UI.autoBossToggleElement.Set then
							return
						end
						S.suppressAutoBossSync = true
						pcall(function()
							UI.autoBossToggleElement:Set(state)
						end)
						S.suppressAutoBossSync = false
					end

					function H.syncAutoGoalsToggle(state)
						if S.suppressAutoGoalsSync or not UI.autoGoalsToggleElement or not UI.autoGoalsToggleElement.Set then
							return
						end
						S.suppressAutoGoalsSync = true
						pcall(function()
							UI.autoGoalsToggleElement:Set(state)
						end)
						S.suppressAutoGoalsSync = false
					end

					function H.syncAutoKothToggle(state)
						if S.suppressAutoKothSync or not UI.autoKothToggleElement or not UI.autoKothToggleElement.Set then
							return
						end
						S.suppressAutoKothSync = true
						pcall(function()
							UI.autoKothToggleElement:Set(state)
						end)
						S.suppressAutoKothSync = false
					end

					function H.syncAutoFishToggle(state)
						if S.suppressAutoFishSync or not UI.autoFishToggleElement or not UI.autoFishToggleElement.Set then
							return
						end
						S.suppressAutoFishSync = true
						pcall(function()
							UI.autoFishToggleElement:Set(state)
						end)
						S.suppressAutoFishSync = false
					end

					function H.syncAutoUpgradeRodToggle(state)
						if S.suppressAutoUpgradeRodSync or not UI.autoUpgradeRodToggleElement or not UI.autoUpgradeRodToggleElement.Set then
							return
						end
						S.suppressAutoUpgradeRodSync = true
						pcall(function()
							UI.autoUpgradeRodToggleElement:Set(state)
						end)
						S.suppressAutoUpgradeRodSync = false
					end

					function H.syncAutoMineRaceToggle(state)
						if S.suppressAutoMineRaceSync or not UI.autoMineRaceToggleElement or not UI.autoMineRaceToggleElement.Set then
							return
						end
						S.suppressAutoMineRaceSync = true
						pcall(function()
							UI.autoMineRaceToggleElement:Set(state)
						end)
						S.suppressAutoMineRaceSync = false
					end

					function H.syncAutoQuestToggle(state)
						if S.suppressAutoQuestSync or not UI.autoQuestToggleElement or not UI.autoQuestToggleElement.Set then
							return
						end
						S.suppressAutoQuestSync = true
						pcall(function()
							UI.autoQuestToggleElement:Set(state)
						end)
						S.suppressAutoQuestSync = false
					end

					function H.syncAutoQuestDeleteToggle(state)
						if S.suppressAutoQuestDeleteSync or not UI.autoQuestDeleteToggleElement or not UI.autoQuestDeleteToggleElement.Set then
							return
						end
						S.suppressAutoQuestDeleteSync = true
						pcall(function()
							UI.autoQuestDeleteToggleElement:Set(state)
						end)
						S.suppressAutoQuestDeleteSync = false
					end

					function H.syncAutoSaveSettingsToggle(state)
						if S.suppressAutoSaveSettingsSync or not UI.autoSaveSettingsToggleElement or not UI.autoSaveSettingsToggleElement.Set then
							return
						end
						S.suppressAutoSaveSettingsSync = true
						pcall(function()
							UI.autoSaveSettingsToggleElement:Set(state)
						end)
						S.suppressAutoSaveSettingsSync = false
					end

					function H.setAutoGoalsKickBusy(busy)
						S.autoGoalsKickBusy = busy == true
					end

					function H.isAutoGoalsKickBusy()
						return S.autoGoalsKickBusy == true
					end

					function H.shouldAutoGoalsUseKothTouchPath()
						return S.autoKothRunning == true and S.autoGoalsRunning == true and S.autoFishRunning ~= true
					end

					function H.faceCharacterTowardGoal(goalPart)
						local root = H.getCharacterRoot()
						local aim = H.getBeachGoalAimPosition(goalPart)
						if not root or not aim then
							return
						end

						local pos = root.Position
						root.CFrame = CFrame.lookAt(pos, Vector3.new(aim.X, pos.Y, aim.Z))
					end

					function H.clampKothHitboxSize(size)
						local maxSize = KOTH_HITBOX_MAX_SIZE
						return Vector3.new(
							math.clamp(size.X, KOTH_HITBOX_MIN_SIZE, maxSize),
							math.clamp(size.Y, KOTH_HITBOX_MIN_SIZE, maxSize),
							math.clamp(size.Z, KOTH_HITBOX_MIN_SIZE, maxSize)
						)
					end

					function H.shouldAutoGoalsBringBallToPlayer()
						return S.autoGoalsRunning == true and S.autoFishRunning == true
					end

					function H.syncAutoKillToggle(state)
						if S.suppressAutoKillSync or not UI.autoKillToggleElement or not UI.autoKillToggleElement.Set then
							return
						end
						S.suppressAutoKillSync = true
						pcall(function()
							UI.autoKillToggleElement:Set(state)
						end)
						S.suppressAutoKillSync = false
					end

					function H.syncAntiAfkToggle(state)
						if S.suppressAntiAfkSync or not UI.antiAfkToggleElement or not UI.antiAfkToggleElement.Set then
							return
						end
						S.suppressAntiAfkSync = true
						pcall(function()
							UI.antiAfkToggleElement:Set(state)
						end)
						S.suppressAntiAfkSync = false
					end

					function H.syncStreamerModeToggle(state)
						if S.suppressStreamerModeSync or not UI.streamerModeToggleElement or not UI.streamerModeToggleElement.Set then
							return
						end
						S.suppressStreamerModeSync = true
						pcall(function()
							UI.streamerModeToggleElement:Set(state)
						end)
						S.suppressStreamerModeSync = false
					end

					function H.syncAutoSellChestToggle(state)
						if S.suppressAutoSellChestSync or not UI.autoSellChestToggleElement or not UI.autoSellChestToggleElement.Set then
							return
						end
						S.suppressAutoSellChestSync = true
						pcall(function()
							UI.autoSellChestToggleElement:Set(state)
						end)
						S.suppressAutoSellChestSync = false
					end

					function H.syncAutoOpenChestToggle(state)
						if S.suppressAutoOpenChestSync or not UI.autoOpenChestToggleElement or not UI.autoOpenChestToggleElement.Set then
							return
						end
						S.suppressAutoOpenChestSync = true
						pcall(function()
							UI.autoOpenChestToggleElement:Set(state)
						end)
						S.suppressAutoOpenChestSync = false
					end

					function H.syncCaveAutoOpenToggle(slotId, state)
						local toggle = UI.caveAutoOpenToggles[slotId]
						if S.suppressCaveAutoOpenSync or not toggle or not toggle.Set then
							return
						end
						S.suppressCaveAutoOpenSync = true
						pcall(function()
							toggle:Set(state)
						end)
						S.suppressCaveAutoOpenSync = false
					end

					function H.syncAutoOpenShellEggToggle(slotId, state)
						local toggle = UI.shellEggAutoOpenToggles[slotId]
						if S.suppressAutoOpenShellEggSync or not toggle or not toggle.Set then
							return
						end
						S.suppressAutoOpenShellEggSync = true
						pcall(function()
							toggle:Set(state)
						end)
						S.suppressAutoOpenShellEggSync = false
					end

					function H.syncEquipBestSwordToggle(state)
						if S.suppressEquipBestSwordSync or not UI.equipBestSwordToggleElement or not UI.equipBestSwordToggleElement.Set then
							return
						end
						S.suppressEquipBestSwordSync = true
						pcall(function()
							UI.equipBestSwordToggleElement:Set(state)
						end)
						S.suppressEquipBestSwordSync = false
					end

					function H.syncEquipBestSkinToggle(state)
						if S.suppressEquipBestSkinSync or not UI.equipBestSkinToggleElement or not UI.equipBestSkinToggleElement.Set then
							return
						end
						S.suppressEquipBestSkinSync = true
						pcall(function()
							UI.equipBestSkinToggleElement:Set(state)
						end)
						S.suppressEquipBestSkinSync = false
					end

					function H.syncAutoEvolvePetsToggle(state)
						if S.suppressAutoEvolvePetsSync or not UI.autoEvolvePetsToggleElement or not UI.autoEvolvePetsToggleElement.Set then
							return
						end
						S.suppressAutoEvolvePetsSync = true
						pcall(function()
							UI.autoEvolvePetsToggleElement:Set(state)
						end)
						S.suppressAutoEvolvePetsSync = false
					end

					function H.syncAutoEvolveArtifactsToggle(state)
						if S.suppressAutoEvolveArtifactsSync or not UI.autoEvolveArtifactsToggleElement or not UI.autoEvolveArtifactsToggleElement.Set then
							return
						end
						S.suppressAutoEvolveArtifactsSync = true
						pcall(function()
							UI.autoEvolveArtifactsToggleElement:Set(state)
						end)
						S.suppressAutoEvolveArtifactsSync = false
					end

					function H.syncAutoDeleteWeaponsToggle(state)
						if S.suppressAutoDeleteWeaponsSync or not UI.autoDeleteWeaponsToggleElement or not UI.autoDeleteWeaponsToggleElement.Set then
							return
						end
						S.suppressAutoDeleteWeaponsSync = true
						pcall(function()
							UI.autoDeleteWeaponsToggleElement:Set(state)
						end)
						S.suppressAutoDeleteWeaponsSync = false
					end

					function H.syncAutoDeleteSkinsToggle(state)
						if S.suppressAutoDeleteSkinsSync or not UI.autoDeleteSkinsToggleElement or not UI.autoDeleteSkinsToggleElement.Set then
							return
						end
						S.suppressAutoDeleteSkinsSync = true
						pcall(function()
							UI.autoDeleteSkinsToggleElement:Set(state)
						end)
						S.suppressAutoDeleteSkinsSync = false
					end

					function H.normalizeRebirthLevel(raw)
						local n = tonumber(raw)
						if not n then
							return MIN_REBIRTH_TARGET_LEVEL
						end
						n = math.floor(n)
						return math.max(MIN_REBIRTH_TARGET_LEVEL, n)
					end

					function H.syncAutoRebirthLevelInput(level)
						if S.suppressAutoRebirthLevelSync or not UI.autoRebirthLevelInputElement or not UI.autoRebirthLevelInputElement.Set then
							return
						end
						S.suppressAutoRebirthLevelSync = true
						pcall(function()
							UI.autoRebirthLevelInputElement:Set(tostring(level))
						end)
						S.suppressAutoRebirthLevelSync = false
					end

					function H.setAutoRebirthTargetLevel(raw, fromInput)
						local level = H.normalizeRebirthLevel(raw)
						S.autoRebirthTargetLevel = level
						if fromInput then
							local trimmed = tostring(raw):match("^%s*(.-)%s*$") or ""
							local typed = tonumber(trimmed)
							if trimmed == "" or not typed or math.floor(typed) ~= level then
								H.syncAutoRebirthLevelInput(level)
							end
						end
						H.scheduleSettingsSave()
					end

					function H.getPlayerController()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers then
							return aero.Controllers.PlayerController
						end
						return nil
					end

					function H.getFishingController()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers then
							return aero.Controllers.FishingController
						end
						return nil
					end

					function H.getFishingRodsData()
						if C.fishingRodsData then
							return C.fishingRodsData
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local rodsScript = sharedFolder and sharedFolder:FindFirstChild("FishingRods")
						if not rodsScript then
							return nil
						end

						local ok, mod = pcall(require, rodsScript)
						if ok and mod and mod.Data then
							C.fishingRodsData = mod.Data
							return mod.Data
						end
						return nil
					end

					function H.getFishingState()
						local fishingController = H.getFishingController()
						return fishingController and fishingController.State or nil
					end

					function H.buildFishingOwnedSet(state)
						local owned = {}
						if state and state.rods then
							for _, entry in ipairs(state.rods) do
								if entry and entry.id then
									owned[entry.id] = true
								end
							end
						end
						return owned
					end

					function H.getBestOwnedFishingRodId(ownedSet)
						local best = 0
						for rodId, isOwned in pairs(ownedSet) do
							if isOwned and type(rodId) == "number" and rodId > best then
								best = rodId
							end
						end
						return best
					end

					function H.getNextAffordableFishingRodId(ownedSet, shells, rodsData)
						if not rodsData then
							return nil
						end

						for rodId = 1, #rodsData do
							if not ownedSet[rodId] then
								local rod = rodsData[rodId]
								local cost = rod and rod.Cost or 0
								if shells >= cost then
									return rodId
								end
								return nil
							end
						end

						return nil
					end

					function H.getFishingRodName(rodId)
						local rodsData = H.getFishingRodsData()
						local rod = rodsData and rodsData[rodId]
						return rod and rod.Name or ("Rod " .. tostring(rodId))
					end

					function H.fireFishingBuyRod(rodId)
						local fishingController = H.getFishingController()
						if fishingController and fishingController.RequestBuyRod then
							local ok = pcall(function()
								fishingController:RequestBuyRod(rodId)
							end)
							if ok then
								return true
							end
						end

						local zap = H.getZapClient()
						if not zap or not zap.FishingBuyRod or not zap.FishingBuyRod.Fire then
							return false
						end

						return pcall(function()
							zap.FishingBuyRod.Fire(rodId)
						end)
					end

					function H.fireFishingEquipRod(rodId)
						local fishingController = H.getFishingController()
						if fishingController and fishingController.RequestEquipRod then
							local ok = pcall(function()
								fishingController:RequestEquipRod(rodId)
							end)
							if ok then
								return true
							end
						end

						local zap = H.getZapClient()
						if not zap or not zap.FishingEquipRod or not zap.FishingEquipRod.Fire then
							return false
						end

						return pcall(function()
							zap.FishingEquipRod.Fire(rodId)
						end)
					end

					function H.shouldPauseAutoUpgradeRod()
						return S.autoFishRunning == true and S.autoFishPhase ~= FISHING_PHASE_IDLE
					end

					function H.tryAutoUpgradeRodStep()
						if S.autoUpgradeRodPending or H.shouldPauseAutoUpgradeRod() then
							return false
						end

						local rodsData = H.getFishingRodsData()
						if not rodsData then
							return false
						end

						local state = H.getFishingState()
						local ownedSet = H.buildFishingOwnedSet(state)
						local shells = H.getCurrencyAmount("shells")
						local equippedRod = state and state.equippedRod or 0
						local buyRodId = H.getNextAffordableFishingRodId(ownedSet, shells, rodsData)

						if buyRodId then
							if H.fireFishingBuyRod(buyRodId) then
								S.autoUpgradeRodPending = true
								H.setStatus("Buying " .. H.getFishingRodName(buyRodId))
								task.delay(AUTO_UPGRADE_ROD_BUY_COOLDOWN, function()
									S.autoUpgradeRodPending = false
									if S.autoUpgradeRodRunning then
										H.fireFishingEquipRod(buyRodId)
									end
								end)
								return true
							end
							return false
						end

						local bestOwned = H.getBestOwnedFishingRodId(ownedSet)
						if bestOwned > 0 and equippedRod ~= bestOwned then
							if H.fireFishingEquipRod(bestOwned) then
								H.setStatus("Equipped " .. H.getFishingRodName(bestOwned))
								return true
							end
						end

						return false
					end

					function H.stopAutoUpgradeRodLoop()
						S.autoUpgradeRodRunning = false
						S.autoUpgradeRodPending = false
					end

					function H.startAutoUpgradeRodLoop()
						if S.autoUpgradeRodLoopActive then
							return
						end
						S.autoUpgradeRodLoopActive = true

						task.spawn(function()
							for _ = 1, 40 do
								if H.getFishingRodsData() and (H.getFishingState() or H.getZapClient()) then
									break
								end
								task.wait(0.25)
							end

							while S.autoUpgradeRodRunning do
								if H.tryAutoUpgradeRodStep() then
									task.wait(AUTO_UPGRADE_ROD_BUY_COOLDOWN)
								else
									task.wait(AUTO_UPGRADE_ROD_POLL)
								end
							end

							S.autoUpgradeRodLoopActive = false
						end)
					end

					function H.waitForPlayerController(timeout)
						local deadline = os.clock() + (timeout or 20)
						while os.clock() < deadline do
							local pc = H.getPlayerController()
							if pc then
								return pc
							end
							task.wait(0.2)
						end
						return nil
					end

					function H.getTrainRemotes()
						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						if not aeroFolder then
							return nil, nil
						end
						local services = aeroFolder:FindFirstChild("AeroRemoteServices")
						if not services then
							return nil, nil
						end
						local gameService = services:FindFirstChild("GameService")
						if not gameService then
							return nil, nil
						end
						return gameService:FindFirstChild("WeaponAttackStart"), gameService:FindFirstChild("WeaponAnimComplete")
					end

					function H.flushZapClient()
						local zap = H.getZapClient()
						if zap and zap.SendEvents then
							pcall(zap.SendEvents)
						end
					end

					function H.fireTrainClick()
						local zap = H.getZapClient()
						if not zap or not zap.TrainClick or not zap.TrainClick.Fire then
							return false
						end
						local ok = pcall(function()
							zap.TrainClick.Fire()
						end)
						H.flushZapClient()
						return ok
					end

					function H.firePlayerTrain()
						local gameService = H.getGameService()
						local constants = H.getSharedConstants()
						if gameService and constants and constants.RemoteEvents then
							local remote = gameService[constants.RemoteEvents.PLAYER_TRAIN]
							if remote and remote.Fire then
								return pcall(function()
									remote:Fire()
								end)
							end
						end
						return false
					end

					function H.withFishingActivationBypass(fn)
						local fc = H.getFishingController()
						if not fc then
							return pcall(fn)
						end

						local originals = {}
						local function patch(methodName, replacement)
							if type(fc[methodName]) == "function" then
								originals[methodName] = fc[methodName]
								fc[methodName] = replacement
							end
						end

						patch("HandleActivation", function()
							return false
						end)
						patch("_inZone", function()
							return false
						end)
						patch("IsInZone", function()
							return false
						end)

						local results = table.pack(pcall(fn))

						for methodName, original in pairs(originals) do
							fc[methodName] = original
						end

						return table.unpack(results, 1, results.n)
					end

					function H.prepareSilentTrainWeapon(pc)
						if not pc then
							return false
						end

						H.ensureWeaponEquipped(pc)
						pcall(function()
							if pc.StartIdling and pc.IsIdlePlaying and not pc:IsIdlePlaying() then
								pc:StartIdling()
							end
						end)
						task.wait(0.02)
						return pc.Weapon ~= nil
					end

					function H.getTrainSlashTrackName(pc)
						if pc and pc.IsDualWielding and pc:IsDualWielding() then
							return "DUAL_SLASH_1"
						end
						return "WPN_SLASH_1"
					end

					function H.fireTrainSwingViaController(pc)
						if not pc then
							return false
						end

						local trackName = H.getTrainSlashTrackName(pc)
						local ok = false

						pcall(function()
							if pc.IsIdlePlaying and pc:IsIdlePlaying() and pc.OnWeaponActivated then
								pc:OnWeaponActivated(true)
								ok = true
								return
							end

							H.fireTrainClick()
							local mc = H.getMeleeController()
							if mc and mc.OnSwingStart then
								mc:OnSwingStart()
							end

							if pc.StartPrimaryAttack then
								pc:StartPrimaryAttack()
							end

							if pc.AnimKeyframeReached then
								pc:AnimKeyframeReached(trackName, "BeamStart")
								task.wait(0.04)
								pc:AnimKeyframeReached(trackName, "End")
								ok = true
								return
							end

							ok = H.fireTrainAttackStart()
							task.wait(TRAIN_REMOTE_SETTLE)
							ok = H.fireTrainAnimComplete() or ok

							if mc and mc.OnSwingEnd then
								mc:OnSwingEnd()
							end
						end)

						return ok
					end

					function H.fireTrainViaInputSimulation(pc)
						local vim = game:GetService("VirtualInputManager")
						if not vim or not pc then
							return false
						end

						local ok = false
						H.withFishingActivationBypass(function()
							H.prepareSilentTrainWeapon(pc)
							ok = pcall(function()
								vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
								task.wait(0.05)
								vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
							end)
						end)
						return ok
					end

					function H.fireTrainAttackStart()
						local gameService = H.getGameService()
						local constants = H.getSharedConstants()
						if gameService and constants and constants.RemoteEvents then
							local remote = gameService[constants.RemoteEvents.WEAPON_ATTACK_START]
							if remote and remote.Fire then
								local ok = pcall(function()
									remote:Fire()
								end)
								if ok then
									return true
								end
							end
						end

						local attackStart = select(1, H.getTrainRemotes())
						if not attackStart then
							return false
						end

						return pcall(function()
							if attackStart.Fire then
								attackStart:Fire()
							elseif attackStart.FireServer then
								attackStart:FireServer()
							end
						end)
					end

					function H.fireTrainAnimComplete()
						local gameService = H.getGameService()
						local constants = H.getSharedConstants()
						if gameService and constants and constants.RemoteEvents then
							local remote = gameService[constants.RemoteEvents.WEAPON_ANIM_COMPLETE]
							if remote and remote.Fire then
								local ok = pcall(function()
									remote:Fire()
								end)
								if ok then
									return true
								end
							end
						end

						local animComplete = select(2, H.getTrainRemotes())
						if not animComplete then
							return false
						end

						return pcall(function()
							if animComplete.Fire then
								animComplete:Fire()
							elseif animComplete.FireServer then
								animComplete:FireServer()
							end
						end)
					end

					function H.getSharedConstants()
						if C.sharedConstants then
							return C.sharedConstants
						end
						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local constantsScript = sharedFolder and sharedFolder:FindFirstChild("SharedConstants")
						if not constantsScript then
							return nil
						end
						local ok, constants = pcall(require, constantsScript)
						if ok and constants then
							C.sharedConstants = constants
							return constants
						end
						return nil
					end

					function H.getClientStats()
						local gui = player:FindFirstChild("PlayerGui")
						local clientData = gui and gui:FindFirstChild("ClientData")
						return clientData and clientData:FindFirstChild("stats") or nil
					end

					function H.getStatValue(stats, name)
						local valueObj = stats and stats:FindFirstChild(name)
						if valueObj and typeof(valueObj.Value) == "number" then
							return valueObj.Value
						end
						return 0
					end

					function H.getMassUpgradeSkillEntries()
						if C.massUpgradeSkills then
							return C.massUpgradeSkills
						end
						local constants = H.getSharedConstants()
						if not constants or not constants.DataKeys or not constants.DataKeys.Skills then
							return nil
						end
						local skills = constants.DataKeys.Skills
						C.massUpgradeSkills = {
							{ skill = skills.XP_SKILL, reqIndex = 4 },
							{ skill = skills.SPEED_SKILL, reqIndex = 1 },
							{ skill = skills.CRIT_SKILL, reqIndex = 2 },
							{ skill = skills.GOLD_SKILL, reqIndex = 3 },
						}
						return C.massUpgradeSkills
					end

					function H.getMassUpgradeSkillRanks(stats)
						return {
							H.getStatValue(stats, "xp_skill"),
							H.getStatValue(stats, "speed_skill"),
							H.getStatValue(stats, "crit_skill"),
							H.getStatValue(stats, "gold_skill"),
						}
					end

					function H.canMassUpgradeNow()
						local constants = H.getSharedConstants()
						local entries = H.getMassUpgradeSkillEntries()
						local stats = H.getClientStats()
						if not constants or not entries or not stats then
							return false
						end

						local tokens = H.getStatValue(stats, "tokens")
						local ranks = H.getMassUpgradeSkillRanks(stats)

						for index, entry in ipairs(entries) do
							local rank = ranks[index]
							local reqSkillKey = constants:GetRequiredSkill(entry.skill)
							local reqRank = ranks[entry.reqIndex]
							local canUpgrade = constants:CanUpgradeSkill(entry.skill, rank, reqSkillKey, reqRank)
							if canUpgrade and constants:GetSkillUpgradeCost(entry.skill, rank) < tokens then
								return true
							end
						end

						return false
					end

					function H.invokeMassUpgradeSkills()
						local aero = H.getGlobal().Aero
						if aero and aero.Services and aero.Services.GameService and aero.Services.GameService.MassUpgradeSkills then
							return pcall(function()
								aero.Services.GameService:MassUpgradeSkills()
							end)
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						local gameService = services and services:FindFirstChild("GameService")
						local remote = gameService and gameService:FindFirstChild("MassUpgradeSkills")
						if remote and remote:IsA("RemoteFunction") then
							return pcall(function()
								remote:InvokeServer()
							end)
						end

						return false, "MassUpgradeSkills unavailable"
					end

					function H.tryMassUpgradeSkills()
						if not H.canMassUpgradeNow() then
							return false
						end
						return H.invokeMassUpgradeSkills()
					end

					function H.stopMassUpgradeLoop()
						S.autoMassUpgradeRunning = false
					end

					function H.startMassUpgradeLoop()
						if S.massUpgradeLoopActive then
							return
						end
						S.massUpgradeLoopActive = true

						task.spawn(function()
							H.waitForPlayerController(25)

							while S.autoMassUpgradeRunning do
								if H.canMassUpgradeNow() then
									local ok = H.tryMassUpgradeSkills()
									if ok then
										H.setStatus("Mass upgraded skills")
									end
								end
								task.wait(MASS_UPGRADE_INTERVAL)
							end

							S.massUpgradeLoopActive = false
						end)
					end

					function H.setAutoUpgradeTargets(selected)
						S.autoUpgradeTargets = {
							primary_weapon = false,
							secondary_weapon = false,
							skin = false,
						}

						for _, label in ipairs(H.normalizeDropdownSelection(selected)) do
							local slotId = AUTO_UPGRADE_LABEL_TO_ID[label]
							if slotId then
								S.autoUpgradeTargets[slotId] = true
							end
						end
						H.scheduleSettingsSave()
					end

					function H.getGoldAmount()
						local constants = H.getSharedConstants()
						local dataKeys = constants and constants.DataKeys
						return H.getCurrencyAmount(dataKeys and dataKeys.GOLD or "gold")
					end

					function H.getRebirthCount()
						local stats = H.getClientStats()
						if not stats then
							return 0
						end

						for _, key in ipairs({ "rebirth", "rebirths", "rebirth_count" }) do
							local valueObj = stats:FindFirstChild(key)
							if valueObj and typeof(valueObj.Value) == "number" then
								return valueObj.Value
							end
						end
						return 0
					end

					function H.invalidateUpgradeInventorySnapshots()
						S.upgradeInventorySnapshots.weapon = nil
						S.upgradeInventorySnapshots.skin = nil
						S.upgradeInventorySnapshots.weaponAt = 0
						S.upgradeInventorySnapshots.skinAt = 0
					end

					function H.getUpgradeInventorySnapshot(kind, forceRefresh)
						local snapshotKey = kind == "weapon" and "weapon" or "skin"
						local atKey = snapshotKey .. "At"
						local now = os.clock()
						local snapshots = S.upgradeInventorySnapshots

						if not forceRefresh
							and snapshots[snapshotKey]
							and (now - (snapshots[atKey] or 0)) < AUTO_UPGRADE_INVENTORY_SNAPSHOT_TTL
						then
							return snapshots[snapshotKey]
						end

						local aero = H.getGlobal().Aero
						local gameDataService = aero and aero.Services and aero.Services.GameDataService
						if not gameDataService then
							return nil
						end

						local ok, data = pcall(function()
							if kind == "weapon" and gameDataService.GetPlayerWeapons then
								return gameDataService:GetPlayerWeapons(player)
							end
							if kind ~= "weapon" and gameDataService.GetPlayerSkins then
								return gameDataService:GetPlayerSkins(player)
							end
							return nil
						end)

						if ok and type(data) == "table" then
							snapshots[snapshotKey] = data
							snapshots[atKey] = now
							return data
						end

						return nil
					end

					function H.lookupUpgradeInventoryEntry(inventory, entry)
						if not inventory or not entry or not entry.key then
							return nil
						end

						return inventory[entry.key]
							or inventory[tostring(entry.key)]
							or inventory[tonumber(entry.key)]
					end

					function H.onPlayerRebirthDetected()
						H.invalidateUpgradeInventorySnapshots()
						S.autoUpgradeFailStreak = 0
						S.autoUpgradeLastRebirthCount = H.getRebirthCount()
						S.autoUpgradeLastPlayerLevel = H.getPlayerLevel()
						S.maxOutLastComplete = false

						if S.maxOutRunning and S.maxOutPhase == "upgrading" then
							S.maxOutPhase = "hunting"
						end

						if S.autoUpgradeRunning or S.maxOutRunning then
							task.defer(function()
								task.wait(AUTO_UPGRADE_POST_REBIRTH_WAIT)
								H.invalidateUpgradeInventorySnapshots()
								S.autoUpgradeFailStreak = 0
								if S.maxOutRunning then
									local progress = H.getMaxOutProgress(H.normalizeMaxOutTier(S.maxOutTier))
									if progress and progress.complete then
										S.maxOutLastComplete = true
										H.equipMaxOutGear(progress)
										H.ensureMaxOutUpgradeEnabled()
									end
								end
								H.ensureAutoUpgradeLoopRunning()
								H.tryAutoUpgradeBurst()
							end)
						end
					end

					function H.ensureAutoUpgradeRebirthListener()
						if S.autoUpgradeRebirthWatchConns then
							return
						end

						local stats = H.getClientStats()
						if not stats then
							return
						end

						S.autoUpgradeLastRebirthCount = H.getRebirthCount()
						S.autoUpgradeLastPlayerLevel = H.getPlayerLevel()
						S.autoUpgradeRebirthWatchConns = {}

						local function track(conn)
							table.insert(S.autoUpgradeRebirthWatchConns, conn)
						end

						for _, key in ipairs({ "rebirth", "rebirths", "rebirth_count" }) do
							local valueObj = stats:FindFirstChild(key)
							if valueObj then
								track(valueObj.Changed:Connect(function(newValue)
									local last = S.autoUpgradeLastRebirthCount
									if type(newValue) == "number" and (last == nil or newValue > last) then
										H.onPlayerRebirthDetected()
									end
								end))
							end
						end

						local levelValue = stats:FindFirstChild("level")
						if levelValue then
							track(levelValue.Changed:Connect(function(newLevel)
								local lastLevel = S.autoUpgradeLastPlayerLevel
								if type(newLevel) == "number" and type(lastLevel) == "number" and newLevel < lastLevel - 5 then
									H.onPlayerRebirthDetected()
								end
								S.autoUpgradeLastPlayerLevel = newLevel
							end))
						end
					end

					function H.teardownAutoUpgradeRebirthListener()
						if S.autoUpgradeRebirthWatchConns then
							for _, conn in ipairs(S.autoUpgradeRebirthWatchConns) do
								pcall(function()
									conn:Disconnect()
								end)
							end
							S.autoUpgradeRebirthWatchConns = nil
						end
					end

					function H.resolveUpgradeEntryKey(entry)
						if not entry or not entry.key then
							return nil
						end

						local inventory
						if entry.kind == "weapon" then
							inventory = H.getWeaponInventoryData()
						else
							inventory = H.getSkinInventoryData()
						end

						if not inventory then
							return tostring(entry.key)
						end

						return H.resolveInventoryKey(inventory, entry.key)
					end

					function H.isValidUpgradeEntry(entry)
						if H.getUpgradeInventoryEntry(entry) ~= nil then
							return true
						end

						-- After rebirth the UI inventory controller can lag behind GameDataService.
						if S.maxOutRunning then
							local progress = H.getMaxOutProgress(H.normalizeMaxOutTier(S.maxOutTier))
							if progress and progress.complete then
								local inventory = H.getUpgradeInventorySnapshot(entry.kind, true)
								return H.lookupUpgradeInventoryEntry(inventory, entry) ~= nil
							end
						end

						return false
					end

					function H.appendUpgradeEntry(entries, key, kind, order)
						if not key or key == "0" then
							return
						end

						local entry = {
							key = tostring(key),
							kind = kind,
							order = order,
						}
						if H.isValidUpgradeEntry(entry) then
							local resolved = H.resolveUpgradeEntryKey(entry)
							if resolved ~= nil then
								entry.key = tostring(resolved)
							end
							table.insert(entries, entry)
						end
					end

					function H.getMaxOutUpgradeEntries()
						if not S.maxOutRunning then
							return nil
						end

						local progress = H.getMaxOutProgress(H.normalizeMaxOutTier(S.maxOutTier))
						if not progress or not progress.complete then
							return nil
						end

						local entries = {}
						local targets = S.autoUpgradeTargets

						if targets.primary_weapon and progress.weaponKeys and progress.weaponKeys[1] then
							H.appendUpgradeEntry(entries, progress.weaponKeys[1].key, "weapon", 1)
						end

						if targets.secondary_weapon and H.canDualWieldNow() and progress.weaponKeys and progress.weaponKeys[2] then
							H.appendUpgradeEntry(entries, progress.weaponKeys[2].key, "weapon", 2)
						end

						if targets.skin and progress.skinKeys and progress.skinKeys[1] then
							H.appendUpgradeEntry(entries, progress.skinKeys[1].key, "skin", 3)
						end

						if #entries > 0 then
							return entries
						end
						return nil
					end

					function H.getEquippedUpgradeEntries()
						local maxOutEntries = H.getMaxOutUpgradeEntries()
						if maxOutEntries and #maxOutEntries > 0 then
							return maxOutEntries
						end

						local entries = {}
						local targets = S.autoUpgradeTargets

						if targets.primary_weapon then
							H.appendUpgradeEntry(entries, H.getEquippedItemKey("weapon_equipped"), "weapon", 1)
						end

						if targets.secondary_weapon and H.canDualWieldNow() then
							H.appendUpgradeEntry(entries, H.getEquippedItemKey("offhand_equipped"), "weapon", 2)
						end

						if targets.skin then
							H.appendUpgradeEntry(entries, H.getEquippedItemKey("skin_equipped"), "skin", 3)
						end

						return entries
					end

					function H.getUpgradeInventoryEntry(entry)
						if not entry or not entry.key then
							return nil
						end

						local inventory
						if entry.kind == "weapon" then
							inventory = H.getWeaponInventoryData()
						else
							inventory = H.getSkinInventoryData()
						end

						local data = H.lookupUpgradeInventoryEntry(inventory, entry)
						if data then
							return data
						end

						inventory = H.getUpgradeInventorySnapshot(entry.kind, S.autoUpgradeFailStreak >= AUTO_UPGRADE_FAIL_REFRESH_AFTER)
						return H.lookupUpgradeInventoryEntry(inventory, entry)
					end

					function H.getUpgradeEntryLevel(entry)
						local data = H.getUpgradeInventoryEntry(entry)
						if not data then
							return 0
						end
						return data.upgrades or 0
					end

					function H.syncUpgradeLevelCache(entries)
						for _, entry in ipairs(entries) do
							entry.level = H.getUpgradeEntryLevel(entry)
						end
					end

					function H.getUpgradeItemType(entry)
						local constants = H.getSharedConstants()
						if entry.kind == "weapon" then
							return constants and constants.ItemType and constants.ItemType.WEAPON or "weapon"
						end
						return constants and constants.ItemType and constants.ItemType.SKIN or "skin"
					end

					function H.getBalancedLevelGainForGold(constants, level, gold, count)
						if not constants or gold <= 0 or count <= 0 then
							return 0
						end

						local function totalCostForGain(gain)
							if gain <= 0 then
								return 0
							end
							return constants:TotalCostForUpgrade(level + gain) - constants:TotalCostForUpgrade(level)
						end

						local lo, hi = 0, 1
						while totalCostForGain(hi) * count <= gold do
							if hi >= 1000000 then
								break
							end
							hi *= 2
						end

						local best = 0
						while lo <= hi do
							local mid = math.floor((lo + hi) / 2)
							if totalCostForGain(mid) * count <= gold then
								best = mid
								lo = mid + 1
							else
								hi = mid - 1
							end
						end

						return best
					end

					function H.getUpgradeLevelSpread(entries)
						local minLevel = math.huge
						local maxLevel = -math.huge
						for _, entry in ipairs(entries) do
							local level = H.getUpgradeEntryLevel(entry)
							entry.level = level
							if level < minLevel then
								minLevel = level
							end
							if level > maxLevel then
								maxLevel = level
							end
						end
						if minLevel == math.huge then
							return 0
						end
						return maxLevel - minLevel
					end

					function H.sortUpgradeEntries(entries)
						table.sort(entries, function(a, b)
							local aLevel = H.getUpgradeEntryLevel(a)
							local bLevel = H.getUpgradeEntryLevel(b)
							a.level = aLevel
							b.level = bLevel
							if aLevel ~= bLevel then
								return aLevel < bLevel
							end
							return (a.order or 99) < (b.order or 99)
						end)
					end

					function H.isUpgradeSuccess(response)
						if response == true then
							return true
						end
						return H.isGameServiceOk(response)
					end

					function H.tryUpgradeEquippedEntry(entry)
						if not entry or not entry.key then
							return false
						end

						local itemKey = H.resolveUpgradeEntryKey(entry)
						if itemKey == nil then
							return false
						end

						if entry.kind == "weapon" then
							return H.isUpgradeSuccess(H.callGameService("UpgradeWeapon", itemKey))
						end

						return H.isUpgradeSuccess(H.callGameService("UpgradeSkin", itemKey))
					end

					function H.requestMaxUpgradeEntry(entry)
						if not entry or not entry.key then
							return false
						end

						local itemKey = H.resolveUpgradeEntryKey(entry)
						if itemKey == nil then
							return false
						end

						return H.isUpgradeSuccess(H.callGameService("RequestMaxUpgradeItem", H.getUpgradeItemType(entry), itemKey))
					end

					function H.getLowestUpgradeEntry(entries)
						local bestEntry = nil
						local bestLevel = math.huge
						for _, entry in ipairs(entries) do
							local level = H.getUpgradeEntryLevel(entry)
							entry.level = level
							if level < bestLevel then
								bestLevel = level
								bestEntry = entry
							end
						end
						return bestEntry
					end

					function H.tryRequestMaxUpgradeEntries(entries)
						H.sortUpgradeEntries(entries)
						for _, entry in ipairs(entries) do
							if H.requestMaxUpgradeEntry(entry) then
								return true
							end
						end
						return false
					end

					function H.tryBalancedUpgradeRound(entries, targetLevel)
						local changed = false
						H.sortUpgradeEntries(entries)
						for _, entry in ipairs(entries) do
							local liveLevel = H.getUpgradeEntryLevel(entry)
							entry.level = liveLevel
							if liveLevel == targetLevel then
								if H.tryUpgradeEquippedEntry(entry) then
									entry.level = liveLevel + 1
									changed = true
								end
							end
						end
						return changed
					end

					function H.tryBalancedBulkUpgrade(entries, constants, gold)
						if #entries == 0 or gold <= 0 then
							return false
						end

						local minLevel = math.huge
						for _, entry in ipairs(entries) do
							local level = H.getUpgradeEntryLevel(entry)
							entry.level = level
							if level < minLevel then
								minLevel = level
							end
						end
						if minLevel == math.huge then
							return false
						end

						local gain = H.getBalancedLevelGainForGold(constants, minLevel, gold, #entries)
						if gain <= 0 then
							return false
						end

						gain = math.min(gain, AUTO_UPGRADE_BULK_MAX_LEVELS)
						local changed = false
						for roundLevel = minLevel, minLevel + gain - 1 do
							if H.getGoldAmount() <= 0 then
								break
							end
							if H.tryBalancedUpgradeRound(entries, roundLevel) then
								changed = true
							else
								break
							end
						end

						return changed
					end

					function H.tryAutoUpgradeBurst()
						local entries = H.getEquippedUpgradeEntries()
						if #entries == 0 then
							if S.autoUpgradeFailStreak >= AUTO_UPGRADE_FAIL_REFRESH_AFTER then
								H.invalidateUpgradeInventorySnapshots()
								entries = H.getEquippedUpgradeEntries()
							end
							if #entries == 0 then
								S.autoUpgradeFailStreak += 1
								return false
							end
						end

						local constants = H.getSharedConstants()
						if not constants then
							S.autoUpgradeFailStreak += 1
							return false
						end

						H.syncUpgradeLevelCache(entries)

						local gold = H.getGoldAmount()
						if gold <= 0 then
							return false
						end

						local lowestEntry = H.getLowestUpgradeEntry(entries)
						if lowestEntry and H.requestMaxUpgradeEntry(lowestEntry) then
							S.autoUpgradeFailStreak = 0
							return true
						end

						if #entries == 1 then
							if H.requestMaxUpgradeEntry(entries[1]) then
								S.autoUpgradeFailStreak = 0
								return true
							end
						else
							local minLevel = math.huge
							local secondMin = math.huge
							local minCount = 0
							for _, entry in ipairs(entries) do
								local level = H.getUpgradeEntryLevel(entry)
								entry.level = level
								if level < minLevel then
									secondMin = minLevel
									minLevel = level
									minCount = 1
								elseif level == minLevel then
									minCount += 1
								elseif level < secondMin then
									secondMin = level
								end
							end

							if minCount == 1 and secondMin ~= math.huge and (secondMin - minLevel) >= AUTO_UPGRADE_CATCHUP_GAP then
								for _, entry in ipairs(entries) do
									if H.getUpgradeEntryLevel(entry) == minLevel then
										if H.requestMaxUpgradeEntry(entry) then
											S.autoUpgradeFailStreak = 0
											return true
										end
										break
									end
								end
							end

							if H.getUpgradeLevelSpread(entries) <= 1 then
								if H.tryBalancedBulkUpgrade(entries, constants, gold) then
									S.autoUpgradeFailStreak = 0
									return true
								end
							end

							local changed = false
							local steps = 0

							while steps < AUTO_UPGRADE_MAX_STEPS and H.getGoldAmount() > 0 do
								local roundMin = math.huge
								for _, entry in ipairs(entries) do
									local level = H.getUpgradeEntryLevel(entry)
									entry.level = level
									if level < roundMin then
										roundMin = level
									end
								end
								if roundMin == math.huge then
									break
								end

								if not H.tryBalancedUpgradeRound(entries, roundMin) then
									break
								end

								changed = true
								steps += 1
							end

							if changed then
								S.autoUpgradeFailStreak = 0
								return true
							end

							if H.tryRequestMaxUpgradeEntries(entries) then
								S.autoUpgradeFailStreak = 0
								return true
							end
						end

						S.autoUpgradeFailStreak += 1
						if S.autoUpgradeFailStreak >= AUTO_UPGRADE_FAIL_REFRESH_AFTER then
							H.invalidateUpgradeInventorySnapshots()
							S.autoUpgradeFailStreak = 0
							entries = H.getEquippedUpgradeEntries()
							if #entries > 0 and H.tryRequestMaxUpgradeEntries(entries) then
								return true
							end
						end

						return false
					end

					function H.stopAutoUpgradeLoop()
						S.autoUpgradeRunning = false
					end

					function H.ensureAutoUpgradeLoopRunning()
						if S.autoUpgradeRunning and not S.autoUpgradeLoopActive then
							H.startAutoUpgradeLoop()
						end
					end

					function H.startAutoUpgradeLoop()
						if S.autoUpgradeLoopActive then
							return
						end
						S.autoUpgradeLoopActive = true

						task.spawn(function()
							while S.autoUpgradeRunning do
								local ok, upgraded = pcall(H.tryAutoUpgradeBurst)
								if not ok then
									warn("[ExonHub] Auto upgrade burst error:", upgraded)
									H.invalidateUpgradeInventorySnapshots()
								elseif upgraded then
									H.setStatus("Auto upgraded equipped gear")
								else
									task.wait(AUTO_UPGRADE_IDLE_WAIT)
								end
							end

							S.autoUpgradeLoopActive = false
						end)
					end

					function H.setAutoBossTargets(selected)
						S.autoBossTargets = {
							borock = false,
							demon_king = false,
						}

						for _, label in ipairs(H.normalizeDropdownSelection(selected)) do
							local bossId = AUTO_BOSS_LABEL_TO_ID[label]
							if bossId then
								S.autoBossTargets[bossId] = true
							end
						end
						H.scheduleSettingsSave()
					end

					function H.getBossDefinition(bossId)
						return AUTO_BOSS_DEFS[bossId]
					end

					function H.getBossFolder(def)
						if not def or not def.folderPath then
							return nil
						end

						local current = workspace
						for _, name in ipairs(def.folderPath) do
							current = current and current:FindFirstChild(name)
						end
						return current
					end

					function H.getBossModel(def)
						local folder = H.getBossFolder(def)
						if not folder or not def.modelName then
							return nil
						end
						return folder:FindFirstChild(def.modelName)
					end

					function H.getBossHumanoid(model)
						if not model then
							return nil
						end
						return model:FindFirstChildOfClass("Humanoid")
					end

					function H.getBossValsFolder()
						return ReplicatedStorage:FindFirstChild("BossVals")
					end

					function H.getBorockSharedHealth()
						local vals = H.getBossValsFolder()
						local hp = vals and vals:FindFirstChild("BossHealth")
						if hp and typeof(hp.Value) == "number" then
							return hp.Value
						end
						return nil
					end

					function H.getBossHealth(def)
						if not def then
							return math.huge
						end

						local model = H.getBossModel(def)
						local humanoid = H.getBossHumanoid(model)
						if humanoid then
							if humanoid.Health > 0 then
								return humanoid.Health
							end
							return math.huge
						end

						if def.useBossVals then
							local sharedHealth = H.getBorockSharedHealth()
							if sharedHealth and sharedHealth > 0 then
								return sharedHealth
							end
						end

						return math.huge
					end

					function H.isBossAlive(def)
						return H.getBossHealth(def) < math.huge
					end

					function H.pickLowestHealthAliveBoss()
						local best = nil
						local bestHealth = math.huge

						for _, def in ipairs(H.getEnabledBossDefinitions()) do
							local health = H.getBossHealth(def)
							if health < bestHealth then
								bestHealth = health
								best = def
							end
						end

						return best
					end

					function H.getEnabledBossDefinitions()
						local enabled = {}
						for _, bossId in ipairs(AUTO_BOSS_ORDER) do
							if S.autoBossTargets[bossId] then
								local def = AUTO_BOSS_DEFS[bossId]
								if def then
									table.insert(enabled, def)
								end
							end
						end
						return enabled
					end

					function H.teleportNearBoss(def)
						local model = H.getBossModel(def)
						local bossRoot = model and model:FindFirstChild("HumanoidRootPart")
						local playerRoot = H.getCharacterRoot()
						if not bossRoot or not playerRoot then
							return false
						end

						local approach = -bossRoot.CFrame.LookVector * AUTO_BOSS_APPROACH_OFFSET
						playerRoot.CFrame = CFrame.new(bossRoot.Position + approach + Vector3.new(0, 2, 0), bossRoot.Position)
						return true
					end

					function H.getFollowCFrameNearBoss(bossRoot)
						if not bossRoot then
							return nil
						end

						local approach = -bossRoot.CFrame.LookVector * AUTO_BOSS_APPROACH_OFFSET
						return CFrame.new(bossRoot.Position + approach + Vector3.new(0, 2, 0), bossRoot.Position)
					end

					function H.cancelAutoBossFollow()
						if S.autoBossFollowTween then
							pcall(function()
								S.autoBossFollowTween:Cancel()
							end)
							S.autoBossFollowTween = nil
						end
						if S.autoBossFollowConnection then
							pcall(function()
								S.autoBossFollowConnection:Disconnect()
							end)
							S.autoBossFollowConnection = nil
						end
						S.autoBossFollowDefId = nil
					end

					function H.tweenToFollowBoss(bossRoot)
						local playerRoot = H.getCharacterRoot()
						if not playerRoot or not bossRoot or not bossRoot.Parent then
							return false
						end

						local goal = H.getFollowCFrameNearBoss(bossRoot)
						if not goal then
							return false
						end

						playerRoot.AssemblyLinearVelocity = Vector3.zero
						playerRoot.AssemblyAngularVelocity = Vector3.zero

						local dist = (playerRoot.Position - goal.Position).Magnitude
						if dist < 0.35 then
							playerRoot.CFrame = goal
							return true
						end

						if S.autoBossFollowTween then
							pcall(function()
								S.autoBossFollowTween:Cancel()
							end)
						end

						local duration = math.clamp(dist / AUTO_KILL_FOLLOW_MAX_SPEED, 0.02, AUTO_KILL_FOLLOW_TWEEN_TIME)
						S.autoBossFollowTween = TweenService:Create(playerRoot, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
							CFrame = goal,
						})
						S.autoBossFollowTween:Play()
						return true
					end

					function H.startFollowBoss(def)
						H.cancelAutoBossFollow()

						if not H.teleportNearBoss(def) then
							return false
						end

						local followDef = def
						S.autoBossFollowDefId = def.id
						S.autoBossFollowConnection = RunService.Heartbeat:Connect(function()
							if not S.autoBossRunning then
								H.cancelAutoBossFollow()
								return
							end

							local model = H.getBossModel(followDef)
							local bossRoot = model and model:FindFirstChild("HumanoidRootPart")
							if not bossRoot or not H.isBossAlive(followDef) then
								H.cancelAutoBossFollow()
								return
							end

							H.tweenToFollowBoss(bossRoot)
						end)

						return true
					end

					function H.getQuestBossDef(targetKey)
						if targetKey == "Borock" then
							return AUTO_BOSS_DEFS.borock
						elseif targetKey == "DemonKing" then
							return AUTO_BOSS_DEFS.demon_king
						end
						return nil
					end

					function H.getQuestBossWaitTeleport(targetKey)
						local label = targetKey == "Borock" and "Borock Boss" or (targetKey == "DemonKing" and "Demon King" or nil)
						if not label then
							return nil
						end
						for _, location in ipairs(MISC_TP_LOCATIONS) do
							if location.label == label then
								return CFrame.new(location.position)
							end
						end
						return nil
					end

					function H.ensureQuestBossWaitPosition(targetKey)
						if S.autoQuestBossWaitTpDone then
							return
						end
						local waitCFrame = H.getQuestBossWaitTeleport(targetKey)
						if waitCFrame then
							H.teleportCharacterTo(waitCFrame)
							S.autoQuestBossWaitTpDone = true
						end
					end

					function H.cancelAutoQuestBossFollow()
						if S.autoQuestBossFollowTween then
							pcall(function()
								S.autoQuestBossFollowTween:Cancel()
							end)
							S.autoQuestBossFollowTween = nil
						end
						if S.autoQuestBossFollowConnection then
							pcall(function()
								S.autoQuestBossFollowConnection:Disconnect()
							end)
							S.autoQuestBossFollowConnection = nil
						end
						S.autoQuestBossFollowDefId = nil
					end

					function H.tweenToFollowQuestBoss(bossRoot)
						local playerRoot = H.getCharacterRoot()
						if not playerRoot or not bossRoot or not bossRoot.Parent then
							return false
						end

						local goal = H.getFollowCFrameNearBoss(bossRoot)
						if not goal then
							return false
						end

						playerRoot.AssemblyLinearVelocity = Vector3.zero
						playerRoot.AssemblyAngularVelocity = Vector3.zero

						local dist = (playerRoot.Position - goal.Position).Magnitude
						if dist < 0.35 then
							playerRoot.CFrame = goal
							return true
						end

						if S.autoQuestBossFollowTween then
							pcall(function()
								S.autoQuestBossFollowTween:Cancel()
							end)
						end

						local duration = math.clamp(dist / AUTO_KILL_FOLLOW_MAX_SPEED, 0.02, AUTO_KILL_FOLLOW_TWEEN_TIME)
						S.autoQuestBossFollowTween = TweenService:Create(playerRoot, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
							CFrame = goal,
						})
						S.autoQuestBossFollowTween:Play()
						return true
					end

					function H.startQuestBossFollow(def)
						H.cancelAutoQuestBossFollow()

						if not H.teleportNearBoss(def) then
							return false
						end

						local followDef = def
						S.autoQuestBossFollowDefId = def.id
						S.autoQuestBossFollowConnection = RunService.Heartbeat:Connect(function()
							if not S.autoQuestRunning then
								H.cancelAutoQuestBossFollow()
								return
							end

							local model = H.getBossModel(followDef)
							local bossRoot = model and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso"))
							if not bossRoot or not H.isBossAlive(followDef) then
								H.cancelAutoQuestBossFollow()
								return
							end

							H.tweenToFollowQuestBoss(bossRoot)
						end)

						return true
					end

					function H.ensureQuestBossSwing(on)
						if on then
							local pc = H.getPlayerController() or H.waitForPlayerController(5)
							if pc then
								H.tryAeroAutoSwing(pc, true)
								S.autoQuestBossSwingActive = pc.DoAutoClick == true
							end
							return
						end

						if S.autoQuestBossSwingActive then
							H.tryAeroAutoSwing(H.getPlayerController(), false)
							S.autoQuestBossSwingActive = false
						end
					end

					function H.waitForQuestRespawn(timeout)
						local deadline = os.clock() + (timeout or 25)
						while os.clock() < deadline do
							if not S.autoQuestRunning then
								return false
							end
							local hum = H.getHumanoid()
							if hum and hum.Health > 0 then
								return true
							end
							task.wait(0.25)
						end
						return false
					end

					function H.ensureBossSwing(on)
						if on then
							local pc = H.getPlayerController() or H.waitForPlayerController(5)
							if pc then
								H.tryAeroAutoSwing(pc, true)
								S.autoBossSwingActive = pc.DoAutoClick == true
							end
							return
						end

						if S.autoBossSwingActive then
							H.tryAeroAutoSwing(H.getPlayerController(), false)
							S.autoBossSwingActive = false
						end
					end

					function H.waitForPlayerRespawn(timeout)
						local deadline = os.clock() + (timeout or 20)
						while os.clock() < deadline do
							if not S.autoBossRunning then
								return false
							end
							local hum = H.getHumanoid()
							if hum and hum.Health > 0 then
								return true
							end
							task.wait(0.25)
						end
						return false
					end

					function H.runAutoBossCycle()
						H.ensureWeaponEquipped(H.getPlayerController())
						H.ensureBossSwing(true)
						local useFallbackSwing = not S.autoBossSwingActive
						local lastSwingAt = 0

						while S.autoBossRunning do
							local bosses = H.getEnabledBossDefinitions()
							if #bosses == 0 then
								H.setStatus("Select at least one boss")
								task.wait(1)
							else
								local target = H.pickLowestHealthAliveBoss()
								if not target then
									H.cancelAutoBossFollow()
									H.setStatus("Waiting for boss respawn...")
									task.wait(AUTO_BOSS_POLL)
								else
									local hum = H.getHumanoid()
									if not hum or hum.Health <= 0 then
										H.cancelAutoBossFollow()
										H.setStatus("Respawning...")
										if not H.waitForPlayerRespawn(25) then
											break
										end
									end

									H.setStatus("Fighting " .. target.label)
									if S.autoBossFollowDefId ~= target.id or not S.autoBossFollowConnection then
										H.startFollowBoss(target)
									end

									if useFallbackSwing and os.clock() - lastSwingAt >= AUTO_BOSS_SWING_INTERVAL then
										H.backgroundTrainSwing()
										lastSwingAt = os.clock()
									end

									task.wait(AUTO_BOSS_POLL)
								end
							end
						end

						H.cancelAutoBossFollow()
						H.ensureBossSwing(false)
					end

					function H.stopAutoBossLoop()
						S.autoBossRunning = false
						H.cancelAutoBossFollow()
						H.ensureBossSwing(false)
					end

					function H.startAutoBossLoop()
						if S.autoBossLoopActive then
							return
						end
						S.autoBossLoopActive = true

						task.spawn(function()
							H.runAutoBossCycle()
							S.autoBossLoopActive = false
						end)
					end

					function H.getPlayerClientBool(targetPlayer, valueName)
						if not targetPlayer then
							return nil
						end

						local gui = targetPlayer:FindFirstChild("PlayerGui")
						local clientData = gui and gui:FindFirstChild("ClientData")
						local valueObj = clientData and clientData:FindFirstChild(valueName)
						if valueObj and typeof(valueObj.Value) == "boolean" then
							return valueObj.Value
						end
						return nil
					end

					function H.isPositionInPvpGroundArea(position)
						local localPos = PVP_GROUND_CFRAME:PointToObjectSpace(position)
						local half = PVP_GROUND_SIZE * 0.5
						local pad = AUTO_KILL_GROUND_RADIUS

						local dx = math.max(0, math.abs(localPos.X) - half.X)
						local dz = math.max(0, math.abs(localPos.Z) - half.Z)
						local distOutside = math.sqrt(dx * dx + dz * dz)
						if distOutside > pad then
							return false
						end

						if localPos.Y < -half.Y - 50 or localPos.Y > half.Y + AUTO_KILL_GROUND_MAX_HEIGHT then
							return false
						end

						return true
					end

					function H.getFollowCFrameOnTarget(targetRoot)
						if not targetRoot then
							return nil
						end
						return targetRoot.CFrame * CFrame.new(AUTO_KILL_TP_OFFSET)
					end

					function H.cancelAutoKillFollow()
						if S.autoKillFollowTween then
							pcall(function()
								S.autoKillFollowTween:Cancel()
							end)
							S.autoKillFollowTween = nil
						end
						if S.autoKillFollowConnection then
							pcall(function()
								S.autoKillFollowConnection:Disconnect()
							end)
							S.autoKillFollowConnection = nil
						end
					end

					function H.tweenToFollowTarget(targetRoot)
						local root = H.getCharacterRoot()
						if not root or not targetRoot or not targetRoot.Parent then
							return false
						end

						local goal = H.getFollowCFrameOnTarget(targetRoot)
						if not goal then
							return false
						end

						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero

						local dist = (root.Position - goal.Position).Magnitude
						if dist < 0.35 then
							root.CFrame = goal
							return true
						end

						if S.autoKillFollowTween then
							pcall(function()
								S.autoKillFollowTween:Cancel()
							end)
						end

						local duration = math.clamp(dist / AUTO_KILL_FOLLOW_MAX_SPEED, 0.02, AUTO_KILL_FOLLOW_TWEEN_TIME)
						S.autoKillFollowTween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
							CFrame = goal,
						})
						S.autoKillFollowTween:Play()
						return true
					end

					function H.startFollowCharacter(character)
						H.cancelAutoKillFollow()

						local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
						local root = H.getCharacterRoot()
						if not targetRoot or not root then
							return false
						end
						if not H.isPositionInPvpGroundArea(targetRoot.Position) then
							return false
						end

						local goal = H.getFollowCFrameOnTarget(targetRoot)
						if goal then
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							root.CFrame = goal
						end

						S.autoKillFollowConnection = RunService.Heartbeat:Connect(function()
							if not S.autoKillRunning then
								H.cancelAutoKillFollow()
								return
							end

							local hum = H.getHumanoid()
							if not hum or hum.Health <= 0 then
								H.cancelAutoKillFollow()
								return
							end

							local liveTargetRoot = character and character:FindFirstChild("HumanoidRootPart")
							if not liveTargetRoot or not liveTargetRoot.Parent then
								H.cancelAutoKillFollow()
								return
							end
							if not H.isPositionInPvpGroundArea(liveTargetRoot.Position) then
								return
							end

							H.tweenToFollowTarget(liveTargetRoot)
						end)

						return true
					end

					function H.isPlayerInPvpGroundArea(targetPlayer)
						local character = targetPlayer and targetPlayer.Character
						local root = character and character:FindFirstChild("HumanoidRootPart")
						if not root then
							return false
						end
						return H.isPositionInPvpGroundArea(root.Position)
					end

					function H.getSafeZoneRegions()
						if S.cachedSafeZoneRegions then
							return S.cachedSafeZoneRegions
						end

						local regions = {}
						local function addPartRegion(part, padding)
							if part and part:IsA("BasePart") then
								table.insert(regions, {
									center = part.Position,
									halfSize = part.Size * 0.5 + padding,
								})
							end
						end

						local spawnsFolder = H.getWorkspacePath({ "Scene", "Spawns" })
						if spawnsFolder then
							for _, child in ipairs(spawnsFolder:GetChildren()) do
								addPartRegion(child, SAFE_ZONE_HUB_PADDING)
							end
						end

						addPartRegion(H.getWorkspacePath({ "Scene", "Minefield", "PlayerSpawn" }), Vector3.new(24, 40, 24))

						S.cachedSafeZoneRegions = regions
						return regions
					end

					function H.isPositionInSafeRegions(position)
						for _, region in ipairs(H.getSafeZoneRegions()) do
							local delta = position - region.center
							if math.abs(delta.X) <= region.halfSize.X
								and math.abs(delta.Y) <= region.halfSize.Y
								and math.abs(delta.Z) <= region.halfSize.Z then
								return true
							end
						end
						return false
					end

					function H.hasSpawnProtection(character)
						if not character then
							return false
						end
						for _, descendant in ipairs(character:GetDescendants()) do
							if descendant:IsA("ForceField") then
								return true
							end
							if descendant.Name == "Shield" and descendant:IsA("BasePart") and descendant.Transparency < 1 then
								return true
							end
						end
						return false
					end

					function H.isPlayerInSafeZone(targetPlayer)
						if not targetPlayer or targetPlayer == player then
							return true
						end

						if H.getPlayerClientBool(targetPlayer, "inCave") == true then
							return true
						end
						if H.getPlayerClientBool(targetPlayer, "inDungeon") == true then
							return true
						end

						local character = targetPlayer.Character
						local root = character and character:FindFirstChild("HumanoidRootPart")
						if root and H.isPositionInSafeRegions(root.Position) then
							return true
						end
						if H.hasSpawnProtection(character) then
							return true
						end

						return false
					end

					function H.getKillablePlayers()
						local targets = {}
						for _, otherPlayer in ipairs(Players:GetPlayers()) do
							if otherPlayer ~= player and otherPlayer.Character then
								local hum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
								if hum and hum.Health > 0 and H.isPlayerInPvpGroundArea(otherPlayer) then
									table.insert(targets, otherPlayer)
								end
							end
						end
						return targets
					end

					function H.attackPlayerCharacter(character)
						if not character then
							return false
						end

						local targetRoot = character:FindFirstChild("HumanoidRootPart")
						local targetHum = character:FindFirstChildOfClass("Humanoid")
						if not targetRoot or not targetHum or targetHum.Health <= 0 then
							return false
						end
						if not H.isPositionInPvpGroundArea(targetRoot.Position) then
							return false
						end

						if not H.startFollowCharacter(character) then
							return false
						end
						H.ensureWeaponEquipped(H.getPlayerController())

						local melee = H.getMeleeController()
						if melee and melee.OnSwingStart then
							melee:OnSwingStart()
						end

						while S.autoKillRunning do
							targetRoot = character:FindFirstChild("HumanoidRootPart")
							targetHum = character:FindFirstChildOfClass("Humanoid")
							if not targetRoot or not targetHum or targetHum.Health <= 0 then
								break
							end
							if not H.isPositionInPvpGroundArea(targetRoot.Position) then
								break
							end

							H.fireMeleeHitOnPart(targetRoot)
							H.backgroundTrainSwing()
							task.wait(AUTO_KILL_SWING_INTERVAL)
						end

						H.cancelAutoKillFollow()
						if melee and melee.OnSwingEnd then
							melee:OnSwingEnd()
						end

						return true
					end

					function H.fireMeleeHitOnPart(hitPart)
						if not hitPart then
							return false
						end

						local aero = H.getGlobal().Aero
						if not aero or not aero.Services or not aero.Services.GameService then
							return false
						end

						local constants = H.getSharedConstants()
						if not constants or not constants.RemoteEvents then
							return false
						end

						local remote = aero.Services.GameService[constants.RemoteEvents.MELEE_HIT]
						if not remote or not remote.Fire then
							return false
						end

						return pcall(function()
							remote:Fire(hitPart)
						end)
					end

					function H.getMeleeController()
						local aero = H.getGlobal().Aero
						return aero and aero.Controllers and aero.Controllers.MeleeController or nil
					end

					function H.getKothContestHitParts(character)
						local parts = {}
						if not character then
							return parts
						end

						local hrp = character:FindFirstChild("HumanoidRootPart")
						local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
						if hrp then
							table.insert(parts, hrp)
						end
						if torso and torso ~= hrp then
							table.insert(parts, torso)
						end
						return parts
					end

					function H.getOrderedKothContestPlayers()
						local contestPlayers = H.getKothContestPlayers()
						if #contestPlayers <= 1 then
							return contestPlayers
						end

						local root = H.getCharacterRoot()
						local look = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
						local flatLook = Vector3.new(look.X, 0, look.Z)
						if flatLook.Magnitude < 0.05 then
							flatLook = Vector3.new(0, 0, -1)
						else
							flatLook = flatLook.Unit
						end

						local rootPos = root and root.Position or Vector3.zero
						local scored = {}
						for _, otherPlayer in ipairs(contestPlayers) do
							local hrp = otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
							if hrp then
								local offset = hrp.Position - rootPos
								local flatOffset = Vector3.new(offset.X, 0, offset.Z)
								local dist = flatOffset.Magnitude
								local behindScore = 0
								if dist > 0.25 then
									behindScore = flatOffset.Unit:Dot(-flatLook)
								end
								table.insert(scored, {
									player = otherPlayer,
									score = behindScore * 120 - dist,
								})
							end
						end

						table.sort(scored, function(a, b)
							return a.score > b.score
						end)

						local ordered = {}
						for _, entry in ipairs(scored) do
							table.insert(ordered, entry.player)
						end
						return ordered
					end

					function H.isKothIdlePeaceful()
						if not S.autoKothRunning or S.kothDefendBusy or H.isAutoGoalsKickBusy() or H.isKothRecovering() then
							return false
						end
						if H.hasKothContestThreat() then
							return false
						end

						local state = H.getKOTHState()
						if not state or state.contested == true then
							return false
						end

						local isKing = state.kingUserId == player.UserId
						return isKing and H.isKothKingLevel(H.getKothSelfLevel())
					end

					function H.applyKothIdleSpin(root, hillCFrame, dt)
						if not root or not hillCFrame then
							return
						end

						local hum = H.getHumanoid()
						if hum then
							hum.AutoRotate = false
						end

						S.kothIdleSpinAngle = ((S.kothIdleSpinAngle or 0) + AUTO_KOTH_IDLE_SPIN_SPEED * dt) % 360
						local pos = hillCFrame.Position
						local angle = math.rad(S.kothIdleSpinAngle)
						local look = Vector3.new(math.sin(angle), 0, math.cos(angle))
						root.CFrame = CFrame.lookAt(pos, pos + look)
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
					end

					function H.getNearestKothContestPlayer()
						return H.getPriorityKothContestPlayer()
					end

					function H.getPriorityKothContestPlayer()
						local contestPlayers = H.getKothContestPlayers()
						if #contestPlayers == 0 then
							return nil
						end

						local root = H.getCharacterRoot()
						if not root then
							return contestPlayers[1]
						end

						local look = root.CFrame.LookVector
						local flatLook = Vector3.new(look.X, 0, look.Z)
						if flatLook.Magnitude < 0.05 then
							flatLook = Vector3.new(0, 0, -1)
						else
							flatLook = flatLook.Unit
						end

						local bestPlayer = nil
						local bestScore = -math.huge
						for _, otherPlayer in ipairs(contestPlayers) do
							local hrp = otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
							if hrp then
								local offset = hrp.Position - root.Position
								local flatOffset = Vector3.new(offset.X, 0, offset.Z)
								local dist = flatOffset.Magnitude
								local behindScore = 0
								if dist > 0.25 then
									behindScore = flatOffset.Unit:Dot(-flatLook)
								end
								local score = behindScore * 120 - dist
								if score > bestScore then
									bestScore = score
									bestPlayer = otherPlayer
								end
							end
						end

						return bestPlayer or contestPlayers[1]
					end

					function H.getKothBehindCFrame(targetRoot)
						if not targetRoot then
							return nil
						end

						local hillCFrame = H.getKothHillCFrame()
						local hillY = hillCFrame and hillCFrame.Position.Y or targetRoot.Position.Y
						local behind = targetRoot.CFrame * CFrame.new(0, 0, AUTO_KOTH_DEFEND_BEHIND_OFFSET)
						local pos = behind.Position
						pos = Vector3.new(pos.X, hillY, pos.Z)
						local targetPos = targetRoot.Position
						return CFrame.lookAt(pos, Vector3.new(targetPos.X, pos.Y, targetPos.Z))
					end

					function H.isKothRecovering()
						return (S.kothRecoverUntil or 0) > os.clock()
					end

					function H.beginKothRecovery(duration, reason)
						S.kothRecoverUntil = os.clock() + (duration or AUTO_KOTH_RECOVER_SECONDS)
						if reason then
							H.setStatus("Auto KOTH: recovering — " .. reason)
						end
					end

					function H.recoverKothPresence(reason)
						if not S.autoKothRunning then
							return false
						end

						H.beginKothRecovery(AUTO_KOTH_RECOVER_SECONDS, reason or "reclaiming hill")

						local hum = H.getHumanoid()
						local root = H.getCharacterRoot()
						if hum then
							hum.PlatformStand = false
							hum.Sit = false
							hum.AutoRotate = true
						end
						if root then
							root.Anchored = false
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
						end

						H.applyKothMovementLock()
						local hillCFrame = H.getKothHillCFrame()
						if hillCFrame and root then
							root.CFrame = hillCFrame
							H.uprightCharacterRoot(root)
						end

						for _ = 1, 20 do
							if not S.autoKothRunning then
								break
							end

							root = H.getCharacterRoot()
							hillCFrame = H.getKothHillCFrame()
							if root and hillCFrame then
								root.CFrame = hillCFrame
								root.AssemblyLinearVelocity = Vector3.zero
								root.AssemblyAngularVelocity = Vector3.zero
								H.uprightCharacterRoot(root)
							end

							if H.isKothKingLevel(H.getKothSelfLevel()) then
								S.kothRecoverUntil = 0
								return true
							end

							task.wait(0.15)
						end

						return H.isKothKingLevel(H.getKothSelfLevel())
					end

					function H.tryRecoverKothIfNeeded()
						if not S.autoKothRunning or H.isAutoGoalsKickBusy() or S.kothDefendBusy then
							return false
						end

						local root = H.getCharacterRoot()
						local hum = H.getHumanoid()
						if not root or not hum or hum.Health <= 0 then
							return false
						end

						if hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics then
							if not H.isKothRecovering() then
								return H.recoverKothPresence("ragdoll")
							end
							return true
						end

						local state = H.getKOTHState()
						local wasKing = state and state.kingUserId == player.UserId
						local onHill = H.isPositionOnKothHill(root.Position, 10)
						if (wasKing or H.isKothKingLevel(H.getKothSelfLevel())) and not onHill then
							if not H.isKothRecovering() then
								return H.recoverKothPresence("knocked off hill")
							end
							return true
						end

						return false
					end

					function H.ensureKothCharacterListener()
						if S.kothCharacterConn then
							return
						end

						S.kothCharacterConn = player.CharacterAdded:Connect(function()
							if not S.autoKothRunning then
								return
							end

							S.kothSelfLevelCache = 0
							S.kothDefendBusy = false
							task.wait(0.35)
							H.stopKothSoftHold()
							H.startKothSoftHold()
							H.recoverKothPresence("respawn")
						end)
					end

					function H.teardownKothCharacterListener()
						if S.kothCharacterConn then
							pcall(function()
								S.kothCharacterConn:Disconnect()
							end)
							S.kothCharacterConn = nil
						end
					end

					function H.ensureKothRagdollListener()
						if S.kothRagdollListener then
							return true
						end

						local aero = H.getGlobal().Aero
						local constants = H.getSharedConstants()
						if not aero or not aero.Services or not constants or not constants.RemoteEvents then
							return false
						end

						local ragdollService = aero.Services.RagdollService
						local eventName = constants.RemoteEvents.RAGDOLL_CHARACTER or "RagdollCharacter"
						local ragdollRemote = ragdollService and ragdollService[eventName]
						if not ragdollRemote or not ragdollRemote.Connect then
							return false
						end

						S.kothRagdollListener = ragdollRemote:Connect(function(targetPlayer, enabled)
							if targetPlayer ~= player or not S.autoKothRunning then
								return
							end

							if enabled == true then
								H.setStatus("Auto KOTH: ragdolled — recovering soon")
								return
							end

							task.defer(function()
								if S.autoKothRunning then
									H.recoverKothPresence("flung")
								end
							end)
						end)
						return true
					end

					function H.teardownKothRagdollListener()
						if S.kothRagdollListener then
							pcall(function()
								S.kothRagdollListener:Disconnect()
							end)
							S.kothRagdollListener = nil
						end
					end

					function H.faceCharacterTowardPosition(worldPos)
						local root = H.getCharacterRoot()
						if not root or not worldPos then
							return
						end

						local pos = root.Position
						root.CFrame = CFrame.lookAt(pos, Vector3.new(worldPos.X, pos.Y, worldPos.Z))
					end

					function H.faceCharacterTowardContestPlayer(targetPlayer)
						local character = targetPlayer and targetPlayer.Character
						local hrp = character and character:FindFirstChild("HumanoidRootPart")
						if hrp then
							H.faceCharacterTowardPosition(hrp.Position)
						end
					end

					function H.hasKothContestThreat()
						if not S.autoKothRunning then
							return false
						end

						local state = H.getKOTHState()
						if state and state.contested == true then
							return true
						end

						return #H.getKothContestPlayers() > 0
					end

					function H.ensureKothSelfListener()
						if S.kothSelfListener then
							return true
						end

						local kothService = H.getKOTHService()
						local constants = H.getSharedConstants()
						if not kothService or not constants or not constants.RemoteEvents then
							return false
						end

						local selfRemote = kothService[constants.RemoteEvents.KOTH_SELF]
						if not selfRemote or not selfRemote.Connect then
							return false
						end

						S.kothSelfLevelCache = H.getKothSelfLevel()
						S.kothSelfListener = selfRemote:Connect(function(level)
							S.kothSelfLevelCache = level or 0
						end)
						return true
					end

					function H.teardownKothSelfListener()
						if S.kothSelfListener then
							pcall(function()
								S.kothSelfListener:Disconnect()
							end)
							S.kothSelfListener = nil
						end
						S.kothSelfLevelCache = nil
					end

					function H.getKOTHService()
						local aero = H.getGlobal().Aero
						return aero and aero.Services and aero.Services.KOTHService or nil
					end

					function H.getKOTHController()
						local aero = H.getGlobal().Aero
						return aero and aero.Controllers and aero.Controllers.KOTHController or nil
					end

					function H.getKOTHState()
						local controller = H.getKOTHController()
						if controller and type(controller.State) == "table" then
							local live = controller.State
							return {
								enabled = live.active ~= nil or live.kingUserId ~= nil or (controller.Level or 0) > 0,
								kingName = live.kingName,
								kingUserId = live.kingUserId,
								multiplier = live.multiplier or 0,
								contested = live.contested == true,
								active = live.active == true,
								level = controller.Level or 0,
							}
						end

						local service = H.getKOTHService()
						if not service then
							return nil
						end

						local ok, state = pcall(function()
							return service:GetState()
						end)
						if ok and type(state) == "table" then
							state.level = state.level or H.getKothSelfLevel()
							return state
						end
						return nil
					end

					function H.getKothSelfLevel()
						local controller = H.getKOTHController()
						if controller and type(controller.Level) == "number" and controller.Level > 0 then
							return controller.Level
						end

						if type(S.kothSelfLevelCache) == "number" and S.kothSelfLevelCache > 0 then
							return S.kothSelfLevelCache
						end

						local state = H.getKOTHState()
						return state and state.level or 0
					end

					function H.isKothKingLevel(level)
						return (level or H.getKothSelfLevel()) >= AUTO_KOTH_KING_LEVEL
					end

					function H.getKothFloorPart()
						if S.cachedKothFloorPart and S.cachedKothFloorPart.Parent then
							return S.cachedKothFloorPart
						end

						local part = H.getWorkspacePath({ "Scene", "Beach", "KingOfTheHillSandCastle", "Floor2" })
						S.cachedKothFloorPart = part
						return part
					end

					function H.getKothHillTopOffset(floor)
						if not floor then
							return 0
						end

						local cf = floor.CFrame
						local size = floor.Size
						return math.abs(cf.RightVector.Y) * size.X * 0.5
							+ math.abs(cf.UpVector.Y) * size.Y * 0.5
							+ math.abs(cf.LookVector.Y) * size.Z * 0.5
					end

					function H.getKothHillCFrame()
						local floor = H.getKothFloorPart()
						if not floor then
							return nil
						end

						local topOffset = H.getKothHillTopOffset(floor) + AUTO_KOTH_HILL_STAND_OFFSET
						local pos = floor.Position + Vector3.new(0, topOffset, 0)
						local look = floor.CFrame.LookVector
						local flatLook = Vector3.new(look.X, 0, look.Z)
						if flatLook.Magnitude < 0.05 then
							flatLook = Vector3.new(0, 0, -1)
						else
							flatLook = flatLook.Unit
						end

						return CFrame.lookAt(pos, pos + flatLook)
					end

					function H.isPositionOnKothHill(position, padding)
						local floor = H.getKothFloorPart()
						if not floor or not position then
							return false
						end

						padding = padding or AUTO_KOTH_HILL_PADDING
						local localPos = floor.CFrame:PointToObjectSpace(position)
						local half = floor.Size * 0.5 + Vector3.new(padding, 24, padding)
						return math.abs(localPos.X) <= half.X
							and math.abs(localPos.Z) <= half.Z
							and localPos.Y >= -half.Y
							and localPos.Y <= half.Y + 28
					end

					function H.getKothContestPlayers()
						local targets = {}
						for _, otherPlayer in ipairs(Players:GetPlayers()) do
							if otherPlayer ~= player and otherPlayer.Character then
								local hum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
								local hrp = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
								if hum and hum.Health > 0 and hrp and H.isPositionOnKothHill(hrp.Position, 14) then
									table.insert(targets, otherPlayer)
								end
							end
						end
						return targets
					end

					function H.backupKothMovement()
						local hum = H.getHumanoid()
						if not hum or S.kothMovementBackup then
							return
						end

						S.kothMovementBackup = {
							WalkSpeed = hum.WalkSpeed,
							JumpPower = hum.JumpPower,
							AutoRotate = hum.AutoRotate,
						}
					end

					function H.applyKothMovementLock()
						H.backupKothMovement()
						local hum = H.getHumanoid()
						if not hum then
							return
						end

						hum.WalkSpeed = 0
						hum.JumpPower = 0
						hum.AutoRotate = true
					end

					function H.restoreKothMovement()
						local hum = H.getHumanoid()
						local backup = S.kothMovementBackup
						if hum and backup then
							hum.WalkSpeed = backup.WalkSpeed
							hum.JumpPower = backup.JumpPower
							hum.AutoRotate = backup.AutoRotate
						end
						S.kothMovementBackup = nil
					end

					function H.maintainKothHillDuringGoalKick()
						local hillCFrame = H.getKothHillCFrame()
						local root = H.getCharacterRoot()
						if not hillCFrame or not root then
							return false
						end

						local hillPos = hillCFrame.Position
						local look = root.CFrame.LookVector
						local flatLook = Vector3.new(look.X, 0, look.Z)
						if flatLook.Magnitude < 0.05 then
							flatLook = Vector3.new(hillCFrame.LookVector.X, 0, hillCFrame.LookVector.Z)
						end
						if flatLook.Magnitude < 0.05 then
							flatLook = Vector3.new(0, 0, -1)
						else
							flatLook = flatLook.Unit
						end

						root.CFrame = CFrame.lookAt(hillPos, hillPos + flatLook)
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						return true
					end

					function H.maintainKothHillPosition(forceSnap)
						if S.kothDefendBusy then
							return true
						end

						if H.isAutoGoalsKickBusy() then
							return H.maintainKothHillDuringGoalKick()
						end

						local hillCFrame = H.getKothHillCFrame()
						local root = H.getCharacterRoot()
						if not hillCFrame or not root then
							return false
						end

						local dist = (root.Position - hillCFrame.Position).Magnitude
						local selfLevel = H.getKothSelfLevel()
						local state = H.getKOTHState()
						local contested = state and state.contested == true
						local contestPlayers = H.getKothContestPlayers()
						local hasThreat = contested or #contestPlayers > 0
						local onHill = H.isPositionOnKothHill(root.Position, 10)
						local recovering = H.isKothRecovering()

						if H.isKothIdlePeaceful() then
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							if dist > 1.25 then
								root.CFrame = root.CFrame:Lerp(hillCFrame, AUTO_KOTH_HOLD_LERP)
							end
							return true
						end

						if hasThreat and not onHill then
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							return true
						end

						if recovering and not hasThreat then
							root.CFrame = hillCFrame
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							H.uprightCharacterRoot(root)
							return true
						end

						if not onHill and not hasThreat then
							root.CFrame = hillCFrame
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							H.uprightCharacterRoot(root)
							return true
						end

						if hasThreat then
							local hum = H.getHumanoid()
							if hum then
								hum.AutoRotate = true
							end
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							local target = H.getPriorityKothContestPlayer()
							if target then
								H.faceCharacterTowardContestPlayer(target)
							end
							return true
						end

						if not H.isKothKingLevel(selfLevel) or dist > AUTO_KOTH_SNAP_DISTANCE then
							root.CFrame = hillCFrame
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							H.uprightCharacterRoot(root)
							return true
						end

						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						if dist > 1.25 then
							root.CFrame = root.CFrame:Lerp(hillCFrame, AUTO_KOTH_HOLD_LERP)
						end

						return true
					end

					function H.stopKothSoftHold()
						if S.autoKothHoldConn then
							pcall(function()
								S.autoKothHoldConn:Disconnect()
							end)
							S.autoKothHoldConn = nil
						end
						H.restoreKothMovement()
					end

					function H.startKothSoftHold()
						if S.autoKothHoldConn then
							return
						end

						H.applyKothMovementLock()
						S.autoKothHoldConn = trackExonHubConnection(RunService.Heartbeat:Connect(function(dt)
							if not S.autoKothRunning then
								H.stopKothSoftHold()
								return
							end
							if H.isAutoGoalsKickBusy() then
								H.maintainKothHillDuringGoalKick()
								return
							end
							if S.kothDefendBusy then
								local root = H.getCharacterRoot()
								if root then
									root.AssemblyLinearVelocity = Vector3.zero
									root.AssemblyAngularVelocity = Vector3.zero
								end
								if S.kothDefendBusy then
									local target = H.getPriorityKothContestPlayer()
									if target then
										H.faceCharacterTowardContestPlayer(target)
									end
								end
								return
							end

							local hum = H.getHumanoid()
							if not hum or hum.Health <= 0 then
								return
							end

							H.maintainKothHillPosition(false)

							if H.isKothIdlePeaceful() then
								local root = H.getCharacterRoot()
								local hillCFrame = H.getKothHillCFrame()
								if root and hillCFrame then
									H.applyKothIdleSpin(root, hillCFrame, dt)
								end
							end
						end))
					end

					function H.getMeleeHitboxModule()
						if C.meleeHitboxModule then
							return C.meleeHitboxModule
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local hitboxScript = sharedFolder and sharedFolder:FindFirstChild("MeleeHitbox")
						if not hitboxScript then
							return nil
						end

						local ok, mod = pcall(require, hitboxScript)
						if ok and mod then
							C.meleeHitboxModule = mod
							return mod
						end
						return nil
					end

					function H.fireKothContestMeleeHits(mc)
						if not S.autoKothRunning then
							return
						end

						local root = H.getCharacterRoot()
						local origin = root and root.Position
						if not origin then
							return
						end

						local hitThisSwing = mc and mc.HitThisSwing or nil

						local function tryHitContestPlayer(targetPlayer, hitPart)
							if not hitPart or not hitPart.Parent then
								return
							end
							if hitThisSwing and hitThisSwing[targetPlayer] then
								return
							end
							if not H.isPositionOnKothHill(hitPart.Position, 16) then
								return
							end
							if (hitPart.Position - origin).Magnitude > KOTH_HITBOX_RADIUS then
								return
							end
							if hitThisSwing then
								hitThisSwing[targetPlayer] = true
							end
							H.fireMeleeHitOnPart(hitPart)
						end

						for _, otherPlayer in H.getKothContestPlayers() do
							local character = otherPlayer.Character
							if character then
								for _, hitPart in ipairs(H.getKothContestHitParts(character)) do
									tryHitContestPlayer(otherPlayer, hitPart)
								end
							end
						end
					end

					function H.teardownKothMeleeHitboxBoost()
						local hitbox = C.meleeHitboxModule
						if hitbox then
							if hitbox.__exonHubComputeWeaponBox then
								hitbox.ComputeWeaponBox = hitbox.__exonHubComputeWeaponBox
								hitbox.__exonHubComputeWeaponBox = nil
							end
							if hitbox.__exonHubWeaponReach then
								hitbox.WeaponReach = hitbox.__exonHubWeaponReach
								hitbox.__exonHubWeaponReach = nil
							end
							hitbox.HITBOX_PADDING = 1.3
							hitbox.HITBOX_MIN_SIZE = 2
						end

						local mc = H.getMeleeController()
						if mc and mc.__exonHubKothHeartbeatPatched and mc.__exonHubOriginalHeartbeat then
							mc.OnHeartbeat = mc.__exonHubOriginalHeartbeat
							mc.__exonHubKothHeartbeatPatched = nil
							mc.__exonHubOriginalHeartbeat = nil
						end

						S.kothMeleeHitboxActive = false
					end

					function H.ensureKothMeleeHitboxBoost()
						if S.kothMeleeHitboxActive then
							return true
						end

						local hitbox = H.getMeleeHitboxModule()
						if not hitbox then
							return false
						end

						hitbox.HITBOX_PADDING = KOTH_HITBOX_PADDING
						hitbox.HITBOX_MIN_SIZE = KOTH_HITBOX_MIN_SIZE

						if not hitbox.__exonHubComputeWeaponBox then
							hitbox.__exonHubComputeWeaponBox = hitbox.ComputeWeaponBox
							hitbox.ComputeWeaponBox = function(weaponRef)
								local cf, size = hitbox.__exonHubComputeWeaponBox(weaponRef)
								local charRoot = H.getCharacterRoot()
								if not cf and charRoot then
									cf = charRoot.CFrame
									size = Vector3.new(KOTH_HITBOX_MIN_SIZE, KOTH_HITBOX_MIN_SIZE, KOTH_HITBOX_MIN_SIZE)
								end
								if not cf then
									return nil
								end

								size = Vector3.new(
									math.max(size.X * KOTH_HITBOX_SCALE, KOTH_HITBOX_MIN_SIZE),
									math.max(size.Y * KOTH_HITBOX_SCALE, KOTH_HITBOX_MIN_SIZE),
									math.max(size.Z * KOTH_HITBOX_SCALE, KOTH_HITBOX_MIN_SIZE)
								)
								size = H.clampKothHitboxSize(size)
								local forwardExtend = math.min(KOTH_HITBOX_FORWARD_EXTEND, 80)
								cf = cf * CFrame.new(0, 0, -forwardExtend * 0.5)
								size = H.clampKothHitboxSize(size + Vector3.new(0, 0, forwardExtend))
								return cf, size
							end
						end

						if not hitbox.__exonHubWeaponReach then
							hitbox.__exonHubWeaponReach = hitbox.WeaponReach
							hitbox.WeaponReach = function(weaponRef, targetPos)
								local reach = hitbox.__exonHubWeaponReach(weaponRef, targetPos)
								if reach then
									return math.max(reach * KOTH_HITBOX_SCALE, KOTH_HITBOX_RADIUS)
								end
								return KOTH_HITBOX_RADIUS
							end
						end

						local mc = H.getMeleeController()
						if mc and not mc.__exonHubKothHeartbeatPatched then
							mc.__exonHubKothHeartbeatPatched = true
							mc.__exonHubOriginalHeartbeat = mc.OnHeartbeat
							local originalHeartbeat = mc.OnHeartbeat
							mc.OnHeartbeat = function(self, ...)
								originalHeartbeat(self, ...)
								if S.autoKothRunning and not H.isAutoGoalsKickBusy() and self.Swinging then
									if H.hasKothContestThreat() then
										H.fireKothContestMeleeHits(self)
									end
								end
							end
						end

						S.kothMeleeHitboxActive = true
						return true
					end

					function H.kothDefendSwingAt(targetPlayer)
						if not S.autoKothRunning then
							return false
						end

						local targets = {}
						if targetPlayer then
							table.insert(targets, targetPlayer)
						else
							targets = H.getKothContestPlayers()
						end
						if #targets == 0 then
							return false
						end

						H.ensureKothMeleeHitboxBoost()
						if targetPlayer then
							H.faceCharacterTowardContestPlayer(targetPlayer)
						else
							local priority = H.getPriorityKothContestPlayer()
							if priority then
								H.faceCharacterTowardContestPlayer(priority)
							end
						end

						local pc = H.getPlayerController()
						local mc = H.getMeleeController()
						H.ensureWeaponEquipped(pc)

						if mc and mc.OnSwingStart then
							pcall(function()
								mc:OnSwingStart()
							end)
						end

						for _, otherPlayer in ipairs(targets) do
							local character = otherPlayer.Character
							if character then
								for _, hitPart in ipairs(H.getKothContestHitParts(character)) do
									H.fireMeleeHitOnPart(hitPart)
								end
							end
						end

						pcall(function()
							if pc and pc.OnWeaponActivated then
								pc:OnWeaponActivated(true)
							else
								H.backgroundTrainSwing()
							end
						end)

						if mc and mc.OnSwingEnd then
							pcall(function()
								mc:OnSwingEnd()
							end)
						end

						return true
					end

					function H.kothBlitzDefend(targetPlayer, returnToCenter, swingCount)
						if not S.autoKothRunning then
							return false
						end

						if not S.kothDefendBusy then
							S.kothDefendBusy = true
						end

						targetPlayer = targetPlayer or H.getPriorityKothContestPlayer()
						if not targetPlayer then
							if returnToCenter ~= false then
								S.kothDefendBusy = false
							end
							return false
						end

						local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
						local root = H.getCharacterRoot()
						local hillCFrame = H.getKothHillCFrame()
						if not targetRoot or not root or not hillCFrame then
							if returnToCenter ~= false then
								S.kothDefendBusy = false
							end
							return false
						end

						H.setStatus("Auto KOTH: blitz " .. targetPlayer.Name)

						local behindCFrame = H.getKothBehindCFrame(targetRoot)
						if behindCFrame and H.isPositionOnKothHill(behindCFrame.Position, 18) then
							root.CFrame = behindCFrame
						else
							H.faceCharacterTowardContestPlayer(targetPlayer)
						end
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero

						local swings = swingCount or AUTO_KOTH_BLITZ_SWINGS
						for _ = 1, swings do
							if not S.autoKothRunning then
								break
							end
							H.kothDefendSwingAt(targetPlayer)
							task.wait(0.05)
						end

						if returnToCenter ~= false then
							root.CFrame = hillCFrame
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							H.uprightCharacterRoot(root)
							S.kothDefendBusy = false
							S.autoKothLastSwingAt = os.clock()
						end
						return true
					end

					function H.kothClearHillContestants()
						if not S.autoKothRunning or S.kothDefendBusy then
							return false
						end

						local ordered = H.getOrderedKothContestPlayers()
						if #ordered == 0 then
							return false
						end

						S.kothDefendBusy = true
						H.setStatus("Auto KOTH: clearing " .. #ordered .. " from hill")

						for _, targetPlayer in ipairs(ordered) do
							if not S.autoKothRunning then
								break
							end

							local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
							if hrp and H.isPositionOnKothHill(hrp.Position, 14) then
								H.kothBlitzDefend(targetPlayer, false, AUTO_KOTH_MULTI_BLITZ_SWINGS)
								task.wait(0.04)
							end
						end

						local hillCFrame = H.getKothHillCFrame()
						local root = H.getCharacterRoot()
						if hillCFrame and root then
							root.CFrame = hillCFrame
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							H.uprightCharacterRoot(root)
						end

						S.kothDefendBusy = false
						S.autoKothLastSwingAt = os.clock()
						return true
					end

					function H.kothDefendSwing()
						local contestPlayers = H.getKothContestPlayers()
						if #contestPlayers > 1 then
							return H.kothClearHillContestants()
						end
						return H.kothBlitzDefend(H.getPriorityKothContestPlayer())
					end

					function H.getKothDefendSwingInterval(contested, contestCount)
						if contested then
							return AUTO_KOTH_CONTESTED_SWING_INTERVAL
						end
						if contestCount > 0 then
							return AUTO_KOTH_DEFEND_SWING_INTERVAL
						end
						return AUTO_KOTH_SWING_INTERVAL
					end

					function H.runAutoKothCycle()
						H.startKothSoftHold()
						H.ensureKothSelfListener()
						H.ensureKothCharacterListener()
						H.ensureKothRagdollListener()

						while S.autoKothRunning do
							local hum = H.getHumanoid()
							if not hum or hum.Health <= 0 then
								H.setStatus("Auto KOTH: waiting for respawn")
								task.wait(0.5)
								continue
							end

							H.tryRecoverKothIfNeeded()

							local state = H.getKOTHState()
							if not state or state.enabled == false then
								H.setStatus("Auto KOTH: event not active")
								task.wait(2)
								continue
							end

							if state.active ~= true then
								H.setStatus("Auto KOTH: need 2+ players online")
								task.wait(2)
								continue
							end

							if not H.maintainKothHillPosition(false) then
								H.setStatus("Auto KOTH: hill not found")
								task.wait(2)
								continue
							end

							H.ensureKothMeleeHitboxBoost()

							local selfLevel = H.getKothSelfLevel()
							local isKing = state.kingUserId == player.UserId
							local contested = state.contested == true
							local contestPlayers = H.getKothContestPlayers()

							if H.isKothRecovering() then
								H.setStatus("Auto KOTH: reclaiming hill (KOTHSelf sync)")
							elseif #contestPlayers > 0 and not H.isAutoGoalsKickBusy() then
								local swingInterval = H.getKothDefendSwingInterval(contested, #contestPlayers)
								if os.clock() - (S.autoKothLastSwingAt or 0) >= swingInterval then
									if not H.isKothKingLevel(selfLevel) then
										H.setStatus("Auto KOTH: clearing hill before claim")
									elseif #contestPlayers > 1 then
										H.setStatus("Auto KOTH: clearing " .. #contestPlayers .. " contesters")
									else
										H.setStatus("Auto KOTH: contested — blitz defend")
									end
									H.kothDefendSwing()
									S.autoKothLastSwingAt = os.clock()
								end
							elseif contested and not H.isAutoGoalsKickBusy() then
								H.setStatus("Auto KOTH: contested — watching hill")
							elseif not H.isKothKingLevel(selfLevel) then
								H.setStatus("Auto KOTH: waiting for KOTHSelf level 2")
							elseif isKing and not contested and #contestPlayers == 0 then
								if H.isAutoGoalsKickBusy() then
									H.setStatus("Auto KOTH: KING — scoring goal")
								else
									H.setStatus(
										("Auto KOTH: KING x%d — %d shells / 5s"):format(
											state.multiplier or 0,
											(state.multiplier or 0) * 5
										)
									)
								end
							elseif not state.kingUserId then
								H.setStatus("Auto KOTH: claiming crown (alone on hill)")
							else
								H.setStatus("Auto KOTH: holding Floor2")
							end

							task.wait(AUTO_KOTH_POLL)
						end
					end

					function H.stopAutoKothLoop()
						S.autoKothRunning = false
						S.autoKothLastSwingAt = 0
						S.kothDefendBusy = false
						S.kothRecoverUntil = 0
						S.kothIdleSpinAngle = 0
						H.stopKothSoftHold()
						H.teardownKothSelfListener()
						H.teardownKothCharacterListener()
						H.teardownKothRagdollListener()
						H.teardownKothMeleeHitboxBoost()
					end

					function H.startAutoKothLoop()
						if S.autoKothLoopActive then
							return
						end
						S.autoKothLoopActive = true

						task.spawn(function()
							H.runAutoKothCycle()
							S.autoKothLoopActive = false
						end)
					end

					function H.runAutoKillCycle()
						while S.autoKillRunning do
							local hum = H.getHumanoid()
							if not hum or hum.Health <= 0 then
								H.setStatus("Auto kill: waiting for respawn")
								task.wait(1)
							else
								local targets = H.getKillablePlayers()
								if #targets == 0 then
									H.setStatus("Auto kill: no targets near GroundPart")
									task.wait(AUTO_KILL_POLL)
								else
									for _, targetPlayer in ipairs(targets) do
										if not S.autoKillRunning then
											break
										end
										if not H.isPlayerInPvpGroundArea(targetPlayer) then
											continue
										end

										local character = targetPlayer.Character
										local targetHum = character and character:FindFirstChildOfClass("Humanoid")
										if character and targetHum and targetHum.Health > 0 then
											H.setStatus("Auto kill: " .. targetPlayer.Name)
											H.attackPlayerCharacter(character)
										end
										task.wait(AUTO_KILL_POLL)
									end
								end
							end
						end
					end

					function H.stopAutoKillLoop()
						S.autoKillRunning = false
						H.cancelAutoKillFollow()
						local melee = H.getMeleeController()
						if melee and melee.OnSwingEnd then
							pcall(function()
								melee:OnSwingEnd()
							end)
						end
					end

					function H.startAutoKillLoop()
						if S.autoKillLoopActive then
							return
						end
						S.autoKillLoopActive = true

						task.spawn(function()
							H.runAutoKillCycle()
							S.autoKillLoopActive = false
						end)
					end

					function H.getAntiAfkClickPosition()
						local cam = workspace.CurrentCamera
						if cam then
							local viewport = cam.ViewportSize
							if viewport.X > 0 and viewport.Y > 0 then
								return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
							end
						end

						local mouseLocation = UserInputService:GetMouseLocation()
						if mouseLocation.X > 0 or mouseLocation.Y > 0 then
							return mouseLocation
						end

						return Vector2.new(1, 1)
					end

					function H.getAntiAfkCameraCFrame()
						local cam = workspace.CurrentCamera
						return cam and cam.CFrame or CFrame.new()
					end

					function H.runAntiAfkVirtualUser(clickPos, camCf)
						pcall(function()
							if VirtualUser.CaptureFocus then
								VirtualUser:CaptureFocus()
							end
						end)
						pcall(function()
							if VirtualUser.CaptureController then
								VirtualUser:CaptureController()
							end
						end)

						local okClick = pcall(function()
							VirtualUser:ClickButton2(clickPos)
						end)
						if not okClick then
							pcall(function()
								VirtualUser:Button2Down(clickPos, camCf)
								VirtualUser:Button2Up(clickPos, camCf)
							end)
						end

						pcall(function()
							VirtualUser:Button1Down(clickPos, camCf)
							VirtualUser:Button1Up(clickPos, camCf)
						end)
					end

					function H.runAntiAfkVirtualInput(clickPos)
						pcall(function()
							VirtualInputManager:SendMouseMoveEvent(clickPos.X + 1, clickPos.Y, game)
							VirtualInputManager:SendMouseMoveEvent(clickPos.X, clickPos.Y, game)
						end)

						pcall(function()
							VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 1, true, game, 1)
							VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 1, false, game, 1)
						end)

						pcall(function()
							VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
							VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
						end)
					end

					-- Fast path for Player.Idled (must finish immediately before kick)
					function H.cancelIdleKickFast()
						local clickPos = H.getAntiAfkClickPosition()
						local camCf = H.getAntiAfkCameraCFrame()
						H.runAntiAfkVirtualUser(clickPos, camCf)
						H.runAntiAfkVirtualInput(clickPos)
					end

					-- Backup pulse rotates methods so at least one path works per executor
					function H.nudgeAntiAfkInput()
						local clickPos = H.getAntiAfkClickPosition()
						local camCf = H.getAntiAfkCameraCFrame()
						S.antiAfkPulseIndex = ((S.antiAfkPulseIndex or 0) % 3) + 1

						if S.antiAfkPulseIndex == 1 then
							H.runAntiAfkVirtualUser(clickPos, camCf)
						elseif S.antiAfkPulseIndex == 2 then
							H.runAntiAfkVirtualInput(clickPos)
						else
							H.runAntiAfkVirtualUser(clickPos, camCf)
							H.runAntiAfkVirtualInput(clickPos)
						end
					end

					function H.connectAntiAfkIdled()
						if S.antiAfkIdledConnection then
							pcall(function()
								S.antiAfkIdledConnection:Disconnect()
							end)
							S.antiAfkIdledConnection = nil
						end

						S.antiAfkIdledConnection = player.Idled:Connect(function()
							if not S.antiAfkRunning then
								return
							end
							task.spawn(function()
								pcall(H.cancelIdleKickFast)
							end)
						end)
					end

					function H.enableAntiAfk()
						H.connectAntiAfkIdled()

						if S.antiAfkLoopActive then
							return
						end

						S.antiAfkLoopActive = true
						S.antiAfkSessionId = S.antiAfkSessionId + 1
						local sessionId = S.antiAfkSessionId

						task.spawn(function()
							-- Immediate pulse on enable, then periodic backup before the 20m kick timer.
							while S.antiAfkRunning and sessionId == S.antiAfkSessionId do
								pcall(H.nudgeAntiAfkInput)
								task.wait(ANTI_AFK_BACKUP_INTERVAL)
							end
							if sessionId == S.antiAfkSessionId then
								S.antiAfkLoopActive = false
							end
						end)
					end

					function H.disableAntiAfk()
						S.antiAfkSessionId = S.antiAfkSessionId + 1
						S.antiAfkLoopActive = false

						if S.antiAfkIdledConnection then
							pcall(function()
								S.antiAfkIdledConnection:Disconnect()
							end)
							S.antiAfkIdledConnection = nil
						end
					end

					local STREAMER_MODE_NAME = "Exon Hub"

					function H.getStreamerNameplateLabel()
						local character = player.Character
						if not character then
							return nil
						end
						local head = character:FindFirstChild("Head")
						if not head then
							return nil
						end
						local nameplate = head:FindFirstChild("PlayerNameplate")
						if not nameplate then
							return nil
						end
						local frame = nameplate:FindFirstChild("Frame")
						if not frame then
							return nil
						end
						local label = frame:FindFirstChild("PlayerName")
						if label and (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) then
							return label
						end
						return nil
					end

					function H.getStreamerPortraitImages()
						local hud = playerGui:FindFirstChild("HUD")
						if not hud then
							return nil, nil
						end
						local leftHud = hud:FindFirstChild("LeftHUD")
						local frame = leftHud and leftHud:FindFirstChild("Frame")
						local portraitFg = frame and frame:FindFirstChild("PortraitFG")
						if not portraitFg then
							return nil, nil
						end
						local portraitImage = portraitFg:FindFirstChild("PortraitImage")
						local portraitBg = portraitFg:FindFirstChild("PortraitBG")
						local imageOk = portraitImage and portraitImage:IsA("ImageLabel")
						local bgOk = portraitBg and portraitBg:IsA("ImageLabel")
						return imageOk and portraitImage or nil, bgOk and portraitBg or nil
					end

					function H.captureStreamerModeBackup()
						if S.streamerModeBackup then
							return
						end

						local backup = {
							displayName = player.DisplayName,
							nameplateText = nil,
							portraitImage = nil,
							portraitBg = nil,
						}

						local nameplate = H.getStreamerNameplateLabel()
						if nameplate then
							backup.nameplateText = nameplate.Text
						end

						local portraitImage, portraitBg = H.getStreamerPortraitImages()
						if portraitImage then
							backup.portraitImage = portraitImage.Image
						end
						if portraitBg then
							backup.portraitBg = portraitBg.Image
						end

						S.streamerModeBackup = backup
					end

					function H.applyStreamerModeVisuals()
						pcall(function()
							player.DisplayName = STREAMER_MODE_NAME
						end)

						local nameplate = H.getStreamerNameplateLabel()
						if nameplate then
							nameplate.Text = STREAMER_MODE_NAME
						end

						local portraitImage, portraitBg = H.getStreamerPortraitImages()
						if portraitImage then
							portraitImage.Image = EXONHUB_ICON_ASSET
						end
						if portraitBg then
							portraitBg.Image = EXONHUB_ICON_ASSET
						end
					end

					function H.restoreStreamerModeVisuals()
						local backup = S.streamerModeBackup
						if not backup then
							return
						end

						pcall(function()
							player.DisplayName = backup.displayName
						end)

						local nameplate = H.getStreamerNameplateLabel()
						if nameplate and backup.nameplateText ~= nil then
							nameplate.Text = backup.nameplateText
						end

						local portraitImage, portraitBg = H.getStreamerPortraitImages()
						if portraitImage and backup.portraitImage ~= nil then
							portraitImage.Image = backup.portraitImage
						end
						if portraitBg and backup.portraitBg ~= nil then
							portraitBg.Image = backup.portraitBg
						end

						S.streamerModeBackup = nil
					end

					function H.stopStreamerModeLoop()
						S.streamerModeRunning = false
						if S.streamerModeCharacterConn then
							pcall(function()
								S.streamerModeCharacterConn:Disconnect()
							end)
							S.streamerModeCharacterConn = nil
						end
					end

					function H.startStreamerModeLoop()
						if S.streamerModeLoopActive then
							return
						end
						S.streamerModeLoopActive = true

						if not S.streamerModeCharacterConn then
							S.streamerModeCharacterConn = player.CharacterAdded:Connect(function()
								if S.streamerModeRunning then
									task.wait(0.35)
									H.applyStreamerModeVisuals()
								end
							end)
						end

						task.spawn(function()
							while S.streamerModeRunning do
								H.applyStreamerModeVisuals()
								task.wait(0.35)
							end
							S.streamerModeLoopActive = false
						end)
					end

					function H.getWorkspacePath(pathParts)
						local current = workspace
						for _, name in ipairs(pathParts) do
							current = current and current:FindFirstChild(name)
						end
						return current
					end

					function H.teleportToMiscLocation(location)
						if not location or not location.position then
							return false
						end

						local root = H.getCharacterRoot()
						if not root then
							H.setStatus("TP: no character")
							return false
						end

						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						root.CFrame = CFrame.new(location.position)
						H.setStatus("TP: " .. location.label)
						return true
					end

					function H.getGoldenEggStandCFrame(egg)
						if not egg then
							return nil
						end

						if egg:IsA("BasePart") then
							local top = egg.CFrame:PointToWorldSpace(Vector3.new(0, egg.Size.Y * 0.5, 0))
							return CFrame.new(top + GOLDEN_EGG_TP_OFFSET)
						end

						if egg:IsA("Model") then
							local primary = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
							if primary then
								return H.getGoldenEggStandCFrame(primary)
							end
						end

						return nil
					end

					function H.getGoldenEggInstances()
						local eggs = {}
						local seen = {}

						local function addEgg(instance)
							if not instance or seen[instance] then
								return
							end
							if not (instance:IsA("BasePart") or instance:IsA("Model")) then
								return
							end
							if not instance:IsDescendantOf(workspace) then
								return
							end
							seen[instance] = true
							table.insert(eggs, instance)
						end

						for _, desc in ipairs(workspace:GetDescendants()) do
							if desc.Name == GOLDEN_EGG_NAME and (desc:IsA("BasePart") or desc:IsA("Model")) then
								if desc:IsA("Model") then
									addEgg(desc)
								elseif desc:IsA("BasePart") then
									local parentModel = desc:FindFirstAncestorOfClass("Model")
									if parentModel and parentModel.Name == GOLDEN_EGG_NAME then
										addEgg(parentModel)
									else
										addEgg(desc)
									end
								end
							end
						end

						local function getEggPosition(egg)
							if egg:IsA("BasePart") then
								return egg.Position
							end
							if egg:IsA("Model") then
								local ok, pivot = pcall(function()
									return egg:GetPivot().Position
								end)
								if ok then
									return pivot
								end
								local primary = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart", true)
								if primary then
									return primary.Position
								end
							end
							return Vector3.zero
						end

						table.sort(eggs, function(a, b)
							local aPos = getEggPosition(a)
							local bPos = getEggPosition(b)
							return aPos.X < bPos.X or (aPos.X == bPos.X and aPos.Z < bPos.Z)
						end)

						return eggs
					end

					function H.teleportToNextGoldenEgg()
						local eggs = H.getGoldenEggInstances()
						if #eggs == 0 then
							H.setStatus("Golden Egg: none in workspace")
							return false
						end

						if not S.goldenEggTpInitialized or S.goldenEggTpCount ~= #eggs then
							S.goldenEggTpIndex = math.random(1, #eggs)
							S.goldenEggTpInitialized = true
							S.goldenEggTpCount = #eggs
						else
							S.goldenEggTpIndex = (S.goldenEggTpIndex % #eggs) + 1
						end

						local egg = eggs[S.goldenEggTpIndex]
						if not egg or not egg.Parent then
							S.goldenEggTpInitialized = false
							S.goldenEggTpCount = 0
							return H.teleportToNextGoldenEgg()
						end

						local standCFrame = H.getGoldenEggStandCFrame(egg)
						if not standCFrame then
							H.setStatus("Golden Egg: no position")
							return false
						end

						local root = H.getCharacterRoot()
						if not root then
							H.setStatus("Golden Egg: no character")
							return false
						end

						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						root.CFrame = standCFrame

						local label = #eggs > 1
							and string.format("Golden Egg %d/%d", S.goldenEggTpIndex, #eggs)
							or "Golden Egg"
						H.setStatus("TP: " .. label)
						return true
					end

					function H.buildGoldenEggTeleportSection(tab)
						local section = H.createStaticBoxSection(tab, "Golden Egg", "solar:egg-bold")

						section:Button({
							Title = "Teleport to Golden Egg",
							Desc = "Scans workspace for Egg, TP to one, then cycles through the rest",
							Callback = function()
								H.teleportToNextGoldenEgg()
							end,
						})

						H.finalizeStaticSection(section)
					end

					function H.buildMiscTeleportSection(tab)
						local section = H.createStaticBoxSection(tab, "Teleports", "solar:map-point-bold")

						for _, location in ipairs(MISC_TP_LOCATIONS) do
							section:Button({
								Title = location.label,
								Callback = function()
									H.teleportToMiscLocation(location)
								end,
							})
						end

						H.finalizeStaticSection(section)
					end

					function H.getBeachBallsFolder()
						return H.getWorkspacePath(BEACH_BALLS_PATH)
					end

					function H.getBeachGoalsFolder()
						return H.getWorkspacePath(BEACH_GOALS_PATH)
					end


					function H.collectBeachGoalTargets()
						local byName = H.collectBeachGoalsByName()
						local targets = {}
						for _, goalPart in pairs(byName) do
							table.insert(targets, goalPart)
						end
						return targets
					end

					function H.collectBeachGoalsByName()
						local folder = H.getBeachGoalsFolder()
						if not folder then
							return {}
						end

						local byName = {}
						for _, goalModel in ipairs(folder:GetChildren()) do
							local fx = goalModel:FindFirstChild("GoalFX")
							if fx and fx:IsA("BasePart") then
								byName[goalModel.Name] = fx
							end
						end
						return byName
					end

					function H.getBeachBalls()
						local folder = H.getBeachBallsFolder()
						if not folder then
							return {}
						end

						local balls = {}
						for _, child in ipairs(folder:GetChildren()) do
							if child:IsA("BasePart") or child:IsA("Model") then
								table.insert(balls, child)
							end
						end
						return balls
					end

					function H.getBeachBallParts(ball)
						local parts = {}
						if not ball then
							return parts
						end

						if ball:IsA("BasePart") then
							table.insert(parts, ball)
						end

						for _, desc in ipairs(ball:GetDescendants()) do
							if desc:IsA("BasePart") then
								table.insert(parts, desc)
							end
						end

						return parts
					end

					function H.getBeachBallPrimaryPart(ball)
						if not ball then
							return nil
						end
						if ball:IsA("BasePart") then
							return ball
						end
						if ball.PrimaryPart then
							return ball.PrimaryPart
						end
						return ball:FindFirstChildWhichIsA("BasePart", true)
					end

					function H.ensureAutoGoalsBallCollisionSetup()
						if S.autoGoalsCollisionReady then
							return true
						end
						if S.autoGoalsCollisionUnsupported then
							return false
						end

						-- RegisterCollisionGroup / NetworkOwner are often plugin/server-only.
						-- Try once; on capability errors, never retry (avoids console spam + UI freeze).
						local registerOk = pcall(function()
							game:GetService("PhysicsService"):RegisterCollisionGroup(AUTO_GOALS_BALL_COLLISION_GROUP)
						end)

						local ok = registerOk and pcall(function()
							local physics = game:GetService("PhysicsService")
							for _, info in ipairs(physics:GetRegisteredCollisionGroups()) do
								if info.name ~= AUTO_GOALS_BALL_COLLISION_GROUP then
									physics:CollisionGroupSetCollidable(AUTO_GOALS_BALL_COLLISION_GROUP, info.name, false)
								end
							end
						end)

						if ok then
							S.autoGoalsCollisionReady = true
							return true
						end

						S.autoGoalsCollisionUnsupported = true
						warn("[ExonHub] Auto Goals collision groups unavailable on this client — using soft no-collide fallback")
						return false
					end

					function H.backupBeachBallCollision(ball)
						if not ball then
							return
						end

						local name = ball.Name
						if S.autoGoalsBallCollisionBackup[name] and S.autoGoalsBallCollisionBackup[name].instance == ball then
							return
						end

						local primary = H.getBeachBallPrimaryPart(ball)
						local collisionGroup = "Default"
						pcall(function()
							if primary then
								collisionGroup = primary.CollisionGroup or "Default"
							end
						end)

						S.autoGoalsBallCollisionBackup[name] = {
							instance = ball,
							collisionGroup = collisionGroup,
							canCollide = primary and primary.CanCollide,
							canTouch = primary and primary.CanTouch,
							massless = primary and primary.Massless,
							anchored = primary and primary.Anchored,
						}
					end

					function H.applyBeachBallSoftNoCollision(ball)
						if not ball or not ball.Parent then
							return false
						end

						H.backupBeachBallCollision(ball)
						for _, part in ipairs(H.getBeachBallParts(ball)) do
							pcall(function()
								part.CanCollide = false
								part.Massless = true
							end)
						end
						return true
					end

					function H.restoreSingleBeachBallCollision(ball)
						if not ball then
							return
						end

						local backup = S.autoGoalsBallCollisionBackup[ball.Name]
						if not backup or backup.instance ~= ball then
							return
						end

						for _, part in ipairs(H.getBeachBallParts(ball)) do
							pcall(function()
								if backup.collisionGroup then
									part.CollisionGroup = backup.collisionGroup
								end
								if backup.canCollide ~= nil then
									part.CanCollide = backup.canCollide
								end
								if backup.canTouch ~= nil then
									part.CanTouch = backup.canTouch
								end
								if backup.massless ~= nil then
									part.Massless = backup.massless
								end
								if backup.anchored ~= nil then
									part.Anchored = backup.anchored
								end
							end)
						end
					end

					function H.enforceBeachBallPhantomPhysics(ball)
						if not ball or not ball.Parent then
							return false
						end

						H.backupBeachBallCollision(ball)

						local parts = H.getBeachBallParts(ball)
						if #parts == 0 then
							return false
						end

						local useCollisionGroup = H.ensureAutoGoalsBallCollisionSetup()
						for _, part in ipairs(parts) do
							pcall(function()
								part.Anchored = true
								part.CanCollide = false
								part.CanTouch = false
								part.Massless = true
								if useCollisionGroup then
									part.CollisionGroup = AUTO_GOALS_BALL_COLLISION_GROUP
								end
								part.AssemblyAngularVelocity = Vector3.zero
								part.AssemblyLinearVelocity = Vector3.zero
							end)
						end

						return true
					end

					function H.releaseBeachBallForKick(ball)
						local useCollisionGroup = H.ensureAutoGoalsBallCollisionSetup()
						local parts = H.getBeachBallParts(ball)
						for _, part in ipairs(parts) do
							pcall(function()
								part.Anchored = false
								part.CanCollide = false
								part.CanTouch = false
								part.Massless = true
								if useCollisionGroup then
									part.CollisionGroup = AUTO_GOALS_BALL_COLLISION_GROUP
								end
							end)
						end
					end

					function H.beginBeachBallPhantomGuard(ball)
						H.endBeachBallPhantomGuard()
						S.autoGoalsPhantomBall = ball
						S.autoGoalsPhantomConn = RunService.Heartbeat:Connect(function()
							local activeBall = S.autoGoalsPhantomBall
							if not S.autoGoalsRunning or not activeBall or not activeBall.Parent then
								return
							end
							H.enforceBeachBallPhantomPhysics(activeBall)
						end)
					end

					function H.endBeachBallPhantomGuard()
						if S.autoGoalsPhantomConn then
							S.autoGoalsPhantomConn:Disconnect()
							S.autoGoalsPhantomConn = nil
						end
						S.autoGoalsPhantomBall = nil
					end

					function H.applyBeachBallNoPlayerCollision(ball)
						return H.applyBeachBallSoftNoCollision(ball)
					end

					function H.applyAutoGoalsBallCollisions(balls)
						for _, ball in ipairs(balls) do
							H.applyBeachBallSoftNoCollision(ball)
						end
					end

					function H.restoreAutoGoalsBallCollisions()
						H.endBeachBallPhantomGuard()
						for _, backup in pairs(S.autoGoalsBallCollisionBackup) do
							local ball = backup.instance
							if ball and ball.Parent then
								local parts = H.getBeachBallParts(ball)
								if #parts == 0 and ball:IsA("BasePart") then
									parts = { ball }
								end
								for _, part in ipairs(parts) do
									pcall(function()
										part.CollisionGroup = backup.collisionGroup or "Default"
										if backup.canCollide ~= nil then
											part.CanCollide = backup.canCollide
										end
										if backup.canTouch ~= nil then
											part.CanTouch = backup.canTouch
										end
										if backup.massless ~= nil then
											part.Massless = backup.massless
										end
										if backup.anchored ~= nil then
											part.Anchored = backup.anchored
										end
									end)
								end
							end
						end
						S.autoGoalsBallCollisionBackup = {}
					end

					function H.teardownAutoGoalsBallCollision()
						H.restoreAutoGoalsBallCollisions()
					end

					function H.getSoccerController()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers then
							return aero.Controllers.SoccerController
						end
						return nil
					end

					function H.getSoccerKickValues()
						local constants = H.getSharedConstants()
						if not constants then
							return 65, 14
						end

						local character = player.Character
						local hum = character and character:FindFirstChildOfClass("Humanoid")
						local scaleObj = hum and hum:FindFirstChild("BodyHeightScale")
						local scale = scaleObj and scaleObj.Value or 1
						return constants:GetSoccerKick(scale)
					end

					function H.getZapClient()
						if C.zapClient then
							return C.zapClient
						end

						local zap = ReplicatedStorage:FindFirstChild("ZapClient")
						if not zap then
							return nil
						end

						local ok, mod = pcall(require, zap)
						if ok and mod then
							C.zapClient = mod
							return mod
						end
						return nil
					end

					function H.horizontalDistance(a, b)
						local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
						return delta.Magnitude, delta
					end

					function H.isBallInSpecificGoal(ball, goalPart, radius)
						if not ball or not goalPart then
							return false
						end

						local primary = H.getBeachBallPrimaryPart(ball) or ball
						local scoreRadius = radius or AUTO_GOALS_SCORE_RADIUS
						local dist = H.horizontalDistance(primary.Position, goalPart.Position)
						if dist <= scoreRadius then
							local yDiff = math.abs(primary.Position.Y - goalPart.Position.Y)
							return yDiff <= 14
						end
						return false
					end

					function H.isBallInGoal(ball, goalParts)
						for _, goalPart in ipairs(goalParts) do
							if H.isBallInSpecificGoal(ball, goalPart) then
								return true
							end
						end
						return false
					end

					function H.cacheBeachBallSpawns(balls)
						for _, ball in ipairs(balls) do
							if ball.Parent and not S.autoGoalsBallSpawns[ball.Name] then
								S.autoGoalsBallSpawns[ball.Name] = ball.Position
							end
						end
					end

					function H.isBeachBallAtSpawn(ball)
						local spawn = S.autoGoalsBallSpawns[ball.Name]
						if not spawn then
							return true
						end

						local dist = H.horizontalDistance(ball.Position, spawn)
						return dist <= AUTO_GOALS_SPAWN_RADIUS
					end

					function H.isBeachBallScoredWaiting(ball, goals)
						local name = ball.Name
						if S.autoGoalsScoredBalls[name] then
							if H.isBeachBallAtSpawn(ball) and not H.isBallInGoal(ball, goals) then
								S.autoGoalsScoredBalls[name] = nil
								S.autoGoalsBallSpawns[name] = ball.Position
								return false
							end
							return true
						end

						return false
					end

					function H.shouldAutoGoalsTargetBall(ball, goals)
						if not ball or not ball.Parent then
							return false
						end
						if H.isBeachBallScoredWaiting(ball, goals) then
							return false
						end
						if S.autoGoalsScoredBalls[ball.Name] then
							return false
						end
						return true
					end

					function H.getFixedBeachGoalForName(ballName, goalsByName, allBalls)
						if ballName == "Ball2" then
							return goalsByName.Goal_1
						end
						if ballName == "Ball1" then
							return goalsByName.Goal_2
						end
						if ballName == "Ball" then
							local goal1 = goalsByName.Goal_1
							local goal2 = goalsByName.Goal_2
							local goalList = {}
							if goal1 then
								table.insert(goalList, goal1)
							end
							if goal2 then
								table.insert(goalList, goal2)
							end
							local goal1Busy = goal1 and H.isGoalOccupiedByBall(goal1, allBalls, goalList)
							local goal2Busy = goal2 and H.isGoalOccupiedByBall(goal2, allBalls, goalList)
							if goal1 and not goal1Busy then
								return goal1
							end
							if goal2 and not goal2Busy then
								return goal2
							end
							return goal1 or goal2
						end
						return goalsByName.Goal_1
					end

					function H.isGoalOccupiedByBall(goalPart, allBalls, goalList)
						if not goalPart or not allBalls then
							return false
						end

						goalList = goalList or { goalPart }
						for _, ball in ipairs(allBalls) do
							if H.isBallInSpecificGoal(ball, goalPart) then
								return true
							end
							if S.autoGoalsScoredBalls[ball.Name] and H.isBallInGoal(ball, goalList) then
								return true
							end
						end
						return false
					end

					function H.shouldSkipBeachBallKick(ball, _goalsByName, _allBalls)
						if not ball then
							return true
						end

						return S.autoGoalsScoredBalls[ball.Name] == true
					end

					function H.getBeachGoalSlotOffset(ballName)
						if ballName == "Ball2" then
							return Vector3.new(-3, 0, 0)
						end
						if ballName == "Ball1" then
							return Vector3.new(0, 0, 0)
						end
						if ballName == "Ball" then
							return Vector3.new(3, 0, 0)
						end
						return Vector3.zero
					end

					function H.getBeachGoalAimPositionForBall(ball, goalPart)
						local base = H.getBeachGoalAimPosition(goalPart)
						if not base or not ball then
							return base
						end

						local offset = H.getBeachGoalSlotOffset(ball.Name)
						return base + offset
					end

					function H.prepareBeachBallForAutoGoal(ball)
						if not ball or not ball.Parent then
							return false
						end

						local primary = H.getBeachBallPrimaryPart(ball)
						local spawn = S.autoGoalsBallSpawns[ball.Name]
						if spawn and primary then
							primary.CFrame = CFrame.new(spawn)
						end

						for _, part in ipairs(H.getBeachBallParts(ball)) do
							part.AssemblyAngularVelocity = Vector3.zero
							part.AssemblyLinearVelocity = Vector3.zero
						end
						return true
					end

					function H.zeroBeachBallVelocity(ball)
						for _, part in ipairs(H.getBeachBallParts(ball)) do
							if part.Parent then
								part.AssemblyAngularVelocity = Vector3.zero
								part.AssemblyLinearVelocity = Vector3.zero
							end
						end
					end

					function H.isBallNearPlayerForKick(ball)
						local root = H.getCharacterRoot()
						if not root or not ball then
							return false
						end

						local dist = H.horizontalDistance(ball.Position, root.Position)
						return dist <= AUTO_GOALS_NEAR_PLAYER_RADIUS
					end

					function H.shouldResetBeachBallForAutoGoal(ball, goals)
						if not ball then
							return false
						end

						if goals and H.isBallInGoal(ball, goals) and not S.autoGoalsScoredBalls[ball.Name] then
							return true
						end

						return not H.isBallNearPlayerForKick(ball)
					end

					function H.fireSoccerKick(ballId)
						if not ballId then
							return false
						end

						local zap = H.getZapClient()
						if not zap or not zap.SoccerKick or not zap.SoccerKick.Fire then
							return false
						end

						local ok = pcall(function()
							zap.SoccerKick.Fire(ballId)
						end)
						H.flushZapClient()
						return ok
					end

					function H.getKickDirectionTowardGoal(ball, goalPart)
						local aimPos = H.getBeachGoalAimPositionForBall(ball, goalPart)
						if not aimPos or not ball then
							return Vector3.new(0, 0, -1)
						end

						local delta = Vector3.new(aimPos.X - ball.Position.X, 0, aimPos.Z - ball.Position.Z)
						if delta.Magnitude < 0.05 then
							local root = H.getCharacterRoot()
							if root then
								local look = root.CFrame.LookVector
								delta = Vector3.new(look.X, 0, look.Z)
							end
						end

						if delta.Magnitude < 0.05 then
							return Vector3.new(0, 0, -1)
						end

						return delta.Unit
					end

					function H.getKothKickSpeedMultiplier(ball, goalPart)
						local aim = H.getBeachGoalAimPositionForBall(ball, goalPart)
						if not aim or not ball then
							return 1.35
						end

						local dist = H.horizontalDistance(ball.Position, aim)
						if dist <= 150 then
							return 1.2
						end

						return math.clamp(1.2 + (dist - 150) / 250, 1.2, 1.65)
					end

					function H.applyBeachBallKickVelocity(ball, goalPart, speedMultiplier)
						local primary = H.getBeachBallPrimaryPart(ball)
						if not primary or not primary.Parent then
							return false
						end

						local kickSpeed, kickLift = H.getSoccerKickValues()
						local direction = H.getKickDirectionTowardGoal(ball, goalPart)
						local speedScale = speedMultiplier or 1
						primary.AssemblyAngularVelocity = Vector3.zero
						primary.AssemblyLinearVelocity = direction * kickSpeed * speedScale + Vector3.new(0, kickLift, 0)
						return true
					end

					function H.trySoccerSwingKick()
						local sc = H.getSoccerController()
						if not sc or not sc.OnLocalSwing then
							return false
						end

						local pc = H.getPlayerController()
						local useSilentTrain = H.shouldClickerUseSilentTrain()
						local swung = false

						pcall(function()
							if useSilentTrain then
								H.ensureWeaponEquipped(pc)
							end
							H.withFishingActivationBypass(function()
								sc:OnLocalSwing()
								swung = true
							end)
						end)

						if useSilentTrain then
							H.ensureWeaponUnequipped(pc)
						end

						return swung
					end

					function H.kickBeachBallAfterTouch(ball, goalPart)
						if not ball or not goalPart then
							return false
						end

						local primary = H.getBeachBallPrimaryPart(ball)
						if not primary then
							return false
						end

						local useKothPath = H.shouldAutoGoalsUseKothTouchPath()
						if useKothPath then
							H.faceCharacterTowardGoal(goalPart)
							task.wait(0.05)
						end

						H.restoreSingleBeachBallCollision(ball)
						H.zeroBeachBallVelocity(ball)
						H.fireTouchPair(H.getCharacterTouchPart(), primary)

						H.trySoccerSwingKick()

						if useKothPath then
							H.applyBeachBallKickVelocity(ball, goalPart, H.getKothKickSpeedMultiplier(ball, goalPart))
						else
							H.applyBeachBallKickVelocity(ball, goalPart)
						end

						local ballId = ball:GetAttribute("SoccerBallId")
						if not ballId and primary ~= ball then
							ballId = primary:GetAttribute("SoccerBallId")
						end
						return H.fireSoccerKick(ballId)
					end

					function H.waitForAutoGoalsServerConfirm(ballName, timeout)
						if not ballName then
							return false
						end

						local deadline = os.clock() + (timeout or AUTO_GOALS_BALL_ATTEMPT_TIMEOUT)
						while S.autoGoalsRunning and os.clock() < deadline do
							if S.autoGoalsScoredBalls[ballName] then
								return true
							end
							task.wait(0.05)
						end

						return S.autoGoalsScoredBalls[ballName] == true
					end

					function H.pickGoalForBeachBall(ball, goalsByName, allBalls)
						return ball and H.getFixedBeachGoalForName(ball.Name, goalsByName, allBalls) or nil
					end

					function H.orderBeachBallsFixed(balls)
						local byName = {}
						for _, ball in ipairs(balls) do
							byName[ball.Name] = ball
						end

						local ordered = {}
						for _, name in ipairs(AUTO_GOALS_BALL_ORDER) do
							local ball = byName[name]
							if ball then
								table.insert(ordered, ball)
							end
						end

						for _, ball in ipairs(balls) do
							if not table.find(ordered, ball) then
								table.insert(ordered, ball)
							end
						end
						return ordered
					end

					function H.collectBeachKickPlan(pending, goalsByName, allBalls)
						local ordered = H.orderBeachBallsFixed(pending)

						for _, ball in ipairs(ordered) do
							if not H.shouldSkipBeachBallKick(ball, goalsByName, allBalls) then
								local goalPart = H.pickGoalForBeachBall(ball, goalsByName, allBalls)
								if goalPart then
									return { { ball = ball, goal = goalPart } }
								end
							end
						end

						return {}
					end

					function H.markAutoGoalsBallScored(ballName)
						if ballName then
							S.autoGoalsScoredBalls[ballName] = true
						end
					end

					function H.getGoalModelNameFromScorePart(scorePart)
						if not scorePart then
							return nil
						end

						local model = scorePart.Parent
						return model and model.Name or nil
					end

					function H.resolveAutoGoalsBallFromGoalScore(scorePart)
						local goalName = H.getGoalModelNameFromScorePart(scorePart)
						local lastBall = S.autoGoalsLastKickBallName
						local lastGoal = S.autoGoalsLastKickGoalName

						if goalName and lastGoal == goalName and lastBall then
							return lastBall
						end

						if goalName == "Goal_2" then
							return "Ball1"
						end

						if goalName == "Goal_1" then
							if lastBall == "Ball2" or lastBall == "Ball" then
								return lastBall
							end
							if not S.autoGoalsScoredBalls["Ball2"] then
								return "Ball2"
							end
							return "Ball"
						end

						return lastBall
					end

					function H.onAutoGoalsServerGoal(scorePart)
						if not S.autoGoalsRunning then
							return
						end

						local ballName = H.resolveAutoGoalsBallFromGoalScore(scorePart)
						if not ballName then
							return
						end

						local now = os.clock()
						if S.autoGoalsLastGoalConfirmBall == ballName and now - (S.autoGoalsLastGoalConfirmAt or 0) < 0.35 then
							return
						end

						S.autoGoalsLastGoalConfirmBall = ballName
						S.autoGoalsLastGoalConfirmAt = now
						H.markAutoGoalsBallScored(ballName)
					end

					function H.ensureAutoGoalsGoalListener()
						if S.autoGoalsGoalListener or S.autoGoalsRawGoalListener then
							return true
						end

						local handler = function(scorePart)
							H.onAutoGoalsServerGoal(scorePart)
						end

						local aero = H.getGlobal().Aero
						if aero and aero.Services and aero.Services.SoccerService then
							local constants = H.getSharedConstants()
							if constants and constants.RemoteEvents then
								local remote = aero.Services.SoccerService[constants.RemoteEvents.SOCCER_GOAL]
								if remote and remote.Connect then
									S.autoGoalsGoalListener = remote:Connect(handler)
								end
							end
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local remoteServices = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						local soccerService = remoteServices and remoteServices:FindFirstChild("SoccerService")
						local rawRemote = soccerService and soccerService:FindFirstChild("SoccerGoal")
						if rawRemote and rawRemote:IsA("RemoteEvent") then
							S.autoGoalsRawGoalListener = rawRemote.OnClientEvent:Connect(handler)
						end

						return S.autoGoalsGoalListener ~= nil or S.autoGoalsRawGoalListener ~= nil
					end

					function H.teardownAutoGoalsGoalListener()
						if S.autoGoalsGoalListener then
							pcall(function()
								S.autoGoalsGoalListener:Disconnect()
							end)
							S.autoGoalsGoalListener = nil
						end
						if S.autoGoalsRawGoalListener then
							pcall(function()
								S.autoGoalsRawGoalListener:Disconnect()
							end)
							S.autoGoalsRawGoalListener = nil
						end
					end

					function H.getBeachGoalAimPosition(goalPart)
						if not goalPart then
							return nil
						end

						local model = goalPart.Parent
						if model then
							local score = model:FindFirstChild("Score")
							if score and score:IsA("BasePart") then
								return score.Position
							end
						end

						return goalPart.Position
					end

					function H.getAutoGoalsMidfieldCFrame(ball)
						local goalsByName = H.collectBeachGoalsByName()
						local goal1Aim = H.getBeachGoalAimPosition(goalsByName.Goal_1)
						if not goal1Aim then
							return nil
						end

						local middle = AUTO_GOALS_MIDFIELD_POSITION
						local lookAt = Vector3.new(goal1Aim.X, middle.Y, goal1Aim.Z)
						return CFrame.new(middle, lookAt)
					end

					function H.getCharacterTouchPart()
						local character = player.Character
						if not character then
							return nil
						end

						return character:FindFirstChild("HumanoidRootPart")
							or character:FindFirstChild("UpperTorso")
							or character:FindFirstChild("Torso")
							or character:FindFirstChildWhichIsA("BasePart")
					end

					function H.fireTouchPair(partA, partB)
						if not partA or not partB or not firetouchinterest then
							return false
						end

						local ok = pcall(function()
							firetouchinterest(partA, partB, 0)
							task.wait()
							firetouchinterest(partA, partB, 1)
						end)
						return ok
					end

					function H.getUndergroundPosition(surfacePos, depth)
						depth = depth or AUTO_GOALS_UNDERGROUND_DEPTH
						return Vector3.new(surfacePos.X, surfacePos.Y - depth, surfacePos.Z)
					end

					function H.setBeachBallPosition(ball, targetPos, useSoftCollision)
						if not ball or not targetPos then
							return false
						end

						if useSoftCollision then
							H.applyBeachBallSoftNoCollision(ball)
						end

						local primary = H.getBeachBallPrimaryPart(ball)
						if not primary then
							return false
						end

						primary.CFrame = CFrame.new(targetPos)
						H.zeroBeachBallVelocity(ball)
						return true
					end

					function H.slideBeachBallTo(ball, targetPos, steps, stepWait, useSoftCollision)
						if not ball or not ball.Parent or not targetPos then
							return false
						end

						if not S.autoGoalsRunning then
							return false
						end

						local primary = H.getBeachBallPrimaryPart(ball)
						if not primary then
							return false
						end

						if useSoftCollision then
							H.applyBeachBallSoftNoCollision(ball)
						end

						local start = primary.Position
						steps = math.max(1, steps or 10)
						stepWait = stepWait or 0.03

						for i = 1, steps do
							if not S.autoGoalsRunning then
								return false
							end

							if useSoftCollision then
								H.applyBeachBallSoftNoCollision(ball)
							end

							local alpha = i / steps
							local pos = start:Lerp(targetPos, alpha)
							primary.CFrame = CFrame.new(pos)
							H.zeroBeachBallVelocity(ball)
							task.wait(stepWait)
						end

						return true
					end

					function H.slideBeachBallUpFromUnderground(ball, surfacePos, riseSteps, stepWait, useSoftCollision)
						if not surfacePos then
							return false
						end

						local underPos = H.getUndergroundPosition(surfacePos)
						if not H.setBeachBallPosition(ball, underPos, useSoftCollision) then
							return false
						end

						return H.slideBeachBallTo(
							ball,
							surfacePos,
							riseSteps or AUTO_GOALS_UNDERGROUND_RISE_STEPS,
							stepWait or AUTO_GOALS_UNDERGROUND_STEP_WAIT,
							useSoftCollision
						)
					end

					function H.slideBeachBallUndergroundToGoal(ball, goalPos)
						local primary = H.getBeachBallPrimaryPart(ball)
						if not primary or not goalPos then
							return false
						end

						local buriedY = goalPos.Y - AUTO_GOALS_UNDERGROUND_DEPTH
						local current = primary.Position
						local underCurrent = Vector3.new(current.X, buriedY, current.Z)
						local underGoal = Vector3.new(goalPos.X, buriedY, goalPos.Z)

						if not H.slideBeachBallTo(
							ball,
							underCurrent,
							AUTO_GOALS_UNDERGROUND_DROP_STEPS,
							AUTO_GOALS_UNDERGROUND_STEP_WAIT,
							false
						) then
							return false
						end

						if not H.slideBeachBallTo(
							ball,
							underGoal,
							AUTO_GOALS_UNDERGROUND_TRAVEL_STEPS,
							AUTO_GOALS_UNDERGROUND_STEP_WAIT,
							false
						) then
							return false
						end

						return H.slideBeachBallTo(
							ball,
							goalPos,
							AUTO_GOALS_UNDERGROUND_RISE_STEPS,
							AUTO_GOALS_UNDERGROUND_STEP_WAIT,
							false
						)
					end

					function H.teleportBeachBallTo(ball, targetPos, useSoftCollision)
						if not ball or not ball.Parent or not targetPos then
							return false
						end

						if not S.autoGoalsRunning then
							return false
						end

						return H.setBeachBallPosition(ball, targetPos, useSoftCollision)
					end

					function H.smoothMoveBallTo(ball, targetPos, steps, stepWait)
						return H.slideBeachBallTo(ball, targetPos, steps, stepWait, true)
					end

					function H.getBeachBallInsidePlayerTarget(ball, embedAlpha)
						local playerRoot = H.getCharacterRoot()
						local primary = H.getBeachBallPrimaryPart(ball)
						if not playerRoot or not primary then
							return nil
						end

						embedAlpha = math.clamp(embedAlpha or 1, 0, 1)

						local look = playerRoot.CFrame.LookVector
						local flatLook = Vector3.new(look.X, 0, look.Z)
						if flatLook.Magnitude < 0.05 then
							flatLook = Vector3.new(0, 0, -1)
						else
							flatLook = flatLook.Unit
						end

						local radius = math.max(primary.Size.X, primary.Size.Y, primary.Size.Z) * 0.5
						local edgePos = playerRoot.Position + flatLook * (radius * 0.15)
						local insidePos = playerRoot.Position
						return edgePos:Lerp(insidePos, embedAlpha)
					end

					function H.moveBeachBallToPlayerForTouch(ball)
						local playerRoot = H.getCharacterRoot()
						if not playerRoot or not ball then
							return false
						end

						if H.shouldAutoGoalsUseKothTouchPath() then
							local goalsByName = H.collectBeachGoalsByName()
							local goalPart = H.pickGoalForBeachBall(ball, goalsByName, H.getBeachBalls())
							if goalPart then
								H.faceCharacterTowardGoal(goalPart)
								task.wait(0.05)
							end
						end

						H.applyBeachBallSoftNoCollision(ball)
						H.zeroBeachBallVelocity(ball)

						local onPos = H.getBeachBallInsidePlayerTarget(ball, AUTO_GOALS_BALL_ON_PLAYER_EMBED)
						if not onPos then
							return false
						end

						if not H.slideBeachBallUpFromUnderground(
							ball,
							onPos,
							AUTO_GOALS_BALL_TO_PLAYER_STEPS,
							AUTO_GOALS_BALL_TO_PLAYER_STEP_WAIT,
							true
						) then
							return false
						end

						H.fireTouchPair(H.getCharacterTouchPart(), H.getBeachBallPrimaryPart(ball) or ball)

						local holdEnd = os.clock() + AUTO_GOALS_BALL_INSIDE_HOLD
						while S.autoGoalsRunning and os.clock() < holdEnd do
							if H.shouldAutoGoalsUseKothTouchPath() then
								H.maintainKothHillDuringGoalKick()
							end
							local heldPos = H.getBeachBallInsidePlayerTarget(ball, AUTO_GOALS_BALL_ON_PLAYER_EMBED)
							if heldPos then
								H.slideBeachBallTo(ball, heldPos, 2, 0.02, true)
							end
							task.wait(0.05)
						end

						if not S.autoGoalsRunning then
							return false
						end

						local deepPos = H.getBeachBallInsidePlayerTarget(ball, 1)
						if not deepPos then
							return false
						end

						if not H.slideBeachBallTo(
							ball,
							deepPos,
							AUTO_GOALS_BALL_INSIDE_SMOOTH_STEPS,
							AUTO_GOALS_BALL_INSIDE_SMOOTH_STEP_WAIT,
							true
						) then
							return false
						end

						H.fireTouchPair(H.getCharacterTouchPart(), H.getBeachBallPrimaryPart(ball) or ball)
						task.wait(AUTO_GOALS_TOUCH_SETTLE)
						return true
					end

					function H.touchBeachBallAtPlayer(ball)
						return H.moveBeachBallToPlayerForTouch(ball)
					end

					function H.touchBeachBallForAutoGoal(ball)
						if H.shouldAutoGoalsBringBallToPlayer() then
							return H.touchBeachBallAtPlayer(ball)
						end
						return H.touchBeachBallAtMidfield(ball)
					end

					function H.touchBeachBallAtMidfield(ball)
						local playerRoot = H.getCharacterRoot()
						if not playerRoot or not ball then
							return false
						end

						local middleCFrame = H.getAutoGoalsMidfieldCFrame(ball)
						if not middleCFrame then
							return false
						end

						playerRoot.CFrame = middleCFrame
						task.wait(AUTO_GOALS_TOUCH_SETTLE)

						return H.moveBeachBallToPlayerForTouch(ball)
					end

					function H.getBeachGoalScorePart(goalPart)
						local model = goalPart and goalPart.Parent
						local score = model and model:FindFirstChild("Score")
						if score and score:IsA("BasePart") then
							return score
						end
						return goalPart
					end

					function H.slideBeachBallIntoGoal(ball, goalPart)
						if not ball or not goalPart then
							return false
						end

						H.restoreSingleBeachBallCollision(ball)

						local aimPos = H.getBeachGoalAimPositionForBall(ball, goalPart)
						if not aimPos then
							return false
						end

						local scorePart = H.getBeachGoalScorePart(goalPart)
						local primary = H.getBeachBallPrimaryPart(ball)
						local goalPos = Vector3.new(aimPos.X, aimPos.Y, aimPos.Z)

						if not H.slideBeachBallUndergroundToGoal(ball, goalPos) then
							return false
						end

						task.wait(AUTO_GOALS_TOUCH_SETTLE)
						H.fireTouchPair(primary or ball, scorePart)

						if H.shouldAutoGoalsUseKothTouchPath() then
							local ballId = ball:GetAttribute("SoccerBallId")
							if not ballId and primary and primary ~= ball then
								ballId = primary:GetAttribute("SoccerBallId")
							end
							H.fireSoccerKick(ballId)
							task.wait(0.05)
							H.fireTouchPair(primary or ball, scorePart)
						end

						return true
					end

					function H.ensureFishingPhaseListener()
						if S.autoFishPhaseConn then
							return
						end

						local zap = H.getZapClient()
						if not zap or not zap.FishingPhase or not zap.FishingPhase.On then
							return
						end

						S.autoFishPhaseConn = zap.FishingPhase.On(function(data)
							S.autoFishPhase = data and data.phase or FISHING_PHASE_IDLE
						end)
					end

					function H.teardownFishingPhaseListener()
						if S.autoFishPhaseConn then
							pcall(function()
								S.autoFishPhaseConn:Disconnect()
							end)
							S.autoFishPhaseConn = nil
						end
						S.autoFishPhase = FISHING_PHASE_IDLE
					end

					function H.getFishAreaPart()
						local fishArea = H.getWorkspacePath(FISH_AREA_PATH)
						if fishArea and fishArea:IsA("BasePart") then
							return fishArea
						end
						return nil
					end

					function H.getFishAreaFootPosition()
						local root = H.getCharacterRoot()
						if not root then
							return nil
						end

						local character = player.Character
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						return root.Position - Vector3.new(0, root.Size.Y * 0.5 + (humanoid and humanoid.HipHeight or 0), 0)
					end

					function H.isPointOnFishAreaPart(footPos)
						local fishArea = H.getFishAreaPart()
						if not fishArea or not footPos then
							return false
						end

						local localPos = fishArea.CFrame:PointToObjectSpace(footPos)
						local half = fishArea.Size * 0.5
						return math.abs(localPos.X) <= half.X
							and math.abs(localPos.Z) <= half.Z
							and math.abs(localPos.Y) <= half.Y + FISHING_ZONE_Y_TOLERANCE
					end

					function H.getFishAreaStandCFrame()
						local fishArea = H.getFishAreaPart()
						if not fishArea then
							return nil
						end

						local root = H.getCharacterRoot()
						local rootHalf = root and root.Size.Y * 0.5 or 1
						local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
						local hip = humanoid and humanoid.HipHeight or 2
						local yOffset = fishArea.Size.Y * 0.5 + rootHalf + hip
						return fishArea.CFrame * CFrame.new(0, yOffset, 0)
					end

					function H.isInFishingZone()
						local footPos = H.getFishAreaFootPosition()
						if not footPos then
							return false
						end

						if H.isPointOnFishAreaPart(footPos) then
							return true
						end

						for _, zonePart in ipairs(CollectionService:GetTagged(FISHING_ZONE_TAG)) do
							if zonePart:IsA("BasePart") then
								local localPos = zonePart.CFrame:PointToObjectSpace(footPos)
								local half = zonePart.Size * 0.5
								if math.abs(localPos.X) <= half.X
									and math.abs(localPos.Z) <= half.Z
									and math.abs(localPos.Y) <= half.Y + FISHING_ZONE_Y_TOLERANCE then
									return true
								end
							end
						end

						return false
					end

					function H.getGroundTeleportCFrame()
						for _, location in ipairs(MISC_TP_LOCATIONS) do
							if location.label == "Ground" then
								return CFrame.new(location.position)
							end
						end
						return nil
					end

					function H.ensureOrbGroundTeleport()
						local ground = H.getGroundTeleportCFrame()
						if not ground then
							return false
						end
						H.teleportCharacterTo(ground)
						return true
					end

					function H.leaveFishingZone()
						local fishingController = H.getFishingController()
						if fishingController and fishingController.RequestStop then
							pcall(function()
								fishingController:RequestStop()
							end)
						end

						if H.isInFishingZone() then
							for _, location in ipairs(MISC_TP_LOCATIONS) do
								if location.label == "Ground" then
									H.teleportCharacterTo(CFrame.new(location.position))
									break
								end
							end
						end
					end

					function H.snapToFishingStand()
						local root = H.getCharacterRoot()
						if not root then
							return false
						end

						local standCFrame = H.getFishAreaStandCFrame()
						if not standCFrame then
							H.setStatus("FishArea not found")
							return false
						end

						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						root.CFrame = standCFrame
						return true
					end

					function H.fireFishingStart()
						local fishingController = H.getFishingController()
						if fishingController and fishingController.RequestStart then
							local ok = pcall(function()
								fishingController:RequestStart()
							end)
							if ok then
								return true
							end
						end

						local zap = H.getZapClient()
						if not zap or not zap.FishingStart or not zap.FishingStart.Fire then
							return false
						end

						local ok = pcall(function()
							zap.FishingStart.Fire()
						end)
						return ok
					end

					function H.runAutoFishCycle()
						H.ensureFishingPhaseListener()

						while S.autoFishRunning do
							local root = H.getCharacterRoot()
							if not root then
								task.wait(AUTO_FISH_POLL)
							else
								if not H.isInFishingZone() then
									H.snapToFishingStand()
									task.wait(0.3)
								end

								if S.autoFishPhase == FISHING_PHASE_IDLE then
									H.fireFishingStart()
									local deadline = os.clock() + AUTO_FISH_CAST_TIMEOUT
									while S.autoFishRunning and S.autoFishPhase ~= FISHING_PHASE_IDLE and os.clock() < deadline do
										task.wait(0.15)
									end
								end

								task.wait(AUTO_FISH_POLL)
							end
						end
					end

					function H.stopAutoFishLoop()
						S.autoFishRunning = false
						H.teardownFishingPhaseListener()
						if not S.autoGoalsRunning then
							H.applySilentTrainMode(false)
						end
					end

					function H.startAutoFishLoop()
						if S.autoFishLoopActive then
							return
						end
						S.autoFishLoopActive = true

						task.spawn(function()
							H.runAutoFishCycle()
							S.autoFishLoopActive = false
						end)
					end

					function H.mineRaceColorClose(color3, r, g, b)
						if not color3 then
							return false
						end
						local cr = math.round(color3.R * 255)
						local cg = math.round(color3.G * 255)
						local cb = math.round(color3.B * 255)
						local tol = AUTO_MINE_RACE_COLOR_TOL
						return math.abs(cr - r) <= tol and math.abs(cg - g) <= tol and math.abs(cb - b) <= tol
					end

					function H.isMineRaceMineColor(color3)
						local c = AUTO_MINE_RACE_MINE_RGB
						return H.mineRaceColorClose(color3, c[1], c[2], c[3])
					end

					function H.isMineRaceSafeColor(color3)
						local c = AUTO_MINE_RACE_SAFE_RGB
						return H.mineRaceColorClose(color3, c[1], c[2], c[3])
					end

					function H.isMineRaceGrayColor(color3)
						local c = AUTO_MINE_RACE_GRAY_RGB
						return H.mineRaceColorClose(color3, c[1], c[2], c[3])
					end

					function H.getMineRaceMinefield()
						return H.getWorkspacePath({ "Scene", "Minefield" })
					end

					function H.getMineRaceCellsFolder()
						local minefield = H.getMineRaceMinefield()
						return minefield and minefield:FindFirstChild("Cells")
					end

					function H.getMineRaceCellButton(cell)
						if not cell then
							return nil
						end
						local button = cell:FindFirstChild("Button")
						if button and button:IsA("BasePart") then
							return button
						end
						return nil
					end

					function H.getMineRaceCellPosition(cell)
						if not cell then
							return nil
						end
						if cell:IsA("Model") then
							return cell:GetPivot().Position
						end
						if cell:IsA("BasePart") then
							return cell.Position
						end
						return nil
					end

					function H.backupAutomationCharacterCollision()
						local character = player.Character
						if not character or S.automationCharacterCollisionBackup then
							return
						end

						S.automationCharacterCollisionBackup = {}
						for _, part in ipairs(character:GetDescendants()) do
							if part:IsA("BasePart") then
								S.automationCharacterCollisionBackup[part] = {
									canCollide = part.CanCollide,
									canTouch = part.CanTouch,
									anchored = part.Anchored,
								}
							end
						end
					end

					function H.restoreAutomationCharacterCollision()
						local backup = S.automationCharacterCollisionBackup
						if not backup then
							return
						end

						for part, state in pairs(backup) do
							if part and part.Parent then
								pcall(function()
									if state.canCollide ~= nil then
										part.CanCollide = state.canCollide
									end
									if state.canTouch ~= nil then
										part.CanTouch = state.canTouch
									end
									if state.anchored ~= nil then
										part.Anchored = state.anchored
									end
								end)
							end
						end

						S.automationCharacterCollisionBackup = nil
					end

					function H.applyAutomationCharacterNoCollide()
						H.backupAutomationCharacterCollision()
						local character = player.Character
						if not character then
							return
						end

						for _, part in ipairs(character:GetDescendants()) do
							if part:IsA("BasePart") then
								part.CanCollide = false
							end
						end
					end

					function H.uprightCharacterRoot(root)
						if not root then
							return
						end

						local pos = root.Position
						local look = root.CFrame.LookVector
						local flatLook = Vector3.new(look.X, 0, look.Z)
						if flatLook.Magnitude > 0.05 then
							root.CFrame = CFrame.lookAt(pos, pos + flatLook.Unit)
						else
							root.CFrame = CFrame.new(pos)
						end
					end

					function H.restoreCharacterMovementState()
						H.cancelAutoQuestTween()
						H.cancelMineRaceTween()
						H.restoreAutomationCharacterCollision()

						local character = player.Character
						if not character then
							return
						end

						local root = character:FindFirstChild("HumanoidRootPart")
						local humanoid = character:FindFirstChildOfClass("Humanoid")

						if root then
							root.Anchored = false
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
							H.uprightCharacterRoot(root)

							for _, part in ipairs(character:GetDescendants()) do
								if part:IsA("BasePart") then
									part.AssemblyLinearVelocity = Vector3.zero
									part.AssemblyAngularVelocity = Vector3.zero
								end
							end
						end

						if humanoid then
							humanoid.PlatformStand = false
							humanoid.Sit = false
							humanoid.AutoRotate = true
						end
					end

					function H.cancelMineRaceTween()
						if S.autoMineRaceTween then
							pcall(function()
								S.autoMineRaceTween:Cancel()
							end)
							S.autoMineRaceTween = nil
						end
					end

					function H.isMineRaceActive()
						return S.autoMineRaceRunning == true
					end

					function H.clearMineRaceProgress()
						S.autoMineRaceMined = {}
						S.autoMineRaceRowSaved = {}
					end

					function H.setMineRaceNoCollide(enabled)
						if enabled then
							H.restoreAutomationCharacterCollision()
						else
							H.applyAutomationCharacterNoCollide()
						end
					end

					function H.mineRaceRespawnPlayer()
						local root = H.getCharacterRoot()
						if not root then
							return
						end
						root.Anchored = false
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						root.CFrame = CFrame.new(AUTO_MINE_RACE_RESPAWN + Vector3.new(0, 50, 0))
						task.wait(0.05)
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						root.CFrame = CFrame.new(AUTO_MINE_RACE_RESPAWN)
					end

					function H.mineRaceAnchorRoot(anchored)
						local root = H.getCharacterRoot()
						if not root then
							return
						end
						root.Anchored = anchored
						if anchored then
							root.AssemblyLinearVelocity = Vector3.zero
							root.AssemblyAngularVelocity = Vector3.zero
						end
					end

					function H.mineRaceCheckMineNearby(cellsFolder, rowIndex, watchCell)
						local root = H.getCharacterRoot()
						if not root then
							return false
						end

						if watchCell then
							local btn = H.getMineRaceCellButton(watchCell)
							if btn and H.isMineRaceMineColor(btn.Color) then
								local pos = H.getMineRaceCellPosition(watchCell)
								if pos and (pos - root.Position).Magnitude < 5 then
									return true
								end
							end
						end

						if cellsFolder and rowIndex then
							for row = math.max(1, rowIndex - 1), math.min(AUTO_MINE_RACE_ROW_COUNT, rowIndex + 1) do
								local rowFolder = cellsFolder:FindFirstChild("Row" .. row)
								if rowFolder then
									for _, cell in ipairs(rowFolder:GetChildren()) do
										if cell.Name == "MineCell" then
											local btn = H.getMineRaceCellButton(cell)
											if btn and H.isMineRaceMineColor(btn.Color) then
												local pos = H.getMineRaceCellPosition(cell)
												if pos and (pos - root.Position).Magnitude < 5 then
													return true
												end
											end
										end
									end
								end
							end
						end

						return false
					end

					function H.tweenMineRaceTo(targetCFrame, watchCell, cellsFolder, rowIndex)
						local root = H.getCharacterRoot()
						if not root or not targetCFrame then
							return false
						end

						local goal = (typeof(targetCFrame) == "CFrame") and targetCFrame or targetCFrame.CFrame
						goal = goal * CFrame.new(0, 2.5, 0)

						local dist = (goal.Position - root.Position).Magnitude
						local duration = dist / AUTO_MINE_RACE_SPEED
						if duration <= 0 then
							return true
						end

						H.cancelMineRaceTween()

						local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
							CFrame = goal,
						})
						S.autoMineRaceTween = tween
						local finished = false
						tween.Completed:Connect(function()
							finished = true
						end)
						tween:Play()

						local deadline = os.clock() + duration + 0.2
						while not finished and os.clock() < deadline do
							if not H.isMineRaceActive() then
								H.cancelMineRaceTween()
								return false
							end
							if H.mineRaceCheckMineNearby(cellsFolder, rowIndex, watchCell) then
								H.cancelMineRaceTween()
								H.mineRaceAnchorRoot(true)
								return false
							end
							task.wait(AUTO_MINE_RACE_POLL)
						end

						H.cancelMineRaceTween()
						return finished
					end

					function H.retreatMineRaceFrom(cell)
						local button = H.getMineRaceCellButton(cell)
						if not button then
							return
						end

						local root = H.getCharacterRoot()
						if not root then
							return
						end

						local function playTrackedTween(goalCFrame, duration)
							if not H.isMineRaceActive() then
								return false
							end

							H.cancelMineRaceTween()
							local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
								CFrame = goalCFrame,
							})
							S.autoMineRaceTween = tween
							local finished = false
							tween.Completed:Connect(function()
								finished = true
							end)
							tween:Play()

							local deadline = os.clock() + duration + 0.15
							while not finished and os.clock() < deadline do
								if not H.isMineRaceActive() then
									H.cancelMineRaceTween()
									return false
								end
								task.wait()
							end

							H.cancelMineRaceTween()
							return finished
						end

						if not playTrackedTween(root.CFrame * CFrame.new(0, 8, 0), 0.15) then
							return
						end

						local target = button.CFrame * CFrame.new(0, 8, 0)
						local dist = (target.Position - root.Position).Magnitude
						local duration = dist / (AUTO_MINE_RACE_SPEED * 1.5)
						if not playTrackedTween(target, math.max(duration, 0.05)) then
							return
						end

						playTrackedTween(button.CFrame * CFrame.new(0, 2.5, 0), 0.15)
					end

					function H.mineRaceCollectRowCandidates(rowFolder, root)
						local nearest = math.huge
						for _, cell in ipairs(rowFolder:GetChildren()) do
							if cell.Name == "MineCell" then
								local pos = H.getMineRaceCellPosition(cell)
								if pos then
									local dist = (pos - root.Position).Magnitude
									if dist < nearest then
										nearest = dist
									end
								end
							end
						end

						local radius = (nearest * 1.8) + 2
						local candidates = {}
						for _, cell in ipairs(rowFolder:GetChildren()) do
							if cell.Name == "MineCell" and not S.autoMineRaceMined[cell] then
								local btn = H.getMineRaceCellButton(cell)
								if btn and (H.isMineRaceGrayColor(btn.Color) or H.isMineRaceSafeColor(btn.Color)) then
									local pos = H.getMineRaceCellPosition(cell)
									if pos and (pos - root.Position).Magnitude <= radius then
										table.insert(candidates, cell)
									end
								end
							end
						end

						table.sort(candidates, function(a, b)
							local btnA = H.getMineRaceCellButton(a)
							local btnB = H.getMineRaceCellButton(b)
							local safeA = btnA and H.isMineRaceSafeColor(btnA.Color)
							local safeB = btnB and H.isMineRaceSafeColor(btnB.Color)
							if safeA and not safeB then
								return true
							end
							if safeB and not safeA then
								return false
							end
							local posA = H.getMineRaceCellPosition(a)
							local posB = H.getMineRaceCellPosition(b)
							if not posA or not posB then
								return false
							end
							return (posA - root.Position).Magnitude < (posB - root.Position).Magnitude
						end)

						return candidates
					end

					function H.runAutoMineRaceLoop(sessionId)
						local cellsFolder = H.getMineRaceCellsFolder()
						if not cellsFolder then
							H.setStatus("Mine race: Cells not found")
							return
						end

						while H.isMineRaceActive() and sessionId == S.autoMineRaceSessionId do
							H.setMineRaceNoCollide(false)

							local boardReset = false
							for _, saved in pairs(S.autoMineRaceRowSaved) do
								local btn = saved and H.getMineRaceCellButton(saved)
								if btn and H.isMineRaceGrayColor(btn.Color) then
									H.clearMineRaceProgress()
									H.mineRaceRespawnPlayer()
									task.wait(1)
									boardReset = true
									break
								end
							end
							if boardReset then
								continue
							end

							local hitMine = false
							local rowIndex = 1

							while rowIndex <= AUTO_MINE_RACE_ROW_COUNT and H.isMineRaceActive() and sessionId == S.autoMineRaceSessionId do
								H.setMineRaceNoCollide(false)

								local rowFolder = cellsFolder:FindFirstChild("Row" .. rowIndex)
								if not rowFolder then
									hitMine = true
									break
								end

								local saved = S.autoMineRaceRowSaved[rowIndex]
								if saved and saved.Parent then
									local savedBtn = H.getMineRaceCellButton(saved)
									if savedBtn and H.isMineRaceMineColor(savedBtn.Color) then
										S.autoMineRaceMined[saved] = true
										S.autoMineRaceRowSaved[rowIndex] = nil
										hitMine = true
										break
									end

									if not H.tweenMineRaceTo(savedBtn and savedBtn.CFrame, saved, cellsFolder, rowIndex) then
										hitMine = true
										break
									end

									task.wait(0.1)
									savedBtn = H.getMineRaceCellButton(saved)
									if savedBtn and H.isMineRaceMineColor(savedBtn.Color) then
										S.autoMineRaceMined[saved] = true
										S.autoMineRaceRowSaved[rowIndex] = nil
										hitMine = true
										break
									end

									rowIndex = rowIndex + 1
								else
									local root = H.getCharacterRoot()
									if not root then
										hitMine = true
										break
									end

									local candidates = H.mineRaceCollectRowCandidates(rowFolder, root)
									local cell = candidates[1]
									if cell then
										local btn = H.getMineRaceCellButton(cell)
										if not H.tweenMineRaceTo(btn and btn.CFrame, cell, cellsFolder, rowIndex) then
											hitMine = true
											break
										end

										task.wait(0.15)
										local deadline = os.clock() + 3
										btn = H.getMineRaceCellButton(cell)
										while btn and not H.isMineRaceMineColor(btn.Color) and not H.isMineRaceSafeColor(btn.Color) and os.clock() < deadline do
											if not H.isMineRaceActive() or sessionId ~= S.autoMineRaceSessionId then
												return
											end
											task.wait(0.05)
											btn = H.getMineRaceCellButton(cell)
										end

										btn = H.getMineRaceCellButton(cell)
										if btn and H.isMineRaceMineColor(btn.Color) then
											S.autoMineRaceMined[cell] = true
											hitMine = true
											break
										elseif btn and H.isMineRaceSafeColor(btn.Color) then
											S.autoMineRaceRowSaved[rowIndex] = cell
											rowIndex = rowIndex + 1
											task.wait(0.02)
										else
											break
										end
									else
										if rowIndex == 1 then
											hitMine = true
											break
										end

										local prevSaved = S.autoMineRaceRowSaved[rowIndex - 1]
										if prevSaved then
											S.autoMineRaceMined[prevSaved] = true
											S.autoMineRaceRowSaved[rowIndex - 1] = nil
										end

										local retreatCell = S.autoMineRaceRowSaved[rowIndex - 2]
										if retreatCell and retreatCell.Parent then
											H.retreatMineRaceFrom(retreatCell)
											task.wait(0.1)
										else
											H.mineRaceRespawnPlayer()
											task.wait(0.2)
										end

										rowIndex = math.max(1, rowIndex - 1)
									end
								end
							end

							if hitMine and H.isMineRaceActive() and sessionId == S.autoMineRaceSessionId then
								H.setStatus("Mine race: hit mine, resetting...")
								H.mineRaceAnchorRoot(true)
								task.wait(AUTO_MINE_RACE_RESET_WAIT)
								H.mineRaceRespawnPlayer()
								H.mineRaceAnchorRoot(false)
							elseif rowIndex > AUTO_MINE_RACE_ROW_COUNT and H.isMineRaceActive() and sessionId == S.autoMineRaceSessionId then
								local root = H.getCharacterRoot()
								if root then
									local look = root.CFrame.LookVector
									local prev = S.autoMineRaceRowSaved[AUTO_MINE_RACE_ROW_COUNT - 1]
									local last = S.autoMineRaceRowSaved[AUTO_MINE_RACE_ROW_COUNT]
									if prev and last then
										local p1 = H.getMineRaceCellPosition(prev)
										local p2 = H.getMineRaceCellPosition(last)
										if p1 and p2 then
											look = (p2 - p1).Unit
										end
									end
									local ahead = CFrame.new(root.Position + look * 5) * root.CFrame.Rotation
									H.tweenMineRaceTo(ahead, nil, cellsFolder, AUTO_MINE_RACE_ROW_COUNT)
									task.wait(0.15)
								end

								local minefield = H.getMineRaceMinefield()
								local endRace = minefield and minefield:FindFirstChild("EndRace")
								if endRace then
									local endCf = (endRace:IsA("Model") and endRace:GetPivot()) or endRace.CFrame
									H.tweenMineRaceTo(endCf, nil, cellsFolder, AUTO_MINE_RACE_ROW_COUNT)
									H.setStatus("Mine race: finished, waiting...")
									task.wait(AUTO_MINE_RACE_FINISH_WAIT)
									if H.isMineRaceActive() and sessionId == S.autoMineRaceSessionId then
										H.clearMineRaceProgress()
										H.mineRaceRespawnPlayer()
									end
								else
									H.setStatus("Mine race: EndRace not found")
									task.wait(2)
								end
							else
								task.wait(0.2)
							end
						end

						H.mineRaceAnchorRoot(false)
						H.restoreCharacterMovementState()
					end

					function H.stopAutoMineRaceLoop()
						S.autoMineRaceSessionId = S.autoMineRaceSessionId + 1
						S.autoMineRaceRunning = false
						H.restoreCharacterMovementState()
					end

					function H.startAutoMineRaceLoop()
						if S.autoMineRaceLoopActive then
							return
						end
						S.autoMineRaceLoopActive = true
						S.autoMineRaceSessionId = S.autoMineRaceSessionId + 1
						local sessionId = S.autoMineRaceSessionId
						H.clearMineRaceProgress()

						task.spawn(function()
							H.runAutoMineRaceLoop(sessionId)
							S.autoMineRaceLoopActive = false
						end)
					end

					function H.getQuestController()
						local aero = H.getGlobal().Aero
						return aero and aero.Controllers and aero.Controllers.QuestController or nil
					end

					function H.getQuestHudController()
						local aero = H.getGlobal().Aero
						return aero and aero.Controllers and aero.Controllers.QuestHudController or nil
					end

					function H.getNewbieQuestsShared()
						if C.newbieQuestsShared then
							return C.newbieQuestsShared
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local newbieScript = sharedFolder and sharedFolder:FindFirstChild("NewbieQuests")
						if not newbieScript then
							return nil
						end

						local ok, mod = pcall(require, newbieScript)
						if ok and mod then
							C.newbieQuestsShared = mod
							return mod
						end
						return nil
					end

					function H.getQuestsShared()
						if C.questsShared then
							return C.questsShared
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local questsScript = sharedFolder and sharedFolder:FindFirstChild("Quests")
						if not questsScript then
							return nil
						end

						local ok, mod = pcall(require, questsScript)
						if ok and mod then
							C.questsShared = mod
							return mod
						end
						return nil
					end

					function H.getClientQuestsFolder()
						local gui = player:FindFirstChild("PlayerGui")
						local clientData = gui and gui:FindFirstChild("ClientData")
						return clientData and clientData:FindFirstChild("quests") or nil
					end

					function H.getActiveQuestKey()
						local questController = H.getQuestController()
						if questController then
							if questController._activeQuestKey then
								local ok, key = pcall(function()
									return questController:_activeQuestKey()
								end)
								if ok and key then
									return key
								end
							end

							if type(questController.Quests) == "table" then
								for key, entry in pairs(questController.Quests) do
									if type(entry) == "table" and entry.active and entry.active.Value then
										return key
									end
								end
							end

							if questController._acceptedQuest then
								return questController._acceptedQuest
							end
						end

						local hud = H.getQuestHudController()
						if hud and type(hud._rotation) == "table" then
							for key, entry in pairs(hud._rotation) do
								if type(entry) == "table" and entry.active and entry.active.Value then
									return key
								end
							end
						end

						local questsFolder = H.getClientQuestsFolder()
						local questsShared = H.getQuestsShared()
						if questsFolder and questsShared then
							local pool = questsShared.ActivePool
							if type(pool) == "table" then
								for _, key in ipairs(pool) do
									local entry = questsFolder:FindFirstChild(key)
									local active = entry and entry:FindFirstChild("active")
									if active and active.Value then
										return key
									end
								end
							end

							if questsShared.Keys then
								for _, key in pairs(questsShared.Keys) do
									local entry = questsFolder:FindFirstChild(key)
									local active = entry and entry:FindFirstChild("active")
									if active and active.Value then
										return key
									end
								end
							end
						end

						return nil
					end

					function H.waitForActiveQuestKey(timeoutSeconds)
						local deadline = os.clock() + (timeoutSeconds or 4)
						local key = H.getActiveQuestKey()
						while not key and os.clock() < deadline do
							task.wait(0.15)
							key = H.getActiveQuestKey()
						end
						return key
					end

					function H.buildQuestStateFromController(questKey)
						local questController = H.getQuestController()
						local questsShared = H.getQuestsShared()
						if not questController or not questsShared or type(questController.Quests) ~= "table" then
							return nil
						end

						local entry = questController.Quests[questKey]
						if not entry or not entry.level then
							return nil
						end

						local levelValue = entry.level.Value or 1
						local objectives = {}
						local completed = true

						for i, objectiveDef in ipairs(questsShared:GetObjectives(questKey)) do
							local goal = questsShared:GetCountForLevel(questKey, levelValue, i)
							local progressObj = entry.progress and entry.progress[i]
							local progress = math.min(progressObj and progressObj.Value or 0, goal)
							local done = progress >= goal
							if not done then
								completed = false
							end
							table.insert(objectives, {
								verb = objectiveDef.Verb,
								noun = objectiveDef.Noun,
								pastVerb = objectiveDef.PastVerb,
								goal = goal,
								progress = progress,
								done = done,
							})
						end

						return {
							key = questKey,
							objectives = objectives,
							completed = completed,
						}
					end

					function H.getQuestState(questKey)
						if not questKey then
							return nil
						end

						local questController = H.getQuestController()
						if questController and questController._questState then
							local ok, state = pcall(function()
								return questController:_questState(questKey)
							end)
							if ok and state then
								return state
							end
						end

						local controllerState = H.buildQuestStateFromController(questKey)
						if controllerState then
							return controllerState
						end

						local questsFolder = H.getClientQuestsFolder()
						local questsShared = H.getQuestsShared()
						if not questsFolder or not questsShared then
							return nil
						end

						local entry = questsFolder:FindFirstChild(questKey)
						if not entry then
							return nil
						end

						local level = entry:FindFirstChild("level")
						local levelValue = level and level.Value or 1
						local objectives = {}
						local completed = true

						for i, objectiveDef in ipairs(questsShared:GetObjectives(questKey)) do
							local goal = questsShared:GetCountForLevel(questKey, levelValue, i)
							local progressValue = entry:FindFirstChild(questsShared:ProgressField(i))
							local progress = math.min(progressValue and progressValue.Value or 0, goal)
							local done = progress >= goal
							if not done then
								completed = false
							end
							table.insert(objectives, {
								verb = objectiveDef.Verb,
								noun = objectiveDef.Noun,
								pastVerb = objectiveDef.PastVerb,
								goal = goal,
								progress = progress,
								done = done,
							})
						end

						return {
							key = questKey,
							objectives = objectives,
							completed = completed,
						}
					end

					function H.getPrimaryQuestObjective(state)
						if not state or not state.objectives then
							return nil
						end

						for _, objective in ipairs(state.objectives) do
							if not objective.done then
								return objective
							end
						end

						return state.objectives[1]
					end

					function H.mapQuestKeyToKind(questKey, state)
						if questKey == "city_routine_quest" then
							local objective = H.getPrimaryQuestObjective(state)
							if not objective then
								return nil
							end

							local noun = string.lower(objective.noun or "")
							if string.find(noun, "orb", 1, true) then
								return "Orb", "Orb"
							end
							if string.find(noun, "chest", 1, true) then
								return "Chest", "Chest"
							end
							return nil
						end

						local kind = QUEST_KEY_TO_KIND[questKey]
						if not kind then
							return nil
						end

						if kind == "CityRoutine" then
							return H.mapQuestKeyToKind("city_routine_quest", state)
						end

						return kind, QUEST_KEY_TO_TARGET[questKey] or kind
					end

					function H.ensureNewbieQuestLoaded(maxWait)
						local hud = H.getQuestHudController()
						if not hud then
							return false
						end
						if hud._newbie then
							return true
						end

						local zap = H.getZapClient()
						if zap and zap.QuestLineRequest and zap.QuestLineRequest.Fire then
							pcall(function()
								zap.QuestLineRequest.Fire()
							end)
						end

						local deadline = os.clock() + (maxWait or 6)
						while os.clock() < deadline do
							if hud._newbie then
								return true
							end
							if zap and zap.QuestLineRequest and zap.QuestLineRequest.Fire then
								pcall(function()
									zap.QuestLineRequest.Fire()
								end)
							end
							task.wait(0.35)
						end

						return hud._newbie ~= nil
					end

					function H.getNewbieObjectiveProgress(objective, index, newbie)
						if type(objective) ~= "table" then
							return 0
						end
						if objective.absolute == true or objective.id == "level" then
							return H.getPlayerLevel()
						end
						return newbie and newbie.progress and newbie.progress[index] or 0
					end

					function H.parseNewbieQuest()
						H.ensureNewbieQuestLoaded(2)

						local activeKey = H.getActiveQuestKey()
						if activeKey then
							local activeState = H.getQuestState(activeKey)
							if not activeState or not activeState.completed then
								return nil
							end
						end

						local hud = H.getQuestHudController()
						local newbie = hud and hud._newbie
						if not newbie or not newbie.stage then
							return nil
						end

						local newbieQuests = H.getNewbieQuestsShared()
						if not newbieQuests or newbieQuests:IsDone(newbie.stage) then
							return nil
						end

						local stage = newbieQuests:GetStage(newbie.stage)
						if not stage or not stage.objectives or #stage.objectives == 0 then
							return nil
						end

						local kind = NEWBIE_STAGE_KIND[stage.id]
						if not kind then
							return nil
						end

						local objective = stage.objectives[1]
						local goal = objective.max or 1
						local current = H.getNewbieObjectiveProgress(objective, 1, newbie)
						for i, obj in ipairs(stage.objectives) do
							local progress = H.getNewbieObjectiveProgress(obj, i, newbie)
							if progress < (obj.max or 1) then
								objective = obj
								goal = obj.max or 1
								current = progress
								break
							end
							objective = obj
							goal = obj.max or 1
							current = progress
						end

						local questKey = "newbie_" .. tostring(stage.id)
						local state = {
							key = questKey,
							objectives = {
								{
									verb = objective.name,
									noun = objective.name,
									goal = goal,
									progress = current,
									done = current >= goal,
								},
							},
							completed = current >= goal,
						}

						return kind, kind, goal, current, true, questKey, state
					end

					function H.parseActiveQuest()
						local questKey = H.waitForActiveQuestKey(0.5) or H.getActiveQuestKey()
						if questKey then
							local state = H.getQuestState(questKey)
							if state then
								if state.completed then
									return "QuestTurnIn", "Hopsalot", 1, 1, true, questKey, state
								end

								local kind, targetKey = H.mapQuestKeyToKind(questKey, state)
								if kind then
									local objective = H.getPrimaryQuestObjective(state)
									local goal = objective and objective.goal or 0
									local current = objective and objective.progress or 0
									if goal > 0 then
										return kind, targetKey, goal, current, true, questKey, state
									end
								end
							end
						end

						return H.parseNewbieQuest()
					end

					function H.isNewbieQuestKey(questKey)
						return type(questKey) == "string" and string.sub(questKey, 1, 7) == "newbie_"
					end

					function H.getQuestBossModel(targetKey)
						if targetKey == "Borock" then
							return H.getBossModel(AUTO_BOSS_DEFS.borock)
						elseif targetKey == "DemonKing" then
							return H.getBossModel(AUTO_BOSS_DEFS.demon_king)
						end
						return nil
					end

					function H.prefabHasMeshId(prefab, meshId)
						if not prefab or not meshId then
							return false
						end
						if prefab:IsA("MeshPart") and string.find(prefab.MeshId, meshId, 1, true) then
							return true
						end
						local specialMesh = prefab:FindFirstChildOfClass("SpecialMesh")
						if specialMesh and string.find(specialMesh.MeshId, meshId, 1, true) then
							return true
						end
						return false
					end

					function H.findQuestOrbNode()
						local root = H.getCharacterRoot()
						if not root then
							return nil
						end

						local folder = H.getNodesFolder()
						if not folder then
							return nil
						end

						local nearest = nil
						local nearestDist = math.huge
						for _, child in ipairs(folder:GetChildren()) do
							if child.Name == "ResourceNode" and child:IsA("BasePart") then
								local isOrb = H.isActiveNode(child) and not H.isNodeCollected(child)
								if not isOrb then
									local prefab = child:FindFirstChild("Prefab")
									isOrb = prefab and H.prefabHasMeshId(prefab, AUTO_QUEST_ORB_MESH_ID)
								end
								if isOrb then
									local dist = (root.Position - child.Position).Magnitude
									if dist < nearestDist then
										nearestDist = dist
										nearest = child
									end
								end
							end
						end

						return nearest
					end

					function H.findQuestEgg()
						local root = H.getCharacterRoot()
						if not root then
							return nil
						end

						local nearest = nil
						local nearestDist = math.huge
						for _, descendant in ipairs(workspace:GetDescendants()) do
							if descendant.Name == "Egg" and descendant:IsA("BasePart") and not S.autoQuestVisitedEggs[descendant] then
								local dist = (root.Position - descendant.Position).Magnitude
								if dist < nearestDist then
									nearestDist = dist
									nearest = descendant
								end
							end
						end

						return nearest
					end

					function H.cancelAutoQuestTween()
						if S.autoQuestTween then
							pcall(function()
								S.autoQuestTween:Cancel()
							end)
							S.autoQuestTween = nil
						end
					end

					function H.setAutoQuestNoCollide(enabled)
						if enabled then
							H.restoreAutomationCharacterCollision()
						else
							H.applyAutomationCharacterNoCollide()
						end
					end

					function H.tweenAutoQuestTo(target)
						local root = H.getCharacterRoot()
						if not root or not target then
							return false
						end

						local targetPos = target.Position
						if not targetPos then
							return false
						end

						local currentPos = root.Position
						if math.abs(currentPos.Y - targetPos.Y) > 2 then
							local yAligned = Vector3.new(currentPos.X, targetPos.Y, currentPos.Z)
							local yDist = math.abs(currentPos.Y - targetPos.Y)
							local yDuration = yDist / AUTO_QUEST_TWEEN_SPEED
							local yGoal = CFrame.new(yAligned) * (root.CFrame - root.CFrame.Position)
							H.cancelAutoQuestTween()
							local yTween = TweenService:Create(root, TweenInfo.new(yDuration, Enum.EasingStyle.Linear), {
								CFrame = yGoal,
							})
							S.autoQuestTween = yTween
							yTween:Play()
							while yTween.PlaybackState == Enum.PlaybackState.Playing and S.autoQuestRunning do
								task.wait()
							end
							if not S.autoQuestRunning then
								H.cancelAutoQuestTween()
								return false
							end
							currentPos = root.Position
						end

						local flatTarget = Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)
						local flatDist = (currentPos - flatTarget).Magnitude
						local duration = flatDist / AUTO_QUEST_TWEEN_SPEED
						if duration <= 0 then
							return true
						end

						local goal = CFrame.new(flatTarget) * (root.CFrame - root.CFrame.Position)
						H.cancelAutoQuestTween()
						local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
							CFrame = goal,
						})
						S.autoQuestTween = tween
						local finished = false
						tween.Completed:Connect(function()
							finished = true
						end)
						tween:Play()

						local deadline = os.clock() + duration + 0.2
						while not finished and os.clock() < deadline do
							if not S.autoQuestRunning then
								H.cancelAutoQuestTween()
								return false
							end
							task.wait(AUTO_QUEST_POLL)
						end

						H.cancelAutoQuestTween()
						return finished
					end

					function H.teleportCharacterTo(cframe)
						local root = H.getCharacterRoot()
						if not root or not cframe then
							return false
						end
						root.Anchored = false
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						root.CFrame = cframe
						return true
					end

					function H.fireQuestBossClick()
						local ok = pcall(function()
							VirtualInputManager:SendMouseButtonEvent(100, 800, 0, true, game, 0)
							task.wait(0.01)
							VirtualInputManager:SendMouseButtonEvent(100, 800, 0, false, game, 0)
						end)
						if not ok then
							H.backgroundTrainSwing()
						end
					end

					function H.resetAutoQuestProgressCounters()
						S.autoQuestBossHits = 0
						S.autoQuestOrbHits = 0
						S.autoQuestEggHits = 0
						S.autoQuestWasAttackingBoss = false
						S.autoQuestVisitedEggs = {}
						S.autoQuestOrbGroundReady = false
						S.autoQuestBossWaitTpDone = false
					end

					function H.cleanupAutoQuestBossFight()
						H.cancelAutoQuestBossFollow()
						H.ensureQuestBossSwing(false)
					end

					function H.restoreAutoQuestSubFeatures()
						H.cleanupAutoQuestBossFight()
						if S.autoQuestEnabledFish and H.setAutoFish then
							H.setAutoFish(false, false)
							H.leaveFishingZone()
							S.autoQuestEnabledFish = false
						end
						if S.autoQuestEnabledClicker and H.setAutoClicker then
							H.setAutoClicker(false, false)
							S.autoQuestEnabledClicker = false
						end
						if S.autoQuestEnabledKill and H.setAutoKill then
							H.setAutoKill(false, false)
							S.autoQuestEnabledKill = false
						end
					end

					function H.getHopsalotPart()
						local model = workspace:FindFirstChild("Sir Hopsalot")
						if not model then
							return nil
						end
						return model:FindFirstChild("HumanoidRootPart")
							or model.PrimaryPart
							or model:FindFirstChildWhichIsA("BasePart")
					end

					function H.teleportToHopsalot()
						local part = H.getHopsalotPart()
						if not part then
							return false
						end
						return H.teleportCharacterTo(part.CFrame * CFrame.new(0, 3, 6))
					end

					function H.tryEquipQuestGear()
						local changed = false
						if H.tryEquipBestSword() then
							changed = true
						end
						if H.tryEquipBestSkin() then
							changed = true
						end
						local hasWeapon = H.getEquippedItemKey("weapon_equipped")
						local hasSkin = H.getEquippedItemKey("skin_equipped")
						return changed or hasWeapon ~= nil or hasSkin ~= nil
					end

					function H.tryEquipQuestPet()
						local inventory = H.getPetInventoryData()
						if type(inventory) ~= "table" then
							return false
						end

						for _, entry in pairs(inventory) do
							if type(entry) == "table" and entry.equipped then
								return true
							end
						end

						for key, entry in pairs(inventory) do
							if type(entry) == "table" and not entry.equipped then
								local ok = pcall(function()
									H.callGameService("RequestEquipPet", tostring(key), true)
								end)
								if ok then
									return true
								end
							end
						end

						return false
					end

					function H.tryJoinArenaForQuest()
						local aero = H.getGlobal().Aero
						local arena = aero and aero.Controllers and aero.Controllers.ArenaController
						if not arena then
							return false
						end

						local seconds = nil
						if arena.SecondsUntilNextInvite then
							local ok, value = pcall(function()
								return arena:SecondsUntilNextInvite()
							end)
							if ok then
								seconds = value
							end
						end

						if type(seconds) == "number" and seconds > 0 then
							H.setStatus(string.format("Auto quest: arena opens in %ds", math.ceil(seconds)))
							return false
						end

						if arena.SubmitArenaChoice then
							local ok = pcall(function()
								arena:SubmitArenaChoice(true)
							end)
							return ok
						end

						return false
					end

					function H.findQuestPetCratePart()
						local petCrates = workspace:FindFirstChild("PetCrates")
						local pet1 = petCrates and petCrates:FindFirstChild("Pet1")
						if pet1 and pet1:IsA("BasePart") then
							return pet1
						end

						for _, tagged in ipairs(CollectionService:GetTagged("Crate")) do
							if tagged.Name == "Pet1" and tagged:IsA("BasePart") then
								return tagged
							end
						end

						return nil
					end

					function H.getCheapestPetCrateSlot()
						if H.getAffordableCrateBatchSize(QUEST_PET_HATCH_SLOT, 1) > 0 then
							return QUEST_PET_HATCH_SLOT
						end
						return nil
					end

					function H.isPetEquipped(petKey)
						local inventory = H.getPetInventoryData()
						local entry = inventory and (inventory[petKey] or inventory[tostring(petKey)])
						return type(entry) == "table" and entry.equipped == true
					end

					function H.deleteAllNewCrateRewards(slot, beforeKeys)
						if not S.autoQuestDeleteRewards or type(beforeKeys) ~= "table" then
							return false
						end

						local inventory = H.getCrateInventory(slot)
						if type(inventory) ~= "table" then
							return false
						end

						local toSell = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and not beforeKeys[tostring(key)] then
								if slot.kind == "pet" and H.isPetEquipped(key) then
									continue
								end
								if slot.kind == "pet" or slot.kind == "artifact" then
									if H.sellCrateReward(slot, key) then
										table.insert(toSell, key)
									end
								else
									table.insert(toSell, tostring(key))
								end
							end
						end

						if slot.kind == "legendary" or slot.kind == "mythic" then
							if #toSell > 0 then
								return H.invokeSellInventoryItems(slot.itemType, toSell)
							end
						end

						return #toSell > 0
					end

					function H.deleteNewInventoryItems(itemType, beforeKeys)
						if not S.autoQuestDeleteRewards or type(beforeKeys) ~= "table" then
							return false
						end

						local inventory = itemType == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
						if type(inventory) ~= "table" then
							return false
						end

						local toSell = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and not beforeKeys[tostring(key)] then
								table.insert(toSell, tostring(key))
							end
						end

						if #toSell == 0 then
							return false
						end

						return H.invokeSellInventoryItems(itemType, toSell)
					end

					function H.getQuestPetCrateSlot()
						return QUEST_PET_HATCH_SLOT
					end

					function H.getPetCrateWorldPart(slot)
						if not slot or slot.kind ~= "pet" then
							return nil
						end

						local index = slot.index or 1
						local petCrates = workspace:FindFirstChild("PetCrates")
						local direct = petCrates and petCrates:FindFirstChild("Pet" .. tostring(index))
						if direct and direct:IsA("BasePart") then
							return direct
						end

						for _, tagged in ipairs(CollectionService:GetTagged("Crate")) do
							if tagged.Name == ("Pet" .. tostring(index)) and tagged:IsA("BasePart") then
								return tagged
							end
						end

						return nil
					end

					function H.getPetInventoryCount()
						local inventory = H.getPetInventoryData()
						if type(inventory) ~= "table" then
							return 0
						end

						local count = 0
						for _ in pairs(inventory) do
							count += 1
						end
						return count
					end

					function H.getMaxPetInventory()
						local constants = H.getSharedConstants()
						return constants and constants.MAX_PETS or 100
					end

					function H.scorePetSellPriority(petsMod, entry)
						if type(entry) ~= "table" then
							return math.huge
						end

						local petType = H.resolvePetEntryType(entry)
						local data = petType and petsMod and petsMod.Data and (petsMod.Data[petType] or petsMod.Data[tostring(petType)])
						if not data then
							return 500000
						end

						local tier = tonumber(data.Tier) or 1
						local xp = tonumber(data.XpBoost) or 0
						local speed = tonumber(data.SpeedBoost) or 0
						local gold = tonumber(data.GoldBoost) or 0
						return tier * 1e9 + xp * 1e6 + speed * 1e3 + gold
					end

					function H.tryMakePetInventorySpaceForQuest(minFree)
						minFree = math.max(1, tonumber(minFree) or 1)
						local maxPets = H.getMaxPetInventory()
						local inventory = H.getPetInventoryData()
						if type(inventory) ~= "table" then
							return false
						end

						local count = H.getPetInventoryCount()
						local needToSell = count + minFree - maxPets
						if needToSell <= 0 then
							return true
						end

						local petsMod = H.getPetsModule()
						local candidates = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and not entry.equipped then
								table.insert(candidates, {
									key = key,
									score = H.scorePetSellPriority(petsMod, entry),
								})
							end
						end

						table.sort(candidates, function(a, b)
							if a.score == b.score then
								return tostring(a.key) < tostring(b.key)
							end
							return a.score < b.score
						end)

						local slot = { kind = "pet" }
						local sold = 0
						for _, row in ipairs(candidates) do
							if sold >= needToSell then
								break
							end
							if H.sellCrateReward(slot, row.key) then
								sold += 1
							end
						end

						if sold > 0 then
							H.setStatus(string.format("Auto quest: sold %d pet(s) for crate space", sold))
						end

						return sold > 0 or H.getPetInventoryCount() + minFree <= maxPets
					end

					function H.tryAutoQuestOpenPetCrate(remaining)
						local slot = H.getQuestPetCrateSlot()
						if not slot then
							return false
						end

						local hatchCount = math.max(1, tonumber(remaining) or 1)
						local batchSize = H.getAffordableCrateBatchSize(slot, hatchCount)
						if batchSize <= 0 then
							H.setStatus("Auto quest: need gold for Pet 1 crate")
							return false
						end

						if S.autoQuestDeleteRewards then
							H.tryMakePetInventorySpaceForQuest(batchSize)
						elseif H.getPetInventoryCount() + batchSize > H.getMaxPetInventory() then
							H.setStatus("Auto quest: pet inventory full")
							return false
						end

						local beforeKeys = H.snapshotInventoryKeys(slot)
						local ok, result = H.invokeOpenCrates(slot, batchSize)
						if not ok or not result then
							if S.autoQuestDeleteRewards then
								H.tryMakePetInventorySpaceForQuest(batchSize + 2)
								ok, result = H.invokeOpenCrates(slot, batchSize)
							end
							if not ok or not result then
								return false
							end
						end

						if S.autoQuestDeleteRewards then
							H.deleteAllNewCrateRewards(slot, beforeKeys)
						end

						return true
					end

					function H.tryMakeChestOpenSpace(itemType)
						local constants = H.getSharedConstants()
						if not constants then
							return false
						end

						local inventory = itemType == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
						local maxInventory = itemType == "weapon" and constants.WPN_MAX_INVENTORY or constants.SKN_MAX_INVENTORY
						local inventorySize = H.getInventorySizeForItemType(itemType)
						if not inventory or not maxInventory or not inventorySize or inventorySize < maxInventory then
							return false
						end

						local toSell = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and (entry.id or entry.ID) then
								table.insert(toSell, tostring(key))
								if #toSell >= 3 then
									break
								end
							end
						end

						if #toSell == 0 then
							return false
						end

						return H.invokeSellInventoryItems(itemType, toSell)
					end

					function H.tryAutoQuestOpenChestBurst()
						local openedAny = false
						for _, itemType in ipairs({ "weapon", "skin" }) do
							local crateKey = H.getNextChestKeyForItemType(itemType)
							if not crateKey or H.getChestCount(crateKey) <= 0 then
								continue
							end

							if not H.canOpenCrateKey(crateKey) then
								H.tryMakeChestOpenSpace(itemType)
							end

							local batch = H.getInventoryChestBatchSize(crateKey)
							if batch <= 0 then
								continue
							end

							local inventory = itemType == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
							local beforeKeys = {}
							if type(inventory) == "table" then
								for key in pairs(inventory) do
									beforeKeys[tostring(key)] = true
								end
							end

							local ok = H.invokeOpenChests(crateKey, batch)
							if ok then
								openedAny = true
								if S.autoQuestDeleteRewards then
									H.deleteNewInventoryItems(itemType, beforeKeys)
								end
							end
						end
						return openedAny
					end

					function H.isAutoQuestComplete(state, goal, current)
						if state and state.completed then
							return true
						end
						if state and state.objectives then
							local hasObjectives = false
							for _, objective in ipairs(state.objectives) do
								hasObjectives = true
								if not objective.done then
									return false
								end
							end
							if hasObjectives then
								return true
							end
						end
						return goal ~= nil and current ~= nil and goal > 0 and current >= goal
					end

					function H.invokeEndQuestRequest()
						local response = H.callGameService("EndQuestRequest")
						if response ~= nil then
							return response
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						local gameService = services and services:FindFirstChild("GameService")
						local remote = gameService and gameService:FindFirstChild("EndQuestRequest")
						if remote and remote:IsA("RemoteFunction") then
							return remote:InvokeServer()
						end

						return nil
					end

					function H.invokeStartQuestRequest()
						local response = H.callGameService("StartQuestRequest")
						if response ~= nil then
							return response
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						local gameService = services and services:FindFirstChild("GameService")
						local remote = gameService and gameService:FindFirstChild("StartQuestRequest")
						if remote and remote:IsA("RemoteFunction") then
							return remote:InvokeServer()
						end

						return nil
					end

					function H.fireQuestTalkButton()
						local gui = player:FindFirstChild("PlayerGui")
						local talkGui = gui and gui:FindFirstChild("TalkGui")
						local talkBtn = talkGui and talkGui:FindFirstChild("TalkBtn")
						if not talkBtn then
							return false
						end

						local ok = pcall(function()
							talkBtn.Activated:Fire()
						end)
						return ok
					end

					function H.tryAutoQuestTalkTurnIn(state)
						local questController = H.getQuestController()
						if not questController then
							return false
						end

						task.wait(0.15)
						if not H.getActiveQuestKey() then
							return true
						end

						local ok = pcall(function()
							if questController.CompleteQuest then
								questController:CompleteQuest()
							end
						end)
						if ok then
							task.wait(0.2)
							return not H.getActiveQuestKey()
						end

						return false
					end

					function H.tryAutoQuestTurnIn(state)
						local questKey = state and state.key or H.getActiveQuestKey()
						if H.isNewbieQuestKey(questKey) then
							return false
						end

						for attempt = 1, 12 do
							if questKey then
								local freshState = H.getQuestState(questKey)
								if freshState then
									state = freshState
								end
							end

							if not H.isAutoQuestComplete(state) then
								return false
							end

							H.setStatus("Auto quest: turning in...")
							H.fireQuestTalkButton()

							local questController = H.getQuestController()
							if questController and questController.CompleteQuest then
								pcall(function()
									questController:CompleteQuest()
								end)
							end

							H.invokeEndQuestRequest()
							task.wait(0.05)

							if not H.getActiveQuestKey() then
								if questController and questController.ResetActiveQuest then
									pcall(function()
										questController:ResetActiveQuest()
									end)
								end
								return true
							end
						end

						if H.tryAutoQuestTalkTurnIn(state) then
							return true
						end

						return not H.getActiveQuestKey()
					end

					function H.tryHandlePendingQuestTurnIn()
						local questKey = H.getActiveQuestKey()
						if not questKey or H.isNewbieQuestKey(questKey) then
							return false
						end

						local state = H.getQuestState(questKey)
						if not state or not H.isAutoQuestComplete(state) then
							return false
						end

						return H.tryAutoQuestTurnIn(state)
					end

					function H.waitForQuestInactive(timeoutSeconds)
						local deadline = os.clock() + (timeoutSeconds or 3)
						while os.clock() < deadline do
							if not H.getActiveQuestKey() then
								return true
							end
							task.wait(0.05)
						end
						return not H.getActiveQuestKey()
					end

					function H.runAutoQuestCycle()
						while S.autoQuestRunning do
							local ok, err = pcall(function()
								H.setAutoQuestNoCollide(false)

								if H.tryHandlePendingQuestTurnIn() then
									H.waitForQuestInactive(3)
									H.invokeStartQuestRequest()
									H.resetAutoQuestProgressCounters()
									S.autoQuestLastKind = nil
									S.autoQuestLastTarget = nil
									S.autoQuestLastQuestKey = nil
									S.autoQuestEggAreaReady = false
									task.wait(0.2)
									return
								end

								local kind, targetKey, goal, current, hasFraction, questKey, state = H.parseActiveQuest()
								if not kind then
									H.setStatus("Auto quest: waiting for quest data...")
									local waitedKey = H.waitForActiveQuestKey(3)
									if waitedKey then
										local waitedState = H.getQuestState(waitedKey)
										if waitedState and waitedState.completed and not H.isNewbieQuestKey(waitedKey) then
											if H.tryAutoQuestTurnIn(waitedState) then
												H.waitForQuestInactive(3)
											end
											return
										end
										kind, targetKey, goal, current, hasFraction, questKey, state = H.parseActiveQuest()
									end
								end

								if not kind then
									H.setStatus("Auto quest: starting quest...")
									H.invokeStartQuestRequest()
									task.wait(0.8)
									return
								end

							if S.autoQuestLastQuestKey ~= questKey or S.autoQuestLastTarget ~= targetKey then
								local previousKey = S.autoQuestLastQuestKey
								if S.autoQuestLastKind == "Fishing" and kind ~= "Fishing" then
									H.leaveFishingZone()
								end
								if S.autoQuestLastKind == "Boss" and kind ~= "Boss" then
									H.cleanupAutoQuestBossFight()
								end
								if S.autoQuestLastKind == "ArenaKill" and kind ~= "ArenaKill" then
									if S.autoQuestEnabledKill and H.setAutoKill then
										H.setAutoKill(false, false)
										S.autoQuestEnabledKill = false
									end
								end
								if S.autoQuestLastKind == "Orb" and kind ~= "Orb" then
									S.autoQuestOrbGroundReady = false
								end
								if kind == "Orb" then
									S.autoQuestOrbGroundReady = false
								end
								if previousKey == "dungeon_boss_quest" and questKey == "egg_collection_quest" then
									H.teleportCharacterTo(AUTO_QUEST_EGG_TELEPORT)
									task.wait(1)
									if kind == "Egg" then
										S.autoQuestEggAreaReady = true
									end
								end
								S.autoQuestLastKind = kind
								S.autoQuestLastTarget = targetKey
								S.autoQuestLastQuestKey = questKey
								H.resetAutoQuestProgressCounters()
								if questKey ~= "egg_collection_quest" or previousKey ~= "dungeon_boss_quest" then
									S.autoQuestEggAreaReady = false
								end
							end

							if questKey and not H.isNewbieQuestKey(questKey) then
								local freshState = H.getQuestState(questKey)
								if freshState then
									state = freshState
									local objective = H.getPrimaryQuestObjective(state)
									if objective then
										goal = objective.goal
										current = objective.progress
									end
								end
							elseif state and state.objectives then
								if H.isNewbieQuestKey(questKey) then
									local _, _, refreshedGoal, refreshedCurrent, _, _, refreshedState = H.parseNewbieQuest()
									if refreshedState then
										state = refreshedState
										goal = refreshedGoal or goal
										current = refreshedCurrent or current
									end
								else
									local objective = H.getPrimaryQuestObjective(state)
									if objective then
										goal = objective.goal
										current = objective.progress
									end
								end
							end

							if H.isAutoQuestComplete(state, goal, current) then
								H.setStatus("Auto quest: completing...")
								if kind == "Fishing" then
									H.leaveFishingZone()
								end
								if kind == "Boss" then
									H.cleanupAutoQuestBossFight()
								end
								H.restoreAutoQuestSubFeatures()
								if not H.isNewbieQuestKey(questKey) then
									H.tryAutoQuestTurnIn(state)
									H.waitForQuestInactive(3)
									H.invokeStartQuestRequest()
								else
									task.wait(0.3)
								end
								H.resetAutoQuestProgressCounters()
								S.autoQuestLastKind = nil
								S.autoQuestLastTarget = nil
								S.autoQuestLastQuestKey = nil
								S.autoQuestEggAreaReady = false
								task.wait(0.15)
								return
							end

							if kind == "QuestTurnIn" then
								H.setStatus("Auto quest: turning in...")
								local rotKey = questKey or H.getActiveQuestKey()
								if rotKey then
									local rotState = H.getQuestState(rotKey) or state
									if rotState and H.tryAutoQuestTurnIn(rotState) then
										H.waitForQuestInactive(3)
										H.invokeStartQuestRequest()
									end
								end
								task.wait(0.3)
							elseif kind == "Boss" then
								local def = H.getQuestBossDef(targetKey)
								if not def then
									task.wait(AUTO_QUEST_POLL)
								else
									local hum = H.getHumanoid()
									if not hum or hum.Health <= 0 then
										H.cleanupAutoQuestBossFight()
										H.setStatus("Auto quest: respawning...")
										H.waitForQuestRespawn(25)
									elseif not H.isBossAlive(def) then
										H.cleanupAutoQuestBossFight()
										S.autoQuestWasAttackingBoss = false
										H.ensureQuestBossWaitPosition(targetKey)
										H.setStatus("Auto quest: waiting for " .. targetKey .. " to spawn...")
										task.wait(0.4)
									else
										S.autoQuestBossWaitTpDone = false
										S.autoQuestWasAttackingBoss = true
										H.setStatus("Auto quest: fighting " .. targetKey)
										H.ensureWeaponEquipped(H.getPlayerController())
										H.ensureQuestBossSwing(true)

										if S.autoQuestBossFollowDefId ~= def.id or not S.autoQuestBossFollowConnection then
											H.startQuestBossFollow(def)
										end

										if not S.autoQuestBossSwingActive then
											H.backgroundTrainSwing()
										end

										task.wait(AUTO_BOSS_POLL)
									end
								end
							elseif kind == "Orb" then
								if not S.autoQuestOrbGroundReady then
									H.ensureOrbGroundTeleport()
									S.autoQuestOrbGroundReady = true
									task.wait(0.2)
								end
								local orbNode = H.findQuestOrbNode()
								if orbNode then
									H.setStatus(string.format("Auto quest: collecting orbs (%d/%d)", current, goal))
									H.tweenAutoQuestTo(orbNode)
									task.wait(0.2)
								else
									task.wait(0.5)
								end
							elseif kind == "Egg" then
								if not S.autoQuestEggAreaReady then
									H.teleportCharacterTo(AUTO_QUEST_EGG_TELEPORT)
									S.autoQuestEggAreaReady = true
									task.wait(1)
								end

								local egg = H.findQuestEgg()
								if egg then
									H.setStatus(string.format("Auto quest: collecting eggs (%d/%d)", current, goal))
									H.tweenAutoQuestTo(egg)
									if S.autoQuestRunning then
										S.autoQuestVisitedEggs[egg] = true
										task.delay(AUTO_QUEST_EGG_VISITED_TTL, function()
											S.autoQuestVisitedEggs[egg] = nil
										end)
										local waited = 0
										while egg.Parent and waited < 1 and S.autoQuestRunning do
											task.wait(0.1)
											waited = waited + 0.1
										end
										task.wait(0.2)
									end
								else
									task.wait(0.5)
								end
							elseif kind == "Fishing" then
								H.setStatus(string.format("Auto quest: fishing (%d/%d)", current, goal))
								if not S.autoFishRunning and H.setAutoFish then
									local fishingController = H.getFishingController()
									if fishingController and fishingController.RequestGoFish then
										pcall(function()
											fishingController:RequestGoFish()
										end)
										task.wait(0.5)
									end
									H.setAutoFish(true, false)
									S.autoQuestEnabledFish = true
								end
								task.wait(0.3)
							elseif kind == "Swing" then
								H.setStatus(string.format("Auto quest: swinging (%d/%d)", current, goal))
								if not S.clickerRunning and H.setAutoClicker then
									H.setAutoClicker(true, false)
									S.autoQuestEnabledClicker = true
								end
								task.wait(0.3)
							elseif kind == "Chest" then
								H.setStatus(string.format("Auto quest: opening chests (%d/%d)", current, goal))
								if H.tryAutoQuestOpenChestBurst() then
									task.wait(0.05)
								else
									task.wait(0.15)
								end
							elseif kind == "QuestAccept" then
								H.setStatus("Auto quest: accepting quest...")
								H.invokeStartQuestRequest()
								task.wait(0.1)
							elseif kind == "ItemEquip" then
								H.setStatus("Auto quest: equipping gear...")
								H.tryEquipQuestGear()
								task.wait(0.3)
							elseif kind == "PetEquip" then
								H.setStatus("Auto quest: equipping pet...")
								H.tryEquipQuestPet()
								task.wait(0.3)
							elseif kind == "Arena" or kind == "ArenaKill" then
								if kind == "ArenaKill" and not S.autoKillRunning and H.setAutoKill then
									H.setAutoKill(true, false)
									S.autoQuestEnabledKill = true
								end
								H.setStatus("Auto quest: joining arena...")
								H.tryJoinArenaForQuest()
								task.wait(0.5)
							elseif kind == "Upgrade" then
								H.setStatus(string.format("Auto quest: upgrading (%d/%d)", current, goal))
								if H.tryAutoUpgradeBurst() or H.tryMassUpgradeSkills() then
									task.wait(0.2)
								else
									task.wait(0.5)
								end
							elseif kind == "PetHatch" then
								H.setStatus(string.format("Auto quest: hatching pets (%d/%d)", current, goal))
								local remaining = math.max(1, (goal or 1) - (current or 0))
								H.tryAutoQuestOpenPetCrate(remaining)
							end
							end)

							if not ok then
								warn("[ExonHub] Auto quest step error:", err)
								task.wait(0.35)
							end
						end

						H.restoreAutoQuestSubFeatures()
						H.restoreCharacterMovementState()
					end

					function H.ensureAutoQuestLoopRunning()
						if S.autoQuestRunning and not S.autoQuestLoopActive then
							H.startAutoQuestLoop()
						end
					end

					function H.stopAutoQuestLoop()
						S.autoQuestRunning = false
						H.restoreAutoQuestSubFeatures()
						H.restoreCharacterMovementState()
					end

					function H.startAutoQuestLoop()
						if S.autoQuestLoopActive then
							return
						end
						S.autoQuestLoopActive = true
						S.autoQuestLastKind = nil
						S.autoQuestLastTarget = nil
						S.autoQuestLastQuestKey = nil
						S.autoQuestEggAreaReady = false
						H.resetAutoQuestProgressCounters()

						task.spawn(function()
							H.runAutoQuestCycle()
							S.autoQuestLoopActive = false
						end)
					end

					function H.tryKickBeachBall(ball, goalPart)
						if not ball or not goalPart then
							return false
						end

						H.setAutoGoalsKickBusy(true)

						local goals = {}
						for _, goal in pairs(H.collectBeachGoalsByName()) do
							table.insert(goals, goal)
						end

						S.autoGoalsLastKickBallName = ball.Name
						local goalModel = goalPart.Parent
						S.autoGoalsLastKickGoalName = goalModel and goalModel.Name or nil

						if H.shouldResetBeachBallForAutoGoal(ball, goals) then
							H.prepareBeachBallForAutoGoal(ball)
						else
							H.zeroBeachBallVelocity(ball)
						end

						local confirmed = false

						local ok, kickErr = pcall(function()
							if H.touchBeachBallForAutoGoal(ball) then
								task.wait(AUTO_GOALS_AFTER_TOUCH_DELAY)
								H.restoreSingleBeachBallCollision(ball)
								H.zeroBeachBallVelocity(ball)
								if H.kickBeachBallAfterTouch(ball, goalPart) then
									task.wait(AUTO_GOALS_POST_KICK_SETTLE)
									if H.slideBeachBallIntoGoal(ball, goalPart) then
										local timeout = AUTO_GOALS_BALL_ATTEMPT_TIMEOUT
										if H.shouldAutoGoalsUseKothTouchPath() then
											timeout = timeout + 1.5
										end
										confirmed = H.waitForAutoGoalsServerConfirm(ball.Name, timeout)
									end
								end
							end
						end)

						H.restoreSingleBeachBallCollision(ball)
						H.setAutoGoalsKickBusy(false)

						if not ok then
							warn("[ExonHub] Auto goals kick error:", kickErr)
						end

						if confirmed then
							H.setStatus(ball.Name .. " goal confirmed")
							return true
						end

						H.prepareBeachBallForAutoGoal(ball)
						H.zeroBeachBallVelocity(ball)
						H.setStatus(ball.Name .. " timed out - retrying")
						return false
					end

					function H.runAutoGoalsCycle()
						H.ensureAutoGoalsGoalListener()
						H.applySilentTrainMode(true)

						if H.shouldAutoGoalsBringBallToPlayer() then
							H.setStatus("Auto goals: ball comes to you (fishing stand)")
						end

						while S.autoGoalsRunning do
							H.ensureAutoGoalsGoalListener()
							local goalsByName = H.collectBeachGoalsByName()
							local goals = {}
							for _, goalPart in pairs(goalsByName) do
								table.insert(goals, goalPart)
							end
							local balls = H.getBeachBalls()
							if #goals == 0 then
								H.setStatus("Beach goals not found")
								task.wait(1)
							elseif #balls == 0 then
								H.setStatus("Waiting for beach balls...")
								task.wait(AUTO_GOALS_POLL)
							else
								H.cacheBeachBallSpawns(balls)

								local pending = {}
								for _, ball in ipairs(balls) do
									if H.shouldAutoGoalsTargetBall(ball, goals) then
										table.insert(pending, ball)
									end
								end

							if #pending == 0 then
								H.setStatus("All beach balls scored â€” waiting for respawn")
								task.wait(AUTO_GOALS_POLL)
							else
								local ordered = H.orderBeachBallsFixed(pending)
								local acted = false

								for _, ball in ipairs(ordered) do
									if not S.autoGoalsRunning then
										break
									end
									if not H.shouldSkipBeachBallKick(ball, goalsByName, balls) then
										local goalPart = H.pickGoalForBeachBall(ball, goalsByName, balls)
										if goalPart then
											acted = true
											local goalName = goalPart.Parent and goalPart.Parent.Name or "goal"
											H.setStatus("Underground slide " .. ball.Name .. " to you, kick, rise into " .. goalName)
											H.tryKickBeachBall(ball, goalPart)
										end
									end
								end

								if not acted then
									H.setStatus("Waiting for next ball...")
									task.wait(AUTO_GOALS_POLL)
								end
							end
							end
						end
					end

					function H.stopAutoGoalsLoop()
						S.autoGoalsRunning = false
						S.autoGoalsScoredBalls = {}
						S.autoGoalsLastKickBallName = nil
						S.autoGoalsLastKickGoalName = nil
						S.autoGoalsKickBusy = false
						S.autoGoalsLastGoalConfirmAt = 0
						S.autoGoalsLastGoalConfirmBall = nil
						H.teardownAutoGoalsGoalListener()
						H.teardownAutoGoalsBallCollision()
						H.applySilentTrainMode(false)
					end

					function H.startAutoGoalsLoop()
						if S.autoGoalsLoopActive then
							return
						end
						S.autoGoalsLoopActive = true

						task.spawn(function()
							H.runAutoGoalsCycle()
							S.autoGoalsLoopActive = false
						end)
					end

					function H.getPlayerLevel()
						return H.getStatValue(H.getClientStats(), "level")
					end

					function H.canAutoRebirthNow()
						local level = H.getPlayerLevel()
						if level < MIN_REBIRTH_TARGET_LEVEL then
							return false
						end
						return level >= S.autoRebirthTargetLevel
					end

					function H.invokeRebirthRequest()
						local aero = H.getGlobal().Aero
						if aero and aero.Services and aero.Services.GameService and aero.Services.GameService.RebirthRequest then
							return pcall(function()
								aero.Services.GameService:RebirthRequest()
							end)
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						local gameService = services and services:FindFirstChild("GameService")
						local remote = gameService and gameService:FindFirstChild("RebirthRequest")
						if remote and remote:IsA("RemoteFunction") then
							return pcall(function()
								remote:InvokeServer()
							end)
						end

						return false, "RebirthRequest unavailable"
					end

					function H.tryAutoRebirth()
						if not H.canAutoRebirthNow() then
							return false
						end

						local now = os.clock()
						if now - S.lastRebirthAttemptAt < REBIRTH_ATTEMPT_COOLDOWN then
							return false
						end
						S.lastRebirthAttemptAt = now

						local ok, err = H.invokeRebirthRequest()
						if ok then
							print("[ExonHub] RebirthRequest sent (level", H.getPlayerLevel(), "target", S.autoRebirthTargetLevel .. ")")
							H.setStatus("Rebirth requested")
							H.onPlayerRebirthDetected()
						else
							warn("[ExonHub] RebirthRequest failed:", err)
							H.setStatus("Rebirth failed")
						end
						return ok
					end

					function H.stopAutoRebirthLoop()
						S.autoRebirthRunning = false
						H.teardownAutoRebirthLevelListener()
					end

					function H.teardownAutoRebirthLevelListener()
						if S.autoRebirthLevelConn then
							S.autoRebirthLevelConn:Disconnect()
							S.autoRebirthLevelConn = nil
						end
					end

					function H.ensureAutoRebirthLevelListener()
						if S.autoRebirthLevelConn then
							return
						end

						local stats = H.getClientStats()
						local levelValue = stats and stats:FindFirstChild("level")
						if not levelValue then
							return
						end

						S.autoRebirthLevelConn = levelValue.Changed:Connect(function()
							if S.autoRebirthRunning and H.canAutoRebirthNow() then
								H.tryAutoRebirth()
							end
						end)
					end

					function H.startAutoRebirthLoop()
						if S.autoRebirthLoopActive then
							return
						end
						S.autoRebirthLoopActive = true

						task.spawn(function()
							for _ = 1, 30 do
								if H.getClientStats() then
									break
								end
								task.wait(0.5)
							end

							while S.autoRebirthRunning do
								if H.canAutoRebirthNow() then
									H.tryAutoRebirth()
								end
								task.wait(REBIRTH_POLL_INTERVAL)
							end

							S.autoRebirthLoopActive = false
						end)
					end

					local WEAPON_CRATE_KEYS = { "t1_wpn_crate", "t2_wpn_crate", "t3_wpn_crate" }
					local SKIN_CRATE_KEYS = { "t1_skin_crate", "t2_skin_crate", "t3_skin_crate" }
					local ALL_CRATE_KEYS = {
						WEAPON_CRATE_KEYS[1],
						SKIN_CRATE_KEYS[1],
						WEAPON_CRATE_KEYS[2],
						SKIN_CRATE_KEYS[2],
						WEAPON_CRATE_KEYS[3],
						SKIN_CRATE_KEYS[3],
					}
					local TIER_KEY_ORDER = {
						{ weapon = "t3_wpn_crate", skin = "t3_skin_crate" },
						{ weapon = "t2_wpn_crate", skin = "t2_skin_crate" },
						{ weapon = "t1_wpn_crate", skin = "t1_skin_crate" },
					}
					local AUTO_OPEN_IDLE_WAIT = 0
					local AUTO_OPEN_BUSY_FAILS = 1000
					local AUTO_OPEN_DELETE_POLL = 0
					local AUTO_OPEN_DELETE_TRIES = 120
					local AUTO_OPEN_BATCH_SIZE = 3

					function H.getClientChests()
						local gui = player:FindFirstChild("PlayerGui")
						local clientData = gui and gui:FindFirstChild("ClientData")
						return clientData and clientData:FindFirstChild("chests") or nil
					end

					function H.getChestCount(crateKey)
						local chests = H.getClientChests()
						if not chests then
							return 0
						end
						local valueObj = chests:FindFirstChild(crateKey)
						if valueObj and typeof(valueObj.Value) == "number" then
							return valueObj.Value
						end
						return 0
					end

					function H.hasCratesToSell()
						for _, crateKey in ipairs(ALL_CRATE_KEYS) do
							if H.getChestCount(crateKey) > 0 then
								return true
							end
						end
						return false
					end

					function H.invokeSellAllCrates(crateKey)
						local aero = H.getGlobal().Aero
						if aero and aero.Services and aero.Services.GameService and aero.Services.GameService.SellAllCratesRequest then
							return pcall(function()
								return aero.Services.GameService:SellAllCratesRequest(crateKey)
							end)
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						local gameService = services and services:FindFirstChild("GameService")
						local remote = gameService and gameService:FindFirstChild("SellAllCratesRequest")
						if remote and remote:IsA("RemoteFunction") then
							return pcall(function()
								return remote:InvokeServer(crateKey)
							end)
						end

						return false, "SellAllCratesRequest unavailable"
					end

					function H.trySellAllCrates()
						if not H.hasCratesToSell() then
							return false
						end

						local soldAny = false
						for _, crateKey in ipairs(ALL_CRATE_KEYS) do
							if H.getChestCount(crateKey) > 0 then
								local ok, result = H.invokeSellAllCrates(crateKey)
								if ok and result ~= false then
									soldAny = true
								end
							end
						end

						return soldAny
					end

					function H.stopAutoSellChestLoop()
						S.autoSellChestRunning = false
					end

					function H.startAutoSellChestLoop()
						if S.autoSellChestLoopActive then
							return
						end
						S.autoSellChestLoopActive = true

						task.spawn(function()
							for _ = 1, 30 do
								if H.getClientChests() then
									break
								end
								task.wait(0.5)
							end

							while S.autoSellChestRunning do
								if H.hasCratesToSell() then
									local ok = H.trySellAllCrates()
									if ok then
										H.setStatus("Sold weapon/skin crates")
									end
								end
								task.wait(AUTO_SELL_CHEST_INTERVAL)
							end

							S.autoSellChestLoopActive = false
						end)
					end

					function H.getCratesModule()
						if C.crates then
							return C.crates
						end
						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local cratesScript = sharedFolder and sharedFolder:FindFirstChild("Crates")
						if not cratesScript then
							return nil
						end
						local ok, mod = pcall(require, cratesScript)
						if ok and mod then
							C.crates = mod
							return mod
						end
						return nil
					end

					function H.getChestInventoryController()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers then
							return aero.Controllers.ChestInventoryController
						end
						return nil
					end

					function H.getInventorySizeForItemType(itemType)
						local aero = H.getGlobal().Aero
						if not aero or not aero.Controllers then
							return nil
						end
						if itemType == "weapon" then
							local weaponController = aero.Controllers.WeaponInventoryController
							if weaponController and weaponController.GetInventorySize then
								return weaponController:GetInventorySize()
							end
						elseif itemType == "skin" then
							local skinController = aero.Controllers.SkinInventoryController
							if skinController and skinController.GetInventorySize then
								return skinController:GetInventorySize()
							end
						end
						return nil
					end

					function H.getNextChestKeyForItemType(itemType)
						local wantWeapon = itemType == "weapon"
						for _, tier in ipairs(TIER_KEY_ORDER) do
							local crateKey = wantWeapon and tier.weapon or tier.skin
							if H.getChestCount(crateKey) > 0 and H.canOpenCrateKey(crateKey) then
								return crateKey
							end
						end
						return nil
					end

					function H.getNextChestKeyLocal()
						-- Prefer alternating types, but type-specific openers are the main path now
						local crates = H.getCratesModule()
						local weaponType = crates and crates.ItemType and crates.ItemType.WEAPON or "weapon"
						if S.autoOpenLastChestType ~= weaponType then
							return H.getNextChestKeyForItemType("weapon") or H.getNextChestKeyForItemType("skin")
						end
						return H.getNextChestKeyForItemType("skin") or H.getNextChestKeyForItemType("weapon")
					end

					function H.canOpenCrateKey(crateKey)
						local crates = H.getCratesModule()
						local constants = H.getSharedConstants()
						local crateData = crates and crates.Data and crates.Data[crateKey]
						if not crateData or not constants then
							return true
						end

						local itemType = crateData.ItemType
						local inventorySize = H.getInventorySizeForItemType(itemType)
						if not inventorySize then
							return true
						end

						local maxInventory = itemType == constants.ItemType.WEAPON and constants.WPN_MAX_INVENTORY
							or constants.SKN_MAX_INVENTORY
						if maxInventory and inventorySize >= maxInventory then
							return false
						end

						return true
					end

					function H.getUIController()
						local aero = H.getGlobal().Aero
						return aero and aero.Controllers and aero.Controllers.UIController or nil
					end

					function H.getCrateOpenUIController()
						local aero = H.getGlobal().Aero
						return aero and aero.Controllers and aero.Controllers.CrateOpenUIController or nil
					end

					function H.getAutoOpenBatchSize(ownedCount)
						local owned = math.max(0, math.floor(tonumber(ownedCount) or 0))
						if owned <= 0 then
							return 0
						end
						return math.min(AUTO_OPEN_BATCH_SIZE, owned)
					end

					function H.buildWorldCrateZapArgs(slot)
						if not slot then
							return nil
						end
						if slot.kind == "pet" then
							return { kind = "pet", id = slot.index }
						end
						if slot.kind == "artifact" then
							return { kind = "artifact", id = slot.index }
						end
						if slot.kind == "legendary" or slot.kind == "mythic" then
							local prefix = slot.itemType == "weapon" and "wpn" or "skin"
							local tier = slot.kind == "legendary" and "legendary" or "mythic"
							return { kind = prefix .. "_" .. tier, id = 0 }
						end
						return nil
					end

					function H.getWorldCrateAutosellIdx()
						return 1
					end

					function H.getAffordableCrateBatchSize(slot, maxBatch)
						local cost, currency = H.getCaveCrateCostInfo(slot)
						if not cost or not currency then
							return 0
						end
						local affordable = math.floor(H.getCurrencyAmount(currency) / cost)
						local batch = math.min(maxBatch or AUTO_OPEN_BATCH_SIZE, math.max(affordable, 0))
						if batch <= 0 then
							return 0
						end

						if slot.kind == "legendary" or slot.kind == "mythic" then
							local constants = H.getSharedConstants()
							local inventorySize = H.getInventorySizeForItemType(slot.itemType)
							local maxInventory = slot.itemType == "weapon" and constants and constants.WPN_MAX_INVENTORY
								or constants and constants.SKN_MAX_INVENTORY
							if inventorySize and maxInventory then
								local space = maxInventory - inventorySize
								if space <= 0 then
									return 0
								end
								batch = math.min(batch, space)
							end
						end

						return batch
					end

					function H.getInventoryChestBatchSize(crateKey)
						local count = H.getAutoOpenBatchSize(H.getChestCount(crateKey))
						if count <= 0 then
							return 0
						end

						local crates = H.getCratesModule()
						local constants = H.getSharedConstants()
						local crateData = crates and crates.Data and crates.Data[crateKey]
						if crateData and constants then
							local itemType = crateData.ItemType
							local inventorySize = H.getInventorySizeForItemType(itemType)
							local maxInventory = itemType == constants.ItemType.WEAPON and constants.WPN_MAX_INVENTORY
								or constants.SKN_MAX_INVENTORY
							if inventorySize and maxInventory then
								local space = maxInventory - inventorySize
								if space <= 0 then
									return 0
								end
								count = math.min(count, space)
							end
						end

						return count
					end

					function H.invokeOpenChests(crateKey, count)
						local zap = H.getZapClient()
						if not zap or not zap.OpenChests or not zap.OpenChests.Call then
							return false, nil
						end

						local batchCount = count or H.getInventoryChestBatchSize(crateKey)
						if batchCount <= 0 then
							return false, nil
						end

						local ok, result = pcall(function()
							return zap.OpenChests.Call({
								crate = crateKey,
								count = batchCount,
							})
						end)
						H.flushZapClient()

						if not ok or not result or result.status ~= "ok" or not result.results or #result.results == 0 then
							return false, result
						end

						return true, result
					end

					function H.invokeOpenCrates(slot, count)
						local zapArgs = H.buildWorldCrateZapArgs(slot)
						if not zapArgs then
							return false, nil
						end

						local zap = H.getZapClient()
						if not zap or not zap.OpenCrates or not zap.OpenCrates.Call then
							return false, nil
						end

						local batchCount = count or H.getAffordableCrateBatchSize(slot, AUTO_OPEN_BATCH_SIZE)
						if batchCount <= 0 then
							return false, nil
						end

						local ok, result = pcall(function()
							return zap.OpenCrates.Call({
								kind = zapArgs.kind,
								id = zapArgs.id,
								count = batchCount,
								autosellIdx = H.getWorldCrateAutosellIdx(),
							})
						end)
						H.flushZapClient()

						local responseOk = H.getServerResponseOk()
						if not ok or not result or result.res ~= responseOk or not result.results or #result.results == 0 then
							return false, result
						end

						return true, result
					end

					function H.setCratePopupSuppressed(suppressed)
						local aero = H.getGlobal().Aero
						local hud = aero and aero.Controllers and aero.Controllers.HUDController
						local ui = H.getUIController()

						if hud and hud.StartCratePopup then
							if suppressed then
								if not C.originalStartCratePopup then
									C.originalStartCratePopup = hud.StartCratePopup
									hud.StartCratePopup = function() end
								end
							elseif C.originalStartCratePopup then
								hud.StartCratePopup = C.originalStartCratePopup
								C.originalStartCratePopup = nil
							end
						end

						if ui and ui.ShowChestReveal then
							if suppressed then
								if not C.originalShowChestReveal then
									C.originalShowChestReveal = ui.ShowChestReveal
									ui.ShowChestReveal = function(_, payload)
										if payload and payload.onClosed then
											task.spawn(payload.onClosed)
										end
									end
								end
							elseif C.originalShowChestReveal then
								ui.ShowChestReveal = C.originalShowChestReveal
								C.originalShowChestReveal = nil
							end
						end
					end

					function H.warmAutoOpenCache()
						H.getZapClient()
						H.getCratesModule()
						H.getSharedConstants()
						H.getChestInventoryController()
						H.getUIController()
					end

					function H.invokeOpenCrateFast(crateKey)
						local ok = H.invokeOpenChests(crateKey)
						return ok
					end

					function H.playCratePopup(itemType, itemId, crateKey)
						local aero = H.getGlobal().Aero
						local hud = aero and aero.Controllers and aero.Controllers.HUDController
						if not hud or not hud.StartCratePopup then
							return
						end

						local crates = H.getCratesModule()
						local mesh = crates and crates.Data and crates.Data[crateKey] and crates.Data[crateKey].Mesh
						if not mesh then
							return
						end

						pcall(function()
							hud:StartCratePopup(itemType, itemId, mesh, false)
						end)
					end

					function H.tryOpenOneCrateOfType(itemType)
						local crateKey = H.getNextChestKeyForItemType(itemType)
						if not crateKey or H.getChestCount(crateKey) <= 0 then
							return false
						end
						if not H.canOpenCrateKey(crateKey) then
							return false
						end
						if not H.invokeOpenCrateFast(crateKey) then
							return false
						end

						S.autoOpenLastChestType = itemType
						return true
					end

					function H.tryOpenOneCrate()
						-- Fallback single opener (kept for compatibility)
						return H.tryOpenOneCrateOfType("weapon") or H.tryOpenOneCrateOfType("skin")
					end

				function H.runAutoOpenChestTypeLoop(itemType)
					local idleFails = 0
					while S.autoOpenChestRunning do
						if not H.shouldMaxOutOpenChestType(itemType) then
							task.wait(MAX_OUT_POLL)
							continue
						end
						if H.tryOpenOneCrateOfType(itemType) then
							idleFails = 0
						else
							idleFails += 1
							if idleFails >= AUTO_OPEN_BUSY_FAILS then
								task.wait(AUTO_OPEN_IDLE_WAIT)
							end
						end
					end
				end

					function H.stopAutoOpenChestLoop()
						S.autoOpenChestRunning = false
						H.setCratePopupSuppressed(false)
					end

					function H.startAutoOpenChestLoop()
						if S.autoOpenChestLoopActive then
							return
						end
						S.autoOpenChestLoopActive = true

						task.spawn(function()
							for _ = 1, 30 do
								if H.getClientChests() then
									break
								end
								task.wait(0.5)
							end

							H.warmAutoOpenCache()
							H.setCratePopupSuppressed(true)

							-- Open sword/weapon and skin chests at the same time (independent remotes)
							local remaining = 2
							local function finishWorker()
								remaining -= 1
								if remaining <= 0 then
									H.setCratePopupSuppressed(false)
									S.autoOpenChestLoopActive = false
								end
							end

							task.spawn(function()
								H.runAutoOpenChestTypeLoop("weapon")
								finishWorker()
							end)
							task.spawn(function()
								H.runAutoOpenChestTypeLoop("skin")
								finishWorker()
							end)
						end)
					end

					local WORLD_CRATE_SLOTS = {
						{
							id = "legendary_weapon",
							kind = "legendary",
							itemType = "weapon",
							title = "Legendary Weapon",
							desc = "100,000 gold â€” Cave crate",
						},
						{
							id = "legendary_skin",
							kind = "legendary",
							itemType = "skin",
							title = "Legendary Skin",
							desc = "100,000 gold â€” Cave crate",
						},
						{
							id = "mythic_weapon",
							kind = "mythic",
							itemType = "weapon",
							title = "Mythic Weapon",
							desc = "30M gold â€” Temple crate",
						},
						{
							id = "mythic_skin",
							kind = "mythic",
							itemType = "skin",
							title = "Mythic Skin",
							desc = "10M gold â€” Temple crate",
						},
						{ id = "pet_1", kind = "pet", index = 1, title = "Pet 1", desc = "5,000 gold â€” Cave crate" },
						{ id = "pet_2", kind = "pet", index = 2, title = "Pet 2", desc = "25,000 gold â€” Cave crate" },
						{ id = "pet_3", kind = "pet", index = 3, title = "Pet 3", desc = "125,000 gold â€” Cave crate" },
						{ id = "pet_4", kind = "pet", index = 4, title = "Pet 4", desc = "1M gold â€” Cave crate" },
						{ id = "pet_5", kind = "pet", index = 5, title = "Pet 5", desc = "20M gold â€” Temple crate" },
						{ id = "artifact_1", kind = "artifact", index = 1, title = "Artifact 1", desc = "1,000 quest points â€” Temple crate" },
						{ id = "artifact_2", kind = "artifact", index = 2, title = "Artifact 2", desc = "10,000 quest points â€” Temple crate" },
						{ id = "artifact_3", kind = "artifact", index = 3, title = "Artifact 3", desc = "100,000 quest points â€” Temple crate" },
					}

					local SHELL_EGG_SLOTS = {
						{
							id = "shell_pet_egg",
							kind = "pet",
							index = 6,
							title = "Pet Egg",
							desc = "2,000 shells â€” Event pet egg",
						},
						{
							id = "shell_artifact_egg",
							kind = "artifact",
							index = 4,
							title = "Artifact Egg",
							desc = "5,000 shells â€” Event artifact egg",
						},
					}

					function H.getWorldCrateSlotsForKind(kind)
						local slots = {}
						for _, slot in ipairs(WORLD_CRATE_SLOTS) do
							if slot.kind == kind then
								table.insert(slots, slot)
							end
						end
						return slots
					end

					function H.isWorldCrateSlotActive(slot)
						return S.caveAutoOpenSlots[slot.id] == true
					end

					function H.stripRichText(text)
						if type(text) ~= "string" then
							return ""
						end
						local stripped = text:gsub("<[^>]+>", "")
						return (stripped:match("^%s*(.-)%s*$") or stripped)
					end

					function H.normalizeDropdownSelection(selected)
						if selected == nil then
							return {}
						end
						if type(selected) ~= "table" then
							return { tostring(selected) }
						end

						local out = {}
						for key, value in pairs(selected) do
							if type(key) == "number" and type(value) == "string" then
								table.insert(out, value)
							elseif type(key) == "string" and (value == true or value == key) then
								table.insert(out, key)
							elseif type(value) == "table" and type(value.Title) == "string" then
								table.insert(out, value.Title)
							end
						end

						table.sort(out)
						return out
					end

					function H.formatRollPercent(chance)
						local pct = (tonumber(chance) or 0) * 100
						if pct >= 10 then
							return string.format("%.0f", pct)
						elseif pct >= 1 then
							return string.format("%.1f", pct)
						end
						return string.format("%.2f", pct)
					end

					function H.colorToRichRgb(color)
						if typeof(color) == "Color3" then
							return string.format(
								"rgb(%d,%d,%d)",
								math.floor(color.R * 255 + 0.5),
								math.floor(color.G * 255 + 0.5),
								math.floor(color.B * 255 + 0.5)
							)
						end
						return "rgb(255,255,255)"
					end

					function H.getRarityColor(name)
						local constants = H.getSharedConstants()
						local colors = constants and constants.RarityColor
						return colors and colors[name] or nil
					end

					function H.inferRollDisplayColor(roll, dataEntry)
						if roll and typeof(roll.Color) == "Color3" then
							return roll.Color
						end
						if dataEntry and typeof(dataEntry.Color) == "Color3" then
							return dataEntry.Color
						end
						if dataEntry and dataEntry.Rarity then
							local rarityColor = H.getRarityColor(dataEntry.Rarity)
							if rarityColor then
								return rarityColor
							end
						end

						local chance = roll and roll.Chance or 0
						if chance >= 0.2 then
							return H.getRarityColor("UNCOMMON") or Color3.fromRGB(0, 255, 127)
						elseif chance >= 0.1 then
							return H.getRarityColor("RARE") or Color3.fromRGB(0, 170, 255)
						elseif chance >= 0.05 then
							return H.getRarityColor("EPIC") or Color3.fromRGB(170, 0, 255)
						elseif chance >= 0.01 then
							return H.getRarityColor("LEGENDARY") or Color3.fromRGB(255, 200, 0)
						end
						return H.getRarityColor("MYTHIC") or Color3.fromRGB(210, 0, 0)
					end

					function H.buildRollOptionLabel(name, chance, color)
						local pctText = H.formatRollPercent(chance)
						local plainLabel = string.format("%s (%s%%)", name, pctText)
						local displayLabel = string.format(
							'%s <font color="%s">(%s%%)</font>',
							name,
							H.colorToRichRgb(color),
							pctText
						)
						return plainLabel, displayLabel
					end

					function H.resolveRollOptionItemId(label, rollOptions)
						local stripped = H.stripRichText(label)
						for _, opt in ipairs(rollOptions) do
							if label == opt.displayLabel or stripped == opt.plainLabel or stripped == opt.name then
								return opt.itemId
							end
						end
						for _, opt in ipairs(rollOptions) do
							if stripped:find(opt.name, 1, true) then
								return opt.itemId
							end
						end
						return nil
					end

					function H.getWorldCrateRollOptions(slot)
						local options = {}
						local seen = {}

						local function addFromRollTable(rollTable, dataModule)
							if not rollTable or not dataModule then
								return
							end
							for _, roll in ipairs(rollTable) do
								local itemId = roll.ItemId
								if itemId and not seen[itemId] then
									seen[itemId] = true
									local data = dataModule[itemId]
									local name = data and (data.DisplayName or data.Name) or ("Item " .. tostring(itemId))
									local chance = roll.Chance or 0
									local color = H.inferRollDisplayColor(roll, data)
									local plainLabel, displayLabel = H.buildRollOptionLabel(name, chance, color)
									table.insert(options, {
										name = name,
										itemId = itemId,
										chance = chance,
										color = color,
										plainLabel = plainLabel,
										displayLabel = displayLabel,
									})
								end
							end
						end

						if slot.kind == "pet" then
							local pets = H.getPetsModule()
							local crate = pets and pets.Crates and pets.Crates[slot.index]
							addFromRollTable(crate and crate.RollTable, pets and pets.Data)
						elseif slot.kind == "artifact" then
							local artifacts = H.getArtifactsModule()
							local crate = artifacts and artifacts.Crates and artifacts.Crates[slot.index]
							addFromRollTable(crate and crate.RollTable, artifacts and artifacts.Data)
						elseif slot.kind == "legendary" then
							local crates = H.getCratesModule()
							local pool = crates and crates.Legendary and crates.Legendary[slot.itemType]
							local dataMod = slot.itemType == "weapon" and H.getWeaponsModule() or H.getSkinsModule()
							addFromRollTable(pool and pool.RollTable, dataMod and dataMod.Data)
						elseif slot.kind == "mythic" then
							local crates = H.getCratesModule()
							local pool = crates and crates.Mythic and crates.Mythic[slot.itemType]
							local dataMod = slot.itemType == "weapon" and H.getWeaponsModule() or H.getSkinsModule()
							addFromRollTable(pool and pool.RollTable, dataMod and dataMod.Data)
						end

						return options
					end

					function H.setCrateAutoDeleteSelection(slotId, selected, rollOptions)
						S.crateAutoDeleteIds[slotId] = {}
						S.crateAutoDeleteLabels = S.crateAutoDeleteLabels or {}
						S.crateAutoDeleteLabels[slotId] = {}
						local normalized = H.normalizeDropdownSelection(selected)
						for _, label in ipairs(normalized) do
							table.insert(S.crateAutoDeleteLabels[slotId], label)
							local itemId = H.resolveRollOptionItemId(label, rollOptions)
							if itemId then
								local id = tonumber(itemId)
								S.crateAutoDeleteIds[slotId][id] = true
								S.crateAutoDeleteIds[slotId][tostring(id)] = true
							end
						end
						H.scheduleSettingsSave()
					end

					function H.hasCrateAutoDeleteEnabled(slotId)
						local deleteSet = S.crateAutoDeleteIds[slotId]
						if not deleteSet then
							return false
						end
						return next(deleteSet) ~= nil
					end

					function H.isInCrateDeleteSet(slotId, itemId)
						local deleteSet = S.crateAutoDeleteIds[slotId]
						if not deleteSet then
							return false
						end
						local id = tonumber(itemId)
						if not id then
							return false
						end
						return deleteSet[id] == true or deleteSet[tostring(id)] == true
					end

					function H.hasCrateHuntTargets(slotId)
						local targets = S.crateHuntTargets and S.crateHuntTargets[slotId]
						return type(targets) == "table" and next(targets) ~= nil
					end

					function H.resolveCrateRewardItemId(slot, reward, beforeKeys)
						if type(reward) == "number" then
							return tonumber(reward)
						end
						if type(reward) == "table" then
							local fromTable = tonumber(reward.ItemId or reward.itemId or reward.id or reward.ID)
							if fromTable then
								return fromTable
							end
							if reward.ItemType or reward.itemType then
								local typed = tonumber(reward.ItemType or reward.itemType)
								if typed then
									return typed
								end
							end
						end

						local fromKey = H.getInventoryEntryItemId(slot, reward)
						if fromKey then
							return tonumber(fromKey)
						end

						if beforeKeys then
							local inventory = H.getCrateInventory(slot)
							if type(inventory) == "table" then
								for key, entry in pairs(inventory) do
									if type(entry) == "table" and not beforeKeys[tostring(key)] then
										local itemId = H.getCrateEntryItemId(slot, entry)
										if itemId then
											return tonumber(itemId)
										end
									end
								end
							end
						end

						return nil
					end

					function H.areCrateHuntTargetsComplete(slotId)
						local targets = S.crateHuntTargets and S.crateHuntTargets[slotId]
						if type(targets) ~= "table" or next(targets) == nil then
							return false
						end
						for _, entry in pairs(targets) do
							if type(entry) ~= "table" then
								return false
							end
							local needed = math.max(1, math.floor(tonumber(entry.needed) or 1))
							local obtained = math.max(0, math.floor(tonumber(entry.obtained) or 0))
							if obtained < needed then
								return false
							end
						end
						return true
					end

					function H.formatCrateHuntCompleteMessage(slot)
						local targets = S.crateHuntTargets and S.crateHuntTargets[slot.id]
						local parts = {}
						if type(targets) == "table" then
							for _, entry in pairs(targets) do
								if type(entry) == "table" then
									local label = H.stripRichText(entry.label or "item")
									local needed = math.max(1, math.floor(tonumber(entry.needed) or 1))
									table.insert(parts, string.format("%s x%d", label, needed))
								end
							end
						end
						table.sort(parts)
						if #parts == 0 then
							return "Hunt complete: " .. slot.title
						end
						return "Hunt complete: " .. table.concat(parts, ", ")
					end

					function H.applyCrateHuntProgress(slot, rewardItemId)
						if not (slot.kind == "legendary" or slot.kind == "mythic") then
							return false
						end
						if not H.hasCrateHuntTargets(slot.id) then
							return false
						end

						local itemId = tonumber(rewardItemId)
						if not itemId then
							return false
						end

						local targets = S.crateHuntTargets[slot.id]
						local entry = targets[tostring(itemId)] or targets[itemId]
						if type(entry) ~= "table" then
							return false
						end

						entry.obtained = math.max(0, math.floor(tonumber(entry.obtained) or 0)) + 1
						H.setStatus(
							string.format(
								"Hunt %s: %d/%d",
								H.stripRichText(entry.label or tostring(itemId)),
								entry.obtained,
								math.max(1, math.floor(tonumber(entry.needed) or 1))
							)
						)

						if H.areCrateHuntTargetsComplete(slot.id) then
							H.setCaveAutoOpenSlot(slot.id, false, false)
							H.setStatus(H.formatCrateHuntCompleteMessage(slot))
						end

						return true
					end

					function H.destroyExonHubQtyPrompt()
						local existing = playerGui:FindFirstChild("ExonHubQtyPrompt")
						if existing then
							pcall(function()
								existing:Destroy()
							end)
						end
						pcall(function()
							if typeof(gethui) == "function" then
								local hui = gethui()
								local old = hui and hui:FindFirstChild("ExonHubQtyPrompt")
								if old then
									old:Destroy()
								end
							end
						end)

						if UI.huntQtyTempInput then
							pcall(function()
								if UI.huntQtyTempInput.Destroy then
									UI.huntQtyTempInput:Destroy()
								elseif UI.huntQtyTempInput.InputFrame and UI.huntQtyTempInput.InputFrame.Destroy then
									UI.huntQtyTempInput.InputFrame:Destroy()
								end
							end)
							UI.huntQtyTempInput = nil
						end

						UI.huntQtyDialog = nil
						UI.huntQtyTextBox = nil
					end

					function H.isCrateHuntTargetItem(slotId, itemId)
						if not H.hasCrateHuntTargets(slotId) then
							return false
						end
						local id = tonumber(itemId)
						if not id then
							return false
						end
						local targets = S.crateHuntTargets[slotId]
						local entry = targets[tostring(id)] or targets[id]
						return type(entry) == "table"
					end

					function H.promptHuntQuantity(itemLabel, onConfirm, onCancel)
						H.destroyExonHubQtyPrompt()

						local done = false
						local qtyText = "1"
						local cleanLabel = H.stripRichText(itemLabel or "item")

						local function finish(confirmed)
							if done then
								return
							end
							done = true
							if UI.huntQtyTextBox then
								qtyText = tostring(UI.huntQtyTextBox.Text or qtyText)
							end
							H.destroyExonHubQtyPrompt()
							if confirmed then
								local amount = math.floor(tonumber(qtyText) or 1)
								if amount < 1 then
									amount = 1
								end
								if onConfirm then
									onConfirm(amount)
								end
							elseif onCancel then
								onCancel()
							end
						end

						local dialogShown = false
						if UI.window and UI.window.Dialog then
							local okDialog, dialog = pcall(function()
								return UI.window:Dialog({
									Title = "Auto Delete + Stop",
									Icon = "hash",
									Width = 360,
									Content = "How many of \""
										.. cleanLabel
										.. "\" do you want to keep?\nOther rolls are auto deleted. Auto open stops when reached.",
									Buttons = {
										{
											Title = "Cancel",
											Variant = "Tertiary",
											Callback = function()
												finish(false)
											end,
										},
										{
											Title = "Confirm",
											Variant = "Primary",
											Callback = function()
												finish(true)
											end,
										},
									},
								})
							end)

							if okDialog and dialog then
								dialogShown = true
								UI.huntQtyDialog = dialog

								local main = dialog.UIElements and dialog.UIElements.Main
								if main then
									local inputWrap = Instance.new("Frame")
									inputWrap.Name = "ExonHubHuntQtyWrap"
									inputWrap.BackgroundTransparency = 1
									inputWrap.Size = UDim2.new(1, 0, 0, 42)
									inputWrap.LayoutOrder = 3
									inputWrap.Parent = main

									local input = Instance.new("TextBox")
									input.Name = "QtyInput"
									input.Size = UDim2.new(1, -8, 0, 36)
									input.Position = UDim2.fromOffset(4, 3)
									input.BackgroundColor3 = Color3.fromRGB(35, 37, 48)
									input.BorderSizePixel = 0
									input.ClearTextOnFocus = false
									input.Font = Enum.Font.Gotham
									input.PlaceholderText = "1"
									input.Text = "1"
									input.TextColor3 = Color3.fromRGB(245, 245, 255)
									input.PlaceholderColor3 = Color3.fromRGB(140, 140, 160)
									input.TextSize = 16
									input.TextXAlignment = Enum.TextXAlignment.Center
									input.Parent = inputWrap

									local corner = Instance.new("UICorner")
									corner.CornerRadius = UDim.new(0, 10)
									corner.Parent = input

									UI.huntQtyTextBox = input
									task.defer(function()
										if input.Parent then
											input:CaptureFocus()
										end
									end)

									input.FocusLost:Connect(function(enterPressed)
										if enterPressed and not done then
											finish(true)
											if dialog.Close then
												pcall(function()
													dialog:Close()
												end)
											end
										end
									end)
								end
							end
						end

						if not dialogShown then
							warn("[ExonHub] WindUI Dialog unavailable for hunt quantity; using default 1")
							finish(true)
						end
					end

					function H.setCrateHuntSelection(slotId, selected, rollOptions, previousLabels)
						S.crateHuntTargets = S.crateHuntTargets or {}
						S.crateHuntLabels = S.crateHuntLabels or {}

						local previous = previousLabels or H.getCrateHuntLabels(slotId)
						local previousSet = {}
						for _, label in ipairs(previous) do
							previousSet[label] = true
						end

						local normalized = H.normalizeDropdownSelection(selected)
						local nextLabels = {}
						local nextTargets = {}
						local existingTargets = S.crateHuntTargets[slotId] or {}
						local newlyAdded = {}

						for _, label in ipairs(normalized) do
							table.insert(nextLabels, label)
							local itemId = H.resolveRollOptionItemId(label, rollOptions)
							if itemId then
								local key = tostring(itemId)
								local prior = existingTargets[key]
								if type(prior) == "table" then
									nextTargets[key] = {
										label = label,
										needed = math.max(1, math.floor(tonumber(prior.needed) or 1)),
										obtained = math.max(0, math.floor(tonumber(prior.obtained) or 0)),
									}
								else
									nextTargets[key] = {
										label = label,
										needed = 1,
										obtained = 0,
									}
								end
								if not previousSet[label] then
									table.insert(newlyAdded, { label = label, itemId = itemId, key = key })
								end
							end
						end

						S.crateHuntLabels[slotId] = nextLabels
						S.crateHuntTargets[slotId] = nextTargets
						H.scheduleSettingsSave()

						local function promptNext(index)
							local added = newlyAdded[index]
							if not added then
								return
							end
							H.promptHuntQuantity(added.label, function(amount)
								local targets = S.crateHuntTargets[slotId]
								if targets and targets[added.key] then
									targets[added.key].needed = math.max(1, math.floor(tonumber(amount) or 1))
									targets[added.key].label = added.label
									H.scheduleSettingsSave()
								end
								promptNext(index + 1)
							end, function()
								local labels = {}
								for _, label in ipairs(S.crateHuntLabels[slotId] or {}) do
									if label ~= added.label then
										table.insert(labels, label)
									end
								end
								S.crateHuntLabels[slotId] = labels
								if S.crateHuntTargets[slotId] then
									S.crateHuntTargets[slotId][added.key] = nil
								end
								S.suppressSettingsDropdownSync = true
								H.setDropdownSelection(UI.crateHuntDropdowns[slotId], labels)
								S.suppressSettingsDropdownSync = false
								H.scheduleSettingsSave()
								promptNext(index + 1)
							end)
						end

						promptNext(1)
					end

					function H.getCrateInventory(slot)
						if slot.kind == "pet" then
							return H.getPetInventoryData()
						elseif slot.kind == "artifact" then
							return H.getArtifactInventoryData()
						elseif slot.kind == "legendary" or slot.kind == "mythic" then
							return slot.itemType == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
						end
						return nil
					end

					function H.snapshotInventoryKeys(slot)
						local keys = {}
						local inventory = H.getCrateInventory(slot)
						if type(inventory) ~= "table" then
							return keys
						end
						for key in pairs(inventory) do
							keys[tostring(key)] = true
						end
						return keys
					end

					function H.getCrateEntryItemId(slot, entry)
						if type(entry) ~= "table" then
							return nil
						end

						if slot.kind == "pet" then
							return H.resolvePetEntryType(entry)
						elseif slot.kind == "artifact" then
							return tonumber(entry.ID or entry.id)
						end

						return tonumber(entry.id)
					end

					function H.findNewRewardInventoryKey(slot, beforeKeys, itemId)
						local inventory = H.getCrateInventory(slot)
						local targetId = tonumber(itemId)
						if not inventory or not targetId then
							return nil
						end

						for key, entry in pairs(inventory) do
							if type(entry) == "table" and not beforeKeys[tostring(key)] then
								if tonumber(H.getCrateEntryItemId(slot, entry)) == targetId then
									return key
								end
							end
						end

						return nil
					end

					function H.isSellSuccess(response)
						if response == false or response == nil then
							return false
						end
						if response == true then
							return true
						end
						return H.isGameServiceOk(response)
					end

					function H.getPetsModule()
						if C.pets then
							return C.pets
						end
						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local petsScript = sharedFolder and sharedFolder:FindFirstChild("Pets")
						if not petsScript then
							return nil
						end
						local ok, mod = pcall(require, petsScript)
						if ok and mod then
							if mod.Init and not C.petsInited then
								local constants = H.getSharedConstants()
								local utilsScript = sharedFolder and sharedFolder:FindFirstChild("Utils")
								local utilsOk, utils = utilsScript and pcall(require, utilsScript)
								pcall(function()
									mod:Init({
										Shared = {
											SharedConstants = constants,
											Utils = utilsOk and utils or nil,
										},
									})
								end)
								C.petsInited = true
							end
							C.pets = mod
							return mod
						end
						return nil
					end

					function H.getArtifactsModule()
						if C.artifacts then
							return C.artifacts
						end
						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local artifactsScript = sharedFolder and sharedFolder:FindFirstChild("Artifacts")
						if not artifactsScript then
							return nil
						end
						local ok, mod = pcall(require, artifactsScript)
						if ok and mod then
							C.artifacts = mod
							return mod
						end
						return nil
					end

					function H.getGameService()
						local aero = H.getGlobal().Aero
						if aero and aero.Services and aero.Services.GameService then
							return aero.Services.GameService
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						return services and services:FindFirstChild("GameService") or nil
					end

					function H.callGameService(methodName, ...)
						local gameService = H.getGameService()
						if not gameService then
							return nil
						end

						if typeof(gameService[methodName]) == "function" then
							return gameService[methodName](gameService, ...)
						end

						local remote = gameService:FindFirstChild(methodName)
						if remote and remote:IsA("RemoteFunction") then
							return remote:InvokeServer(...)
						end

						return nil
					end

					function H.getServerResponseOk()
						local constants = H.getSharedConstants()
						return constants and constants.ServerResponse and constants.ServerResponse.OK or 0
					end

					function H.getCurrencyAmount(currencyKey)
						local stats = H.getClientStats()
						if not stats or not currencyKey then
							return 0
						end

						local statName = currencyKey
						local constants = H.getSharedConstants()
						local dataKeys = constants and constants.DataKeys
						if dataKeys then
							if currencyKey == dataKeys.GOLD then
								statName = "gold"
							elseif currencyKey == dataKeys.QUEST_POINTS then
								statName = "quest_points"
							elseif currencyKey == dataKeys.SHELLS then
								statName = "shells"
							end
						end

						return H.getStatValue(stats, statName)
					end

					function H.getCaveCrateCostInfo(slot)
						local constants = H.getSharedConstants()
						local dataKeys = constants and constants.DataKeys
						if not constants or not dataKeys then
							return nil
						end

						if slot.kind == "pet" then
							local pets = H.getPetsModule()
							local crate = pets and pets.Crates and pets.Crates[slot.index]
							if not crate then
								return nil
							end
							return crate.Cost, crate.Currency or dataKeys.GOLD
						elseif slot.kind == "artifact" then
							local artifacts = H.getArtifactsModule()
							local crate = artifacts and artifacts.Crates and artifacts.Crates[slot.index]
							if not crate then
								return nil
							end
							return crate.Cost, crate.Currency or dataKeys.QUEST_POINTS
						elseif slot.kind == "legendary" then
							local tierCosts = constants.WeaponTierCosts
							return tierCosts and tierCosts[4], dataKeys.GOLD
						elseif slot.kind == "mythic" then
							local crates = H.getCratesModule()
							local mythic = crates and crates.Mythic and crates.Mythic[slot.itemType]
							local tierCosts = constants.WeaponTierCosts
							local cost = mythic and mythic.Cost or (tierCosts and tierCosts[5])
							return cost, dataKeys.GOLD
						end

						return nil
					end

					function H.canOpenCaveCrateSlot(slot)
						if H.getAffordableCrateBatchSize(slot, 1) <= 0 then
							return false
						end

						if slot.kind == "legendary" or slot.kind == "mythic" then
							local constants = H.getSharedConstants()
							local inventorySize = H.getInventorySizeForItemType(slot.itemType)
							local maxInventory = slot.itemType == "weapon" and constants and constants.WPN_MAX_INVENTORY
								or constants and constants.SKN_MAX_INVENTORY
							if inventorySize and maxInventory and inventorySize >= maxInventory then
								return false
							end
						end

						return true
					end

					function H.handleCaveCrateOpenReward(slot, reward, beforeKeys)
						H.processCaveCrateOpenRewardsSync(slot, { reward }, beforeKeys)
					end

					function H.resolveCrateRewardSellKey(slot, reward, beforeKeys, claimedKeys)
						claimedKeys = claimedKeys or {}

						if type(reward) == "string" or type(reward) == "number" then
							local key = tostring(reward)
							if not beforeKeys[key] and not claimedKeys[key] then
								local inventory = H.getCrateInventory(slot)
								local entry = inventory and (inventory[reward] or inventory[key])
								if type(entry) == "table" then
									claimedKeys[key] = true
									return reward
								end
							end
						end

						local itemId = H.resolveCrateRewardItemId(slot, reward, beforeKeys)
						if not itemId then
							return nil
						end

						local inventory = H.getCrateInventory(slot)
						if type(inventory) ~= "table" then
							return nil
						end

						for key, entry in pairs(inventory) do
							local keyStr = tostring(key)
							if type(entry) == "table" and not beforeKeys[keyStr] and not claimedKeys[keyStr] then
								if tonumber(H.getCrateEntryItemId(slot, entry)) == tonumber(itemId) then
									claimedKeys[keyStr] = true
									return key
								end
							end
						end

						return nil
					end

					function H.processCaveCrateOpenRewardsSync(slot, rewards, beforeKeys)
						if type(rewards) ~= "table" or #rewards == 0 then
							return false
						end

						local claimedKeys = {}
						local weaponSkinDeletes = {}
						local otherDeletes = {}

						for _, reward in ipairs(rewards) do
							local rewardItemId = H.resolveCrateRewardItemId(slot, reward, beforeKeys)
							local sellKey = H.resolveCrateRewardSellKey(slot, reward, beforeKeys, claimedKeys)
							if sellKey then
								local keyStr = tostring(sellKey)
								beforeKeys[keyStr] = true
							end

							if slot.kind == "legendary" or slot.kind == "mythic" then
								if H.hasCrateHuntTargets(slot.id) then
									if H.isCrateHuntTargetItem(slot.id, rewardItemId) then
										H.applyCrateHuntProgress(slot, rewardItemId)
									elseif sellKey then
										table.insert(weaponSkinDeletes, tostring(sellKey))
									end
								elseif H.hasCrateAutoDeleteEnabled(slot.id)
									and rewardItemId
									and H.isInCrateDeleteSet(slot.id, rewardItemId)
									and sellKey
								then
									table.insert(weaponSkinDeletes, tostring(sellKey))
								end
							elseif H.hasCrateAutoDeleteEnabled(slot.id) and rewardItemId and H.isInCrateDeleteSet(slot.id, rewardItemId) and sellKey then
								table.insert(otherDeletes, sellKey)
							end
						end

						local deleted = false
						if #weaponSkinDeletes > 0 then
							deleted = H.invokeSellInventoryItems(slot.itemType, weaponSkinDeletes) or deleted
						end
						for _, sellKey in ipairs(otherDeletes) do
							if H.sellCrateReward(slot, sellKey) then
								deleted = true
							end
						end

						if deleted then
							H.setStatus("Auto deleted crate drop from " .. slot.title)
						end

						return deleted
					end

					function H.flushCrateSlotDeletes(slot)
						if not slot or (slot.kind ~= "legendary" and slot.kind ~= "mythic") then
							return false
						end

						local inventory = H.getCrateInventory(slot)
						if type(inventory) ~= "table" then
							return false
						end

						local toSell = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" then
								local itemId = H.getCrateEntryItemId(slot, entry)
								local shouldDelete = false
								if H.hasCrateHuntTargets(slot.id) then
									shouldDelete = itemId and not H.isCrateHuntTargetItem(slot.id, itemId)
								elseif H.hasCrateAutoDeleteEnabled(slot.id) then
									shouldDelete = itemId and H.isInCrateDeleteSet(slot.id, itemId)
								end
								if shouldDelete then
									table.insert(toSell, tostring(key))
								end
							end
						end

						if #toSell == 0 then
							return false
						end

						return H.invokeSellInventoryItems(slot.itemType, toSell)
					end

					function H.tryOpenCaveCrateSlot(slot)
						if H.hasCrateHuntTargets(slot.id) and H.areCrateHuntTargetsComplete(slot.id) then
							H.setCaveAutoOpenSlot(slot.id, false, false)
							return false
						end

						if slot.kind == "legendary" or slot.kind == "mythic" then
							if not H.canOpenCaveCrateSlot(slot) then
								H.flushCrateSlotDeletes(slot)
							end
						end

						local beforeKeys = H.snapshotInventoryKeys(slot)
						local batchSize = H.getAffordableCrateBatchSize(slot, AUTO_OPEN_BATCH_SIZE)
						if batchSize <= 0 then
							return false
						end

						local ok, result = H.invokeOpenCrates(slot, batchSize)
						if not ok or not result then
							return false
						end

						H.processCaveCrateOpenRewardsSync(slot, result.results, beforeKeys)

						if H.areCrateHuntTargetsComplete(slot.id) then
							H.setCaveAutoOpenSlot(slot.id, false, false)
							H.setStatus(H.formatCrateHuntCompleteMessage(slot))
						end

						return true
					end

					function H.hasAnyCaveAutoOpenEnabled()
						for _, slot in ipairs(WORLD_CRATE_SLOTS) do
							if H.isWorldCrateSlotActive(slot) then
								return true
							end
						end
						return false
					end

					function H.tryOpenEnabledCaveCrate()
						local openedAny = false
						local lastSlot = nil
						for _, slot in ipairs(WORLD_CRATE_SLOTS) do
							if H.isWorldCrateSlotActive(slot) and H.canOpenCaveCrateSlot(slot) then
								if H.tryOpenCaveCrateSlot(slot) then
									openedAny = true
									lastSlot = slot
								end
							end
						end
						return openedAny, lastSlot
					end

				function H.runCaveAutoOpenSlotLoop(slot)
					local idleFails = 0
					while H.isWorldCrateSlotActive(slot) do
						if H.hasCrateHuntTargets(slot.id) and H.areCrateHuntTargetsComplete(slot.id) then
							H.setCaveAutoOpenSlot(slot.id, false, false)
							break
						end
						if not H.shouldMaxOutOpenCaveSlot(slot) then
							task.wait(MAX_OUT_POLL)
							continue
						end
						if H.tryOpenCaveCrateSlot(slot) then
							idleFails = 0
						else
							if slot.kind == "legendary" or slot.kind == "mythic" then
								H.flushCrateSlotDeletes(slot)
							end
							idleFails += 1
							if idleFails >= AUTO_OPEN_BUSY_FAILS then
								task.wait(AUTO_OPEN_IDLE_WAIT)
							end
						end
					end
				end

					function H.startCaveAutoOpenLoop()
						if S.caveAutoOpenLoopActive then
							return
						end
						S.caveAutoOpenLoopActive = true

						task.spawn(function()
							for _ = 1, 30 do
								if H.getClientStats() then
									break
								end
								task.wait(0.5)
							end

							H.warmAutoOpenCache()
							H.getPetsModule()
							H.getArtifactsModule()

							-- One worker per enabled slot so pets/artifacts/legendary/mythic all open as fast as possible
							local workers = {}
							for _, slot in ipairs(WORLD_CRATE_SLOTS) do
								if H.isWorldCrateSlotActive(slot) then
									workers[slot.id] = true
									task.spawn(function()
										H.runCaveAutoOpenSlotLoop(slot)
										workers[slot.id] = nil
									end)
								end
							end

							while H.hasAnyCaveAutoOpenEnabled() do
								for _, slot in ipairs(WORLD_CRATE_SLOTS) do
									if H.isWorldCrateSlotActive(slot) and not workers[slot.id] then
										workers[slot.id] = true
										task.spawn(function()
											H.runCaveAutoOpenSlotLoop(slot)
											workers[slot.id] = nil
										end)
									end
								end
								task.wait(AUTO_OPEN_IDLE_WAIT)
							end

							S.caveAutoOpenLoopActive = false
						end)
					end

					function H.isShellEggSlotActive(slot)
						return S.autoOpenShellEggSlots[slot.id] == true
					end

					function H.hasAnyShellEggAutoOpenEnabled()
						for _, slot in ipairs(SHELL_EGG_SLOTS) do
							if H.isShellEggSlotActive(slot) then
								return true
							end
						end
						return false
					end

					function H.tryOpenEnabledShellEgg()
						local openedAny = false
						local lastSlot = nil
						for _, slot in ipairs(SHELL_EGG_SLOTS) do
							if H.isShellEggSlotActive(slot) and H.canOpenCaveCrateSlot(slot) then
								if H.tryOpenCaveCrateSlot(slot) then
									openedAny = true
									lastSlot = slot
								end
							end
						end
						return openedAny, lastSlot
					end

					function H.runShellEggAutoOpenSlotLoop(slot)
						local idleFails = 0
						while H.isShellEggSlotActive(slot) do
							if H.canOpenCaveCrateSlot(slot) and H.tryOpenCaveCrateSlot(slot) then
								idleFails = 0
							else
								idleFails += 1
								if idleFails >= AUTO_OPEN_BUSY_FAILS then
									task.wait(AUTO_OPEN_IDLE_WAIT)
								end
							end
						end
					end

					function H.startShellEggAutoOpenLoop()
						if S.shellEggAutoOpenLoopActive then
							return
						end
						S.shellEggAutoOpenLoopActive = true

						task.spawn(function()
							for _ = 1, 30 do
								if H.getClientStats() then
									break
								end
								task.wait(0.5)
							end

							H.getPetsModule()
							H.getArtifactsModule()

							local workers = {}
							for _, slot in ipairs(SHELL_EGG_SLOTS) do
								if H.isShellEggSlotActive(slot) then
									workers[slot.id] = true
									task.spawn(function()
										H.runShellEggAutoOpenSlotLoop(slot)
										workers[slot.id] = nil
									end)
								end
							end

							while H.hasAnyShellEggAutoOpenEnabled() do
								for _, slot in ipairs(SHELL_EGG_SLOTS) do
									if H.isShellEggSlotActive(slot) and not workers[slot.id] then
										workers[slot.id] = true
										task.spawn(function()
											H.runShellEggAutoOpenSlotLoop(slot)
											workers[slot.id] = nil
										end)
									end
								end
								task.wait(AUTO_OPEN_IDLE_WAIT)
							end

							S.shellEggAutoOpenLoopActive = false
						end)
					end

					function H.getPetInventoryData()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers and aero.Controllers.PetsUIController then
							local data = aero.Controllers.PetsUIController.Data
							if type(data) == "table" then
								return data
							end
						end
						if aero and aero.Services and aero.Services.GameDataService and aero.Services.GameDataService.GetPlayerPetsData then
							local ok, data = pcall(function()
								return aero.Services.GameDataService:GetPlayerPetsData(player)
							end)
							if ok and type(data) == "table" then
								return data
							end
						end
						return nil
					end

					function H.getArtifactInventoryData()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers and aero.Controllers.ArtifactsUIController then
							local data = aero.Controllers.ArtifactsUIController.Data
							if type(data) == "table" then
								return data
							end
						end
						if aero and aero.Services and aero.Services.GameDataService and aero.Services.GameDataService.GetPlayerArtifactsData then
							local ok, data = pcall(function()
								return aero.Services.GameDataService:GetPlayerArtifactsData(player)
							end)
							if ok and type(data) == "table" then
								return data
							end
						end
						return nil
					end

					function H.getInventoryEntryItemId(slot, rewardKey)
						if rewardKey == nil then
							return nil
						end

						if slot.kind == "pet" then
							local inventory = H.getPetInventoryData()
							local entry = inventory and (inventory[rewardKey] or inventory[tostring(rewardKey)])
							return entry and H.resolvePetEntryType(entry)
						elseif slot.kind == "artifact" then
							local inventory = H.getArtifactInventoryData()
							local entry = inventory and (inventory[rewardKey] or inventory[tostring(rewardKey)])
							return entry and tonumber(entry.ID or entry.id)
						elseif slot.kind == "legendary" or slot.kind == "mythic" then
							if type(rewardKey) == "number" then
								return rewardKey
							end
							local inventory = slot.itemType == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
							local entry = inventory and (inventory[rewardKey] or inventory[tostring(rewardKey)])
							return entry and tonumber(entry.id)
						end

						return type(rewardKey) == "number" and rewardKey or nil
					end

					function H.sellCrateReward(slot, rewardKey)
						if not rewardKey then
							return false
						end

						local key = tostring(rewardKey)
						if slot.kind == "pet" then
							return H.isSellSuccess(H.callGameService("SellPet", key))
						elseif slot.kind == "artifact" then
							return H.isSellSuccess(H.callGameService("SellArtifact", key))
						elseif slot.kind == "legendary" or slot.kind == "mythic" then
							local constants = H.getSharedConstants()
							local weaponType = constants and constants.ItemType and constants.ItemType.WEAPON or "weapon"
							return H.invokeSellInventoryItems(slot.itemType, { key })
						end

						return false
					end

					function H.tryAutoDeleteCrateRewardForced(slot, rewardItemId, beforeKeys, statusText)
						if not rewardItemId then
							return false
						end

						local sellKey = nil
						for i = 1, AUTO_OPEN_DELETE_TRIES do
							sellKey = H.findNewRewardInventoryKey(slot, beforeKeys, rewardItemId)
							if sellKey then
								break
							end
							if i < AUTO_OPEN_DELETE_TRIES then
								task.wait()
							end
						end

						if not sellKey then
							return false
						end

						if H.sellCrateReward(slot, sellKey) then
							H.setStatus(statusText or ("Auto deleted crate drop from " .. slot.title))
							return true
						end

						return false
					end

					function H.tryAutoDeleteCrateReward(slot, rewardItemId, beforeKeys)
						if not H.hasCrateAutoDeleteEnabled(slot.id) then
							return false
						end

						if not rewardItemId or not H.isInCrateDeleteSet(slot.id, rewardItemId) then
							return false
						end

						return H.tryAutoDeleteCrateRewardForced(
							slot,
							rewardItemId,
							beforeKeys,
							"Auto deleted crate drop from " .. slot.title
						)
					end

					function H.createWorldCrateAutoOpenToggle(section, slot)
						UI.caveAutoOpenToggles[slot.id] = section:Toggle({
							Title = "Auto Open " .. slot.title,
							Desc = slot.desc,
							Value = S.caveAutoOpenSlots[slot.id] == true,
							Callback = function(on)
								if S.suppressCaveAutoOpenSync then
									return
								end
								if H.setCaveAutoOpenSlot then
									H.setCaveAutoOpenSlot(slot.id, on == true, true)
								end
							end,
						})
					end

					function H.createShellEggAutoOpenToggle(section, slot)
						UI.shellEggAutoOpenToggles[slot.id] = section:Toggle({
							Title = "Auto Open " .. slot.title,
							Desc = slot.desc,
							Value = S.autoOpenShellEggSlots[slot.id] == true,
							Callback = function(on)
								if S.suppressAutoOpenShellEggSync then
									return
								end
								if H.setAutoOpenShellEggSlot then
									H.setAutoOpenShellEggSlot(slot.id, on == true, true)
								end
							end,
						})
					end

					function H.buildShellEggEventSection(tab, sectionTitle)
						local section = H.createStaticBoxSection(tab, sectionTitle, "solar:calendar-bold")
						for _, slot in ipairs(SHELL_EGG_SLOTS) do
							H.createShellEggAutoOpenToggle(section, slot)
							H.createWorldCrateDeletePicker(section, slot)
						end
						H.finalizeStaticSection(section)
					end

					function H.buildBeachGoalsEventSection(tab, sectionTitle)
						local section = H.createStaticBoxSection(tab, sectionTitle, "solar:football-bold")

						UI.autoFishToggleElement = section:Toggle({
							Title = "Auto Fish",
							Desc = "AFK fish at the beach stand",
							Value = false,
							Callback = function(on)
								if S.suppressAutoFishSync then
									return
								end
								if H.setAutoFish then
									H.setAutoFish(on == true, true)
								end
							end,
						})

						UI.autoUpgradeRodToggleElement = section:Toggle({
							Title = "Auto Upgrade Rod",
							Desc = "Buys the next rod you can afford (shells) and equips your best rod",
							Value = false,
							Callback = function(on)
								if S.suppressAutoUpgradeRodSync then
									return
								end
								if H.setAutoUpgradeRod then
									H.setAutoUpgradeRod(on == true, true)
								end
							end,
						})

						UI.autoGoalsToggleElement = section:Toggle({
							Title = "Auto Goals",
							Desc = "Beach soccer goals; with Auto Fish on, ball comes to you",
							Value = false,
							Callback = function(on)
								if S.suppressAutoGoalsSync then
									return
								end
								if H.setAutoGoals then
									H.setAutoGoals(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(section)
					end

					function H.buildKothEventSection(tab, sectionTitle)
						local section = H.createStaticBoxSection(tab, sectionTitle, "solar:crown-bold")

						UI.autoKothToggleElement = section:Toggle({
							Title = "Auto King of the Hill",
							Desc = "TP to Floor2, hold position (KOTHSelf=2), earn shells; swings when KOTHState contested",
							Value = false,
							Callback = function(on)
								if S.suppressAutoKothSync then
									return
								end
								if H.setAutoKoth then
									H.setAutoKoth(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(section)
					end

					function H.buildMineRaceEventSection(tab, sectionTitle)
						local section = H.createStaticBoxSection(tab, sectionTitle, "solar:flag-bold")

						UI.autoMineRaceToggleElement = section:Toggle({
							Title = "Auto Mine Race",
							Desc = "Shell Race minefield solver — tweens rows 1–20 and finishes at EndRace",
							Value = false,
							Callback = function(on)
								if S.suppressAutoMineRaceSync then
									return
								end
								if H.setAutoMineRace then
									H.setAutoMineRace(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(section)
					end

					function H.createWorldCrateDeletePicker(section, slot)
						local rollOptions = H.getWorldCrateRollOptions(slot)
						if #rollOptions == 0 then
							return
						end

						local displayValues = {}
						for _, opt in ipairs(rollOptions) do
							table.insert(displayValues, opt.displayLabel)
						end

						if not S.crateAutoDeleteIds[slot.id] then
							S.crateAutoDeleteIds[slot.id] = {}
						end

						local ok, picker = pcall(function()
							return section:Dropdown({
								Title = "Auto Delete Drops",
								Desc = slot.title .. " â€” sells selected drops after auto open only",
								Values = displayValues,
								Value = H.getCrateAutoDeleteLabels(slot.id),
								Multi = true,
								AllowNone = true,
								Callback = function(selected)
									if S.suppressSettingsDropdownSync then
										return
									end
									H.setCrateAutoDeleteSelection(slot.id, selected, rollOptions)
								end,
							})
						end)

						if not ok then
							warn("[ExonHub] Auto delete dropdown failed for", slot.title, picker)
						else
							UI.crateDeleteDropdowns[slot.id] = picker
						end
					end

					function H.createWorldCrateHuntPicker(section, slot)
						local rollOptions = H.getWorldCrateRollOptions(slot)
						if #rollOptions == 0 then
							return
						end

						local displayValues = {}
						for _, opt in ipairs(rollOptions) do
							table.insert(displayValues, opt.displayLabel)
						end

						S.crateHuntTargets = S.crateHuntTargets or {}
						S.crateHuntLabels = S.crateHuntLabels or {}
						if not S.crateHuntTargets[slot.id] then
							S.crateHuntTargets[slot.id] = {}
						end
						if not S.crateHuntLabels[slot.id] then
							S.crateHuntLabels[slot.id] = {}
						end

						local ok, picker = pcall(function()
							return section:Dropdown({
								Title = "Auto Delete + Stop",
								Desc = slot.title
									.. " — keep selected targets, auto delete others, stop auto open when obtained",
								Values = displayValues,
								Value = H.getCrateHuntLabels(slot.id),
								Multi = true,
								AllowNone = true,
								Callback = function(selected)
									if S.suppressSettingsDropdownSync then
										return
									end
									H.setCrateHuntSelection(slot.id, selected, rollOptions, H.getCrateHuntLabels(slot.id))
								end,
							})
						end)

						if not ok then
							warn("[ExonHub] Hunt dropdown failed for", slot.title, picker)
						else
							UI.crateHuntDropdowns[slot.id] = picker
						end
					end

					function H.buildWorldCrateKindSection(tab, sectionTitle, kind)
						local section = H.createStaticBoxSection(tab, sectionTitle)
						for _, slot in ipairs(WORLD_CRATE_SLOTS) do
							if slot.kind == kind then
								H.createWorldCrateAutoOpenToggle(section, slot)
								if kind == "legendary" or kind == "mythic" then
									H.createWorldCrateHuntPicker(section, slot)
								else
									H.createWorldCrateDeletePicker(section, slot)
								end
							end
						end
						H.finalizeStaticSection(section)
					end

					function H.ensureWeaponEquipped(pc)
						if not pc then
							return false
						end
						pcall(function()
							if pc.SetWeaponEquipped and pc.IsWeaponEquipped and not pc:IsWeaponEquipped() then
								pc:SetWeaponEquipped(true)
							end
						end)
						return pc.Weapon ~= nil
					end

					function H.ensureWeaponUnequipped(pc)
						if not pc then
							return false
						end
						pcall(function()
							if pc.SetWeaponEquipped and pc.IsWeaponEquipped and pc:IsWeaponEquipped() then
								pc:SetWeaponEquipped(false)
							end
						end)
						return true
					end

					function H.shouldClickerUseSilentTrain()
						return S.autoGoalsRunning == true
					end

					function H.backgroundTrainSilent()
						local pc = H.getPlayerController()

						if not pc then
							return H.fireTrainRemotes()
						end

						local ok = false
						H.withFishingActivationBypass(function()
							H.prepareSilentTrainWeapon(pc)
							ok = H.fireTrainSwingViaController(pc)
							if not ok then
								ok = H.fireTrainRemotes()
							end
							if not ok then
								ok = H.fireTrainViaInputSimulation(pc)
							end
						end)
						H.ensureWeaponUnequipped(pc)
						return ok
					end

					function H.applySilentTrainMode(enabled)
						local pc = H.getPlayerController()
						if enabled then
							if not S.silentTrainModeActive then
								S.clickerHadAeroAuto = pc and pc.DoAutoClick == true
								S.silentTrainModeActive = true
							end
							H.tryAeroAutoSwing(pc, false)
							H.ensureWeaponUnequipped(pc)
							return
						end

						S.silentTrainModeActive = false
						if S.clickerHadAeroAuto and not H.shouldClickerUseSilentTrain() then
							H.tryAeroAutoSwing(pc, true)
							S.clickerHadAeroAuto = false
						elseif not H.shouldClickerUseSilentTrain() then
							S.clickerHadAeroAuto = false
						end
					end

					function H.applyClickerModeForAutoGoals(autoGoalsOn)
						if autoGoalsOn or H.shouldClickerUseSilentTrain() then
							H.applySilentTrainMode(true)
						else
							H.applySilentTrainMode(false)
						end
					end

					function H.tryAeroAutoSwing(pc, enable)
						if not pc then
							return false
						end
						local ok = pcall(function()
							pc.CanAutoClick = true
							H.ensureWeaponEquipped(pc)
							if enable then
								if pc.SetAutoClick then
									pc:SetAutoClick(true, true)
								elseif pc.ToggleAutoClick and pc.IsAutoClicking and not pc:IsAutoClicking() then
									pc:ToggleAutoClick()
								elseif pc.OnWeaponActivated then
									pc:OnWeaponActivated(true)
								end
							elseif pc.SetAutoClick and pc.DoAutoClick then
								pc:SetAutoClick(false, true)
							end
						end)
						return ok
					end

					function H.fireTrainRemotes()
						local ok = H.fireTrainClick()
						ok = H.firePlayerTrain() or ok
						ok = H.fireTrainAttackStart() or ok
						task.wait(TRAIN_REMOTE_SETTLE)
						ok = H.fireTrainAnimComplete() or ok
						return ok
					end

					function H.backgroundTrainBurst()
						for i = 1, TRAIN_BURST_SWINGS do
							H.backgroundTrainSwing()
							if i < TRAIN_BURST_SWINGS then
								task.wait(TRAIN_BURST_GAP)
							end
						end
					end

					function H.runClickerTrainTick()
						if H.shouldClickerUseSilentTrain() then
							H.applySilentTrainMode(true)
							H.backgroundTrainSilent()
							return
						end

						if S.autoFishRunning then
							return
						end

						H.applySilentTrainMode(false)
						local pc = H.getPlayerController()
						if pc and not pc.DoAutoClick then
							H.tryAeroAutoSwing(pc, true)
						end

						if pc and pc.DoAutoClick then
							H.fireTrainClick()
							return
						end

						H.backgroundTrainBurst()
					end

					function H.backgroundTrainSwing()
						local pc = H.getPlayerController()
						local swung = false
						if pc then
							swung = pcall(function()
								H.ensureWeaponEquipped(pc)
								if pc.OnWeaponActivated then
									pc:OnWeaponActivated(true)
								end
							end)
						end
						if not swung then
							H.fireTrainRemotes()
						end
					end

					function H.stopClickerLoop()
						S.clickerRunning = false
						H.tryAeroAutoSwing(H.getPlayerController(), false)
					end

					function H.clickerLoop()
						if S.clickerLoopActive then
							return
						end
						S.clickerLoopActive = true

						task.spawn(function()
							H.waitForPlayerController(25)

							if S.clickerRunning then
								if H.shouldClickerUseSilentTrain() then
									H.applySilentTrainMode(true)
									print("[ExonHub] Auto click: silent train (goals active)")
								else
									H.applySilentTrainMode(false)
									print("[ExonHub] Auto click train loop active")
								end
							end

							while S.clickerRunning do
								H.runClickerTrainTick()
								task.wait(TRAIN_INTERVAL)
							end

							H.applySilentTrainMode(false)
							H.tryAeroAutoSwing(H.getPlayerController(), false)
							S.clickerLoopActive = false
						end)
					end

					local WEAPON_SORT_OPTIONS = { "XP", "Damage", "Crit" }
					local SKIN_SORT_OPTIONS = { "XP", "Health", "Regen" }

					function H.getOptionIndex(options, value)
						for index, option in ipairs(options) do
							if option == value then
								return index
							end
						end
						return 1
					end

					function H.refreshSectionBoxLayout(section)
						if not section or not section.ElementFrame then
							return
						end

						local elementFrame = section.ElementFrame
						local outline = elementFrame:FindFirstChild("Outline")
						if not outline then
							return
						end

						local content = outline:FindFirstChild("Content")
						if not content then
							return
						end

						content.Visible = true

						for _, descendant in ipairs(content:GetDescendants()) do
							if descendant:IsA("UIListLayout") then
								descendant.Padding = UDim.new(0, 8)
							end
						end

						if not content:FindFirstChild("ExonHubSectionPad") then
							local pad = Instance.new("Frame")
							pad.Name = "ExonHubSectionPad"
							pad.BackgroundTransparency = 1
							pad.BorderSizePixel = 0
							pad.Size = UDim2.new(1, 0, 0, 10)
							pad.LayoutOrder = 99999
							pad.Parent = content
						end

						for _, frame in ipairs({ content, outline, elementFrame }) do
							pcall(function()
								frame.AutomaticSize = Enum.AutomaticSize.Y
							end)
						end
					end

					function H.finalizeStaticSection(section)
						if not section then
							return
						end

						H.refreshSectionBoxLayout(section)

						task.defer(function()
							pcall(function()
								if section.Open then
									section:Open(true)
								end
								section.Expandable = false
								section.Opened = true
							end)

							local elementFrame = section.ElementFrame
							if not elementFrame then
								return
							end

							local outline = elementFrame:FindFirstChild("Outline")
							if not outline then
								return
							end

							local content = outline:FindFirstChild("Content")
							if content then
								content.Visible = true
							end

							local top = outline:FindFirstChild("Top")
							if top then
								for _, child in top:GetChildren() do
									pcall(function()
										if child:IsA("Frame") and child:FindFirstChild("ImageLabel") and not child:FindFirstChild("TextLabel", true) then
											child.Visible = false
										end
									end)
								end
							end

							H.refreshSectionBoxLayout(section)
							task.delay(0.08, function()
								H.refreshSectionBoxLayout(section)
							end)
						end)
					end

					function H.createStaticBoxSection(tab, title, icon)
						local config = {
							Title = title,
							Box = true,
							BoxBorder = true,
							Opened = true,
						}
						if icon then
							config.Icon = icon
						end
						return tab:Section(config)
					end

					function H.createStatPicker(tab, config)
						local options = config.options
						local title = config.title
						local desc = config.desc
						local getStat = config.getStat
						local setStat = config.setStat
						local onChange = config.onChange
						local current = getStat()

						local function applySelection(selected)
							local value = selected
							if type(selected) == "number" then
								value = options[selected]
							elseif type(selected) == "table" then
								value = selected.Title or selected[1]
							end
							if type(value) == "string" then
								setStat(value)
								if onChange then
									onChange()
								end
								H.scheduleSettingsSave()
							end
						end

						local pickerClose = nil

						local ok, picker = pcall(function()
							return tab:Dropdown({
								Title = title,
								Desc = desc,
								Values = options,
								Value = current,
								Multi = false,
								Callback = function(selected)
									applySelection(selected)
									if pickerClose and pickerClose.Close then
										pickerClose:Close()
									end
								end,
							})
						end)

						if ok and picker then
							pickerClose = picker
							return picker
						end

						warn("[ExonHub] Dropdown failed for", title, "- using button fallback:", picker)

						local index = H.getOptionIndex(options, current)
						local button = tab:Button({
							Title = title .. ": " .. options[index],
							Desc = desc .. " (click to cycle)",
							Callback = function()
								index = (index % #options) + 1
								applySelection(options[index])
								if button.SetTitle then
									button:SetTitle(title .. ": " .. options[index])
								end
							end,
						})

						return button
					end

					function H.getWeaponsModule()
						if C.weapons then
							return C.weapons
						end
						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local weaponsScript = sharedFolder and sharedFolder:FindFirstChild("Weapons")
						if not weaponsScript then
							return nil
						end
						local ok, mod = pcall(require, weaponsScript)
						if ok and mod then
							C.weapons = mod
							return mod
						end
						return nil
					end

					function H.getSkinsModule()
						if C.skins then
							return C.skins
						end
						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
						local skinsScript = sharedFolder and sharedFolder:FindFirstChild("Skins")
						if not skinsScript then
							return nil
						end
						local ok, mod = pcall(require, skinsScript)
						if ok and mod then
							C.skins = mod
							return mod
						end
						return nil
					end

					function H.getWeaponInventoryData()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers and aero.Controllers.WeaponInventoryController then
							return aero.Controllers.WeaponInventoryController.InventoryData
						end
						if aero and aero.Services and aero.Services.GameDataService and aero.Services.GameDataService.GetPlayerWeapons then
							local ok, data = pcall(function()
								return aero.Services.GameDataService:GetPlayerWeapons(player)
							end)
							if ok and type(data) == "table" then
								return data
							end
						end
						return nil
					end

					function H.getSkinInventoryData()
						local aero = H.getGlobal().Aero
						if aero and aero.Controllers and aero.Controllers.SkinInventoryController then
							return aero.Controllers.SkinInventoryController.InventoryData
						end
						if aero and aero.Services and aero.Services.GameDataService and aero.Services.GameDataService.GetPlayerSkins then
							local ok, data = pcall(function()
								return aero.Services.GameDataService:GetPlayerSkins(player)
							end)
							if ok and type(data) == "table" then
								return data
							end
						end
						return nil
					end

					function H.getEquippedItemKey(statName)
						local stats = H.getClientStats()
						if not stats then
							return nil
						end
						local valueObj = stats:FindFirstChild(statName)
						if not valueObj then
							return nil
						end
						local raw = valueObj.Value
						if raw == nil or raw == "" or raw == 0 or raw == "0" then
							return nil
						end
						return tostring(raw)
					end

					function H.canDualWieldNow()
						return H.getStatValue(H.getClientStats(), "dual_skill") > 0
					end

					function H.fireGameServiceEvent(remoteName, arg)
						local aero = H.getGlobal().Aero
						if aero and aero.Services and aero.Services.GameService then
							local remote = aero.Services.GameService[remoteName]
							if remote and remote.Fire then
								return pcall(function()
									remote:Fire(arg)
								end)
							end
						end

						local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
						local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
						local gameService = services and services:FindFirstChild("GameService")
						local remote = gameService and gameService:FindFirstChild(remoteName)
						if remote and remote:IsA("RemoteEvent") then
							return pcall(function()
								remote:FireServer(arg)
							end)
						end

						return false, remoteName .. " unavailable"
					end

					function H.getWeaponInventoryEntry(key, inventory)
						inventory = inventory or H.getWeaponInventoryData()
						if not inventory or not key then
							return nil
						end
						return inventory[key] or inventory[tostring(key)] or inventory[tonumber(key)]
					end

					function H.getWeaponAps(weaponsMod, entry)
						local data = weaponsMod and entry and weaponsMod.Data[entry.id]
						if not data then
							return 0
						end
						return data.APS or 0
					end

					function H.assignBestWeaponHands(weaponsMod, inventory, primaryKey, secondaryKey)
						if not secondaryKey then
							return primaryKey, nil
						end

						local primaryEntry = H.getWeaponInventoryEntry(primaryKey, inventory)
						local secondaryEntry = H.getWeaponInventoryEntry(secondaryKey, inventory)
						if not primaryEntry or not secondaryEntry then
							return primaryKey, secondaryKey
						end

						local primaryAps = H.getWeaponAps(weaponsMod, primaryEntry)
						local secondaryAps = H.getWeaponAps(weaponsMod, secondaryEntry)
						if secondaryAps > primaryAps then
							return secondaryKey, primaryKey
						end

						return primaryKey, secondaryKey
					end

					function H.scoreWeaponEntry(weaponsMod, entry, stat)
						local data = weaponsMod.Data[entry.id]
						if not data then
							return 0
						end

						if stat == "XP" then
							return weaponsMod:GetWeaponXp(entry)
						end

						local damage = select(1, weaponsMod:GetWeaponDamage(entry, false))

						if stat == "Damage" then
							return damage
						elseif stat == "Crit" then
							return data.Crit or 0
						end

						return weaponsMod:GetWeaponXp(entry)
					end

					function H.scoreSkinEntry(skinsMod, entry, stat)
						if stat == "XP" then
							return skinsMod:GetSkinXp(entry)
						elseif stat == "Health" then
							return skinsMod:GetSkinHealth(entry)
						elseif stat == "Regen" then
							return skinsMod:GetSkinRegen(entry)
						end

						return skinsMod:GetSkinXp(entry)
					end

					function H.rankInventoryEntries(inventory, scoreFn, playerLevel)
						local ranked = {}
						if type(inventory) ~= "table" then
							return ranked
						end

						for key, entry in pairs(inventory) do
							if type(entry) == "table" and entry.id and entry.level and entry.level <= playerLevel then
								table.insert(ranked, {
									key = tostring(key),
									score = scoreFn(entry),
								})
							end
						end

						table.sort(ranked, function(a, b)
							if a.score == b.score then
								return a.key < b.key
							end
							return a.score > b.score
						end)

						return ranked
					end

					function H.getBestWeaponKeys(stat)
						local weaponsMod = H.getWeaponsModule()
						local inventory = H.getWeaponInventoryData()
						if not weaponsMod or not inventory then
							return nil, nil
						end

						local ranked = H.rankInventoryEntries(inventory, function(entry)
							return H.scoreWeaponEntry(weaponsMod, entry, stat)
						end, H.getPlayerLevel())

						if #ranked == 0 then
							return nil, nil
						end

						local mainKey = ranked[1].key
						local offhandKey = nil
						for index = 2, #ranked do
							if ranked[index].key ~= mainKey then
								offhandKey = ranked[index].key
								break
							end
						end

						mainKey, offhandKey = H.assignBestWeaponHands(weaponsMod, inventory, mainKey, offhandKey)

						return mainKey, offhandKey
					end

					function H.getBestSkinKey(stat)
						local skinsMod = H.getSkinsModule()
						local inventory = H.getSkinInventoryData()
						if not skinsMod or not inventory then
							return nil
						end

						local ranked = H.rankInventoryEntries(inventory, function(entry)
							return H.scoreSkinEntry(skinsMod, entry, stat)
						end, H.getPlayerLevel())

						if #ranked == 0 then
							return nil
						end

						return ranked[1].key
					end

					function H.tryEquipBestSword()
						local constants = H.getSharedConstants()
						if not constants or not constants.RemoteEvents then
							return false
						end

						local mainKey, offhandKey = H.getBestWeaponKeys(S.weaponSortStat)
						if not mainKey then
							return false
						end

						local changed = false
						local equippedMain = H.getEquippedItemKey("weapon_equipped")
						local equippedOffhand = H.getEquippedItemKey("offhand_equipped")

						if equippedMain ~= mainKey then
							local ok = H.fireGameServiceEvent(constants.RemoteEvents.EQUIP_WEAPON, mainKey)
							if ok then
								changed = true
							end
						end

						if H.canDualWieldNow() and offhandKey and equippedOffhand ~= offhandKey then
							local ok = H.fireGameServiceEvent(constants.RemoteEvents.EQUIP_OFFHAND, offhandKey)
							if ok then
								changed = true
							end
						end

						if changed then
							H.setStatus("Equipped best sword (" .. S.weaponSortStat .. ")")
						end

						return changed
					end

					function H.tryEquipBestSkin()
						local constants = H.getSharedConstants()
						if not constants or not constants.RemoteEvents then
							return false
						end

						local bestKey = H.getBestSkinKey(S.skinSortStat)
						if not bestKey then
							return false
						end

						local equippedSkin = H.getEquippedItemKey("skin_equipped")
						if equippedSkin == bestKey then
							return false
						end

						local ok = H.fireGameServiceEvent(constants.RemoteEvents.EQUIP_SKIN, bestKey)
						if ok then
							H.setStatus("Equipped best skin (" .. S.skinSortStat .. ")")
						end
						return ok
					end

					function H.normalizeMaxOutTier(value)
						if value == nil or value == false or value == "" then
							return nil
						end
						if type(value) == "table" then
							local labels = H.normalizeDropdownSelection(value)
							value = labels[1]
						end
						if type(value) ~= "string" then
							return nil
						end
						local cleaned = H.stripRichText(value)
						for _, option in ipairs(MAX_OUT_OPTIONS) do
							if cleaned:lower() == option:lower() then
								return option
							end
						end
						return nil
					end

					function H.normalizeItemName(name)
						if type(name) ~= "string" then
							return ""
						end
						local cleaned = H.stripRichText(name):lower()
						cleaned = cleaned:gsub("[''`]", "")
						cleaned = cleaned:gsub("[^%w%s]", " ")
						cleaned = cleaned:gsub("%s+", " ")
						return (cleaned:match("^%s*(.-)%s*$")) or ""
					end

					function H.getItemRarityRank(dataEntry)
						if type(dataEntry) ~= "table" then
							return 0
						end
						local rarity = tostring(dataEntry.Rarity or dataEntry.rarity or ""):upper()
						for tierName, aliases in pairs(MAX_OUT_RARITY_ALIASES) do
							if aliases[rarity] then
								return MAX_OUT_RARITY_RANK[tierName] or 0
							end
						end
						local itemTier = tonumber(dataEntry.Tier or dataEntry.Tier)
						if itemTier then
							if itemTier >= 5 then
								return 5
							end
							return math.clamp(math.floor(itemTier), 0, 5)
						end
						return 0
					end

					function H.itemMatchesMaxOutRarity(dataEntry, tier)
						if not dataEntry or not tier then
							return false
						end
						return H.getItemRarityRank(dataEntry) == (MAX_OUT_RARITY_RANK[tier] or -1)
					end

					function H.getItemBaseXpMod(dataEntry)
						if type(dataEntry) ~= "table" then
							return 0
						end
						return tonumber(dataEntry.XpMod or dataEntry.XPMod or dataEntry.xpMod) or 0
					end

					function H.findCatalogIdByName(mod, wantedName)
						if not mod or type(mod.Data) ~= "table" or type(wantedName) ~= "string" then
							return nil
						end
						local want = H.normalizeItemName(wantedName)
						if want == "" then
							return nil
						end

						local exact = nil
						local partial = nil
						for itemId, dataEntry in pairs(mod.Data) do
							if type(dataEntry) == "table" then
								local name = H.normalizeItemName(dataEntry.DisplayName or dataEntry.Name)
								if name == want then
									exact = tonumber(itemId) or itemId
									break
								end
								if not partial and name ~= "" and (name:find(want, 1, true) or want:find(name, 1, true)) then
									partial = tonumber(itemId) or itemId
								end
							end
						end
						return exact or partial
					end

					function H.getPreferredCatalogTargets(kind, tier)
						local mod = kind == "weapon" and H.getWeaponsModule() or H.getSkinsModule()
						local preferred = MAX_OUT_PREFERRED[tier]
						local names = preferred and (kind == "weapon" and preferred.weapons or preferred.skins) or {}
						local out = {}
						local seen = {}

						for _, name in ipairs(names) do
							local id = H.findCatalogIdByName(mod, name)
							if id and not seen[tostring(id)] then
								seen[tostring(id)] = true
								table.insert(out, {
									id = id,
									name = name,
									xp = H.getItemBaseXpMod(mod and mod.Data and (mod.Data[id] or mod.Data[tostring(id)])),
								})
							end
						end

						-- Fallback: rank by XP within rarity if preferred names missing from this game build
						if #out == 0 and mod and type(mod.Data) == "table" then
							local ranked = {}
							for itemId, dataEntry in pairs(mod.Data) do
								if type(dataEntry) == "table" and H.itemMatchesMaxOutRarity(dataEntry, tier) then
									table.insert(ranked, {
										id = tonumber(itemId) or itemId,
										name = dataEntry.DisplayName or dataEntry.Name or tostring(itemId),
										xp = H.getItemBaseXpMod(dataEntry),
									})
								end
							end
							table.sort(ranked, function(a, b)
								if a.xp == b.xp then
									return tostring(a.name) < tostring(b.name)
								end
								return a.xp > b.xp
							end)
							out = ranked
						end

						return out
					end

					function H.findOwnedEntriesByCatalogId(kind, catalogId)
						local inventory = kind == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
						local found = {}
						if type(inventory) ~= "table" or not catalogId then
							return found
						end
						local want = tonumber(catalogId) or catalogId
						for key, entry in pairs(inventory) do
							if type(entry) == "table" then
								local id = tonumber(entry.id or entry.ID)
								if id and (id == want or tostring(id) == tostring(want)) then
									table.insert(found, {
										key = tostring(key),
										id = id,
										entry = entry,
									})
								end
							end
						end
						return found
					end

					function H.entryMatchesCatalogTarget(entry, mod, target)
						if type(entry) ~= "table" or type(target) ~= "table" then
							return false
						end

						local id = tonumber(entry.id or entry.ID)
						local targetId = tonumber(target.id)
						if id and targetId and (id == targetId or tostring(id) == tostring(targetId)) then
							return true
						end

						if not mod or type(mod.Data) ~= "table" or not id then
							return false
						end

						local data = mod.Data[id] or mod.Data[tostring(id)]
						if type(data) ~= "table" then
							return false
						end

						local entryName = H.normalizeItemName(data.DisplayName or data.Name)
						local wantName = H.normalizeItemName(target.name)
						if entryName == "" or wantName == "" then
							return false
						end

						return entryName == wantName
							or entryName:find(wantName, 1, true) ~= nil
							or wantName:find(entryName, 1, true) ~= nil
					end

					function H.findOwnedTargetEntries(kind, mod, target)
						local inventory = kind == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
						local found = {}
						if type(inventory) ~= "table" or type(target) ~= "table" then
							return found
						end

						for key, entry in pairs(inventory) do
							if type(entry) == "table" and H.entryMatchesCatalogTarget(entry, mod, target) then
								table.insert(found, {
									key = tostring(key),
									id = tonumber(entry.id or entry.ID) or entry.id,
									entry = entry,
								})
							end
						end

						return found
					end

					function H.pickBestOwnedEntry(rows)
						if type(rows) ~= "table" or #rows == 0 then
							return nil
						end
						table.sort(rows, function(a, b)
							local au = (a.entry and a.entry.upgrades) or 0
							local bu = (b.entry and b.entry.upgrades) or 0
							return au > bu
						end)
						return rows[1]
					end

					function H.findOwnedMaxOutSkin(tier, preferredSkins, skinsMod)
						preferredSkins = preferredSkins or {}
						skinsMod = skinsMod or H.getSkinsModule()
						local inventory = H.getSkinInventoryData()
						if type(inventory) ~= "table" or not skinsMod then
							return nil, nil
						end

						local maxPreferredXp = 0
						for _, preferredSkin in ipairs(preferredSkins) do
							if tonumber(preferredSkin.xp) and preferredSkin.xp > maxPreferredXp then
								maxPreferredXp = preferredSkin.xp
							end
						end

						for _, preferredSkin in ipairs(preferredSkins) do
							local ownedSkins = H.findOwnedTargetEntries("skin", skinsMod, preferredSkin)
							local best = H.pickBestOwnedEntry(ownedSkins)
							if best then
								return best, preferredSkin
							end
						end

						local bestTierOwned = nil
						for key, entry in pairs(inventory) do
							if type(entry) == "table" then
								local id = tonumber(entry.id or entry.ID)
								local data = id and skinsMod.Data and (skinsMod.Data[id] or skinsMod.Data[tostring(id)])
								if data and H.itemMatchesMaxOutRarity(data, tier) then
									local xp = H.getItemBaseXpMod(data)
									if maxPreferredXp <= 0 or xp >= maxPreferredXp then
										local row = {
											key = tostring(key),
											id = id,
											entry = entry,
										}
										if not bestTierOwned then
											bestTierOwned = row
										else
											local currentUp = (bestTierOwned.entry and bestTierOwned.entry.upgrades) or 0
											local nextUp = (entry.upgrades) or 0
											if nextUp > currentUp then
												bestTierOwned = row
											end
										end
									end
								end
							end
						end

						if bestTierOwned then
							local data = skinsMod.Data[bestTierOwned.id] or skinsMod.Data[tostring(bestTierOwned.id)]
							local matchedPreferred = preferredSkins[1]
							if data then
								local entryName = H.normalizeItemName(data.DisplayName or data.Name)
								for _, preferredSkin in ipairs(preferredSkins) do
									local wantName = H.normalizeItemName(preferredSkin.name)
									if entryName == wantName
										or entryName:find(wantName, 1, true)
										or wantName:find(entryName, 1, true)
									then
										matchedPreferred = preferredSkin
										break
									end
								end
							end
							return bestTierOwned, matchedPreferred
						end

						return nil, nil
					end

					function H.getMaxOutBestWeaponTargets(preferredWeapons)
						if type(preferredWeapons) ~= "table" or #preferredWeapons == 0 then
							return {}, nil
						end

						local maxXp = 0
						for _, preferred in ipairs(preferredWeapons) do
							local xp = tonumber(preferred.xp) or 0
							if xp > maxXp then
								maxXp = xp
							end
						end

						local bestTargets = {}
						for _, preferred in ipairs(preferredWeapons) do
							local xp = tonumber(preferred.xp) or 0
							if xp >= maxXp then
								table.insert(bestTargets, preferred)
							end
						end

						return bestTargets, bestTargets[1]
					end

					function H.findOwnedMaxOutWeapons(tier, neededCount, weaponsMod, preferredWeapons)
						neededCount = math.max(1, tonumber(neededCount) or 1)
						weaponsMod = weaponsMod or H.getWeaponsModule()
						preferredWeapons = preferredWeapons or H.getPreferredCatalogTargets("weapon", tier)
						local bestTargets, headlineTarget = H.getMaxOutBestWeaponTargets(preferredWeapons)
						local ownedBest = {}
						local seenKeys = {}

						for _, target in ipairs(bestTargets) do
							for _, row in ipairs(H.findOwnedTargetEntries("weapon", weaponsMod, target)) do
								if not seenKeys[row.key] then
									seenKeys[row.key] = true
									table.insert(ownedBest, row)
								end
							end
						end

						if #ownedBest == 0 and weaponsMod and type(weaponsMod.Data) == "table" then
							local inventory = H.getWeaponInventoryData()
							local maxPreferredXp = tonumber(headlineTarget and headlineTarget.xp) or 0
							if type(inventory) == "table" then
								for key, entry in pairs(inventory) do
									if type(entry) == "table" then
										local id = tonumber(entry.id or entry.ID)
										local data = id and (weaponsMod.Data[id] or weaponsMod.Data[tostring(id)])
										if data and H.itemMatchesMaxOutRarity(data, tier) then
											local xp = H.getItemBaseXpMod(data)
											if maxPreferredXp <= 0 or xp >= maxPreferredXp then
												local row = {
													key = tostring(key),
													id = id,
													entry = entry,
												}
												if not seenKeys[row.key] then
													seenKeys[row.key] = true
													table.insert(ownedBest, row)
												end
											end
										end
									end
								end
							end
						end

						table.sort(ownedBest, function(a, b)
							local au = (a.entry and a.entry.upgrades) or 0
							local bu = (b.entry and b.entry.upgrades) or 0
							if au == bu then
								return tostring(a.key) < tostring(b.key)
							end
							return au > bu
						end)

						local weaponKeys = {}
						for index = 1, math.min(neededCount, #ownedBest) do
							table.insert(weaponKeys, ownedBest[index])
						end

						local missingWeapons = {}
						if #weaponKeys < neededCount then
							local bestName = headlineTarget and headlineTarget.name or "best weapon"
							table.insert(
								missingWeapons,
								string.format("%s x%d", bestName, neededCount - #weaponKeys)
							)
						end

						return weaponKeys, missingWeapons, bestTargets, headlineTarget
					end

					function H.refreshMaxOutCrateNeeds(progress)
						if not S.maxOutRunning or not progress then
							S.maxOutNeedWeaponCrates = false
							S.maxOutNeedSkinCrates = false
							return
						end
						S.maxOutNeedWeaponCrates = not progress.haveWeapons
						S.maxOutNeedSkinCrates = not progress.haveSkin
					end

					function H.shouldMaxOutOpenChestType(itemType)
						if not S.maxOutRunning or S.maxOutStopping then
							return true
						end
						local tier = H.normalizeMaxOutTier(S.maxOutTier)
						if not tier then
							return true
						end
						local progress = H.getMaxOutProgress(tier)
						if not progress or progress.usesCaveCrates then
							return true
						end
						if itemType == "weapon" then
							return not progress.haveWeapons
						end
						return not progress.haveSkin
					end

					function H.shouldMaxOutOpenCaveSlot(slot)
						if not S.maxOutRunning or S.maxOutStopping or type(slot) ~= "table" then
							return true
						end
						local tier = H.normalizeMaxOutTier(S.maxOutTier)
						if not tier or (tier ~= "Legendary" and tier ~= "Mythic") then
							return true
						end
						if not (S.maxOutManagedCaveSlots and S.maxOutManagedCaveSlots[slot.id]) then
							return true
						end
						local progress = H.getMaxOutProgress(tier)
						if not progress then
							return true
						end
						if slot.itemType == "weapon" then
							return not progress.haveWeapons
						end
						if slot.itemType == "skin" then
							return not progress.haveSkin
						end
						return true
					end

					function H.getMaxOutProgress(tier)
						tier = H.normalizeMaxOutTier(tier)
						if not tier then
							return nil
						end

						local neededWeapons = H.canDualWieldNow() and 2 or 1
						local weaponsMod = H.getWeaponsModule()
						local skinsMod = H.getSkinsModule()
						local preferredWeapons = H.getPreferredCatalogTargets("weapon", tier)
						local preferredSkins = H.getPreferredCatalogTargets("skin", tier)

						local weaponKeys, missingWeapons, targetWeapons, headlineWeapon =
							H.findOwnedMaxOutWeapons(tier, neededWeapons, weaponsMod, preferredWeapons)

						local skinKeys = {}
						local haveSkin = #preferredSkins == 0
						local targetSkin = preferredSkins[1]
						if #preferredSkins > 0 then
							local ownedSkin, matchedPreferred = H.findOwnedMaxOutSkin(tier, preferredSkins, skinsMod)
							if ownedSkin then
								table.insert(skinKeys, ownedSkin)
								haveSkin = true
								if matchedPreferred then
									targetSkin = matchedPreferred
								end
							end
						end

						local haveWeapons = #weaponKeys >= neededWeapons
						if #preferredWeapons == 0 then
							haveWeapons = false
						end

						local bestWeaponName = headlineWeapon and headlineWeapon.name or "?"
						if neededWeapons > 1 and haveWeapons then
							bestWeaponName = string.format("%s x%d", bestWeaponName, neededWeapons)
						end

						return {
							tier = tier,
							neededWeapons = neededWeapons,
							weaponOwnedCount = #weaponKeys,
							skinOwnedCount = #skinKeys,
							haveWeapons = haveWeapons,
							haveSkin = haveSkin,
							complete = haveWeapons and haveSkin,
							weaponKeys = weaponKeys,
							skinKeys = skinKeys,
							targetWeapons = targetWeapons or {},
							targetSkin = targetSkin,
							missingWeapons = missingWeapons,
							bestWeaponName = bestWeaponName,
							bestSkinName = targetSkin and targetSkin.name or "?",
							usesCaveCrates = tier == "Legendary" or tier == "Mythic",
						}
					end

					function H.equipMaxOutGear(progress)
						local constants = H.getSharedConstants()
						if not constants or not constants.RemoteEvents or not progress then
							return false
						end

						local changed = false
						local weaponsMod = H.getWeaponsModule()
						local inventory = H.getWeaponInventoryData()

						local mainKey = progress.weaponKeys and progress.weaponKeys[1] and progress.weaponKeys[1].key
						local offhandKey = progress.weaponKeys and progress.weaponKeys[2] and progress.weaponKeys[2].key
						if mainKey and offhandKey then
							mainKey, offhandKey = H.assignBestWeaponHands(weaponsMod, inventory, mainKey, offhandKey)
						end

						if mainKey and H.getEquippedItemKey("weapon_equipped") ~= mainKey then
							if H.fireGameServiceEvent(constants.RemoteEvents.EQUIP_WEAPON, mainKey) then
								changed = true
							end
						end
						if progress.neededWeapons > 1 and offhandKey and H.canDualWieldNow() then
							if H.getEquippedItemKey("offhand_equipped") ~= offhandKey then
								if H.fireGameServiceEvent(constants.RemoteEvents.EQUIP_OFFHAND, offhandKey) then
									changed = true
								end
							end
						end

						local skinKey = progress.skinKeys and progress.skinKeys[1] and progress.skinKeys[1].key
						if skinKey and H.getEquippedItemKey("skin_equipped") ~= skinKey then
							if H.fireGameServiceEvent(constants.RemoteEvents.EQUIP_SKIN, skinKey) then
								changed = true
								H.setStatus("Max Out equipped skin: " .. tostring(progress.bestSkinName))
							end
						end

						return changed
					end

					function H.syncMaxOutCaveSlot(slotId, shouldEnable)
						if shouldEnable then
							local wasOn = S.caveAutoOpenSlots[slotId] == true
							if not wasOn then
								S.maxOutEnabledCaveSlots[slotId] = true
								S.maxOutManagedCaveSlots[slotId] = true
								if H.setCaveAutoOpenSlot then
									H.setCaveAutoOpenSlot(slotId, true, false)
								end
							else
								S.maxOutManagedCaveSlots[slotId] = true
							end
						else
							if S.maxOutEnabledCaveSlots[slotId] and H.setCaveAutoOpenSlot then
								H.setCaveAutoOpenSlot(slotId, false, false)
								S.maxOutEnabledCaveSlots[slotId] = nil
							end
							S.maxOutManagedCaveSlots[slotId] = nil
						end
					end

					function H.getMaxOutProtectedKeys(kind, tier)
						tier = H.normalizeMaxOutTier(tier)
						local protected = {}
						if not tier then
							return protected
						end

						local selectedRank = MAX_OUT_RARITY_RANK[tier] or 0
						local mod = kind == "weapon" and H.getWeaponsModule() or H.getSkinsModule()
						local inventory = kind == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
						if type(inventory) ~= "table" or not mod or type(mod.Data) ~= "table" then
							return protected
						end

						local targetIds = {}
						local preferred = H.getPreferredCatalogTargets(kind, tier)
						local bestTargets = kind == "weapon" and H.getMaxOutBestWeaponTargets(preferred) or preferred
						for _, row in ipairs(bestTargets) do
							targetIds[tostring(row.id)] = true
						end

						-- Also protect currently equipped gear
						if kind == "weapon" then
							local main = H.getEquippedItemKey("weapon_equipped")
							local off = H.getEquippedItemKey("offhand_equipped")
							if main then
								protected[main] = true
							end
							if off then
								protected[off] = true
							end
						else
							local skin = H.getEquippedItemKey("skin_equipped")
							if skin then
								protected[skin] = true
							end
						end

						for key, entry in pairs(inventory) do
							if type(entry) == "table" then
								local keyStr = tostring(key)
								local id = tonumber(entry.id or entry.ID)
								local data = id and (mod.Data[id] or mod.Data[tostring(id)])
								local rank = H.getItemRarityRank(data)
								-- Keep exact max-out targets (by catalog id or display name)
								if id and targetIds[tostring(id)] then
									protected[keyStr] = true
								else
									for _, target in ipairs(preferred) do
										if H.entryMatchesCatalogTarget(entry, mod, target) then
											protected[keyStr] = true
											break
										end
									end
								end
								-- Keep anything better than selected rarity (e.g. Mythic while farming Legendary)
								if rank > selectedRank then
									protected[keyStr] = true
								end
							end
						end

						return protected
					end

					function H.tryMaxOutAutoDelete(kind, tier)
						local constants = H.getSharedConstants()
						local inventory = kind == "weapon" and H.getWeaponInventoryData() or H.getSkinInventoryData()
						if not constants or type(inventory) ~= "table" then
							return false
						end

						local protected = H.getMaxOutProtectedKeys(kind, tier)
						local toSell = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and entry.id then
								local keyStr = tostring(key)
								if not protected[keyStr] and not entry.locked then
									table.insert(toSell, keyStr)
								end
							end
						end

						if #toSell == 0 then
							return false
						end

						local itemType = kind == "weapon" and constants.ItemType.WEAPON or constants.ItemType.SKIN
						if H.invokeSellInventoryItems(itemType, toSell) then
							H.setStatus(string.format("Max Out deleted %d %s(s)", #toSell, kind))
							return true
						end
						return false
					end

					function H.ensureMaxOutFarmingEnabled()
						if not S.clickerRunning and H.setAutoClicker then
							S.maxOutEnabledClicker = true
							H.setAutoClicker(true, false)
						end
						if not S.running and H.setRunning then
							S.maxOutEnabledFarm = true
							H.setRunning(true, false)
						end
					end

					function H.stopMaxOutHuntFeatures()
						if S.maxOutEnabledChest and H.setAutoOpenChest then
							H.setAutoOpenChest(false, false, false)
						end
						S.maxOutEnabledChest = false
						S.maxOutManagedChest = false

						for slotId, enabled in pairs(S.maxOutEnabledCaveSlots or {}) do
							if enabled and H.setCaveAutoOpenSlot and S.caveAutoOpenSlots[slotId] then
								H.setCaveAutoOpenSlot(slotId, false, false)
							end
						end
						S.maxOutEnabledCaveSlots = {}
						S.maxOutManagedCaveSlots = {}
					end

					function H.stopMaxOutAllManagedFeatures()
						S.maxOutStopping = true

						H.stopMaxOutHuntFeatures()

						if S.maxOutEnabledClicker and H.setAutoClicker then
							H.setAutoClicker(false, false)
						end
						S.maxOutEnabledClicker = false

						if S.maxOutEnabledFarm and H.setRunning then
							H.setRunning(false, false)
						end
						S.maxOutEnabledFarm = false

						if S.maxOutEnabledUpgrade and H.setAutoUpgrade then
							H.setAutoUpgrade(false, false)
						end
						S.maxOutEnabledUpgrade = false
						S.maxOutManagedUpgrade = false

						if not S.autoUpgradeRunning then
							H.teardownAutoUpgradeRebirthListener()
						end

						S.maxOutStopping = false
					end

					function H.ensureMaxOutCratesEnabled(tier, progress)
						if not S.maxOutRunning or S.maxOutStopping then
							return
						end

						progress = progress or H.getMaxOutProgress(tier)
						if not progress then
							return
						end

						H.refreshMaxOutCrateNeeds(progress)

						if progress.usesCaveCrates then
							local weaponSlot = tier == "Mythic" and "mythic_weapon" or "legendary_weapon"
							local skinSlot = tier == "Mythic" and "mythic_skin" or "legendary_skin"
							-- Keep opening only what's still missing
							H.syncMaxOutCaveSlot(weaponSlot, not progress.haveWeapons)
							H.syncMaxOutCaveSlot(skinSlot, not progress.haveSkin)
							return
						end

						-- Inventory chests (Common/Rare/Epic): stop each type once owned
						if progress.complete or (progress.haveWeapons and progress.haveSkin) then
							H.stopMaxOutHuntFeatures()
							return
						end

						if not S.maxOutManagedChest then
							S.maxOutManagedChest = true
						end
						if not S.autoOpenChestRunning and H.setAutoOpenChest then
							S.maxOutEnabledChest = true
							H.setAutoOpenChest(true, false, true)
						end
					end

					function H.ensureMaxOutUpgradeEnabled()
						H.setAutoUpgradeTargets({
							"Primary Weapon",
							"Secondary Weapon",
							"Skin",
						})
						H.setDropdownSelection(UI.autoUpgradeDropdownElement, H.getAutoUpgradeTargetLabels())
						H.ensureAutoUpgradeRebirthListener()
						S.maxOutManagedUpgrade = true
						S.maxOutEnabledUpgrade = true
						H.invalidateUpgradeInventorySnapshots()
						S.autoUpgradeFailStreak = 0

						if not S.autoUpgradeRunning and H.setAutoUpgrade then
							H.setAutoUpgrade(true, false)
						else
							H.ensureAutoUpgradeLoopRunning()
							H.tryAutoUpgradeBurst()
						end
					end

					function H.setMaxOutPhase(phase, detail)
						S.maxOutPhase = phase
						if detail then
							H.setStatus(detail)
						end
					end

					function H.updateMaxOutStatusLabel(_progress)
					end

					function H.maxOutTick()
						if not S.maxOutRunning or S.maxOutStopping then
							return false
						end
						local tier = H.normalizeMaxOutTier(S.maxOutTier)
						if not tier then
							return false
						end

						H.ensureMaxOutFarmingEnabled()
						local progress = H.getMaxOutProgress(tier)
						H.updateMaxOutStatusLabel(progress)
						if not progress then
							return false
						end

						local wasComplete = S.maxOutLastComplete == true
						if progress.complete and not wasComplete then
							H.invalidateUpgradeInventorySnapshots()
							S.autoUpgradeFailStreak = 0
						end
						S.maxOutLastComplete = progress.complete == true

						-- Clean junk, keep exact targets + anything better than selected rarity
						H.tryMaxOutAutoDelete("weapon", tier)
						H.tryMaxOutAutoDelete("skin", tier)

						-- Equip target pieces as soon as we have them (skin/weapons)
						H.equipMaxOutGear(progress)

						if not progress.complete then
							H.ensureMaxOutCratesEnabled(tier, progress)

							local missingParts = {}
							if #(progress.missingWeapons or {}) > 0 then
								table.insert(missingParts, table.concat(progress.missingWeapons, ", "))
							end
							if not progress.haveSkin then
								table.insert(missingParts, tostring(progress.bestSkinName))
							end

							H.setMaxOutPhase(
								"hunting",
								string.format(
									"Max Out %s: waiting for %s",
									tier,
									#missingParts > 0 and table.concat(missingParts, " + ") or "targets"
								)
							)
							return true
						end

						-- Full set owned — stop crate hunting, keep gear equipped, THEN start upgrading
						H.stopMaxOutHuntFeatures()
						H.equipMaxOutGear(progress)

						if S.maxOutPhase ~= "upgrading" then
							H.ensureMaxOutUpgradeEnabled()
							H.setMaxOutPhase(
								"upgrading",
								string.format(
									"Max Out %s: got %s + %s — auto upgrading",
									tier,
									tostring(progress.bestWeaponName),
									tostring(progress.bestSkinName)
								)
							)
						elseif not S.autoUpgradeRunning then
							H.ensureMaxOutUpgradeEnabled()
						else
							H.ensureAutoUpgradeLoopRunning()
							H.tryAutoUpgradeBurst()
						end
						return true
					end

					function H.stopMaxOutLoop()
						S.maxOutLoopActive = false
						S.maxOutPhase = "idle"
						S.maxOutLastComplete = false
						H.updateMaxOutStatusLabel(nil)
					end

					function H.startMaxOutLoop()
						if S.maxOutLoopActive then
							return
						end
						S.maxOutLoopActive = true

						task.spawn(function()
							H.getWeaponsModule()
							H.getSkinsModule()
							H.getSharedConstants()

							while S.maxOutRunning do
								local ok, err = pcall(H.maxOutTick)
								if not ok then
									warn("[ExonHub] Max Out tick failed:", err)
								end
								task.wait(MAX_OUT_POLL)
							end

							S.maxOutLoopActive = false
							if not S.maxOutStopping then
								H.stopMaxOutAllManagedFeatures()
							end
							H.updateMaxOutStatusLabel(nil)
						end)
					end

					function H.setMaxOutTier(value, fromDropdown)
						local tier = H.normalizeMaxOutTier(value) or "Common"
						if S.maxOutTier == tier then
							return
						end

						-- Switching rarity while running: stop hunt crates for the old tier
						if S.maxOutRunning then
							H.stopMaxOutHuntFeatures()
						end

						S.maxOutTier = tier
						S.maxOutPhase = S.maxOutRunning and "starting" or "idle"

						if S.maxOutRunning then
							H.setMaxOutPhase("starting", "Max Out " .. tier .. " — enabling farm + hunting crates")
							print("[ExonHub] Max Out target:", tier)
						end

						if not fromDropdown then
							S.suppressMaxOutSync = true
							H.setDropdownSelection(UI.maxOutDropdownElement, tier)
							S.suppressMaxOutSync = false
						end
						H.scheduleSettingsSave()
					end

					function H.setMaxOutImpl(state, fromToggle)
						state = state == true
						if S.maxOutRunning == state then
							if state and not S.maxOutLoopActive then
								H.startMaxOutLoop()
							end
							return
						end

						if not state then
							S.maxOutRunning = false
							H.stopMaxOutAllManagedFeatures()
							H.stopMaxOutLoop()
							H.setStatus("Max Out OFF")
							print("[ExonHub] Max Out OFF")
						else
							S.maxOutRunning = true
							if not H.normalizeMaxOutTier(S.maxOutTier) then
								S.maxOutTier = "Common"
								S.suppressMaxOutSync = true
								H.setDropdownSelection(UI.maxOutDropdownElement, S.maxOutTier)
								S.suppressMaxOutSync = false
							end
							H.setMaxOutPhase(
								"starting",
								"Max Out " .. tostring(S.maxOutTier) .. " — enabling farm + hunting crates"
							)
							print("[ExonHub] Max Out ON:", S.maxOutTier)
							H.ensureAutoUpgradeRebirthListener()
							H.startMaxOutLoop()
						end

						if not fromToggle then
							H.syncMaxOutToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setMaxOut = H.setMaxOutImpl

					function H.isGameServiceOk(response)
						local constants = H.getSharedConstants()
						local codes = constants and constants.ServerResponse
						if not codes then
							return response == 0
						end
						return response == codes.OK or response == codes.RESULT_OK
					end

					function H.resolveInventoryKey(inventory, key)
						if inventory[key] ~= nil then
							return key
						end
						local keyStr = tostring(key)
						if inventory[keyStr] ~= nil then
							return keyStr
						end
						local keyNum = tonumber(keyStr)
						if keyNum ~= nil and inventory[keyNum] ~= nil then
							return keyNum
						end
						return key
					end

					function H.isKnownPetType(id)
						id = tonumber(id)
						if not id then
							return false
						end
						local petsMod = H.getPetsModule()
						return petsMod and petsMod.Data and petsMod.Data[id] ~= nil
					end

					function H.resolvePetEntryType(entry)
						if type(entry) ~= "table" then
							return nil
						end

						local ptype = tonumber(entry.ptype)
						if ptype and ptype > 0 then
							return math.floor(ptype)
						end

						local id = tonumber(entry.id or entry.ID)
						if id and id > 0 and H.isKnownPetType(id) then
							return math.floor(id)
						end

						return nil
					end

					function H.getEvolveRequirements()
						local constants = H.getSharedConstants()
						local duplicateRequired = constants and constants.REQUIRED_PET_EVOLVE_COUNT or 4
						return {
							duplicateRequired = duplicateRequired,
							totalRequired = duplicateRequired + 1,
							maxPetEvolutions = constants and constants.MAX_PET_EVOLUTIONS or 1,
							maxArtifactEvolutions = constants and constants.MAX_ARTIFACT_EVOLUTIONS or 1,
						}
					end

					function H.resolveArtifactEntryId(entry)
						if type(entry) ~= "table" then
							return nil
						end
						return tonumber(entry.ID or entry.id)
					end

					function H.resolvePetEntryEvoLevel(entry)
						if type(entry) ~= "table" then
							return 0
						end
						return entry.evo or entry.evoLevel or entry.Evo or 0
					end

					function H.resolveArtifactEntryEvoLevel(entry)
						if type(entry) ~= "table" then
							return 0
						end
						return entry.evolutionlevel or entry.evoLevel or entry.evo or 0
					end

					function H.isEvolveSuccess(result)
						return result == true or H.isGameServiceOk(result)
					end

					function H.trimDuplicateKeys(duplicateKeys, duplicateRequired)
						while #duplicateKeys > duplicateRequired do
							table.remove(duplicateKeys)
						end
						return duplicateKeys
					end

					function H.getPetDuplicateKeys(targetKey, inventory)
						local invKey = H.resolveInventoryKey(inventory, targetKey)
						local target = inventory[invKey]
						if type(target) ~= "table" then
							return {}
						end

						local targetType = tonumber(target.ptype)
						if not targetType then
							return {}
						end

						local duplicates = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" then
								local resolvedKey = H.resolveInventoryKey(inventory, key)
								if resolvedKey ~= invKey
									and tonumber(entry.ptype) == targetType
									and not entry.locked
									and H.resolvePetEntryEvoLevel(entry) == 0 then
									table.insert(duplicates, resolvedKey)
								end
							end
						end

						table.sort(duplicates, function(a, b)
							return tostring(a) < tostring(b)
						end)
						return duplicates
					end

					function H.getArtifactDuplicateKeys(targetKey, inventory)
						local invKey = H.resolveInventoryKey(inventory, targetKey)
						local target = inventory[invKey]
						if type(target) ~= "table" then
							return {}
						end

						local targetId = H.resolveArtifactEntryId(target)
						if not targetId then
							return {}
						end

						local duplicates = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" then
								local resolvedKey = H.resolveInventoryKey(inventory, key)
								if resolvedKey ~= invKey
									and H.resolveArtifactEntryId(entry) == targetId
									and not entry.locked
									and not entry.equipped
									and H.resolveArtifactEntryEvoLevel(entry) == 0 then
									table.insert(duplicates, resolvedKey)
								end
							end
						end

						table.sort(duplicates, function(a, b)
							return tostring(a) < tostring(b)
						end)
						return duplicates
					end

					function H.pickPetEvolveTarget(inventory, req)
						local grouped = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and not entry.locked then
								local petType = tonumber(entry.ptype)
								if petType and H.resolvePetEntryEvoLevel(entry) < req.maxPetEvolutions then
									local invKey = H.resolveInventoryKey(inventory, key)
									grouped[petType] = grouped[petType] or {}
									table.insert(grouped[petType], {
										key = invKey,
										level = entry.level or 1,
										evo = H.resolvePetEntryEvoLevel(entry),
									})
								end
							end
						end

						local bestTarget = nil
						local bestLevel = -1
						for _, entries in pairs(grouped) do
							local baseEntries = {}
							for _, item in ipairs(entries) do
								if item.evo == 0 then
									table.insert(baseEntries, item)
								end
							end
							if #baseEntries >= req.totalRequired then
								for _, item in ipairs(baseEntries) do
									if item.level > bestLevel then
										bestLevel = item.level
										bestTarget = item.key
									end
								end
							end
						end

						return bestTarget
					end

					function H.pickArtifactEvolveTarget(inventory, req)
						local grouped = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and not entry.locked then
								local artifactId = H.resolveArtifactEntryId(entry)
								if artifactId and H.resolveArtifactEntryEvoLevel(entry) < req.maxArtifactEvolutions then
									local invKey = H.resolveInventoryKey(inventory, key)
									grouped[artifactId] = grouped[artifactId] or {}
									table.insert(grouped[artifactId], {
										key = invKey,
										equipped = entry.equipped == true,
										evo = H.resolveArtifactEntryEvoLevel(entry),
									})
								end
							end
						end

						local bestTarget = nil
						local bestScore = -1
						for _, entries in pairs(grouped) do
							local baseEntries = {}
							for _, item in ipairs(entries) do
								if item.evo == 0 then
									table.insert(baseEntries, item)
								end
							end
							if #baseEntries >= req.totalRequired then
								for _, item in ipairs(baseEntries) do
									local score = item.equipped and 1 or 0
									if score > bestScore or (score == bestScore and (not bestTarget or tostring(item.key) < tostring(bestTarget))) then
										bestScore = score
										bestTarget = item.key
									end
								end
							end
						end

						return bestTarget
					end

					function H.tryEvolvePet(targetKey)
						local inventory = H.getPetInventoryData()
						if not inventory then
							return false
						end

						local invKey = H.resolveInventoryKey(inventory, targetKey)
						local entry = inventory[invKey]
						if type(entry) ~= "table" then
							return false
						end

						local req = H.getEvolveRequirements()
						if H.resolvePetEntryEvoLevel(entry) >= req.maxPetEvolutions then
							return false
						end

						local duplicates = H.trimDuplicateKeys(H.getPetDuplicateKeys(invKey, inventory), req.duplicateRequired)
						if #duplicates ~= req.duplicateRequired then
							return false
						end

						return H.isEvolveSuccess(H.callGameService("EvolvePet", invKey, duplicates))
					end

					function H.copyArtifactEntry(entry)
						if type(entry) ~= "table" then
							return nil
						end
						local copy = {}
						for key, value in pairs(entry) do
							copy[key] = value
						end
						return copy
					end

					function H.findArtifactWidgetByKey(key)
						local playerGui = player:FindFirstChild("PlayerGui")
						local hud = playerGui and playerGui:FindFirstChild("HUD")
						local screen = hud and hud:FindFirstChild("Screen")
						local artifactsView = screen and screen:FindFirstChild("ArtifactsView")
						local center = artifactsView and artifactsView:FindFirstChild("Center")
						local list = center and center:FindFirstChild("ArtifactsList")
						local scroll = list and list:FindFirstChild("ScrollingFrame")
						if not scroll then
							return nil
						end
						return scroll:FindFirstChild(tostring(key))
					end

					function H.fireArtifactDataUpdate(gameDataService, constants, key, entry)
						local updateKey = constants.RemoteEvents and constants.RemoteEvents.UPDATE_ARTIFACT_DATA
						local updateSignal = updateKey and gameDataService[updateKey]
						if not updateSignal or not updateSignal.Fire then
							return false
						end
						local ok = pcall(function()
							updateSignal:Fire(tostring(key), entry)
						end)
						return ok
					end

					function H.updateArtifactWidgetEvoDisplay(widget, evoLevel)
						if not widget or evoLevel <= 0 then
							return
						end

						local shine = widget:FindFirstChild("Shine")
						if shine then
							shine.Visible = true
						end

						local evoLabel = widget:FindFirstChild("evo")
						if not evoLabel then
							return
						end

						evoLabel.Visible = true
						local evoText = "EVO " .. tostring(evoLevel)
						if evoLabel:IsA("TextLabel") then
							evoLabel.Text = evoText
							return
						end

						local textLabel = evoLabel:FindFirstChild("TextLabel")
						if textLabel then
							textLabel.Text = evoText
						end
					end

					function H.applyArtifactEvolveLocalUI(keeperKey, duplicateKeys, keeperEntryBefore)
						local aero = H.getGlobal().Aero
						local gameDataService = aero and aero.Services and aero.Services.GameDataService
						local artifactsController = aero and aero.Controllers and aero.Controllers.ArtifactsUIController
						local constants = H.getSharedConstants()
						if not gameDataService or not constants then
							return
						end

						local keeperStr = tostring(keeperKey)
						local updatedEntry = H.copyArtifactEntry(keeperEntryBefore) or {}
						updatedEntry.evolutionlevel = H.resolveArtifactEntryEvoLevel(keeperEntryBefore) + 1

						for _, dupKey in ipairs(duplicateKeys) do
							H.fireArtifactDataUpdate(gameDataService, constants, dupKey, nil)
						end
						H.fireArtifactDataUpdate(gameDataService, constants, keeperStr, updatedEntry)

						local widget = H.findArtifactWidgetByKey(keeperStr)
						if widget then
							H.updateArtifactWidgetEvoDisplay(widget, updatedEntry.evolutionlevel)
						end

						if artifactsController and artifactsController.GetActiveSelection and artifactsController.ShowInfoPanes then
							local active = artifactsController:GetActiveSelection()
							if active and active:FindFirstChild("ArtifactUID") and active.ArtifactUID.Value == keeperStr then
								pcall(function()
									artifactsController:ShowInfoPanes(keeperStr)
								end)
							end
						elseif artifactsController and artifactsController.RefreshInventory then
							pcall(function()
								artifactsController:RefreshInventory()
							end)
						end
					end

					function H.tryEvolveArtifact(targetKey)
						local inventory = H.getArtifactInventoryData()
						if not inventory then
							return false
						end

						local invKey = H.resolveInventoryKey(inventory, targetKey)
						local entry = inventory[invKey]
						if type(entry) ~= "table" then
							return false
						end

						local req = H.getEvolveRequirements()
						if H.resolveArtifactEntryEvoLevel(entry) >= req.maxArtifactEvolutions then
							return false
						end

						local duplicateKeys = H.trimDuplicateKeys(H.getArtifactDuplicateKeys(invKey, inventory), req.duplicateRequired)
						if #duplicateKeys ~= req.duplicateRequired then
							return false
						end

						local entrySnapshot = H.copyArtifactEntry(entry)
						local ok = H.isEvolveSuccess(H.callGameService("EvolveArtifact", invKey, duplicateKeys))
						if ok then
							H.applyArtifactEvolveLocalUI(invKey, duplicateKeys, entrySnapshot)
						end
						return ok
					end

					function H.tryAutoEvolvePetsOnce()
						local inventory = H.getPetInventoryData()
						if not inventory then
							return false
						end

						local req = H.getEvolveRequirements()
						local targetKey = H.pickPetEvolveTarget(inventory, req)
						if not targetKey then
							return false
						end

						if H.tryEvolvePet(targetKey) then
							H.setStatus("Evolved pet (5 combined into 1 golden)")
							return true
						end

						return false
					end

					function H.tryAutoEvolveArtifactsOnce()
						local inventory = H.getArtifactInventoryData()
						if not inventory then
							return false
						end

						local req = H.getEvolveRequirements()
						local targetKey = H.pickArtifactEvolveTarget(inventory, req)
						if not targetKey then
							return false
						end

						if H.tryEvolveArtifact(targetKey) then
							H.setStatus("Evolved artifact (5 combined into 1 evolved)")
							return true
						end

						return false
					end

					function H.stopAutoEvolvePetsLoop()
						S.autoEvolvePetsRunning = false
					end

					function H.stopAutoEvolveArtifactsLoop()
						S.autoEvolveArtifactsRunning = false
					end

					function H.startAutoEvolvePetsLoop()
						if S.autoEvolvePetsLoopActive then
							return
						end
						S.autoEvolvePetsLoopActive = true

						task.spawn(function()
							for _ = 1, 40 do
								if H.getPetInventoryData() then
									break
								end
								task.wait(0.5)
							end

							while S.autoEvolvePetsRunning do
								H.tryAutoEvolvePetsOnce()
								task.wait(AUTO_EVOLVE_INTERVAL)
							end

							S.autoEvolvePetsLoopActive = false
						end)
					end

					function H.startAutoEvolveArtifactsLoop()
						if S.autoEvolveArtifactsLoopActive then
							return
						end
						S.autoEvolveArtifactsLoopActive = true

						task.spawn(function()
							for _ = 1, 40 do
								if H.getArtifactInventoryData() then
									break
								end
								task.wait(0.5)
							end

							while S.autoEvolveArtifactsRunning do
								H.tryAutoEvolveArtifactsOnce()
								task.wait(AUTO_EVOLVE_INTERVAL)
							end

							S.autoEvolveArtifactsLoopActive = false
						end)
					end

					function H.stopEquipBestSwordLoop()
						S.equipBestSwordRunning = false
					end

					function H.stopEquipBestSkinLoop()
						S.equipBestSkinRunning = false
					end

					function H.startEquipBestSwordLoop()
						if S.equipBestSwordLoopActive then
							return
						end
						S.equipBestSwordLoopActive = true

						task.spawn(function()
							for _ = 1, 40 do
								if H.getWeaponInventoryData() and H.getWeaponsModule() then
									break
								end
								task.wait(0.5)
							end

							while S.equipBestSwordRunning do
								H.tryEquipBestSword()
								task.wait(EQUIP_BEST_INTERVAL)
							end

							S.equipBestSwordLoopActive = false
						end)
					end

					function H.startEquipBestSkinLoop()
						if S.equipBestSkinLoopActive then
							return
						end
						S.equipBestSkinLoopActive = true

						task.spawn(function()
							for _ = 1, 40 do
								if H.getSkinInventoryData() and H.getSkinsModule() then
									break
								end
								task.wait(0.5)
							end

							while S.equipBestSkinRunning do
								H.tryEquipBestSkin()
								task.wait(EQUIP_BEST_INTERVAL)
							end

							S.equipBestSkinLoopActive = false
						end)
					end

					function H.getProtectedWeaponKeys()
						local protected = {}

						local equippedMain = H.getEquippedItemKey("weapon_equipped")
						local equippedOffhand = H.getEquippedItemKey("offhand_equipped")
						if equippedMain then
							protected[equippedMain] = true
						end
						if equippedOffhand and equippedOffhand ~= "0" then
							protected[equippedOffhand] = true
						end

						if S.equipBestSwordRunning then
							local bestMain, bestOffhand = H.getBestWeaponKeys(S.weaponSortStat)
							if bestMain then
								protected[bestMain] = true
							end
							if bestOffhand then
								protected[bestOffhand] = true
							end
						end

						return protected
					end

					function H.getProtectedSkinKeys()
						local protected = {}

						local equippedSkin = H.getEquippedItemKey("skin_equipped")
						if equippedSkin then
							protected[equippedSkin] = true
						end

						if S.equipBestSkinRunning then
							local bestSkin = H.getBestSkinKey(S.skinSortStat)
							if bestSkin then
								protected[bestSkin] = true
							end
						end

						return protected
					end

					function H.invokeSellInventoryItems(itemType, keys)
						if type(keys) ~= "table" or #keys == 0 then
							return false
						end

						local constants = H.getSharedConstants()
						local weaponType = constants and constants.ItemType and constants.ItemType.WEAPON or "weapon"
						local skinType = constants and constants.ItemType and constants.ItemType.SKIN or "skin"

						local aero = H.getGlobal().Aero
						local gameService = aero and aero.Services and aero.Services.GameService

						if #keys > 1 and gameService and gameService.OnMultiSellRequest then
							local ok, result = pcall(function()
								return gameService:OnMultiSellRequest(itemType, keys)
							end)
							if ok and result ~= false then
								return true
							end
						end

						local soldAny = false
						for _, key in ipairs(keys) do
							local ok, result
							if itemType == weaponType and gameService and gameService.SellWeapon then
								ok, result = pcall(function()
									return gameService:SellWeapon(key)
								end)
							elseif itemType == skinType and gameService and gameService.SellSkin then
								ok, result = pcall(function()
									return gameService:SellSkin(key)
								end)
							else
								local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
								local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
								local remoteFolder = services and services:FindFirstChild("GameService")
								local remoteName = itemType == weaponType and "SellWeapon" or "SellSkin"
								local remote = remoteFolder and remoteFolder:FindFirstChild(remoteName)
								if remote and remote:IsA("RemoteFunction") then
									ok, result = pcall(function()
										return remote:InvokeServer(key)
									end)
								end
							end
							if ok and result ~= false then
								soldAny = true
							end
						end

						return soldAny
					end

					function H.tryAutoDeleteWeapons()
						if S.equipBestSwordRunning then
							H.tryEquipBestSword()
						end

						local constants = H.getSharedConstants()
						local inventory = H.getWeaponInventoryData()
						if not constants or not inventory then
							return false
						end

						local protected = H.getProtectedWeaponKeys()
						local toSell = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and entry.id then
								local keyStr = tostring(key)
								if not protected[keyStr] then
									table.insert(toSell, keyStr)
								end
							end
						end

						if #toSell == 0 then
							return false
						end

						if H.invokeSellInventoryItems(constants.ItemType.WEAPON, toSell) then
							H.setStatus("Deleted " .. #toSell .. " weapon(s)")
							return true
						end

						return false
					end

					function H.tryAutoDeleteSkins()
						if S.equipBestSkinRunning then
							H.tryEquipBestSkin()
						end

						local constants = H.getSharedConstants()
						local inventory = H.getSkinInventoryData()
						if not constants or not inventory then
							return false
						end

						local protected = H.getProtectedSkinKeys()
						local toSell = {}
						for key, entry in pairs(inventory) do
							if type(entry) == "table" and entry.id then
								local keyStr = tostring(key)
								if not protected[keyStr] then
									table.insert(toSell, keyStr)
								end
							end
						end

						if #toSell == 0 then
							return false
						end

						if H.invokeSellInventoryItems(constants.ItemType.SKIN, toSell) then
							H.setStatus("Deleted " .. #toSell .. " skin(s)")
							return true
						end

						return false
					end

					function H.stopAutoDeleteWeaponsLoop()
						S.autoDeleteWeaponsRunning = false
					end

					function H.stopAutoDeleteSkinsLoop()
						S.autoDeleteSkinsRunning = false
					end

					function H.startAutoDeleteWeaponsLoop()
						if S.autoDeleteWeaponsLoopActive then
							return
						end
						S.autoDeleteWeaponsLoopActive = true

						task.spawn(function()
							for _ = 1, 40 do
								if H.getWeaponInventoryData() and H.getWeaponsModule() then
									break
								end
								task.wait(0.5)
							end

							while S.autoDeleteWeaponsRunning do
								H.tryAutoDeleteWeapons()
								task.wait(AUTO_DELETE_INTERVAL)
							end

							S.autoDeleteWeaponsLoopActive = false
						end)
					end

					function H.startAutoDeleteSkinsLoop()
						if S.autoDeleteSkinsLoopActive then
							return
						end
						S.autoDeleteSkinsLoopActive = true

						task.spawn(function()
							for _ = 1, 40 do
								if H.getSkinInventoryData() and H.getSkinsModule() then
									break
								end
								task.wait(0.5)
							end

							while S.autoDeleteSkinsRunning do
								H.tryAutoDeleteSkins()
								task.wait(AUTO_DELETE_INTERVAL)
							end

							S.autoDeleteSkinsLoopActive = false
						end)
					end

					function H.createUI()
						H.disconnectUiRotation("topbar")
						H.disconnectUiRotation("minimized")
						H.disconnectMinimizedDragConns()

						H.destroyGateUi()

						if UI.window then
							pcall(function()
								if UI.window.Destroy then
									UI.window:Destroy()
								end
							end)
							UI.window = nil
						end

						local ok, WindUI = H.loadWindUI()
						if not ok or not WindUI then
							error("WindUI failed to load: " .. tostring(WindUI))
						end

						local Window = WindUI:CreateWindow({
							Title = "Exon Hub",
							Folder = "ExonHub",
							NewElements = true,
							ToggleKey = H.getMinimizeHotkeyEnum(),
							OpenButton = {
								Enabled = false,
							},
						})

						UI.window = Window
						UI.windUI = WindUI
						H.applyExonHubWindowIcon(Window)
						H.createExonHubFloatingToggle(Window)

						local MainSection = Window:Section({
							Title = "Main",
							Opened = true,
						})

						local FarmingTab = MainSection:Tab({
							Title = "Farming",
							Icon = "solar:leaf-bold",
						})

						local FarmSection = H.createStaticBoxSection(FarmingTab, "Farm")

						UI.clickerToggleElement = FarmSection:Toggle({
							Title = "Auto Click / Train",
							Value = false,
							Callback = function(on)
								if S.suppressClickerSync then
									return
								end
								if H.setAutoClicker then
									H.setAutoClicker(on == true, true)
								end
							end,
						})

						UI.farmToggleElement = FarmSection:Toggle({
							Title = "Auto Collect Orbs",
							Value = false,
							Callback = function(on)
								if S.suppressToggleSync then
									return
								end
								if H.setRunning then
									H.setRunning(on == true, true)
								end
							end,
						})

						UI.autoQuestToggleElement = FarmSection:Toggle({
							Title = "Auto Quest",
							Desc = "Starts quests and completes Borock, Demon King, golden egg, and orb tasks",
							Value = false,
							Callback = function(on)
								if S.suppressAutoQuestSync then
									return
								end
								if H.setAutoQuest then
									H.setAutoQuest(on == true, true)
								end
							end,
						})

						UI.autoQuestDeleteToggleElement = FarmSection:Toggle({
							Title = "Auto Delete Quest Drops",
							Desc = "Sells items from chests, crates, and pet eggs opened for quest progress",
							Value = S.autoQuestDeleteRewards == true,
							Callback = function(on)
								if S.suppressAutoQuestDeleteSync then
									return
								end
								if H.setAutoQuestDeleteRewards then
									H.setAutoQuestDeleteRewards(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(FarmSection)

						local MaxOutSection = H.createStaticBoxSection(FarmingTab, "Training — Max Out", "solar:fire-bold")

						UI.maxOutToggleElement = MaxOutSection:Toggle({
							Title = "Auto Max Out",
								Desc = "Turns on train + orbs, opens crates for exact best gear, deletes junk (keeps better rarity), then upgrades",
							Value = S.maxOutRunning == true,
							Callback = function(on)
								if S.suppressMaxOutToggleSync then
									return
								end
								if H.setMaxOut then
									H.setMaxOut(on == true, true)
								end
							end,
						})

						local okMaxOutDropdown, maxOutDropdownErr = pcall(function()
							UI.maxOutDropdownElement = MaxOutSection:Dropdown({
								Title = "Max Out Rarity",
								Desc = "Only one rarity at a time (Common / Rare / Epic / Legendary / Mythic)",
								Values = MAX_OUT_OPTIONS,
								Value = S.maxOutTier or "Common",
								Multi = false,
								AllowNone = false,
								Callback = function(selected)
									if S.suppressMaxOutSync or S.suppressSettingsDropdownSync then
										return
									end
									H.setMaxOutTier(selected, true)
								end,
							})
						end)

						if not okMaxOutDropdown then
							warn("[ExonHub] Max Out dropdown failed:", maxOutDropdownErr)
						end

						H.finalizeStaticSection(MaxOutSection)

						local AutoUpgradeSection = H.createStaticBoxSection(FarmingTab, "Auto Upgrade")

						local okUpgradeDropdown, _ = pcall(function()
							UI.autoUpgradeDropdownElement = AutoUpgradeSection:Dropdown({
								Title = "Upgrade Targets",
								Desc = "Splits gold evenly â€” always upgrades the lowest level item next",
								Values = AUTO_UPGRADE_SLOT_LABELS,
								Value = H.getAutoUpgradeTargetLabels(),
								Multi = true,
								AllowNone = true,
								Callback = function(selected)
									if S.suppressSettingsDropdownSync then
										return
									end
									H.setAutoUpgradeTargets(selected)
									if S.autoUpgradeRunning then
										H.tryAutoUpgradeBurst()
									end
								end,
							})
						end)

						if not okUpgradeDropdown then
							warn("[ExonHub] Auto upgrade dropdown failed")
						end

						UI.autoUpgradeToggleElement = AutoUpgradeSection:Toggle({
							Title = "Auto Upgrade",
							Desc = "Rapidly upgrades selected gear whenever you have gold",
							Value = false,
							Callback = function(on)
								if S.suppressAutoUpgradeSync then
									return
								end
								if H.setAutoUpgrade then
									H.setAutoUpgrade(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(AutoUpgradeSection)

						local EquipBestSection = H.createStaticBoxSection(FarmingTab, "Equip Best")

						UI.equipBestSwordToggleElement = EquipBestSection:Toggle({
							Title = "Equip Best Sword",
							Desc = "Top 2 by stat; faster weapon (APS) goes main hand, slower offhand",
							Value = false,
							Callback = function(on)
								if S.suppressEquipBestSwordSync then
									return
								end
								if H.setEquipBestSword then
									H.setEquipBestSword(on == true, true)
								end
							end,
						})

						UI.weaponSortDropdownElement = H.createStatPicker(EquipBestSection, {
							title = "Sword Priority",
							desc = "Sort weapons by this stat",
							options = WEAPON_SORT_OPTIONS,
							getStat = function()
								return S.weaponSortStat
							end,
							setStat = function(value)
								S.weaponSortStat = value
							end,
							onChange = function()
								if S.equipBestSwordRunning then
									H.tryEquipBestSword()
								end
							end,
						})

						UI.equipBestSkinToggleElement = EquipBestSection:Toggle({
							Title = "Equip Best Skin",
							Desc = "Keeps your best skin equipped",
							Value = false,
							Callback = function(on)
								if S.suppressEquipBestSkinSync then
									return
								end
								if H.setEquipBestSkin then
									H.setEquipBestSkin(on == true, true)
								end
							end,
						})

						UI.skinSortDropdownElement = H.createStatPicker(EquipBestSection, {
							title = "Skin Priority",
							desc = "Sort skins by this stat",
							options = SKIN_SORT_OPTIONS,
							getStat = function()
								return S.skinSortStat
							end,
							setStat = function(value)
								S.skinSortStat = value
							end,
							onChange = function()
								if S.equipBestSkinRunning then
									H.tryEquipBestSkin()
								end
							end,
						})

						H.finalizeStaticSection(EquipBestSection)

						local EvolveSection = H.createStaticBoxSection(FarmingTab, "Evolve", "solar:star-bold")

						UI.autoEvolvePetsToggleElement = EvolveSection:Toggle({
							Title = "Auto Evolve Pets",
							Desc = "Needs 5 matching pets — keeps highest level, consumes the other 4",
							Value = false,
							Callback = function(on)
								if S.suppressAutoEvolvePetsSync then
									return
								end
								if H.setAutoEvolvePets then
									H.setAutoEvolvePets(on == true, true)
								end
							end,
						})

						UI.autoEvolveArtifactsToggleElement = EvolveSection:Toggle({
							Title = "Auto Evolve Artifacts",
							Desc = "Needs 5 matching artifacts — keeps 1 evolved, consumes the other 4",
							Value = false,
							Callback = function(on)
								if S.suppressAutoEvolveArtifactsSync then
									return
								end
								if H.setAutoEvolveArtifacts then
									H.setAutoEvolveArtifacts(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(EvolveSection)

						local AutoDeleteSection = H.createStaticBoxSection(FarmingTab, "Auto Delete")

						UI.autoDeleteWeaponsToggleElement = AutoDeleteSection:Toggle({
							Title = "Auto Delete Weapons",
							Desc = "Sells unequipped weapons. With Equip Best on, equips best first",
							Value = false,
							Callback = function(on)
								if S.suppressAutoDeleteWeaponsSync then
									return
								end
								if H.setAutoDeleteWeapons then
									H.setAutoDeleteWeapons(on == true, true)
								end
							end,
						})

						UI.autoDeleteSkinsToggleElement = AutoDeleteSection:Toggle({
							Title = "Auto Delete Skins",
							Desc = "Sells unequipped skins. With Equip Best on, equips best first",
							Value = false,
							Callback = function(on)
								if S.suppressAutoDeleteSkinsSync then
									return
								end
								if H.setAutoDeleteSkins then
									H.setAutoDeleteSkins(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(AutoDeleteSection)

						local RebirthsTab = MainSection:Tab({
							Title = "Rebirths",
							Icon = "solar:restart-bold",
						})

						local RebirthSection = H.createStaticBoxSection(RebirthsTab, "Rebirth")

						UI.autoRebirthToggleElement = RebirthSection:Toggle({
							Title = "Auto Rebirth",
							Value = false,
							Callback = function(on)
								if S.suppressAutoRebirthSync then
									return
								end
								if H.setAutoRebirth then
									H.setAutoRebirth(on == true, true)
								end
							end,
						})

						UI.autoRebirthLevelInputElement = RebirthSection:Input({
							Title = "Rebirth Level",
							Desc = "Rebirth when you reach this level (min 100)",
							Value = tostring(S.autoRebirthTargetLevel),
							Placeholder = "100",
							Callback = function(text)
								if S.suppressAutoRebirthLevelSync then
									return
								end
								H.setAutoRebirthTargetLevel(text, true)
							end,
						})

						H.finalizeStaticSection(RebirthSection)

						local MassUpgradeSection = H.createStaticBoxSection(RebirthsTab, "Mass Upgrade")

						UI.autoMassUpgradeToggleElement = MassUpgradeSection:Toggle({
							Title = "Auto Mass Upgrade",
							Value = false,
							Callback = function(on)
								if S.suppressAutoMassUpgradeSync then
									return
								end
								if H.setAutoMassUpgrade then
									H.setAutoMassUpgrade(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(MassUpgradeSection)

						local CratesTab = MainSection:Tab({
							Title = "Crates",
							Icon = "solar:box-bold",
						})

						local CratesSection = H.createStaticBoxSection(CratesTab, "Inventory Crates")

						UI.autoSellChestToggleElement = CratesSection:Toggle({
							Title = "Auto Sell Chest",
							Desc = "Sells all weapon and skin crates in your inventory",
							Value = false,
							Callback = function(on)
								if S.suppressAutoSellChestSync then
									return
								end
								if H.setAutoSellChest then
									H.setAutoSellChest(on == true, true)
								end
							end,
						})

						UI.autoOpenChestToggleElement = CratesSection:Toggle({
							Title = "Auto Open Chest",
							Desc = "Opens sword/weapon and skin chests at the same time as fast as possible",
							Value = false,
							Callback = function(on)
								if S.suppressAutoOpenChestSync then
									return
								end
								if H.setAutoOpenChest then
									H.setAutoOpenChest(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(CratesSection)

						H.buildWorldCrateKindSection(CratesTab, "Legendary Crates", "legendary")
						H.buildWorldCrateKindSection(CratesTab, "Mythic Crates", "mythic")
						H.buildWorldCrateKindSection(CratesTab, "Pet Crates", "pet")
						H.buildWorldCrateKindSection(CratesTab, "Artifact Crates", "artifact")

						local BossesTab = MainSection:Tab({
							Title = "Bosses",
							Icon = "solar:crown-bold",
						})

						local BossesSection = H.createStaticBoxSection(BossesTab, "Bosses", "solar:crown-bold")

						local okBossDropdown, _ = pcall(function()
							UI.autoBossDropdownElement = BossesSection:Dropdown({
								Title = "Boss Targets",
								Desc = "Borock (Dungeon) and Demon King (Temple)",
								Values = AUTO_BOSS_OPTION_LABELS,
								Value = H.getAutoBossTargetLabels(),
								Multi = true,
								AllowNone = true,
								Callback = function(selected)
									if S.suppressSettingsDropdownSync then
										return
									end
									H.setAutoBossTargets(selected)
								end,
							})
						end)

						if not okBossDropdown then
							warn("[ExonHub] Auto boss dropdown failed")
						end

						UI.autoBossToggleElement = BossesSection:Toggle({
							Title = "Auto Boss",
							Desc = "Fights lowest-HP boss; snaps once then tweens to follow",
							Value = false,
							Callback = function(on)
								if S.suppressAutoBossSync then
									return
								end
								if H.setAutoBoss then
									H.setAutoBoss(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(BossesSection)

						local OthersSection = Window:Section({
							Title = "Others",
							Opened = true,
						})

						local MiscTab = OthersSection:Tab({
							Title = "Misc",
							Icon = "solar:widget-bold",
						})

						local MiscSection = H.createStaticBoxSection(MiscTab, "Misc", "solar:widget-bold")

						UI.antiAfkToggleElement = MiscSection:Toggle({
							Title = "Anti AFK",
							Desc = "Blocks the 20m idle kick (Idled hook + 30s input backup)",
							Value = true,
							Callback = function(on)
								if S.suppressAntiAfkSync then
									return
								end
								if H.setAntiAfk then
									H.setAntiAfk(on == true, true)
								end
							end,
						})

						UI.autoKillToggleElement = MiscSection:Toggle({
							Title = "Auto Kill",
							Desc = "Follow and attack players within GroundPart radius",
							Value = false,
							Callback = function(on)
								if S.suppressAutoKillSync then
									return
								end
								if H.setAutoKill then
									H.setAutoKill(on == true, true)
								end
							end,
						})

						UI.streamerModeToggleElement = MiscSection:Toggle({
							Title = "Streamer Mode",
							Desc = "Hides your name as Exon Hub and swaps portrait to Exon Hub icon",
							Value = false,
							Callback = function(on)
								if S.suppressStreamerModeSync then
									return
								end
								if H.setStreamerMode then
									H.setStreamerMode(on == true, true)
								end
							end,
						})

						H.finalizeStaticSection(MiscSection)
						H.buildGoldenEggTeleportSection(MiscTab)
						H.buildMiscTeleportSection(MiscTab)

						local EventTab = OthersSection:Tab({
							Title = "Event",
							Icon = "solar:calendar-bold",
						})

						H.buildShellEggEventSection(EventTab, "Event Eggs")
						H.buildBeachGoalsEventSection(EventTab, "Beach Soccer")
						H.buildKothEventSection(EventTab, "King of the Hill")
						H.buildMineRaceEventSection(EventTab, "Shell Race")

						local SettingsTab = OthersSection:Tab({
							Title = "Settings",
							Icon = "solar:settings-bold",
						})

						local SettingsSection = H.createStaticBoxSection(SettingsTab, "Settings", "solar:settings-bold")

						local okMinimizeHotkey, minimizeHotkeyErr = pcall(function()
							UI.minimizeHotkeyKeybindElement = SettingsSection:Keybind({
								Title = "Minimize Hotkey",
								Desc = "Show or hide Exon Hub (default: Left Alt)",
								Value = H.getMinimizeHotkeyName(),
								Callback = function(keyName)
									if S.suppressSettingsDropdownSync then
										return
									end
									H.setMinimizeHotkey(keyName, true)
								end,
							})
						end)

						if not okMinimizeHotkey then
							warn("[ExonHub] Minimize hotkey keybind failed:", minimizeHotkeyErr)
						end

						UI.autoSaveSettingsToggleElement = SettingsSection:Toggle({
							Title = "Auto Save Settings",
							Desc = "Remembers your toggles and options for the next time you execute",
							Value = S.autoSaveSettingsEnabled == true,
							Callback = function(on)
								if S.suppressAutoSaveSettingsSync then
									return
								end
								if H.setAutoSaveSettings then
									H.setAutoSaveSettings(on == true, true)
								end
							end,
						})

						SettingsSection:Button({
							Title = "Reset ExonHub",
							Desc = "Delete all saved ExonHub and WindUI files from your executor",
							Callback = function()
								H.promptResetExonHub()
							end,
						})

						H.finalizeStaticSection(SettingsSection)

						if Window.SelectTab and FarmingTab.Index then
							Window:SelectTab(FarmingTab.Index)
						end
					end

					function H.showError(msg)
						warn("[ExonHub] ERROR:", msg)
						if debug and debug.traceback then
							warn("[ExonHub] traceback:", debug.traceback(tostring(msg), 2))
						end
						local errGui = Instance.new("ScreenGui")
						errGui.Name = "ExonHubError"
						errGui.ResetOnSpawn = false
						errGui.Parent = playerGui
						local lbl = Instance.new("TextLabel")
						lbl.Size = UDim2.fromOffset(480, 120)
						lbl.Position = UDim2.new(0.5, -240, 0, 20)
						lbl.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
						lbl.TextColor3 = Color3.new(1, 1, 1)
						lbl.Text = "Exon Hub error:\n" .. tostring(msg)
						lbl.TextWrapped = true
						lbl.TextSize = 14
						lbl.Parent = errGui
					end
					local NODE_NAME = "ResourceNode"
					local NODE_TYPE_NAMES = { [1] = "XP", [2] = "Gold", [3] = "Speed", [4] = "Event" }

					function H.getNodesFolder()
						local current = workspace
						for i, name in ipairs(NODES_PATH) do
							local child = current:FindFirstChild(name)
							if not child then
								local timeout = (i == #NODES_PATH) and FOLDER_WAIT or 5
								child = current:WaitForChild(name, timeout)
							end
							if not child then
								warn("[ExonHub] missing:", name, "in", current:GetFullName())
								return nil
							end
							current = child
						end
						return current
					end

					function H.getNodeTypeValue(node)
						local nodeType = node:FindFirstChild("NodeType")
						if nodeType and nodeType:IsA("IntValue") then
							return nodeType.Value
						end
						return 0
					end

					function H.isActiveNode(node)
						if not node.Parent then return false end
						if node.Name ~= NODE_NAME or not node:IsA("BasePart") then return false end
						return H.getNodeTypeValue(node) > 0
					end

					function H.isNodeCollected(node)
						if not node.Parent then return true end
						return H.getNodeTypeValue(node) == 0
					end

					function H.hasClientVisual(node)
						return node:FindFirstChild("Prefab") ~= nil
					end

					function H.isSkipped(node)
						local untilTime = S.skipUntil[node]
						return untilTime ~= nil and os.clock() < untilTime
					end

					function H.markNodeFailed(node, reason)
						S.failCount[node] = (S.failCount[node] or 0) + 1
						local fails = S.failCount[node]
						local nodeType = H.getNodeTypeValue(node)
						print(string.format(
							"[ExonHub] FAIL #%d | NodeType=%d | Prefab=%s | %s",
							fails, nodeType, H.hasClientVisual(node) and "yes" or "NO", reason
						))
						if fails >= MAX_FAILS_BEFORE_SKIP then
							S.skipUntil[node] = os.clock() + SKIP_SECONDS
							S.failCount[node] = 0
						end
					end

					function H.clearNodeFailure(node)
						S.failCount[node] = nil
						S.skipUntil[node] = nil
					end

					function H.getNodeLabel(node, typeValue)
						local nodeType = typeValue or H.getNodeTypeValue(node)
						local typeName = NODE_TYPE_NAMES[nodeType] or ("Type" .. nodeType)
						return "ResourceNode (" .. typeName .. ")"
					end

					function H.findAllActiveNodes(folder)
						local nodes = {}
						for _, child in ipairs(folder:GetChildren()) do
							if H.isActiveNode(child) then
								table.insert(nodes, child)
							end
						end
						table.sort(nodes, function(a, b)
							return a:GetFullName() < b:GetFullName()
						end)
						return nodes
					end

					function H.getAllActiveNodes()
						local folder = H.getNodesFolder()
						if not folder then return {} end
						return H.findAllActiveNodes(folder)
					end

					function H.debugScan()
						print("========== ExonHub DEBUG ==========")
						local folder = H.getNodesFolder()
						if not folder then
							print("FAILED: workspace.Scene.ResourceNodes1 not found")
							return
						end
						local children = folder:GetChildren()
						local active, empty, ghost = 0, 0, 0
						local byType = { XP = 0, Gold = 0, Speed = 0, Event = 0 }
						for _, child in ipairs(children) do
							if child.Name == NODE_NAME and child:IsA("BasePart") then
								local nodeType = H.getNodeTypeValue(child)
								if nodeType > 0 then
									active = active + 1
									local typeName = NODE_TYPE_NAMES[nodeType]
									if typeName and byType[typeName] ~= nil then
										byType[typeName] = byType[typeName] + 1
									end
									if not child:FindFirstChild("Prefab") then
										ghost = ghost + 1
									end
								else
									empty = empty + 1
								end
							end
						end
						print("active/empty:", active, "/", empty)
						print("XP:", byType.XP, "Gold:", byType.Gold, "Speed:", byType.Speed, "Event:", byType.Event)
						print("Farmable (all active types):", active)
						print("===============================================")
					end

					function H.getCharacterRoot()
						local character = player.Character
						if not character then return nil end
						return character:FindFirstChild("HumanoidRootPart")
					end

					function H.getHumanoid()
						local character = player.Character
						if not character then return nil end
						return character:FindFirstChildOfClass("Humanoid")
					end

					function H.getActiveNodes()
						local folder = H.getNodesFolder()
						if not folder then return {} end

						local nodes = H.findAllActiveNodes(folder)
						local filtered = {}
						for _, node in ipairs(nodes) do
							if not H.isSkipped(node) then
								table.insert(filtered, node)
							end
						end
						nodes = filtered

						local root = H.getCharacterRoot()
						table.sort(nodes, function(a, b)
							if root then
								return (a.Position - root.Position).Magnitude < (b.Position - root.Position).Magnitude
							end
							return a:GetFullName() < b:GetFullName()
						end)
						return nodes
					end

					function H.waitForNodeCollected(node, timeout)
						if H.isNodeCollected(node) then return true end

						local collected = false
						local nodeType = node:FindFirstChild("NodeType")
						local connection = nil

						if nodeType and nodeType:IsA("IntValue") then
							connection = nodeType.Changed:Connect(function(value)
								if value == 0 then collected = true end
							end)
						end

						local start = os.clock()
						while os.clock() - start < timeout do
							if not S.running then
								if connection then connection:Disconnect() end
								return false
							end
							if collected or H.isNodeCollected(node) then
								if connection then connection:Disconnect() end
								return true
							end
							task.wait(COLLECT_POLL)
						end

						if connection then connection:Disconnect() end
						return H.isNodeCollected(node)
					end

					function H.resetOrbFarmMovement()
						S.orbFirstSnapDone = false
						S.orbGroundTeleported = false
						H.cancelOrbFollowTween()
					end

					function H.getOrbStandCFrame(node)
						return CFrame.new(node.Position + Vector3.new(0, 2, 0))
					end

					function H.cancelOrbFollowTween()
						if S.orbFollowTween then
							pcall(function()
								S.orbFollowTween:Cancel()
							end)
							S.orbFollowTween = nil
						end
					end

					function H.moveToOrbNode(node, useSnap)
						local hrp = H.getCharacterRoot()
						if not hrp or not node or not node.Parent then
							return false
						end

						if S.orbGroundTeleported then
							useSnap = false
							S.orbGroundTeleported = false
						end

						local goal = H.getOrbStandCFrame(node)
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.AssemblyAngularVelocity = Vector3.zero

						if useSnap then
							hrp.CFrame = goal
							return true
						end

						local dist = (hrp.Position - goal.Position).Magnitude
						if dist < 0.15 then
							return true
						end

						H.cancelOrbFollowTween()

						local duration = math.max(dist / ORB_FOLLOW_SPEED, 0.06)
						local finished = false
						local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
							CFrame = goal,
						})
						S.orbFollowTween = tween
						tween.Completed:Connect(function(playbackState)
							if playbackState == Enum.PlaybackState.Completed then
								finished = true
							end
						end)
						tween:Play()

						local deadline = os.clock() + duration + 0.35
						while not finished and os.clock() < deadline do
							if not S.running then
								H.cancelOrbFollowTween()
								return false
							end
							local hum = H.getHumanoid()
							if not hum or hum.Health <= 0 then
								H.resetOrbFarmMovement()
								return false
							end
							if H.isNodeCollected(node) then
								H.cancelOrbFollowTween()
								return true
							end
							task.wait(COLLECT_POLL)
						end

						H.cancelOrbFollowTween()
						return finished
					end

					function H.tpCollectAtNode(node)
						if not S.running or H.isNodeCollected(node) then return H.isNodeCollected(node) end
						if not H.getCharacterRoot() then return false end

						local useSnap = not S.orbFirstSnapDone
						if not H.moveToOrbNode(node, useSnap) then
							return false
						end
						if useSnap then
							S.orbFirstSnapDone = true
						end

						task.wait(0.05)
						if not S.running then return false end

						local collected = H.waitForNodeCollected(node, COLLECT_WAIT)
						if collected and S.running then
							task.wait((ORB_COLLECT_PAUSE_MIN + ORB_COLLECT_PAUSE_MAX) * 0.5)
						end
						return collected
					end

					function H.tryCollectAtNode(node)
						return H.tpCollectAtNode(node)
					end

					function H.processNode(node, verbose)
						if not S.running or S.isProcessing then return false end
						S.isProcessing = true

						local nodeType = H.getNodeTypeValue(node)
						local label = H.getNodeLabel(node, nodeType)
						local useSnap = not S.orbFirstSnapDone
						H.setStatus((useSnap and "TP" or "Tween") .. " → " .. label)

						if not H.getCharacterRoot() then
							H.setStatus("No character â€” spawn first")
							S.isProcessing = false
							return false
						end

						local claimed = H.tryCollectAtNode(node)
						if claimed then
							H.clearNodeFailure(node)
							H.setStatus("Claimed: " .. label)
						else
							H.markNodeFailed(node, "no collect")
							H.setStatus("Skipped: " .. label)
						end

						S.isProcessing = false
						return claimed
					end

					function H.farmOnce()
						if S.isProcessing then return 0 end
						local nodes = H.getActiveNodes()
						if #nodes == 0 then
							H.setStatus("No active nodes")
							return 0
						end

						local node = nodes[1]
						if not H.isNodeCollected(node) then
							if H.processNode(node, false) then return 1 end
						end
						return 0
					end

					function H.farmLoop()
						if S.farmLoopActive then return end
						S.farmLoopActive = true
						H.setStatus("Running...")
						while S.running do
							local hum = H.getHumanoid()
							if not hum or hum.Health <= 0 then
								H.resetOrbFarmMovement()
								H.setStatus("Waiting for respawn...")
								task.wait(0.5)
								continue
							end

							if not S.orbGroundTeleported and not S.orbFirstSnapDone then
								H.ensureOrbGroundTeleport()
								S.orbGroundTeleported = true
								task.wait(0.15)
							end

							local claimed = H.farmOnce()
							if not S.running then
								break
							end
							if claimed == 0 then
								H.setStatus("Waiting for nodes...")
								task.wait(0.5)
							end
						end
						S.farmLoopActive = false
						H.setStatus("Stopped")
					end

					function H.setRunningImpl(state, fromToggle)
						if S.running == state then return end
						S.running = state
						if S.running then
							H.resetOrbFarmMovement()
							H.ensureOrbGroundTeleport()
							S.orbGroundTeleported = true
							S.farmLoopActive = false
							print("[ExonHub] Farm ON")
							H.setStatus("Running...")
							task.spawn(H.farmLoop)
						else
							S.isProcessing = false
							H.resetOrbFarmMovement()
							print("[ExonHub] Farm OFF")
							H.setStatus("Stopping...")
						end
						if not fromToggle then
							H.syncFarmToggle(S.running)
						end
						H.scheduleSettingsSave()
					end

					H.setRunning = H.setRunningImpl

					function H.setAutoClickerImpl(state, fromToggle)
						if S.clickerRunning == state then
							return
						end

						if state then
							S.clickerRunning = true
							if H.shouldClickerUseSilentTrain() then
								H.applySilentTrainMode(true)
							else
								task.defer(function()
									if S.clickerRunning and not H.shouldClickerUseSilentTrain() then
										H.tryAeroAutoSwing(H.getPlayerController(), true)
									end
								end)
							end
							print("[ExonHub] Auto click ON")
							H.setStatus("Auto click ON")
							H.clickerLoop()
						else
							H.stopClickerLoop()
							print("[ExonHub] Auto click OFF")
							H.setStatus("Auto click OFF")
						end

						if not fromToggle then
							H.syncClickerToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoClicker = H.setAutoClickerImpl

					function H.setAutoRebirthImpl(state, fromToggle)
						if S.autoRebirthRunning == state then
							return
						end

						S.autoRebirthRunning = state
						if state then
							print("[ExonHub] Auto rebirth ON at level", S.autoRebirthTargetLevel)
							H.setStatus("Auto rebirth ON (level " .. S.autoRebirthTargetLevel .. ")")
							H.ensureAutoRebirthLevelListener()
							H.startAutoRebirthLoop()
							task.defer(function()
								if S.autoRebirthRunning and H.canAutoRebirthNow() then
									H.tryAutoRebirth()
								end
							end)
						else
							H.stopAutoRebirthLoop()
							print("[ExonHub] Auto rebirth OFF")
							H.setStatus("Auto rebirth OFF")
						end

						if not fromToggle then
							H.syncAutoRebirthToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoRebirth = H.setAutoRebirthImpl

					function H.setAutoMassUpgradeImpl(state, fromToggle)
						if S.autoMassUpgradeRunning == state then
							return
						end

						S.autoMassUpgradeRunning = state
						if state then
							print("[ExonHub] Auto mass upgrade ON")
							H.setStatus("Auto mass upgrade ON")
							H.startMassUpgradeLoop()
						else
							H.stopMassUpgradeLoop()
							print("[ExonHub] Auto mass upgrade OFF")
							H.setStatus("Auto mass upgrade OFF")
						end

						if not fromToggle then
							H.syncAutoMassUpgradeToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoMassUpgrade = H.setAutoMassUpgradeImpl

					function H.setAutoUpgradeImpl(state, fromToggle)
						if S.autoUpgradeRunning == state then
							return
						end

						S.autoUpgradeRunning = state
						if state then
							S.autoUpgradeFailStreak = 0
							H.invalidateUpgradeInventorySnapshots()
							H.ensureAutoUpgradeRebirthListener()
							print("[ExonHub] Auto upgrade ON")
							H.setStatus("Auto upgrade ON")
							H.tryAutoUpgradeBurst()
							H.ensureAutoUpgradeLoopRunning()
						else
							H.stopAutoUpgradeLoop()
							if not S.maxOutRunning then
								H.teardownAutoUpgradeRebirthListener()
							end
							print("[ExonHub] Auto upgrade OFF")
							H.setStatus("Auto upgrade OFF")
						end

						if not fromToggle then
							H.syncAutoUpgradeToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoUpgrade = H.setAutoUpgradeImpl

					function H.setAutoBossImpl(state, fromToggle)
						if S.autoBossRunning == state then
							return
						end

						S.autoBossRunning = state
						if state then
							print("[ExonHub] Auto boss ON")
							H.setStatus("Auto boss ON")
							H.startAutoBossLoop()
						else
							H.stopAutoBossLoop()
							print("[ExonHub] Auto boss OFF")
							H.setStatus("Auto boss OFF")
						end

						if not fromToggle then
							H.syncAutoBossToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoBoss = H.setAutoBossImpl

					function H.setAutoGoalsImpl(state, fromToggle)
						if S.autoGoalsRunning == state then
							return
						end

						S.autoGoalsRunning = state
						if state then
							S.autoGoalsScoredBalls = {}
							S.autoGoalsBallSpawns = {}
							S.autoGoalsLastKickBallName = nil
							S.autoGoalsLastKickGoalName = nil
							if S.clickerRunning or S.autoKothRunning then
								H.applySilentTrainMode(true)
							end
							print("[ExonHub] Auto goals ON")
							H.setStatus("Auto goals ON")
							H.startAutoGoalsLoop()
						else
							H.stopAutoGoalsLoop()
							print("[ExonHub] Auto goals OFF")
							H.setStatus("Auto goals OFF")
						end

						if not fromToggle then
							H.syncAutoGoalsToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoGoals = H.setAutoGoalsImpl

					function H.setAutoKothImpl(state, fromToggle)
						if S.autoKothRunning == state then
							return
						end

						S.autoKothRunning = state
						if state then
							S.autoKothLastSwingAt = 0
							if S.autoGoalsRunning then
								H.applySilentTrainMode(true)
							end
							print("[ExonHub] Auto KOTH ON")
							H.setStatus("Auto KOTH ON")
							H.startAutoKothLoop()
						else
							H.stopAutoKothLoop()
							print("[ExonHub] Auto KOTH OFF")
							H.setStatus("Auto KOTH OFF")
						end

						if not fromToggle then
							H.syncAutoKothToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoKoth = H.setAutoKothImpl

					function H.setAutoFishImpl(state, fromToggle)
						if S.autoFishRunning == state then
							return
						end

						S.autoFishRunning = state
						if state then
							S.autoFishPhase = FISHING_PHASE_IDLE
							print("[ExonHub] Auto fish ON")
							H.setStatus("Auto fish ON")
							H.startAutoFishLoop()
						else
							H.stopAutoFishLoop()
							print("[ExonHub] Auto fish OFF")
							H.setStatus("Auto fish OFF")
						end

						if not fromToggle then
							H.syncAutoFishToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoFish = H.setAutoFishImpl

					function H.setAutoMineRaceImpl(state, fromToggle)
						if S.autoMineRaceRunning == state then
							return
						end

						S.autoMineRaceRunning = state
						if state then
							print("[ExonHub] Auto mine race ON")
							H.setStatus("Auto mine race ON")
							H.startAutoMineRaceLoop()
						else
							H.stopAutoMineRaceLoop()
							print("[ExonHub] Auto mine race OFF")
							H.setStatus("Auto mine race OFF")
						end

						if not fromToggle then
							H.syncAutoMineRaceToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoMineRace = H.setAutoMineRaceImpl

					function H.setAutoQuestImpl(state, fromToggle)
						state = state == true
						if S.autoQuestRunning == state then
							if state then
								H.ensureAutoQuestLoopRunning()
							end
							return
						end

						S.autoQuestRunning = state
						if state then
							print("[ExonHub] Auto quest ON")
							H.setStatus("Auto quest ON")
							H.ensureAutoQuestLoopRunning()
						else
							H.stopAutoQuestLoop()
							print("[ExonHub] Auto quest OFF")
							H.setStatus("Auto quest OFF")
						end

						if not fromToggle then
							H.syncAutoQuestToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoQuest = H.setAutoQuestImpl

					function H.setAutoQuestDeleteRewardsImpl(state, fromToggle)
						if S.autoQuestDeleteRewards == state then
							return
						end

						S.autoQuestDeleteRewards = state
						if not fromToggle then
							H.syncAutoQuestDeleteToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoQuestDeleteRewards = H.setAutoQuestDeleteRewardsImpl

					function H.setAutoUpgradeRodImpl(state, fromToggle)
						if S.autoUpgradeRodRunning == state then
							return
						end

						S.autoUpgradeRodRunning = state
						if state then
							print("[ExonHub] Auto upgrade rod ON")
							H.setStatus("Auto upgrade rod ON")
							H.startAutoUpgradeRodLoop()
						else
							H.stopAutoUpgradeRodLoop()
							print("[ExonHub] Auto upgrade rod OFF")
							H.setStatus("Auto upgrade rod OFF")
						end

						if not fromToggle then
							H.syncAutoUpgradeRodToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoUpgradeRod = H.setAutoUpgradeRodImpl

					function H.setAutoKillImpl(state, fromToggle)
						if S.autoKillRunning == state then
							return
						end

						S.autoKillRunning = state
						if state then
							print("[ExonHub] Auto kill ON")
							H.setStatus("Auto kill ON")
							H.ensureWeaponEquipped(H.getPlayerController())
							H.startAutoKillLoop()
						else
							H.stopAutoKillLoop()
							print("[ExonHub] Auto kill OFF")
							H.setStatus("Auto kill OFF")
						end

						if not fromToggle then
							H.syncAutoKillToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoKill = H.setAutoKillImpl

					function H.setAntiAfkImpl(state, fromToggle)
						if S.antiAfkRunning == state then
							return
						end

						S.antiAfkRunning = state
						if state then
							H.enableAntiAfk()
							print("[ExonHub] Anti AFK ON")
							H.setStatus("Anti AFK ON")
						else
							H.disableAntiAfk()
							print("[ExonHub] Anti AFK OFF")
							H.setStatus("Anti AFK OFF")
						end

						if not fromToggle then
							H.syncAntiAfkToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAntiAfk = H.setAntiAfkImpl

					function H.setStreamerModeImpl(state, fromToggle)
						if S.streamerModeRunning == state then
							return
						end

						S.streamerModeRunning = state
						if state then
							H.captureStreamerModeBackup()
							H.applyStreamerModeVisuals()
							H.startStreamerModeLoop()
							print("[ExonHub] Streamer Mode ON")
							H.setStatus("Streamer Mode ON")
						else
							H.stopStreamerModeLoop()
							H.restoreStreamerModeVisuals()
							print("[ExonHub] Streamer Mode OFF")
							H.setStatus("Streamer Mode OFF")
						end

						if not fromToggle then
							H.syncStreamerModeToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setStreamerMode = H.setStreamerModeImpl

					function H.setAutoSellChestImpl(state, fromToggle)
						if S.autoSellChestRunning == state then
							return
						end

						S.autoSellChestRunning = state
						if state then
							print("[ExonHub] Auto sell chest ON")
							H.setStatus("Auto sell chest ON")
							H.startAutoSellChestLoop()
						else
							H.stopAutoSellChestLoop()
							print("[ExonHub] Auto sell chest OFF")
							H.setStatus("Auto sell chest OFF")
						end

						if not fromToggle then
							H.syncAutoSellChestToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoSellChest = H.setAutoSellChestImpl

					function H.setAutoOpenChestImpl(state, fromToggle, skipToggleSync)
						if S.autoOpenChestRunning == state then
							return
						end

						S.autoOpenChestRunning = state
						if state then
							print("[ExonHub] Auto open chest ON")
							H.setStatus("Auto open chest ON")
							H.startAutoOpenChestLoop()
						else
							H.stopAutoOpenChestLoop()
							print("[ExonHub] Auto open chest OFF")
							H.setStatus("Auto open chest OFF")
						end

						if not fromToggle and not skipToggleSync then
							H.syncAutoOpenChestToggle(state)
						end
						if not skipToggleSync then
							H.scheduleSettingsSave()
						end
					end

					H.setAutoOpenChest = H.setAutoOpenChestImpl

					function H.setCaveAutoOpenSlotImpl(slotId, state, fromToggle)
						local enabling = state == true and S.caveAutoOpenSlots[slotId] ~= true
						S.caveAutoOpenSlots[slotId] = state == true

						if enabling then
							H.resetCrateHuntObtained(slotId)
						end

						if state and not S.caveAutoOpenLoopActive then
							print("[ExonHub] Auto open ON:", slotId)
							H.setStatus("Auto open ON: " .. slotId)
							H.startCaveAutoOpenLoop()
						elseif not H.hasAnyCaveAutoOpenEnabled() then
							print("[ExonHub] World crate auto open OFF")
							H.setStatus("World crate auto open OFF")
						end

						if not fromToggle then
							H.syncCaveAutoOpenToggle(slotId, state)
						end
						H.scheduleSettingsSave()
					end

					H.setCaveAutoOpenSlot = H.setCaveAutoOpenSlotImpl

					function H.setAutoOpenShellEggSlotImpl(slotId, state, fromToggle)
						S.autoOpenShellEggSlots[slotId] = state == true

						if state and not S.shellEggAutoOpenLoopActive then
							print("[ExonHub] Shell egg auto open ON:", slotId)
							H.setStatus("Shell egg auto open ON")
							H.startShellEggAutoOpenLoop()
						elseif not H.hasAnyShellEggAutoOpenEnabled() then
							print("[ExonHub] Shell egg auto open OFF")
							H.setStatus("Shell egg auto open OFF")
						end

						if not fromToggle then
							H.syncAutoOpenShellEggToggle(slotId, state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoOpenShellEggSlot = H.setAutoOpenShellEggSlotImpl

					function H.setEquipBestSwordImpl(state, fromToggle)
						if S.equipBestSwordRunning == state then
							return
						end

						S.equipBestSwordRunning = state
						if state then
							print("[ExonHub] Equip best sword ON (" .. S.weaponSortStat .. ")")
							H.setStatus("Equip best sword ON")
							H.tryEquipBestSword()
							H.startEquipBestSwordLoop()
						else
							H.stopEquipBestSwordLoop()
							print("[ExonHub] Equip best sword OFF")
							H.setStatus("Equip best sword OFF")
						end

						if not fromToggle then
							H.syncEquipBestSwordToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setEquipBestSword = H.setEquipBestSwordImpl

					function H.setEquipBestSkinImpl(state, fromToggle)
						if S.equipBestSkinRunning == state then
							return
						end

						S.equipBestSkinRunning = state
						if state then
							print("[ExonHub] Equip best skin ON (" .. S.skinSortStat .. ")")
							H.setStatus("Equip best skin ON")
							H.tryEquipBestSkin()
							H.startEquipBestSkinLoop()
						else
							H.stopEquipBestSkinLoop()
							print("[ExonHub] Equip best skin OFF")
							H.setStatus("Equip best skin OFF")
						end

						if not fromToggle then
							H.syncEquipBestSkinToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setEquipBestSkin = H.setEquipBestSkinImpl

					function H.setAutoEvolvePetsImpl(state, fromToggle)
						if S.autoEvolvePetsRunning == state then
							return
						end

						S.autoEvolvePetsRunning = state
						if state then
							print("[ExonHub] Auto evolve pets ON")
							H.setStatus("Auto evolve pets ON")
							H.tryAutoEvolvePetsOnce()
							H.startAutoEvolvePetsLoop()
						else
							H.stopAutoEvolvePetsLoop()
							print("[ExonHub] Auto evolve pets OFF")
							H.setStatus("Auto evolve pets OFF")
						end

						if not fromToggle then
							H.syncAutoEvolvePetsToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoEvolvePets = H.setAutoEvolvePetsImpl

					function H.setAutoEvolveArtifactsImpl(state, fromToggle)
						if S.autoEvolveArtifactsRunning == state then
							return
						end

						S.autoEvolveArtifactsRunning = state
						if state then
							print("[ExonHub] Auto evolve artifacts ON")
							H.setStatus("Auto evolve artifacts ON")
							H.tryAutoEvolveArtifactsOnce()
							H.startAutoEvolveArtifactsLoop()
						else
							H.stopAutoEvolveArtifactsLoop()
							print("[ExonHub] Auto evolve artifacts OFF")
							H.setStatus("Auto evolve artifacts OFF")
						end

						if not fromToggle then
							H.syncAutoEvolveArtifactsToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoEvolveArtifacts = H.setAutoEvolveArtifactsImpl

					function H.setAutoDeleteWeaponsImpl(state, fromToggle)
						if S.autoDeleteWeaponsRunning == state then
							return
						end

						S.autoDeleteWeaponsRunning = state
						if state then
							print("[ExonHub] Auto delete weapons ON")
							H.setStatus("Auto delete weapons ON")
							H.tryAutoDeleteWeapons()
							H.startAutoDeleteWeaponsLoop()
						else
							H.stopAutoDeleteWeaponsLoop()
							print("[ExonHub] Auto delete weapons OFF")
							H.setStatus("Auto delete weapons OFF")
						end

						if not fromToggle then
							H.syncAutoDeleteWeaponsToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoDeleteWeapons = H.setAutoDeleteWeaponsImpl

					function H.setAutoDeleteSkinsImpl(state, fromToggle)
						if S.autoDeleteSkinsRunning == state then
							return
						end

						S.autoDeleteSkinsRunning = state
						if state then
							print("[ExonHub] Auto delete skins ON")
							H.setStatus("Auto delete skins ON")
							H.tryAutoDeleteSkins()
							H.startAutoDeleteSkinsLoop()
						else
							H.stopAutoDeleteSkinsLoop()
							print("[ExonHub] Auto delete skins OFF")
							H.setStatus("Auto delete skins OFF")
						end

						if not fromToggle then
							H.syncAutoDeleteSkinsToggle(state)
						end
						H.scheduleSettingsSave()
					end

					H.setAutoDeleteSkins = H.setAutoDeleteSkinsImpl

					function H.setAutoSaveSettingsImpl(state, fromToggle)
						if S.autoSaveSettingsEnabled == state then
							return
						end

						S.autoSaveSettingsEnabled = state
						if state then
							if not H.canFilesystemPersist() then
								warn("[ExonHub] Auto save needs writefile/readfile support from your executor")
							end
							print("[ExonHub] Auto save settings ON")
							H.setStatus("Auto save settings ON")
							H.saveSettingsSnapshot(true)
						else
							print("[ExonHub] Auto save settings OFF")
							H.setStatus("Auto save settings OFF")
							H.saveSettingsSnapshot(true)
						end

						if not fromToggle then
							H.syncAutoSaveSettingsToggle(state)
						end
					end

					H.setAutoSaveSettings = H.setAutoSaveSettingsImpl

					function H.runStartup()
						local ok, err = pcall(function()
							H.initUsageTracking()
							H.preparePendingSettingsRestore()
							H.waitForDiscordGate()
						end)
						if not ok then
							H.showError(err)
							return
						end

						H.sendDiscordExecuteLog()

						ok, err = pcall(function()
							H.createUI()

							if not H.restoreSavedSettingsOnLoad() then
								H.setAntiAfk(true, false)
								if S.autoSaveSettingsEnabled then
									H.saveSettingsSnapshot(true)
								end
							end
						end)

						if not ok then
							H.showError(err)
						else
							print("[ExonHub] Loaded")
						end
					end

					H.runStartup()

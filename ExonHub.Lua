		print("[ExonHub] loading...")

		local ALLOWED_PLACE_ID = 12645083079 -- Giant Simulator REBORN

		local Players = game:GetService("Players")
		local VirtualUser = game:GetService("VirtualUser")
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
			warn("[ExonHub] no PlayerGui")
			return
		end

		-- remove old UI from previous run
		for _, name in ipairs({ "Exon", "ExonHubUI", "ExonHubFloatingToggle", "ExonHubMinimizedClone", "ExonHubMinimizedGui" }) do
			local old = playerGui:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end

		local NODES_PATH = { "Scene", "ResourceNodes1" }
		local FOLDER_WAIT = 30
		local COLLECT_POLL = 0.1
		local COLLECT_WAIT = 0.3
		local COLLECT_RADIUS = 8
		local ORB_FOLLOW_SPEED = 300
		local ORB_COLLECT_PAUSE_MIN = 0.3
		local ORB_COLLECT_PAUSE_MAX = 0.3
		local MISC_TP_LOCATIONS = {
			{ label = "Ground", position = Vector3.new(1303.301, 93.754, -71.574) },
			{ label = "Cave", position = Vector3.new(2078.066, 208.596, -981.986) },
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
		local EXONHUB_DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1522690164093358110/gP1G5kEHAoOOQaYH5DV9hAvO2jKHzTsBIkAt7x9GctKXPoXeeeWjRWGOCciAWLlF-TXo"
		local EXONHUB_DISCORD_BOT_NAME = "Exon Hub"
		local EXONHUB_ICON_ASSET_ID = 131372483038871
		local EXONHUB_ICON_ASSET = "rbxassetid://" .. tostring(EXONHUB_ICON_ASSET_ID)
		local EXONHUB_ICON_URL = "https://cdn.discordapp.com/attachments/1522686323234832526/1522695144611123250/bce603ec-f4f6-458d-ad80-226aee524ea5.png"
		local EXONHUB_DISCORD_ICON_URL = EXONHUB_ICON_URL
		local EXONHUB_USAGE_DIR = "ExonHub/usage"
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
			autoUpgradeRodRunning = false,
			autoUpgradeRodLoopActive = false,
			autoUpgradeRodPending = false,
			suppressAutoUpgradeRodSync = false,
			autoGoalsScoredBalls = {},
			autoGoalsBallSpawns = {},
			autoGoalsLastKickBallName = nil,
			autoGoalsGoalListener = nil,
			clickerHadAeroAuto = false,
			silentTrainModeActive = false,
			autoGoalsBallCollisionBackup = {},
			autoGoalsCollisionReady = false,
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
			equipBestPetRunning = false,
			equipBestPetLoopActive = false,
			equipBestArtifactRunning = false,
			equipBestArtifactLoopActive = false,
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
			autoRebirthTargetLevel = 100,
			lastRebirthAttemptAt = 0,
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
			suppressAutoRebirthLevelSync = false,
			suppressEquipBestSwordSync = false,
			suppressEquipBestSkinSync = false,
			suppressEquipBestPetSync = false,
			suppressEquipBestArtifactSync = false,
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
			streamerModeRunning = false,
			streamerModeLoopActive = false,
			streamerModeCharacterConn = nil,
			streamerModeBackup = nil,
			cachedSafeZoneRegions = nil,
			usageStats = nil,
			usageLastCheckpoint = nil,
			usageTrackingActive = false,
			topbarIconRotationConn = nil,
			minimizedIconRotationConn = nil,
		}
		local UI = {
			caveAutoOpenToggles = {},
			shellEggAutoOpenToggles = {},
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
			iapData = nil,
			petsInited = nil,
			zapClient = nil,
			fishingRodsData = nil,
		}
		local MIN_REBIRTH_TARGET_LEVEL = 100
		local TRAIN_INTERVAL = 0.52
		local MASS_UPGRADE_INTERVAL = 0.75
		local AUTO_SELL_CHEST_INTERVAL = 0.75
		local REBIRTH_POLL_INTERVAL = 1.5
		local REBIRTH_ATTEMPT_COOLDOWN = 3
		local EQUIP_BEST_INTERVAL = 2
		local AUTO_EVOLVE_INTERVAL = 0.75
		local AUTO_DELETE_INTERVAL = 2.5
		local AUTO_UPGRADE_IDLE_WAIT = 0.01
		local AUTO_UPGRADE_MAX_STEPS = 10000
		local AUTO_UPGRADE_CATCHUP_GAP = 5
		local AUTO_UPGRADE_BULK_MAX_LEVELS = 100
		local AUTO_UPGRADE_SLOT_LABELS = { "Primary Weapon", "Secondary Weapon", "Skin" }
		local AUTO_UPGRADE_LABEL_TO_ID = {
			["Primary Weapon"] = "primary_weapon",
			["Secondary Weapon"] = "secondary_weapon",
			["Skin"] = "skin",
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
		local AUTO_FISH_POLL = 0.35
		local AUTO_FISH_CAST_TIMEOUT = 45
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
		local PET_EVOLVE_MULTIPLIER = 1.25

		-- Pets.Data raw boosts from decompile (Gold, Speed, XP, Shell)
		local PET_BASE_STATS = {
			[1] = { 0, 1.1, 1.1, 0 },
			[2] = { 0, 1.6, 1.6, 0 },
			[3] = { 1.1, 2.65, 2.65, 0 },
			[4] = { 2.5, 4.5, 4.5, 0 },
			[5] = { 0, 1.7, 1.7, 0 },
			[6] = { 1.1, 2.85, 2.85, 0 },
			[7] = { 0, 1.14, 1.14, 0 },
			[8] = { 0, 1.25, 1.25, 0 },
			[9] = { 1.6, 3.75, 3.75, 0 },
			[10] = { 1.1, 2.45, 2.45, 0 },
			[11] = { 1.9, 4, 4, 0 },
			[12] = { 0, 1.18, 1.18, 0 },
			[13] = { 0, 1.8, 1.8, 0 },
			[14] = { 0, 2, 2, 0 },
			[15] = { 0, 2.25, 2.25, 0 },
			[16] = { 1.3, 3.5, 3.5, 0 },
			[17] = { 0, 1.9, 1.9, 0 },
			[18] = { 4, 8, 8, 0 },
			[19] = { 1.15, 3.15, 3.15, 0 },
			[20] = { 1.18, 3.25, 3.25, 0 },
			[21] = { 0, 1.22, 1.22, 0 },
			[22] = { 5, 1.1, 1.1, 0 },
			[23] = { 2.2, 4.25, 4.25, 0 },
			[24] = { 0, 1.5, 1.5, 0 },
			[25] = { 3, 5, 5, 0 },
			[26] = { 2.75, 4.75, 4.75, 0 },
			[38] = { 5.5, 8.5, 8.5, 0 },
			[39] = { 3.25, 6, 6, 0 },
			[40] = { 7, 10, 10, 0 },
			[41] = { 4.75, 7.5, 7.5, 0 },
			[42] = { 4.25, 7, 7, 0 },
			[43] = { 3.75, 6.5, 6.5, 0 },
			[44] = { 1.05, 2.25, 2.25, 1.05 },
			[45] = { 1.18, 3.25, 3.25, 1.1 },
			[46] = { 1.9, 4, 4, 1.2 },
			[47] = { 3, 5, 5, 1.4 },
			[48] = { 4.25, 7, 7, 1.6 },
			[49] = { 8, 12, 12, 2 },
			[50] = { 10, 14, 14, 2 },
		}

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

		function H.setStatus(text)
			print("[ExonHub]", text)
		end

		function H.truncateText(text, maxLen)
			text = tostring(text or "")
			if #text <= maxLen then
				return text
			end
			return text:sub(1, maxLen - 3) .. "..."
		end

		function H.startUiRotation(guiObject, speedDegreesPerSecond)
			if not guiObject then
				return nil
			end
			local speed = speedDegreesPerSecond or EXONHUB_ICON_ROTATION_SPEED
			return RunService.Heartbeat:Connect(function(dt)
				if guiObject.Parent then
					guiObject.Rotation = (guiObject.Rotation + speed * dt) % 360
				end
			end)
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
					local imageLabel

					if iconHolder then
						imageLabel = iconHolder:FindFirstChildWhichIsA("ImageLabel", true)
					else
						for _, desc in ipairs(topbarLeft:GetDescendants()) do
							if desc:IsA("ImageLabel") then
								imageLabel = desc
								iconHolder = desc.Parent
								break
							end
						end
					end

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

					if not S.topbarIconRotationConn then
						S.topbarIconRotationConn = H.startUiRotation(iconHolder, EXONHUB_ICON_ROTATION_SPEED)
					end

					return
				end
			end)
		end

		function H.buildExonHubMinimizedUi()
			local gui = Instance.new("ScreenGui")
			gui.Name = "ExonHubMinimizedGui"
			gui.ResetOnSpawn = false
			gui.IgnoreGuiInset = false
			gui.DisplayOrder = 1000
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
			minimized.Active = false
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

			gui.Parent = playerGui
			return minimized, gui, {
				uiScale = uiScale,
				strokes = { strokeCenter, strokeInner, strokeOuter },
				strokeRestTransparency = { 0, 0.8299999833106995, 0.8299999833106995 },
			}
		end

		function H.createExonHubFloatingToggle(window)
			local TweenService = game:GetService("TweenService")
			local UserInputService = game:GetService("UserInputService")

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
				pulseConn = RunService.Heartbeat:Connect(function()
					if not toggleVisible or not minimized.Parent then
						stopPulse()
						return
					end
					local elapsed = os.clock() - baseTime
					pulseScale.Scale = 1 + math.sin(elapsed * 3.2) * EXONHUB_MINIMIZED_PULSE
				end)
			end

			if not S.minimizedIconRotationConn then
				S.minimizedIconRotationConn = H.startUiRotation(minimized, EXONHUB_ICON_ROTATION_SPEED)
			end

			local function destroyMinimizedUi()
				allowMinimized = false
				toggleVisible = false
				stopPulse()
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

			minimized.InputBegan:Connect(onPointerDown)
			UserInputService.InputChanged:Connect(onPointerMove)
			minimized.InputEnded:Connect(onPointerUp)
			UserInputService.InputEnded:Connect(onPointerUp)

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

					local fields = {
						{ name = "Username", value = "`" .. player.Name .. "`", inline = true },
						{ name = "Display Name", value = player.DisplayName, inline = true },
						{ name = "User ID", value = tostring(userId), inline = true },
						{ name = "Profile", value = "[Open Roblox Profile](" .. profileUrl .. ")", inline = false },
						{ name = "Account", value = accountInfo, inline = false },
						{ name = "Client", value = clientInfo, inline = false },
						{ name = "Session", value = sessionInfo, inline = false },
						{ name = "Exon Hub Usage", value = usageInfo, inline = false },
					}

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

					local payload = {
						username = EXONHUB_DISCORD_BOT_NAME,
						avatar_url = EXONHUB_DISCORD_ICON_URL,
						embeds = {
							{
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
							},
						},
					}

					if H.postDiscordWebhook(webhook, payload) then
						print("[ExonHub] Discord log sent")
					else
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

		function H.shouldAutoGoalsBringBallToPlayer()
			return S.autoFishRunning == true and S.autoGoalsRunning == true
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

		function H.syncEquipBestPetToggle(state)
			if S.suppressEquipBestPetSync or not UI.equipBestPetToggleElement or not UI.equipBestPetToggleElement.Set then
				return
			end
			S.suppressEquipBestPetSync = true
			pcall(function()
				UI.equipBestPetToggleElement:Set(state)
			end)
			S.suppressEquipBestPetSync = false
		end

		function H.syncEquipBestArtifactToggle(state)
			if S.suppressEquipBestArtifactSync or not UI.equipBestArtifactToggleElement or not UI.equipBestArtifactToggleElement.Set then
				return
			end
			S.suppressEquipBestArtifactSync = true
			pcall(function()
				UI.equipBestArtifactToggleElement:Set(state)
			end)
			S.suppressEquipBestArtifactSync = false
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
		end

		function H.getGoldAmount()
			local constants = H.getSharedConstants()
			local dataKeys = constants and constants.DataKeys
			return H.getCurrencyAmount(dataKeys and dataKeys.GOLD or "gold")
		end

		function H.getEquippedUpgradeEntries()
			local entries = {}
			local targets = S.autoUpgradeTargets

			if targets.primary_weapon then
				local key = H.getEquippedItemKey("weapon_equipped")
				if key then
					table.insert(entries, {
						key = key,
						kind = "weapon",
						order = 1,
					})
				end
			end

			if targets.secondary_weapon and H.canDualWieldNow() then
				local key = H.getEquippedItemKey("offhand_equipped")
				if key and key ~= "0" then
					table.insert(entries, {
						key = key,
						kind = "weapon",
						order = 2,
					})
				end
			end

			if targets.skin then
				local key = H.getEquippedItemKey("skin_equipped")
				if key then
					table.insert(entries, {
						key = key,
						kind = "skin",
						order = 3,
					})
				end
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

			if not inventory then
				return nil
			end

			return inventory[entry.key] or inventory[tostring(entry.key)] or inventory[tonumber(entry.key)]
		end

		function H.getUpgradeEntryLevel(entry)
			if entry and entry.level ~= nil then
				return entry.level
			end

			local data = H.getUpgradeInventoryEntry(entry)
			if not data then
				return 0
			end
			return data.upgrades or 0
		end

		function H.syncUpgradeLevelCache(entries)
			for _, entry in ipairs(entries) do
				local data = H.getUpgradeInventoryEntry(entry)
				entry.level = data and (data.upgrades or 0) or 0
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
				local level = entry.level or 0
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
				local aLevel = a.level or 0
				local bLevel = b.level or 0
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

			if entry.kind == "weapon" then
				return H.isUpgradeSuccess(H.callGameService("UpgradeWeapon", entry.key))
			end

			return H.isUpgradeSuccess(H.callGameService("UpgradeSkin", entry.key))
		end

		function H.requestMaxUpgradeEntry(entry)
			if not entry or not entry.key then
				return false
			end
			return H.isUpgradeSuccess(H.callGameService("RequestMaxUpgradeItem", H.getUpgradeItemType(entry), entry.key))
		end

		function H.tryBalancedUpgradeRound(entries, targetLevel)
			local changed = false
			H.sortUpgradeEntries(entries)
			for _, entry in ipairs(entries) do
				if (entry.level or 0) == targetLevel then
					if H.tryUpgradeEquippedEntry(entry) then
						entry.level = (entry.level or 0) + 1
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
				local level = entry.level or 0
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
				return false
			end

			local constants = H.getSharedConstants()
			if not constants then
				return false
			end

			H.syncUpgradeLevelCache(entries)

			local gold = H.getGoldAmount()
			if gold <= 0 then
				return false
			end

			if #entries == 1 then
				return H.requestMaxUpgradeEntry(entries[1])
			end

			local minLevel = math.huge
			local secondMin = math.huge
			local minCount = 0
			for _, entry in ipairs(entries) do
				local level = entry.level or 0
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
					if (entry.level or 0) == minLevel then
						if H.requestMaxUpgradeEntry(entry) then
							return true
						end
						break
					end
				end
			end

			if H.getUpgradeLevelSpread(entries) <= 1 then
				if H.tryBalancedBulkUpgrade(entries, constants, gold) then
					return true
				end
			end

			local changed = false
			local steps = 0

			while steps < AUTO_UPGRADE_MAX_STEPS and H.getGoldAmount() > 0 do
				local roundMin = math.huge
				for _, entry in ipairs(entries) do
					local level = entry.level or 0
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

			return changed
		end

		function H.stopAutoUpgradeLoop()
			S.autoUpgradeRunning = false
		end

		function H.startAutoUpgradeLoop()
			if S.autoUpgradeLoopActive then
				return
			end
			S.autoUpgradeLoopActive = true

			task.spawn(function()
				while S.autoUpgradeRunning do
					if H.tryAutoUpgradeBurst() then
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

		function H.enableAntiAfk()
			if S.antiAfkIdledConnection then
				return
			end

			S.antiAfkIdledConnection = player.Idled:Connect(function()
				if not S.antiAfkRunning then
					return
				end
				pcall(function()
					VirtualUser:CaptureFocus()
					VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
					task.wait(0.25)
					VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
				end)
			end)
		end

		function H.disableAntiAfk()
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

			pcall(function()
				game:GetService("PhysicsService"):RegisterCollisionGroup(AUTO_GOALS_BALL_COLLISION_GROUP)
			end)

			local ok = pcall(function()
				local physics = game:GetService("PhysicsService")
				for _, info in ipairs(physics:GetRegisteredCollisionGroups()) do
					if info.name ~= AUTO_GOALS_BALL_COLLISION_GROUP then
						physics:CollisionGroupSetCollidable(AUTO_GOALS_BALL_COLLISION_GROUP, info.name, false)
					end
				end
			end)

			if ok then
				S.autoGoalsCollisionReady = true
			end
			return ok
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
			S.autoGoalsBallCollisionBackup[name] = {
				instance = ball,
				collisionGroup = primary and primary.CollisionGroup or "Default",
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

		function H.enforceBeachBallPhantomPhysics(ball)
			if not ball or not ball.Parent then
				return false
			end

			if not H.ensureAutoGoalsBallCollisionSetup() then
				return false
			end

			H.backupBeachBallCollision(ball)

			local parts = H.getBeachBallParts(ball)
			if #parts == 0 then
				return false
			end

			for _, part in ipairs(parts) do
				pcall(function()
					part.Anchored = true
					part.CanCollide = false
					part.CanTouch = false
					part.Massless = true
					part.CollisionGroup = AUTO_GOALS_BALL_COLLISION_GROUP
					part.AssemblyAngularVelocity = Vector3.zero
					part.AssemblyLinearVelocity = Vector3.zero
				end)
			end

			local primary = H.getBeachBallPrimaryPart(ball)
			if primary then
				pcall(function()
					primary:SetNetworkOwner(player)
				end)
			end

			return true
		end

		function H.releaseBeachBallForKick(ball)
			local parts = H.getBeachBallParts(ball)
			for _, part in ipairs(parts) do
				pcall(function()
					part.Anchored = false
					part.CanCollide = false
					part.CanTouch = false
					part.Massless = true
					part.CollisionGroup = AUTO_GOALS_BALL_COLLISION_GROUP
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

		function H.applyBeachBallKickVelocity(ball, goalPart)
			local primary = H.getBeachBallPrimaryPart(ball)
			if not primary or not primary.Parent then
				return false
			end

			local kickSpeed, kickLift = H.getSoccerKickValues()
			local direction = H.getKickDirectionTowardGoal(ball, goalPart)
			primary.AssemblyAngularVelocity = Vector3.zero
			primary.AssemblyLinearVelocity = direction * kickSpeed + Vector3.new(0, kickLift, 0)
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
				sc:OnLocalSwing()
				swung = true
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

			H.restoreSingleBeachBallCollision(ball)
			H.zeroBeachBallVelocity(ball)
			H.fireTouchPair(H.getCharacterTouchPart(), primary)

			H.trySoccerSwingKick()
			H.applyBeachBallKickVelocity(ball, goalPart)

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

		function H.onAutoGoalsServerGoal()
			if not S.autoGoalsRunning then
				return
			end
			H.markAutoGoalsBallScored(S.autoGoalsLastKickBallName)
		end

		function H.ensureAutoGoalsGoalListener()
			if S.autoGoalsGoalListener then
				return true
			end

			local aero = H.getGlobal().Aero
			if not aero or not aero.Services or not aero.Services.SoccerService then
				return false
			end

			local constants = H.getSharedConstants()
			if not constants or not constants.RemoteEvents then
				return false
			end

			local remote = aero.Services.SoccerService[constants.RemoteEvents.SOCCER_GOAL]
			if not remote or not remote.Connect then
				return false
			end

			S.autoGoalsGoalListener = remote:Connect(function()
				H.onAutoGoalsServerGoal()
			end)
			return true
		end

		function H.teardownAutoGoalsGoalListener()
			if S.autoGoalsGoalListener then
				pcall(function()
					S.autoGoalsGoalListener:Disconnect()
				end)
				S.autoGoalsGoalListener = nil
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

		function H.tryKickBeachBall(ball, goalPart)
			if not ball or not goalPart then
				return false
			end

			local goals = {}
			for _, goal in pairs(H.collectBeachGoalsByName()) do
				table.insert(goals, goal)
			end

			S.autoGoalsLastKickBallName = ball.Name

			if H.shouldResetBeachBallForAutoGoal(ball, goals) then
				H.prepareBeachBallForAutoGoal(ball)
			else
				H.zeroBeachBallVelocity(ball)
			end

			local confirmed = false

			if H.touchBeachBallForAutoGoal(ball) then
				task.wait(AUTO_GOALS_AFTER_TOUCH_DELAY)
				H.restoreSingleBeachBallCollision(ball)
				H.zeroBeachBallVelocity(ball)
				if H.kickBeachBallAfterTouch(ball, goalPart) then
					task.wait(AUTO_GOALS_POST_KICK_SETTLE)
					if H.slideBeachBallIntoGoal(ball, goalPart) then
						confirmed = H.waitForAutoGoalsServerConfirm(ball.Name, AUTO_GOALS_BALL_ATTEMPT_TIMEOUT)
					end
				end
			end

			H.restoreSingleBeachBallCollision(ball)

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
			H.teardownAutoGoalsGoalListener()
			H.teardownAutoGoalsBallCollision()
			if not S.autoFishRunning then
				H.applySilentTrainMode(false)
			end
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
			else
				warn("[ExonHub] RebirthRequest failed:", err)
				H.setStatus("Rebirth failed")
			end
			return ok
		end

		function H.stopAutoRebirthLoop()
			S.autoRebirthRunning = false
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
		local AUTO_OPEN_IDLE_WAIT = 0.01
		local AUTO_OPEN_BUSY_FAILS = 3

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

		function H.getNextChestKeyLocal()
			local crates = H.getCratesModule()
			local weaponType = crates and crates.ItemType and crates.ItemType.WEAPON or "weapon"
			for _, tier in ipairs(TIER_KEY_ORDER) do
				local weaponCount = H.getChestCount(tier.weapon)
				local skinCount = H.getChestCount(tier.skin)
				if weaponCount + skinCount > 0 then
					if S.autoOpenLastChestType ~= weaponType then
						return weaponCount > 0 and tier.weapon or tier.skin
					end
					return skinCount > 0 and tier.skin or tier.weapon
				end
			end
			return nil
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

		function H.getOpenCrateInvoker()
			if C.openCrateInvoker then
				return C.openCrateInvoker
			end

			local aero = H.getGlobal().Aero
			if aero and aero.Services and aero.Services.GameService and aero.Services.GameService.OpenCrate then
				local gameService = aero.Services.GameService
				C.openCrateInvoker = function(crateKey)
					return gameService:OpenCrate(crateKey)
				end
				return C.openCrateInvoker
			end

			local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
			local services = aeroFolder and aeroFolder:FindFirstChild("AeroRemoteServices")
			local gameService = services and services:FindFirstChild("GameService")
			local remote = gameService and gameService:FindFirstChild("OpenCrate")
			if remote and remote:IsA("RemoteFunction") then
				C.openCrateInvoker = function(crateKey)
					return remote:InvokeServer(crateKey)
				end
				return C.openCrateInvoker
			end

			return nil
		end

		function H.setCratePopupSuppressed(suppressed)
			local aero = H.getGlobal().Aero
			local hud = aero and aero.Controllers and aero.Controllers.HUDController
			if not hud or not hud.StartCratePopup then
				return
			end

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

		function H.warmAutoOpenCache()
			H.getOpenCrateInvoker()
			H.getCratesModule()
			H.getSharedConstants()
			H.getChestInventoryController()
		end

		function H.invokeOpenCrateFast(crateKey)
			local invoke = H.getOpenCrateInvoker()
			if not invoke then
				return false
			end

			local ok, itemType = pcall(invoke, crateKey)
			return ok and itemType ~= nil
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

		function H.tryOpenOneCrate()
			local chestController = H.getChestInventoryController()
			local crateKey = (chestController and chestController.GetNextChestKey and chestController:GetNextChestKey())
				or H.getNextChestKeyLocal()
			if not crateKey or H.getChestCount(crateKey) <= 0 then
				return false
			end
			if not H.canOpenCrateKey(crateKey) then
				return false
			end
			if not H.invokeOpenCrateFast(crateKey) then
				return false
			end

			local crates = H.getCratesModule()
			local crateData = crates and crates.Data and crates.Data[crateKey]
			if crateData and crateData.ItemType then
				S.autoOpenLastChestType = crateData.ItemType
			end
			return true
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

				local idleFails = 0
				while S.autoOpenChestRunning do
					if H.tryOpenOneCrate() then
						idleFails = 0
					else
						idleFails += 1
						if idleFails >= AUTO_OPEN_BUSY_FAILS then
							task.wait(AUTO_OPEN_IDLE_WAIT)
						end
					end
				end

				H.setCratePopupSuppressed(false)
				S.autoOpenChestLoopActive = false
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
			local normalized = H.normalizeDropdownSelection(selected)
			for _, label in ipairs(normalized) do
				local itemId = H.resolveRollOptionItemId(label, rollOptions)
				if itemId then
					local id = tonumber(itemId)
					S.crateAutoDeleteIds[slotId][id] = true
					S.crateAutoDeleteIds[slotId][tostring(id)] = true
				end
			end
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
			local cost, currency = H.getCaveCrateCostInfo(slot)
			if not cost or H.getCurrencyAmount(currency) < cost then
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

		function H.tryOpenCaveCrateSlot(slot)
			local responseOk = H.getServerResponseOk()
			local status, reward
			local beforeKeys = H.snapshotInventoryKeys(slot)

			local ok = pcall(function()
				if slot.kind == "pet" then
					status, reward = H.callGameService("OpenPetCrate", slot.index, 1)
				elseif slot.kind == "artifact" then
					status, reward = H.callGameService("OpenArtifactCrate", slot.index, 1)
				elseif slot.kind == "legendary" then
					status, reward = H.callGameService("OpenLegendaryCrate", slot.itemType, 1)
				elseif slot.kind == "mythic" then
					status, reward = H.callGameService("OpenMythicCrate", slot.itemType, 1)
				end
			end)

			if not ok or status == nil or status ~= responseOk then
				return false
			end

			if H.hasCrateAutoDeleteEnabled(slot.id) then
				H.tryAutoDeleteCrateReward(slot, reward, beforeKeys)
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
			for _, slot in ipairs(WORLD_CRATE_SLOTS) do
				if H.isWorldCrateSlotActive(slot) and H.canOpenCaveCrateSlot(slot) and H.tryOpenCaveCrateSlot(slot) then
					return true, slot
				end
			end
			return false
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

				local idleFails = 0
				while H.hasAnyCaveAutoOpenEnabled() do
					local opened = H.tryOpenEnabledCaveCrate()
					if opened then
						idleFails = 0
					else
						idleFails += 1
						if idleFails >= AUTO_OPEN_BUSY_FAILS then
							task.wait(AUTO_OPEN_IDLE_WAIT)
						end
					end
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
			for _, slot in ipairs(SHELL_EGG_SLOTS) do
				if H.isShellEggSlotActive(slot) and H.canOpenCaveCrateSlot(slot) and H.tryOpenCaveCrateSlot(slot) then
					return true, slot
				end
			end
			return false
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

				local idleFails = 0
				while H.hasAnyShellEggAutoOpenEnabled() do
					local opened, slot = H.tryOpenEnabledShellEgg()
					if opened then
						idleFails = 0
						if slot then
							H.setStatus("Opened " .. slot.title)
						end
					else
						idleFails += 1
						if idleFails >= AUTO_OPEN_BUSY_FAILS then
							task.wait(AUTO_OPEN_IDLE_WAIT)
						end
					end
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

		function H.tryAutoDeleteCrateReward(slot, rewardItemId, beforeKeys)
			if not H.hasCrateAutoDeleteEnabled(slot.id) then
				return false
			end

			if not rewardItemId or not H.isInCrateDeleteSet(slot.id, rewardItemId) then
				return false
			end

			local sellKey = nil
			for _ = 1, 30 do
				sellKey = H.findNewRewardInventoryKey(slot, beforeKeys, rewardItemId)
				if sellKey then
					break
				end
				task.wait(0.05)
			end

			if not sellKey then
				return false
			end

			if H.sellCrateReward(slot, sellKey) then
				H.setStatus("Auto deleted crate drop from " .. slot.title)
				return true
			end

			return false
		end

		function H.createWorldCrateAutoOpenToggle(section, slot)
			UI.caveAutoOpenToggles[slot.id] = section:Toggle({
				Title = "Auto Open " .. slot.title,
				Desc = slot.desc,
				Value = false,
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
				Value = false,
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
				Desc = "AFK fish at the beach stand (Zap FishingStart)",
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
				Desc = "Beach soccer goals; with Auto Fish on, ball comes to you on the fishing stand",
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
					Value = {},
					Multi = true,
					AllowNone = true,
					Callback = function(selected)
						H.setCrateAutoDeleteSelection(slot.id, selected, rollOptions)
					end,
				})
			end)

			if not ok then
				warn("[ExonHub] Auto delete dropdown failed for", slot.title, picker)
			end
		end

		function H.buildWorldCrateKindSection(tab, sectionTitle, kind)
			local section = H.createStaticBoxSection(tab, sectionTitle)
			for _, slot in ipairs(WORLD_CRATE_SLOTS) do
				if slot.kind == kind then
					H.createWorldCrateAutoOpenToggle(section, slot)
					H.createWorldCrateDeletePicker(section, slot)
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
			return S.autoGoalsRunning == true or S.autoFishRunning == true
		end

		function H.backgroundTrainSilent()
			return H.fireTrainRemotes()
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
						pc:OnWeaponActivated()
					end
				elseif pc.SetAutoClick and pc.DoAutoClick then
					pc:SetAutoClick(false, true)
				end
			end)
			return ok
		end

		function H.fireTrainRemotes()
			local attackStart, animComplete = H.getTrainRemotes()
			if not attackStart then
				return false
			end
			local ok = pcall(function()
				attackStart:FireServer()
				if animComplete then
					task.wait(0.1)
					animComplete:FireServer()
				end
			end)
			return ok
		end

		function H.backgroundTrainSwing()
			H.fireTrainRemotes()
			local pc = H.getPlayerController()
			if not pc then
				return
			end
			pcall(function()
				H.ensureWeaponEquipped(pc)
				if pc.OnWeaponActivated then
					pc:OnWeaponActivated()
				end
			end)
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
				local pc = H.waitForPlayerController(25)
				local aeroAutoActive = false

				if S.clickerRunning and pc then
					if H.shouldClickerUseSilentTrain() then
						H.applySilentTrainMode(true)
						aeroAutoActive = false
						print("[ExonHub] Auto click: silent train (fish/goals active)")
					else
						H.tryAeroAutoSwing(pc, true)
						task.wait(0.35)
						aeroAutoActive = pc.DoAutoClick == true
						if aeroAutoActive then
							print("[ExonHub] Background auto swing (game controller)")
						else
							print("[ExonHub] Background auto swing (remote fallback)")
						end
					end
				elseif S.clickerRunning then
					print("[ExonHub] Background auto swing (remote fallback)")
				end

				while S.clickerRunning do
					if H.shouldClickerUseSilentTrain() then
						H.applySilentTrainMode(true)
						aeroAutoActive = false
						H.backgroundTrainSilent()
						task.wait(TRAIN_INTERVAL)
					elseif not aeroAutoActive then
						H.backgroundTrainSwing()
						task.wait(TRAIN_INTERVAL)
					else
						task.wait(0.5)
					end
				end

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
						if child:IsA("Frame") and child:FindFirstChild("ImageLabel") and not child:FindFirstChild("TextLabel", true) then
							child.Visible = false
						end
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

		function H.isGameServiceOk(response)
			local constants = H.getSharedConstants()
			local codes = constants and constants.ServerResponse
			if not codes then
				return response == 0
			end
			return response == codes.OK or response == codes.RESULT_OK
		end

		function H.hasGamePass(passKey)
			if C.iapData and C.iapData.Passes and C.iapData.Passes[passKey] then
				local passId = C.iapData.Passes[passKey]
				local gui = player:FindFirstChild("PlayerGui")
				local passes = gui and gui:FindFirstChild("ClientData") and gui.ClientData:FindFirstChild("passes")
				local passObj = passes and passes:FindFirstChild(tostring(passId))
				return passObj and passObj.Value == true
			end

			local aeroFolder = ReplicatedStorage:FindFirstChild("Aero")
			local sharedFolder = aeroFolder and aeroFolder:FindFirstChild("Shared")
			local iapScript = sharedFolder and sharedFolder:FindFirstChild("IAPData")
			if not iapScript then
				return false
			end
			local ok, iap = pcall(require, iapScript)
			if not ok or not iap or not iap.Passes or not iap.Passes[passKey] then
				return false
			end
			C.iapData = iap

			local passId = iap.Passes[passKey]
			local gui = player:FindFirstChild("PlayerGui")
			local passes = gui and gui:FindFirstChild("ClientData") and gui.ClientData:FindFirstChild("passes")
			local passObj = passes and passes:FindFirstChild(tostring(passId))
			return passObj and passObj.Value == true
		end

		function H.getMaxEquippedPetBonus()
			local aero = H.getGlobal().Aero
			local petsUI = aero and aero.Controllers and aero.Controllers.PetsUIController
			if petsUI then
				if petsUI.PetEquipSlotsRef and type(petsUI.PetEquipSlotsRef.Value) == "number" then
					return petsUI.PetEquipSlotsRef.Value
				end

				local bonus = 0
				if petsUI.MaxPets and petsUI.MaxPets.Value == true then
					bonus += 2
				elseif H.hasGamePass("TWO_MAX_PETS") then
					bonus += 2
				end
				if petsUI.FourMaxPets and petsUI.FourMaxPets.Value == true then
					bonus += 4
				elseif H.hasGamePass("FOUR_MAX_PETS") then
					bonus += 4
				end
				return bonus
			end

			local bonus = 0
			if H.hasGamePass("TWO_MAX_PETS") then
				bonus += 2
			end
			if H.hasGamePass("FOUR_MAX_PETS") then
				bonus += 4
			end
			return bonus
		end

		function H.getMaxEquippedPets()
			local constants = H.getSharedConstants()
			local max = constants and constants.MAX_EQUIPPED_PETS or 2
			return max + H.getMaxEquippedPetBonus()
		end

		function H.getMaxEquippedArtifacts()
			local constants = H.getSharedConstants()
			local max = constants and constants.MAX_EQUIPPED_ARTIFACTS or 2
			if H.hasGamePass("FOUR_MAX_ARTIFACTS") then
				return max + 2
			end
			return max
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
			if PET_BASE_STATS[id] then
				return true
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

		function H.resolvePetEntryEvo(entry)
			if type(entry) ~= "table" then
				return 0
			end
			return entry.evo or entry.evoLevel or entry.Evo or 0
		end

		function H.getPetEntryLevel(entry)
			if type(entry) ~= "table" or entry.level == nil then
				return 1
			end
			return entry.level
		end

		function H.getPetVariantKey(petType, evo)
			return tostring(petType) .. ":" .. tostring(evo or 0)
		end

		function H.getPetBaseStats(ptype)
			local id = tonumber(ptype)
			if not id then
				return nil
			end

			local petsMod = H.getPetsModule()
			local data = petsMod and petsMod.Data and petsMod.Data[id]
			if data then
				return data.GoldBoost or 0, data.SpeedBoost or 0, data.XpBoost or 0, data.ShellBoost or 0
			end

			local row = PET_BASE_STATS[id]
			if row then
				return row[1], row[2], row[3], row[4]
			end

			return nil
		end

		function H.getPetBaseScore(petType, evo)
			local gold, speed, xp, shell = H.getPetBaseStats(petType)
			if gold == nil then
				return 0
			end

			local rawTotal = (gold or 0) + (speed or 0) + (xp or 0) + (shell or 0)
			local evoLevel = evo or 0
			if evoLevel > 0 then
				rawTotal *= PET_EVOLVE_MULTIPLIER ^ evoLevel
			end

			return rawTotal
		end

		function H.getPetEntryBaseScore(entry)
			local petType = H.resolvePetEntryType(entry)
			if not petType then
				return 0
			end

			local evo = H.resolvePetEntryEvo(entry)
			local petsMod = H.getPetsModule()
			if petsMod then
				return (petsMod:GetGoldBoost(petType, 1, evo) or 0)
					+ (petsMod:GetSpeedBoost(petType, 1, evo) or 0)
					+ (petsMod:GetXpBoost(petType, 1, evo) or 0)
					+ (petsMod:GetShellBoost(petType, 1, evo) or 0)
			end

			return H.getPetBaseScore(petType, evo)
		end

		function H.scorePetBase(entry)
			if type(entry) ~= "table" then
				return 0
			end
			return H.getPetEntryBaseScore(entry)
		end

		function H.scoreArtifactEntry(artifactsMod, entry)
			if not artifactsMod or not entry or not entry.ID or entry.locked then
				return 0
			end
			local evo = entry.evolutionlevel or 0
			local artifactId = entry.ID
			return (artifactsMod:GetArtifactGoldBoost(artifactId, evo) or 0)
				+ (artifactsMod:GetArtifactTokenBoost(artifactId, evo) or 0)
				+ (artifactsMod:GetArtifactQuestBoost(artifactId, evo) or 0)
				+ (artifactsMod:GetArtifactShellBoost(artifactId, evo) or 0)
		end

		function H.getBestInventoryKeys(inventory, scoreFn, limit)
			local ranked = {}
			if type(inventory) ~= "table" then
				return ranked
			end

			for key, entry in pairs(inventory) do
				if type(entry) == "table" then
					local score = scoreFn(entry)
					if score > 0 then
						table.insert(ranked, {
							key = tostring(key),
							score = score,
						})
					end
				end
			end

			table.sort(ranked, function(a, b)
				if a.score == b.score then
					return a.key < b.key
				end
				return a.score > b.score
			end)

			local keys = {}
			for i = 1, math.min(limit, #ranked) do
				keys[i] = ranked[i].key
			end
			return keys
		end

		function H.getBestPetKeys()
			local inventory = H.getPetInventoryData()
			if not inventory then
				return {}
			end

			local ranked = {}

			for key, entry in pairs(inventory) do
				if type(entry) == "table" then
					local petType = H.resolvePetEntryType(entry)
					if petType then
						local evo = H.resolvePetEntryEvo(entry)
						local baseScore = H.getPetEntryBaseScore(entry)
						if baseScore > 0 then
							table.insert(ranked, {
								key = key,
								petType = petType,
								evo = evo,
								level = H.getPetEntryLevel(entry),
								baseScore = baseScore,
								variantKey = H.getPetVariantKey(petType, evo),
							})
						end
					end
				end
			end

			table.sort(ranked, function(a, b)
				if a.baseScore ~= b.baseScore then
					return a.baseScore > b.baseScore
				end
				if a.variantKey == b.variantKey and a.level ~= b.level then
					return a.level > b.level
				end
				if a.petType ~= b.petType then
					return a.petType > b.petType
				end
				return tostring(a.key) < tostring(b.key)
			end)

			local limit = H.getMaxEquippedPets()
			local keys = {}
			for i = 1, math.min(limit, #ranked) do
				keys[i] = ranked[i].key
			end
			return keys
		end

		function H.getBestArtifactKeys()
			local artifactsMod = H.getArtifactsModule()
			local inventory = H.getArtifactInventoryData()
			if not artifactsMod or not inventory then
				return {}
			end
			return H.getBestInventoryKeys(inventory, function(entry)
				return H.scoreArtifactEntry(artifactsMod, entry)
			end, H.getMaxEquippedArtifacts())
		end

		function H.requestEquipPet(key, shouldEquip)
			return H.callGameService("RequestEquipPet", key, shouldEquip == true)
		end

		function H.requestEquipArtifact(key, shouldEquip)
			return H.callGameService("RequestEquipArtifact", key, shouldEquip == true)
		end

		function H.syncEquippedFromBest(inventory, bestKeys, equipFn, allowLocked)
			if type(inventory) ~= "table" or type(bestKeys) ~= "table" then
				return false
			end

			local bestSet = {}
			for _, key in ipairs(bestKeys) do
				bestSet[tostring(key)] = true
			end

			local changed = false

			for key, entry in pairs(inventory) do
				if type(entry) == "table" and entry.equipped then
					if not bestSet[tostring(key)] then
						local invKey = H.resolveInventoryKey(inventory, key)
						local response = equipFn(invKey, false)
						if H.isGameServiceOk(response) then
							changed = true
						end
					end
				end
			end

			for _, key in ipairs(bestKeys) do
				local invKey = H.resolveInventoryKey(inventory, key)
				local entry = inventory[invKey]
				if type(entry) == "table" and not entry.equipped then
					if allowLocked or entry.locked ~= true then
						local response = equipFn(invKey, true)
						if H.isGameServiceOk(response) then
							changed = true
						end
					end
				end
			end

			return changed
		end

		function H.tryEquipBestPets()
			local inventory = H.getPetInventoryData()
			if not inventory then
				return false
			end

			local bestKeys = H.getBestPetKeys()
			if #bestKeys == 0 then
				return false
			end

			local bestSet = {}
			for _, key in ipairs(bestKeys) do
				bestSet[tostring(key)] = true
			end

			local changed = false

			for key, entry in pairs(inventory) do
				if type(entry) == "table" and entry.equipped and not bestSet[tostring(key)] then
					local invKey = H.resolveInventoryKey(inventory, key)
					local response = H.requestEquipPet(invKey, false)
					if H.isGameServiceOk(response) then
						changed = true
					end
					task.wait(0.08)
				end
			end

			for _, key in ipairs(bestKeys) do
				local invKey = H.resolveInventoryKey(inventory, key)
				local entry = inventory[invKey]
				if type(entry) == "table" and not entry.equipped then
					local response = H.requestEquipPet(invKey, true)
					if H.isGameServiceOk(response) then
						changed = true
					end
					task.wait(0.08)
				end
			end

			if changed then
				H.setStatus("Equipped best pet(s)")
			end
			return changed
		end

		function H.tryEquipBestArtifacts()
			local inventory = H.getArtifactInventoryData()
			if not inventory then
				return false
			end

			local bestKeys = H.getBestArtifactKeys()
			if #bestKeys == 0 then
				return false
			end

			local changed = H.syncEquippedFromBest(inventory, bestKeys, H.requestEquipArtifact)
			if changed then
				H.setStatus("Equipped best artifact(s)")
			end
			return changed
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

		function H.stopEquipBestPetLoop()
			S.equipBestPetRunning = false
		end

		function H.stopEquipBestArtifactLoop()
			S.equipBestArtifactRunning = false
		end

		function H.startEquipBestPetLoop()
			if S.equipBestPetLoopActive then
				return
			end
			S.equipBestPetLoopActive = true

			task.spawn(function()
				for _ = 1, 40 do
					if H.getPetInventoryData() then
						break
					end
					task.wait(0.5)
				end

				while S.equipBestPetRunning do
					H.tryEquipBestPets()
					task.wait(EQUIP_BEST_INTERVAL)
				end

				S.equipBestPetLoopActive = false
			end)
		end

		function H.startEquipBestArtifactLoop()
			if S.equipBestArtifactLoopActive then
				return
			end
			S.equipBestArtifactLoopActive = true

			task.spawn(function()
				for _ = 1, 40 do
					if H.getArtifactInventoryData() and H.getArtifactsModule() then
						break
					end
					task.wait(0.5)
				end

				while S.equipBestArtifactRunning do
					H.tryEquipBestArtifacts()
					task.wait(EQUIP_BEST_INTERVAL)
				end

				S.equipBestArtifactLoopActive = false
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
			local ok, WindUI = pcall(function()
				return loadstring(game:HttpGet(
					"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
				))()
			end)
			if not ok or not WindUI then
				error("WindUI failed to load: " .. tostring(WindUI))
			end

			local Window = WindUI:CreateWindow({
				Title = "Exon Hub",
				Folder = "ExonHub",
				Icon = EXONHUB_ICON_ASSET,
				IconSize = EXONHUB_TOPBAR_ICON_SIZE,
				IconThemed = false,
				NewElements = true,
				ToggleKey = Enum.KeyCode.LeftAlt,
				OpenButton = {
					Enabled = false,
				},
			})

			UI.window = Window
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

			H.finalizeStaticSection(FarmSection)

			local AutoUpgradeSection = H.createStaticBoxSection(FarmingTab, "Auto Upgrade")

			local okUpgradeDropdown, _ = pcall(function()
				UI.autoUpgradeDropdownElement = AutoUpgradeSection:Dropdown({
					Title = "Upgrade Targets",
					Desc = "Splits gold evenly â€” always upgrades the lowest level item next",
					Values = AUTO_UPGRADE_SLOT_LABELS,
					Value = AUTO_UPGRADE_SLOT_LABELS,
					Multi = true,
					AllowNone = true,
					Callback = function(selected)
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
				Desc = "Best in main hand, 2nd best in offhand (needs dual wield)",
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

			UI.equipBestPetToggleElement = EquipBestSection:Toggle({
				Title = "Equip Best Pet",
				Desc = "Base stats ranking (includes locked pets), level only breaks same-type ties",
				Value = false,
				Callback = function(on)
					if S.suppressEquipBestPetSync then
						return
					end
					if H.setEquipBestPet then
						H.setEquipBestPet(on == true, true)
					end
				end,
			})

			UI.equipBestArtifactToggleElement = EquipBestSection:Toggle({
				Title = "Equip Best Artifact",
				Desc = "Equips your best artifacts (uses evolution boosts, up to max slots)",
				Value = false,
				Callback = function(on)
					if S.suppressEquipBestArtifactSync then
						return
					end
					if H.setEquipBestArtifact then
						H.setEquipBestArtifact(on == true, true)
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
				Value = "100",
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
				Desc = "Opens inventory weapon/skin crates as fast as the server allows",
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
					Value = AUTO_BOSS_OPTION_LABELS,
					Multi = true,
					AllowNone = true,
					Callback = function(selected)
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
				Desc = "Prevents idle kick (on by default)",
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
				H.startAutoRebirthLoop()
			else
				H.stopAutoRebirthLoop()
				print("[ExonHub] Auto rebirth OFF")
				H.setStatus("Auto rebirth OFF")
			end

			if not fromToggle then
				H.syncAutoRebirthToggle(state)
			end
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
		end

		H.setAutoMassUpgrade = H.setAutoMassUpgradeImpl

		function H.setAutoUpgradeImpl(state, fromToggle)
			if S.autoUpgradeRunning == state then
				return
			end

			S.autoUpgradeRunning = state
			if state then
				print("[ExonHub] Auto upgrade ON")
				H.setStatus("Auto upgrade ON")
				H.tryAutoUpgradeBurst()
				H.startAutoUpgradeLoop()
			else
				H.stopAutoUpgradeLoop()
				print("[ExonHub] Auto upgrade OFF")
				H.setStatus("Auto upgrade OFF")
			end

			if not fromToggle then
				H.syncAutoUpgradeToggle(state)
			end
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
				if S.clickerRunning then
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
		end

		H.setAutoGoals = H.setAutoGoalsImpl

		function H.setAutoFishImpl(state, fromToggle)
			if S.autoFishRunning == state then
				return
			end

			S.autoFishRunning = state
			if state then
				S.autoFishPhase = FISHING_PHASE_IDLE
				if S.clickerRunning then
					H.applySilentTrainMode(true)
				end
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
		end

		H.setAutoFish = H.setAutoFishImpl

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
		end

		H.setAutoSellChest = H.setAutoSellChestImpl

		function H.setAutoOpenChestImpl(state, fromToggle)
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

			if not fromToggle then
				H.syncAutoOpenChestToggle(state)
			end
		end

		H.setAutoOpenChest = H.setAutoOpenChestImpl

		function H.setCaveAutoOpenSlotImpl(slotId, state, fromToggle)
			S.caveAutoOpenSlots[slotId] = state == true

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
		end

		H.setEquipBestSkin = H.setEquipBestSkinImpl

		function H.setEquipBestPetImpl(state, fromToggle)
			if S.equipBestPetRunning == state then
				return
			end

			S.equipBestPetRunning = state
			if state then
				print("[ExonHub] Equip best pet ON")
				H.setStatus("Equip best pet ON")
				H.tryEquipBestPets()
				H.startEquipBestPetLoop()
			else
				H.stopEquipBestPetLoop()
				print("[ExonHub] Equip best pet OFF")
				H.setStatus("Equip best pet OFF")
			end

			if not fromToggle then
				H.syncEquipBestPetToggle(state)
			end
		end

		H.setEquipBestPet = H.setEquipBestPetImpl

		function H.setEquipBestArtifactImpl(state, fromToggle)
			if S.equipBestArtifactRunning == state then
				return
			end

			S.equipBestArtifactRunning = state
			if state then
				print("[ExonHub] Equip best artifact ON")
				H.setStatus("Equip best artifact ON")
				H.tryEquipBestArtifacts()
				H.startEquipBestArtifactLoop()
			else
				H.stopEquipBestArtifactLoop()
				print("[ExonHub] Equip best artifact OFF")
				H.setStatus("Equip best artifact OFF")
			end

			if not fromToggle then
				H.syncEquipBestArtifactToggle(state)
			end
		end

		H.setEquipBestArtifact = H.setEquipBestArtifactImpl

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
		end

		H.setAutoDeleteSkins = H.setAutoDeleteSkinsImpl

		local ok, err = pcall(function()
			H.initUsageTracking()
			H.createUI()
			print("[ExonHub] UI created")
			H.sendDiscordExecuteLog()

			H.setAntiAfk(true, false)

			H.setStatus("Loading...")
			task.spawn(function()
				for _ = 1, 10 do
					local folder = H.getNodesFolder()
					if folder then
						H.debugScan()
						local active = #H.getActiveNodes()
						if active > 0 then
							H.setStatus("Ready â€” " .. active .. " node(s)")
						else
							H.setStatus("0 nodes â€” wait for respawn")
						end
						return
					end
					task.wait(1)
				end
				H.setStatus("Missing ResourceNodes1")
			end)
		end)

		if not ok then
			H.showError(err)
		else
			print("[ExonHub] loaded OK")
		end

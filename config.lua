local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local NPCT = E:NewModule('NameplateTweaks', 'AceEvent-3.0')
local NP = E:GetModule('NamePlates')

if E.private.npct == nil then E.private.npct = {} end
if P.npct == nil then P.npct = {} end

-- Locked Settings, These settings are stored for your character only regardless of profile options.
-- Defaults
V['npct'] = {
	['low'] = 0.2,
	['lowColor'] = {r = 1, g = 0, b = 0},
	['middle'] = 0.35,
	['middleColor'] = {r = 1, g = 1, b = 0},
}

-- Options
function NPCT:AddOptions()
	E.Options.args.nameplate.args.healthBar.args.npct = {
		order = 4.5,
		type = 'group',
		name = "Health-Dependant Nameplate Coloring",
		guiInline = true,
		get = function(info) return E.private.npct[ info[#info] ] end,
		set = function(info, value) E.private.npct[ info[#info] ] = value; NP:UpdateAllPlates() end,
		args = {
			low = {
				type = 'range',
				order = 1,
				name = "Lower Health Threshold",
				desc = "Color the nameplate accordingly when health gets below this point.",
				isPercent = true,
				min = 0, max = 1, step = 0.01,
			},
			lowColor = {
				get = function(info)
					local t = E.private.npct.lowColor
					local d = V.npct.lowColor
					return t.r, t.g, t.b, t.a, d.r, d.g, d.b
				end,
				set = function(info, r, g, b)
					E.private.npct.lowColor = {}
					local t = E.private.npct.lowColor
					t.r, t.g, t.b = r, g, b
					NP:UpdateAllPlates()
				end,
				name = "Color on low health",
				order = 2,
				type = 'color',
				hasAlpha = false,
			},
			middle = {
				type = 'range',
				order = 4,
				name = "Higher Health Threshold",
				desc = "Color the nameplate accordingly when health gets below this point.",
				isPercent = true,
				min = 0, max = 1, step = 0.01,
			},
			middleColor = {
				get = function(info)
					local t = E.private.npct.middleColor
					local d = V.npct.middleColor
					return t.r, t.g, t.b, t.a, d.r, d.g, d.b
				end,
				set = function(info, r, g, b)
					E.private.npct.middleColor = {}
					local t = E.private.npct.middleColor
					t.r, t.g, t.b = r, g, b
					NP:UpdateAllPlates()
				end,
				name = "Color on middle health",
				order = 5,
				type = 'color',
				hasAlpha = false,
			}
		}
	}
	
	-- deactivate default color options (cheap overwrite)
	E.Options.args.nameplate.args.healthBar.args.lowHPScale.args.changeColor = {
		name = "",
		order = 5,
		type = "description",
	}
	E.Options.args.nameplate.args.healthBar.args.lowHPScale.args.color = {
		name = "",
		order = 6,
		type = "description",
	}
end

E:RegisterModule(NPCT:GetName())
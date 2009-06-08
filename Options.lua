local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local media = LibStub("LibSharedMedia-3.0")

Skada.resetoptions = {[1] = L["No"], [2] = L["Yes"], [3] = L["Ask"]}

Skada.windowdefaults = {
	name = "Skada",
	
	barmax=10,
	barspacing=0,
	bartexture="BantoBar",
	barfont="Accidental Presidency",
	barfontsize=11,
	barheight=15,
	barwidth=180,
	barorientation=1,
	barcolor = {r = 0.3, g = 0.3, b = 0.8, a=1},
	baraltcolor = {r = 0.45, g = 0.45, b = 0.8, a = 1},
	barslocked=false,

	classcolorbars = true,
	classcolortext = false,
	
	title = {font="Accidental Presidency", fontsize=11,margin=0, texture="Round", bordertexture="None", borderthickness=2, color = {r=0,g=0,b=0,a=0.6}},
	background = {margin=0, height=150, texture="None", bordertexture="None", borderthickness=0, color = {r=0,g=0,b=0.5,a=0.5}},

	reversegrowth=false,
	modeincombat="",
	returnaftercombat=false,
	
	hidden = false,
	enabletitle = true, 
	enablebackground = false,
	
	set = "current",
	mode = nil,
	
	display = "bar",
}

local windefaultscopy = {}
Skada:tcopy(windefaultscopy, Skada.windowdefaults)

Skada.defaults = {
	profile = {
		reset={instance=1, join=1, leave=1},
		icon = {hide = false, radius = 80, minimapPos = 195},
		numberformat=1,
		setstokeep = 10,
		tooltips=true,
		tooltippos="default",
		onlykeepbosses=false,
		hidesolo=false,
		hidepvp=false,
		hidedisables=true,
		feed = "",
		sets = {},
		total = nil,

		modules = {},
		columns = {},
		report = {mode = "Damage", set = "current", channel = "Say", chantype = "preset", number = 10},

		windows = {windefaultscopy},
	}
}

-- Returns column configuration options for a mode.
function Skada:GetColumnOptions(mod)
	local db = self.db.profile.columns
	
	if mod.metadata and mod.metadata.columns then
		local cols = {
	        type="group",
			name="Columns",
	        args={
	        	
					defaultvalues = {
					        type="toggle",
					        name="Default",
					        get=function() return db[mod.name] end,
					        set=function() 
					        		db[mod.name] = not db[mod.name]
				         			Skada:ApplySettings()
					        	end,
					},
					        	
	        	},
		}
		
		for colname, value in ipairs(mod.metadata.columns) do
			local c = mod.name.."_"..colname
			local col = {
			        type="toggle",
			        name=colname,
			        get=function() return db[c] end,
			        set=function() 
			        		db[c] = not db[c]
		         			Skada:ApplySettings()
			        	end,
			}
			cols.args[c] = col
		end
		
		return cols
	end
	
end

local deletewindow = nil

Skada.options = {
	        type="group",
			name="Skada",
			plugins = {},
	        args={
	        		d = {
	        			type="description",
						name=L["A damage meter."],
						order=0,
	        		},
	        		
	        		windows = {
	        			type = "group",
	        			name = L["Windows"],
	        			order=0,
						args = {

							create = {
								type="input",
								name=L["Create window"],
								desc=L["Enter the name for the new window."],
								set=function(self, val) if val and val ~= "" then Skada:CreateWindow(val) end end,
								order=1,
							},

							delete = {
								type="select",
								name=L["Delete window"],
								desc=L["Choose the window to be deleted."],
								values=	function()
											local windows = {}
											for i, win in ipairs(Skada:GetWindows()) do
												windows[win.db.name] = win.db.name
											end
											return windows
										end,
								get=function() return deletewindow end,
								set=function(self, val) deletewindow = val end,
								order=2,
							},
							deleteexecute = {
								type="execute",
								name=L["Delete window"],
								desc=L["Deletes the chosen window."],
								func=function(self) if deletewindow then Skada:DeleteWindow(deletewindow) end end,
								order=3,
							},
																					
						},
	        		},
	        		
	        		resetoptions = {
	        			type = "group",
	        			name = L["Data resets"],
	        			order=2,
						args = {

							resetinstance = {
								type="select",
								name=L["Reset on entering instance"],
								desc=L["Controls if data is reset when you enter an instance."],
								values=	function() return Skada.resetoptions end,
								get=function() return Skada.db.profile.reset.instance end,
								set=function(self, opt) Skada.db.profile.reset.instance = opt end,
								order=30,
							},
							
							resetjoin = {
								type="select",
								name=L["Reset on joining a group"],
								desc=L["Controls if data is reset when you join a group."],
								values=	function() return Skada.resetoptions end,
								get=function() return Skada.db.profile.reset.join end,
								set=function(self, opt) Skada.db.profile.reset.join = opt end,
								order=31,
							},
		
							resetleave = {
								type="select",
								name=L["Reset on leaving a group"],
								desc=L["Controls if data is reset when you leave a group."],
								values=	function() return Skada.resetoptions end,
								get=function() return Skada.db.profile.reset.leave end,
								set=function(self, opt) Skada.db.profile.reset.leave = opt end,
								order=32,
							},
							
				        }
				        
	        		},

	        		generaloptions = {
	        			type = "group",
	        			name = L["General options"],
	        			order=3,
						args = {
							
							mmbutton = {
							        type="toggle",
							        name=L["Show minimap button"],
							        desc=L["Toggles showing the minimap button."],
							        order=23,
							        get=function() return not Skada.db.profile.icon.hide end,
							        set=function()
							    			Skada.db.profile.icon.hide = not Skada.db.profile.icon.hide
											Skada:RefreshMMButton()
							        	end,
							},

							tooltips = {
							        type="toggle",
							        name=L["Show tooltips"],
							        desc=L["Shows tooltips with extra information in some modes."],
							        order=24,
							        get=function() return Skada.db.profile.tooltips end,
							        set=function() Skada.db.profile.tooltips = not Skada.db.profile.tooltips end,
							},
							
							tooltippos = {
								type="select",
								name=L["Tooltip position"],
								desc=L["Position of the tooltips."],
								values=	{["default"] = L["Default"], ["topright"] = L["Top right"], ["topleft"] = L["Top left"]},
								get=function() return Skada.db.profile.tooltippos end,
								set=function(self, opt) Skada.db.profile.tooltippos = opt end,
								order=25,
							},
							
							onlykeepbosses = {
							        type="toggle",
							        name=L["Only keep boss fighs"],
							        desc=L["Boss fights will be kept with this on, and non-boss fights are discarded."],
							        order=26,
							        get=function() return Skada.db.profile.onlykeepbosses end,
							        set=function() Skada.db.profile.onlykeepbosses = not Skada.db.profile.onlykeepbosses end,
							},
							
							hidesolo = {
							        type="toggle",
							        name=L["Hide when solo"],
							        desc=L["Hides Skada's window when not in a party or raid."],
							        order=27,
							        get=function() return Skada.db.profile.hidesolo end,
							        set=function()
							        			Skada.db.profile.hidesolo = not Skada.db.profile.hidesolo
							        			Skada:ApplySettings()
							        		end,
							},

							hidepvp = {
							        type="toggle",
							        name=L["Hide in PvP"],
							        desc=L["Hides Skada's window when in Battlegrounds/Arenas."],
							        order=28,
							        get=function() return Skada.db.profile.hidepvp end,
							        set=function()
							        			Skada.db.profile.hidepvp = not Skada.db.profile.hidepvp
							        			Skada:ApplySettings()
							        		end,
							},
							
							disablewhenhidden = {
							        type="toggle",
							        name=L["Disable while hidden"],
							        desc=L["Skada will not collect any data when automatically hidden."],
							        order=29,
							        get=function() return Skada.db.profile.hidedisables end,
							        set=function()
							        			Skada.db.profile.hidedisables = not Skada.db.profile.hidedisables
							        			Skada:ApplySettings()
							        		end,
							},
							
							numberformat = {
								type="select",
								name=L["Number format"],
								desc=L["Controls the way large numbers are displayed."],
								values=	function() return {[1] = L["Condensed"], [2] = L["Detailed"]} end,
								get=function() return Skada.db.profile.numberformat end,
								set=function(self, opt) Skada.db.profile.numberformat = opt end,
								order=30,
							},
							
							datafeed = {
								type="select",
								name=L["Data feed"],
								desc=L["Choose which data feed to show in the DataBroker view. This requires an LDB display addon, such as Titan Panel."],
								values=	function()
											local feeds = {}
											feeds[""] = L["None"]
											for name, func in pairs(Skada:GetFeeds()) do feeds[name] = name end
											return feeds
										end,
								get=function() return Skada.db.profile.feed end,
								set=function(self, feed)
											Skada.db.profile.feed = feed
											if feed ~= "" then Skada:SetFeed(Skada:GetFeeds()[feed]) end
										end,
								order=31,
							},

							setstokeep = {
								type="range",
								name=L["Data segments to keep"],
								desc=L["The number of fight segments to keep. Persistent segments are not included in this."],
								min=0,
								max=30,
								step=1,
								get=function() return Skada.db.profile.setstokeep end,
								set=function(self, val) Skada.db.profile.setstokeep = val end,
								order=32,
							},
							
						}
	        		},
	        		
	        		
	        }
	        
}


local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local media = LibStub("LibSharedMedia-3.0")

Skada.resetoptions = {[1] = L["No"], [2] = L["Yes"], [3] = L["Ask"]}

Skada.defaults = {
	profile = {
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
		title = {margin=0, texture="Round", bordertexture="None", borderthickness=2, color = {r=0,g=0,b=0,a=0.6}},
		reversegrowth=false,
		reset={instance=1, join=1, leave=1},
		icon = {hide = false, radius = 80, minimapPos = 195},
		modeincombat="",
		numberformat=1,
		setstokeep = 10,
		onlykeepbosses=false,
		window = {shown = true, enabletitle = true, enablebackground = false, margin=0, height=150, texture="None", bordertexture="None", borderthickness=0, color = {r=0,g=0,b=0.5,a=0.5}},
		returnaftercombat=false,
		hidesolo=false,
		set = "current",
		mode = nil,
		feed = "",
		sets = {},
		total = nil,
		modules = {},	-- Place module config here if needed.

	}
}


--[[
		windows = {
				{
					-- Default window.
					name = "Default",
					
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
					title = {margin=0, texture="Round", bordertexture="None", borderthickness=2, color = {r=0,g=0,b=0,a=0.6}},
					reversegrowth=false,
					modeincombat="",
					
					shown = true,
					enabletitle = true, 
					enablebackground = false,
					background = {
						margin=0,
						height=150,
						texture="None",
						bordertexture="None",
						borderthickness=0,
						color = {r=0,g=0,b=0.5,a=0.5}},
					},
					
					set = "current",
					mode = nil,
				},
			},
		}
--]]

Skada.options = {
	        type="group",
			name="Skada",
	        args={
	        		d = {
	        			type="description",
						name=L["A damage meter."],
						order=0,
	        		},
	        		
	        		baroptions = {
	        			type = "group",
	        			name = L["Bars"],
	        			order=1,
						args = {

						    barfont = {
						         type = 'select',
						         dialogControl = 'LSM30_Font',
						         name = L["Bar font"],
						         desc = L["The font used by all bars."],
						         values = AceGUIWidgetLSMlists.font,
						         get = function() return Skada.db.profile.barfont end,
						         set = function(self,key) 
						         			Skada.db.profile.barfont = key
						         			Skada:ApplySettings()
										end,
								order=10,
						    },
		
							barfontsize = {
								type="range",
								name=L["Bar font size"],
								desc=L["The font size of all bars."],
								min=7,
								max=40,
								step=1,
								get=function() return Skada.db.profile.barfontsize end,
								set=function(self, size)
											Skada.db.profile.barfontsize = size
						         			Skada:ApplySettings()
										end,
								order=11,
							},
		
						    bartexture = {
						         type = 'select',
						         dialogControl = 'LSM30_Statusbar',
						         name = L["Bar texture"],
						         desc = L["The texture used by all bars."],
						         values = AceGUIWidgetLSMlists.statusbar,
						         get = function() return Skada.db.profile.bartexture end,
						         set = function(self,key)
					         				Skada.db.profile.bartexture = key
						         			Skada:ApplySettings()
										end,
								order=12,
						    },
		
							barspacing = {
								type="range",
								name=L["Bar spacing"],
								desc=L["Distance between bars."],
								min=0,
								max=10,
								step=1,
								get=function() return Skada.db.profile.barspacing end,
								set=function(self, spacing)
											Skada.db.profile.barspacing = spacing
						         			Skada:ApplySettings()
										end,
								order=13,
							},
		
							barheight = {
								type="range",
								name=L["Bar height"],
								desc=L["The height of the bars."],
								min=10,
								max=40,
								step=1,
								get=function() return Skada.db.profile.barheight end,
								set=function(self, height)
											Skada.db.profile.barheight = height
						         			Skada:ApplySettings()
										end,
								order=14,
							},
							
							barwidth = {
								type="range",
								name=L["Bar width"],
								desc=L["The width of the bars."],
								min=80,
								max=400,
								step=1,
								get=function() return Skada.db.profile.barwidth end,
								set=function(self, width)
											Skada.db.profile.barwidth = width
						         			Skada:ApplySettings()
										end,
								order=14,
							},
																	
							barmax = {
								type="range",
								name=L["Max bars"],
								desc=L["The maximum number of bars shown."],
								min=0,
								max=100,
								step=1,
								get=function() return Skada.db.profile.barmax end,
								set=function(self, max)
											Skada.db.profile.barmax = max
						         			Skada:ApplySettings()
										end,
								order=15,
							},
		
							barorientation = {
								type="select",
								name=L["Bar orientation"],
								desc=L["The direction the bars are drawn in."],
								values=	function() return {[1] = L["Left to right"], [3] = L["Right to left"]} end,
								get=function() return Skada.db.profile.barorientation end,
								set=function(self, orientation)
										Skada.db.profile.barorientation = orientation
					         			Skada:ApplySettings()
									end,
								order=17,
							},
							
							barslocked = {
							        type="toggle",
							        name=L["Lock window"],
							        desc=L["Locks the bar window in place."],
							        order=18,
							        get=function() return Skada.db.profile.barslocked end,
							        set=function() 
							        		Skada.db.profile.barslocked = not Skada.db.profile.barslocked
						         			Skada:ApplySettings()
							        	end,
							},
		
							reversegrowth = {
							        type="toggle",
							        name=L["Reverse bar growth"],
							        desc=L["Bars will grow up instead of down."],
							        order=19,
							        get=function() return Skada.db.profile.reversegrowth end,
							        set=function() 
							        		Skada.db.profile.reversegrowth = not Skada.db.profile.reversegrowth
						         			Skada:ApplySettings()
							        	end,
							},
							
							color = {
								type="color",
								name=L["Bar color"],
								desc=L["Choose the default color of the bars."],
								hasAlpha=true,
								get=function(i) 
										local c = Skada.db.profile.barcolor
										return c.r, c.g, c.b, c.a
									end,
								set=function(i, r,g,b,a) 
										Skada.db.profile.barcolor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
										Skada:ApplySettings()
									end,
								order=20,
							},

							altcolor = {
								type="color",
								name=L["Alternate color"],
								desc=L["Choose the alternate color of the bars."],
								hasAlpha=true,
								get=function(i) 
										local c = Skada.db.profile.baraltcolor
										return c.r, c.g, c.b, c.a
									end,
								set=function(i, r,g,b,a) 
										Skada.db.profile.baraltcolor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
										Skada:ApplySettings()
									end,
								order=21,
							},
							
						}
	        		},
					
	        		titleoptions = {
	        			type = "group",
	        			name = L["Title bar"],
	        			order=2,
						args = {
							
							enable = {
							        type="toggle",
							        name=L["Enable"],
							        desc=L["Enables the title bar."],
							        order=0,
							        get=function() return Skada.db.profile.window.enabletitle end,
							        set=function() 
							        		Skada.db.profile.window.enabletitle = not Skada.db.profile.window.enabletitle
						         			Skada:ApplySettings()
							        	end,
							},
							
						    texture = {
						         type = 'select',
						         dialogControl = 'LSM30_Statusbar',
						         name = L["Background texture"],
						         desc = L["The texture used as the background of the title."],
						         values = AceGUIWidgetLSMlists.statusbar,
						         get = function() return Skada.db.profile.title.texture end,
						         set = function(self,key)
					         				Skada.db.profile.title.texture = key
						         			Skada:ApplySettings()
										end,
								order=1,
						    },						    
						    
						    bordertexture = {
						         type = 'select',
						         dialogControl = 'LSM30_Border',
						         name = L["Border texture"],
						         desc = L["The texture used for the border of the title."],
						         values = AceGUIWidgetLSMlists.border,
						         get = function() return Skada.db.profile.title.bordertexture end,
						         set = function(self,key)
					         				Skada.db.profile.title.bordertexture = key
						         			Skada:ApplySettings()
										end,
								order=2,
						    },					
					
							thickness = {
								type="range",
								name=L["Border thickness"],
								desc=L["The thickness of the borders."],
								min=0,
								max=50,
								step=0.5,
								get=function() return Skada.db.profile.title.borderthickness end,
								set=function(self, val)
											Skada.db.profile.title.borderthickness = val
						         			Skada:ApplySettings()
										end,
								order=3,
							},

							margin = {
								type="range",
								name=L["Margin"],
								desc=L["The margin between the outer edge and the background texture."],
								min=0,
								max=50,
								step=0.5,
								get=function() return Skada.db.profile.title.margin end,
								set=function(self, val)
											Skada.db.profile.title.margin = val
						         			Skada:ApplySettings()
										end,
								order=4,
							},	
														
							color = {
								type="color",
								name=L["Background color"],
								desc=L["The background color of the title."],
								hasAlpha=true,
								get=function(i) 
										local c = Skada.db.profile.title.color
										return c.r, c.g, c.b, c.a
									end,
								set=function(i, r,g,b,a) 
										Skada.db.profile.title.color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
										Skada:ApplySettings()
									end,
								order=5,
							},
							
						}
	        		},

	        		windowoptions = {
	        			type = "group",
	        			name = L["Background"],
	        			order=2,
						args = {

							enablebackground = {
							        type="toggle",
							        name=L["Enable"],
							        desc=L["Adds a background frame under the bars. The height of the background frame determines how many bars are shown. This will override the max number of bars setting."],
							        order=0,
							        get=function() return Skada.db.profile.window.enablebackground end,
							        set=function() 
							        		Skada.db.profile.window.enablebackground = not Skada.db.profile.window.enablebackground
						         			Skada:ApplySettings()
							        	end,
							},
							
						    texture = {
						         type = 'select',
						         dialogControl = 'LSM30_Statusbar',
						         name = L["Background texture"],
						         desc = L["The texture used as the background."],
						         values = AceGUIWidgetLSMlists.statusbar,
						         get = function() return Skada.db.profile.window.texture end,
						         set = function(self,key)
					         				Skada.db.profile.window.texture = key
						         			Skada:ApplySettings()
										end,
								order=1,
						    },						    
						    
						    bordertexture = {
						         type = 'select',
						         dialogControl = 'LSM30_Border',
						         name = L["Border texture"],
						         desc = L["The texture used for the borders."],
						         values = AceGUIWidgetLSMlists.border,
						         get = function() return Skada.db.profile.window.bordertexture end,
						         set = function(self,key)
					         				Skada.db.profile.window.bordertexture = key
						         			Skada:ApplySettings()
										end,
								order=2,
						    },					
					
							thickness = {
								type="range",
								name=L["Border thickness"],
								desc=L["The thickness of the borders."],
								min=0,
								max=50,
								step=0.5,
								get=function() return Skada.db.profile.window.borderthickness end,
								set=function(self, val)
											Skada.db.profile.window.borderthickness = val
						         			Skada:ApplySettings()
										end,
								order=3,
							},
							
							margin = {
								type="range",
								name=L["Margin"],
								desc=L["The margin between the outer edge and the background texture."],
								min=0,
								max=50,
								step=0.5,
								get=function() return Skada.db.profile.window.margin end,
								set=function(self, val)
											Skada.db.profile.window.margin = val
						         			Skada:ApplySettings()
										end,
								order=4,
							},							

							height = {
								type="range",
								name=L["Window height"],
								desc=L["The height of the window. If this is 0 the height is dynamically changed according to how many bars exist."],
								min=0,
								max=600,
								step=1,
								get=function() return Skada.db.profile.window.height end,
								set=function(self, height)
											Skada.db.profile.window.height = height
						         			Skada:ApplySettings()
										end,
								order=5,
							},
							
							color = {
								type="color",
								name=L["Background color"],
								desc=L["The color of the background."],
								hasAlpha=true,
								get=function(i) 
										local c = Skada.db.profile.window.color
										return c.r, c.g, c.b, c.a
									end,
								set=function(i, r,g,b,a) 
										Skada.db.profile.window.color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
										Skada:ApplySettings()
									end,
								order=6,
							},
														
						}
	        		},
	        		
	        		resetoptions = {
	        			type = "group",
	        			name = L["Data resets"],
	        			order=3,
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

	        		switchoptions = {
	        			type = "group",
	        			name = L["Mode switching"],
	        			order=4,
						args = {
												
							modeincombat = {
								type="select",
								name=L["Combat mode"],
								desc=L["Automatically switch to set 'Current' and this mode when entering combat."],
								values=	function()
											local modes = {}
											modes[""] = L["None"]
											for i, mode in ipairs(Skada:GetModes()) do
												modes[mode.name] = mode.name
											end
											return modes
										end,
								get=function() return Skada.db.profile.modeincombat end,
								set=function(self, mode)
											Skada.db.profile.modeincombat = mode
										end,
								order=21,
							},
							
							returnaftercombat = {
								type="toggle",
			                	name=L["Return after combat"],
		               			desc=L["Return to the previous set and mode after combat ends."],
				                order=22,
		       			        get=function() return Skada.db.profile.returnaftercombat end,
		           			    set=function() Skada.db.profile.returnaftercombat = not Skada.db.profile.returnaftercombat end,
		           			    disabled=function() return Skada.db.profile.returnaftercombat == nil end,
							},
						}
	        		},
	        		
	        		generaloptions = {
	        			type = "group",
	        			name = L["General options"],
	        			order=5,
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

							onlykeepbosses = {
							        type="toggle",
							        name=L["Only keep boss fighs"],
							        desc=L["Boss fights will be kept with this on, and non-boss fights are discarded."],
							        order=23,
							        get=function() return Skada.db.profile.onlykeepbosses end,
							        set=function() Skada.db.profile.onlykeepbosses = not Skada.db.profile.onlykeepbosses end,
							},
							
							hidesolo = {
							        type="toggle",
							        name=L["Hide when solo"],
							        desc=L["Hides Skada's window when not in a party or raid."],
							        order=24,
							        get=function() return Skada.db.profile.hidesolo end,
							        set=function()
							        			Skada.db.profile.hidesolo = not Skada.db.profile.hidesolo
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
								order=25,
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
								order=26,
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
								order=27,
							},
							
						}
	        		},
	        }
	        
}


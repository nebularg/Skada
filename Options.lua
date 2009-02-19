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
		barcolor = {r = 0.41, g = 0.8, b = 0.94, a=1},
		barslocked=false,
		reversegrowth=false,
		reset={instance=1, join=1, leave=1},
		icon = {},
		modeincombat="",
		numberformat=1,
		onlykeepbosses=false,
		window = {shown = true},
		returnaftercombat=false,
		mmbutton=true,
		set = "current",
		mode = nil,
		sets = {},
		current = nil,
		total = nil,
	}
}

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
		       					width="full",
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
																	
							color = {
								type="color",
								name=L["Bar color"],
								desc=L["Choose the default color of the bars."],
								get=function(i) 
										local c = Skada.db.profile.barcolor
										return c.r, c.g, c.b, a
									end,
								set=function(i, r,g,b,a) 
										Skada.db.profile.barcolor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
										Skada:ApplySettings()
									end,
								order=15,
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
								order=16,
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
						}
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

	        		switchoptions = {
	        			type = "group",
	        			name = L["Mode switching"],
	        			order=3,
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
	        			order=4,
						args = {
												
							mmbutton = {
							        type="toggle",
							        name=L["Show minimap button"],
							        desc=L["Toggles showing the minimap button."],
							        order=23,
							        get=function() return Skada.db.profile.mmbutton end,
							        set=function()
							    			Skada.db.profile.mmbutton = not Skada.db.profile.mmbutton
											Skada:ShowMMButton(Skada.db.profile.mmbutton)
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
							
							numberformat = {
								type="select",
								name=L["Number format"],
								desc=L["Controls the way large numbers are displayed."],
								values=	function() return {[1] = L["Condensed"], [2] = L["Detailed"]} end,
								get=function() return Skada.db.profile.numberformat end,
								set=function(self, opt) Skada.db.profile.numberformat = opt end,
								order=24,
							},
						}
	        		},
	        }
	        
}


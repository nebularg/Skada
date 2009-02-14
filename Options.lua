local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local media = LibStub("LibSharedMedia-3.0")

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
		icon = {},
		modeincombat="",
		window = {shown = true},
		returnaftercombat=false,
		mmbutton=true,
		set = "current",
		mode = nil,
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

					hdrcd = {order=1, type="header", name=L["Appearance"]},

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
										
					hdrcd = {order=20, type="header", name=L["Options"]},
					
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

					
		        },
	        
	        
}


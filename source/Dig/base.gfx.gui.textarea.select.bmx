SuperStrict
Import "base.gfx.gui.textarea.bmx"




Type TGuiTextAreaSelect Extends TGUITextArea
	Field selectedLine:int
	Field hoveredLine:int

    Method Create:TGUITextAreaSelect(position:TVec2D = null, dimension:TVec2D = null, limitState:String = "")
		Super.Create(position, dimension, limitState)

		SetFont( GetBitmapFont("default", 12) )
		SetFixedLineHeight( GetFont().getMaxCharHeight()+2 )

		_horizontalScrollerAllowed = False

		return self
	End Method


	Method onMouseOver:int(triggerEvent:TEventBase)
		local coord:TVec2D = TVec2D(triggerEvent.GetData().Get("coord"))
		if not coord then return False

		local localCoord:TVec2D = new TVec2D.Init( coord.x - GetContentScreenX(), coord.y - GetContentScreenY())
		hoveredLine = 1 + int((localCoord.y + Abs(guiTextPanel.scrollPosition.GetY())) / GetLineHeight())
		hoveredLine = MathHelper.Clamp(hoveredLine, 0, GetValueLines().length -1)
	End Method


	Method onClick:int(triggerEvent:TEventBase)
		local coord:TVec2D = TVec2D(triggerEvent.GetData().Get("coord"))
		if not coord then return False

		local localCoord:TVec2D = new TVec2D.Init( coord.x - GetContentScreenX(), coord.y - GetContentScreenY())
		selectedLine = 1 + int((localCoord.y + Abs(guiTextPanel.scrollPosition.GetY())) / GetLineHeight())
		selectedLine = MathHelper.Clamp(selectedLine, 0, GetValueLines().length -1)

		return True
	End Method


	Method SetValue(value:string)
		Super.SetValue(value)
		hoveredLine = -1
		selectedLine = -1
	End Method


	Method Update:Int()
		'gets refreshed automatically
		hoveredLine = -1

		Super.Update()
	End Method


	Method DrawContent()
		Super.DrawContent()

		if selectedLine > 0 or hoveredLine > 0
			RestrictContentViewport()
			local oldCol:TColor = new TColor.Get()

			if selectedLine > 0
				SetBlend LightBlend
				SetAlpha oldCol.a * 0.25
				SetColor 200,200,200
				local lineY:int = GetLineHeight() * (selectedLine-1) + guiTextPanel.scrollPosition.GetY()
				DrawRect(GetContentScreenX(), GetContentScreenY() + lineY -1, GetContentScreenWidth(), GetLineHeight())
				SetBlend AlphaBlend
			endif

			if hoveredLine > 0 and hoveredLine <> selectedLine
				SetBlend LightBlend
				SetAlpha oldCol.a * 0.10
				SetColor 200,200,230
				local lineY:int = GetLineHeight() * (hoveredLine-1) + guiTextPanel.scrollPosition.GetY()
				DrawRect(GetContentScreenX(), GetContentScreenY() + lineY -1, GetContentScreenWidth(), GetLineHeight())
				SetBlend AlphaBlend
			endif
			

			oldCol.SetRGBA()
			ResetViewport()
		endif
	End Method
End Type
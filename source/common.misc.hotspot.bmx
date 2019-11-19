SuperStrict
Import "Dig/base.framework.entity.bmx"
Import "Dig/base.framework.tooltip.bmx"
Import "Dig/base.util.event.bmx"
Import "Dig/base.util.input.bmx"


Type THotspot Extends TRenderableEntity
	Field name:String = ""
	Field tooltip:TTooltip
	Field tooltipEnabled:Int = True
	Field tooltipText:String = ""
	Field tooltipDescription:String	= ""
	Field hovered:Int = False
	Field enterable:Int = False


	Method Create:THotSpot(name:String, x:Int,y:Int,w:Int,h:Int)
		area = New TRectangle.Init(x,y,w,h)
		Self.name = name

		Return Self
	End Method


	Method setTooltipText( text:String="", description:String="" )
		Self.tooltipText		= text
		Self.tooltipDescription = description
	End Method


	Method GetTooltip:TTooltip()
		'return the first tooltip found in children
		For Local t:TTooltip = EachIn childEntities
			Return t
		Next
		Return Null
	End Method


	Method SetEnterable(bool:Int = True)
		enterable = bool
	End Method


	Method IsEnterable:Int()
		Return enterable
	End Method


rem
	Method Render:Int(xOffset:Float = 0, yOffset:Float = 0, alignment:TVec2D = Null)
'		if tooltipEnabled
			DrawRect(xOffset + area.GetX(),yOffset + area.GetY(),area.GetW(), area.GetH())
'			DrawRect(xOffset + GetScreenArea().GetX(),0,GetScreenArea().GetW(), GetScreenArea().GetH())
'		endif
		Super.Render(xOffset, yOffset, alignment)
	End Method
endrem


	'update tooltip
	'handle clicks -> send events so eg can send figure to it
	Method Update:Int()
		hovered = False

		If GetScreenArea().containsXY(MouseManager.x, MouseManager.y)
			hovered = True
			If MOUSEMANAGER.isClicked(1)
				EventManager.triggerEvent( TEventSimple.Create("hotspot.onClick", New TData , Self ) )
				'done by the hotspots if there are some
				'MouseManager.ResetClicked(1)
			EndIf
		EndIf

		If hovered And tooltipEnabled
			If tooltip
				tooltip.Hover()
			ElseIf tooltipText<>""
				'create it
				tooltip = TTooltip.Create(tooltipText, tooltipDescription, 100, 140, 0, 0)
				'layout the tooltip centered above the hotspot
				tooltip.area.position.SetXY(area.GetW()/2 - tooltip.GetWidth()/2, -tooltip.GetHeight())
				tooltip.enabled = True

				AddChild(tooltip)
			EndIf
		EndIf

		UpdateChildren()

		'delete old tooltips
		If tooltip And tooltip.lifetime < 0
			RemoveChild(tooltip)
			tooltip = null
		Endif
	End Method
End Type
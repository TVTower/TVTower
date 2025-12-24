SuperStrict
Import Brl.Max2D
Import "base.util.srectangle.bmx"

Function DrawOutlinePolygon4:Int(p1:SVec2F, p2:SVec2F, p3:SVec2F, p4:SVec2F)
    DrawLine(p1.x, p1.y, p2.x, p2.y)
    DrawLine(p2.x, p2.y, p3.x, p3.y)
    DrawLine(p3.x, p3.y, p4.x, p4.y)
    DrawLine(p4.x, p4.y, p1.x, p1.y)
End Function

Function DrawOutlinePolygon4:Float(p1:SVec2F, p2:SVec2F, p3:SVec2F, p4:SVec2F, dashLength:Float, spaceLength:Float, offset:Float = 0.0)
    offset = DrawDashedLine(p1.x, p1.y, p2.x, p2.y, dashLength, spaceLength, offset)
    offset = DrawDashedLine(p2.x, p2.y, p3.x, p3.y, dashLength, spaceLength, offset)
    offset = DrawDashedLine(p3.x, p3.y, p4.x, p4.y, dashLength, spaceLength, offset)
    offset = DrawDashedLine(p4.x, p4.y, p1.x, p1.y, dashLength, spaceLength, offset)
    Return offset
End Function

Function RotateVectorAround:SVec2F(p:SVec2F, pivot:SVec2F, angle:Float)
    Local rotated:SVec2F = New SVec2F(p.x - pivot.x, p.y - pivot.y).Rotate(angle)
    Return New SVec2F(pivot.x + rotated.x, pivot.y + rotated.y)
End Function

Function DrawOutlineRotatedPolygon4:Int(p1:SVec2F, p2:SVec2F, p3:SVec2F, p4:SVec2F, angle:Float)
    Local rp2:SVec2F = RotateVectorAround(p2, p1, angle)
    Local rp3:SVec2F = RotateVectorAround(p3, p1, angle)
    Local rp4:SVec2F = RotateVectorAround(p4, p1, angle)

    DrawOutlinePolygon4(p1, rp2, rp3, rp4)
End Function

Function DrawOutlineRotatedPolygon4Dashed:Int(p1:SVec2F, p2:SVec2F, p3:SVec2F, p4:SVec2F, angle:Float, dashLen:Float, spaceLen:Float, offset:Float = 0.0)
    Local rp2:SVec2F = RotateVectorAround(p2, p1, angle)
    Local rp3:SVec2F = RotateVectorAround(p3, p1, angle)
    Local rp4:SVec2F = RotateVectorAround(p4, p1, angle)

    DrawOutlinePolygon4(p1, rp2, rp3, rp4, dashLen, spaceLen, offset)
End Function

Function DrawOutlineRect(r:SRectI, angle:Int)
    Local p1:SVec2F = New SVec2F(r.x, r.y)
    Local p2:SVec2F = New SVec2F(r.x + r.w - 1, r.y)
    Local p3:SVec2F = New SVec2F(r.x + r.w - 1, r.y + r.h - 1)
    Local p4:SVec2F = New SVec2F(r.x, r.y + r.h - 1)

    If angle = 0
        DrawOutlinePolygon4(p1, p2, p3, p4)
    Else
        DrawOutlineRotatedPolygon4(p1, p2, p3, p4, angle)
    End If
End Function

Function DrawOutlineRect(r:SRectI, angle:Int, dashLen:Float, spaceLen:Float, offset:Float = 0.0)
    Local p1:SVec2F = New SVec2F(r.x, r.y)
    Local p2:SVec2F = New SVec2F(r.x + r.w - 1, r.y)
    Local p3:SVec2F = New SVec2F(r.x + r.w - 1, r.y + r.h - 1)
    Local p4:SVec2F = New SVec2F(r.x, r.y + r.h - 1)

    If angle = 0
        DrawOutlinePolygon4(p1, p2, p3, p4, dashLen, spaceLen, offset)
    Else
        DrawOutlineRotatedPolygon4Dashed(p1, p2, p3, p4, angle, dashLen, spaceLen, offset)
    End If
End Function

Function DrawDashedLine:Float(x1:Float, y1:Float, x2:Float, y2:Float, dashLen:Float, spaceLen:Float, offset:Float = 0.0)
    Local dx:Float = x2 - x1
    Local dy:Float = y2 - y1
    Local totalLen:Float = Sqr(dx * dx + dy * dy)
    If totalLen <= 0 Or dashLen <= 0 Then Return offset
    Local dirX:Float = dx / totalLen
    Local dirY:Float = dy / totalLen
    Local patternLen:Float = dashLen + spaceLen
    If patternLen <= 0 
		DrawLine(x1, y1, x2, y2)
		Return 0.0
	EndIf

    Local traveled:Float = 0
    Local patternPos:Float = offset Mod patternLen
    Local drawSegment:Int
	Local segmentLen:Float
    While traveled < totalLen
        If patternPos < dashLen Then
            drawSegment = True
            segmentLen = dashLen - patternPos
        Else
            drawSegment = False
            segmentLen = patternLen - patternPos
        End If
        Local stepLen:Float = Min(segmentLen, totalLen - traveled)
        Local startX:Float = x1 + dirX * traveled
        Local startY:Float = y1 + dirY * traveled
        Local endX:Float = x1 + dirX * (traveled + stepLen)
        Local endY:Float = y1 + dirY * (traveled + stepLen)

        If drawSegment Then DrawLine(startX, startY, endX, endY)

        traveled :+ stepLen
        patternPos :+ stepLen
        If patternPos >= patternLen
			patternPos :- patternLen
		EndIf
    Wend
    Return patternPos
End Function


Function DrawRect(r:SRectI)
	DrawRect(r.x, r.y, r.w, r.h)
End Function

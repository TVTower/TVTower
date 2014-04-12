Type BroadcastTest Extends TTest

        Field broadcastManager:TBroadcastManager

        Method setup() { before }
                broadcastManager = New TBroadcastManager
        End Method

        Method testDoCalculation() { test }
        
                Local result:Int = broadcastManager.GetTastValue( )
                Local expectedResult:Int = 5   '  1 + 1 = 2 * 2 = 4 '
                
                assertEqualsI(expectedResult, result)
        
        End Method

End Type
import brl.blitz
import "basefunctions_events.bmx"
TDeltaTimer^brl.blitz.Object{
.newTime%&
.oldTime%&
.loopTime#&
.deltaTime#&
.accumulator#&
.tweenValue#&
.fps%&
.ups%&
.deltas#&
.timesDrawn%&
.timesUpdated%&
.secondGone#&
.totalTime#&
-New%()="_bb_TDeltaTimer_New"
-Delete%()="_bb_TDeltaTimer_Delete"
+Create:TDeltaTimer(physicsFps%=60)="_bb_TDeltaTimer_Create"
-Loop%()="_bb_TDeltaTimer_Loop"
-getTween#()="_bb_TDeltaTimer_getTween"
-getDeltaTime#()="_bb_TDeltaTimer_getDeltaTime"
}="bb_TDeltaTimer"

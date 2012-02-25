Cower.BufferedGLMax2D
===================================================================================================

About
---------------------------------------------------------------------------------------------------
This is an open-source implementation of the GLMax2D driver that approaches implementing the renderer using vertex arrays rather than using glBegin/glVertex/glEnd for all rendering.

Most of the code is fairly functional now, although it's not certain what sort of bugs there are that remain in the code.  As of this writing, DrawOval, GrabPixmap, and DrawPixmap remain to be implemented, and some clean up needs to be done.  There may be extensions to Max2D added to allow coders to directly work with the TRenderBuffer code, thereby allowing more complex drawing operations (e.g., skewed images, complex shapes such as stars or toruses, 3D rendering is also possible), but this is still up in the air (meaning I haven't yet found a coin to toss).

This module __requires__ [Cower.RenderBuffer](http://github.com/nilium/cower.renderbuffer), so mosy on over to that repo and grab it too.

If you're up for breaking the code or contributing to it, go nuts.  If you want to steal the code, go nuts.  If you want to demand its completion for God knows what reason, go nuts.

License
---------------------------------------------------------------------------------------------------

	Cower.GLMax2D is copyright (c) 2009 Noel R. Cower
	
	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.

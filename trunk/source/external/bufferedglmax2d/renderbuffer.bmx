Rem
Copyright (c) 2010 Noel R. Cower

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
EndRem

SuperStrict

'Module Cower.RenderBuffer

Import Brl.Graphics
'Import Brl.LinkedList
Import Pub.Glew

Import "renderbuffer.cpp"

Private

Extern "C"
	'renderstate
	Function rs_init@Ptr(rs@Ptr)
	Function rs_copy@Ptr(from@Ptr, to_@Ptr)
	Function rs_bind(rs@Ptr)
	Function rs_restore(rs@Ptr)
	Function rs_set_texture(name%)
	'renderbuffer
	Function rb_init@Ptr(rb@Ptr)
	Function rb_destroy@Ptr(rb@Ptr)
	Function rb_set_texture(rb@Ptr, name%)
	Function rb_set_mode(rb@Ptr, mode%)
	Function rb_set_blend_func(rb@Ptr, source%, dest%)
	Function rb_set_alpha_func(rb@Ptr, func%, ref#)
	Function rb_set_scissor_test(rb@Ptr, enabled%, x%, y%, w%, h%)
	Function rb_set_line_width(rb@Ptr, width#)
	Function rb_add_vertices(rb@Ptr, elements%, vertices@Ptr, texcoords@Ptr, colors@Ptr)
	Function rb_lock_buffers(rb@Ptr)
	Function rb_unlock_buffers(rb@Ptr)
	Function rb_render(rb@Ptr)
	Function rb_reset(rb@Ptr)
End Extern

Public

Type TRenderState Final
	Field texture_name%
	Field render_mode%
	Field blend_source%
	Field blend_dest%
	Field alpha_func%
	Field alpha_ref#
	Field sc_enabled%
	Field sc_x%, sc_y%
	Field sc_w%, sc_h%
	Field line_width#

	Method New()
		rs_init(Self)
	End Method

	Method Bind()
		rs_bind(Self)
	End Method

	Method Restore()
		rs_restore(Self)
	End Method

	Method Clone:TRenderState()
		Local c:TRenderState = New TRenderState
		rs_copy(Self, c)
		Return c
	End Method

	Function SetTexture(tex%)
		rs_set_texture(tex)
	End Function

	Function RestoreState(state:TRenderState=Null)
		If state = Null Then
			rs_restore(Null)
		Else
			rs_restore(state)
		EndIf
	End Function
End Type

Type TRenderBuffer Final
	Field _vertices@Ptr, _texcoords@Ptr, _colors@Ptr
	Field _vertices_len%, _texcoords_len%, _colors_len%
	Field _index%, _sets%
	Field _indices@Ptr, _counts@Ptr
	Field _indices_length%
	Field _lock%
	Field _render_indices@Ptr
	Field _render_states@Ptr
	Field _state_capacity%, _states_top%

	Method New()
		rb_init(Self)
	End Method

	Method Delete()
		rb_destroy(Self)
	End Method

	Method SetTexture(name:Int)
		rb_set_texture(Self, name)
	End Method

	Method SetMode(mode:Int)
		rb_set_mode(Self, mode)
	End Method

	Method SetBlendFunc(source:Int, dest:Int)
		rb_set_blend_func(Self, source, dest)
	End Method

	Method SetAlphaFunc(func:Int, ref:Float)
		rb_set_alpha_func(Self, func, ref)
	End Method

	Method SetScissorTest(enabled%, x%, y%, w%, h%)
		rb_set_scissor_test(Self, enabled, x, y, w, h)
	End Method

	Method SetLineWidth(width#)
		rb_set_line_width(Self, width)
	End Method

	Method AddVerticesEx(elements%, vertices@Ptr, texcoords@Ptr, colors@Ptr)
		rb_add_vertices(Self, elements, vertices, texcoords, colors)
	End Method

	Method LockBuffers()
		rb_lock_buffers(Self)
	End Method

	Method UnlockBuffers()
		rb_unlock_buffers(Self)
	End Method

	Method Render()
		rb_render(Self)
	End Method

	Method Reset()
		rb_reset(Self)
	End Method
End Type

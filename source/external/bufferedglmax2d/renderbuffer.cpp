/*
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
*/

#include <pub.mod/glew.mod/GL/glew.h>
#include <math.h>
#include <float.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif



#pragma mark Utility

inline bool floats_differ(float l, float r) {
	return (FLT_EPSILON<=fabsf(l-r));
}




#pragma mark brl.graphics imports

extern int brl_graphics_GraphicsSeq;




#pragma mark Constants

const size_t RENDER_BUFFER_INIT_ELEMENTS = 512;
const double RENDER_BUFFER_SCALE = 2.0;



#pragma mark Types

typedef struct s_blend_factors {
	GLenum source;
	GLenum dest;
} blend_factors_t;

typedef struct s_alpha_test {
	GLenum func;
	GLclampf ref;
} alpha_test_t;

typedef struct s_scissor_test {
	int enabled;
	GLint x, y;
	GLsizei width, height;
} scissor_test_t;

typedef struct s_render_indices {
	uint32_t index_from;
	uint32_t indices;
	uint32_t num_indices;
} render_indices_t;

typedef struct s_render_state {
	GLuint texture_name;
	GLenum render_mode;
	blend_factors_t blend;
	alpha_test_t alpha;
	scissor_test_t scissor;
	
	GLfloat line_width;
} render_state_t;

typedef struct s_render_buffer {
	GLfloat *vertices, *texcoords;
	GLubyte *colors;
	size_t vertices_length, texcoords_length, colors_length;
	
	uint32_t index;
	uint32_t sets;
	
	GLint *indices;
	GLsizei *counts;
	uint32_t indices_length;
	uint32_t lock;
	
	render_indices_t *render_indices;
	render_state_t *render_states;
	uint32_t state_capacity, state_top;
} render_buffer_t;




#pragma mark Globals

static struct {
	bool state_bound;
	bool texture2D_enabled;
	GLuint texture2D_binding;
	int sequence;
	bool blend_enabled;
	bool alpha_test_enabled;
	scissor_test_t scissor;
	
	render_state_t active;
} rs_globals = {
	false, false, (GLuint)0, 0, false, false,
	{0, 0, 0, 0, 0},
};




#pragma mark Prototypes

// render_state_t
render_state_t *rs_init(render_state_t *rs);
render_state_t *rs_copy(render_state_t *rs, render_state_t *to);
void rs_bind(render_state_t *rs);
void rs_restore(render_state_t *rs);
void rs_set_texture(GLuint name);

// render_buffer_t

render_buffer_t *rb_new();
render_buffer_t *rb_init(render_buffer_t *rb);
void rb_destroy(render_buffer_t *rb);
//inline void rb_new_state(render_buffer_t *rb);
void rb_set_texture(render_buffer_t *rb, GLuint name);
void rb_set_mode(render_buffer_t *rb, GLenum mode);
void rb_set_blend_func(render_buffer_t *rb, GLenum source, GLenum dest);
void rb_set_alpha_func(render_buffer_t *rb, GLenum func, GLclampf ref);
void rb_set_scissor_test(render_buffer_t *rb, int enabled, int x, int y, int w, int h);
void rb_set_line_width(render_buffer_t *rb, GLfloat width);
void rb_add_vertices(render_buffer_t *rb, int elements, GLfloat *points, GLfloat *texcoords, GLubyte *colors);
void rb_lock_buffers(render_buffer_t *rb);
void rb_unlock_buffers(render_buffer_t *rb);
void rb_render(render_buffer_t *rb);
void rb_reset(render_buffer_t *rb);




#pragma mark Implementations

// render_state_t

render_state_t *rs_init(render_state_t *rs) {
	if (rs) {
		rs->texture_name = (GLuint)0;
		rs->render_mode = GL_POLYGON;
		rs->blend.source = GL_ONE;
		rs->blend.dest = GL_ZERO;
		rs->alpha.func = GL_ALWAYS;
		rs->alpha.ref = (GLclampf)0.0f;
		rs->line_width = 1.0f;
	}
	return rs;
}


render_state_t *rs_copy(render_state_t *rs, render_state_t *to) {
	*to = *rs;
	return to;
}


void rs_bind(render_state_t *rs) {
	if (!rs_globals.state_bound) {
		rs_globals.state_bound = true;
		rs_init(&rs_globals.active);
	}
	
	render_state_t active = rs_globals.active;
	rs_set_texture(rs->texture_name);
	
	if (rs->blend.dest != active.blend.dest ||
		rs->blend.source != active.blend.source) {
		if (rs->blend.dest == GL_ONE && rs->blend.source == GL_ZERO && rs_globals.blend_enabled) {
			glDisable(GL_BLEND);
			rs_globals.blend_enabled = false;
		} else {
			if (!rs_globals.blend_enabled) {
				glEnable(GL_BLEND);
				rs_globals.blend_enabled = true;
			}
			glBlendFunc(rs->blend.source, rs->blend.dest);
		}
	}
	
	if (rs->alpha.func != active.alpha.func || floats_differ(rs->alpha.ref, active.alpha.ref)) {
		if (rs->alpha.func == GL_ALWAYS && rs_globals.alpha_test_enabled) {
			glDisable(GL_ALPHA_TEST);
			rs_globals.alpha_test_enabled = false;
		} else {
			if (!rs_globals.alpha_test_enabled) {
				glEnable(GL_ALPHA_TEST);
				rs_globals.alpha_test_enabled = true;
			}
			glAlphaFunc(rs->alpha.func, rs->alpha.ref);
		}
	}
	
	if (rs->scissor.enabled == 0 && active.scissor.enabled) {
		glDisable(GL_SCISSOR_TEST);
	} else {
		if (rs->scissor.enabled && active.scissor.enabled == 0) {
			glEnable(GL_SCISSOR_TEST);
		}
		if (rs->scissor.x != active.scissor.x || rs->scissor.y != active.scissor.y || 
			rs->scissor.width != active.scissor.width || rs->scissor.height != active.scissor.height) {
			glScissor(rs->scissor.x, rs->scissor.y, rs->scissor.width, rs->scissor.height);
		}
	}
	
	if (rs->render_mode == GL_LINES && floats_differ(rs->line_width, active.line_width)) {
		glLineWidth(rs->line_width);
	}
	
	rs_globals.active = *rs;
}


void rs_restore(render_state_t *rs) {
	render_state_t restore;
	if (rs) {
		restore = *rs;
	} else {
		if (!rs_globals.state_bound) {
			rs_init(&restore);
		} else {
			restore = rs_globals.active;
		}
	}
	
	if (rs_globals.alpha_test_enabled) {
		glEnable(GL_ALPHA_TEST);
	} else {
		glDisable(GL_ALPHA_TEST);
	}
	
	if (rs_globals.blend_enabled) {
		glEnable(GL_BLEND);
	} else {
		glDisable(GL_BLEND);
	}
	
	if (rs_globals.sequence == brl_graphics_GraphicsSeq && rs_globals.texture2D_enabled &&
		rs_globals.texture2D_binding) {
		glBindTexture(GL_TEXTURE_2D, rs_globals.texture2D_binding);
	} else {
		rs_globals.texture2D_binding = 0;
	}
	
	if (rs_globals.texture2D_enabled) {
		glEnable(GL_TEXTURE_2D);
	} else {
		glDisable(GL_TEXTURE_2D);
	}
	
	rs_bind(&restore);
}


void rs_set_texture(GLuint name) {
	int cur_seq = brl_graphics_GraphicsSeq;
	int active_seq = rs_globals.sequence;
	
	if (name == rs_globals.texture2D_binding && cur_seq == active_seq ) {
		return;
	}
	
	if (name) {
		if (!rs_globals.texture2D_enabled || cur_seq != active_seq) {
			glEnable(GL_TEXTURE_2D);
			rs_globals.texture2D_enabled = true;
		}
		glBindTexture(GL_TEXTURE_2D, name);
	} else if (rs_globals.texture2D_enabled || cur_seq == active_seq) {
		glDisable(GL_TEXTURE_2D);
		rs_globals.texture2D_enabled = false;
	}
	rs_globals.sequence = cur_seq;
	rs_globals.texture2D_binding = name;
}


// render_buffer_t

/* // UNUSED
render_buffer_t *rb_new() {
	return rb_init(new render_buffer_t());
}
*/


render_buffer_t *rb_init(render_buffer_t *rb) {
	if (!rs_globals.state_bound) {
		rs_init(&rs_globals.active);
		rs_globals.state_bound = true;
	}
	
	if (rb) {
		// init vertex arrays
		rb->vertices_length = RENDER_BUFFER_INIT_ELEMENTS*2;
		rb->texcoords_length = RENDER_BUFFER_INIT_ELEMENTS*2;
		rb->colors_length = RENDER_BUFFER_INIT_ELEMENTS*4;
		rb->vertices = (GLfloat*)malloc(rb->vertices_length*sizeof(GLfloat));
		rb->texcoords = (GLfloat*)malloc(rb->texcoords_length*sizeof(GLfloat));
		rb->colors = (GLubyte*)malloc(rb->colors_length*sizeof(GLubyte));
		rb->index = 0;
		rb->sets = 0;
		rb->indices_length = RENDER_BUFFER_INIT_ELEMENTS;
		rb->indices = (GLint*)malloc(RENDER_BUFFER_INIT_ELEMENTS*sizeof(GLint));
		rb->counts = (GLsizei*)malloc(RENDER_BUFFER_INIT_ELEMENTS*sizeof(GLsizei));
		rb->lock = 0;
		
		// init index arrays
		rb->render_indices = (render_indices_t*)malloc(sizeof(render_indices_t)*RENDER_BUFFER_INIT_ELEMENTS);
		*rb->render_indices = (render_indices_t){0,0,0};
		
		// init state arrays
		rb->render_states = (render_state_t*)malloc(sizeof(render_state_t)*RENDER_BUFFER_INIT_ELEMENTS);
		rs_init(rb->render_states);
		
		rb->state_capacity = RENDER_BUFFER_INIT_ELEMENTS;
		rb->state_top = 0;
	}
	return rb;
}


void rb_destroy(render_buffer_t *rb) {
	if (rb) {
		free(rb->vertices);
		free(rb->texcoords);
		free(rb->colors);
		free(rb->indices);
		free(rb->counts);
		free(rb->render_states);
		free(rb->render_indices);
	}
}


inline void rb_new_state(render_buffer_t *rb) {	
	if (0 < rb->render_indices[rb->state_top].indices) {
		uint32_t last = rb->state_top;
		uint32_t top = ++rb->state_top;
		if (top == rb->state_capacity) {
			uint32_t newcap = rb->state_capacity *= 2;
			rb->render_indices = (render_indices_t*)realloc(rb->render_indices, sizeof(render_indices_t)*newcap);
			rb->render_states = (render_state_t*)realloc(rb->render_states, sizeof(render_state_t)*newcap);
		}
		
		rb->render_indices[top] = (render_indices_t){rb->sets, 0, 0};
		rb->render_states[top] = rb->render_states[last];
	}
}


void rb_set_texture(render_buffer_t *rb, GLuint name) {
	if (rb->render_states[rb->state_top].texture_name != name) {
		rb_new_state(rb);
		rb->render_states[rb->state_top].texture_name = name;
	}
}


void rb_set_mode(render_buffer_t *rb, GLenum mode) {
	if (rb->render_states[rb->state_top].render_mode != mode) {
		rb_new_state(rb);
		rb->render_states[rb->state_top].render_mode = mode;
	}
}


void rb_set_blend_func(render_buffer_t *rb, GLenum source, GLenum dest) {
	blend_factors_t orig = rb->render_states[rb->state_top].blend;
	if (orig.source != source || orig.dest != dest) {
		rb_new_state(rb);
		rb->render_states[rb->state_top].blend = (blend_factors_t){source, dest};
	}
}


void rb_set_alpha_func(render_buffer_t *rb, GLenum func, GLclampf ref) {
	alpha_test_t orig = rb->render_states[rb->state_top].alpha;
	if (orig.func != func || floats_differ(orig.ref, ref)) {
		rb_new_state(rb);
		rb->render_states[rb->state_top].alpha = (alpha_test_t){func, ref};
	}
}


void rb_set_scissor_test(render_buffer_t *rb, int enabled, int x, int y, int w, int h) {
	scissor_test_t scissor = rb->render_states[rb->state_top].scissor;
	if (scissor.enabled != enabled || (enabled && (scissor.x != x || scissor.y != y ||
		scissor.width != w || scissor.height != h))) {
		rb_new_state(rb);
		rb->render_states[rb->state_top].scissor = (scissor_test_t){enabled, (GLint)x, (GLint)y, (GLsizei)w, (GLsizei)h};
	}
}


void rb_set_line_width(render_buffer_t *rb, GLfloat width) {
	if (floats_differ(rb->render_states[rb->state_top].line_width, width)) {
		rb_new_state(rb);
		rb->render_states[rb->state_top].line_width = width;
	}
}


void rb_add_vertices(render_buffer_t *rb, int elements, GLfloat *vertices, GLfloat *texcoords, GLubyte *colors) {
	if (rb->lock != 0) {
		fprintf(stderr, "attempt to add vertices to buffer when locked\n");
		exit(1);
	}
	
	if (rb->indices_length <= rb->sets) {
		size_t new_size = (size_t)(rb->indices_length*RENDER_BUFFER_SCALE);
		rb->indices = (GLint*)realloc(rb->indices, new_size*sizeof(GLint));
		rb->counts = (GLsizei*)realloc(rb->counts, new_size*sizeof(GLsizei));
		rb->indices_length = new_size;
	}
	
	uint32_t index = rb->index;
	uint32_t set = rb->sets++;
	rb->indices[set] = index;
	rb->counts[set] = elements;
	
	{
		size_t sizereq = (size_t)(index+elements)*2;
	
		if (rb->vertices_length < sizereq) {
			size_t new_size = (size_t)(rb->vertices_length*RENDER_BUFFER_SCALE);
			if (new_size < sizereq) {
				new_size = sizereq;
			}
			rb->vertices = (GLfloat*)realloc(rb->vertices, new_size*sizeof(GLfloat));
			rb->vertices_length = new_size;
		}
	
		if (rb->texcoords_length < sizereq) {
			size_t new_size = (size_t)(rb->texcoords_length*RENDER_BUFFER_SCALE);
			if (new_size < sizereq) {
				new_size = sizereq;
			}
			rb->texcoords = (GLfloat*)realloc(rb->texcoords, new_size*sizeof(GLfloat));
			rb->texcoords_length = new_size;
		}
	
		sizereq *= 2;
		if (rb->colors_length < sizereq) {
			size_t new_size = (size_t)(rb->colors_length*RENDER_BUFFER_SCALE);
			if (new_size < sizereq) {
				new_size = sizereq;
			}
			rb->colors = (GLubyte*)realloc(rb->colors, new_size*sizeof(GLubyte));
			rb->colors_length = new_size;
		}
	}
	
	index *= 2;
	int copy_elems = elements*2;
	size_t copy_floats = copy_elems*sizeof(GLfloat);
	memcpy(rb->vertices+(index), vertices, copy_floats);
	
	if (texcoords != NULL) {
		memcpy(rb->texcoords+(index), texcoords, copy_floats);
	} else {
		memset(rb->texcoords+(index), 0, copy_floats);
	}
	
	if (colors != NULL) {
		memcpy(rb->colors+(index*2), colors, copy_elems*2*sizeof(GLubyte));
	} else {
		memset(rb->colors+(index*2), 255, copy_elems*2*sizeof(GLubyte));
	}
	
	
	rb->index += elements;
	render_indices_t *indices = rb->render_indices+rb->state_top;
	indices->indices += 1;
	indices->num_indices += elements;
}


void rb_lock_buffers(render_buffer_t *rb) {
	if (rb->lock == 0 && rb->index) {
		glVertexPointer(2, GL_FLOAT, 0, rb->vertices);
		glColorPointer(4, GL_UNSIGNED_BYTE, 0, rb->colors);
		glTexCoordPointer(2, GL_FLOAT, 0, rb->texcoords);
		
		if (GL_EXT_compiled_vertex_array) {
			glLockArraysEXT(0, rb->index);
		}
	}
	rb->lock += 1;
}


void rb_unlock_buffers(render_buffer_t *rb) {
	if (rb->lock == 0) {
		fprintf(stderr, "woops - unlock underflow\n");
		exit(1);
		return;
	}
	rb->lock -= 1;
	if (rb->lock == 0 && rb->index) {
		if (GL_EXT_compiled_vertex_array) {
			glUnlockArraysEXT();
		}
		
		glVertexPointer(4, GL_FLOAT, 0, NULL);
		glTexCoordPointer(4, GL_FLOAT, 0, NULL);
		glColorPointer(4, GL_FLOAT, 0, NULL);
	}
}


void rb_render(render_buffer_t *rb) {
	if (rb->sets == 0) {
		return;
	}
	
	rb_lock_buffers(rb);
	
	GLint *indices_ptr = rb->indices;
	GLsizei *counts_ptr = rb->counts;
	
	uint32_t state_idx = 0;
	uint32_t state_top = rb->state_top;
	
	render_indices_t *indexp;
	render_state_t *statep;
	
	if (GL_VERSION_1_4) {
		while (state_idx <= state_top) {
			indexp = rb->render_indices+state_idx;
			GLint indices = indexp->indices;
			
			if (0 < indices) {
				statep = rb->render_states+state_idx;
				rs_bind(statep);
				
				uint32_t index_from = indexp->index_from;
				if (1 < indices) {
					glMultiDrawArrays(statep->render_mode, indices_ptr+index_from, counts_ptr+index_from, indices);
				} else {
					glDrawArrays(statep->render_mode, indices_ptr[index_from], counts_ptr[index_from]);
				}
			}
			
			++state_idx;
		}
	} else {
		while (state_idx <= state_top) {
			indexp = rb->render_indices+state_idx;
			uint32_t indices = indexp->indices;
			if (0 < indices) {
				statep = rb->render_states+state_idx;
				rs_bind(statep);
				
				uint32_t index_from = indexp->index_from;
				for(; index_from < indices; ++index_from) {
					glDrawArrays(statep->render_mode, indices_ptr[index_from], counts_ptr[index_from]);
				}
			}
			
			++state_idx;
		}
	}
	
	rb_unlock_buffers(rb);
}


void rb_reset(render_buffer_t *rb) {
	if (rb->lock != 0) {
		// TODO: error?
		return;
	}
	uint32_t last = rb->state_top;
	rb->index = 0;
	rb->sets = 0;
	rb->state_top = 0;
	*rb->render_indices = (render_indices_t){0, 0, 0};
	*rb->render_states = rb->render_states[last];
}

#ifdef __cplusplus
}
#endif

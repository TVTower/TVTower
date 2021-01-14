#include "brl.mod/blitz.mod/blitz.h"
#include "brl.mod/blitz.mod/tree/tree.h"

#if !defined(generic_compare)
#	define generic_compare(x, y) (((x) > (y)) - ((x) < (y)))
#endif

/* +++++++++++++++++++++++++++++++++++++++++++++++++++++ */

struct longmap_node {
	struct avl_root link;
	BBLONG key;
	BBOBJECT value;
};

static int compare_longmap_nodes(const void *x, const void *y) {

        struct longmap_node * node_x = (struct longmap_node *)x;
        struct longmap_node * node_y = (struct longmap_node *)y;

        return generic_compare(node_x->key, node_y->key);
}

void bmx_map_longmap_clear(struct avl_root ** root) {
	struct longmap_node *node;
	struct longmap_node *tmp;
	avl_for_each_entry_safe(node, tmp, *root, link) {
		avl_del(&node->link, root);
		GC_FREE(node);
	}
}

int bmx_map_longmap_isempty(struct avl_root ** root) {
	return *root == 0;
}

void bmx_map_longmap_insert( BBLONG key, BBObject *value, struct avl_root ** root ) {
	struct longmap_node * node = (struct longmap_node *)GC_malloc_uncollectable(sizeof(struct longmap_node));
	node->key = key;
	node->value = value;
	
	struct longmap_node * old_node = (struct longmap_node *)avl_map(&node->link, compare_longmap_nodes, root);

	if (&node->link != &old_node->link) {
		// key already exists. Store the value in this node.
		old_node->value = value;
		// delete the new node, since we don't need it
		GC_FREE(node);
	}
}

int bmx_map_longmap_contains(BBLONG key, struct avl_root ** root) {
	struct longmap_node node;
	node.key = key;
	
	struct longmap_node * found = (struct longmap_node *)tree_search(&node, compare_longmap_nodes, *root);
	if (found) {
		return 1;
	} else {
		return 0;
	}
}

BBObject * bmx_map_longmap_valueforkey(BBLONG key, struct avl_root ** root) {
	struct longmap_node node;
	node.key = key;
	
	struct longmap_node * found = (struct longmap_node *)tree_search(&node, compare_longmap_nodes, *root);
	
	if (found) {
		return found->value;
	}
	
	return &bbNullObject;
}

int bmx_map_longmap_remove(BBLONG key, struct avl_root ** root) {
	struct longmap_node node;
	node.key = key;
	
	struct longmap_node * found = (struct longmap_node *)tree_search(&node, compare_longmap_nodes, *root);
	
	if (found) {
		avl_del(&found->link, root);
		GC_FREE(found);
		return 1;
	} else {
		return 0;
	}
}

struct longmap_node * bmx_map_longmap_nextnode(struct longmap_node * node) {
	return tree_successor(node);
}

struct longmap_node * bmx_map_longmap_firstnode(struct avl_root * root) {
	return tree_min(root);
}

BBLONG bmx_map_longmap_key(struct longmap_node * node) {
	return node->key;
}

BBObject * bmx_map_longmap_value(struct longmap_node * node) {
	return node->value;
}

int bmx_map_longmap_hasnext(struct longmap_node * node, struct avl_root * root) {
	if (!root) {
		return 0;
	}
	
	if (!node) {
		return 1;
	}
	
	return (tree_successor(node) != 0) ? 1 : 0;
}

void bmx_map_longmap_copy(struct avl_root ** dst_root, struct avl_root * src_root) {
	struct longmap_node *src_node;
	struct longmap_node *tmp;
	avl_for_each_entry_safe(src_node, tmp, src_root, link) {
		bmx_map_longmap_insert(src_node->key, src_node->value, dst_root);
	}
}

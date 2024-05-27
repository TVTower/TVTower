#include "brl.mod/blitz.mod/blitz.h"
#include "brl.mod/blitz.mod/tree/tree.h"

#if !defined(generic_compare)
#	define generic_compare(x, y) (((x) > (y)) - ((x) < (y)))
#endif


/* +++++++++++++++++++++++++++++++++++++++++++++++++++++ */

struct longintmap_node {
	struct avl_root link;
	BBLONG key;
	int value;
};

static int compare_longintmap_nodes(const void *x, const void *y) {

        struct longintmap_node * node_x = (struct longintmap_node *)x;
        struct longintmap_node * node_y = (struct longintmap_node *)y;

        return generic_compare(node_x->key, node_y->key);
}

void bmx_map_longintmap_clear(struct avl_root ** root) {
	struct longintmap_node *node;
	struct longintmap_node *tmp;
	if (*root == 0) return; // already cleared?
	avl_for_each_entry_safe(node, tmp, *root, link)
	{
		avl_del(&node->link, root);
		GC_FREE(node);
	}
}

int bmx_map_longintmap_isempty(struct avl_root * root) {
	return root == 0;
}

void bmx_map_longintmap_insert( BBLONG key, int value, struct avl_root ** root ) {
//Ronny: nodes contain no objects, so should no longer need GC interaction?
//       -> also replace GC_FREE stuff then
	struct longintmap_node * node = (struct longintmap_node *)GC_malloc_uncollectable(sizeof(struct longintmap_node));
	node->key = key;
	node->value = value;
	
	struct longintmap_node * old_node = (struct longintmap_node *)avl_map(&node->link, compare_longintmap_nodes, root);

	if (&node->link != &old_node->link) {
		// key already exists. Store the value in this node.
		old_node->value = value;
		// delete the new node, since we don't need it
		GC_FREE(node);
	}
}

int bmx_map_longintmap_contains(BBLONG key, struct avl_root * root) {
	struct longintmap_node node;
	node.key = key;
	
	struct longintmap_node * found = (struct longintmap_node *)TREE_SEARCH(&node, compare_longintmap_nodes, root);
	if (found) {
		return 1;
	} else {
		return 0;
	}
}

BBObject * bmx_map_longintmap_valueforkey(BBLONG key, struct avl_root * root) {
	struct longintmap_node node;
	node.key = key;
	
	struct longintmap_node * found = (struct longintmap_node *)TREE_SEARCH(&node, compare_longintmap_nodes, root);
	
	if (found) {
		return found->value;
	}
	
	return 0;
}

int bmx_map_longintmap_remove(BBLONG key, struct avl_root ** root) {
	struct longintmap_node node;
	node.key = key;
	
	struct longintmap_node * found = (struct longintmap_node *)TREE_SEARCH(&node, compare_longintmap_nodes, *root);
	
	if (found) {
		avl_del(&found->link, root);
		GC_FREE(found);
		return 1;
	} else {
		return 0;
	}
}

struct longintmap_node * bmx_map_longintmap_nextnode(struct longintmap_node * node) {
	return (struct longintmap_node *)TREE_SUCCESSOR(node);
}

struct longintmap_node * bmx_map_longintmap_firstnode(struct avl_root * root) {
	return (struct longintmap_node *)TREE_MIN(root);
}

BBLONG bmx_map_longintmap_key(struct longintmap_node * node) {
	return node->key;
}

int bmx_map_longintmap_value(struct longintmap_node * node) {
	return node->value;
}

int bmx_map_longintmap_hasnext(struct longintmap_node * node, struct avl_root * root) {
	if (!root) {
		return 0;
	}
	
	if (!node) {
		return 1;
	}
	
	return (TREE_SUCCESSOR(node) != 0) ? 1 : 0;
}

void bmx_map_longintmap_copy(struct avl_root ** dst_root, struct avl_root * src_root) {
	struct longintmap_node *src_node;
	struct longintmap_node *tmp;
	avl_for_each_entry_safe(src_node, tmp, src_root, link) {
		bmx_map_longintmap_insert(src_node->key, src_node->value, dst_root);
	}
}

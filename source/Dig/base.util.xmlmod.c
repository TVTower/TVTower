#include "text.mod/mxml.mod/mxml/mxml.h"
#include "brl.mod/blitz.mod/blitz.h"


BBString * bmx_mxmlElementGetAttrMOD(mxml_node_t * node, BBString * name, int *found) {
	char * n = bbStringToUTF8String(name);
	char * v = mxmlElementGetAttr(node, n);
	bbMemFree(n);
	if (v) {
		*found = 1;
		return bbStringFromUTF8String(v);
	}
	*found = 0;
	return &bbEmptyString;
}

BBString * bmx_mxmlElementGetAttrByIndexNoNameMOD(mxml_node_t * node, int index) {
    char * n;
    char * v = mxmlElementGetAttrByIndex(node, index, &n);
    if (v) {
        return bbStringFromUTF8String(v);
    } else {
        return &bbEmptyString;
    }
}

BBString * bmx_mxmlElementGetAttrCaseInsensitiveMOD(mxml_node_t *node,
                                                   BBString *attr,
                                                   int *found) {
    if (attr == &bbEmptyString) return &bbEmptyString;

    char *a = bbStringToUTF8String(attr);
    const char *result = NULL;
    int type = mxmlGetType(node);
    
    *found = 0;

    if (type == MXML_ELEMENT && a) {
        int count = mxmlElementGetAttrCount(node);

        for (int i = 0; i < count; i++) {
            const char *name = NULL;
            const char *val = mxmlElementGetAttrByIndex(node, i, &name);

            if (!name) 
                continue;

            // different name?
            if (strcasecmp(name, a) != 0) {
                continue;
            }

            // found the value
            result = val;   // can be NULL !
            *found = 1;
            break;
        }
    }

    bbMemFree(a);

    return bbStringFromUTF8String(result);
}



int bmx_mxmlElementHasAttrCaseInsensitiveMOD(mxml_node_t *node, BBString *name) {
    char *n = bbStringToUTF8String(name);
    int found = 0;

    if (mxmlGetType(node) == MXML_ELEMENT && n) {
        int count = mxmlElementGetAttrCount(node);
        for (int i = 0; i < count; i++) {
            const char *attrName = NULL;
            mxmlElementGetAttrByIndex(node, i, &attrName);
            if (attrName && strcasecmp(attrName, n) == 0) {
                found = 1;
                break;
            }
        }
    }

    bbMemFree(n);
    return found;
}

void bmx_mxmlElementDeleteAttrCaseInsensitiveMOD(mxml_node_t *node, BBString *name) {
    char *n = bbStringToUTF8String(name);

    if (mxmlGetType(node) == MXML_ELEMENT && n) {
        int count = mxmlElementGetAttrCount(node);
        for (int i = 0; i < count; i++) {
            const char *attrName = NULL;
            mxmlElementGetAttrByIndex(node, i, &attrName);
            if (attrName && strcasecmp(attrName, n) == 0) {
                // use original name (mxml stores case-sensitive)
                mxmlElementDeleteAttr(node, attrName);
                // only delete first found entry
                break;
            }
        }
    }

    bbMemFree(n);
}


mxml_node_t * bmx_mxmlFindElementCaseInsensitiveMOD(mxml_node_t * node,
    BBString * element, BBString * attr, BBString * value, int descend) {
    
    char * e = 0;
    char * a = 0;
    char * v = 0;
    
    if (element != &bbEmptyString) {
        e = bbStringToUTF8String(element);
    }
    if (attr != &bbEmptyString) {
        a = bbStringToUTF8String(attr);
    }
    if (value != &bbEmptyString) {
        v = bbStringToUTF8String(value);
    }

    mxml_node_t * result = 0;

    for (mxml_node_t * cur = node; cur; cur = mxmlWalkNext(cur, node, descend)) {
        if (mxmlGetType(cur) != MXML_ELEMENT) continue;

        if (e && strcasecmp(mxmlGetElement(cur), e) != 0) continue;

        if (a) {
            const char *attrVal = mxmlElementGetAttr(cur, a);
            if (!attrVal) continue;
            if (v && strcasecmp(attrVal, v) != 0) continue;
        }

        result = cur;
        break;
    }

    bbMemFree(v);
    bbMemFree(a);
    bbMemFree(e);

    return result;
}

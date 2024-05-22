/*
 Copyright (c) 2006-2012 Bruce A Henderson

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


 CONTRIBUTION:
 2014-04-04: Ronny Otto - added win32 specific "IN_LIBXML" definition
*/

/* RONNY:
 * add win32 specific definition
 */
#ifdef _WIN32
#define IN_LIBXML 1
#endif
// end modification

#include "blitz.h"
#include "libxml/catalog.h"
#include "libxml/entities.h"
#include "libxml/tree.h"
#include "libxml/uri.h"
#include "libxml/valid.h"
#include "libxml/xinclude.h"
#include "libxml/xmlreader.h"
#include "libxml/xpath.h"
#include "libxml/xpathInternals.h"
#include "libxml/xpointer.h"

extern "C" {

	int bmx_libxml_xmlbase_getType(xmlNodePtr handle);
	BBString * bmx_libxml_xmlbase_getName(xmlNodePtr handle);
	xmlDocPtr bmx_libxml_xmlbase_getDoc(xmlNodePtr handle);
	xmlNodePtr bmx_libxml_xmlbase_next(xmlNodePtr handle);
	xmlNodePtr bmx_libxml_xmlbase_prev(xmlNodePtr handle);
	xmlNodePtr bmx_libxml_xmlbase_children(xmlNodePtr handle);
	xmlNodePtr bmx_libxml_xmlbase_parent(xmlNodePtr handle);

	xmlNodePtr bmx_libxml_xmlGetLastChild(xmlNodePtr handle);
	int bmx_libxml_xmlGetLineNo(xmlNodePtr handle);

	xmlNodePtr bmx_libxml_xmlNewNode(xmlNsPtr ns, BBString * name);
	BBString * bmx_libxml_xmlNodeGetContent(xmlNodePtr handle);
	int bmx_libxml_xmlTextConcat(xmlNodePtr handle, BBString * content);
	int bmx_libxml_xmlNodeIsText(xmlNodePtr handle);
	int bmx_libxml_xmlIsBlankNode(xmlNodePtr handle);
	void bmx_libxml_xmlNodeSetBase(xmlNodePtr handle, BBString * uri);
	BBString * bmx_libxml_xmlNodeGetBase(xmlDocPtr doc, xmlNodePtr handle);
	void bmx_libxml_xmlNodeSetContent(xmlNodePtr handle, BBString * content);
	void bmx_libxml_xmlNodeAddContent(xmlNodePtr handle, BBString * content);
	void bmx_libxml_xmlNodeSetName(xmlNodePtr handle, BBString * name);
	xmlNodePtr bmx_libxml_xmlTextMerge(xmlNodePtr handle, xmlNodePtr node);
	xmlNodePtr bmx_libxml_xmlNewChild(xmlNodePtr handle, xmlNsPtr ns, BBString * name, BBString * content);
	xmlNodePtr bmx_libxml_xmlNewTextChild(xmlNodePtr handle, xmlNsPtr ns, BBString * name, BBString * content);
	xmlNodePtr bmx_libxml_xmlAddChild(xmlNodePtr handle, xmlNodePtr firstNode);
	xmlNodePtr bmx_libxml_xmlAddNextSibling(xmlNodePtr handle, xmlNodePtr node);
	xmlNodePtr bmx_libxml_xmlAddPrevSibling(xmlNodePtr handle, xmlNodePtr node);
	xmlNodePtr bmx_libxml_xmlAddSibling(xmlNodePtr handle, xmlNodePtr node);
	xmlAttrPtr bmx_libxml_xmlNewProp(xmlNodePtr handle, BBString * name, BBString * value);
	xmlAttrPtr bmx_libxml_xmlSetProp(xmlNodePtr handle, BBString * name, BBString * value);
	xmlAttrPtr bmx_libxml_xmlSetNsProp(xmlNodePtr handle, xmlNsPtr ns, BBString * name, BBString * value);
	int bmx_libxml_xmlUnsetNsProp(xmlNodePtr handle, xmlNsPtr ns, BBString * name);
	int bmx_libxml_xmlUnsetProp(xmlNodePtr handle, BBString * name);
	BBString * bmx_libxml_xmlGetProp(xmlNodePtr handle, BBString * name);
	BBString * bmx_libxml_xmlGetNsProp(xmlNodePtr handle, BBString * name, BBString * ns);
	BBString * bmx_libxml_xmlGetNoNsProp(xmlNodePtr handle, BBString * name);
	xmlAttrPtr bmx_libxml_xmlHasNsProp(xmlNodePtr handle, BBString * name, BBString * ns);
	xmlAttrPtr bmx_libxml_xmlHasProp(xmlNodePtr handle, BBString * name);
	BBString * bmx_libxml_xmlGetNodePath(xmlNodePtr handle);
	xmlNodePtr bmx_libxml_xmlReplaceNode(xmlNodePtr handle, xmlNodePtr withNode);
	void bmx_libxml_xmlSetNs(xmlNodePtr handle, xmlNsPtr ns);
	void bmx_libxml_xmlNodeSetSpacePreserve(xmlNodePtr handle, int value);
	int bmx_libxml_xmlNodeGetSpacePreserve(xmlNodePtr handle);
	void bmx_libxml_xmlNodeSetLang(xmlNodePtr handle, BBString * lang);
	BBString * bmx_libxml_xmlNodeGetLang(xmlNodePtr handle);
	xmlNodePtr bmx_libxml_xmlNewCDataBlock(xmlNodePtr handle, BBString * content);
	BBString * bmx_libxml_xmlNodeListGetString(xmlNodePtr handle);

	xmlNodePtr bmx_libxml_xmlNewComment(BBString * comment);
	void bmx_libxml_xmlNodeDump(xmlBufferPtr buffer, xmlNodePtr handle);
	xmlNsPtr bmx_libxml_xmlSearchNs(xmlNodePtr handle, BBString * ns);
	xmlNsPtr bmx_libxml_xmlSearchNsByHref(xmlNodePtr handle, BBString * href);
	xmlNodePtr bmx_libxml_xmlCopyNode(xmlNodePtr handle, int extended);
	xmlNodePtr bmx_libxml_xmlDocCopyNode(xmlNodePtr handle, xmlDocPtr doc, int extended);
	void bmx_libxml_xmlSetTreeDoc(xmlNodePtr handle, xmlDocPtr doc);
	int bmx_libxml_xmlXIncludeProcessTree(xmlNodePtr handle);
	int bmx_libxml_xmlXIncludeProcessTreeFlags(xmlNodePtr handle, int flags);
	xmlNsPtr bmx_libxml_xmlnode_namespace(xmlNodePtr handle);
	xmlAttrPtr bmx_libxml_xmlnode_properties(xmlNodePtr handle);
	void bmx_libxml_xmlUnlinkNode(xmlNodePtr handle);
	void bmx_libxml_xmlFreeNode(xmlNodePtr handle);

	xmlDocPtr bmx_libxml_xmlReadDoc(BBString * text, BBString * url, BBString * encoding, int options);
	xmlDocPtr bmx_libxml_xmlNewDoc(BBString * version);
	xmlDocPtr bmx_libxml_xmlParseFile(BBString * filename);
	xmlDocPtr bmx_libxml_xmlParseMemory(void * buf, int size);
	xmlDocPtr bmx_libxml_xmlParseDoc(BBString * text);
	xmlDocPtr bmx_libxml_xmlReadFile(BBString * filename, BBString * encoding, int options);
	xmlDocPtr bmx_libxml_xmlParseCatalogFile(BBString * filename);
	BBString * bmx_libxml_xmldoc_url(xmlDocPtr handle);
	xmlNodePtr bmx_libxml_xmlDocGetRootElement(xmlDocPtr handle);
	xmlNodePtr bmx_libxml_xmlDocSetRootElement(xmlDocPtr handle, xmlNodePtr root);
	void bmx_libxml_xmlFreeDoc(xmlDocPtr handle);
	BBString * bmx_libxml_xmldoc_version(xmlDocPtr handle);
	BBString * bmx_libxml_xmldoc_encoding(xmlDocPtr handle);
	void bmx_libxml_xmldoc_setencoding(xmlDocPtr handle, BBString * encoding);
	int bmx_libxml_xmldoc_standalone(xmlDocPtr handle);
	void bmx_libxml_xmldoc_setStandalone(xmlDocPtr handle, int value);
	xmlNodePtr bmx_libxml_xmlNewDocPI(xmlDocPtr handle, BBString * name, BBString * content);
	xmlAttrPtr bmx_libxml_xmlNewDocProp(xmlDocPtr handle, BBString * name, BBString * value);
	void bmx_libxml_xmlSetDocCompressMode(xmlDocPtr handle, int mode);
	int bmx_libxml_xmlGetDocCompressMode(xmlDocPtr handle);
	int bmx_libxml_xmlSaveFile(BBString * filename, xmlDocPtr handle, BBString * encoding);
	int bmx_libxml_xmlSaveFormatFileTo(xmlOutputBufferPtr outputBuffer, xmlDocPtr handle, BBString * encoding, int format);
	int bmx_libxml_xmlSaveFormatFile(BBString * filename, xmlDocPtr handle, BBString * encoding, int format);
	xmlXPathContextPtr bmx_libxml_xmlXPathNewContext(xmlDocPtr handle);
	xmlDtdPtr bmx_libxml_xmlCreateIntSubset(xmlDocPtr handle, BBString * name, BBString * externalID, BBString * systemID);
	xmlDtdPtr bmx_libxml_xmlGetIntSubset(xmlDocPtr handle);
	xmlDtdPtr bmx_libxml_xmlNewDtd(xmlDocPtr handle, BBString * name, BBString * externalID, BBString * systemID);
	void bmx_libxml_xmlXPathOrderDocElems(xmlDocPtr handle, BBInt64 * value);
	xmlDocPtr bmx_libxml_xmlCopyDoc(xmlDocPtr handle, int recursive);
	xmlEntityPtr bmx_libxml_xmlAddDocEntity(xmlDocPtr handle, BBString * name, int entityType, BBString * externalID, BBString * systemID, BBString * content);
	xmlEntityPtr bmx_libxml_xmlAddDtdEntity(xmlDocPtr handle, BBString * name, int entityType, BBString * externalID, BBString * systemID, BBString * content);
	BBString * bmx_libxml_xmlEncodeEntitiesReentrant(xmlDocPtr handle, BBString * inp);
	BBString * bmx_libxml_xmlEncodeSpecialChars(xmlDocPtr handle, BBString * inp);
	xmlEntityPtr bmx_libxml_xmlGetDocEntity(xmlDocPtr handle, BBString * name);
	xmlEntityPtr bmx_libxml_xmlGetDtdEntity(xmlDocPtr handle, BBString * name);
	xmlEntityPtr bmx_libxml_xmlGetParameterEntity(xmlDocPtr handle, BBString * name);
	int bmx_libxml_xmlXIncludeProcess(xmlDocPtr handle);
	int bmx_libxml_xmlXIncludeProcessFlags(xmlDocPtr handle, int flags);
	xmlAttrPtr bmx_libxml_xmlGetID(xmlDocPtr handle, BBString * id);
	int bmx_libxml_xmlIsID(xmlDocPtr handle, xmlNodePtr node, xmlAttrPtr attr);
	int bmx_libxml_xmlIsRef(xmlDocPtr handle, xmlNodePtr node, xmlAttrPtr attr);
	int bmx_libxml_xmlIsMixedElement(xmlDocPtr handle, BBString * name);
	int bmx_libxml_xmlRemoveID(xmlDocPtr handle, xmlAttrPtr attr);
	int bmx_libxml_xmlRemoveRef(xmlDocPtr handle, xmlAttrPtr attr);
	xmlElementContentPtr bmx_libxml_xmlNewDocElementContent(xmlDocPtr handle, BBString * name, int contentType);
	void bmx_libxml_xmlFreeDocElementContent(xmlDocPtr handle, xmlElementContentPtr content);
	BBString * bmx_libxml_xmlValidCtxtNormalizeAttributeValue(xmlValidCtxtPtr context, xmlDocPtr handle, xmlNodePtr elem, BBString * name, BBString * value);
	BBString * bmx_libxml_xmlValidNormalizeAttributeValue(xmlDocPtr handle, xmlNodePtr elem, BBString * name, BBString * value);

	int bmx_libxml_xmlns_type(xmlNsPtr handle);
	BBString * bmx_libxml_xmlns_href(xmlNsPtr handle);
	BBString * bmx_libxml_xmlns_prefix(xmlNsPtr handle);
	void bmx_libxml_xmlFreeNs(xmlNsPtr handle);

	int bmx_libxml_xmlattr_atype(xmlAttrPtr handle);
	xmlNsPtr bmx_libxml_xmlattr_ns(xmlAttrPtr handle);

	xmlXPathCompExprPtr bmx_libxml_xmlXPathCompile(BBString * expr);
	xmlXPathObjectPtr bmx_libxml_xmlXPathCompiledEval(xmlXPathCompExprPtr handle, xmlXPathContextPtr context);
	void bmx_libxml_xmlXPathFreeCompExpr(xmlXPathCompExprPtr handle);

	int bmx_libxml_xmlelementcontent_type(xmlElementContentPtr handle);
	int bmx_libxml_xmlelementcontent_ocur(xmlElementContentPtr handle);
	BBString * bmx_libxml_xmlelementcontent_name(xmlElementContentPtr handle);
	BBString * bmx_libxml_xmlelementcontent_prefix(xmlElementContentPtr handle);

	int bmx_libxml_xmlValidateAttributeValue(int attributeType, BBString * value);
	xmlValidCtxtPtr bmx_libxml_xmlNewValidCtxt();
	int bmx_libxml_xmlValidateNameValue(BBString * value);
	int bmx_libxml_xmlValidateNamesValue(BBString * value);
	int bmx_libxml_xmlValidateNmtokenValue(BBString * value);
	int bmx_libxml_xmlValidateNmtokensValue(BBString * value);
	int bmx_libxml_xmlvalidctxt_valid(xmlValidCtxtPtr handle);
	int bmx_libxml_xmlvalidctxt_finishDtd(xmlValidCtxtPtr handle);
	xmlDocPtr bmx_libxml_xmlvalidctxt_doc(xmlValidCtxtPtr handle);
	int bmx_libxml_xmlValidateDocument(xmlValidCtxtPtr handle, xmlDocPtr doc);
	int bmx_libxml_xmlValidateDocumentFinal(xmlValidCtxtPtr handle, xmlDocPtr doc);
	int bmx_libxml_xmlValidateDtd(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlDtdPtr dtd);
	int bmx_libxml_xmlValidateDtdFinal(xmlValidCtxtPtr handle, xmlDocPtr doc);
	int bmx_libxml_xmlValidateRoot(xmlValidCtxtPtr handle, xmlDocPtr doc);
	int bmx_libxml_xmlValidateElement(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlNodePtr elem);
	int bmx_libxml_xmlValidateElementDecl(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlElementPtr elem);
	int bmx_libxml_xmlValidateAttributeDecl(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlAttributePtr attr);
	int bmx_libxml_xmlValidBuildContentModel(xmlValidCtxtPtr handle, xmlElementPtr elem);
	void bmx_libxml_xmlFreeValidCtxt(xmlValidCtxtPtr handle);

	xmlXPathContextPtr bmx_libxml_xmlXPtrNewContext(xmlDocPtr doc, xmlNodePtr here, xmlNodePtr origin);
	xmlXPathObjectPtr bmx_libxml_xmlXPathEvalExpression(BBString * text, xmlXPathContextPtr handle);
	xmlXPathObjectPtr bmx_libxml_xmlXPathEval(BBString * text, xmlXPathContextPtr handle);
	xmlDocPtr bmx_libxml_xmlxpathcontext_doc(xmlXPathContextPtr handle);
	xmlNodePtr bmx_libxml_xmlxpathcontext_node(xmlXPathContextPtr handle);
	int bmx_libxml_xmlXPathRegisterNs(xmlXPathContextPtr handle, BBString * prefix, BBString * uri);
	int bmx_libxml_xmlXPathEvalPredicate(xmlXPathContextPtr handle, xmlXPathObjectPtr res);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrEval(BBString * expr, xmlXPathContextPtr handle);
	int bmx_libxml_xmlxpathcontext_nb_types(xmlXPathContextPtr handle);
	int bmx_libxml_xmlxpathcontext_max_types(xmlXPathContextPtr handle);
	int bmx_libxml_xmlxpathcontext_contextSize(xmlXPathContextPtr handle);
	int bmx_libxml_xmlxpathcontext_proximityPosition(xmlXPathContextPtr handle);
	int bmx_libxml_xmlxpathcontext_xptr(xmlXPathContextPtr handle);
	xmlNodePtr bmx_libxml_xmlxpathcontext_here(xmlXPathContextPtr handle);
	xmlNodePtr bmx_libxml_xmlxpathcontext_origin(xmlXPathContextPtr handle);
	BBString * bmx_libxml_xmlxpathcontext_function(xmlXPathContextPtr handle);
	BBString * bmx_libxml_xmlxpathcontext_functionURI(xmlXPathContextPtr handle);
	void bmx_libxml_xmlXPathFreeContext(xmlXPathContextPtr handle);

	BBString * bmx_libxml_xmldtd_externalID(xmlDtdPtr handle);
	BBString * bmx_libxml_xmldtd_systemID(xmlDtdPtr handle);
	xmlDtdPtr bmx_libxml_xmlCopyDtd(xmlDtdPtr handle);
	xmlAttributePtr bmx_libxml_xmlGetDtdAttrDesc(xmlDtdPtr handle, BBString * elem, BBString * name);
	xmlElementPtr bmx_libxml_xmlGetDtdElementDesc(xmlDtdPtr handle, BBString * name);
	xmlNotationPtr bmx_libxml_xmlGetDtdNotationDesc(xmlDtdPtr handle, BBString * name);
	xmlAttributePtr bmx_libxml_xmlGetDtdQAttrDesc(xmlDtdPtr handle, BBString * elem, BBString * name, BBString * prefix);
	xmlElementPtr bmx_libxml_xmlGetDtdQElementDesc(xmlDtdPtr handle, BBString * name, BBString * prefix);
	void bmx_libxml_xmlFreeDtd(xmlDtdPtr handle);

	xmlErrorPtr bmx_libxml_xmlGetLastError();
	int bmx_libxml_xmlerror_domain(xmlErrorPtr handle);
	int bmx_libxml_xmlerror_code(xmlErrorPtr handle);
	BBString * bmx_libxml_xmlerror_message(xmlErrorPtr handle);
	int bmx_libxml_xmlerror_level(xmlErrorPtr handle);
	BBString * bmx_libxml_xmlerror_file(xmlErrorPtr handle);
	int bmx_libxml_xmlerror_line(xmlErrorPtr handle);
	BBString * bmx_libxml_xmlerror_str1(xmlErrorPtr handle);
	BBString * bmx_libxml_xmlerror_str2(xmlErrorPtr handle);
	BBString * bmx_libxml_xmlerror_str3(xmlErrorPtr handle);
	int bmx_libxml_xmlerror_int2(xmlErrorPtr handle);
	xmlNodePtr bmx_libxml_xmlerror_node(xmlErrorPtr handle);

	xmlEntityPtr bmx_libxml_xmlGetPredefinedEntity(BBString * name);
	int bmx_libxml_xmlSubstituteEntitiesDefault(int value);

	xmlBufferPtr bmx_libxml_xmlBufferCreate();
	xmlBufferPtr bmx_libxml_xmlBufferCreateStatic(void * mem, int size);
	BBString * bmx_libxml_xmlbuffer_content(xmlBufferPtr handle);
	void bmx_libxml_xmlBufferFree(xmlBufferPtr handle);

	int bmx_libxml_xmlnodeset_nodeNr(xmlNodeSetPtr handle);
	xmlNodePtr bmx_libxml_xmlnodeset_nodetab(xmlNodeSetPtr handle, int index);
	int bmx_libxml_xmlXPathCastNodeSetToBoolean(xmlNodeSetPtr handle);
	double bmx_libxml_xmlXPathCastNodeSetToNumber(xmlNodeSetPtr handle);
	BBString * bmx_libxml_xmlXPathCastNodeSetToString(xmlNodeSetPtr handle);
	void bmx_libxml_xmlXPathFreeNodeSet(xmlNodeSetPtr handle);

	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewCollapsedRange(xmlNodePtr node);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewLocationSetNodeSet(xmlNodeSetPtr set);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewLocationSetNodes(xmlNodePtr start, xmlNodePtr end);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRange(xmlNodePtr start, int startindex, xmlNodePtr end, int endindex);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangeNodeObject(xmlNodePtr start, xmlXPathObjectPtr end);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangeNodePoint(xmlNodePtr start, xmlXPathObjectPtr end);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangeNodes(xmlNodePtr start, xmlNodePtr end);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangePointNode(xmlXPathObjectPtr start, xmlNodePtr end);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangePoints(xmlXPathObjectPtr start, xmlXPathObjectPtr end);
	xmlXPathObjectPtr bmx_libxml_xmlXPtrWrapLocationSet(xmlLocationSetPtr val);
	int bmx_libxml_xmlxpathobject_type(xmlXPathObjectPtr handle);
	xmlNodeSetPtr bmx_libxml_xmlxpathobject_nodesetval(xmlXPathObjectPtr handle);
	BBString * bmx_libxml_xmlxpathobject_stringval(xmlXPathObjectPtr handle);
	int bmx_libxml_xmlXPathCastToBoolean(xmlXPathObjectPtr handle);
	double bmx_libxml_xmlXPathCastToNumber(xmlXPathObjectPtr handle);
	BBString * bmx_libxml_xmlXPathCastToString(xmlXPathObjectPtr handle);
	xmlXPathObjectPtr bmx_libxml_xmlXPathConvertBoolean(xmlXPathObjectPtr handle);
	xmlXPathObjectPtr bmx_libxml_xmlXPathConvertNumber(xmlXPathObjectPtr handle);
	xmlXPathObjectPtr bmx_libxml_xmlXPathConvertString(xmlXPathObjectPtr handle);
	xmlXPathObjectPtr bmx_libxml_xmlXPathObjectCopy(xmlXPathObjectPtr handle);
	xmlNodePtr bmx_libxml_xmlXPtrBuildNodeList(xmlXPathObjectPtr handle);
	xmlLocationSetPtr bmx_libxml_xmlXPtrLocationSetCreate(xmlXPathObjectPtr handle);
	void bmx_libxml_xmlXPathFreeObject(xmlXPathObjectPtr handle);

	xmlXIncludeCtxtPtr bmx_libxml_xmlXIncludeNewContext(xmlDocPtr doc);
	int bmx_libxml_xmlXIncludeProcessNode(xmlXIncludeCtxtPtr handle, xmlNodePtr node);
	int bmx_libxml_xmlXIncludeSetFlags(xmlXIncludeCtxtPtr handle, int flags);
	void bmx_libxml_xmlXIncludeFreeContext(xmlXIncludeCtxtPtr handle);

	xmlURIPtr bmx_libxml_xmlCreateURI();
	xmlURIPtr bmx_libxml_xmlParseURI(BBString * uri);
	xmlURIPtr bmx_libxml_xmlParseURIRaw(BBString * uri, int raw);
	BBString * bmx_libxml_xmlBuildURI(BBString * uri, BBString * base);
	BBString * bmx_libxml_xmlCanonicPath(BBString * path);
	BBString * bmx_libxml_xmlNormalizeURIPath(BBString * path);
	BBString * bmx_libxml_xmlURIEscape(BBString * uri);
	BBString * bmx_libxml_xmlURIEscapeStr(BBString * uri, BBString * list);
	BBString * bmx_libxml_xmlURIUnescapeString(BBString * text);
	int bmx_libxml_xmlParseURIReference(xmlURIPtr handle, BBString * uri);
	BBString * bmx_libxml_xmlSaveUri(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_scheme(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_opaque(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_authority(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_server(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_user(xmlURIPtr handle);
	int bmx_libxml_xmluri_port(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_path(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_query(xmlURIPtr handle);
	BBString * bmx_libxml_xmluri_fragment(xmlURIPtr handle);
	void bmx_libxml_xmlFreeURI(xmlURIPtr handle);

	xmlTextReaderPtr bmx_libxml_xmlNewTextReaderFilename(BBString * filename);
	xmlTextReaderPtr bmx_libxml_xmlReaderForFile(BBString * filename, BBString * encoding, int options);
	xmlTextReaderPtr bmx_libxml_xmlReaderForMemory(void * buf, int size, BBString * url, BBString * encoding, int options);
	xmlTextReaderPtr bmx_libxml_xmlReaderForDoc(char * docTextPtr, BBString * urlTextPtr, BBString * encTextPtr, int options);
	int bmx_libxml_xmlTextReaderAttributeCount(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderBaseUri(xmlTextReaderPtr handle);
	xmlDocPtr bmx_libxml_xmlTextReaderCurrentDoc(xmlTextReaderPtr handle);
	void bmx_libxml_xmlFreeTextReader(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderRead(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderReadAttributeValue(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderReadInnerXml(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderReadOuterXml(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderReadState(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderReadString(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstName(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstLocalName(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstEncoding(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstBaseUri(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstNamespaceUri(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstPrefix(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstValue(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstXmlLang(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderConstXmlVersion(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderDepth(xmlTextReaderPtr handle);
	xmlNodePtr bmx_libxml_xmlTextReaderExpand(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderGetAttribute(xmlTextReaderPtr handle, BBString * name);
	BBString * bmx_libxml_xmlTextReaderGetAttributeNo(xmlTextReaderPtr handle, int index);
	BBString * bmx_libxml_xmlTextReaderGetAttributeNs(xmlTextReaderPtr handle, BBString * localName, BBString * namespaceURI);
	int bmx_libxml_xmlTextReaderGetParserColumnNumber(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderGetParserLineNumber(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderGetParserProp(xmlTextReaderPtr handle, int prop);
	int bmx_libxml_xmlTextReaderHasAttributes(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderHasValue(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderIsDefault(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderIsEmptyElement(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderIsNamespaceDecl(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderIsValid(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderLocalName(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderLookupNamespace(xmlTextReaderPtr handle, BBString * prefix);
	int bmx_libxml_xmlTextReaderMoveToAttribute(xmlTextReaderPtr handle, BBString * name);
	int bmx_libxml_xmlTextReaderMoveToAttributeNo(xmlTextReaderPtr handle, int index);
	int bmx_libxml_xmlTextReaderMoveToAttributeNs(xmlTextReaderPtr handle, BBString * localName, BBString * namespaceURI);
	int bmx_libxml_xmlTextReaderMoveToElement(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderMoveToFirstAttribute(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderMoveToNextAttribute(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderName(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderNamespaceUri(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderNext(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderNodeType(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderNormalization(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderPrefix(xmlTextReaderPtr handle);
	xmlNodePtr bmx_libxml_xmlTextReaderPreserve(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderQuoteChar(xmlTextReaderPtr handle);
	int bmx_libxml_xmlTextReaderRelaxNGValidate(xmlTextReaderPtr handle, BBString * rng);
	int bmx_libxml_xmlTextReaderSchemaValidate(xmlTextReaderPtr handle, BBString * xsd);
	int bmx_libxml_xmlTextReaderSetParserProp(xmlTextReaderPtr handle, int prop, int value);
	int bmx_libxml_xmlTextReaderStandalone(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderValue(xmlTextReaderPtr handle);
	BBString * bmx_libxml_xmlTextReaderXmlLang(xmlTextReaderPtr handle);

	xmlCatalogPtr bmx_libxml_xmlNewCatalog(int sgml);
	xmlCatalogPtr bmx_libxml_xmlLoadACatalog(BBString * filename);
	int bm_libxml_xmlLoadCatalog(BBString * filename);
	xmlCatalogPtr bmx_libxml_xmlLoadSGMLSuperCatalog(BBString * filename);
	void bmx_libxml_xmlCatalogSetDefaults(int allow);
	int bmx_libxml_xmlCatalogGetDefaults();
	int bmx_libxml_xmlCatalogSetDebug(int level);
	int bmx_libxml_xmlCatalogSetDefaultPrefer(int prefer);
	int bmx_libxml_xmlCatalogAdd(BBString * rtype, BBString * orig, BBString * rep);
	int bmx_libxml_xmlCatalogConvert();
	int bmx_libxml_xmlCatalogRemove(BBString * value);
	BBString * bmx_libxml_xmlCatalogResolve(BBString * pubID, BBString * sysID);
	BBString * bmx_libxml_xmlCatalogResolvePublic(BBString * pubID);
	BBString * bmx_libxml_xmlCatalogResolveSystem(BBString * sysID);
	BBString * bmx_libxml_xmlCatalogResolveURI(BBString * uri);
	int bmx_libxml_xmlACatalogAdd(xmlCatalogPtr handle, BBString * rtype, BBString * orig, BBString * rep);
	int bmx_libxml_xmlACatalogRemove(xmlCatalogPtr handle, BBString * value);
	BBString * bmx_libxml_xmlACatalogResolve(xmlCatalogPtr handle, BBString * pubID, BBString * sysID);
	BBString * bmx_libxml_xmlACatalogResolvePublic(xmlCatalogPtr handle, BBString * pubID);
	BBString * bmx_libxml_xmlACatalogResolveSystem(xmlCatalogPtr handle, BBString * sysID);
	int bmx_libxml_xmlCatalogIsEmpty(xmlCatalogPtr handle);
	int bmx_libxml_xmlConvertSGMLCatalog(xmlCatalogPtr handle);
	void bmx_libxml_xmlACatalogDump(xmlCatalogPtr handle, int file);
	void bmx_libxml_xmlFreeCatalog(xmlCatalogPtr handle);

	BBString * bmx_libxml_xmldtdattribute_defaultValue(xmlAttributePtr handle);

	int bmx_libxml_xmldtdelement_etype(xmlElementPtr handle);
	BBString * bmx_libxml_xmldtdelement_prefix(xmlElementPtr handle);

	BBString * bmx_libxml_xmlnotation_name(xmlNotationPtr handle);
	BBString * bmx_libxml_xmlnotation_PublicID(xmlNotationPtr handle);
	BBString * bmx_libxml_xmlnotation_SystemID(xmlNotationPtr handle);

	void bmx_libxml_xmlXPtrLocationSetAdd(xmlLocationSetPtr handle, xmlXPathObjectPtr value);
	void bmx_libxml_xmlXPtrLocationSetDel(xmlLocationSetPtr handle, xmlXPathObjectPtr value);
	xmlLocationSetPtr bmx_libxml_xmlXPtrLocationSetMerge(xmlLocationSetPtr handle, xmlLocationSetPtr value);
	void bmx_libxml_xmlXPtrLocationSetRemove(xmlLocationSetPtr handle, int index);
	void bmx_libxml_xmlXPtrFreeLocationSet(xmlLocationSetPtr handle);

	BBString * bbStringFromXmlChar(xmlChar * text);
	char * bbStringToUTF8StringOrNull(BBString * text);
}

// ****************************************************************************

BBString * bbStringFromXmlChar(xmlChar * text) {
	if (text) {
		BBString * s = bbStringFromUTF8String((char *) text);
		xmlFree(text);
		return s;
	} else {
		return &bbEmptyString;
	}
}

char * bbStringToUTF8StringOrNull(BBString * text) {
	if (text && (text != &bbEmptyString) && text->length > 0) {
		return bbStringToUTF8String(text);
	} else {
		return 0;
	}
}

// ****************************************************************************


int bmx_libxml_xmlbase_getType(xmlNodePtr handle) {
	return static_cast<int>(handle->type);
}

BBString * bmx_libxml_xmlbase_getName(xmlNodePtr handle) {
	return bbStringFromUTF8String((const char*)handle->name);
}

xmlDocPtr bmx_libxml_xmlbase_getDoc(xmlNodePtr handle) {
	return handle->doc;
}

xmlNodePtr bmx_libxml_xmlbase_next(xmlNodePtr handle) {
	return handle->next;
}

xmlNodePtr bmx_libxml_xmlbase_prev(xmlNodePtr handle) {
	return handle->prev;
}

xmlNodePtr bmx_libxml_xmlbase_children(xmlNodePtr handle) {
	return handle->children;
}

xmlNodePtr bmx_libxml_xmlbase_parent(xmlNodePtr handle) {
	return handle->parent;
}

// ****************************************************************************

xmlNodePtr bmx_libxml_xmlGetLastChild(xmlNodePtr handle) {
	return xmlGetLastChild(handle);
}

int bmx_libxml_xmlGetLineNo(xmlNodePtr handle) {
	return xmlGetLineNo(handle);
}

// ****************************************************************************

xmlNodePtr bmx_libxml_xmlNewNode(xmlNsPtr ns, BBString * name) {
	xmlNodePtr node = 0;

	char * n = bbStringToUTF8String(name);
	node = xmlNewNode(ns, (xmlChar*)n);
	bbMemFree(n);

	return node;
}

BBString * bmx_libxml_xmlNodeGetContent(xmlNodePtr handle) {
	return bbStringFromXmlChar(xmlNodeGetContent(handle));
}

int bmx_libxml_xmlTextConcat(xmlNodePtr handle, BBString * content) {
	char * s = bbStringToUTF8String(content);
	int ret = xmlTextConcat(handle, (xmlChar *)s, strlen(s));
	bbMemFree(s);
	return ret;
}

int bmx_libxml_xmlNodeIsText(xmlNodePtr handle) {
	return xmlNodeIsText(handle);
}

int bmx_libxml_xmlIsBlankNode(xmlNodePtr handle) {
	return xmlIsBlankNode(handle);
}

void bmx_libxml_xmlNodeSetBase(xmlNodePtr handle, BBString * uri) {
	char * s = bbStringToUTF8String(uri);
	xmlNodeSetBase(handle, (xmlChar *)s);
	bbMemFree(s);
}

BBString * bmx_libxml_xmlNodeGetBase(xmlDocPtr doc, xmlNodePtr handle) {
	return bbStringFromXmlChar(xmlNodeGetBase(doc, handle));
}

void bmx_libxml_xmlNodeSetContent(xmlNodePtr handle, BBString * content) {
	char * s = bbStringToUTF8String(content);
	xmlNodeSetContent(handle, (xmlChar *)s);
	bbMemFree(s);
}

void bmx_libxml_xmlNodeAddContent(xmlNodePtr handle, BBString * content) {
	char * s = bbStringToUTF8String(content);
	xmlNodeAddContent(handle, (xmlChar *)s);
	bbMemFree(s);
}

void bmx_libxml_xmlNodeSetName(xmlNodePtr handle, BBString * name) {
	char * s = bbStringToUTF8String(name);
	xmlNodeSetName(handle, (xmlChar *)s);
	bbMemFree(s);
}

xmlNodePtr bmx_libxml_xmlTextMerge(xmlNodePtr handle, xmlNodePtr node) {
	return xmlTextMerge(handle, node);
}

xmlNodePtr bmx_libxml_xmlNewChild(xmlNodePtr handle, xmlNsPtr ns, BBString * name, BBString * content) {
	char * n = bbStringToUTF8String(name);
	char * s = bbStringToUTF8StringOrNull(content);
	xmlNodePtr child = xmlNewChild(handle, ns, (xmlChar *)n, (xmlChar *)s);
	bbMemFree(s);
	bbMemFree(n);
	return child;
}

xmlNodePtr bmx_libxml_xmlNewTextChild(xmlNodePtr handle, xmlNsPtr ns, BBString * name, BBString * content) {
	char * n = bbStringToUTF8String(name);
	char * s = bbStringToUTF8StringOrNull(content);
	xmlNodePtr child = xmlNewTextChild(handle, ns, (xmlChar *)n, (xmlChar *)s);
	bbMemFree(s);
	bbMemFree(n);
	return child;
}

xmlNodePtr bmx_libxml_xmlAddChild(xmlNodePtr handle, xmlNodePtr firstNode) {
	return xmlAddChild(handle, firstNode);
}

xmlNodePtr bmx_libxml_xmlAddNextSibling(xmlNodePtr handle, xmlNodePtr node) {
	return xmlAddNextSibling(handle, node);
}

xmlNodePtr bmx_libxml_xmlAddPrevSibling(xmlNodePtr handle, xmlNodePtr node) {
	return xmlAddPrevSibling(handle, node);
}

xmlNodePtr bmx_libxml_xmlAddSibling(xmlNodePtr handle, xmlNodePtr node) {
	return xmlAddSibling(handle, node);
}

xmlAttrPtr bmx_libxml_xmlNewProp(xmlNodePtr handle, BBString * name, BBString * value) {
	char * n = bbStringToUTF8String(name);
	char * v = bbStringToUTF8String(value);
	xmlAttrPtr a = xmlNewProp(handle, (xmlChar *)n, (xmlChar *)v);
	bbMemFree(v);
	bbMemFree(n);
	return a;
}

xmlAttrPtr bmx_libxml_xmlSetProp(xmlNodePtr handle, BBString * name, BBString * value) {
	char * n = bbStringToUTF8String(name);
	char * v = bbStringToUTF8String(value);
	xmlAttrPtr a = xmlSetProp(handle, (xmlChar *)n, (xmlChar *)v);
	bbMemFree(v);
	bbMemFree(n);
	return a;
}

xmlAttrPtr bmx_libxml_xmlSetNsProp(xmlNodePtr handle, xmlNsPtr ns, BBString * name, BBString * value) {
	char * n = bbStringToUTF8String(name);
	char * v = bbStringToUTF8String(value);
	xmlAttrPtr a = xmlSetNsProp(handle, ns, (xmlChar *)n, (xmlChar *)v);
	bbMemFree(v);
	bbMemFree(n);
	return a;
}

int bmx_libxml_xmlUnsetNsProp(xmlNodePtr handle, xmlNsPtr ns, BBString * name) {
	char * n = bbStringToUTF8String(name);
	int ret = xmlUnsetNsProp(handle, ns, (xmlChar *)n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlUnsetProp(xmlNodePtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	int ret = xmlUnsetProp(handle, (xmlChar *)n);
	bbMemFree(n);
	return ret;
}

BBString * bmx_libxml_xmlGetProp(xmlNodePtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	BBString * s = bbStringFromXmlChar(xmlGetProp(handle, (xmlChar *)n));
	bbMemFree(n);
	return s;

}

BBString * bmx_libxml_xmlGetNsProp(xmlNodePtr handle, BBString * name, BBString * ns) {
	char * n = bbStringToUTF8String(name);
	char * nss = bbStringToUTF8StringOrNull(ns);
	BBString * s = bbStringFromXmlChar(xmlGetNsProp(handle, (xmlChar *)n, (xmlChar *)nss));
	bbMemFree(nss);
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlGetNoNsProp(xmlNodePtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	BBString * s = bbStringFromXmlChar(xmlGetNoNsProp(handle, (xmlChar *)n));
	bbMemFree(n);
	return s;
}

xmlAttrPtr bmx_libxml_xmlHasNsProp(xmlNodePtr handle, BBString * name, BBString * ns) {
	char * n = bbStringToUTF8String(name);
	char * nss = bbStringToUTF8StringOrNull(ns);
	xmlAttrPtr a = xmlHasNsProp(handle, (xmlChar *)n, (xmlChar *)nss);
	bbMemFree(nss);
	bbMemFree(n);
	return a;
}

xmlAttrPtr bmx_libxml_xmlHasProp(xmlNodePtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	xmlAttrPtr a = xmlHasProp(handle, (xmlChar *)n);
	bbMemFree(n);
	return a;
}

BBString * bmx_libxml_xmlGetNodePath(xmlNodePtr handle) {
	return bbStringFromXmlChar(xmlGetNodePath(handle));
}

xmlNodePtr bmx_libxml_xmlReplaceNode(xmlNodePtr handle, xmlNodePtr withNode) {
	return xmlReplaceNode(handle, withNode);
}

void bmx_libxml_xmlSetNs(xmlNodePtr handle, xmlNsPtr ns) {
	xmlSetNs(handle, ns);
}

void bmx_libxml_xmlNodeSetSpacePreserve(xmlNodePtr handle, int value) {
	xmlNodeSetSpacePreserve(handle, value);
}

int bmx_libxml_xmlNodeGetSpacePreserve(xmlNodePtr handle) {
	return xmlNodeGetSpacePreserve(handle);
}

void bmx_libxml_xmlNodeSetLang(xmlNodePtr handle, BBString * lang) {
	char * n = bbStringToUTF8String(lang);
	xmlNodeSetLang(handle, (xmlChar *)n);
	bbMemFree(n);
}

BBString * bmx_libxml_xmlNodeGetLang(xmlNodePtr handle) {
	return bbStringFromXmlChar(xmlNodeGetLang(handle));
}

xmlNodePtr bmx_libxml_xmlNewCDataBlock(xmlNodePtr handle, BBString * content) {
	char * n = bbStringToUTF8String(content);
	xmlNodePtr np = xmlNewCDataBlock(handle->doc, (xmlChar *)n, strlen(n));
	bbMemFree(n);
	return np;
}

BBString * bmx_libxml_xmlNodeListGetString(xmlNodePtr handle) {
	return bbStringFromXmlChar(xmlNodeListGetString(handle->doc, handle->children, 1));
}

xmlNodePtr bmx_libxml_xmlNewComment(BBString * comment) {
	char * n = bbStringToUTF8String(comment);
	xmlNodePtr np = xmlNewComment((xmlChar *)n);
	bbMemFree(n);
	return np;
}

void bmx_libxml_xmlNodeDump(xmlBufferPtr buffer, xmlNodePtr handle) {
	xmlNodeDump(buffer, handle->doc, handle, 1, 1);
}

xmlNsPtr bmx_libxml_xmlSearchNs(xmlNodePtr handle, BBString * ns) {
	char * nss = bbStringToUTF8StringOrNull(ns);
	xmlNsPtr n = xmlSearchNs(handle->doc, handle, (xmlChar *)nss);
	bbMemFree(nss);
	return n;
}

xmlNsPtr bmx_libxml_xmlSearchNsByHref(xmlNodePtr handle, BBString * href) {
	char * n = bbStringToUTF8String(href);
	xmlNsPtr ns = xmlSearchNsByHref(handle->doc, handle, (xmlChar *)n);
	bbMemFree(n);
	return ns;
}

xmlNodePtr bmx_libxml_xmlCopyNode(xmlNodePtr handle, int extended) {
	return xmlCopyNode(handle, extended);
}

xmlNodePtr bmx_libxml_xmlDocCopyNode(xmlNodePtr handle, xmlDocPtr doc, int extended) {
	return xmlDocCopyNode(handle, doc, extended);
}

void bmx_libxml_xmlSetTreeDoc(xmlNodePtr handle, xmlDocPtr doc) {
	xmlSetTreeDoc(handle, doc);
}

int bmx_libxml_xmlXIncludeProcessTree(xmlNodePtr handle) {
	return xmlXIncludeProcessTree(handle);
}

int bmx_libxml_xmlXIncludeProcessTreeFlags(xmlNodePtr handle, int flags) {
	return xmlXIncludeProcessTreeFlags(handle, flags);
}

xmlNsPtr bmx_libxml_xmlnode_namespace(xmlNodePtr handle) {
	return handle->ns;
}

xmlAttrPtr bmx_libxml_xmlnode_properties(xmlNodePtr handle) {
	return handle->properties;
}

void bmx_libxml_xmlUnlinkNode(xmlNodePtr handle) {
	xmlUnlinkNode(handle);
}

void bmx_libxml_xmlFreeNode(xmlNodePtr handle) {
	xmlFreeNode(handle);
}

// ****************************************************************************

xmlDocPtr bmx_libxml_xmlReadDoc(BBString * text, BBString * url, BBString * encoding, int options) {
	char * t = bbStringToUTF8String(text);
	char * u = bbStringToUTF8StringOrNull(url);
	char * e = bbStringToUTF8StringOrNull(encoding);
	xmlDocPtr d = xmlReadDoc((xmlChar *)t, u, e, options);
	bbMemFree(e);
	bbMemFree(u);
	bbMemFree(t);
	return d;
}

xmlDocPtr bmx_libxml_xmlNewDoc(BBString * version) {
	char * n = bbStringToUTF8String(version);
	xmlDocPtr d = xmlNewDoc((xmlChar *)n);
	bbMemFree(n);
	return d;
}

xmlDocPtr bmx_libxml_xmlParseFile(BBString * filename) {
	char * n = bbStringToUTF8String(filename);
	xmlDocPtr d = xmlParseFile(n);
	bbMemFree(n);
	return d;
}

xmlDocPtr bmx_libxml_xmlParseMemory(void * buf, int size) {
	return xmlParseMemory((char *)buf, size);
}

xmlDocPtr bmx_libxml_xmlParseDoc(BBString * text) {
	char * n = bbStringToUTF8String(text);
	xmlDocPtr d = xmlParseDoc((xmlChar *)n);
	bbMemFree(n);
	return d;
}

xmlDocPtr bmx_libxml_xmlReadFile(BBString * filename, BBString * encoding, int options) {
	char * n = bbStringToUTF8String(filename);
	char * e = bbStringToUTF8StringOrNull(encoding);
	xmlDocPtr d = xmlReadFile(n, e, options);
	bbMemFree(e);
	bbMemFree(n);
	return d;
}

xmlDocPtr bmx_libxml_xmlParseCatalogFile(BBString * filename) {
	char * n = bbStringToUTF8String(filename);
	xmlDocPtr doc = xmlParseCatalogFile(n);
	bbMemFree(n);
	return doc;
}

BBString * bmx_libxml_xmldoc_url(xmlDocPtr handle) {
	return bbStringFromUTF8String((char *)handle->URL);
}

xmlNodePtr bmx_libxml_xmlDocGetRootElement(xmlDocPtr handle) {
	return xmlDocGetRootElement(handle);
}

xmlNodePtr bmx_libxml_xmlDocSetRootElement(xmlDocPtr handle, xmlNodePtr root) {
	return xmlDocSetRootElement(handle, root);
}

void bmx_libxml_xmlFreeDoc(xmlDocPtr handle) {
	xmlFreeDoc(handle);
}

BBString * bmx_libxml_xmldoc_version(xmlDocPtr handle) {
	return bbStringFromUTF8String((char *)handle->version);
}

BBString * bmx_libxml_xmldoc_encoding(xmlDocPtr handle) {
	return bbStringFromUTF8String((char *)handle->encoding);
}

void bmx_libxml_xmldoc_setencoding(xmlDocPtr handle, BBString * encoding) {
	char * e = bbStringToUTF8String(encoding);

	if (handle->encoding != NULL) {
		xmlFree((xmlChar *)handle->encoding);
	}

	handle->encoding = xmlStrdup((xmlChar *)e);
	bbMemFree(e);
}

int bmx_libxml_xmldoc_standalone(xmlDocPtr handle) {
	return handle->standalone;
}

void bmx_libxml_xmldoc_setStandalone(xmlDocPtr handle, int value) {
	handle->standalone = value;
}

xmlNodePtr bmx_libxml_xmlNewDocPI(xmlDocPtr handle, BBString * name, BBString * content) {
	char * n = bbStringToUTF8String(name);
	char * t = bbStringToUTF8String(content);
	xmlNodePtr node = xmlNewDocPI(handle, (xmlChar *)n, (xmlChar *)t);
	bbMemFree(t);
	bbMemFree(n);
	return node;
}

xmlAttrPtr bmx_libxml_xmlNewDocProp(xmlDocPtr handle, BBString * name, BBString * value) {
	char * n = bbStringToUTF8String(name);
	char * v = bbStringToUTF8String(value);
	xmlAttrPtr att = xmlNewDocProp(handle, (xmlChar *)n, (xmlChar *)v);
	bbMemFree(v);
	bbMemFree(n);
	return att;
}

void bmx_libxml_xmlSetDocCompressMode(xmlDocPtr handle, int mode) {
	xmlSetDocCompressMode(handle, mode);
}

int bmx_libxml_xmlGetDocCompressMode(xmlDocPtr handle) {
	return xmlGetDocCompressMode(handle);
}

int bmx_libxml_xmlSaveFile(BBString * filename, xmlDocPtr handle, BBString * encoding) {
	char * n = bbStringToUTF8String(filename);
	char * e = bbStringToUTF8StringOrNull(encoding);
	int ret;
	if (e) {
		ret = xmlSaveFileEnc(n, handle, e);
	} else {
		ret = xmlSaveFile(n, handle);
	}
	bbMemFree(e);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlSaveFormatFileTo(xmlOutputBufferPtr outputBuffer, xmlDocPtr handle, BBString * encoding, int format) {
	char * e = bbStringToUTF8StringOrNull(encoding);
	int ret = xmlSaveFormatFileTo(outputBuffer, handle, e, format);
	bbMemFree(e);
	return ret;
}

int bmx_libxml_xmlSaveFormatFile(BBString * filename, xmlDocPtr handle, BBString * encoding, int format) {
	char * n = bbStringToUTF8String(filename);
	char * e = bbStringToUTF8StringOrNull(encoding);
	int ret = xmlSaveFormatFileEnc(n, handle, e, format);
	bbMemFree(e);
	bbMemFree(n);
	return ret;
}

xmlXPathContextPtr bmx_libxml_xmlXPathNewContext(xmlDocPtr handle) {
	return xmlXPathNewContext(handle);
}

xmlDtdPtr bmx_libxml_xmlCreateIntSubset(xmlDocPtr handle, BBString * name, BBString * externalID, BBString * systemID) {
	char * n = bbStringToUTF8String(name);
	char * e = bbStringToUTF8String(externalID);
	char * s = bbStringToUTF8String(systemID);
	xmlDtdPtr dtd = xmlCreateIntSubset(handle, (xmlChar *)n, (xmlChar *)e, (xmlChar *)s);
	bbMemFree(n);
	bbMemFree(e);
	bbMemFree(s);
	return dtd;
}

xmlDtdPtr bmx_libxml_xmlGetIntSubset(xmlDocPtr handle) {
	return xmlGetIntSubset(handle);
}

xmlDtdPtr bmx_libxml_xmlNewDtd(xmlDocPtr handle, BBString * name, BBString * externalID, BBString * systemID) {
	char * n = bbStringToUTF8String(name);
	char * e = bbStringToUTF8String(externalID);
	char * s = bbStringToUTF8String(systemID);
	xmlDtdPtr dtd = xmlNewDtd(handle, (xmlChar *)n, (xmlChar *)e, (xmlChar *)s);
	bbMemFree(n);
	bbMemFree(e);
	bbMemFree(s);
	return dtd;
}

void bmx_libxml_xmlXPathOrderDocElems(xmlDocPtr handle, BBInt64 * value) {
	*value = xmlXPathOrderDocElems(handle);
}

xmlDocPtr bmx_libxml_xmlCopyDoc(xmlDocPtr handle, int recursive) {
	return xmlCopyDoc(handle, recursive);
}

xmlEntityPtr bmx_libxml_xmlAddDocEntity(xmlDocPtr handle, BBString * name, int entityType, BBString * externalID, BBString * systemID, BBString * content) {
	char * n = bbStringToUTF8String(name);
	char * t = bbStringToUTF8String(content);
	char * e = bbStringToUTF8StringOrNull(externalID);
	char * s = bbStringToUTF8StringOrNull(systemID);
	xmlEntityPtr entity = xmlAddDocEntity(handle, (xmlChar *)n, entityType, (xmlChar *)e, (xmlChar *)s, (xmlChar *)t);
	bbMemFree(s);
	bbMemFree(e);
	bbMemFree(t);
	bbMemFree(n);
	return entity;
}

xmlEntityPtr bmx_libxml_xmlAddDtdEntity(xmlDocPtr handle, BBString * name, int entityType, BBString * externalID, BBString * systemID, BBString * content) {
	char * n = bbStringToUTF8String(name);
	char * t = bbStringToUTF8String(content);
	char * e = bbStringToUTF8StringOrNull(externalID);
	char * s = bbStringToUTF8StringOrNull(systemID);
	xmlEntityPtr entity = xmlAddDtdEntity(handle, (xmlChar *)n, entityType, (xmlChar *)e, (xmlChar *)s, (xmlChar *)t);
	bbMemFree(s);
	bbMemFree(e);
	bbMemFree(t);
	bbMemFree(n);
	return entity;
}

BBString * bmx_libxml_xmlEncodeEntitiesReentrant(xmlDocPtr handle, BBString * inp) {
	char * n = bbStringToUTF8String(inp);
	BBString * s = bbStringFromXmlChar(xmlEncodeEntitiesReentrant(handle, (xmlChar *)n));
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlEncodeSpecialChars(xmlDocPtr handle, BBString * inp) {
	char * n = bbStringToUTF8String(inp);
	BBString * s = bbStringFromXmlChar(xmlEncodeSpecialChars(handle, (xmlChar *)n));
	bbMemFree(n);
	return s;
}

xmlEntityPtr bmx_libxml_xmlGetDocEntity(xmlDocPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	xmlEntityPtr entity = xmlGetDocEntity(handle, (xmlChar *)n);
	bbMemFree(n);
	return entity;
}

xmlEntityPtr bmx_libxml_xmlGetDtdEntity(xmlDocPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	xmlEntityPtr entity = xmlGetDtdEntity(handle, (xmlChar *)n);
	bbMemFree(n);
	return entity;
}

xmlEntityPtr bmx_libxml_xmlGetParameterEntity(xmlDocPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	xmlEntityPtr entity = xmlGetParameterEntity(handle, (xmlChar *)n);
	bbMemFree(n);
	return entity;
}

int bmx_libxml_xmlXIncludeProcess(xmlDocPtr handle) {
	return xmlXIncludeProcess(handle);
}

int bmx_libxml_xmlXIncludeProcessFlags(xmlDocPtr handle, int flags) {
	return xmlXIncludeProcessFlags(handle, flags);
}

xmlAttrPtr bmx_libxml_xmlGetID(xmlDocPtr handle, BBString * id) {
	char * n = bbStringToUTF8String(id);
	xmlAttrPtr attr = xmlGetID(handle, (xmlChar *)n);
	bbMemFree(n);
	return attr;
}

int bmx_libxml_xmlIsID(xmlDocPtr handle, xmlNodePtr node, xmlAttrPtr attr) {
	return xmlIsID(handle, node, attr);
}

int bmx_libxml_xmlIsRef(xmlDocPtr handle, xmlNodePtr node, xmlAttrPtr attr) {
	return xmlIsRef(handle, node, attr);
}

int bmx_libxml_xmlIsMixedElement(xmlDocPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	int ret = xmlIsMixedElement(handle, (xmlChar *)n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlRemoveID(xmlDocPtr handle, xmlAttrPtr attr) {
	return xmlRemoveID(handle, attr);
}

int bmx_libxml_xmlRemoveRef(xmlDocPtr handle, xmlAttrPtr attr) {
	return xmlRemoveRef(handle, attr);
}

xmlElementContentPtr bmx_libxml_xmlNewDocElementContent(xmlDocPtr handle, BBString * name, int contentType) {
	char * n = bbStringToUTF8String(name);
	xmlElementContentPtr content = xmlNewDocElementContent(handle, (xmlChar *)n, static_cast<xmlElementContentType>(contentType));
	bbMemFree(n);
	return content;
}

void bmx_libxml_xmlFreeDocElementContent(xmlDocPtr handle, xmlElementContentPtr content) {
	xmlFreeDocElementContent(handle, content);
}

BBString * bmx_libxml_xmlValidCtxtNormalizeAttributeValue(xmlValidCtxtPtr context, xmlDocPtr handle, xmlNodePtr elem, BBString * name, BBString * value) {
	char * n = bbStringToUTF8String(name);
	char * v = bbStringToUTF8String(value);
	BBString * s = bbStringFromXmlChar(xmlValidCtxtNormalizeAttributeValue(context, handle, elem, (xmlChar *)n, (xmlChar *)v));
	bbMemFree(v);
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlValidNormalizeAttributeValue(xmlDocPtr handle, xmlNodePtr elem, BBString * name, BBString * value) {
	char * n = bbStringToUTF8String(name);
	char * v = bbStringToUTF8String(value);
	BBString * s = bbStringFromXmlChar(xmlValidNormalizeAttributeValue(handle, elem, (xmlChar *)n, (xmlChar *)v));
	bbMemFree(v);
	bbMemFree(n);
	return s;
}

// ****************************************************************************

int bmx_libxml_xmlns_type(xmlNsPtr handle) {
	return handle->type;
}

BBString * bmx_libxml_xmlns_href(xmlNsPtr handle) {
	return bbStringFromUTF8String((char*)handle->href);
}

BBString * bmx_libxml_xmlns_prefix(xmlNsPtr handle) {
	return bbStringFromUTF8String((char*)handle->prefix);
}

void bmx_libxml_xmlFreeNs(xmlNsPtr handle) {
	xmlFreeNs(handle);
}

// ****************************************************************************

int bmx_libxml_xmlattr_atype(xmlAttrPtr handle) {
	return handle->atype;
}

xmlNsPtr bmx_libxml_xmlattr_ns(xmlAttrPtr handle) {
	return handle->ns;
}

// ****************************************************************************

xmlXPathCompExprPtr bmx_libxml_xmlXPathCompile(BBString * expr) {
	char * n = bbStringToUTF8String(expr);
	xmlXPathCompExprPtr xp = xmlXPathCompile((xmlChar *)n);
	bbMemFree(n);
	return xp;
}

xmlXPathObjectPtr bmx_libxml_xmlXPathCompiledEval(xmlXPathCompExprPtr handle, xmlXPathContextPtr context) {
	return xmlXPathCompiledEval(handle, context);
}

void bmx_libxml_xmlXPathFreeCompExpr(xmlXPathCompExprPtr handle) {
	xmlXPathFreeCompExpr(handle);
}

// ****************************************************************************

int bmx_libxml_xmlelementcontent_type(xmlElementContentPtr handle) {
	return handle->type;
}

int bmx_libxml_xmlelementcontent_ocur(xmlElementContentPtr handle) {
	return handle->ocur;
}

BBString * bmx_libxml_xmlelementcontent_name(xmlElementContentPtr handle) {
	return bbStringFromUTF8String((char *)handle->name);
}

BBString * bmx_libxml_xmlelementcontent_prefix(xmlElementContentPtr handle) {
	return bbStringFromUTF8String((char *)handle->prefix);
}

// ****************************************************************************

int bmx_libxml_xmlValidateAttributeValue(int attributeType, BBString * value) {
	char * n = bbStringToUTF8String(value);
	int ret = xmlValidateAttributeValue(static_cast<xmlAttributeType>(attributeType), (xmlChar *)n);
	bbMemFree(n);
	return ret;
}

xmlValidCtxtPtr bmx_libxml_xmlNewValidCtxt() {
	return xmlNewValidCtxt();
}

int bmx_libxml_xmlValidateNameValue(BBString * value) {
	char * n = bbStringToUTF8String(value);
	int ret = xmlValidateNameValue((xmlChar *)n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlValidateNamesValue(BBString * value) {
	char * n = bbStringToUTF8String(value);
	int ret = xmlValidateNamesValue((xmlChar *)n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlValidateNmtokenValue(BBString * value) {
	char * n = bbStringToUTF8String(value);
	int ret = xmlValidateNmtokenValue((xmlChar *)n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlValidateNmtokensValue(BBString * value) {
	char * n = bbStringToUTF8String(value);
	int ret = xmlValidateNmtokensValue((xmlChar *)n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlvalidctxt_valid(xmlValidCtxtPtr handle) {
	return handle->valid;
}

int bmx_libxml_xmlvalidctxt_finishDtd(xmlValidCtxtPtr handle) {
	return handle->finishDtd;
}

xmlDocPtr bmx_libxml_xmlvalidctxt_doc(xmlValidCtxtPtr handle) {
	return handle->doc;
}

int bmx_libxml_xmlValidateDocument(xmlValidCtxtPtr handle, xmlDocPtr doc) {
	return xmlValidateDocument(handle, doc);
}

int bmx_libxml_xmlValidateDocumentFinal(xmlValidCtxtPtr handle, xmlDocPtr doc) {
	return xmlValidateDocumentFinal(handle, doc);
}

int bmx_libxml_xmlValidateDtd(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlDtdPtr dtd) {
	return xmlValidateDtd(handle, doc, dtd);
}

int bmx_libxml_xmlValidateDtdFinal(xmlValidCtxtPtr handle, xmlDocPtr doc) {
	return xmlValidateDtdFinal(handle, doc);
}

int bmx_libxml_xmlValidateRoot(xmlValidCtxtPtr handle, xmlDocPtr doc) {
	return xmlValidateRoot(handle, doc);
}

int bmx_libxml_xmlValidateElement(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlNodePtr elem) {
	return xmlValidateElement(handle, doc, elem);
}

int bmx_libxml_xmlValidateElementDecl(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlElementPtr elem) {
	return xmlValidateElementDecl(handle, doc, elem);
}

int bmx_libxml_xmlValidateAttributeDecl(xmlValidCtxtPtr handle, xmlDocPtr doc, xmlAttributePtr attr) {
	return xmlValidateAttributeDecl(handle, doc, attr);
}

int bmx_libxml_xmlValidBuildContentModel(xmlValidCtxtPtr handle, xmlElementPtr elem) {
	return xmlValidBuildContentModel(handle, elem);
}

void bmx_libxml_xmlFreeValidCtxt(xmlValidCtxtPtr handle) {
	xmlFreeValidCtxt(handle);
}

// ****************************************************************************

xmlXPathContextPtr bmx_libxml_xmlXPtrNewContext(xmlDocPtr doc, xmlNodePtr here, xmlNodePtr origin) {
	return xmlXPtrNewContext(doc, here, origin);
}

xmlXPathObjectPtr bmx_libxml_xmlXPathEvalExpression(BBString * text, xmlXPathContextPtr handle) {
	char * n = bbStringToUTF8String(text);
	xmlXPathObjectPtr obj = xmlXPathEvalExpression((xmlChar *)n, handle);
	bbMemFree(n);
	return obj;
}

xmlXPathObjectPtr bmx_libxml_xmlXPathEval(BBString * text, xmlXPathContextPtr handle) {
	char * n = bbStringToUTF8String(text);
	xmlXPathObjectPtr obj = xmlXPathEval((xmlChar *)n, handle);
	bbMemFree(n);
	return obj;
}

xmlDocPtr bmx_libxml_xmlxpathcontext_doc(xmlXPathContextPtr handle) {
	return handle->doc;
}

xmlNodePtr bmx_libxml_xmlxpathcontext_node(xmlXPathContextPtr handle) {
	return handle->node;
}

int bmx_libxml_xmlXPathRegisterNs(xmlXPathContextPtr handle, BBString * prefix, BBString * uri) {
	char * p = bbStringToUTF8StringOrNull(prefix);
	char * u = bbStringToUTF8StringOrNull(uri);
	int ret = xmlXPathRegisterNs(handle, (xmlChar *)p, (xmlChar *)u);
	bbMemFree(p);
	bbMemFree(u);
	return ret;
}

int bmx_libxml_xmlXPathEvalPredicate(xmlXPathContextPtr handle, xmlXPathObjectPtr res) {
	return xmlXPathEvalPredicate(handle, res);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrEval(BBString * expr, xmlXPathContextPtr handle) {
	char * n = bbStringToUTF8String(expr);
	xmlXPathObjectPtr obj = xmlXPathEval((xmlChar *)n, handle);
	bbMemFree(n);
	return obj;
}

int bmx_libxml_xmlxpathcontext_nb_types(xmlXPathContextPtr handle) {
	return handle->nb_types;
}

int bmx_libxml_xmlxpathcontext_max_types(xmlXPathContextPtr handle) {
	return handle->max_types;
}

int bmx_libxml_xmlxpathcontext_contextSize(xmlXPathContextPtr handle) {
	return handle->contextSize;
}

int bmx_libxml_xmlxpathcontext_proximityPosition(xmlXPathContextPtr handle) {
	return handle->proximityPosition;
}

int bmx_libxml_xmlxpathcontext_xptr(xmlXPathContextPtr handle) {
	return handle->xptr;
}

xmlNodePtr bmx_libxml_xmlxpathcontext_here(xmlXPathContextPtr handle) {
	return handle->here;
}

xmlNodePtr bmx_libxml_xmlxpathcontext_origin(xmlXPathContextPtr handle) {
	return handle->origin;
}

BBString * bmx_libxml_xmlxpathcontext_function(xmlXPathContextPtr handle) {
	return bbStringFromUTF8String((char *)handle->function);
}

BBString * bmx_libxml_xmlxpathcontext_functionURI(xmlXPathContextPtr handle) {
	return bbStringFromUTF8String((char *)handle->functionURI);
}

void bmx_libxml_xmlXPathFreeContext(xmlXPathContextPtr handle) {
	xmlXPathFreeContext(handle);
}

// ****************************************************************************

BBString * bmx_libxml_xmldtd_externalID(xmlDtdPtr handle) {
	return bbStringFromUTF8String((char *)handle->ExternalID);
}

BBString * bmx_libxml_xmldtd_systemID(xmlDtdPtr handle) {
	return bbStringFromUTF8String((char *)handle->SystemID);
}

xmlDtdPtr bmx_libxml_xmlCopyDtd(xmlDtdPtr handle) {
	return xmlCopyDtd(handle);
}

xmlAttributePtr bmx_libxml_xmlGetDtdAttrDesc(xmlDtdPtr handle, BBString * elem, BBString * name) {
	char * e = bbStringToUTF8String(elem);
	char * n = bbStringToUTF8String(name);
	xmlAttributePtr attr = xmlGetDtdAttrDesc(handle, (xmlChar *)e, (xmlChar *)n);
	bbMemFree(n);
	bbMemFree(e);
	return attr;
}

xmlElementPtr bmx_libxml_xmlGetDtdElementDesc(xmlDtdPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	xmlElementPtr elem = xmlGetDtdElementDesc(handle, (xmlChar *)n);
	bbMemFree(n);
	return elem;
}

xmlNotationPtr bmx_libxml_xmlGetDtdNotationDesc(xmlDtdPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	xmlNotationPtr notation = xmlGetDtdNotationDesc(handle, (xmlChar *)n);
	bbMemFree(n);
	return notation;
}

xmlAttributePtr bmx_libxml_xmlGetDtdQAttrDesc(xmlDtdPtr handle, BBString * elem, BBString * name, BBString * prefix) {
	char * e = bbStringToUTF8String(elem);
	char * n = bbStringToUTF8String(name);
	char * p = bbStringToUTF8String(prefix);
	xmlAttributePtr attr = xmlGetDtdQAttrDesc(handle, (xmlChar *)e, (xmlChar *)n, (xmlChar *)p);
	bbMemFree(p);
	bbMemFree(n);
	bbMemFree(e);
	return attr;
}

xmlElementPtr bmx_libxml_xmlGetDtdQElementDesc(xmlDtdPtr handle, BBString * name, BBString * prefix) {
	char * n = bbStringToUTF8String(name);
	char * p = bbStringToUTF8String(prefix);
	xmlElementPtr elem = xmlGetDtdQElementDesc(handle, (xmlChar *)n, (xmlChar *)p);
	bbMemFree(p);
	bbMemFree(n);
	return elem;
}

void bmx_libxml_xmlFreeDtd(xmlDtdPtr handle) {
	xmlFreeDtd(handle);
}

// ****************************************************************************

xmlErrorPtr bmx_libxml_xmlGetLastError() {
	return xmlGetLastError();
}

int bmx_libxml_xmlerror_domain(xmlErrorPtr handle) {
	return handle->domain;
}

int bmx_libxml_xmlerror_code(xmlErrorPtr handle) {
	return handle->code;
}

BBString * bmx_libxml_xmlerror_message(xmlErrorPtr handle) {
	return bbStringFromUTF8String(handle->message);
}

int bmx_libxml_xmlerror_level(xmlErrorPtr handle) {
	return handle->level;
}

BBString * bmx_libxml_xmlerror_file(xmlErrorPtr handle) {
	return bbStringFromUTF8String(handle->file);
}

int bmx_libxml_xmlerror_line(xmlErrorPtr handle) {
	return handle->line;
}

BBString * bmx_libxml_xmlerror_str1(xmlErrorPtr handle) {
	return bbStringFromUTF8String(handle->str1);
}

BBString * bmx_libxml_xmlerror_str2(xmlErrorPtr handle) {
	return bbStringFromUTF8String(handle->str2);
}

BBString * bmx_libxml_xmlerror_str3(xmlErrorPtr handle) {
	return bbStringFromUTF8String(handle->str3);
}

int bmx_libxml_xmlerror_int2(xmlErrorPtr handle) {
	return handle->int2;
}

xmlNodePtr bmx_libxml_xmlerror_node(xmlErrorPtr handle) {
	return (xmlNodePtr)handle->node;
}

// ****************************************************************************

xmlEntityPtr bmx_libxml_xmlGetPredefinedEntity(BBString * name) {
	char * n = bbStringToUTF8String(name);
	xmlEntityPtr entity = xmlGetPredefinedEntity((xmlChar *)n);
	bbMemFree(n);
	return entity;
}

int bmx_libxml_xmlSubstituteEntitiesDefault(int value) {
	return xmlSubstituteEntitiesDefault(value);
}

// ****************************************************************************

xmlBufferPtr bmx_libxml_xmlBufferCreate() {
	return xmlBufferCreate();
}

xmlBufferPtr bmx_libxml_xmlBufferCreateStatic(void * mem, int size) {
	return xmlBufferCreateStatic(mem, size);
}

BBString * bmx_libxml_xmlbuffer_content(xmlBufferPtr handle) {
	return bbStringFromUTF8String((char*)handle->content);
}

void bmx_libxml_xmlBufferFree(xmlBufferPtr handle) {
	xmlBufferFree(handle);
}

// ****************************************************************************

int bmx_libxml_xmlnodeset_nodeNr(xmlNodeSetPtr handle) {
	return handle->nodeNr;
}

xmlNodePtr bmx_libxml_xmlnodeset_nodetab(xmlNodeSetPtr handle, int index) {
	return handle->nodeTab[index];
}

int bmx_libxml_xmlXPathCastNodeSetToBoolean(xmlNodeSetPtr handle) {
	return xmlXPathCastNodeSetToBoolean(handle);
}

double bmx_libxml_xmlXPathCastNodeSetToNumber(xmlNodeSetPtr handle) {
	return xmlXPathCastNodeSetToNumber(handle);
}

BBString * bmx_libxml_xmlXPathCastNodeSetToString(xmlNodeSetPtr handle) {
	return bbStringFromXmlChar(xmlXPathCastNodeSetToString(handle));
}

void bmx_libxml_xmlXPathFreeNodeSet(xmlNodeSetPtr handle) {
	xmlXPathFreeNodeSet(handle);
}

// ****************************************************************************

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewCollapsedRange(xmlNodePtr node) {
	return xmlXPtrNewCollapsedRange(node);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewLocationSetNodeSet(xmlNodeSetPtr set) {
	return xmlXPtrNewLocationSetNodeSet(set);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewLocationSetNodes(xmlNodePtr start, xmlNodePtr end) {
	return xmlXPtrNewLocationSetNodes(start, end);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRange(xmlNodePtr start, int startindex, xmlNodePtr end, int endindex) {
	return xmlXPtrNewRange(start, startindex, end, endindex);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangeNodeObject(xmlNodePtr start, xmlXPathObjectPtr end) {
	return xmlXPtrNewRangeNodeObject(start, end);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangeNodePoint(xmlNodePtr start, xmlXPathObjectPtr end) {
	return xmlXPtrNewRangeNodePoint(start, end);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangeNodes(xmlNodePtr start, xmlNodePtr end) {
	return xmlXPtrNewRangeNodes(start, end);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangePointNode(xmlXPathObjectPtr start, xmlNodePtr end) {
	return xmlXPtrNewRangePointNode(start, end);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrNewRangePoints(xmlXPathObjectPtr start, xmlXPathObjectPtr end) {
	return xmlXPtrNewRangePoints(start, end);
}

xmlXPathObjectPtr bmx_libxml_xmlXPtrWrapLocationSet(xmlLocationSetPtr val) {
	return xmlXPtrWrapLocationSet(val);
}

int bmx_libxml_xmlxpathobject_type(xmlXPathObjectPtr handle) {
	return handle->type;
}

xmlNodeSetPtr bmx_libxml_xmlxpathobject_nodesetval(xmlXPathObjectPtr handle) {
	return handle->nodesetval;
}

BBString * bmx_libxml_xmlxpathobject_stringval(xmlXPathObjectPtr handle) {
	return bbStringFromUTF8String((char *)handle->stringval);
}

int bmx_libxml_xmlXPathCastToBoolean(xmlXPathObjectPtr handle) {
	return xmlXPathCastToBoolean(handle);
}

double bmx_libxml_xmlXPathCastToNumber(xmlXPathObjectPtr handle) {
	return xmlXPathCastToNumber(handle);
}

BBString * bmx_libxml_xmlXPathCastToString(xmlXPathObjectPtr handle) {
	return bbStringFromXmlChar(xmlXPathCastToString(handle));
}

xmlXPathObjectPtr bmx_libxml_xmlXPathConvertBoolean(xmlXPathObjectPtr handle) {
	return xmlXPathConvertBoolean(handle);
}

xmlXPathObjectPtr bmx_libxml_xmlXPathConvertNumber(xmlXPathObjectPtr handle) {
	return xmlXPathConvertNumber(handle);
}

xmlXPathObjectPtr bmx_libxml_xmlXPathConvertString(xmlXPathObjectPtr handle) {
	return xmlXPathConvertString(handle);
}

xmlXPathObjectPtr bmx_libxml_xmlXPathObjectCopy(xmlXPathObjectPtr handle) {
	return xmlXPathObjectCopy(handle);
}

xmlNodePtr bmx_libxml_xmlXPtrBuildNodeList(xmlXPathObjectPtr handle) {
	return xmlXPtrBuildNodeList(handle);
}

xmlLocationSetPtr bmx_libxml_xmlXPtrLocationSetCreate(xmlXPathObjectPtr handle) {
	return xmlXPtrLocationSetCreate(handle);
}

void bmx_libxml_xmlXPathFreeObject(xmlXPathObjectPtr handle) {
	xmlXPathFreeObject(handle);
}

// ****************************************************************************

xmlXIncludeCtxtPtr bmx_libxml_xmlXIncludeNewContext(xmlDocPtr doc) {
	return xmlXIncludeNewContext(doc);
}

int bmx_libxml_xmlXIncludeProcessNode(xmlXIncludeCtxtPtr handle, xmlNodePtr node) {
	return xmlXIncludeProcessNode(handle, node);
}

int bmx_libxml_xmlXIncludeSetFlags(xmlXIncludeCtxtPtr handle, int flags) {
	return xmlXIncludeSetFlags(handle, flags);
}

void bmx_libxml_xmlXIncludeFreeContext(xmlXIncludeCtxtPtr handle) {
	xmlXIncludeFreeContext(handle);
}

// ****************************************************************************

xmlURIPtr bmx_libxml_xmlCreateURI() {
	return xmlCreateURI();
}

xmlURIPtr bmx_libxml_xmlParseURI(BBString * uri) {
	char * n = bbStringToUTF8String(uri);
	xmlURIPtr u = xmlParseURI(n);
	bbMemFree(n);
	return u;
}

xmlURIPtr bmx_libxml_xmlParseURIRaw(BBString * uri, int raw) {
	char * n = bbStringToUTF8String(uri);
	xmlURIPtr u = xmlParseURIRaw(n, raw);
	bbMemFree(n);
	return u;
}

BBString * bmx_libxml_xmlBuildURI(BBString * uri, BBString * base) {
	char * n = bbStringToUTF8String(uri);
	char * b = bbStringToUTF8String(base);
	BBString * s = bbStringFromXmlChar(xmlBuildURI((xmlChar *)n, (xmlChar *)b));
	bbMemFree(b);
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlCanonicPath(BBString * path) {
	char * n = bbStringToUTF8String(path);
	BBString * s = bbStringFromXmlChar(xmlCanonicPath((xmlChar *)n));
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlNormalizeURIPath(BBString * path) {
	char * n = bbStringToUTF8String(path);
	int ret = xmlNormalizeURIPath(n);
	BBString * s = bbStringFromUTF8String(n);
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlURIEscape(BBString * uri) {
	char * n = bbStringToUTF8String(uri);
	BBString * s = bbStringFromXmlChar(xmlURIEscape((xmlChar *)n));
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlURIEscapeStr(BBString * uri, BBString * list) {
	char * n = bbStringToUTF8String(uri);
	char * l = bbStringToUTF8String(list);
	BBString * s = bbStringFromXmlChar(xmlURIEscapeStr((xmlChar *)n, (xmlChar *)l));
	bbMemFree(l);
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlURIUnescapeString(BBString * text) {
	char * n = bbStringToUTF8String(text);
	BBString * s = bbStringFromXmlChar((xmlChar*)xmlURIUnescapeString(n, 0, 0));
	bbMemFree(n);
	return s;
}

int bmx_libxml_xmlParseURIReference(xmlURIPtr handle, BBString * uri) {
	char * n = bbStringToUTF8String(uri);
	int ret = xmlParseURIReference(handle, n);
	bbMemFree(n);
	return ret;
}

BBString * bmx_libxml_xmlSaveUri(xmlURIPtr handle) {
	return bbStringFromXmlChar(xmlSaveUri(handle));
}

BBString * bmx_libxml_xmluri_scheme(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->scheme);
}

BBString * bmx_libxml_xmluri_opaque(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->opaque);
}

BBString * bmx_libxml_xmluri_authority(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->authority);
}

BBString * bmx_libxml_xmluri_server(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->server);
}

BBString * bmx_libxml_xmluri_user(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->user);
}

int bmx_libxml_xmluri_port(xmlURIPtr handle) {
	return handle->port;
}

BBString * bmx_libxml_xmluri_path(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->path);
}

BBString * bmx_libxml_xmluri_query(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->query);
}

BBString * bmx_libxml_xmluri_fragment(xmlURIPtr handle) {
	return bbStringFromUTF8String(handle->fragment);
}

void bmx_libxml_xmlFreeURI(xmlURIPtr handle) {
	xmlFreeURI(handle);
}

// ****************************************************************************

xmlTextReaderPtr bmx_libxml_xmlNewTextReaderFilename(BBString * filename) {
	char * n = bbStringToUTF8String(filename);
	xmlTextReaderPtr t = xmlNewTextReaderFilename(n);
	bbMemFree(n);
	return t;
}

xmlTextReaderPtr bmx_libxml_xmlReaderForFile(BBString * filename, BBString * encoding, int options) {
	char * n = bbStringToUTF8String(filename);
	char * e = bbStringToUTF8StringOrNull(encoding);
	xmlTextReaderPtr t = xmlReaderForFile(n, e, options);
	bbMemFree(e);
	bbMemFree(n);
	return t;
}

xmlTextReaderPtr bmx_libxml_xmlReaderForMemory(void * buf, int size, BBString * url, BBString * encoding, int options) {
	char * u = bbStringToUTF8StringOrNull(url);
	char * e = bbStringToUTF8StringOrNull(encoding);
	xmlTextReaderPtr t = xmlReaderForMemory((char *)buf, size, u, e, options);
	bbMemFree(e);
	bbMemFree(u);
	return t;
}

xmlTextReaderPtr bmx_libxml_xmlReaderForDoc(char * docTextPtr, BBString * url, BBString * encoding, int options) {
	char * u = bbStringToUTF8StringOrNull(url);
	char * e = bbStringToUTF8StringOrNull(encoding);
	xmlTextReaderPtr t = xmlReaderForDoc((xmlChar *)docTextPtr, u, e, options);
	bbMemFree(e);
	bbMemFree(u);
	return t;
}

int bmx_libxml_xmlTextReaderAttributeCount(xmlTextReaderPtr handle) {
	return xmlTextReaderAttributeCount(handle);
}

BBString * bmx_libxml_xmlTextReaderBaseUri(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderBaseUri(handle));
}

xmlDocPtr bmx_libxml_xmlTextReaderCurrentDoc(xmlTextReaderPtr handle) {
	return xmlTextReaderCurrentDoc(handle);
}

void bmx_libxml_xmlFreeTextReader(xmlTextReaderPtr handle) {
	xmlFreeTextReader(handle);
}

int bmx_libxml_xmlTextReaderRead(xmlTextReaderPtr handle) {
	return xmlTextReaderRead(handle);
}

int bmx_libxml_xmlTextReaderReadAttributeValue(xmlTextReaderPtr handle) {
	return xmlTextReaderReadAttributeValue(handle);
}

BBString * bmx_libxml_xmlTextReaderReadInnerXml(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderReadInnerXml(handle));
}

BBString * bmx_libxml_xmlTextReaderReadOuterXml(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderReadOuterXml(handle));
}

int bmx_libxml_xmlTextReaderReadState(xmlTextReaderPtr handle) {
	return xmlTextReaderReadState(handle);
}

BBString * bmx_libxml_xmlTextReaderReadString(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderReadString(handle));
}

BBString * bmx_libxml_xmlTextReaderConstName(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstName(handle));
}

BBString * bmx_libxml_xmlTextReaderConstLocalName(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstLocalName(handle));
}

BBString * bmx_libxml_xmlTextReaderConstEncoding(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstEncoding(handle));
}

BBString * bmx_libxml_xmlTextReaderConstBaseUri(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstBaseUri(handle));
}

BBString * bmx_libxml_xmlTextReaderConstNamespaceUri(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstNamespaceUri(handle));
}

BBString * bmx_libxml_xmlTextReaderConstPrefix(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstPrefix(handle));
}

BBString * bmx_libxml_xmlTextReaderConstValue(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstValue(handle));
}

BBString * bmx_libxml_xmlTextReaderConstXmlLang(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstXmlLang(handle));
}

BBString * bmx_libxml_xmlTextReaderConstXmlVersion(xmlTextReaderPtr handle) {
	return bbStringFromUTF8String((char * )xmlTextReaderConstXmlVersion(handle));
}

int bmx_libxml_xmlTextReaderDepth(xmlTextReaderPtr handle) {
	return xmlTextReaderDepth(handle);
}

xmlNodePtr bmx_libxml_xmlTextReaderExpand(xmlTextReaderPtr handle) {
	return xmlTextReaderExpand(handle);
}

BBString * bmx_libxml_xmlTextReaderGetAttribute(xmlTextReaderPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	BBString * s = bbStringFromXmlChar(xmlTextReaderGetAttribute(handle, (xmlChar *)n));
	bbMemFree(n);
	return s;
}

BBString * bmx_libxml_xmlTextReaderGetAttributeNo(xmlTextReaderPtr handle, int index) {
	return bbStringFromXmlChar(xmlTextReaderGetAttributeNo(handle, index));
}

BBString * bmx_libxml_xmlTextReaderGetAttributeNs(xmlTextReaderPtr handle, BBString * localName, BBString * namespaceURI) {
	char * n = bbStringToUTF8String(localName);
	char * u = bbStringToUTF8String(namespaceURI);
	BBString * s = bbStringFromXmlChar(xmlTextReaderGetAttributeNs(handle, (xmlChar *)n, (xmlChar *)u));
	bbMemFree(u);
	bbMemFree(n);
	return s;
}

int bmx_libxml_xmlTextReaderGetParserColumnNumber(xmlTextReaderPtr handle) {
	return xmlTextReaderGetParserColumnNumber(handle);
}

int bmx_libxml_xmlTextReaderGetParserLineNumber(xmlTextReaderPtr handle) {
	return xmlTextReaderGetParserLineNumber(handle);
}

int bmx_libxml_xmlTextReaderGetParserProp(xmlTextReaderPtr handle, int prop) {
	return xmlTextReaderGetParserProp(handle, prop);
}

int bmx_libxml_xmlTextReaderHasAttributes(xmlTextReaderPtr handle) {
	return xmlTextReaderHasAttributes(handle);
}

int bmx_libxml_xmlTextReaderHasValue(xmlTextReaderPtr handle) {
	return xmlTextReaderHasValue(handle);
}

int bmx_libxml_xmlTextReaderIsDefault(xmlTextReaderPtr handle) {
	return xmlTextReaderIsDefault(handle);
}

int bmx_libxml_xmlTextReaderIsEmptyElement(xmlTextReaderPtr handle) {
	return xmlTextReaderIsEmptyElement(handle);
}

int bmx_libxml_xmlTextReaderIsNamespaceDecl(xmlTextReaderPtr handle) {
	return xmlTextReaderIsNamespaceDecl(handle);
}

int bmx_libxml_xmlTextReaderIsValid(xmlTextReaderPtr handle) {
	return xmlTextReaderIsValid(handle);
}

BBString * bmx_libxml_xmlTextReaderLocalName(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderLocalName(handle));
}

BBString * bmx_libxml_xmlTextReaderLookupNamespace(xmlTextReaderPtr handle, BBString * prefix) {
	char * n = bbStringToUTF8StringOrNull(prefix);
	BBString * s = bbStringFromXmlChar(xmlTextReaderLookupNamespace(handle, (xmlChar *)n));
	bbMemFree(n);
	return s;
}

int bmx_libxml_xmlTextReaderMoveToAttribute(xmlTextReaderPtr handle, BBString * name) {
	char * n = bbStringToUTF8String(name);
	int ret = xmlTextReaderMoveToAttribute(handle, (xmlChar *)n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlTextReaderMoveToAttributeNo(xmlTextReaderPtr handle, int index) {
	return xmlTextReaderMoveToAttributeNo(handle, index);
}

int bmx_libxml_xmlTextReaderMoveToAttributeNs(xmlTextReaderPtr handle, BBString * localName, BBString * namespaceURI) {
	char * n = bbStringToUTF8String(localName);
	char * u = bbStringToUTF8String(namespaceURI);
	int ret = xmlTextReaderMoveToAttributeNs(handle, (xmlChar *)n, (xmlChar *)u);
	bbMemFree(u);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlTextReaderMoveToElement(xmlTextReaderPtr handle) {
	return xmlTextReaderMoveToElement(handle);
}

int bmx_libxml_xmlTextReaderMoveToFirstAttribute(xmlTextReaderPtr handle) {
	return xmlTextReaderMoveToFirstAttribute(handle);
}

int bmx_libxml_xmlTextReaderMoveToNextAttribute(xmlTextReaderPtr handle) {
	return xmlTextReaderMoveToNextAttribute(handle);
}

BBString * bmx_libxml_xmlTextReaderName(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderName(handle));
}

BBString * bmx_libxml_xmlTextReaderNamespaceUri(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderNamespaceUri(handle));
}

int bmx_libxml_xmlTextReaderNext(xmlTextReaderPtr handle) {
	return xmlTextReaderNext(handle);
}

int bmx_libxml_xmlTextReaderNodeType(xmlTextReaderPtr handle) {
	return xmlTextReaderNodeType(handle);
}

int bmx_libxml_xmlTextReaderNormalization(xmlTextReaderPtr handle) {
	return xmlTextReaderNormalization(handle);
}

BBString * bmx_libxml_xmlTextReaderPrefix(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderPrefix(handle));
}

xmlNodePtr bmx_libxml_xmlTextReaderPreserve(xmlTextReaderPtr handle) {
	return xmlTextReaderPreserve(handle);
}

int bmx_libxml_xmlTextReaderQuoteChar(xmlTextReaderPtr handle) {
	return xmlTextReaderQuoteChar(handle);
}

int bmx_libxml_xmlTextReaderRelaxNGValidate(xmlTextReaderPtr handle, BBString * rng) {
	char * n = bbStringToUTF8StringOrNull(rng);
	int ret = xmlTextReaderRelaxNGValidate(handle, n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlTextReaderSchemaValidate(xmlTextReaderPtr handle, BBString * xsd) {
	char * n = bbStringToUTF8StringOrNull(xsd);
	int ret = xmlTextReaderSchemaValidate(handle, n);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlTextReaderSetParserProp(xmlTextReaderPtr handle, int prop, int value) {
	return xmlTextReaderSetParserProp(handle, prop, value);
}

int bmx_libxml_xmlTextReaderStandalone(xmlTextReaderPtr handle) {
	return xmlTextReaderStandalone(handle);
}

BBString * bmx_libxml_xmlTextReaderValue(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderValue(handle));
}

BBString * bmx_libxml_xmlTextReaderXmlLang(xmlTextReaderPtr handle) {
	return bbStringFromXmlChar(xmlTextReaderXmlLang(handle));
}

// ****************************************************************************

xmlCatalogPtr bmx_libxml_xmlNewCatalog(int sgml) {
	return xmlNewCatalog(sgml);
}

xmlCatalogPtr bmx_libxml_xmlLoadACatalog(BBString * filename) {
	char * n = bbStringToUTF8String(filename);
	xmlCatalogPtr c = xmlLoadACatalog(n);
	bbMemFree(n);
	return c;
}

int bm_libxml_xmlLoadCatalog(BBString * filename) {
	char * n = bbStringToUTF8String(filename);
	int ret = xmlLoadCatalog(n);
	bbMemFree(n);
	return ret;
}

xmlCatalogPtr bmx_libxml_xmlLoadSGMLSuperCatalog(BBString * filename) {
	char * n = bbStringToUTF8String(filename);
	xmlCatalogPtr c = xmlLoadSGMLSuperCatalog(n);
	bbMemFree(n);
	return c;
}

void bmx_libxml_xmlCatalogSetDefaults(int allow) {
	xmlCatalogSetDefaults(static_cast<xmlCatalogAllow>(allow));
}

int bmx_libxml_xmlCatalogGetDefaults() {
	return xmlCatalogGetDefaults();
}

int bmx_libxml_xmlCatalogSetDebug(int level) {
	return xmlCatalogSetDebug(level);
}

int bmx_libxml_xmlCatalogSetDefaultPrefer(int prefer) {
	return xmlCatalogSetDefaultPrefer(static_cast<xmlCatalogPrefer>(prefer));
}

int bmx_libxml_xmlCatalogAdd(BBString * rtype, BBString * orig, BBString * rep) {
	char * n = bbStringToUTF8String(rtype);
	char * o = bbStringToUTF8String(orig);
	char * r = bbStringToUTF8String(rep);
	int ret = xmlCatalogAdd((xmlChar *)n, (xmlChar *)o, (xmlChar *)r);
	bbMemFree(r);
	bbMemFree(o);
	bbMemFree(n);
	return ret;
}

int bmx_libxml_xmlCatalogConvert() {
	return xmlCatalogConvert();
}

int bmx_libxml_xmlCatalogRemove(BBString * value) {
	char * v = bbStringToUTF8String(value);
	int ret = xmlCatalogRemove((xmlChar *)v);
	bbMemFree(v);
	return ret;
}

BBString * bmx_libxml_xmlCatalogResolve(BBString * pubID, BBString * sysID) {
	char * p = bbStringToUTF8String(pubID);
	char * y = bbStringToUTF8String(sysID);
	BBString * s = bbStringFromXmlChar(xmlCatalogResolve((xmlChar *)p, (xmlChar *)y));
	bbMemFree(y);
	bbMemFree(p);
	return s;
}

BBString * bmx_libxml_xmlCatalogResolvePublic(BBString * pubID) {
	char * p = bbStringToUTF8String(pubID);
	BBString * s = bbStringFromXmlChar(xmlCatalogResolvePublic((xmlChar *)p));
	bbMemFree(p);
	return s;
}

BBString * bmx_libxml_xmlCatalogResolveSystem(BBString * sysID) {
	char * p = bbStringToUTF8String(sysID);
	BBString * s = bbStringFromXmlChar(xmlCatalogResolveSystem((xmlChar *)p));
	bbMemFree(p);
	return s;
}

BBString * bmx_libxml_xmlCatalogResolveURI(BBString * uri) {
	char * p = bbStringToUTF8String(uri);
	BBString * s = bbStringFromXmlChar(xmlCatalogResolveURI((xmlChar *)p));
	bbMemFree(p);
	return s;
}

int bmx_libxml_xmlACatalogAdd(xmlCatalogPtr handle, BBString * rtype, BBString * orig, BBString * rep) {
	char * t = bbStringToUTF8String(rtype);
	char * o = bbStringToUTF8String(orig);
	char * r = bbStringToUTF8String(rep);
	int ret = xmlACatalogAdd(handle, (xmlChar *)t, (xmlChar *)o, (xmlChar *)r);
	bbMemFree(r);
	bbMemFree(o);
	bbMemFree(t);
	return ret;
}

int bmx_libxml_xmlACatalogRemove(xmlCatalogPtr handle, BBString * value) {
	char * v = bbStringToUTF8String(value);
	int ret = xmlACatalogRemove(handle, (xmlChar *)v);
	bbMemFree(v);
	return ret;
}

BBString * bmx_libxml_xmlACatalogResolve(xmlCatalogPtr handle, BBString * pubID, BBString * sysID) {
	char * p = bbStringToUTF8String(pubID);
	char * y = bbStringToUTF8String(sysID);
	BBString * s = bbStringFromXmlChar(xmlACatalogResolve(handle, (xmlChar *)p, (xmlChar *)y));
	bbMemFree(y);
	bbMemFree(p);
	return s;
}

BBString * bmx_libxml_xmlACatalogResolvePublic(xmlCatalogPtr handle, BBString * pubID) {
	char * p = bbStringToUTF8String(pubID);
	BBString * s = bbStringFromXmlChar(xmlACatalogResolvePublic(handle, (xmlChar *)p));
	bbMemFree(p);
	return s;
}

BBString * bmx_libxml_xmlACatalogResolveSystem(xmlCatalogPtr handle, BBString * sysID) {
	char * p = bbStringToUTF8String(sysID);
	BBString * s = bbStringFromXmlChar(xmlACatalogResolveSystem(handle, (xmlChar *)p));
	bbMemFree(p);
	return s;
}

int bmx_libxml_xmlCatalogIsEmpty(xmlCatalogPtr handle) {
	return xmlCatalogIsEmpty(handle);
}

int bmx_libxml_xmlConvertSGMLCatalog(xmlCatalogPtr handle) {
	return xmlConvertSGMLCatalog(handle);
}

void bmx_libxml_xmlACatalogDump(xmlCatalogPtr handle, int file) {
	xmlACatalogDump(handle, (FILE*)file);
}

void bmx_libxml_xmlFreeCatalog(xmlCatalogPtr handle) {
	xmlFreeCatalog(handle);
}

// ****************************************************************************

BBString * bmx_libxml_xmldtdattribute_defaultValue(xmlAttributePtr handle) {
	return bbStringFromUTF8String((char *)handle->defaultValue);
}

// ****************************************************************************

int bmx_libxml_xmldtdelement_etype(xmlElementPtr handle) {
	return handle->etype;
}

BBString * bmx_libxml_xmldtdelement_prefix(xmlElementPtr handle) {
	return bbStringFromUTF8String((char *)handle->prefix);
}

// ****************************************************************************

BBString * bmx_libxml_xmlnotation_name(xmlNotationPtr handle) {
	return bbStringFromUTF8String((char *)handle->name);
}

BBString * bmx_libxml_xmlnotation_PublicID(xmlNotationPtr handle) {
	return bbStringFromUTF8String((char *)handle->PublicID);
}

BBString * bmx_libxml_xmlnotation_SystemID(xmlNotationPtr handle) {
	return bbStringFromUTF8String((char *)handle->SystemID);
}

// ****************************************************************************

void bmx_libxml_xmlXPtrLocationSetAdd(xmlLocationSetPtr handle, xmlXPathObjectPtr value) {
	xmlXPtrLocationSetAdd(handle, value);
}

void bmx_libxml_xmlXPtrLocationSetDel(xmlLocationSetPtr handle, xmlXPathObjectPtr value) {
	xmlXPtrLocationSetDel(handle, value);
}

xmlLocationSetPtr bmx_libxml_xmlXPtrLocationSetMerge(xmlLocationSetPtr handle, xmlLocationSetPtr value) {
	return xmlXPtrLocationSetMerge(handle, value);
}

void bmx_libxml_xmlXPtrLocationSetRemove(xmlLocationSetPtr handle, int index) {
	xmlXPtrLocationSetRemove(handle, index);
}

void bmx_libxml_xmlXPtrFreeLocationSet(xmlLocationSetPtr handle) {
	xmlXPtrFreeLocationSet(handle);
}

// ****************************************************************************

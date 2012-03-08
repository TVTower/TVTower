' Copyright (c) 2006-2010 Bruce A Henderson
'
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is
' furnished to do so, subject to the following conditions:
'
' The above copyright notice and this permission notice shall be included in
' all copies or substantial portions of the Software.
'
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
' THE SOFTWARE.
'
SuperStrict

Import Pub.zlib
Import BRL.LinkedList
Import BRL.Stream

'Import "../../pub.mod/zlib.mod/*.h"

Import "src/libxml/*.h"
Import "src/*.h"

Import "src/c14n.c"
Import "src/xpointer.c"
Import "src/catalog.c"
Import "src/chvalid.c"
Import "src/debugXML.c"
Import "src/dict.c"
'Import "src/DOCBparser.c"
Import "src/encoding.c"
Import "src/entities.c"
Import "src/error.c"
Import "src/globals.c"
Import "src/hash.c"
Import "src/HTMLparser.c"
Import "src/HTMLtree.c"
Import "src/legacy.c"
Import "src/list.c"
Import "src/nanoftp.c"
Import "src/nanohttp.c"
Import "src/parser.c"
Import "src/parserInternals.c"
Import "src/pattern.c"
Import "src/relaxng.c"
Import "src/SAX.c"
Import "src/SAX2.c"
Import "src/schematron.c"
Import "src/threads.c"
Import "src/tree.c"
Import "src/uri.c"
Import "src/valid.c"
Import "src/xinclude.c"
Import "src/xlink.c"
'Import "src/xmlcatalog.c" ' is an app
Import "src/xmlIO.c"
'Import "src/xmllint.c" ' is an app
Import "src/xmlmemory.c"
Import "src/xmlmodule.c"
Import "src/xmlreader.c"
Import "src/xmlregexp.c"
Import "src/xmlsave.c"
Import "src/xmlschemas.c"
Import "src/xmlschemastypes.c"
Import "src/xmlstring.c"
Import "src/xmlunicode.c"
Import "src/xmlwriter.c"
Import "src/xpath.c"


Extern
	Function _strlen:Int(s:Byte Ptr) = "strlen"

	Function xmlMemFree(p:Byte Ptr)
	Function xmlStrdup:Byte Ptr(s:Byte Ptr)
	Function _xmlCleanupParser() = "xmlCleanupParser"

	Function xmlNewDoc:Byte Ptr(vers:Byte Ptr)
	Function xmlNewDocNode:Byte Ptr(doc:Byte Ptr, ns:Byte Ptr, name:Byte Ptr, content:Byte Ptr)
	Function xmlParseMemory:Byte Ptr(buf:Byte Ptr, size:Int)
	Function xmlDocGetRootElement:Byte Ptr(xmlDocPtr:Byte Ptr)
	Function xmlDocSetRootElement:Byte Ptr(doc:Byte Ptr, root:Byte Ptr)
	Function xmlParseFile:Byte Ptr(filename:Byte Ptr)
	Function xmlSaveFile:Int(filename:Byte Ptr, doc:Byte Ptr)
	Function xmlSaveFormatFile:Int(filename:Byte Ptr, doc:Byte Ptr, format:Int)
	Function xmlParseDoc:Byte Ptr(text:Byte Ptr)
	Function xmlFreeDoc(xmlDocPtr:Byte Ptr)
	Function xmlNewDocRawNode:Byte Ptr(doc:Byte Ptr, ns:Byte Ptr, name:Byte Ptr, content:Byte Ptr)
	Function xmlNewDocPI:Byte Ptr(doc:Byte Ptr, name:Byte Ptr, content:Byte Ptr)
	Function xmlNewDocProp:Byte Ptr(doc:Byte Ptr, name:Byte Ptr, value:Byte Ptr)
	Function xmlEncodeEntitiesReentrant:Byte Ptr(doc:Byte Ptr, inp:Byte Ptr)
	Function xmlNewDtd:Byte Ptr(doc:Byte Ptr, name:Byte Ptr, externalID:Byte Ptr, systemID:Byte Ptr)
	Function xmlCreateIntSubset:Byte Ptr(doc:Byte Ptr, name:Byte Ptr, externalID:Byte Ptr, systemID:Byte Ptr)
	Function xmlCopyDoc:Byte Ptr(doc:Byte Ptr, recursive:Int)
	Function xmlGetIntSubset:Byte Ptr(doc:Byte Ptr)
	Function xmlReadFile:Byte Ptr(filename:Byte Ptr, encoding:Byte Ptr, options:Int)
	Function xmlReadMemory:Byte Ptr(buf:Byte Ptr, size:Int, url:Byte Ptr, encoding:Byte Ptr, options:Int)
	Function xmlReadDoc:Byte Ptr(text:Byte Ptr, url:Byte Ptr, encoding:Byte Ptr, options:Int)
	Function xmlReadIO:Byte Ptr(readCallback:Int(context:Object, buf:Byte Ptr, length:Int), closeCallback:Int(context:Object), context:Object, url:Byte Ptr, encoding:Byte Ptr, options:Int)

	Function xmlSetDocCompressMode(doc:Byte Ptr, Mode:Int)
	Function xmlGetDocCompressMode:Int(doc:Byte Ptr)

	Function xmlNewNode:Byte Ptr(ns:Byte Ptr, name:Byte Ptr)
	Function xmlNodeAddContent(cur:Byte Ptr, content:Byte Ptr)
	Function xmlNodeGetContent:Byte Ptr(node:Byte Ptr)
	Function xmlNodeIsText:Int(node:Byte Ptr)
	Function xmlNodeSetBase(node:Byte Ptr, uri:Byte Ptr)
	Function xmlNodeGetBase:Byte Ptr(doc:Byte Ptr, node:Byte Ptr)
	Function xmlNodeSetContent(node:Byte Ptr, content:Byte Ptr)
	Function xmlNodeSetName(node:Byte Ptr, name:Byte Ptr)
	Function xmlNodeSetSpacePreserve(node:Byte Ptr, value:Int)
	Function xmlNodeGetSpacePreserve:Int(node:Byte Ptr)
	Function xmlRemoveProp:Int(xmlAttrPtr:Byte Ptr)
	Function xmlReplaceNode:Byte Ptr(old:Byte Ptr, cur:Byte Ptr)
	Function xmlSearchNs:Byte Ptr(doc:Byte Ptr, node:Byte Ptr, nameSpace:Byte Ptr)
	Function xmlTextConcat:Int(node:Byte Ptr, content:Byte Ptr, length:Int)
	Function xmlTextMerge:Byte Ptr(First:Byte Ptr, Second:Byte Ptr)
	Function xmlUnlinkNode(cur:Byte Ptr)
	Function xmlFreeNode(cur:Byte Ptr)
	Function xmlGetLastChild:Byte Ptr(parent:Byte Ptr)
	Function xmlNewTextChild:Byte Ptr(parent:Byte Ptr, ns:Byte Ptr, name:Byte Ptr, content:Byte Ptr)
	Function xmlNewChild:Byte Ptr(parent: Byte Ptr, ns:Byte Ptr, name:Byte Ptr, content:Byte Ptr)
	Function xmlSetProp:Byte Ptr(node:Byte Ptr, name:Byte Ptr, value:Byte Ptr)
	Function xmlGetProp:Byte Ptr(node:Byte Ptr, name:Byte Ptr)
	Function xmlGetNsProp:Byte Ptr(node:Byte Ptr, name:Byte Ptr, nameSpace:Byte Ptr)
	Function xmlGetNoNsProp:Byte Ptr(node:Byte Ptr, name:Byte Ptr)
	Function xmlIsBlankNode:Int(node:Byte Ptr)
	Function xmlAddChild:Byte Ptr(parent:Byte Ptr, cur:Byte Ptr)
	Function xmlGetNodePath:Byte Ptr(node:Byte Ptr)
	Function xmlHasNsProp:Byte Ptr(node:Byte Ptr, name:Byte Ptr, nameSpace:Byte Ptr)
	Function xmlHasProp:Byte Ptr(node:Byte Ptr, name:Byte Ptr)
	Function xmlNodeListGetString:Byte Ptr(doc:Byte Ptr, list:Byte Ptr, inLine:Int)
	Function xmlNodeDump:Int(buf:Byte Ptr, doc:Byte Ptr, cur:Byte Ptr, level:Int, format:Int)
	Function xmlNewProp:Byte Ptr(node:Byte Ptr, name:Byte Ptr, value:Byte Ptr)
	Function xmlSetNs(node:Byte Ptr, ns:Byte Ptr)
	Function xmlSetNsProp:Byte Ptr(node:Byte Ptr, ns:Byte Ptr, name:Byte Ptr, value:Byte Ptr)
	Function xmlUnsetNsProp:Int(node:Byte Ptr, ns:Byte Ptr, name:Byte Ptr)
	Function xmlUnsetProp:Int(node:Byte Ptr, name:Byte Ptr)
	Function xmlSearchNsByHref:Byte Ptr(doc:Byte Ptr, node:Byte Ptr, href:Byte Ptr)
	Function xmlNodeSetLang(node:Byte Ptr, lang:Byte Ptr)
	Function xmlNodeGetLang:Byte Ptr(node:Byte Ptr)
	Function xmlAddChildList:Byte Ptr(parent:Byte Ptr, list:Byte Ptr)
	Function xmlAddPrevSibling:Byte Ptr(cur:Byte Ptr, elem:Byte Ptr)
	Function xmlAddNextSibling:Byte Ptr(cur:Byte Ptr, elem:Byte Ptr)
	Function xmlAddSibling:Byte Ptr(cur:Byte Ptr, elem:Byte Ptr)
	Function xmlCopyNode:Byte Ptr(node:Byte Ptr, extended:Int)
	Function xmlDocCopyNode:Byte Ptr(node:Byte Ptr, doc:Byte Ptr, extended:Int)
	Function xmlSetTreeDoc(node:Byte Ptr, doc:Byte Ptr)

	Function xmlNewComment:Byte Ptr(content:Byte Ptr)
	Function xmlNewCDataBlock:Byte Ptr(doc:Byte Ptr, content:Byte Ptr, length:Int)

	Function xmlXPathEval:Byte Ptr(txt:Byte Ptr, ctxt:Byte Ptr)
	Function xmlXPathNewContext:Byte Ptr(doc:Byte Ptr)
	Function xmlXPathEvalExpression:Byte Ptr(txt:Byte Ptr, ctxt:Byte Ptr)
	Function xmlXPathFreeContext(ctxt:Byte Ptr)
	Function xmlXPathFreeObject(obj:Byte Ptr)
	Function xmlXPathNodeSetIsEmpty:Int(ns:Byte Ptr)
	Function xmlXPathFreeNodeSet(nodeset:Byte Ptr)
	Function xmlXPathRegisterNs:Int(ctxt:Byte Ptr, prefix:Byte Ptr, url:Byte Ptr)
	Function xmlXPathEvalPredicate:Int(ctxt:Byte Ptr, res:Byte Ptr)
	'Function xmlXPathContextSetCache:Int(ctxt:Byte Ptr, active:Int, value:Int, options:Int)
	Function xmlXPathOrderDocElems:Long(doc:Byte Ptr)

	Function xmlXPathCastNodeSetToBoolean:Int(nodeset:Byte Ptr)
	Function xmlXPathCastNodeSetToNumber:Double(nodeset:Byte Ptr)
	Function xmlXPathCastNodeSetToString:Byte Ptr(nodeset:Byte Ptr)
	Function xmlXPathCastToBoolean:Int(xpathobj:Byte Ptr)
	Function xmlXPathCastToNumber:Double(xpathobj:Byte Ptr)
	Function xmlXPathCastToString:Byte Ptr(xpathobj:Byte Ptr)
	Function xmlXPathConvertBoolean:Byte Ptr(xpathobj:Byte Ptr)
	Function xmlXPathConvertNumber:Byte Ptr(xpathobj:Byte Ptr)
	Function xmlXPathConvertString:Byte Ptr(xpathobj:Byte Ptr)
	Function xmlXPathObjectCopy:Byte Ptr(xpathobj:Byte Ptr)

	Function xmlBufferCreate:Byte Ptr()
	Function xmlBufferFree(buffer:Byte Ptr)
	Function xmlBufferLength:Int(buffer:Byte Ptr)
	Function xmlBufferSetAllocationScheme(buffer:Byte Ptr, scheme:Int)
	Function xmlBufferCreateStatic:Byte Ptr(mam:Byte Ptr, size:Int)
	Function xmlBufferContent:Byte Ptr(buffer:Byte Ptr)

	Function xmlFreeDtd(dtd:Byte Ptr)
	Function xmlCopyDtd:Byte Ptr(dtd:Byte Ptr)
	Function xmlFreeNs(ns:Byte Ptr)

	Function _xmlGetLastError:Byte Ptr() = "xmlGetLastError"

	' xml reader
	Function xmlNewTextReaderFilename:Byte Ptr(filename:Byte Ptr)
	Function xmlFreeTextReader(reader:Byte Ptr)
	Function xmlReaderForFile:Byte Ptr(filename:Byte Ptr, encoding:Byte Ptr, options:Int)
	Function xmlReaderForDoc:Byte Ptr(cur:Byte Ptr, url:Byte Ptr, encoding:Byte Ptr, options:Int)
	Function xmlReaderForMemory:Byte Ptr(buf:Byte Ptr, size:Int, url:Byte Ptr, encoding:Byte Ptr, options:Int)
	Function xmlTextReaderAttributeCount:Int(reader:Byte Ptr)
	Function xmlTextReaderBaseUri:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstName:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstLocalName:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstEncoding:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstBaseUri:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstNamespaceUri:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstPrefix:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstValue:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstXmlLang:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderConstXmlVersion:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderCurrentDoc:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderDepth:Int(reader:Byte Ptr)
	Function xmlTextReaderExpand:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderGetAttribute:Byte Ptr(reader:Byte Ptr, name:Byte Ptr)
	Function xmlTextReaderGetAttributeNo:Byte Ptr(reader:Byte Ptr, no:Int)
	Function xmlTextReaderGetAttributeNs:Byte Ptr(reader:Byte Ptr, localName:Byte Ptr, nameSpaceURI:Byte Ptr)
	Function xmlTextReaderGetParserColumnNumber:Int(reader:Byte Ptr)
	Function xmlTextReaderGetParserLineNumber:Int(reader:Byte Ptr)
	Function xmlTextReaderGetParserProp:Int(reader:Byte Ptr, prop:Int)
	Function xmlTextReaderHasAttributes:Int(reader:Byte Ptr)
	Function xmlTextReaderHasValue:Int(reader:Byte Ptr)
	Function xmlTextReaderIsDefault:Int(reader:Byte Ptr)
	Function xmlTextReaderIsEmptyElement:Int(reader:Byte Ptr)
	Function xmlTextReaderIsNamespaceDecl:Int(reader:Byte Ptr)
	Function xmlTextReaderIsValid:Int(reader:Byte Ptr)
	Function xmlTextReaderLocalName:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderLookupNamespace:Byte Ptr(reader:Byte Ptr, prefix:Byte Ptr)
	Function xmlTextReaderMoveToAttribute:Int(reader:Byte Ptr, name:Byte Ptr)
	Function xmlTextReaderMoveToAttributeNo:Int(reader:Byte Ptr, index:Int)
	Function xmlTextReaderMoveToAttributeNs:Int(reader:Byte Ptr, localName:Byte Ptr, namespaceURI:Byte Ptr)
	Function xmlTextReaderMoveToElement:Int(reader:Byte Ptr)
	Function xmlTextReaderMoveToFirstAttribute:Int(reader:Byte Ptr)
	Function xmlTextReaderMoveToNextAttribute:Int(reader:Byte Ptr)
	Function xmlTextReaderName:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderNamespaceUri:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderNext:Int(reader:Byte Ptr)
	Function xmlTextReaderNodeType:Int(reader:Byte Ptr)
	Function xmlTextReaderNormalization:Int(reader:Byte Ptr)
	Function xmlTextReaderPrefix:Int(reader:Byte Ptr)
	Function xmlTextReaderPreserve:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderQuoteChar:Int(reader:Byte Ptr)
	Function xmlTextReaderRead:Int(reader:Byte Ptr)
	Function xmlTextReaderReadAttributeValue:Int(reader:Byte Ptr)
	Function xmlTextReaderReadInnerXml:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderReadOuterXml:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderReadState:Int(reader:Byte Ptr)
	Function xmlTextReaderReadString:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderRelaxNGValidate:Int(reader:Byte Ptr, rng:Byte Ptr)
	Function xmlTextReaderSchemaValidate:Int(reader:Byte Ptr, xsd:Byte Ptr)
	Function xmlTextReaderSetParserProp:Int(reader:Byte Ptr, prop:Int, value:Int)
	Function xmlTextReaderStandalone:Int(reader:Byte Ptr)
	Function xmlTextReaderValue:Byte Ptr(reader:Byte Ptr)
	Function xmlTextReaderXmlLang:Byte Ptr(reader:Byte Ptr)

	Function UTF8Toisolat1(out:Byte Ptr,outlen:Int Var ,in:Byte Ptr,inlen:Int Var )
	Function isolat1ToUTF8(out:Byte Ptr,outlen:Int Var ,in:Byte Ptr,inlen:Int Var )

	Function _xmlSubstituteEntitiesDefault:Int(value:Int) = "xmlSubstituteEntitiesDefault"
	Function xmlAddDocEntity:Byte Ptr(doc:Byte Ptr, name:Byte Ptr, _type:Int, externalID:Byte Ptr, systemID:Byte Ptr, content:Byte Ptr)
	Function xmlAddDtdEntity:Byte Ptr(doc:Byte Ptr, name:Byte Ptr, _type:Int, externalID:Byte Ptr, systemID:Byte Ptr, content:Byte Ptr)
	Function xmlEncodeSpecialChars:Byte Ptr(doc:Byte Ptr, inp:Byte Ptr)
	Function xmlGetDocEntity:Byte Ptr(doc:Byte Ptr, name:Byte Ptr)
	Function xmlGetDtdEntity:Byte Ptr(doc:Byte Ptr, name:Byte Ptr)
	Function xmlGetParameterEntity:Byte Ptr(doc:Byte Ptr, name:Byte Ptr)
	Function _xmlGetPredefinedEntity:Byte Ptr(name:Byte Ptr) = "xmlGetPredefinedEntity"

	Function xmlNewCatalog:Byte Ptr(sgml:Int)
	Function xmlACatalogAdd:Int(catal:Byte Ptr, _type:Byte Ptr, orig:Byte Ptr, rep:Byte Ptr)
	Function xmlFreeCatalog(catal:Byte Ptr)
	Function xmlACatalogRemove:Int(catal:Byte Ptr, value:Byte Ptr)
	Function xmlACatalogResolve:Byte Ptr(catal:Byte Ptr, pubID:Byte Ptr, sysID:Byte Ptr)
	Function xmlACatalogResolvePublic:Byte Ptr(catal:Byte Ptr, pubID:Byte Ptr)
	Function xmlACatalogResolveSystem:Byte Ptr(catal:Byte Ptr, sysID:Byte Ptr)
	Function xmlCatalogIsEmpty:Int(catal:Byte Ptr)
	Function xmlConvertSGMLCatalog:Int(catal:Byte Ptr)
	Function xmlLoadACatalog:Byte Ptr(filename:Byte Ptr)
	Function xmlLoadSGMLSuperCatalog:Byte Ptr(filename:Byte Ptr)
	Function xmlParseCatalogFile:Byte Ptr(filename:Byte Ptr)
	Function xmlCatalogSetDefaults(allow:Int)
	Function xmlCatalogGetDefaults:Int()
	Function xmlCatalogSetDebug:Int(level:Int)
	Function xmlCatalogSetDefaultPrefer:Int(prefer:Int)
	Function xmlLoadCatalog:Int(filename:Byte Ptr)
	Function xmlCatalogAdd:Int(_type:Byte Ptr, orig:Byte Ptr, rep:Byte Ptr)
	Function xmlCatalogConvert:Int()
	Function xmlCatalogRemove:Int(value:Byte Ptr)
	Function xmlCatalogResolve:Byte Ptr(pubID:Byte Ptr, sysID:Byte Ptr)
	Function xmlCatalogResolvePublic:Byte Ptr(pubID:Byte Ptr)
	Function xmlCatalogResolveSystem:Byte Ptr(sysID:Byte Ptr)
	Function xmlCatalogResolveURI:Byte Ptr(uri:Byte Ptr)
	Function xmlACatalogDump(catalog:Byte Ptr, file:Int)
	Function xmlCatalogDump(file:Int)

	Function xmlXIncludeNewContext:Byte Ptr(doc:Byte Ptr)
	Function xmlXIncludeFreeContext(context:Byte Ptr)
	Function xmlXIncludeProcess:Int(doc:Byte Ptr)
	Function xmlXIncludeProcessFlags:Int(doc:Byte Ptr, flags:Int)
	Function xmlXIncludeProcessNode:Int(context:Byte Ptr, node:Byte Ptr)
	Function xmlXIncludeProcessTree:Int(node:Byte Ptr)
	Function xmlXIncludeProcessTreeFlags:Int(node:Byte Ptr, flags:Int)
	Function xmlXIncludeSetFlags:Int(context:Byte Ptr, flags:Int)

	Function xmlCreateURI:Byte Ptr()
	Function xmlBuildURI:Byte Ptr(uri:Byte Ptr, base:Byte Ptr)
	Function xmlCanonicPath:Byte Ptr(path:Byte Ptr)
	Function xmlFreeURI(uri:Byte Ptr)
	Function xmlNormalizeURIPath:Int(path:Byte Ptr)
	Function xmlParseURI:Byte Ptr(uri:Byte Ptr)
	Function xmlParseURIRaw:Byte Ptr(uri:Byte Ptr, raw:Int)
	Function xmlParseURIReference:Int(uri:Byte Ptr, str:Byte Ptr)
	Function xmlSaveUri:Byte Ptr(uri:Byte Ptr)
	Function xmlURIEscape:Byte Ptr(uri:Byte Ptr)
	Function xmlURIEscapeStr:Byte Ptr(str:Byte Ptr, list:Byte Ptr)
	Function xmlURIUnescapeString:Byte Ptr(str:Byte Ptr, length:Int, target:Byte Ptr)

	Function xmlXPtrBuildNodeList:Byte Ptr(obj:Byte Ptr)
	Function xmlXPtrEval:Byte Ptr(str:Byte Ptr, context:Byte Ptr)
	Function xmlXPtrLocationSetAdd(set:Byte Ptr, value:Byte Ptr)
	Function xmlXPtrFreeLocationSet(set:Byte Ptr)
	Function xmlXPtrLocationSetCreate:Byte Ptr(value:Byte Ptr)
	Function xmlXPtrLocationSetDel(set:Byte Ptr, value:Byte Ptr)
	Function xmlXPtrLocationSetMerge:Byte Ptr(val1:Byte Ptr, val2:Byte Ptr)
	Function xmlXPtrLocationSetRemove(set:Byte Ptr, index:Int)
	Function xmlXPtrNewCollapsedRange:Byte Ptr(node:Byte Ptr)
	Function xmlXPtrNewContext:Byte Ptr(doc:Byte Ptr, here:Byte Ptr, origin:Byte Ptr)
	Function xmlXPtrNewLocationSetNodeSet:Byte Ptr(nodeset:Byte Ptr)
	Function xmlXPtrNewLocationSetNodes:Byte Ptr(startnode:Byte Ptr, endnode:Byte Ptr)
	Function xmlXPtrNewRange:Byte Ptr(startnode:Byte Ptr, startindex:Int, endnode:Byte Ptr, endindex:Int)
	Function xmlXPtrNewRangeNodeObject:Byte Ptr(startnode:Byte Ptr, xpath:Byte Ptr)
	Function xmlXPtrNewRangeNodePoint:Byte Ptr(startnode:Byte Ptr, xpath:Byte Ptr)
	Function xmlXPtrNewRangeNodes:Byte Ptr(startnode:Byte Ptr, endnode:Byte Ptr)
	Function xmlXPtrNewRangePointNode:Byte Ptr(xpath:Byte Ptr, endnode:Byte Ptr)
	Function xmlXPtrNewRangePoints:Byte Ptr(startxpath:Byte Ptr, endxpath:Byte Ptr)
	Function xmlXPtrWrapLocationSet:Byte Ptr(location:Byte Ptr)

	Function xmlGetDtdAttrDesc:Byte Ptr(dtd:Byte Ptr, elem:Byte Ptr, name:Byte Ptr)
	Function xmlGetDtdElementDesc:Byte Ptr(dtd:Byte Ptr, name:Byte Ptr)
	Function xmlGetDtdNotationDesc:Byte Ptr(dtd:Byte Ptr, name:Byte Ptr)
	Function xmlGetDtdQAttrDesc:Byte Ptr(dtd:Byte Ptr, elem:Byte Ptr, name:Byte Ptr, prefix:Byte Ptr)
	Function xmlGetDtdQElementDesc:Byte Ptr(dtd:Byte Ptr, name:Byte Ptr, prefix:Byte Ptr)
	Function xmlGetID:Byte Ptr(doc:Byte Ptr, id:Byte Ptr)
	Function xmlIsID:Int(doc:Byte Ptr, node:Byte Ptr, attr:Byte Ptr)
	Function xmlIsRef:Int(doc:Byte Ptr, node:Byte Ptr, attr:Byte Ptr)
	Function xmlIsMixedElement:Int(doc:Byte Ptr, name:Byte Ptr)
	Function xmlRemoveID:Int(doc:Byte Ptr, attr:Byte Ptr)
	Function xmlRemoveRef:Int(doc:Byte Ptr, attr:Byte Ptr)
	Function xmlValidateAttributeValue:Int(_type:Int, value:Byte Ptr)
	Function xmlValidateDocument:Int(context:Byte Ptr, doc:Byte Ptr)
	Function xmlValidateDocumentFinal:Int(context:Byte Ptr, doc:Byte Ptr)
	Function xmlValidateDtd:Int(context:Byte Ptr, doc:Byte Ptr, dtd:Byte Ptr)
	Function xmlValidateDtdFinal:Int(context:Byte Ptr, doc:Byte Ptr)
	Function xmlValidateRoot:Int(context:Byte Ptr, doc:Byte Ptr)
	Function xmlValidateElement:Int(context:Byte Ptr, doc:Byte Ptr, elem:Byte Ptr)
	Function xmlValidateElementDecl:Int(context:Byte Ptr, doc:Byte Ptr, elem:Byte Ptr)
	Function xmlValidateNameValue:Int(value:Byte Ptr)
	Function xmlValidateNamesValue:Int(value:Byte Ptr)
	Function xmlValidateNmtokenValue:Int(value:Byte Ptr)
	Function xmlValidateNmtokensValue:Int(value:Byte Ptr)
	Function xmlValidBuildContentModel:Int(context:Byte Ptr, elem:Byte Ptr)
	Function xmlValidCtxtNormalizeAttributeValue:Byte Ptr(context:Byte Ptr, doc:Byte Ptr, elem:Byte Ptr, name:Byte Ptr, value:Byte Ptr)
	Function xmlValidNormalizeAttributeValue:Byte Ptr(doc:Byte Ptr, elem:Byte Ptr, name:Byte Ptr, value:Byte Ptr)
	Function xmlValidateAttributeDecl:Int(context:Byte Ptr, doc:Byte Ptr, attr:Byte Ptr)

	Function xmlNewValidCtxt:Byte Ptr()
	Function xmlFreeValidCtxt(context:Byte Ptr)

	Function xmlFreeDocElementContent(doc:Byte Ptr, content:Byte Ptr)
	Function xmlNewDocElementContent:Byte Ptr(doc:Byte Ptr, name:Byte Ptr, contentType:Int)

	Function xmlXPathCompile:Byte Ptr(expr:Byte Ptr)
	Function xmlXPathCompiledEval:Byte Ptr(expr:Byte Ptr, context:Byte Ptr)
	Function xmlXPathFreeCompExpr(expr:Byte Ptr)

	Function xmlGetLineNo:Int(node:Byte Ptr)

	Function initGenericErrorDefaultFunc(err:Byte Ptr)
	Function xmlSetStructuredErrorFunc(data:Object, callback(data:Object, error:Byte Ptr))

	Function xmlOutputBufferCreateBuffer:Byte Ptr(buffer:Byte Ptr, encoder:Byte Ptr)
	Function xmlSaveFormatFileTo:Int(outputBuffer:Byte Ptr, doc:Byte Ptr, encoder:Byte Ptr, format:Int)
	Function xmlOutputBufferCreateIO:Byte Ptr(writeCallback:Int(context:TStream, buffer:Byte Ptr, length:Int), ..
		closeCallback:Int(context:TStream), context:TStream, encoder:Byte Ptr)
End Extern

Const XML_SGML_DEFAULT_CATALOG:String = "file:///etc/sgml/catalog"

' parse options
Const XML_PARSE_RECOVER:Int = 1
Const XML_PARSE_NOENT:Int = 2
Const XML_PARSE_DTDLOAD:Int = 4
Const XML_PARSE_DTDATTR:Int = 8
Const XML_PARSE_DTDVALID:Int = 16
Const XML_PARSE_NOERROR:Int = 32
Const XML_PARSE_NOWARNING:Int = 64
Const XML_PARSE_PEDANTIC:Int = 128
Const XML_PARSE_NOBLANKS:Int = 256
Const XML_PARSE_SAX1:Int = 512
Const XML_PARSE_XINCLUDE:Int = 1024
Const XML_PARSE_NONET:Int = 2048
Const XML_PARSE_NODICT:Int = 4096
Const XML_PARSE_NSCLEAN:Int = 8192
Const XML_PARSE_NOCDATA:Int = 16384
Const XML_PARSE_NOXINCNODE:Int = 32768
Const XML_PARSE_COMPACT:Int = 65536
Const XML_PARSE_OLD10:Int = 1 Shl 17
Const XML_PARSE_NOBASEFIX:Int = 1 Shl 18
Const XML_PARSE_HUGE:Int = 1 Shl 19
Const XML_PARSE_OLDSAX:Int = 1 Shl 20

' attribute default
Const XML_ATTRIBUTE_NONE:Int = 1
Const XML_ATTRIBUTE_REQUIRED:Int = 2
Const XML_ATTRIBUTE_IMPLIED:Int = 3
Const XML_ATTRIBUTE_FIXED:Int = 4

' attribute type
Const XML_ATTRIBUTE_CDATA:Int = 1
Const XML_ATTRIBUTE_ID:Int = 2
Const XML_ATTRIBUTE_IDREF:Int = 3
Const XML_ATTRIBUTE_IDREFS:Int = 4
Const XML_ATTRIBUTE_ENTITY:Int = 5
Const XML_ATTRIBUTE_ENTITIES:Int = 6
Const XML_ATTRIBUTE_NMTOKEN:Int = 7
Const XML_ATTRIBUTE_NMTOKENS:Int = 8
Const XML_ATTRIBUTE_ENUMERATION:Int = 9
Const XML_ATTRIBUTE_NOTATION:Int = 10


' buffer allocation scheme
Const XML_BUFFER_ALLOC_DOUBLEIT:Int = 1
Const XML_BUFFER_ALLOC_EXACT:Int = 2
Const XML_BUFFER_ALLOC_IMMUTABLE:Int = 3


' element content occur
Const XML_ELEMENT_CONTENT_ONCE:Int = 1
Const XML_ELEMENT_CONTENT_OPT:Int = 2
Const XML_ELEMENT_CONTENT_MULT:Int = 3
Const XML_ELEMENT_CONTENT_PLUS:Int = 4

' element content type
Const XML_ELEMENT_CONTENT_PCDATA:Int = 1
Const XML_ELEMENT_CONTENT_ELEMENT:Int = 2
Const XML_ELEMENT_CONTENT_SEQ:Int = 3
Const XML_ELEMENT_CONTENT_OR:Int = 4

' node types
Const XML_ELEMENT_NODE:Int = 1
Const XML_ATTRIBUTE_NODE:Int = 2
Const XML_TEXT_NODE:Int = 3
Const XML_CDATA_SECTION_NODE:Int = 4
Const XML_ENTITY_REF_NODE:Int = 5
Const XML_ENTITY_NODE:Int = 6
Const XML_PI_NODE:Int = 7
Const XML_COMMENT_NODE:Int = 8
Const XML_DOCUMENT_NODE:Int = 9
Const XML_DOCUMENT_TYPE_NODE:Int = 10
Const XML_DOCUMENT_FRAG_NODE:Int = 11
Const XML_NOTATION_NODE:Int = 12
Const XML_HTML_DOCUMENT_NODE:Int = 13
Const XML_DTD_NODE:Int = 14
Const XML_ELEMENT_DECL:Int = 15
Const XML_ATTRIBUTE_DECL:Int = 16
Const XML_ENTITY_DECL:Int = 17
Const XML_NAMESPACE_DECL:Int = 18
Const XML_XINCLUDE_START:Int = 19
Const XML_XINCLUDE_END:Int = 20
Const XML_DOCB_DOCUMENT_NODE:Int = 21

' element type val
Const XML_ELEMENT_TYPE_UNDEFINED:Int = 0
Const XML_ELEMENT_TYPE_EMPTY:Int = 1
Const XML_ELEMENT_TYPE_ANY:Int = 2
Const XML_ELEMENT_TYPE_MIXED:Int = 3
Const XML_ELEMENT_TYPE_ELEMENT:Int = 4

' xpath error
Const XPATH_EXPRESSION_OK:Int = 0
Const XPATH_NUMBER_ERROR:Int = 1
Const XPATH_UNFINISHED_LITERAL_ERROR:Int = 2
Const XPATH_START_LITERAL_ERROR:Int = 3
Const XPATH_VARIABLE_REF_ERROR:Int = 4
Const XPATH_UNDEF_VARIABLE_ERROR:Int = 5
Const XPATH_INVALID_PREDICATE_ERROR:Int = 6
Const XPATH_EXPR_ERROR:Int = 7
Const XPATH_UNCLOSED_ERROR:Int = 8
Const XPATH_UNKNOWN_FUNC_ERROR:Int = 9
Const XPATH_INVALID_OPERAND:Int = 10
Const XPATH_INVALID_TYPE:Int = 11
Const XPATH_INVALID_ARITY:Int = 12
Const XPATH_INVALID_CTXT_SIZE:Int = 13
Const XPATH_INVALID_CTXT_POSITION:Int = 14
Const XPATH_MEMORY_ERROR:Int = 15
Const XPTR_SYNTAX_ERROR:Int = 16
Const XPTR_RESOURCE_ERROR:Int = 17
Const XPTR_SUB_RESOURCE_ERROR:Int = 18
Const XPATH_UNDEF_PREFIX_ERROR:Int = 19
Const XPATH_ENCODING_ERROR:Int = 20
Const XPATH_INVALID_CHAR_ERROR:Int = 21
Const XPATH_INVALID_CTXT:Int = 22

' error domain
Const XML_FROM_NONE:Int = 0
Const XML_FROM_PARSER:Int = 1
Const XML_FROM_TREE:Int = 2
Const XML_FROM_NAMESPACE:Int = 3
Const XML_FROM_DTD:Int = 4
Const XML_FROM_HTML:Int = 5
Const XML_FROM_MEMORY:Int = 6
Const XML_FROM_OUTPUT:Int = 7
Const XML_FROM_IO:Int = 8
Const XML_FROM_FTP:Int = 9
Const XML_FROM_HTTP:Int = 10
Const XML_FROM_XINCLUDE:Int = 11
Const XML_FROM_XPATH:Int = 12
Const XML_FROM_XPOINTER:Int = 13
Const XML_FROM_REGEXP:Int = 14
Const XML_FROM_DATATYPE:Int = 15
Const XML_FROM_SCHEMASP:Int = 16
Const XML_FROM_SCHEMASV:Int = 17
Const XML_FROM_RELAXNGP:Int = 18
Const XML_FROM_RELAXNGV:Int = 19
Const XML_FROM_CATALOG:Int = 20
Const XML_FROM_C14N:Int = 21
Const XML_FROM_XSLT:Int = 22
Const XML_FROM_VALID:Int = 23
Const XML_FROM_CHECK:Int = 24
Const XML_FROM_WRITER:Int = 25
Const XML_FROM_MODULE:Int = 26
Const XML_FROM_I18N:Int = 27

' xpath object types
Const XPATH_UNDEFINED:Int = 0
Const XPATH_NODESET:Int = 1
Const XPATH_BOOLEAN:Int = 2
Const XPATH_NUMBER:Int = 3
Const XPATH_STRING:Int = 4
Const XPATH_POINT:Int = 5
Const XPATH_RANGE:Int = 6
Const XPATH_LOCATIONSET:Int = 7
Const XPATH_USERS:Int = 8
Const XPATH_XSLT_TREE:Int = 9

' parser property
Const XML_PARSER_LOADDTD:Int = 1
Const XML_PARSER_DEFAULTATTRS:Int = 2
Const XML_PARSER_VALIDATE:Int = 3
Const XML_PARSER_SUBST_ENTITIES:Int = 4

' xmlEntityType
Const XML_INTERNAL_GENERAL_ENTITY:Int = 1
Const XML_EXTERNAL_GENERAL_PARSED_ENTITY:Int = 2
Const XML_EXTERNAL_GENERAL_UNPARSED_ENTITY:Int = 3
Const XML_INTERNAL_PARAMETER_ENTITY:Int = 4
Const XML_EXTERNAL_PARAMETER_ENTITY:Int = 5
Const XML_INTERNAL_PREDEFINED_ENTITY:Int = 6

' xmlCatalogAllow
Const XML_CATA_ALLOW_NONE:Int = 0
Const XML_CATA_ALLOW_GLOBAL:Int = 1
Const XML_CATA_ALLOW_DOCUMENT:Int = 2
Const XML_CATA_ALLOW_ALL:Int = 3

' xmlCatalogPrefer
Const XML_CATA_PREFER_NONE:Int = 0
Const XML_CATA_PREFER_PUBLIC:Int = 1
Const XML_CATA_PREFER_SYSTEM:Int = 2

' internal error message
Const XML_ERROR_PARAM:String = "Mandatory parameter is Null"

Const XML_ERR_NONE:Int = 0
Const XML_ERR_WARNING:Int = 1
Const XML_ERR_ERROR:Int = 2
Const XML_ERR_FATAL:Int = 3

' BOM - UTF-8
Const BOM_UTF8:String = Chr(239) + Chr(187) + Chr(191)


Type TxmlOutputStreamHandler

	Global stream:TStream
	Global autoClose:Int

	Function writeCallback:Int(context:TStream, buffer:Byte Ptr, length:Int)
		If Not stream Then
			Return -1
		End If

		Local count:Int = stream.WriteBytes(buffer, length)
	End Function

	Function closeCallback:Int(context:TStream)
		If Not stream Then
			Return -1
		End If

		If autoClose Then
			stream.Close()
		End If

		stream = Null
		Return 0
	End Function


End Type

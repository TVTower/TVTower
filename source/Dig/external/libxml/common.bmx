' Copyright (c) 2006-2012 Bruce A Henderson
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

Import "source.bmx"

Extern

	Function _xmlCleanupParser() = "xmlCleanupParser"

	Function xmlReadMemory:Byte Ptr(buf:Byte Ptr, size:Int, url:Byte Ptr, encoding:Byte Ptr, options:Int)
	Function xmlReadIO:Byte Ptr(readCallback:Int(context:Object, buf:Byte Ptr, length:Int), closeCallback:Int(context:Object), context:Object, url:Byte Ptr, encoding:Byte Ptr, options:Int)
	
	Function initGenericErrorDefaultFunc(err:Byte Ptr)
	Function xmlSetStructuredErrorFunc(data:Object, callback(data:Object, error:Byte Ptr))
	
	Function xmlOutputBufferCreateBuffer:Byte Ptr(buffer:Byte Ptr, encoder:Byte Ptr)
	Function xmlOutputBufferCreateIO:Byte Ptr(writeCallback:Int(context:TStream, buffer:Byte Ptr, length:Int), ..
		closeCallback:Int(context:TStream), context:TStream, encoder:Byte Ptr)
		
	
End Extern


Extern
	Function bmx_libxml_xmlbase_getType:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlbase_getName:String(handle:Byte Ptr)
	Function bmx_libxml_xmlbase_getDoc:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlbase_next:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlbase_prev:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlbase_children:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlbase_parent:Byte Ptr(handle:Byte Ptr)

	Function bmx_libxml_xmlGetLastChild:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlGetLineNo:Int(handle:Byte Ptr)
	
	Function bmx_libxml_xmlNewNode:Byte Ptr(nsPtr:Byte Ptr, name:String)
	Function bmx_libxml_xmlNodeGetContent:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextConcat:Int(handle:Byte Ptr, content:String)
	Function bmx_libxml_xmlNodeIsText:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlIsBlankNode:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlNodeSetBase(handle:Byte Ptr, uri:String)
	Function bmx_libxml_xmlNodeGetBase:String(doc:Byte Ptr, handle:Byte Ptr)
	Function bmx_libxml_xmlNodeSetContent(handle:Byte Ptr, content:String)
	Function bmx_libxml_xmlNodeAddContent(handle:Byte Ptr, content:String)
	Function bmx_libxml_xmlNodeSetName(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlTextMerge:Byte Ptr(handle:Byte Ptr, node:Byte Ptr)
	Function bmx_libxml_xmlNewChild:Byte Ptr(handle:Byte Ptr, namespace:Byte Ptr, name:String, content:String)
	Function bmx_libxml_xmlNewTextChild:Byte Ptr(handle:Byte Ptr, namespace:Byte Ptr, name:String, content:String)
	Function bmx_libxml_xmlAddChild:Byte Ptr(handle:Byte Ptr, firstNode:Byte Ptr)
	Function bmx_libxml_xmlAddNextSibling:Byte Ptr(handle:Byte Ptr, node:Byte Ptr)
	Function bmx_libxml_xmlAddPrevSibling:Byte Ptr(handle:Byte Ptr, node:Byte Ptr)
	Function bmx_libxml_xmlAddSibling:Byte Ptr(handle:Byte Ptr, node:Byte Ptr)
	Function bmx_libxml_xmlNewProp:Byte Ptr(handle:Byte Ptr, name:String, value:String)
	Function bmx_libxml_xmlSetProp:Byte Ptr(handle:Byte Ptr, name:String, value:String)
	Function bmx_libxml_xmlSetNsProp:Byte Ptr(handle:Byte Ptr, namespace:Byte Ptr, name:String, value:String)
	Function bmx_libxml_xmlUnsetNsProp:Int(handle:Byte Ptr, namespace:Byte Ptr, name:String)
	Function bmx_libxml_xmlUnsetProp:Int(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlGetProp:String(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlGetNsProp:String(handle:Byte Ptr, name:String, namespace:String)
	Function bmx_libxml_xmlGetNoNsProp:String(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlHasNsProp:Byte Ptr(handle:Byte Ptr, name:String, namespace:String)
	Function bmx_libxml_xmlHasProp:Byte Ptr(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlGetNodePath:String(handle:Byte Ptr)
	Function bmx_libxml_xmlReplaceNode:Byte Ptr(handle:Byte Ptr, withNode:Byte Ptr)
	Function bmx_libxml_xmlSetNs(handle:Byte Ptr, namespace:Byte Ptr)
	Function bmx_libxml_xmlNodeSetSpacePreserve(handle:Byte Ptr, value:Int)
	Function bmx_libxml_xmlNodeGetSpacePreserve:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlNodeSetLang(handle:Byte Ptr, lang:String)
	Function bmx_libxml_xmlNodeGetLang:String(handle:Byte Ptr)
	Function bmx_libxml_xmlNewCDataBlock:Byte Ptr(handle:Byte Ptr, content:String)
	Function bmx_libxml_xmlNodeListGetString:String(handle:Byte Ptr)

	Function bmx_libxml_xmlNewComment:Byte Ptr(comment:String)
	Function bmx_libxml_xmlNodeDump(buffer:Byte Ptr, handle:Byte Ptr)
	Function bmx_libxml_xmlSearchNs:Byte Ptr(handle:Byte Ptr, namespace:String)
	Function bmx_libxml_xmlSearchNsByHref:Byte Ptr(handle:Byte Ptr, href:String)
	Function bmx_libxml_xmlCopyNode:Byte Ptr(handle:Byte Ptr, extended:Int)
	Function bmx_libxml_xmlDocCopyNode:Byte Ptr(handle:Byte Ptr, doc:Byte Ptr, extended:Int)
	Function bmx_libxml_xmlSetTreeDoc(handle:Byte Ptr, doc:Byte Ptr)
	Function bmx_libxml_xmlXIncludeProcessTree:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlXIncludeProcessTreeFlags:Int(handle:Byte Ptr, flags:Int)
	Function bmx_libxml_xmlnode_namespace:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlnode_properties:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlUnlinkNode(handle:Byte Ptr)
	Function bmx_libxml_xmlFreeNode(handle:Byte Ptr)
	
	Function bmx_libxml_xmlReadDoc:Byte Ptr(text:String, url:String, encoding:String, options:Int)
	Function bmx_libxml_xmlNewDoc:Byte Ptr(version:String)
	Function bmx_libxml_xmlParseFile:Byte Ptr(filename:String)
	Function bmx_libxml_xmlParseMemory:Byte Ptr(buf:Byte Ptr, size:Int)
	Function bmx_libxml_xmlParseDoc:Byte Ptr(text:String)
	Function bmx_libxml_xmlReadFile:Byte Ptr(filename:String, encoding:String, options:Int)
	Function bmx_libxml_xmlParseCatalogFile:Byte Ptr(filename:String)
	Function bmx_libxml_xmldoc_url:String(handle:Byte Ptr)
	Function bmx_libxml_xmlDocGetRootElement:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlDocSetRootElement:Byte Ptr(handle:Byte Ptr, root:Byte Ptr)
	Function bmx_libxml_xmlFreeDoc(handle:Byte Ptr)
	Function bmx_libxml_xmldoc_version:String(handle:Byte Ptr)
	Function bmx_libxml_xmldoc_encoding:String(handle:Byte Ptr)
	Function bmx_libxml_xmldoc_setencoding(handle:Byte Ptr, encoding:String)
	Function bmx_libxml_xmldoc_standalone:Int(handle:Byte Ptr)
	Function bmx_libxml_xmldoc_setStandalone(handle:Byte Ptr, value:Int)
	Function bmx_libxml_xmlNewDocPI:Byte Ptr(handle:Byte Ptr, name:String, content:String)
	Function bmx_libxml_xmlNewDocProp:Byte Ptr(handle:Byte Ptr, name:String, value:String)
	Function bmx_libxml_xmlSetDocCompressMode(handle:Byte Ptr, Mode:Int)
	Function bmx_libxml_xmlGetDocCompressMode:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlSaveFile:Int(filename:String, handle:Byte Ptr, encoding:String)
	Function bmx_libxml_xmlSaveFormatFileTo:Int(outputBuffer:Byte Ptr, handle:Byte Ptr, encoding:String, format:Int)
	Function bmx_libxml_xmlSaveFormatFile:Int(filename:String, handle:Byte Ptr, encoding:String, format:Int)
	Function bmx_libxml_xmlXPathNewContext:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlCreateIntSubset:Byte Ptr(handle:Byte Ptr, name:String, externalID:String, systemID:String)
	Function bmx_libxml_xmlGetIntSubset:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlNewDtd:Byte Ptr(handle:Byte Ptr, name:String, externalID:String, systemID:String)
	Function bmx_libxml_xmlXPathOrderDocElems(handle:Byte Ptr, value:Long Ptr)
	Function bmx_libxml_xmlCopyDoc:Byte Ptr(handle:Byte Ptr, recursive:Int)
	Function bmx_libxml_xmlAddDocEntity:Byte Ptr(handle:Byte Ptr, name:String, entityType:Int, externalID:String, systemID:String, content:String)
	Function bmx_libxml_xmlAddDtdEntity:Byte Ptr(handle:Byte Ptr, name:String, entityType:Int, externalID:String, systemID:String, content:String)
	Function bmx_libxml_xmlEncodeEntitiesReentrant:String(handle:Byte Ptr, inp:String)
	Function bmx_libxml_xmlEncodeSpecialChars:String(handle:Byte Ptr, inp:String)
	Function bmx_libxml_xmlGetDocEntity:Byte Ptr(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlGetDtdEntity:Byte Ptr(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlGetParameterEntity:Byte Ptr(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlXIncludeProcess:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlXIncludeProcessFlags:Int(handle:Byte Ptr, flags:Int)
	Function bmx_libxml_xmlGetID:Byte Ptr(handle:Byte Ptr, id:String)
	Function bmx_libxml_xmlIsID:Int(handle:Byte Ptr, node:Byte Ptr, attr:Byte Ptr)
	Function bmx_libxml_xmlIsRef:Int(handle:Byte Ptr, node:Byte Ptr, attr:Byte Ptr)
	Function bmx_libxml_xmlIsMixedElement:Int(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlRemoveID:Int(handle:Byte Ptr, attr:Byte Ptr)
	Function bmx_libxml_xmlRemoveRef:Int(handle:Byte Ptr, attr:Byte Ptr)
	Function bmx_libxml_xmlNewDocElementContent:Byte Ptr(handle:Byte Ptr, name:String, contentType:Int)
	Function bmx_libxml_xmlFreeDocElementContent(handle:Byte Ptr, content:Byte Ptr)
	Function bmx_libxml_xmlValidCtxtNormalizeAttributeValue:String(context:Byte Ptr, handle:Byte Ptr, elem:Byte Ptr, name:String, value:String)
	Function bmx_libxml_xmlValidNormalizeAttributeValue:String(handle:Byte Ptr, elem:Byte Ptr, name:String, value:String)
	
	Function bmx_libxml_xmlns_type:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlns_href:String(handle:Byte Ptr)
	Function bmx_libxml_xmlns_prefix:String(handle:Byte Ptr)
	Function bmx_libxml_xmlFreeNs(handle:Byte Ptr)
	
	Function bmx_libxml_xmlattr_atype:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlattr_ns:Byte Ptr(handle:Byte Ptr)

	Function bmx_libxml_xmlXPathCompile:Byte Ptr(expr:String)
	Function bmx_libxml_xmlXPathCompiledEval:Byte Ptr(handle:Byte Ptr, context:Byte Ptr)
	Function bmx_libxml_xmlXPathFreeCompExpr(handle:Byte Ptr)
	
	Function bmx_libxml_xmlelementcontent_type:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlelementcontent_ocur:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlelementcontent_name:String(handle:Byte Ptr)
	Function bmx_libxml_xmlelementcontent_prefix:String(handle:Byte Ptr)
	
	Function bmx_libxml_xmlValidateAttributeValue:Int(attributeType:Int, value:String)
	Function bmx_libxml_xmlNewValidCtxt:Byte Ptr()
	Function bmx_libxml_xmlValidateNameValue:Int(value:String)
	Function bmx_libxml_xmlValidateNamesValue:Int(value:String)
	Function bmx_libxml_xmlValidateNmtokenValue:Int(value:String)
	Function bmx_libxml_xmlValidateNmtokensValue:Int(value:String)
	Function bmx_libxml_xmlvalidctxt_valid:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlvalidctxt_finishDtd:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlvalidctxt_doc:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlValidateDocument:Int(handle:Byte Ptr, doc:Byte Ptr)
	Function bmx_libxml_xmlValidateDocumentFinal:Int(handle:Byte Ptr, doc:Byte Ptr)
	Function bmx_libxml_xmlValidateDtd:Int(handle:Byte Ptr, doc:Byte Ptr, dtd:Byte Ptr)
	Function bmx_libxml_xmlValidateDtdFinal:Int(handle:Byte Ptr, doc:Byte Ptr)
	Function bmx_libxml_xmlValidateRoot:Int(handle:Byte Ptr, doc:Byte Ptr)
	Function bmx_libxml_xmlValidateElement:Int(handle:Byte Ptr, doc:Byte Ptr, elem:Byte Ptr)
	Function bmx_libxml_xmlValidateElementDecl:Int(handle:Byte Ptr, doc:Byte Ptr, elem:Byte Ptr)
	Function bmx_libxml_xmlValidateAttributeDecl:Int(handle:Byte Ptr, doc:Byte Ptr, attr:Byte Ptr)
	Function bmx_libxml_xmlValidBuildContentModel:Int(handle:Byte Ptr, elem:Byte Ptr)
	Function bmx_libxml_xmlFreeValidCtxt(handle:Byte Ptr)
	
	Function bmx_libxml_xmlXPtrNewContext:Byte Ptr(doc:Byte Ptr, here:Byte Ptr, origin:Byte Ptr)
	Function bmx_libxml_xmlXPathEvalExpression:Byte Ptr(text:String, handle:Byte Ptr)
	Function bmx_libxml_xmlXPathEval:Byte Ptr(text:String, handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_doc:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_node:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathRegisterNs:Int(handle:Byte Ptr, prefix:String, uri:String)
	Function bmx_libxml_xmlXPathEvalPredicate:Int(handle:Byte Ptr, res:Byte Ptr)
	Function bmx_libxml_xmlXPtrEval:Byte Ptr(expr:String, handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_nb_types:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_max_types:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_contextSize:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_proximityPosition:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_xptr:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_here:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_origin:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_function:String(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathcontext_functionURI:String(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathFreeContext(handle:Byte Ptr)
	
	Function bmx_libxml_xmldtd_externalID:String(handle:Byte Ptr)
	Function bmx_libxml_xmldtd_systemID:String(handle:Byte Ptr)
	Function bmx_libxml_xmlCopyDtd:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlGetDtdAttrDesc:Byte Ptr(handle:Byte Ptr, elem:String, name:String)
	Function bmx_libxml_xmlGetDtdElementDesc:Byte Ptr(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlGetDtdNotationDesc:Byte Ptr(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlGetDtdQAttrDesc:Byte Ptr(handle:Byte Ptr, elem:String, name:String, prefix:String)
	Function bmx_libxml_xmlGetDtdQElementDesc:Byte Ptr(handle:Byte Ptr, name:String, prefix:String)
	Function bmx_libxml_xmlFreeDtd(handle:Byte Ptr)
	
	Function bmx_libxml_xmlGetLastError:Byte Ptr()
	Function bmx_libxml_xmlerror_domain:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_code:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_message:String(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_level:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_file:String(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_line:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_str1:String(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_str2:String(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_str3:String(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_int2:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlerror_node:Byte Ptr(handle:Byte Ptr)
	
	Function bmx_libxml_xmlGetPredefinedEntity:Byte Ptr(name:String)
	Function bmx_libxml_xmlSubstituteEntitiesDefault:Int(value:Int)
	
	Function bmx_libxml_xmlBufferCreate:Byte Ptr()
	Function bmx_libxml_xmlBufferCreateStatic:Byte Ptr(mem:Byte Ptr, size:Int)
	Function bmx_libxml_xmlbuffer_content:String(handle:Byte Ptr)
	Function bmx_libxml_xmlBufferFree(handle:Byte Ptr)
	
	Function bmx_libxml_xmlnodeset_nodeNr:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlnodeset_nodetab:Byte Ptr(handle:Byte Ptr, index:Int)
	Function bmx_libxml_xmlXPathCastNodeSetToBoolean:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathCastNodeSetToNumber:Double(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathCastNodeSetToString:String(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathFreeNodeSet(handle:Byte Ptr)
	
	Function bmx_libxml_xmlXPtrNewCollapsedRange:Byte Ptr(node:Byte Ptr)
	Function bmx_libxml_xmlXPtrNewLocationSetNodeSet:Byte Ptr(nodeset:Byte Ptr)
	Function bmx_libxml_xmlXPtrNewLocationSetNodes:Byte Ptr(startnode:Byte Ptr, endnode:Byte Ptr)
	Function bmx_libxml_xmlXPtrNewRange:Byte Ptr(startnode:Byte Ptr, startindex:Int, endnode:Byte Ptr, endindex:Int)
	Function bmx_libxml_xmlXPtrNewRangeNodeObject:Byte Ptr(startnode:Byte Ptr, endobj:Byte Ptr)
	Function bmx_libxml_xmlXPtrNewRangeNodePoint:Byte Ptr(startnode:Byte Ptr, endpoint:Byte Ptr)
	Function bmx_libxml_xmlXPtrNewRangeNodes:Byte Ptr(startnode:Byte Ptr, endnode:Byte Ptr)
	Function bmx_libxml_xmlXPtrNewRangePointNode:Byte Ptr(startpoint:Byte Ptr, endnode:Byte Ptr)
	Function bmx_libxml_xmlXPtrNewRangePoints:Byte Ptr(startpoint:Byte Ptr, endpoint:Byte Ptr)
	Function bmx_libxml_xmlXPtrWrapLocationSet:Byte Ptr(value:Byte Ptr)
	Function bmx_libxml_xmlxpathobject_type:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathobject_nodesetval:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlxpathobject_stringval:String(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathCastToBoolean:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathCastToNumber:Double(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathCastToString:String(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathConvertBoolean:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathConvertNumber:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathConvertString:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathObjectCopy:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlXPtrBuildNodeList:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlXPtrLocationSetCreate:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlXPathFreeObject(handle:Byte Ptr)
	
	Function bmx_libxml_xmlXIncludeNewContext:Byte Ptr(doc:Byte Ptr)
	Function bmx_libxml_xmlXIncludeProcessNode:Int(handle:Byte Ptr, node:Byte Ptr)
	Function bmx_libxml_xmlXIncludeSetFlags:Int(handle:Byte Ptr, flags:Int)
	Function bmx_libxml_xmlXIncludeFreeContext(handle:Byte Ptr)
	
	Function bmx_libxml_xmlCreateURI:Byte Ptr()
	Function bmx_libxml_xmlParseURI:Byte Ptr(uri:String)
	Function bmx_libxml_xmlParseURIRaw:Byte Ptr(uri:String, raw:Int)
	Function bmx_libxml_xmlBuildURI:String(uri:String, base:String)
	Function bmx_libxml_xmlCanonicPath:String(path:String)
	Function bmx_libxml_xmlNormalizeURIPath:String(path:String)
	Function bmx_libxml_xmlURIEscape:String(uri:String)
	Function bmx_libxml_xmlURIEscapeStr:String(uri:String, list:String)
	Function bmx_libxml_xmlURIUnescapeString:String(text:String)
	Function bmx_libxml_xmlParseURIReference:Int(handle:Byte Ptr, uri:String)
	Function bmx_libxml_xmlSaveUri:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_scheme:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_opaque:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_authority:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_server:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_user:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_port:Int(handle:Byte Ptr)
	Function bmx_libxml_xmluri_path:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_query:String(handle:Byte Ptr)
	Function bmx_libxml_xmluri_fragment:String(handle:Byte Ptr)
	Function bmx_libxml_xmlFreeURI(handle:Byte Ptr)
	
	Function bmx_libxml_xmlNewTextReaderFilename:Byte Ptr(filename:String)
	Function bmx_libxml_xmlReaderForFile:Byte Ptr(filename:String, encoding:String, options:Int)
	Function bmx_libxml_xmlReaderForMemory:Byte Ptr(buf:Byte Ptr, size:Int, url:String, encoding:String, options:Int)
	Function bmx_libxml_xmlReaderForDoc:Byte Ptr(docTextPtr:Byte Ptr, urlTextPtr:String, encTextPtr:String, options:Int)
	Function bmx_libxml_xmlTextReaderAttributeCount:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderBaseUri:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderCurrentDoc:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlFreeTextReader(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderRead:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderReadAttributeValue:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderReadInnerXml:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderReadOuterXml:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderReadState:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderReadString:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstName:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstLocalName:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstEncoding:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstBaseUri:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstNamespaceUri:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstPrefix:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstValue:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstXmlLang:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderConstXmlVersion:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderDepth:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderExpand:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderGetAttribute:String(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlTextReaderGetAttributeNo:String(handle:Byte Ptr, index:Int)
	Function bmx_libxml_xmlTextReaderGetAttributeNs:String(handle:Byte Ptr, localName:String, namespaceURI:String)
	Function bmx_libxml_xmlTextReaderGetParserColumnNumber:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderGetParserLineNumber:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderGetParserProp:Int(handle:Byte Ptr, prop:Int)
	Function bmx_libxml_xmlTextReaderHasAttributes:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderHasValue:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderIsDefault:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderIsEmptyElement:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderIsNamespaceDecl:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderIsValid:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderLocalName:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderLookupNamespace:String(handle:Byte Ptr, prefix:String)
	Function bmx_libxml_xmlTextReaderMoveToAttribute:Int(handle:Byte Ptr, name:String)
	Function bmx_libxml_xmlTextReaderMoveToAttributeNo:Int(handle:Byte Ptr, index:Int)
	Function bmx_libxml_xmlTextReaderMoveToAttributeNs:Int(handle:Byte Ptr, localName:String, namespaceURI:String)
	Function bmx_libxml_xmlTextReaderMoveToElement:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderMoveToFirstAttribute:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderMoveToNextAttribute:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderName:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderNamespaceUri:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderNext:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderNodeType:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderNormalization:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderPrefix:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderPreserve:Byte Ptr(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderQuoteChar:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderRelaxNGValidate:Int(handle:Byte Ptr, rng:String)
	Function bmx_libxml_xmlTextReaderSchemaValidate:Int(handle:Byte Ptr, xsd:String)
	Function bmx_libxml_xmlTextReaderSetParserProp:Int(handle:Byte Ptr, prop:Int, value:Int)
	Function bmx_libxml_xmlTextReaderStandalone:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderValue:String(handle:Byte Ptr)
	Function bmx_libxml_xmlTextReaderXmlLang:String(handle:Byte Ptr)
	
	Function bmx_libxml_xmlNewCatalog:Byte Ptr(sgml:Int)
	Function bmx_libxml_xmlLoadACatalog:Byte Ptr(filename:String)
	Function bm_libxml_xmlLoadCatalog:Int(filename:String)
	Function bmx_libxml_xmlLoadSGMLSuperCatalog:Byte Ptr(filename:String)
	Function bmx_libxml_xmlCatalogSetDefaults(allow:Int)
	Function bmx_libxml_xmlCatalogGetDefaults:Int()
	Function bmx_libxml_xmlCatalogSetDebug:Int(level:Int)
	Function bmx_libxml_xmlCatalogSetDefaultPrefer:Int(prefer:Int)
	Function bmx_libxml_xmlCatalogAdd:Int(rtype:String, orig:String, rep:String)
	Function bmx_libxml_xmlCatalogConvert:Int()
	Function bmx_libxml_xmlCatalogRemove:Int(value:String)
	Function bmx_libxml_xmlCatalogResolve:String(pubID:String, sysID:String)
	Function bmx_libxml_xmlCatalogResolvePublic:String(pubID:String)
	Function bmx_libxml_xmlCatalogResolveSystem:String(sysID:String)
	Function bmx_libxml_xmlCatalogResolveURI:String(uri:String)
	Function bmx_libxml_xmlACatalogAdd:Int(handle:Byte Ptr, rtype:String, orig:String, rep:String)
	Function bmx_libxml_xmlACatalogRemove:Int(handle:Byte Ptr, value:String)
	Function bmx_libxml_xmlACatalogResolve:String(handle:Byte Ptr, pubID:String, sysID:String)
	Function bmx_libxml_xmlACatalogResolvePublic:String(handle:Byte Ptr, pubID:String)
	Function bmx_libxml_xmlACatalogResolveSystem:String(handle:Byte Ptr, sysID:String)
	Function bmx_libxml_xmlCatalogIsEmpty:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlConvertSGMLCatalog:Int(handle:Byte Ptr)
	Function bmx_libxml_xmlACatalogDump(handle:Byte Ptr, file:Int)
	Function bmx_libxml_xmlFreeCatalog(handle:Byte Ptr)

	Function bmx_libxml_xmldtdattribute_defaultValue:String(handle:Byte Ptr)

	Function bmx_libxml_xmldtdelement_etype:Int(handle:Byte Ptr)
	Function bmx_libxml_xmldtdelement_prefix:String(handle:Byte Ptr)

	Function bmx_libxml_xmlnotation_name:String(handle:Byte Ptr)
	Function bmx_libxml_xmlnotation_PublicID:String(handle:Byte Ptr)
	Function bmx_libxml_xmlnotation_SystemID:String(handle:Byte Ptr)

	Function bmx_libxml_xmlXPtrLocationSetAdd(handle:Byte Ptr, value:Byte Ptr)
	Function bmx_libxml_xmlXPtrLocationSetDel(handle:Byte Ptr, value:Byte Ptr)
	Function bmx_libxml_xmlXPtrLocationSetMerge:Byte Ptr(handle:Byte Ptr, value:Byte Ptr)
	Function bmx_libxml_xmlXPtrLocationSetRemove(handle:Byte Ptr, index:Int)
	Function bmx_libxml_xmlXPtrFreeLocationSet(handle:Byte Ptr)
	
	
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

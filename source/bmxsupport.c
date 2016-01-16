// Small support functions for BlitzMax
// Author: Thomas Mayer
// License: Public domain code

#include "unzip.h"
#include "zip.h"

int unzGetCurrentFileSize (unzFile* zipFile)
{
	unz_file_info	fileinfo;

	if (!zipFile)
		return;

	unzGetCurrentFileInfo ( zipFile, &fileinfo,
							0,
							0,
							0,
							0,
							0,
							0);
	return fileinfo.uncompressed_size;
}

int zipOpenNewFileWithPassword (file, filename, zipfi,
                                         extrafield_local, size_extrafield_local,
                                         extrafield_global, size_extrafield_global,
                                         comment, method, level,password)
    zipFile file;
    const char* filename;
    const zip_fileinfo* zipfi;
    const void* extrafield_local;
    uInt size_extrafield_local;
    const void* extrafield_global;
    uInt size_extrafield_global;
    const char* comment;
    int method;
    int level;
    const char* password;
{
	return zipOpenNewFileInZip3(file,filename,zipfi,extrafield_local,size_extrafield_local,extrafield_global,size_extrafield_global,comment,method,level,0, -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY,password, 0);
}




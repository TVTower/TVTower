// Small support functions for BlitzMax
// Author: Thomas Mayer
// License: Public domain code

#include "unzip.h"
#include "zip.h"
#include <time.h>
#include <utime.h>
#include <errno.h>

#include "brl.mod/blitz.mod/blitz.h"

int bmx_set_file_mod_date_time(const char* filename, int hour, int min, int sec, int day, int month, int year) {
	struct tm file_date_time;
	file_date_time.tm_sec = sec;
	file_date_time.tm_min = min;
	file_date_time.tm_hour = hour;
	file_date_time.tm_mday = day;
	file_date_time.tm_mon = (month - 1);
	file_date_time.tm_year = (year - 1900);
	file_date_time.tm_isdst = -1;
	
	time_t t_mod = mktime(&file_date_time);

	struct utimbuf	tm_buf;

	tm_buf.actime = t_mod;
	tm_buf.modtime = t_mod;
	
	int success = utime(filename, &tm_buf);
	
	return (success == 0 ? 0 : errno);
}

int unzGetCurrentFileSize (unzFile* zipFile)
{
	unz_file_info	fileinfo;

	if (!zipFile) {
		return 0;
	}

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
                                         comment, method, level, password, crcForCrypting)
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
    BBInt64 crcForCrypting;
{
	return zipOpenNewFileInZip3(file,filename,zipfi,extrafield_local,size_extrafield_local,extrafield_global,size_extrafield_global,comment,method,level,0, -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, password, crcForCrypting);
}

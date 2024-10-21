#include "blitz.h"

#define XXH_STATIC_LINKING_ONLY
#include "hash/xxhash.h"

BBULONG bbSubStringHash( BBSTRING x, BBINT start, BBINT length ) {
    return XXH3_64bits(x->buf + start, length * sizeof(BBChar));
}


BBULONG bbSubAsciiStringHashLC( BBSTRING x, BBINT start, BBINT length ) {
    if (start < 0 || length <= 0 || start + length > x->length)
        return 0;

	// convert buffer part to lower case (ASCII ONLY!)
	int bytes = length * sizeof(BBChar);
	BBChar* lowerCaseBuf = (BBChar*) malloc(bytes);

	for(int k = 0; k < length; ++k ) {
		lowerCaseBuf[k] = 0x20 | x->buf[k + start];
	}

	BBULONG result = XXH3_64bits(lowerCaseBuf, length * sizeof(BBChar));

	free(lowerCaseBuf);
	
	return result;
}


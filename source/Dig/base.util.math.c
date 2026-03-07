/*
 	====================================================================
	Math helper class
	====================================================================

	Various helpers to work with numbers.


	====================================================================
	If not otherwise stated, the following code is available under the
	following licence:

	LICENCE: zlib/libpng

	Copyright (C) 2026 Ronny Otto, digidea.de

	This software is provided 'as-is', without any express or
	implied warranty. In no event will the authors be held liable
	for any	damages arising from the use of this software.

	Permission is granted to anyone to use this software for any
	purpose, including commercial applications, and to alter it
	and redistribute it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented; you
	   must not claim that you wrote the original software. If you use
	   this software in a product, an acknowledgment in the product
	   documentation would be appreciated but is not required.

	2. Altered source versions must be plainly marked as such, and
	   must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source
	   distribution.
	====================================================================
*/
#include <brl.mod/blitz.mod/blitz.h>
#include <stdint.h>
#include <math.h>



/* Pow10 lookup */
static const int64_t POW10[] = {1LL,10LL,100LL,1000LL,10000LL,100000LL,1000000LL,10000000LL,100000000LL};

/* Digit-Pair Table */
static const char DIGITS[201] =
"00010203040506070809"
"10111213141516171819"
"20212223242526272829"
"30313233343536373839"
"40414243444546474849"
"50515253545556575859"
"60616263646566676869"
"70717273747576777879"
"80818283848586878889"
"90919293949596979899";

/* --- internal function --- */
static size_t digNumberToBuffer(double value, int decimals, int truncateZeros, int decimalSeparatorChar, char* buffer) {
	if (decimals < 0) decimals = 0;
	if (decimals > 8) decimals = 8;
	const int64_t pow = POW10[decimals];

	int64_t integer = (int64_t)value;
	double frac = value - (double)integer;
	if (frac < 0) {
		frac = -frac;
	}
	int64_t fracInt = (int64_t)(frac * pow + 0.5);

	if (fracInt >= pow) {
		integer += (value >= 0 ? 1 : -1);
		fracInt -= pow;
	}

	char* p = buffer;

	int negative = (value < 0);
	if (negative) {
		*p++ = '-'; 
		integer = -integer;
	}

	/* integer part */
	char tmpint[32];
	char* t = tmpint+32;
	while (integer >= 100) {
		int64_t q = integer / 100;
		int r = (int)(integer - q * 100);
		int i = r * 2;
		integer = q;

		/* digits lookup - write right to left */
		*--t = DIGITS[i+1];
		*--t = DIGITS[i];
	}
	if (integer<10) {
		*--t = '0' + integer;
	} else {
		int i = integer * 2;
		/* digits lookup - write right to left */
		*--t = DIGITS[i+1];
		*--t = DIGITS[i];
	}
	while (t < tmpint + 32) {
		*p++ = *t++;
	}

	/* decimal part */
	if (decimals>0) {
		char* dot = p++;
		*dot = (char)decimalSeparatorChar;
		int64_t f = fracInt;
		char buf[16];
		int len = decimals;
		for (int i = decimals - 1; i > 0; i -= 2) {
			int64_t q = f / 100;
			int d = (int)(f - q * 100);
			f = q;
			buf[i-1] = DIGITS[d*2];
			buf[i] = DIGITS[d*2+1];
		}
		if (decimals % 2 == 1) {
			buf[0] = '0' + (int)(f % 10);
		}

		if (truncateZeros) {
			while (len && buf[len-1]=='0') {
				len--;
			}
		}

		for (int i = 0; i < len; i++) {
			*p++ = buf[i];
		}
		if (len==0) {
			p = dot;
		}
	}

	return (size_t)(p - buffer);
}


BBString* digNumberToString(double value, int decimals, int truncateZeros, int decimalSeparatorChar) {
	char tmp[64];
	size_t sz = digNumberToBuffer(value, decimals, truncateZeros, decimalSeparatorChar, tmp);
	BBString* str = bbStringNew(sz);
	for (size_t i = 0; i < sz; i++) {
		str->buf[i] = (BBChar)tmp[i];
	}
	return str;
}


BBString* digNumberToDottedValue(double value, int thousandsSeparatorChar, int decimalSeparatorChar, int decimals, int truncateZeros){
	char tmp[64];
	size_t len = digNumberToBuffer(value, decimals, truncateZeros, decimalSeparatorChar, tmp);

	/* Count amount of required thousands separators */
	size_t intLen = 0;
	size_t start = 0;
	/* skip sign */
	if (tmp[0] == '-') {
		start = 1;
	}
	for (size_t i = start; i < len && tmp[i] != decimalSeparatorChar; i++) {
		intLen++;
	}

	size_t nSep = (intLen > 3) ? (intLen - 1) / 3 : 0;
	size_t newLen = len + nSep;
	BBString* str = bbStringNew(newLen);
	BBChar* out = str->buf;

	/* write sign */
	size_t idx = 0;
	if (start) {
		out[idx++] = tmp[0];
	}

	/* Write integer part including thousands separators */
	for (size_t i = 0; i < intLen; i++) {
		if (i > 0 && (intLen - i) % 3 == 0) {
			out[idx++] = (BBChar)thousandsSeparatorChar;
		}
		out[idx++] = (BBChar)tmp[start + i];
	}

	/* Rest (decimal) */
	for (size_t i = start + intLen; i < len; i++) {
		out[idx++] = (BBChar)tmp[i];
	}

	return str;
}



/* return amount of digits for the given Long */
int digLongDigitCount(int64_t v){
	uint64_t x = (v < 0) ? (uint64_t)(-(int64_t)v) : (uint64_t)v;

	if (x >= 1000000000000000000ULL) return 19;
	if (x >= 100000000000000000ULL)  return 18;
	if (x >= 10000000000000000ULL)   return 17;
	if (x >= 1000000000000000ULL)    return 16;
	if (x >= 100000000000000ULL)     return 15;
	if (x >= 10000000000000ULL)      return 14;
	if (x >= 1000000000000ULL)       return 13;
	if (x >= 100000000000ULL)        return 12;
	if (x >= 10000000000ULL)         return 11;
	if (x >= 1000000000ULL)          return 10;
	if (x >= 100000000ULL)           return 9;
	if (x >= 10000000ULL)            return 8;
	if (x >= 1000000ULL)             return 7;
	if (x >= 100000ULL)              return 6;
	if (x >= 10000ULL)               return 5;
	if (x >= 1000ULL)                return 4;
	if (x >= 100ULL)                 return 3;
	if (x >= 10ULL)                  return 2;
	return 1;
}


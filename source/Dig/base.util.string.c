#include <brl.mod/blitz.mod/blitz.h>

BBString *digStringJoinInts( BBArray *bits, BBString *sep ) {
	int i, sz = 0;
	int n_bits = bits->scales[0];
	int *p, v;
	BBString *str;
	BBChar *t;

	if( bits == &bbEmptyArray ){
		return &bbEmptyString;
	}

	// calc size
	p = (int*)BBARRAYDATA( bits, 1 );
	for( i = 0; i < n_bits; ++i ){
		v = *p++;

		if( v == 0 ){
			sz += 1;
			continue;
		}

		if( v < 0 ){
			sz++;       // '-', negative
			v = -v;
		}

		while( v ){
			sz++;
			v /= 10;
		}
	}

	sz += (n_bits - 1) * sep->length;


	// create/prepare string
	str = bbStringNew( sz );
	t = str->buf;

	// write into it (reset pointer first)
	p = (int*)BBARRAYDATA( bits, 1 );
	for( i = 0; i < n_bits; ++i ) {
		if( i ) {
			memcpy( t, sep->buf, sep->length * sizeof(BBChar) );
			t += sep->length;
		}

		v = *p++;

		/* backwards writing of numbers */
		int start = 0;

		if( v == 0 ) {
			*t++ = '0';
			continue;
		}

		if( v < 0 ) {
			*t++ = '-';
			v = -v;
		}

		BBChar tmp[16];   // array must be big enough for a 32 bit integer
		int n = 0;

		while( v ) {
			tmp[n++] = '0' + (v % 10);
			v /= 10;
		}

		while( n-- ) {
			*t++ = tmp[n];
		}
	}

	return str;
}


BBString *JoinIntArray2( BBArray *bits, BBString *sep ) {
	int n = bits->scales[0];
	if( !n || bits == &bbEmptyArray ) {
		return &bbEmptyString;
	}

	int i;
	int sz = (n - 1) * sep->length;
	int *p = (int*)BBARRAYDATA(bits, 1);

	for( i=0; i<n; ++i ) {
		sz += snprintf(NULL, 0, "%d", p[i]);
	}

	BBString *str = bbStringNew(sz);
	BBChar *t = str->buf;

	for( i=0; i<n; ++i ) {
		if( i ) {
			memcpy(t, sep->buf, sep->length * sizeof(BBChar));
			t += sep->length;
		}
		t += snprintf((char*)t, sz - (t - str->buf), "%d", p[i]);
	}

	return str;
}

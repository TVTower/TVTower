#include "time.h"
#include <sys/time.h>
#include <brl.mod/blitz.mod/blitz.h>

BBLONG MilliSecsLong(void) {
    struct timeval tv;
    gettimeofday( &tv, NULL );
    return (( (BBLONG)tv.tv_sec )*1000 )+( tv.tv_usec/1000 );
    /*return (( (long)tv.tv_sec )*1000 )*/;
}
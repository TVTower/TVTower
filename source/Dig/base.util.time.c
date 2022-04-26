#include "time.h"
#include <sys/time.h>

long MilliSecsLong(void) {
    struct timeval tv;
    gettimeofday( &tv, NULL );
    return (( (long)tv.tv_sec )*1000 )+( tv.tv_usec/1000 );
    /*return (( (long)tv.tv_sec )*1000 )*/;
}
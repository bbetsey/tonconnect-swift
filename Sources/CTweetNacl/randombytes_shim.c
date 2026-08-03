/* Hand-written shim for the TonConnect package (not part of tweetnacl).
   Provides the `randombytes` symbol tweetnacl.c links against and a
   function-pointer seam (tc_set_randombytes) so Swift chooses the source. */
#include "randombytes_shim.h"
#include <stdlib.h>   /* abort() */

static RandomBytesFn currentImpl = 0;

void tc_set_randombytes(RandomBytesFn fn) {
    currentImpl = fn;
}

void randombytes(unsigned char *buf, unsigned long long len) {
    if (currentImpl == 0) {
        /* No source installed: fail loudly, never silently.
           Swift registers the implementation before first use. */
        abort();
    }
    currentImpl(buf, len);
}

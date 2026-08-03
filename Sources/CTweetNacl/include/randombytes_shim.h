/* Hand-written shim for the TonConnect package (not part of tweetnacl).
   tweetnacl.c declares `extern void randombytes(u8 *, u64)` and calls it
   from crypto_box_keypair — this header exposes the seam through which
   Swift installs the actual implementation. */
#ifndef RANDOMBYTES_SHIM_H
#define RANDOMBYTES_SHIM_H

typedef void (*RandomBytesFn)(unsigned char *buf, unsigned long long len);

void tc_set_randombytes(RandomBytesFn fn);

/* Exposed so Swift can draw nonce bytes through the same seam as keypair. */
void randombytes(unsigned char *buf, unsigned long long len);

#endif

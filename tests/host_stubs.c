/*
 * host_stubs.c - what the host test builds need besides the core: no filesystem (the ROM is fed
 * as a buffer), no yx5200 MP3 cartridge. crc32, _ctype_, setjmp and memcpy come from glibc and
 * zlib. GPGX's file I/O paths are optional and unused.
 *
 * Copyright (c) 2026 TheGammaSqueeze. Part of genesis-plus-gx-pico, under the Genesis Plus GX
 * licence (LICENSE).
 */
typedef unsigned long usize;
void *filestream_open(const char*p,unsigned m,unsigned h){(void)p;(void)m;(void)h;return 0;}
long filestream_read(void*f,void*b,long n){(void)f;(void)b;(void)n;return 0;}
long filestream_write(void*f,const void*b,long n){(void)f;(void)b;(void)n;return 0;}
long filestream_seek(void*f,long o,int w){(void)f;(void)o;(void)w;return -1;}
long filestream_tell(void*f){(void)f;return -1;}
int filestream_close(void*f){(void)f;return -1;}
char *filestream_gets(void*f,char*b,unsigned n){(void)f;(void)b;(void)n;return 0;}
void filestream_vfs_init(const void*i){(void)i;}
void *rfopen(const char*p,const char*m){(void)p;(void)m;return 0;}
long rfread(void*b,long s,long n,void*f){(void)b;(void)s;(void)n;(void)f;return 0;}
long rfwrite(const void*b,long s,long n,void*f){(void)b;(void)s;(void)n;(void)f;return 0;}
int rfseek(void*f,long o,int w){(void)f;(void)o;(void)w;return -1;}
long rftell(void*f){(void)f;return -1;}
int rfclose(void*f){(void)f;return -1;}
char *rfgets(char*b,int n,void*f){(void)b;(void)n;(void)f;return 0;}
void yx5200_init(void){} void yx5200_reset(void){}
void yx5200_write(unsigned a,unsigned d){(void)a;(void)d;}
int yx5200_update(int*b,int n){(void)b;(void)n;return 0;}
int yx5200_context_save(unsigned char*s){(void)s;return 0;}
int yx5200_context_load(unsigned char*s){(void)s;return 0;}
usize strlcpy_retro__(char*d,const char*s,usize n){usize i=0;if(n){while(i<n-1&&s[i]){d[i]=s[i];i++;}d[i]=0;}while(s[i])i++;return i;}
usize strlcat_retro__(char*d,const char*s,usize n){usize l=0;while(l<n&&d[l])l++;return l+strlcpy_retro__(d+l,s,n>l?n-l:0);}
usize fill_pathname_join(char*o,const char*a,const char*b,usize n){usize l=strlcpy_retro__(o,a,n);if(l&&l<n&&o[l-1]!='/'){o[l++]='/';o[l]=0;}return strlcat_retro__(o,b,n);}

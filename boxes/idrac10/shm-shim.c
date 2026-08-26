/*
 * shm-shim2.c — LD_PRELOAD shim for iDRAC10 fullfw on NPCM845 QEMU
 *
 * PROBLEM: shmget() and semget() block/hang on npcm845-evb QEMU due to kernel
 *          lock contention with /dev/shm tmpfs. iDRAC10's libshareddata.so uses
 *          SYSV SHM (shmget/shmat) for the Dell Shared Data Cache (SDC) between
 *          processes (fullfw, AIM, etc.). Without these working, fullfw exits.
 *
 * FIX:
 *   shmget  → file-backed mmap at /tmp/shmshim-<key_hex>  (size-agnostic filename)
 *   shmat   → mmap the backing file; returns aligned pointer
 *   shmdt   → munmap
 *   shmctl  → IPC_RMID = unlink file; IPC_STAT = synthesize; else nop
 *   semget  → returns fake semid (file-based token); no actual kernel semaphore
 *   semop   → nop (no blocking; SHM semaphores are used for mutual exclusion only)
 *   semctl  → nop for SETVAL/GETVAL; returns 0
 *   Dell_shm_memread / Dell_shm_memread_unlocked → zero-fill buf, skip section-size check
 *   Dell_shm_memwrite / Dell_shm_memset → nop (writes go to mmap anyway via shmat)
 *   Dell_shm_get_shm → return static zero buffer
 *   CfgGetAttribute* → return 0 (success) with empty/zero defaults
 *   dlopen → strip RTLD_DEEPBIND so LD_PRELOAD hooks work inside dlopen'd libs
 *
 * NOTE: semaphores are only used for SHM access control. Since we're running
 *       single-threaded init, skipping them is safe for the boot phase.
 */
#define _GNU_SOURCE
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>
#include <stddef.h>
#include <dlfcn.h>
#include <pthread.h>
#include <time.h>
#include <signal.h>
#include <ucontext.h>


/* Max tracked segments */
#define MAX_SEGS 64
#define MAX_SEMS 64
#define SHM_DIR  "/tmp"

typedef struct {
    key_t   key;
    int     shmid;       /* our fake shmid = index+1 */
    size_t  size;
    void   *mapped;
    char    path[128];
} seg_t;

static seg_t segs[MAX_SEGS];
static int   nseg = 0;
static int   nsem = 0;  /* fake semid counter */
static FILE *log_fp = NULL;
static volatile unsigned long _libsess_base = 0;  /* cached by dumper; read by crash_handler */
static void crash_handler(int sig, siginfo_t *si, void *uc);  /* fwd decl */
static volatile int mu_lock = 0;

/*
 * NON-INTERPOSING observer: G_sUserTable is an EXPORTED libsess.so.9 symbol
 * (0x32b10). Instead of interposing PSMgrReadAttr (which destabilizes fullfw
 * init), a detached thread dlsym's the table and dumps each slot's 16-byte
 * UserName field directly from live memory. This finally shows whether "root"
 * reaches entry+0x00 (the thing gating RAKP2 0x0d). Only fires in processes
 * where libsess is loaded (fullfw); elsewhere dlsym returns NULL and it exits.
 * Layout: G_sUserTable{ ..., count@+8 (u32), entries@+0x10 (ptr) }, stride 0x3d,
 * UserName@+0x00 (16B), priv@+0x10, pwd@+0x11.
 */
/* Find the lowest mapped base of a library by scanning /proc/self/maps.
 * Scope-independent (works even when the lib is dlopen'd RTLD_LOCAL, where
 * dlsym(RTLD_DEFAULT,...) returns NULL). Returns 0 if not mapped. */
static unsigned long lib_base(const char *needle) {
    FILE *m = fopen("/proc/self/maps", "r");
    if (!m) return 0;
    char line[512]; unsigned long best = 0;
    while (fgets(line, sizeof line, m)) {
        if (strstr(line, needle)) {
            unsigned long a = strtoul(line, NULL, 16);
            if (a && (best == 0 || a < best)) best = a;
        }
    }
    fclose(m);
    return best;
}

/*
 * UserInfoGetMaxUserNumber (libsess 0x104c0, called by UserInfoInit + the
 * user-config loader via GOT 0x32390 -> interposable). The real fn returns a
 * global byte that is 0 in this virtual env, so the IPMI user count is 0:
 * UserInfoInit allocates a 0-slot table AND the loader's `for i in 0..count`
 * never runs -> G_sUserTable stays empty -> RAKP1 finds no user -> 0x0d.
 * Return 16 so the real init allocates 16 slots and the loader populates each
 * from cfgmgrd (Users.N#UserName etc.) with all fields correct — the proper
 * fix, vs. hand-injecting a partial table that crashes the RAKP2 stage.
 */
int UserInfoGetMaxUserNumber(void) {
    if (log_fp) { fprintf(log_fp, "[shim2] UserInfoGetMaxUserNumber -> 16\n"); fflush(log_fp); }
    return 16;
}

/*
 * UserInfoGetChannelAccess (libsess 0x10030, exported global, called via PLT
 * 0x7430 from RSSPOnSMWaitRAKP1StateRecvRAKP1 -> interposable). This IS the
 * real RAKP2 0x0a gate (not a raw entry+0x25 byte, as earlier notes claimed):
 *   17a70: bl UserInfoGetChannelAccess ; 17a74: ands w0,w0,#0xf ; b.eq -> 0x0a
 * The real fn does `ldrb w0,[x1,#0x25]; and w0,w0,#0x7f` where x1 is located via
 * INTERNAL tables (x2+0x208), NOT our injected G_sUserTable slot — so seeding
 * +0x25 in our entry can never satisfy it. Return 0x04 (Admin): low nibble 4
 * (!=0) clears the 0x0a gate; bit6 clear takes the good path that stores priv=4
 * as the session privilege (-> RAKP4 / Admin session).
 */
/* Factory IPMIKey, first 20 bytes = the RAKP HMAC key (shared with zipmi -K). */
static const unsigned char FKM[20] = {
    0x91,0x5F,0x32,0xF4,0x9A,0x97,0x45,0x6D,0x0D,0x6D,
    0x66,0xEE,0xE5,0xED,0x84,0xC8,0x94,0xB4,0x14,0xAF
};

int UserInfoGetChannelAccess(int channel, int arg2) {
    typedef int (*fn_t)(int, int);
    static fn_t real_fn = 0;
    if (!real_fn) real_fn = (fn_t)dlsym(RTLD_NEXT, "UserInfoGetChannelAccess");
    int real = real_fn ? real_fn(channel, arg2) : 0;
    /* Two RAKP2 0x0a gates read this in RSSPOnSMWaitRAKP1StateRecvRAKP1:
     *   (a) 0x17a74  ands #0xf; b.eq 0x0a  -> low nibble (priv) must be nonzero
     *   (b) 0x17ab4  tbnz w0,#6, 0x177fc   -> bit6 SET diverts off the good path
     * The cfgmgrd-loaded entry returns 0x44 (bit6 set) -> trips (b) -> 0x0a. The
     * injected table (0x04, bit6 clear) reached RAKP4. So CLEAR bit6, and inject
     * Admin(4) if the priv nibble is 0. Preserve everything else (don't blanket
     * to 0x04 — that clobbered LAN init and silenced RMCP in run138). */
    int v = real & ~0x40;                                  /* clear bit6 → passes gate (b) */
    int ret = ((v & 0xf) == 0) ? ((v & 0xf0) | 0x04) : v;  /* ensure nonzero priv nibble → gate (a) */
    if (log_fp) { fprintf(log_fp, "[shim2] UserInfoGetChannelAccess(ch=%d,a=%d) real=0x%02x -> 0x%02x\n", channel, arg2, real, ret); fflush(log_fp); }
    return ret;
}

/*
 * UserInfoSearchByNameAndPriv (libsess 0xfeb0, exported, PLT 0x74e0). RAKP1 uses
 * its return at 0x177bc: `cmp w19,#0xff; b.eq 0x0d`. The real fn MemCmp's the
 * 16-byte name then priv-matches on entry+0x25 read DIRECTLY from memory (0xff48
 * ldrb [x20,#0x25]) — which my GetChannelAccess interpose can't touch. On the
 * cfgmgrd table that priv-match intermittently fails -> 0xff -> 0x0d. Force a
 * valid index (root = uid 2) when the real fn can't find our user, so RAKP1's
 * name gate passes deterministically; the RAKP2 priv gates are handled by the
 * GetChannelAccess interpose above. Signature: (channel, name*, 0) -> index.
 */
int UserInfoSearchByNameAndPriv(int channel, void *name, int zero) {
    typedef int (*fn_t)(int, void *, int);
    static fn_t real_fn = 0;
    if (!real_fn) real_fn = (fn_t)dlsym(RTLD_NEXT, "UserInfoSearchByNameAndPriv");
    int real = real_fn ? real_fn(channel, name, zero) : 0xff;
    int ret = ((real & 0xff) == 0xff) ? 2 : real;   /* not-found -> root uid 2 */
    if (log_fp) { fprintf(log_fp, "[shim2] UserInfoSearchByNameAndPriv(ch=%d) real=0x%02x -> %d\n", channel, real & 0xff, ret); fflush(log_fp); }
    return ret;
}

/*
 * UserInfoGetUserHashPWD (libsess 0x10274, exported, PLT 0x7150) — THE RAKP2 key
 * gate. RSSPOnSMWaitRAKP1 calls it as (uid, name, len=0x14, outbuf=session+0x13)
 * to load the user's 20-byte HMAC key, then `ldrb [session+0x13]; cbnz good` —
 * a zero key -> 0x0a. More importantly, whatever key lands in outbuf is what the
 * BMC uses to compute the RAKP2 HMAC, so writing OUR factory-IPMIKey (FKM, first
 * 20 bytes) makes the BMC's HMAC match the zipmi client (-K FKM) -> RAKP2 auth
 * succeeds -> RAKP4 -> established session. Write FKM, return success. */
int UserInfoGetUserHashPWD(int uid, void *name, int len, void *outbuf) {
    (void)name;
    if (outbuf && len >= 20) memcpy(outbuf, FKM, 20);
    if (log_fp) { fprintf(log_fp, "[shim2] UserInfoGetUserHashPWD(uid=%d,len=%d) -> wrote FKM(20)\n", uid, len); fflush(log_fp); }
    return 0;
}

/* Crash-proof mem access via /proc/self/mem: pread/pwrite return -1 on a
 * bad/unmapped address instead of SIGSEGV, so wrong offsets can't kill fullfw. */
static int mem_read(int fd, unsigned long addr, void *dst, size_t n) {
    return pread(fd, dst, n, (off_t)addr) == (ssize_t)n ? 0 : -1;
}
static int mem_write(int fd, unsigned long addr, const void *src, size_t n) {
    return pwrite(fd, src, n, (off_t)addr) == (ssize_t)n ? 0 : -1;
}

/*
 * G_sUserTable INJECTOR. Ground truth (run81): the table is never populated
 * (count=0, entries=NULL) — UserInfoInit's chain doesn't run in this virtual
 * env, so RAKP1 searches an empty table -> 0x0d. Rather than chase the whole
 * IPMI init chain, build a populated table in-process and splice it into
 * G_sUserTable directly:
 *   G_sUserTable{ count@+8 (u32), entries@+0x10 (ptr) }, stride 0x3d,
 *   slot fields: UserName@+0x00 (16B), priv@+0x10, pwd/Km@+0x11 (20B).
 *   slot i corresponds to IPMI user (i+1); root = Users.2 => slot 1.
 * Also set the present bitmap G_pu8UserAccessNewDesign (GOT 0x321d0 -> ptr)[slot]=1
 * so UserInfoSearchByNameAndPriv doesn't take the "disabled" exit.
 * Idempotent: only injects when count is still 0 (real init never fills it).
 */
#define UT_SLOTS 16
#define UT_STRIDE 0x3d
static unsigned char _ut_buf[UT_SLOTS * UT_STRIDE];   /* stays alive (static) */

static void *usertable_dumper(void *arg) {
    (void)arg;
    int misses = 0, announced = 0, injected = 0;
    int mfd = open("/proc/self/mem", O_RDWR);
    if (mfd < 0) return NULL;
    for (int round = 0; round < 240; round++) {
        struct timespec ts = {1, 0};   /* 1s: enforce content without starving RMCP handler */
        /* Reclaim SIGSEGV/ABRT/BUS/ILL: fullfw installs its own handlers during
         * init, overriding ours. Re-install every round so ours is active when
         * the RAKP2-stage fault fires and can log the PC. */
        if ((round % 5) == 0) { struct sigaction sa; memset(&sa,0,sizeof sa);
          sa.sa_sigaction = crash_handler; sa.sa_flags = SA_SIGINFO;
          sigaction(SIGSEGV,&sa,NULL); sigaction(SIGABRT,&sa,NULL);
          sigaction(SIGBUS,&sa,NULL); sigaction(SIGILL,&sa,NULL); }
        unsigned long base = lib_base("libsess.so.9");
        if (!base) { (void)misses; continue; }  /* keep polling: libsess may load late / in a forked worker; never give up so EVERY libsess process gets injected */
        _libsess_base = base;   /* cache for the crash handler */

        /* NOTE: do NOT patch UserInfoGetMaxUserNumber->16. That activates the real
         * UserInfoInit + user-config loader, which then actively manages the
         * entries buffer and overwrites our injected "root" with empty names
         * (run102/103 -> 0x0d). Leaving max-users=0 keeps the real loader dormant
         * so our private _ut_buf (installed below) is uncontested (run95 config). */
        unsigned long tbl = base + 0x32b10;   /* G_sUserTable */
        /* No LoadUserConfig patch: runs 112/113 proved neutering it cleans the
         * name but deterministically breaks fullfw init (needed at boot). The
         * "roo\0" corruption is instead fixed at its source — the cfgmgrd seed's
         * AttributeMemSize for Users.2#UserName bumped 4->16 (size-1 truncation
         * copied only "roo"). LoadUserConfig now reads the full "root". */
        if (log_fp && !announced) { announced = 1; fprintf(log_fp, "[dump] libsess base=0x%lx pid=%d\n", base, (int)getpid()); fflush(log_fp); }
        unsigned int count = 0; unsigned long entries = 0;
        if (mem_read(mfd, tbl + 8, &count, 4) || mem_read(mfd, tbl + 0x10, &entries, 8)) continue;

        /* Self-healing: (re)inject whenever the table isn't ours. The real
         * UserInfoInit can run AFTER our first injection (with max-users still 0)
         * and reset count->0, leaving the table empty for the rest of the run
         * (the run95->run96 flakiness). Re-assert our table every round. */
        /* Point the table's entries at our PRIVATE _ut_buf + count=16 when the
         * table isn't ours; THEN, every round, rewrite the root name/key/access
         * fields into the slots. The firmware intermittently corrupts the name
         * (zeroes byte 3: "root"->"roo\0") — rewriting every round repairs it
         * within 1s. Only field writes (never a full memset), so no zero-window. */
        if (round >= 2) {
            int ours = (count == UT_SLOTS && entries == (unsigned long)_ut_buf);
            /* Install-once ONLY. Per-round content re-writes into the live _ut_buf
             * race the RAKP handler's concurrent read of the same buffer and KILL
             * fullfw (runs 108-110: all-timeout, SoftTimer gone). So write content
             * exactly once, on (re)install. KNOWN LIMITATION: the firmware then
             * intermittently zeroes username byte 3 ("root"->"roo\0") and we can't
             * safely repair it -> intermittent 0x0d. Proper fix = patch the
             * firmware corruptor (RE the writer of entry+0x03). */
            /* Inject ONLY as a fallback when the real table is unpopulated. Once
             * cfgmgrd + GetMaxUserNumber=16 fill the real table (count>0, a real
             * entries buffer), DON'T clobber it: the old self-heal re-injected
             * _ut_buf every round and ping-ponged with LoadUserConfig's reload,
             * causing the intermittent 0x0d/0x0a flapping (live box, single fullfw). */
            int real_populated = (count > 0 && entries != 0 && entries != (unsigned long)_ut_buf);
            if (!ours && !real_populated) {
                for (int slot = 1; slot < UT_SLOTS; slot++) {
                    unsigned char *s = _ut_buf + slot * UT_STRIDE;
                    memcpy(s + 0x00, "root", 4);
                    s[0x10] = 0x14;
                    memcpy(s + 0x11, FKM, 20);
                    /* Per-channel UserChannelAccess @+0x25..+0x34 (16 channels) =
                     * admin. NB: filling past +0x34 into the entry tail (+0x35..)
                     * broke fullfw init (runs 126-130 all failed to bring RMCP up),
                     * so those bytes DO matter to the firmware — keep them zero. */
                    for (int c = 0; c < 16; c++) s[0x25 + c] = 0x04;
                }
                unsigned long ebuf = (unsigned long)_ut_buf; unsigned int nc = UT_SLOTS;
                mem_write(mfd, tbl + 0x10, &ebuf, 8);   /* entries -> our buffer */
                mem_write(mfd, tbl + 8, &nc, 4);        /* count = 16 */
                /* present bitmap G_pu8UserAccessNewDesign (GOT 0x321d0 -> &var ->
                 * array); search derefs [*var + uid]. Ensure array[1..15]=1; install
                 * our own if var is NULL. (Writing 0x01 over the pointer itself was
                 * the run85 crash: 0x0101010101010101 -> deref segfault.) */
                static unsigned char _ut_bmp[UT_SLOTS];
                unsigned long varaddr = 0, arrayptr = 0;
                mem_read(mfd, base + 0x321d0, &varaddr, 8);
                if (varaddr) mem_read(mfd, varaddr, &arrayptr, 8);
                if (!arrayptr) {
                    memset(_ut_bmp, 1, sizeof _ut_bmp); _ut_bmp[0] = 0;
                    unsigned long p = (unsigned long)_ut_bmp;
                    if (varaddr) mem_write(mfd, varaddr, &p, 8);
                } else {
                    unsigned char ones[UT_SLOTS]; memset(ones, 1, sizeof ones); ones[0] = 0;
                    mem_write(mfd, arrayptr, ones, UT_SLOTS);
                }
                injected++;
                if (log_fp && injected <= 3) { fprintf(log_fp, "[inject] (re)install prev_count=%u prev_entries=0x%lx -> our_buf=0x%lx\n", count, entries, (unsigned long)_ut_buf); fflush(log_fp); }
            }
        }
        if (log_fp && (round % 15) == 0) {
            /* read back the LIVE table: what does the RAKP search actually see?
             * re-read count/entries fresh, then slot1's 16-byte name. */
            unsigned int c2 = 0; unsigned long e2 = 0; unsigned char nm[16] = {0}, uca[16] = {0}, pv = 0;
            mem_read(mfd, tbl + 8, &c2, 4); mem_read(mfd, tbl + 0x10, &e2, 8);
            if (e2) { mem_read(mfd, e2 + UT_STRIDE + 0x00, nm, 16);
                      mem_read(mfd, e2 + UT_STRIDE + 0x10, &pv, 1);
                      mem_read(mfd, e2 + UT_STRIDE + 0x25, uca, 16); }
            fprintf(log_fp, "[dump] r=%d count=%u slot1name='", round, c2);
            for (int j=0;j<16;j++){unsigned char ch=nm[j];fprintf(log_fp,"%c",(ch>=32&&ch<127)?ch:'.');}
            fprintf(log_fp, "' +0x10=%02x UserChanAccess=", pv);
            for (int j=0;j<8;j++) fprintf(log_fp,"%02x",uca[j]);
            fprintf(log_fp, " reinjects=%d\n", injected); fflush(log_fp);
        }
    }
    close(mfd);
    return NULL;
}

/* Crash locator: catch fullfw's fault from inside the process and log the
 * faulting PC (async-signal-safe raw write). _libsess_base (declared near
 * log_fp) is cached by the dumper thread so the handler needs no fopen/malloc.
 * pc - base = offset into libsess.so.9, mappable to the exact function. */
static void put_hex(char *b, int *p, unsigned long v) {
    b[(*p)++]='0'; b[(*p)++]='x';
    int started=0;
    for (int i=60;i>=0;i-=4){ int d=(v>>i)&0xf; if(d||started||i==0){b[(*p)++]="0123456789abcdef"[d];started=1;} }
}
static void crash_handler(int sig, siginfo_t *si, void *uc) {
    ucontext_t *u = (ucontext_t *)uc;
    unsigned long pc = (unsigned long)u->uc_mcontext.pc;
    unsigned long base = _libsess_base;
    char b[160]; int p=0;
    const char *m="[CRASH] sig="; while(*m) b[p++]=*m++;
    b[p++]='0'+(sig%10);
    m=" pc="; while(*m)b[p++]=*m++; put_hex(b,&p,pc);
    m=" off="; while(*m)b[p++]=*m++; put_hex(b,&p,base?pc-base:0);
    m=" addr="; while(*m)b[p++]=*m++; put_hex(b,&p,(unsigned long)si->si_addr);
    b[p++]='\n';
    int fd=open("/tmp/crash.log",O_CREAT|O_WRONLY|O_APPEND,0644);
    if(fd>=0){ if(write(fd,b,p)<0){} close(fd);}
    signal(sig,SIG_DFL); raise(sig);
}

static void __attribute__((constructor)) shim_init(void) {
    log_fp = fopen("/tmp/shim-calls.log", "a");
    struct sigaction sa; memset(&sa,0,sizeof sa);
    sa.sa_sigaction = crash_handler; sa.sa_flags = SA_SIGINFO;
    sigaction(SIGSEGV,&sa,NULL); sigaction(SIGABRT,&sa,NULL);
    sigaction(SIGBUS,&sa,NULL); sigaction(SIGILL,&sa,NULL);
    if (log_fp) { fprintf(log_fp, "[shim2] constructor: loaded pid=%d\n", (int)getpid()); fflush(log_fp); }
    /* Signal to boot script that shim is active */
    int fd = open("/tmp/shm-shim-loaded", O_CREAT|O_WRONLY|O_TRUNC, 0644);
    if (fd >= 0) close(fd);
    /* spawn detached table-dumper (no-op + exits in non-fullfw processes) */
    pthread_t t;
    if (pthread_create(&t, NULL, usertable_dumper, NULL) == 0) pthread_detach(t);
}

static seg_t *find_seg_by_key(key_t key) {
    for (int i = 0; i < nseg; i++)
        if (segs[i].key == key) return &segs[i];
    return NULL;
}
static seg_t *find_seg_by_id(int shmid) {
    for (int i = 0; i < nseg; i++)
        if (segs[i].shmid == shmid) return &segs[i];
    return NULL;
}

int shmget(key_t key, size_t size, int shmflg) {
    while (__sync_lock_test_and_set(&mu_lock, 1)) {}

    if (log_fp) {
        fprintf(log_fp, "[shim2] shmget key=%d(0x%x) sz=%zu flg=0%o\n",
                key, (unsigned)key, size, shmflg);
        fflush(log_fp);
    }

    seg_t *s = find_seg_by_key(key);
    if (s) {
        /* Segment already known — check size compatibility */
        if (size > 0 && size > s->size) {
            /* Re-map with larger size */
            if (s->mapped) { munmap(s->mapped, s->size); s->mapped = NULL; }
            int fd = open(s->path, O_RDWR|O_CREAT, 0666);
            if (fd >= 0) { ftruncate(fd, size); close(fd); }
            s->size = size;
        }
        if (log_fp) { fprintf(log_fp, "[shim2] shmget found existing id=%d\n", s->shmid); fflush(log_fp); }
        __sync_lock_release(&mu_lock);
        return s->shmid;
    }

    if (nseg >= MAX_SEGS) {
        errno = ENOSPC;
        __sync_lock_release(&mu_lock);
        return -1;
    }

    seg_t *n = &segs[nseg];
    n->key   = key;
    n->shmid = nseg + 1;  /* 1-indexed fake id */
    n->size  = size > 0 ? size : 4096;
    n->mapped = NULL;
    snprintf(n->path, sizeof(n->path), SHM_DIR "/shmshim2-%08x", (unsigned)key);

    int fd = open(n->path, O_RDWR|O_CREAT, 0666);
    if (fd < 0) {
        if (log_fp) { fprintf(log_fp, "[shim2] shmget open failed: %s\n", strerror(errno)); fflush(log_fp); }
        __sync_lock_release(&mu_lock);
        return -1;
    }
    /* Ensure file is large enough */
    struct stat st;
    fstat(fd, &st);
    if ((size_t)st.st_size < n->size) ftruncate(fd, n->size);
    close(fd);

    nseg++;
    if (log_fp) { fprintf(log_fp, "[shim2] shmget created id=%d path=%s\n", n->shmid, n->path); fflush(log_fp); }
    __sync_lock_release(&mu_lock);
    return n->shmid;
}

void *shmat(int shmid, const void *shmaddr, int shmflg) {
    while (__sync_lock_test_and_set(&mu_lock, 1)) {}

    if (log_fp) { fprintf(log_fp, "[shim2] shmat shmid=%d\n", shmid); fflush(log_fp); }

    seg_t *s = find_seg_by_id(shmid);
    if (!s) {
        if (log_fp) { fprintf(log_fp, "[shim2] shmat EINVAL (unknown shmid)\n"); fflush(log_fp); }
        errno = EINVAL;
        __sync_lock_release(&mu_lock);
        return (void *)-1;
    }

    if (s->mapped) {
        /* Already mapped — re-map if needed */
        if (log_fp) { fprintf(log_fp, "[shim2] shmat already mapped at %p\n", s->mapped); fflush(log_fp); }
        __sync_lock_release(&mu_lock);
        return s->mapped;
    }

    int fd = open(s->path, O_RDWR|O_CREAT, 0666);
    if (fd < 0) {
        __sync_lock_release(&mu_lock);
        return (void *)-1;
    }
    /* Ensure file is large enough */
    struct stat st;
    fstat(fd, &st);
    if ((size_t)st.st_size < s->size) ftruncate(fd, s->size);

    void *p = mmap(NULL, s->size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    close(fd);

    if (p == MAP_FAILED) {
        if (log_fp) { fprintf(log_fp, "[shim2] shmat mmap failed: %s\n", strerror(errno)); fflush(log_fp); }
        __sync_lock_release(&mu_lock);
        return (void *)-1;
    }

    s->mapped = p;
    if (log_fp) { fprintf(log_fp, "[shim2] shmat → %p (size=%zu)\n", p, s->size); fflush(log_fp); }
    __sync_lock_release(&mu_lock);
    return p;
}

int shmdt(const void *shmaddr) {
    while (__sync_lock_test_and_set(&mu_lock, 1)) {}
    for (int i = 0; i < nseg; i++) {
        if (segs[i].mapped == shmaddr) {
            munmap(segs[i].mapped, segs[i].size);
            segs[i].mapped = NULL;
            if (log_fp) { fprintf(log_fp, "[shim2] shmdt unmapped key=0x%x\n", segs[i].key); fflush(log_fp); }
            __sync_lock_release(&mu_lock);
            return 0;
        }
    }
    __sync_lock_release(&mu_lock);
    errno = EINVAL;
    return -1;
}

int shmctl(int shmid, int cmd, struct shmid_ds *buf) {
    if (cmd == IPC_RMID) {
        while (__sync_lock_test_and_set(&mu_lock, 1)) {}
        seg_t *s = find_seg_by_id(shmid);
        if (s) {
            if (s->mapped) { munmap(s->mapped, s->size); s->mapped = NULL; }
            unlink(s->path);
            memset(s, 0, sizeof(*s));
        }
        __sync_lock_release(&mu_lock);
        return 0;
    }
    if (cmd == IPC_STAT && buf) {
        seg_t *s = find_seg_by_id(shmid);
        memset(buf, 0, sizeof(*buf));
        if (s) buf->shm_segsz = s->size;
        return 0;
    }
    return 0;
}

#if 0  /* config reads now served by REAL cfgmgrd + seeded CfgCurrentValues.db (boot-fullfw-guest.sh). Flip to 1 to restore standalone stubs. */
/*
 * CfgGetAttribute / CfgGetAttributeInt bypass:
 *
 * fullfw (and its deps) call CfgGetAttribute from libdellcfg.so.9 via PLT to
 * fetch IPMI user attributes (privilege, payload types, etc.) from cfgd on
 * D-Bus (com.dell.idrac.CfgMgrInternal). Without cfgd running, every call
 * returns ServiceUnknown instantly (no timeout). However, callers like
 * SerNonVolatileConfigInit retry 5x and then ABORT init on failure — they
 * do NOT fall back to defaults. Returning 1 (failure) causes serial/LAN
 * PEF init to abort before registering fd=3 with epoll.
 *
 * Fix: return 0 (success) with empty-string / zero defaults. The IPMI stack
 * then continues init (community name = "", flow control = 0, etc.). RAKP
 * auth still uses avctpasswd directly.
 *
 * Note: CfgLibGetAttributeCfgMgr is called internally (direct branch) within
 * libdellcfg.so.9 — it cannot be intercepted here. CfgGetAttribute IS a PLT
 * symbol, so this hook catches all external callers.
 */
int CfgGetAttribute(const char *key, char *buf, int buf_len) {
    /* The third arg is actually int* (pointer to allocated size), not int.
     * Treating it as int gives garbage (lower 32 bits of stack addr).
     * Do NOT use buf_len for sizing — use fixed-size writes only.
     *
     * Inject "root" for user 2 username so UserInfoSearchByNameAndPriv finds it.
     * buf is always malloc'd with at least attr_max_len+1 bytes (≥32), so
     * memcpy of 5 bytes is always safe. */
    const char *inject = NULL;
    if (key && buf) {
        if (strstr(key, "Users.2#UserName"))
            inject = "root";
        else if (strstr(key, "Users.") && strstr(key, "#Enable")) /* Users.N#Enable only */
            inject = "1";
        else if (strstr(key, "PrivLimit"))        /* IPMIUserInfo.N#PrivLimit */
            inject = "4";                          /* IPMI_PRIVILEGE_ADMIN */
        else if (strstr(key, "IpmiLanPrivilege")) /* Users.N#IpmiLanPrivilege */
            inject = "4";
        else if (strstr(key, "UserChannelAccess"))/* IPMIUserInfo.N#UserChannelAccess */
            inject = "4";
    }
    if (inject) {
        size_t n = strlen(inject) + 1;
        memcpy(buf, inject, n);
        if (log_fp) {
            fprintf(log_fp, "[shim2] CfgGetAttribute(%s) → '%s' (injected)\n",
                    key, inject);
            fflush(log_fp);
        }
        return 0;
    }
    if (buf) buf[0] = '\0';
    if (log_fp) {
        fprintf(log_fp, "[shim2] CfgGetAttribute(%s) → 0 (bypass, empty)\n",
                key ? key : "null");
        fflush(log_fp);
    }
    return 0;
}

int CfgGetAttributeInt(const char *key, int *out) {
    /* Privilege/access attrs need ADMIN (4) not 1 (callback).
     * RAKP2 status 0x0a = "Unauthorized role or privilege level" when
     * PrivLimit=1 but zipmi requests Administrator (3). Return 4 for
     * all privilege/access attrs; 1 for everything else (enabled/count). */
    int val = 1;
    if (key && (strstr(key, "PrivLimit") ||
                strstr(key, "Privilege") ||
                strstr(key, "UserChannelAccess"))) {
        val = 4;  /* IPMI_PRIVILEGE_ADMIN */
    }
    if (out) *out = val;
    if (log_fp) {
        fprintf(log_fp, "[shim2] CfgGetAttributeInt(%s) → 0 (bypass, val=%d)\n",
                key ? key : "null", val);
        fflush(log_fp);
    }
    return 0;
}

int CfgGetAttributeBin(const char *key, char *buf, int buf_len) {
    if (buf && buf_len > 0) buf[0] = '\0';
    if (log_fp) {
        fprintf(log_fp, "[shim2] CfgGetAttributeBin(%s) → 0 (bypass, empty)\n",
                key ? key : "null");
        fflush(log_fp);
    }
    return 0;
}

/* CfgLibGetAttributeCfgMgr: called internally in libdellcfg.so.9 (direct
 * branch, not PLT). Keeping hook here in case any external caller exists. */
int CfgLibGetAttributeCfgMgr(const char *key, long arg2, long arg3) {
    if (log_fp) {
        fprintf(log_fp, "[shim2] CfgLibGetAttributeCfgMgr(%s) → bypass 0\n",
                key ? key : "null");
        fflush(log_fp);
    }
    return 0;
}
#endif  /* config-read shims disabled — real cfgmgrd serves them */

/*
 * getPowerState: C-linkage export in libpower.so.9.9.9 at 0x6c80.
 * Called by RawPowerStatus (0x4af0) with a uint8* output arg.
 * Internally calls getPowerStateDbusProperty (D-Bus, "xyz.openbmc_project.State.Host0")
 * which blocks 2s per call (sd_bus_set_method_call_timeout 0x1e8480 μs).
 * PowerScanFunc fires at ~1Hz → 45+ blocked calls → ~90s delay before RMCP init.
 * Bypass: write 1 (host on) to *out, return 0 (success, bit-0-clear).
 *
 * GetSystemPowerStatusSHM: in libshm.so.9.9.9; reads power state from SDC SHM.
 * Returns 0 when SHM addr 713 not populated → GetSystemPowerStatus falls through.
 * Return 1 (on) to let GetSystemPowerStatus skip the fallback D-Bus path.
 */
int getPowerState(unsigned char *out) {
    if (out) *out = 1;  /* host power = on */
    if (log_fp) { fprintf(log_fp, "[shim2] getPowerState → 0 (*out=1 power=on)\n"); fflush(log_fp); }
    return 0;  /* bit 0 clear = success */
}

int GetSystemPowerStatusSHM(void) {
    if (log_fp) { fprintf(log_fp, "[shim2] GetSystemPowerStatusSHM → 1 (bypass)\n"); fflush(log_fp); }
    return 1;
}

#if defined(__aarch64__)
#define INDIRECT_CALL_TARGET __attribute__((target("branch-protection=standard")))
#else
#define INDIRECT_CALL_TARGET
#endif

typedef uint8_t (*ipmi_handler_fn)(const uint8_t *message,
                                   uint8_t *response_len,
                                   uint8_t *response_data);

struct request_handle_record {
    uint16_t selector;
    uint8_t required_priv;
    uint8_t request_len;
    uint32_t reserved;
    ipmi_handler_fn handler;
};

_Static_assert(offsetof(struct request_handle_record, selector) == 0,
               "request selector ABI offset");
_Static_assert(offsetof(struct request_handle_record, required_priv) == 2,
               "request privilege ABI offset");
_Static_assert(offsetof(struct request_handle_record, request_len) == 3,
               "request length ABI offset");
_Static_assert(offsetof(struct request_handle_record, reserved) == 4,
               "request reserved ABI offset");
_Static_assert(offsetof(struct request_handle_record, handler) == 8,
               "request handler ABI offset");
_Static_assert(sizeof(struct request_handle_record) == 16,
               "request record ABI size");

/* Minimum backend-free providers for authenticated IPMI commands. */
INDIRECT_CALL_TARGET uint8_t CmdGetDeviceID(const uint8_t *request,
                                            uint8_t *response_len,
                                            uint8_t response_data[15]) {
    static const uint8_t device_id[15] = {
        0x20, 0x81, 0x01, 0x0a, 0x02, 0x7f, 0xa2, 0x02,
        0x00, 0x00, 0x01, 0x00, 0x03, 0x00, 0x00
    };
    (void)request;
    if (!response_len || !response_data) return 0xff;
    memcpy(response_data, device_id, sizeof device_id);
    *response_len = sizeof device_id;
    if (log_fp) { fprintf(log_fp, "[shim2] CmdGetDeviceID → 0 (15-byte static response)\n"); fflush(log_fp); }
    return 0;
}

static INDIRECT_CALL_TARGET uint8_t shim_get_chassis_status(
        const uint8_t *message, uint8_t *response_len, uint8_t *response_data) {
    static const uint8_t chassis_status[3] = { 0x01, 0x00, 0x00 };
    (void)message;
    if (!response_len || !response_data) return 0xff;
    memcpy(response_data, chassis_status, sizeof chassis_status);
    *response_len = sizeof chassis_status;
    return 0;
}

INDIRECT_CALL_TARGET uint8_t RequestHandleTableSearch(
        const uint8_t *message, struct request_handle_record *out) {
    typedef uint8_t (*search_fn)(const uint8_t *, struct request_handle_record *);
    static search_fn real_fn = NULL;
    if (log_fp) { fprintf(log_fp, "[shim2] RequestHandleTableSearch entry\n"); fflush(log_fp); }
    if (!real_fn) {
        real_fn = (search_fn)dlsym(RTLD_NEXT, "RequestHandleTableSearch");
    }
    if (!real_fn) {
        if (log_fp) { fprintf(log_fp, "[shim2] RequestHandleTableSearch real lookup unavailable\n"); fflush(log_fp); }
        return 0;
    }

    uint8_t found = real_fn(message, out);
    if (!found) {
        if (log_fp) { fprintf(log_fp, "[shim2] RequestHandleTableSearch no match\n"); fflush(log_fp); }
        return found;
    }
    if (log_fp) { fprintf(log_fp, "[shim2] RequestHandleTableSearch selector=%04x\n", out->selector); fflush(log_fp); }

    switch (out->selector) {
    case 0x0601:
        out->handler = CmdGetDeviceID;
        if (log_fp) { fprintf(log_fp, "[shim2] RequestHandleTableSearch → CmdGetDeviceID\n"); fflush(log_fp); }
        break;
    case 0x0001:
        out->handler = shim_get_chassis_status;
        if (log_fp) { fprintf(log_fp, "[shim2] RequestHandleTableSearch → chassis status\n"); fflush(log_fp); }
        break;
    }
    return found;
}

void SenMgrGetSysHealth(uint8_t health[9]) {
    if (health) memset(health, 0, 9);
    if (log_fp) { fprintf(log_fp, "[shim2] SenMgrGetSysHealth → healthy\n"); fflush(log_fp); }
}

/*
 * Dell_shm_init_shm / Dell_shm_init_static_shm bypass (libshareddata.so.9.9.9):
 *
 * Dell_shm_init_shm(int sec_id) → calls Dell_shm_init_static_shm() → reads a
 * "section size" header from the SHM segment.  In a real system AIM pre-populates
 * the SHM before fullfw starts; in emulation the SHM backing files are zero-filled
 * so the header check fails with "SHM section size data is not valid!" for
 * sec_id=10, 12, 37.  sec_id=37 is the IPMI-security SHM; its failure prevents
 * the RMCP listener from calling epoll_ctl(ADD, fd=3) → fd=3 never in epoll →
 * UDP packets queue up unread → all zipmi polls time out.
 *
 * Fix: intercept both functions and return 0 (success) immediately.  The SHM
 * backing files remain zero-filled; downstream read/write via Dell_shm_memread /
 * Dell_shm_memwrite still work (return zeros / silently store), which is
 * sufficient for IPMI session establishment and RAKP auth (which uses avctpasswd).
 *
 * Dell_shm_init_static_shm takes no arguments (confirmed from disassembly: the
 * caller does not set x0 before bl Dell_shm_init_static_shm@plt).
 * Dell_shm_init_shm takes one int (sec_id).
 */
/*
 * Dell_shm_memread / Dell_shm_memread_unlocked bypass (libshareddata.so.9.9.9):
 *
 * Dell_shm_memread(sec_id, buf, offset, length) validates the SHM section header
 * (stores expected size at byte 0 of the SHM region). Zero-filled mmap backing
 * files have size=0 there, so every call returns "caller requested an offset
 * beyond the end of the section, section size=0" — including IPMI LAN init reads
 * for channel config, session counts, auth params, etc.
 *
 * Fix: return zeros into buf without the size check. IPMI reads zero config and
 * uses defaults or falls through to CfgGetAttribute for the authoritative value.
 * Dell_shm_memwrite/Dell_shm_memset: log and return 0; the mmap-backed writes
 * from shmat() already work, but any direct function path is also silenced here.
 */
int Dell_shm_memread(int sec_id, void *buf, int offset, int length) {
    if (buf && length > 0) memset(buf, 0, (size_t)length);
    if (log_fp) {
        fprintf(log_fp, "[shim2] Dell_shm_memread(sec_id=%d, off=%d, len=%d) → 0\n",
                sec_id, offset, length);
        fflush(log_fp);
    }
    return 0;
}

int Dell_shm_memread_unlocked(int sec_id, void *buf, int offset, int length) {
    if (buf && length > 0) memset(buf, 0, (size_t)length);
    if (log_fp) {
        fprintf(log_fp, "[shim2] Dell_shm_memread_unlocked(sec_id=%d, off=%d, len=%d) → 0\n",
                sec_id, offset, length);
        fflush(log_fp);
    }
    return 0;
}

int Dell_shm_memwrite(int sec_id, const void *buf, int offset, int length) {
    if (log_fp) {
        fprintf(log_fp, "[shim2] Dell_shm_memwrite(sec_id=%d, off=%d, len=%d) → 0\n",
                sec_id, offset, length);
        fflush(log_fp);
    }
    return 0;
}

int Dell_shm_memset(int sec_id, int val, int offset, int length) {
    if (log_fp) {
        fprintf(log_fp, "[shim2] Dell_shm_memset(sec_id=%d, val=%d, off=%d, len=%d) → 0\n",
                sec_id, val, offset, length);
        fflush(log_fp);
    }
    return 0;
}

/* Static zero buffer returned by Dell_shm_get_shm so callers don't crash
 * on NULL dereference when they bypass Dell_shm_memread. */
static char _shm_zero_buf[4096];
void *Dell_shm_get_shm(int sec_id) {
    if (log_fp) {
        fprintf(log_fp, "[shim2] Dell_shm_get_shm(sec_id=%d) → zero_buf\n", sec_id);
        fflush(log_fp);
    }
    return (void *)_shm_zero_buf;
}

/*
 * dlopen interceptor: strip RTLD_DEEPBIND so that libraries dlopen'd at
 * runtime (e.g. libdellcfg.so.9 loaded by libipmilinux.so.9 plugin path)
 * search the global scope first — ensuring our LD_PRELOAD stubs for
 * CfgGetAttribute, Dell_shm_memread, etc. are found before the real symbols.
 * Without this, RTLD_DEEPBIND would make the loaded lib prefer its own scope,
 * silently bypassing all LD_PRELOAD hooks.
 */
void *dlopen(const char *filename, int flags) {
    typedef void *(*dlopen_t)(const char *, int);
    dlopen_t real = (dlopen_t)dlsym(RTLD_NEXT, "dlopen");
    int stripped = flags & ~0x8;  /* 0x8 = RTLD_DEEPBIND */
    if (log_fp) {
        fprintf(log_fp, "[shim2] dlopen(%s, 0x%x→0x%x)\n",
                filename ? filename : "NULL", flags, stripped);
        fflush(log_fp);
    }
    return real ? real(filename, stripped) : NULL;
}

#if 0  /* user-table reads now served by REAL cfgmgrd (seeded Users.2). Flip to 1 to restore stubs. */
/*
 * PSMgrReadAttr intercept — libipmicommonapi.so (imported into libsess via PLT).
 *
 * PSMgrReadAttr(table_entry, user_id, buf, buf_size) reads a IPMI user attribute
 * from cfgd via D-Bus — it does NOT call CfgGetAttribute via PLT, so our Cfg*
 * hooks never fire from this path. Without cfgd running, every call returns
 * non-zero (error), leaving G_sUserTable zeroed:
 *   slot[0..f]  = username ""  → UserInfoSearchByNameAndPriv never matches
 *   slot[0x25+] = priv 0       → even if name matched, RAKP2 priv check fails
 *
 * Fix: call real function; on failure for user_id==2 (root), inject synthetic
 * values. Call ordering in User_Access_Handler READ path (deterministic):
 *   uid=2, sz=1   → Enable (1st sz=1 call) → inject 1
 *   uid=2, sz=8   → UserChannelAccess or PrivLimit → inject {4×8}
 *   uid=2, sz=1   → IpmiLanPrivilege (2nd+ sz=1) → inject 4
 * Plus UserInfoLoadUserConfig calls uid=2, sz=16 for Username → inject "root".
 *
 * Counter tracks sz=1 calls per user to distinguish Enable from priv calls.
 */
static int _psmgr_sz1_count[256];   /* per user_id count of buf_size==1 calls */
static int _psmgr_saw_sz8[256];     /* set when first sz=8 call seen for user */

/* Learn IPMI user-table attribute descriptors from uid=1 sz=1 calls.
 * The scan visits Enable, LanPriv, SerialPriv in order — three distinct tbl ptrs.
 * We record all three; the first is Enable (keep buf as-is for uid=2),
 * the rest are priv attrs (force buf=4 for uid=2).
 * SNMP alert tables have completely different tbl ranges → never learned → never injected. */
#define _IPMI_TBL_MAX 8
static void *_ipmi_tbls[_IPMI_TBL_MAX];   /* tbl ptrs seen for uid=1 sz=1 (in order) */
static int   _ipmi_tbl_n = 0;
static void *_ipmi_enable_tbl = NULL;      /* first uid=1 sz=1 tbl = Enable descriptor */

static int _ipmi_tbl_known(void *t) {
    for (int i = 0; i < _ipmi_tbl_n; i++) if (_ipmi_tbls[i] == t) return 1;
    return 0;
}

int PSMgrReadAttr(void *table_entry, unsigned int user_id, void *buf,
                  unsigned int buf_size) {
    typedef int (*fn_t)(void *, unsigned int, void *, unsigned int);
    static fn_t real_fn = NULL;
    if (!real_fn) real_fn = (fn_t)dlsym(RTLD_NEXT, "PSMgrReadAttr");

    int rc = real_fn ? (int)real_fn(table_entry, user_id, buf, buf_size) : -1;

    if (log_fp) {
        fprintf(log_fp,
                "[shim2] PSMgrReadAttr(tbl=%p, uid=%u, sz=%u) → %d",
                table_entry, user_id, buf_size, rc);
        if (rc == 0 && buf && buf_size <= 16) {
            fprintf(log_fp, " buf=");
            for (unsigned i = 0; i < buf_size && i < 16; i++)
                fprintf(log_fp, "%02x", ((unsigned char *)buf)[i]);
        }
        fprintf(log_fp, "\n");
        fflush(log_fp);
    }

    /* Learn IPMI user-table attr descriptors from uid=1 sz=1 scan calls */
    if (user_id == 1 && buf_size == 1 && !_ipmi_tbl_known(table_entry)) {
        if (_ipmi_tbl_n < _IPMI_TBL_MAX) {
            _ipmi_tbls[_ipmi_tbl_n++] = table_entry;
            if (_ipmi_enable_tbl == NULL) _ipmi_enable_tbl = table_entry;
            if (log_fp) {
                fprintf(log_fp, "[shim2] learned ipmi_tbl[%d]=%p\n",
                        _ipmi_tbl_n - 1, table_entry);
                fflush(log_fp);
            }
        }
    }

    /* For uid=2 sz=1: if tbl was seen in uid=1 scan AND is not Enable → force Admin(4) */
    if (user_id == 2 && buf_size == 1 && buf &&
        _ipmi_tbl_known(table_entry) && table_entry != _ipmi_enable_tbl) {
        ((unsigned char *)buf)[0] = 4;
        rc = 0;
        if (log_fp) {
            fprintf(log_fp, "[shim2] PSMgrReadAttr uid=2 tbl=%p → forced priv=4\n",
                    table_entry);
            fflush(log_fp);
        }
    }

    /* For uid=2 sz=7 or sz=30: possible username lookup fields — inject "root" */
    if (user_id == 2 && (buf_size == 7 || buf_size == 30) && buf) {
        memset(buf, 0, buf_size);
        memcpy(buf, "root", buf_size > 4 ? 4 : buf_size);
        rc = 0;
        if (log_fp) {
            fprintf(log_fp, "[shim2] PSMgrReadAttr uid=2 sz=%u → injected username root\n", buf_size);
            fflush(log_fp);
        }
    }

    if (rc != 0 && user_id == 2 && buf && buf_size > 0) {
        unsigned int uid_idx = user_id < 256 ? user_id : 255;
        if (buf_size == 16) {
            /* Username: inject "root" null-padded to 16 bytes */
            memset(buf, 0, 16);
            memcpy(buf, "root", 4);
            rc = 0;
        } else if (buf_size == 8) {
            /* UserChannelAccess or PrivLimit: inject Admin (4) for all 8 channels */
            memset(buf, 0x04, 8);
            _psmgr_saw_sz8[uid_idx] = 1;
            rc = 0;
        } else if (buf_size == 1) {
            int nth = _psmgr_sz1_count[uid_idx]++;
            if (!_psmgr_saw_sz8[uid_idx] && nth == 0) {
                /* First sz=1 call before any sz=8 → Enable → inject 1 (enabled) */
                ((unsigned char *)buf)[0] = 1;
            } else {
                /* After sz=8 calls → IpmiLanPrivilege / IpmiSerialPrivilege → 4 (Admin) */
                ((unsigned char *)buf)[0] = 4;
            }
            rc = 0;
        }
        if (log_fp && rc == 0) {
            fprintf(log_fp, "[shim2] PSMgrReadAttr uid=%u sz=%u → injected\n",
                    user_id, buf_size);
            fflush(log_fp);
        }
    }
    return rc;
}
#endif  /* PSMgrReadAttr user-table stub disabled */

int Dell_shm_init_shm(int sec_id) {
    if (log_fp) {
        fprintf(log_fp, "[shim2] Dell_shm_init_shm(sec_id=%d) → 0 (bypass)\n", sec_id);
        fflush(log_fp);
    }
    return 0;
}

int Dell_shm_init_static_shm(void) {
    if (log_fp) {
        fprintf(log_fp, "[shim2] Dell_shm_init_static_shm() → 0 (bypass)\n");
        fflush(log_fp);
    }
    return 0;
}

/* semaphores: fake them to unblock Dell_shm_init_sem() */
int semget(key_t key, int nsems, int semflg) {
    if (log_fp) { fprintf(log_fp, "[shim2] semget key=%d n=%d flg=0%o → fake %d\n", key, nsems, semflg, nsem+1); fflush(log_fp); }
    return ++nsem;  /* return unique fake semid; never 0 or -1 */
}

int semop(int semid, struct sembuf *sops, size_t nsops) {
    /* no-op: allow all SHM lock/unlock operations to proceed without blocking */
    if (log_fp) { fprintf(log_fp, "[shim2] semop semid=%d nsops=%zu → 0\n", semid, nsops); fflush(log_fp); }
    return 0;
}

int semtimedop(int semid, struct sembuf *sops, size_t nsops, const struct timespec *ts) {
    if (log_fp) { fprintf(log_fp, "[shim2] semtimedop semid=%d nsops=%zu → 0\n", semid, nsops); fflush(log_fp); }
    return 0;
}

int semctl(int semid, int semnum, int cmd, ...) {
    if (log_fp) { fprintf(log_fp, "[shim2] semctl semid=%d cmd=%d → 0\n", semid, cmd); fflush(log_fp); }
    return 0;
}

#if 0  /* SUPERSEDED by direct G_sUserTable injection (usertable_dumper). These
          getter shims are now redundant and can only interfere: the injected
          entry carries UserName + 20-byte key directly, and the real
          UserInfoGetUserPWD reads entry+0x11 straight from our table. */
/*
 * UserInfoGetUserPWD — libsess.so.9 (0x10164) reads 20-byte IPMI Km from
 * G_sUserTable[slot_id].pwd into dest.  The table is populated by
 * User_SHA256Password_Handler via PSMgrReadAttr → CfgGetAttribute, which
 * fails (cfgd absent) → 5 retries → empty → RAKP2 status 0x0a (bad HMAC).
 *
 * Bypass: inject factory IPMIKey bytes directly so RAKP2 HMAC matches.
 *
 * AArch64 calling convention (confirmed from disassembly at 0x101a8–0x101ac):
 *   x0 = unknown first arg (session or channel ctx — ignored here)
 *   x1 = slot_id   (and w20 = x1 & 0xff)
 *   x2 = len       (and w21 = x2 & 0xff; must be ≤ 20 or caller gets error)
 *   x3 = dest      (output buffer, at least len bytes)
 * Return 0 = success; nonzero = error (caller checks tst w0,0xff; b.ne fail).
 * Caller then checks dest[0] != 0 to confirm key was populated.
 *
 * Factory IPMIKey: avctpasswd field 14, first 20 bytes
 *   915F32F49A97456D0D6D66EEE5ED84C894B414AF
 */
/*
 * UserInfoGetUserName — returns the stored IPMI username for slot_id.
 * Called during UserInfoSearchByName to compare against requested username.
 * cfgd absent → CfgGetAttribute(Users.N#UserName) fails → empty name → 0x0d.
 * Same AArch64 calling convention as UserInfoGetUserPWD:
 *   x0=arg0, x1=slot_id, x2=name_buf, x3=buf_len
 */
int UserInfoGetUserName(int arg0, int slot_id, char *name_buf, int buf_len) {
    if (slot_id == 2 && name_buf && buf_len >= 5) {
        int n = buf_len < 16 ? buf_len : 16;
        memset(name_buf, 0, n);
        memcpy(name_buf, "root", 4);
        if (log_fp) {
            fprintf(log_fp, "[shim2] UserInfoGetUserName(slot=%d) → injected 'root'\n", slot_id);
            fflush(log_fp);
        }
        return 0;
    }
    typedef int (*fn_t)(int, int, char *, int);
    static fn_t real_fn = NULL;
    if (!real_fn) real_fn = (fn_t)dlsym(RTLD_NEXT, "UserInfoGetUserName");
    if (log_fp) {
        fprintf(log_fp, "[shim2] UserInfoGetUserName(slot=%d) → passthrough\n", slot_id);
        fflush(log_fp);
    }
    return real_fn ? real_fn(arg0, slot_id, name_buf, buf_len) : -1;
}

int UserInfoGetUserPWD(int arg0, int slot_id, int len, unsigned char *dest) {
    static const unsigned char km[20] = {
        0x91,0x5F,0x32,0xF4,0x9A,0x97,0x45,0x6D,
        0x0D,0x6D,0x66,0xEE,0xE5,0xED,0x84,0xC8,
        0x94,0xB4,0x14,0xAF
    };
    if (slot_id == 2 && dest) {
        int n = (len > 0 && len <= 20) ? len : 20;
        memcpy(dest, km, (size_t)n);
        if (log_fp) {
            fprintf(log_fp, "[shim2] UserInfoGetUserPWD(slot=%d, len=%d) → factory IPMIKey[0..%d]\n",
                    slot_id, len, n - 1);
            fflush(log_fp);
        }
        return 0;
    }
    /* Other slots: call original via RTLD_NEXT */
    typedef int (*fn_t)(int, int, int, unsigned char *);
    static fn_t real_fn = NULL;
    if (!real_fn) real_fn = (fn_t)dlsym(RTLD_NEXT, "UserInfoGetUserPWD");
    if (log_fp) {
        fprintf(log_fp, "[shim2] UserInfoGetUserPWD(slot=%d, len=%d) → passthrough\n", slot_id, len);
        fflush(log_fp);
    }
    return real_fn ? real_fn(arg0, slot_id, len, dest) : -1;
}

/*
 * User_Password_Handler — libsess.so.9 (0x10a20), reached via GOT/PLT from
 * UserInfoLoadUserConfig @0x11650 to populate the 20-byte password field of the
 * in-memory user-config table (G_aPSUserInfoTable[uid]).  Call site:
 *   User_Password_Handler(ctx=x20+0x40, uid=w1, flag=w2=1, dest=x3=struct+0x11)
 * The struct byte at +0x10 is preset to 0x14 (len=20), so the field is 20 bytes.
 *
 * The real handler calls osi_getUserSHA256() against the absent cfgd/dbus
 * backend → fails → UserInfoLoadUserConfig retries 5× ("Failed to read key
 * idrac.embedded.1#Users.%d#Password, UserID 2 after 5 retries") then ABORTS
 * the whole load.  Because the load aborts, the cached table for uid=2 is never
 * filled and RAKP2 never reaches the UserInfoGetUserPWD getter above — so
 * hooking only the getter is too late.  This hook is the missing piece: it
 * fills the password field with the 20-byte factory IPMIKey and returns 0,
 * letting the load complete so RAKP1 username match + RAKP2 HMAC both succeed.
 *
 * Interposable because libsess exports the symbol AND calls it through its own
 * PLT (SET_64 GOT reloc @0x32868); our LD_PRELOAD def wins global scope.
 */
int User_Password_Handler(void *ctx, unsigned int uid, int flag, unsigned char *dest) {
    static const unsigned char km[20] = {
        0x91,0x5F,0x32,0xF4,0x9A,0x97,0x45,0x6D,
        0x0D,0x6D,0x66,0xEE,0xE5,0xED,0x84,0xC8,
        0x94,0xB4,0x14,0xAF
    };
    if (uid == 2 && dest) {
        memcpy(dest, km, sizeof km);
        if (log_fp) {
            fprintf(log_fp, "[shim2] User_Password_Handler(uid=%u, flag=%d) → factory IPMIKey[0..19]\n",
                    uid, flag);
            fflush(log_fp);
        }
        return 0;
    }
    typedef int (*fn_t)(void *, unsigned int, int, unsigned char *);
    static fn_t real_fn = NULL;
    if (!real_fn) real_fn = (fn_t)dlsym(RTLD_NEXT, "User_Password_Handler");
    if (log_fp) {
        fprintf(log_fp, "[shim2] User_Password_Handler(uid=%u, flag=%d) → passthrough\n", uid, flag);
        fflush(log_fp);
    }
    return real_fn ? real_fn(ctx, uid, flag, dest) : -1;
}
#endif  /* username/password getter stubs disabled */

/*
 * PSMgrReadAttr targeted UserName fix (RE-confirmed). UserInfoLoadUserConfig
 * @0x115a4 fills G_sUserTable slot in place; the ONLY thing gating RAKP2 0x0d is
 * the 16-byte UserName field at entry+0x00. In this env the UserName read
 * (idrac.embedded.1#Users.2#UserName via the PSMgr accessor) returns EMPTY, so
 * the name never matches -> 0x0d, and the empty-name gate at 0x11630 skips the
 * rest of the load.
 *
 * Fix: only when the uid=2 sz=16 read comes back empty (that's the UserName;
 * the other sz=16 read, IPMIUserInfo.2#UserChannelAccess, is seeded non-empty in
 * cfgmgrd so it's left untouched), write "root"+NUL padding and return success.
 * Everything else passes through to the real cfgmgrd-backed read. Minimal work
 * per call (no per-call fflush storms) to avoid destabilizing fullfw init.
 */
int PSMgrReadAttr(void *table_entry, unsigned int user_id, void *buf, unsigned int buf_size) {
    typedef int (*fn_t)(void *, unsigned int, void *, unsigned int);
    static fn_t real_fn = NULL;
    static int resolved = 0;
    if (!resolved) { real_fn = (fn_t)dlsym(RTLD_NEXT, "PSMgrReadAttr"); resolved = 1; }
    int rc = real_fn ? real_fn(table_entry, user_id, buf, buf_size) : -1;

    if (user_id == 2 && buf_size == 16 && buf &&
        (rc != 0 || ((unsigned char *)buf)[0] == 0)) {
        memset(buf, 0, 16);
        memcpy(buf, "root", 4);
        rc = 0;
        if (log_fp) { fprintf(log_fp, "[shim2] PSMgrReadAttr uid=2 sz=16 empty -> forced UserName 'root'\n"); fflush(log_fp); }
    }
    return rc;
}

# iDRAC9 fullfw RAKP2/RAKP4 HMAC key — RE result (cipher suite 17, RAKP-HMAC-SHA256)

Rootfs: /Users/zen/phd/bmc/idrac9-firmware/extracted/rootfs
All addresses = libsess.so.9.9.9 (ARMv7) unless noted. Disasm saved alongside:
libsess_objdump_full.asm, libipmicrypto.asm, libdccfg_full.asm, libfnprv_full.asm, libosi_full.asm

## The key-derivation chain (binary-proven)

RAKP1 handler  RSSPOnSMWaitRAKP1StateRecvRAKP1 @0x447b6054
 -> fills the 20-byte HMAC-key buffer at  ctrl+19  (ctrl = session->[8]):
    1. UserInfoGetUserPWD(chan, idx, dest=ctrl+19, len=20)   @call 0x447b6320
       def @0x447ae198 — copies PLAINTEXT password from in-memory user table
       record (61 bytes/user, password at record+17, strnlen<=20). Empty pw -> dest[0]=0.
    2. if dest[0]==0 -> UserInfoGetUserHashPWD(chan, name, len=20, dest=ctrl+19) @call 0x447b634c
       def @0x447ae2a0 — calls osi_getUserSHA256() (libosi @0x441310ac ->
       AIM DDS "osi_function_getuser_sha256pwd"), gets a 64-hex ASCII string in the
       returned struct (off +0x480), HEX-DECODES it, memcpy FIRST 20 BYTES to dest.
    3. if dest[0]!=0 -> RSSPReplyRAKP2Msg (88-byte reply). else completion 0x0a.
       (completion 0x0d earlier = user not found, now cleared.)

RAKP2 authcode  RSSPReplyRAKP2Msg @0x447b5d64 -> RSSPGetRAKPAuthCode @0x447b5280
  case msg=1/3: @0x447b537c-94
    mov ip,#20            ; <-- KEY LENGTH HARDCODED = 20
    add r3,ctrl,#19       ; KEY PTR = ctrl+19
    -> RSSPGetKeyExchangeCode(algo, msg, msglen, key=ctrl+19, keylen=20, out) @0x447b51b4
       algo 3 (RAKP-HMAC-SHA256, suite 17) -> hmac_SHA256 @libipmicrypto 0x449c289c
       hmac_SHA256(data, datalen, key, keylen, out): @0x449c2908
         __memcpy_chk(k_ipad, key, keylen, 64)  -> uses EXACTLY keylen(=20) bytes,
         zero-padded to the 64-byte HMAC block.

## ANSWERS

1. HMAC key = the per-user key buffer ctrl+19 = hex-decode of the 64-hex value returned by
   osi_getUserSHA256. For a user with EMPTY plaintext Password (our case) this is the
   IPMIKey-class value (the only non-empty 64-hex secret; an empty SHA256Password would
   give completion 0x0a, not the observed 88-byte reply).
2. ENCODING: the 64-hex ASCII is HEX-DECODED to raw bytes, then TRUNCATED TO 20 BYTES
   (keylen hardcoded 20). NOT the 64 ASCII chars, NOT the full 32 raw bytes.
3. osi_function_getuser_sha256pwd returns the user's SHA256/IPMIKey hash (64 hex). Handler
   is AIM-runtime-registered (not a static table; the libdccfg SHA256Password reader at
   0x40e50 is scp_sshkey.c's pubkey setter, a red herring). Empty -> hash buffer stays
   empty -> RAKP1 emits 0x0a. With our user it returns IPMIKey 915F32...8964.
4. KEY fullfw uses = first 20 bytes of hex-decoded IPMIKey:
   915f32f49a97456d0d6d66eee5ed84c894b414af  (20 bytes / 40 hex)
   -> pass  zipmi -K 915f32f49a97456d0d6d66eee5ed84c894b414af
   This explains all 3 prior misses: 32 raw bytes (wrong len), 64 ASCII (wrong len), empty.
5. RAKP2 msg order built by RSSPGetRAKPAuthCode case 1 matches the IPMI 2.0 standard
   (SIDm||SIDc||Rm||Rc||GUIDc||ROLEm||ULENm||UNAMEm); no Dell deviation. Failure was the
   key only. RAKP4 ICV (case 3) uses the SAME 20-byte key.

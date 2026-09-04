# gxp_dev.py - named stub for GXP device controller @0xD1000000 (ASCII-only for IronPython).
# Logs accesses, returns ledger values (default 0). Observed: read 0x20, write byte 0x8 -> 0x24.
if request.IsInit:
    REGISTERS = {
        0x20: 0x00000000,
    }
    # Gate 5: gxp_dev @0xD1000000 is a register MAILBOX. The driver poll @0x41021834 does:
    #   strb cmd,[0x34] ; r3=[0x30] ; cmp cmd,(r3>>24) ; if eq -> result = r3 & 0x00ffffff
    # i.e. write a command BYTE to 0x34, the device echoes that byte in the TOP byte of the
    # 0x30 status word when the command completes, low 24 bits = result data. The 0-stub never
    # echoes -> poll fails 3x -> caller retries forever. Model the echo so commands "complete".
    LASTCMD = [0]
elif request.IsRead:
    if request.Offset == 0x30:
        # status word: echo last 0x34 command byte in bits[31:24] (done) + result data low 24.
        # This mailbox is MDIO/PHY mgmt. The REAL link-check @0x410221b4 issues cmd 1 then
        # tests result & 0x80 (bit 7 = LINK UP). Set bit 7 so net bring-up sees link.
        request.Value = ((LASTCMD[0] & 0xff) << 24) | 0x80
    else:
        request.Value = REGISTERS.get(request.Offset, 0x00000000)
    self.InfoLog("gxp_dev READ  off=0x%x -> 0x%x" % (request.Offset, request.Value))
else:
    if request.Offset == 0x34:
        LASTCMD[0] = request.Value & 0xff      # remember the command byte to echo at 0x30
    else:
        REGISTERS[request.Offset] = request.Value
    self.InfoLog("gxp_dev WRITE off=0x%x val=0x%x" % (request.Offset, request.Value))

# gxp_sysctl.py - named stub for the GXP system/config controller @0xC0000000.
# Renode Python.PythonPeripheral script: runs once with request.IsInit, then per access.
# IMPORTANT: IronPython is ASCII-strict here - keep this file pure ASCII (no em dashes,
# arrows, etc.) or it raises SyntaxError at load.
# Logs every access (InfoLog -> visible at default log level) and returns per-offset values
# from REGISTERS (default 0). Grows in place as the peel loop learns which registers gate
# progress; mirror each change into gxp_registers.md.
if request.IsInit:
    REGISTERS = {
        # offset: read_value  (add entries from gxp_registers.md as they are learned)
        0x1c: 0x00000000,
        0x24: 0x00000000,
        0x48: 0x00000008,   # DDR-ready status: bit3 set (bootloader1 memwait polls 0xC0000048 & 0x8 == 0x8)
        0x64: 0x00000000,
        0xa0: 0x00000000,
    }
    UARTBUF = []   # 16550-style UART at 0xC00000F0 (TX data) / 0xF5 (LSR); putchar @bootblock 0xa0000670
elif request.IsRead:
    # 0x98/0x9c = 64-bit free-running counter bootblock spins on as a startup delay
    # (ldrd r0,[0xC0000098]; wait until it exceeds a target). Make it tick so the wait ends.
    if request.Offset == 0x98:
        REGISTERS[0x98] = (REGISTERS.get(0x98, 0) + 0x100000) & 0xffffffff
        request.Value = REGISTERS[0x98]
    elif request.Offset == 0x9c:
        request.Value = REGISTERS.get(0x9c, 0)
    elif request.Offset == 0xf5:
        request.Value = 0x60   # UART LSR: THRE|TEMT -> TX always ready (don't block putchar)
    elif request.Offset == 0xf0:
        request.Value = 0x00   # UART RX (nothing to read)
    elif request.Offset == 0x44:
        # indexed DDR-PHY register file: index written to 0x40, value read from 0x44.
        # index 22 = DFIAuto training result; bootloader1 needs (v&0x1f)>=9 and (v&0x1f00)>=0x900
        # to treat training as complete. Report "trained" (0x0909) for it.
        idx = REGISTERS.get("_ddr_idx", 0)
        if idx == 0:
            request.Value = REGISTERS.get(("ddr", 0), 0) | 0x40   # idx0 = control/status: bit6 "op done"
        elif idx == 22:
            request.Value = 0x0909                                 # idx22 = DFIAuto "trained"
        else:
            request.Value = REGISTERS.get(("ddr", idx), 0x00000000)   # data indices: read back writes
    else:
        request.Value = REGISTERS.get(request.Offset, 0x00000000)
        self.InfoLog("gxp_sysctl READ  off=0x%x -> 0x%x" % (request.Offset, request.Value))
else:
    if request.Offset == 0x40:
        REGISTERS["_ddr_idx"] = request.Value   # DDR-PHY indexed-register select
    elif request.Offset == 0x44:
        REGISTERS[("ddr", REGISTERS.get("_ddr_idx", 0))] = request.Value   # indexed store (read-back verify)
    elif request.Offset == 0xf0:
        c = request.Value & 0xff
        if c == 0x0a or c == 0x0d:
            if UARTBUF:
                self.InfoLog("UART| " + "".join(UARTBUF))
                del UARTBUF[:]
        elif 0x20 <= c < 0x7f:
            UARTBUF.append(chr(c))
            if len(UARTBUF) >= 72:
                self.InfoLog("UART| " + "".join(UARTBUF))
                del UARTBUF[:]
    else:
        self.InfoLog("gxp_sysctl WRITE off=0x%x val=0x%x" % (request.Offset, request.Value))

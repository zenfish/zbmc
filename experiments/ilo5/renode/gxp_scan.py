# Native MR80000 device page. dvrgpio polls tagged samples at halfword 0xb8.
if request.IsInit:
    PAGE = bytearray(0x1000)
    SCAN_INDEX = 0
    # Unmeasured GPIO inputs: zero-filled emulation fixture, not hardware evidence.
    SAMPLES = bytearray(256)
elif request.IsRead:
    if request.Offset == 0xb8 and request.Length == 2:
        request.Value = (SCAN_INDEX << 8) | SAMPLES[SCAN_INDEX]
        # ponytail: read-driven 8-bit scan; use a timed engine for GPIO timing tests.
        SCAN_INDEX = (SCAN_INDEX + 1) & 0xff
    else:
        request.Value = sum(PAGE[request.Offset + i] << (8 * i) for i in range(request.Length))
elif request.IsWrite:
    if request.Offset == 0xb8 and request.Length == 2 and request.Value == 0:
        SCAN_INDEX = 0
    else:
        for i in range(request.Length):
            PAGE[request.Offset + i] = (request.Value >> (8 * i)) & 0xff

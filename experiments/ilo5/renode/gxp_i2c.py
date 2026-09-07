"""GXP basic-byte I2C fixture, using full C0000000-relative offsets.

Register protocol: vendor Linux i2c-gxp.c; engine 2/24c02@50/pagesize 8:
vendor gxp.dts. EEPROM bytes are an unmeasured erased fixture, not HPE data.
Commands complete synchronously; EEPROM writes have no write-cycle delay.
Native EEPROM BTE handles <=16 write bytes and <=127 read bytes in 16-byte
chunks. Longer/continuation and slave transfers remain unsupported. No Renode dependency.
"""


class GxpI2C(object):
    def __init__(self, irq):
        self.irq = irq
        self.irq_level = False
        self.enable = 0
        self.engines = [bytearray(256) for _ in range(10)]
        for registers in self.engines:
            registers[8] = 0x30
        self.active = [False] * 10
        self.selected = [False] * 10
        self.reading = [False] * 10
        self.bte = [None] * 10
        self.address_pending = False
        self.pointer = 0
        self.page = 0
        self.eeprom = bytearray([0xff] * 256)
        self.irq(False)

    @staticmethod
    def _check(offset, width):
        if width not in (1, 2, 4):
            raise ValueError('I2C access width must be 1, 2, or 4')
        if 0xf8 <= offset and offset + width <= 0x100:
            return
        if 0x2000 <= offset and offset + width <= 0x2a00:
            if offset // 256 == (offset + width - 1) // 256:
                return
        raise ValueError('access outside GXP I2C register ranges')

    def _events(self):
        return sum(1 << n for n, registers in enumerate(self.engines) if registers[1] or registers[0x60] & 0x12)

    def _refresh_irq(self):
        level = bool(self.enable & self._events())
        if level != self.irq_level:
            self.irq_level = level
            self.irq(level)

    def read(self, offset, width):
        self._check(offset, width)
        if offset < 0x100:
            image = self._events() | (self.enable << 32)
            return (image >> ((offset - 0xf8) * 8)) & ((1 << (width * 8)) - 1)
        engine, local = divmod(offset - 0x2000, 256)
        registers = self.engines[engine]
        value = 0
        for index in range(width):
            byte = registers[local + index]
            if local + index == 8:
                # Only drive/sample correlation is decoded; output-enable bits stay opaque.
                byte = (byte & ~3) | ((byte >> 4) & 3)
            value |= byte << (index * 8)
        return value

    def write(self, offset, width, value):
        self._check(offset, width)
        if value < 0 or value >= 1 << (width * 8):
            raise ValueError('I2C write does not fit access width')
        if offset < 0x100:
            for index in range(width):
                address = offset + index
                if address >= 0xfc:
                    shift = (address - 0xfc) * 8
                    self.enable = (self.enable & ~(0xff << shift)) | (((value >> (index * 8)) & 0xff) << shift)
            self._refresh_irq()
            return
        engine, local = divmod(offset - 0x2000, 256)
        registers = self.engines[engine]
        # Reject unmodeled modes before modifying registers or completing a command.
        for index in range(width):
            address, byte = local + index, (value >> (index * 8)) & 0xff
            if address == 0x60 and byte & ~0x1a:
                raise NotImplementedError('unknown GXP master BTE status acknowledgement')
            if 0x64 <= address < 0x80 and byte:
                raise NotImplementedError('GXP I2C slave/extended BTE transfer is not modeled')
            if address == 4 and byte & 0x70:
                raise NotImplementedError('unknown GXP I2C master command bits')
            if address == 1 and byte:
                raise NotImplementedError('only zero-clear I2C event writes are decoded')
        # Stage all bytes first: a halfword command must see its new high/data byte.
        for index in range(width):
            address = local + index
            if address not in (0, 2, 3, 0x60):
                registers[address] = (value >> (index * 8)) & 0xff
        if local <= 8 < local + width and registers[8] & 0x80:
            # Native recovery pulses this reset control; abort controller work,
            # preserving EEPROM bytes and timing/configuration registers.
            registers[0] = registers[1] = registers[0x60] = 0
            self.active[engine] = self.selected[engine] = self.reading[engine] = False
            self.bte[engine] = None
        if local <= 1 < local + width and not registers[1] & 0x10:
            registers[0] &= ~0x80
        if local <= 6 < local + width:
            # Slave configuration is retained; no external slave transactions are generated.
            registers[1] &= ~3
        if local <= 4 < local + width:
            self._command(engine)
        if local <= 0x60 < local + width:
            self._ack_bte(engine, (value >> ((0x60 - local) * 8)) & 0xff)
        if local <= 0x61 < local + width and registers[0x61] & 1:
            self._start_bte(engine)
        self._refresh_irq()

    def _command(self, engine):
        registers = self.engines[engine]
        command, data = registers[4], registers[5]
        if command & 0x80:
            registers[1] &= ~0x10
        if command & 2:  # STOP completes without another master event.
            registers[1] &= ~0x10
            self.active[engine] = self.selected[engine] = False
            registers[0] = 0
            return
        if command & 1:
            self.active[engine] = True
            self.selected[engine] = engine == 2 and data >> 1 == 0x50
            self.reading[engine] = bool(command & 4)
            if self.selected[engine]:
                self.address_pending = not self.reading[engine]
        elif not self.active[engine]:
            return  # Linux initialization's 0x80 only clears an event.
        elif self.selected[engine]:
            if command & 4 and self.reading[engine]:
                registers[2] = self.eeprom[self.pointer]
                self.pointer = (self.pointer + 1) & 0xff
            elif not (command & 4) and not self.reading[engine]:
                self._write_eeprom(data)
            else:
                raise NotImplementedError('I2C data direction changed without START')
        # Native dvri2c 0x10c64 tests STAT bit7 for basic master completion.
        registers[0] = 0x80 | (4 if self.reading[engine] else 0) | (8 if self.selected[engine] else 0)
        # Address NACK is still a completed bus transaction, allowing the driver to stop.
        registers[1] |= 0x10

    def _write_eeprom(self, data):
        if self.address_pending:
            self.pointer = data
            self.page = data & ~7
            self.address_pending = False
        else:
            self.eeprom[self.pointer] = data
            self.pointer = self.page | ((self.pointer + 1) & 7)

    def _start_bte(self, engine):
        registers = self.engines[engine]
        write_count, read_count = registers[0x62], registers[0x63]
        if write_count > 16 or read_count > 127:
            raise NotImplementedError('GXP BTE write refill and 128-byte continuation are not modeled')
        if self.bte[engine] is not None or registers[0x60] & 0x12:
            raise ValueError('BTE START before prior transfer acknowledgement')
        if self.active[engine]:
            raise ValueError('BTE START while basic transfer is active')
        registers[0x62] = registers[0x63] = 0
        if engine != 2 or registers[0x61] >> 1 != 0x50:
            registers[0x60] = 0x0a  # Completion plus address NACK, no fixture access.
            return
        self.address_pending = bool(write_count)
        for index in range(write_count):
            self._write_eeprom(registers[0x20 + index])
        registers[0x62] = write_count
        self.bte[engine] = {'total': read_count, 'done': 0}
        self._advance_bte(engine)

    def _advance_bte(self, engine):
        registers = self.engines[engine]
        state = self.bte[engine]
        count = min(16, state['total'] - state['done'])
        for index in range(count):
            registers[0x20 + index] = self.eeprom[self.pointer]
            self.pointer = (self.pointer + 1) & 0xff
        state['done'] += count
        registers[0x63] = state['done']
        # Completed chunks are synchronous; bus-cycle timing is not modeled.
        direction = 0x80 if state['total'] else 0
        registers[0x60] = direction | (0x10 if state['done'] < state['total'] else 2)

    def _ack_bte(self, engine, value):
        registers = self.engines[engine]
        pending = registers[0x60]
        if value & 2 and pending & 2:
            registers[0x60] = pending & ~(value & 0x0a)
            self.bte[engine] = None
        if value & 0x10 and pending & 0x10:
            registers[0x60] &= ~0x10
            self._advance_bte(engine)

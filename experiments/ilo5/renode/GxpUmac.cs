using System;
using System.Collections.Generic;

using Antmicro.Renode.Core;
using Antmicro.Renode.Core.Structure;
using Antmicro.Renode.Logging;
using Antmicro.Renode.Network;
using Antmicro.Renode.Peripherals.Bus;
using Antmicro.Renode.Peripherals.Python;
using Antmicro.Renode.Utilities;

namespace Antmicro.Renode.Peripherals.Network
{
    public class GxpUmac : IDoubleWordPeripheral, IMACInterface, IKnownSize
    {
        public GxpUmac(IMachine machine, PythonPeripheral interruptController)
        {
            sysbus = machine.GetSystemBus(this);
            this.interruptController = interruptController;
            Reset();
        }

        public uint ReadDoubleWord(long offset)
        {
            if((offset & 0x7F) == DmaClockStatus)
            {
                return 0x18000;
            }
            return registers.TryGetValue(offset, out var value) ? value : 0;
        }

        public void WriteDoubleWord(long offset, uint value)
        {
            var bankOffset = offset & BankMask;
            if(bankOffset == Configuration)
            {
                registers[offset] = value & ~SoftwareReset;
            }
            else if(offset == Interrupt)
            {
                var pending = registers.GetValueOrDefault(offset) & InterruptStatusMask & ~(value & InterruptStatusMask);
                registers[offset] = pending | (value & ~InterruptStatusMask);
                RefreshInterrupt();
            }
            else
            {
                registers[offset] = value;
            }

            if(offset == RingPointer)
            {
                txIndex = (int)((value >> 16) & 0x7FFF);
                rxIndex = (int)(value & 0x7FFF);
                txGeneration = (value & TxGeneration) != 0;
                rxGeneration = (value & RxGeneration) != 0;
            }
            else if(offset == RingPrompt)
            {
                TransmitPendingFrames();
            }
            else if(offset == MacHigh || offset == MacMiddle || offset == MacLow)
            {
                UpdateMacAddress();
            }
        }

        public void Reset()
        {
            registers.Clear();
            txIndex = 0;
            rxIndex = 0;
            txGeneration = false;
            rxGeneration = false;
            MAC = MACAddress.Default;
            RefreshInterrupt();
        }

        public void ReceiveFrame(EthernetFrame frame)
        {
            var ringBase = ReadDoubleWord(RxRingAddress);
            if(ringBase == 0)
            {
                return;
            }

            var descriptor = ringBase + (uint)(rxIndex * DescriptorSize);
            var status = sysbus.ReadWord(descriptor + 4);
            var capacity = sysbus.ReadWord(descriptor + 6);
            // EthernetFrame.Bytes includes the validated FCS that firmware strips.
            var bytes = frame.Bytes;
            if(frame.Length < 60)
            {
                // TAP can supply unpadded Ethernet frames; hardware presents padding before FCS.
                var padded = new byte[60];
                Array.Copy(frame.UnderlyingPacket.Bytes, padded, frame.Length);
                if(!Misc.TryCreateFrameOrLogWarning(this, padded, out var paddedFrame, addCrc: true))
                {
                    return;
                }
                bytes = paddedFrame.Bytes;
            }
            if((status & HardwareOwned) == 0 || bytes.Length > capacity)
            {
                this.Log(LogLevel.Warning, "Dropping RX frame at descriptor {0}: owned={1}, length={2}, capacity={3}", rxIndex, (status & HardwareOwned) != 0, bytes.Length, capacity);
                return;
            }

            var address = sysbus.ReadDoubleWord(descriptor);
            sysbus.WriteBytes(bytes, address);
            sysbus.WriteWord(descriptor + 6, (ushort)bytes.Length);
            sysbus.WriteWord(descriptor + 4, 0);

            AdvanceRx();
            SetInterrupt(RxInterrupt);
            this.Log(LogLevel.Info, "GXP_UMAC_RX index={0} address=0x{1:X8} length={2}", PreviousIndex(rxIndex, RxEntries), address, bytes.Length);
        }

        public long Size => 0x100;

        public MACAddress MAC { get; set; }

        public event Action<EthernetFrame> FrameReady;

        private void TransmitPendingFrames()
        {
            var ringBase = ReadDoubleWord(TxRingAddress);
            if(ringBase == 0)
            {
                return;
            }

            var entries = TxEntries;
            for(var processed = 0; processed < entries; processed++)
            {
                var descriptor = ringBase + (uint)(txIndex * DescriptorSize);
                var status = sysbus.ReadWord(descriptor + 4);
                if((status & HardwareOwned) == 0)
                {
                    break;
                }

                var count = sysbus.ReadWord(descriptor + 6);
                var address = sysbus.ReadDoubleWord(descriptor);
                var bytes = sysbus.ReadBytes(address, count);
                if(Misc.TryCreateFrameOrLogWarning(this, bytes, out var frame, addCrc: true))
                {
                    this.Log(LogLevel.Info, "GXP_UMAC_TX index={0} address=0x{1:X8} length={2}", txIndex, address, count);
                    FrameReady?.Invoke(frame);
                }

                sysbus.WriteWord(descriptor + 4, 0);
                AdvanceTx();
                SetInterrupt(TxInterrupt);
            }
        }

        private void AdvanceTx()
        {
            txIndex++;
            if(txIndex == TxEntries)
            {
                txIndex = 0;
                txGeneration = !txGeneration;
            }
            UpdateRingPointer();
        }

        private void AdvanceRx()
        {
            rxIndex++;
            if(rxIndex == RxEntries)
            {
                rxIndex = 0;
                rxGeneration = !rxGeneration;
            }
            UpdateRingPointer();
        }

        private void UpdateRingPointer()
        {
            registers[RingPointer] = (uint)(txIndex << 16) | (uint)rxIndex
                | (txGeneration ? TxGeneration : 0)
                | (rxGeneration ? RxGeneration : 0);
        }

        private void SetInterrupt(uint status)
        {
            registers[Interrupt] = registers.GetValueOrDefault(Interrupt) | status;
            this.Log(LogLevel.Info, "GXP_UMAC_IRQ status=0x{0:X8} register=0x{1:X8}", status, registers[Interrupt]);
            RefreshInterrupt();
        }

        private void RefreshInterrupt()
        {
            if(interruptController == null)
            {
                return;
            }
            var value = registers.GetValueOrDefault(Interrupt);
            var active = ((value & TxInterrupt) != 0 && (value & TxInterruptEnable) != 0)
                || ((value & RxInterrupt) != 0 && (value & RxInterruptEnable) != 0);
            interruptController.ControlWrite(PrimaryInterruptSource, active ? 1UL : 0UL);
        }

        private static int PreviousIndex(int current, int entries)
        {
            return current == 0 ? entries - 1 : current - 1;
        }

        private int TxEntries => (((int)(ReadDoubleWord(RingSize) >> 24) & 0xFF) + 1) * 4;
        private int RxEntries => (((int)(ReadDoubleWord(RingSize) >> 16) & 0xFF) + 1) * 4;

        private void UpdateMacAddress()
        {
            var value = ((ulong)(ReadDoubleWord(MacHigh) & 0xFFFF) << 32)
                | ((ulong)(ReadDoubleWord(MacMiddle) & 0xFFFF) << 16)
                | (ReadDoubleWord(MacLow) & 0xFFFF);
            MAC = new MACAddress(value);
        }

        private readonly IBusController sysbus;
        private readonly PythonPeripheral interruptController;
        private readonly Dictionary<long, uint> registers = new Dictionary<long, uint>();
        private int txIndex;
        private int rxIndex;
        private bool txGeneration;
        private bool rxGeneration;

        private const int DescriptorSize = 16;
        private const ushort HardwareOwned = 0x8000;
        private const uint TxInterrupt = 0x1;
        private const uint TxInterruptEnable = 0x2;
        private const uint RxInterrupt = 0x4;
        private const uint RxInterruptEnable = 0x8;
        private const uint InterruptStatusMask = 0xD5;
        private const uint SoftwareReset = 0x200;
        private const uint RxGeneration = 1U << 15;
        private const uint TxGeneration = 1U << 31;
        private const long PrimaryInterruptSource = 10;
        private const long BankMask = 0x7F;
        private const long Configuration = 0x00;
        private const long RingPointer = 0x04;
        private const long RingPrompt = 0x08;
        private const long RingSize = 0x14;
        private const long MacHigh = 0x18;
        private const long MacMiddle = 0x1C;
        private const long MacLow = 0x20;
        private const long DmaClockStatus = 0x2C;
        private const long Interrupt = 0x30;
        private const long RxRingAddress = 0x4C;
        private const long TxRingAddress = 0x50;
    }
}

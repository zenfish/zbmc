set pagination off
python
import gdb

fields = {field.name for field in gdb.lookup_type("AspeedMachineState").fields()}
bmc = gdb.parse_and_eval("(AspeedMachineState *) current_machine")
gdb.set_convenience_variable("bmc", bmc)
state_in_machine = "xcc_fpga_read_count" in fields
gdb.execute("list xcc_fpga_read", to_string=True)

def expression(name):
    return f"$bmc->{name}" if name in fields else name

def dump(filename, start, end):
    gdb.execute(f"dump binary memory {filename} {start} {end}")

scalars = (
    "xcc_fpga_write_count", "xcc_fpga_read_count", "xcc_fpga_transaction",
    "xcc_fpga_command", "xcc_fpga_fifo_pos", "xcc_fpga_request_length",
    "xcc_fpga_response_length", "xcc_fpga_collecting_write",
    "xcc_fpga_i2c_operation_complete", "xcc_fpga_i2c_status_logged",
    "xcc_ptables_valid", "xcc_ptables_polls",
)
with open("lenovo-fpga-state.txt", "w", encoding="ascii") as output:
    output.write(f"layout={'machine' if state_in_machine else 'static'}\n")
    for name in scalars:
        value = int(gdb.parse_and_eval(expression(name)))
        output.write(f"{name.removeprefix('xcc_')}={value}\n")

dump("lenovo-fpga-command.bin", "$bmc->xcc_fpga_buf[0]", "$bmc->xcc_fpga_buf[0]+0x8000")
dump("lenovo-fpga-data.bin", "$bmc->xcc_fpga_buf[1]", "$bmc->xcc_fpga_buf[1]+0x4000")
dump("lenovo-fpga-control.bin", "$bmc->xcc_fpga_buf[2]", "$bmc->xcc_fpga_buf[2]+0x1000")
def array(name, count, filename):
    prefix = "$bmc->" if name in fields else ""
    dump(filename, f"&{prefix}{name}[0]", f"&{prefix}{name}[{count}]")

array("xcc_fpga_fifo", 4096, "lenovo-fpga-fifo.bin")
array("xcc_fpga_request", 1031, "lenovo-fpga-request.bin")
array("xcc_ptables_data", 32768, "lenovo-ptables.bin")
end

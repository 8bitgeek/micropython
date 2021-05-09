import uasyncio as asyncio
import microamp as amp
import gc

echo_data_write="<All good men come to the aid of their country"
echo_data_read ="                                              "

def echo_dataready_event(fd_list):
    avail=amp.channel_avail(fd_list[0])
    while avail:
        if amp.channel_read(fd_list[0],echo_data_read,len(echo_data_read)) >= 0:
            print(echo_data_read)
        if amp.channel_write(fd_list[1],echo_data_write,len(echo_data_write)) >= 0:
            print(echo_data_write)
        avail=amp.channel_avail(fd_list[0])

def clock_handler(fd):
    avail = amp.channel_avail(fd)
    buf=b'\x00\x00\x00\x00\x00\x00'
    if amp.channel_read(fd,buf,4) >= 0:
        #data = list(buf)
        #tm = data[0] | data[1]<<8 | data[2]<<16 | data[3]<<24
        (tm, ) = struct.unpack('<L', buf)
        print("dataready_handler",tm)

if amp.endpoint_indexof("echo0") >= 0:
    fd_read=amp.channel_open("echo0")
    if fd_read >= 0:
        fd_write=amp.channel_open("echo1")
        if fd_write >= 0:
            fd_list = [ fd_read, fd_write ]
            amp.channel_dataready_handler(fd_read,echo_dataready_event,fd_list)

if amp.endpoint_indexof("clock") >= 0:
    fd_clk=amp.channel_open("clock")
    if fd_clk >= 0:
        amp.channel_dataready_handler(fd_clk,clock_handler,fd_clk)

async def busy():
    while True:
        await asyncio.sleep_ms(1000)
        gc.collect()

asyncio.run(busy())

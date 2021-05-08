import uasyncio as asyncio
import microamp as amp
import gc

# the rx data callback handler
def rx_event(fd):
    avail = amp.channel_avail(fd)
    buf=b'\x00\x00\x00\x00\x00\x00'
    if amp.channel_read(fd,buf,4) >= 0:
        data = list(buf)
        tm = data[0] | data[1]<<8 | data[2]<<16 | data[3]<<24
        print("rx_event",tm)
        gc.collect()

# open the ondpoint and assign a callback function.
if amp.endpoint_indexof("clock") >= 0:
    fd=amp.channel_open("clock")
    if fd >= 0:
        amp.channel_callback(fd,rx_event,fd)

# just doing some busy work here.
async def busy():
    while True:
        await asyncio.sleep_ms(2000)

asyncio.run(busy())

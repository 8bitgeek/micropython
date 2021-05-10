import uasyncio as asyncio
import microamp as amp
import struct
import utime
import gc

def echo_dataready_event(fd):
    print(amp.channel_get(fd[0]))
    print(amp.channel_put(fd[1],"<"))

def clock_tick_event(fd):
    print(struct.unpack('<L',amp.channel_get(fd)))

async def busy():
    while True:
        await asyncio.sleep_ms(1000)
        gc.collect()

#fd_get=amp.channel_open("echo0")
#fd_put=amp.channel_open("echo1")
#if fd_get >= 0 and fd_put >= 0:
    #amp.channel_dataready_handler(fd_get,echo_dataready_event,[ fd_get, fd_put ])
    #print(amp.channel_put(fd_put,"<"))

fd_clk=amp.channel_open("clock")
if fd_clk >= 0:
    amp.channel_dataready_handler(fd_clk,clock_tick_event,fd_clk)

asyncio.run(busy())

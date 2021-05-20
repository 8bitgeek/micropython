import uasyncio as asyncio
import microamp as amp
import struct
import utime
import gc

cls='\x1B[1J'
home='\x1B[H'
txt='***'

def clock_tick_event(fd):
    print(home)
    print(struct.unpack('<L',amp.channel_get(fd)))

async def busy():
    while True:
        await asyncio.sleep_ms(1000)
        gc.collect()

fd_clk=amp.channel_open("clock")
if fd_clk >= 0:
    amp.channel_dataready_handler(fd_clk,clock_tick_event,fd_clk)

print(cls)
asyncio.run(busy())

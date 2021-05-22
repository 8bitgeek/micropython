import uasyncio as asyncio
import microamp as amp
import gc

def callback(arg):
    print("callback", arg)

async def clock():
    if amp.endpoint_indexof("clock") >= 0:
        fd=amp.channel_open("clock")
        if fd >= 0:
            #cb=amp.channel_callback(fd,callback,fd)
            while True:
                avail = amp.channel_avail(fd)
                if avail > 0:
                    buf=b'\x00\x00\x00\x00'
                    if amp.channel_read(fd,buf,4) >= 0:
                        data = list(buf)
                        tm = data[0] | data[1]<<8 | data[2]<<16 | data[3]<<24
                        print(tm,gc.mem_alloc())
                        gc.collect()
                await asyncio.sleep_ms(1)


asyncio.run(clock())

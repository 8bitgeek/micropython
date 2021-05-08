import uasyncio as asyncio
import microamp as amp

tm=b'\x00\x00\x00\x00\x00\x00\x00\x00'

async def clock():
    if amp.endpoint_indexof("clock") >= 0:
        print(amp.endpoint_count())
        fd=amp.channel_open("clock")
        if fd >= 0:
            while True:
                avail = amp.channel_avail(fd)
                if avail > 0:
                    print(avail)
                    if amp.channel_read(fd,tm,avail) >= 0:
                        print(tm)
                await asyncio.sleep_us(10);


asyncio.run(clock())

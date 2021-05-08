import uasyncio as asyncio
import microamp as amp

async def clock():
    if amp.endpoint_indexof("clock") >= 0:
        print(amp.endpoint_count())
        fd=amp.channel_open("clock")
        if fd >= 0:
            while True:
                avail = amp.channel_avail(fd)
                if avail > 0:
                    buf=b'\x00\x00\x00\x00'
                    if amp.channel_read(fd,buf,4) >= 0:
                        b = list(buf)
                        print(b[0] | b[1]<<8 | b[2]<<16 | b[3]<<24)
                await asyncio.sleep_ms(1)


asyncio.run(clock())

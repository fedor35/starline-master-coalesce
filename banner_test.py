import os, termios, time, sys
fd = os.open('/dev/ttyUSB0', os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
a = termios.tcgetattr(fd)
a[0]=0; a[1]=0; a[2]=termios.CS8|termios.CREAD|termios.CLOCAL; a[3]=0
a[4]=a[5]=termios.B115200; a[6][termios.VMIN]=0; a[6][termios.VTIME]=0
termios.tcsetattr(fd, termios.TCSANOW, a)
os.set_blocking(fd, True)
termios.tcflush(fd, termios.TCIOFLUSH)
time.sleep(0.3); termios.tcflush(fd, termios.TCIFLUSH)
os.write(fd, b'\x50'); termios.tcdrain(fd)
t0=time.time()
while time.time()-t0 < 1.0:
    d = os.read(fd, 512)
    if d: print(f"read {len(d)} bytes: {d!r}")

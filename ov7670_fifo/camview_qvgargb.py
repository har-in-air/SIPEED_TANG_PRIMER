#!/usr/bin/env python

# modified by HN

import pygame
import sys
import serial
import time
import re
import struct

def parsergb565(byte1, byte2):
    byte12 = byte1 << 8 | byte2

    red = byte12 >> 8+3
    green = (byte12 >> 5) & 0x3f
    blue = byte12 & 0x1f
    
    red *= 8
    green *= 4
    blue *= 8

    return (red, green, blue)


def readimage():
    imagebuf = [None] * image_height
    print('Capture new image')
    ser.write(b'1') # send char '1' to capture new image
    l = ser.read(1) # wait for captured image ack '1'
    while l != b'1' :
         time.sleep(0.1)    
         l = ser.read(1)
    print('New image captured, reading image from fifo')
    ser.write(b'2') # send char '2' to download image
    print('Transferring buffer via serial')
    l = ''
    for y in range(0, image_height):
        sys.stdout.write('\r%d/%d [%d%%]' % \
            (y + 1, image_height,
            int((y + 1) / float(image_height) * 100.0)))
        sys.stdout.flush()
        l = ser.read(image_width * 2)
        if len(l) != (image_width * 2):
            print('\nonly got %d bytes!'.encode() % (len(l),))
            sys.exit(1)
        imagebuf[y] = l
    print('\r\n');
    return imagebuf


def _drawimage():
    for y in range(0, image_height):
        i = 0
        for x in range(0, image_width):
            color = parsergb565(buf[y][i],buf[y][i + 1])
            i += 2
            screen.set_at((2 * x, 2 * y), color)
            screen.set_at((2 * x + 1, 2 * y), color)
            screen.set_at((2 * x, 2 * y + 1), color)
            screen.set_at((2 * x + 1, 2 * y + 1), color)


def saveimage():
    fp = open("image.bin","wb")
    for y in range(0, image_height):
        i = 0
        for x in range(0, image_width):
            h = buf[y][i]
            l = buf[y][i + 1]
            fp.write(struct.pack('B',h))
            fp.write(struct.pack('B',l))
            i += 2            
    fp.close()            


def drawimage():
    for y in range(0, image_height):
        i = 0
        for x in range(0, image_width):
            color = parsergb565(buf[y][i], buf[y][i + 1])
            i += 2
            screen.set_at((x, y), color)

if __name__ == '__main__':

    image_width = 320
    image_height = 240
    if len(sys.argv) != 3:
        print(str(sys.argv[0]) + ' /dev/ttyUSBx baudrate')
        sys.exit(1)
    comport = str(sys.argv[1])
    baud = sys.argv[2]

    ser = serial.Serial(
            port = comport,
            baudrate = baud,
            parity = serial.PARITY_NONE,
            stopbits = serial.STOPBITS_ONE,
            bytesize = serial.EIGHTBITS,
            timeout = 1
        )
        
    print('Serial port open')

    print('Reading image from camera...')
    starttime = time.time()
    buf = readimage()
    print('Read complete in %.3f seconds' % (time.time() - starttime))

    print('Opening window')
    width = image_width
    height = image_height
    screen = pygame.display.set_mode((width, height))
    clock = pygame.time.Clock()

    running = True
    while running:
        drawimage()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif (event.type == pygame.KEYDOWN):
                if (event.key == pygame.K_SPACE): # spacebar triggers new image capture and display
                    buf = readimage()
                    #saveimage()
                    pass
        pygame.display.flip()

        clock.tick(240)


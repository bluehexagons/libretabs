#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Original fixture music/data by bluehexagons, dedicated under CC0-1.0."""
from pathlib import Path
import struct
ROOT = Path(__file__).resolve().parents[1] / 'content' / 'fixtures'

def vlq(n):
    result = [n & 127]
    n >>= 7
    while n:
        result.insert(0, (n & 127) | 128)
        n >>= 7
    return bytes(result)

def track(events, end=7680):
    data = bytearray(); last = 0
    for tick, event in sorted(events, key=lambda pair: pair[0]):
        data.extend(vlq(tick-last) + event); last = tick
    data.extend(vlq(max(end,last)-last) + b'\xff\x2f\x00')
    return b'MTrk' + struct.pack('>I',len(data)) + data

def midi(tracks, fmt=1):
    return b'MThd'+struct.pack('>IHHH',6,fmt,len(tracks),480)+b''.join(tracks)

def melody(channel=0):
    pitches=[64,64,67,69,67,66,64,62,64,67,71,69,67,66,64]
    times=[0,480,960,1440,1920,2160,2400,2880,3840,4320,4800,5040,5280,6000,6720]
    durations=[480,480,480,480,240,240,480,480,480,480,240,240,720,720,960]
    result=[]
    for tick,pitch,duration in zip(times,pitches,durations):
        result.extend([(tick,bytes([0x90+channel,pitch,90])),(tick+duration,bytes([0x80+channel,pitch,0]))])
    return result

if __name__=='__main__':
    ROOT.mkdir(parents=True,exist_ok=True)
    conductor=[(0,b'\xff\x51\x03\x09\x27\xc0'),(0,b'\xff\x58\x04\x04\x02\x18\x08')]
    named=[(0,b'\xff\x03\x06Melody')]+melody()
    backing=[(0,b'\xff\x03\x04Bass')]
    for start,pitch in [(0,40),(1920,45),(3840,43),(5760,40)]:
        backing.extend([(start,bytes([0x91,pitch,65])),(start+1800,bytes([0x81,pitch,0]))])
    (ROOT/'first_melody.mid').write_bytes(midi([track(conductor),track(named),track(backing)]))
    (ROOT/'changing_tempo.mid').write_bytes(midi([track(conductor+[(3840,b'\xff\x51\x03\x0c\x35\x00')]),track(named)]))
    (ROOT/'format0.mid').write_bytes(midi([track(conductor+named+backing)],0))
    held=[(0,b'\x90\x40\x60'),(480,b'\x90\x40\x60'),(960,b'\x80\x40\x00'),(1440,b'\x80\x40\x00'),(1920,b'\x90\x14\x60'),(2400,b'\x80\x14\x00')]
    (ROOT/'held_notes.mid').write_bytes(midi([track(conductor+held,3840)],0))
    (ROOT/'running_status.mid').write_bytes(midi([track([(0,b'\x90\x40\x60'),(480,b'\x40\x00')],480)],0))

    dense=[]
    for pitch in range(40,72):
        dense.extend([(0,bytes([0x90,pitch,90])),(1920,bytes([0x80,pitch,0]))])
    (ROOT/'dense_chord.mid').write_bytes(midi([track(conductor+dense,3840)],0))
    (ROOT/'invalid_text.mid').write_bytes(midi([track([(0,b'\xff\x03\x03\x00\xffA')]+melody())],0))
    (ROOT/'short_header.mid').write_bytes(b'MTh')

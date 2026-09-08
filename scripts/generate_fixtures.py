#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Original fixture music/data by bluehexagons, dedicated under CC0-1.0."""
from pathlib import Path
import struct
ROOT = Path(__file__).resolve().parents[1] / 'content' / 'fixtures'


def meta(kind, text):
    value = text.encode('ascii')
    if len(value) >= 128:
        raise ValueError('metadata text must fit the one-byte fixture VLQ')
    return bytes([0xff, kind, len(value)]) + value

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


def authored_melody(title, composer, pitches, durations, tempo=100, time_numerator=4, time_denominator=4):
    if len(pitches) != len(durations):
        raise ValueError(f'{title}: pitch and duration counts differ')
    microseconds = round(60_000_000 / tempo)
    conductor = [
        (0, b'\xff\x51\x03' + microseconds.to_bytes(3, 'big')),
        (0, b'\xff\x58\x04' + bytes([time_numerator, {2: 1, 4: 2, 8: 3}[time_denominator], 0x18, 0x08])),
        (0, meta(0x03, title)),
        (0, meta(0x01, composer)),
    ]
    events = []
    cursor = 0
    for pitch, duration in zip(pitches, durations):
        events.extend([
            (cursor, bytes([0x90, pitch, 88])),
            (cursor + duration, bytes([0x80, pitch, 0])),
        ])
        cursor += duration
    return midi([track(conductor + events, max(cursor, 1920))], 0)

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

    library = ROOT.parent / 'library'
    library.mkdir(parents=True, exist_ok=True)
    library_songs = [
        ('ode_to_joy', 'Ode to Joy - Beethoven', 'Beethoven',
         [64, 64, 65, 67, 67, 65, 64, 62, 60, 60, 62, 64, 64, 62, 62],
         [480, 480, 480, 480, 480, 480, 480, 480, 480, 480, 480, 480, 720, 240, 960], 4, 4),
        ('fur_elise', 'Fur Elise - Beethoven', 'Beethoven',
         [76, 75, 76, 75, 76, 71, 74, 72, 69, 60, 64, 69, 71, 60, 64, 71, 72, 64,
          76, 75, 76, 75, 76, 71, 74, 72, 69],
         [240] * 27, 4, 4),
        ('spring', 'Spring - Vivaldi', 'Vivaldi',
         [64, 64, 64, 62, 64, 67, 69, 69, 69, 67, 69, 72, 71, 69, 67, 64],
         [240, 240, 480, 240, 240, 480, 240, 240, 480, 240, 240, 480, 240, 240, 240, 960], 4, 4),
        ('canon_in_d', 'Canon in D - Pachelbel', 'Pachelbel',
         [66, 69, 67, 66, 64, 62, 64, 66, 67, 69, 71, 69, 67, 66, 64, 62],
         [480] * 15 + [960], 4, 4),
        ('twinkle', 'Twinkle Twinkle Little Star - traditional', 'Traditional',
         [60, 60, 67, 67, 69, 69, 67, 65, 65, 64, 64, 62, 62, 60],
         [480, 480, 480, 480, 480, 480, 960, 480, 480, 480, 480, 480, 480, 960], 4, 4),
        ('the_entertainer', 'The Entertainer - Scott Joplin', 'Scott Joplin',
         [63, 64, 72, 69, 69, 72, 75, 76, 72, 69, 67, 69, 72, 69, 64, 63, 64],
         [240, 240, 480, 480, 240, 240, 480, 480, 240, 240, 480, 480, 240, 240, 480, 240, 960], 4, 4),
        ('mary_had_a_little_lamb', 'Mary Had a Little Lamb - American traditional', 'American traditional',
         [64, 62, 60, 62, 64, 64, 64, 62, 62, 62, 64, 67, 67,
          64, 62, 60, 62, 64, 64, 64, 64, 62, 62, 64, 62, 60],
         [480, 480, 480, 480, 480, 480, 960, 480, 480, 960, 480, 480, 960,
          480, 480, 480, 480, 480, 480, 480, 480, 480, 480, 480, 480, 960], 4, 4),
        ('frere_jacques', 'Frere Jacques - French traditional', 'French traditional',
         [60, 62, 64, 60, 60, 62, 64, 60, 64, 65, 67, 64, 65, 67, 67, 69,
          67, 65, 64, 60, 67, 69, 67, 65, 64, 60, 60, 67, 60, 60, 67, 60],
         [480] * 32, 4, 4),
        ('auld_lang_syne', 'Auld Lang Syne - Scottish traditional', 'Scottish traditional',
         [67, 60, 60, 60, 64, 62, 60, 62, 64, 60, 67, 67, 64, 62, 60, 62, 64, 67,
          69, 67, 65, 64, 60, 60, 67, 67, 64, 62, 60, 62, 64, 60],
         [240, 720, 480, 480, 720, 480, 480, 480, 480, 960, 480, 480, 720, 480, 480, 480,
          480, 960, 480, 480, 720, 480, 480, 480, 480, 960, 480, 480, 720, 480, 480, 960], 2, 4),
        ('yankee_doodle', 'Yankee Doodle - American traditional', 'American traditional',
         [60, 60, 62, 64, 60, 64, 62, 60, 62, 64, 60, 60, 62, 64, 60, 64,
          62, 60, 62, 64, 62, 62, 64, 62, 60, 62, 64, 60],
         [240, 240, 240, 240, 240, 240, 240, 240, 240, 240, 480, 240, 240, 240,
          240, 240, 240, 240, 240, 240, 480, 240, 240, 240, 240, 240, 240, 960], 4, 4),
        ('brahms_lullaby', 'Lullaby - Johannes Brahms', 'Johannes Brahms',
         [67, 67, 71, 67, 67, 71, 67, 71, 74, 72, 71, 69, 69, 71, 72, 69,
          67, 67, 71, 67, 67, 71, 67, 71, 74, 72, 71, 69, 67, 67, 60],
         [240, 240, 720, 240, 240, 720, 480, 480, 480, 480, 960, 240, 240, 720, 240, 240,
          720, 240, 240, 720, 240, 240, 720, 480, 480, 480, 480, 960, 240, 240, 720], 3, 4),
        ('minuet_in_g', 'Minuet in G - Christian Petzold', 'Christian Petzold',
         [62, 67, 69, 71, 67, 64, 60, 62, 64, 65, 67, 69, 71, 72, 74, 71,
          69, 67, 65, 64, 62, 60, 62, 67, 69, 71, 67, 64, 60, 62, 64, 65],
         [480] * 32, 3, 4),
    ]
    for filename, title, composer, pitches, durations, time_numerator, time_denominator in library_songs:
        (library / f'{filename}.mid').write_bytes(authored_melody(
            title, composer, pitches, durations,
            time_numerator=time_numerator,
            time_denominator=time_denominator,
        ))

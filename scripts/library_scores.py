# SPDX-License-Identifier: Apache-2.0
"""Measure-checked teaching melodies. Authored music data: CC0-1.0.

Durations are sixteenth-note units (120 MIDI ticks). R means rest; ~ continues
one sounding note across a bar, without a second attack. See content/library.
"""
import re


def notes(bars, meter):
    result = []
    bar_units = meter[0] * 16 // meter[1]
    for index, bar in enumerate(bars.split('|'), 1):
        total = 0
        for token in bar.split():
            name, units = token.split(':') if ':' in token else (token, '4')
            duration = int(units) * 120
            total += int(units)
            if name == '~':
                if not result or result[-1][0] is None:
                    raise ValueError('Tie needs a preceding note')
                result[-1] = (result[-1][0], result[-1][1] + duration)
                continue
            match = re.fullmatch(r'([A-G])([#b]?)([3-5])', name)
            pitch = None if name == 'R' else (12 * (int(match[3]) + 1)
                + {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}[match[1]]
                + {'': 0, '#': 1, 'b': -1}[match[2]])
            result.append((pitch, duration))
        if total != bar_units:
            raise ValueError(f'Bar {index}: {total} units, expected {bar_units}: {bar}')
    return result


SONGS = {}
def add(key, title, composer, bars, meter=(4, 4), tempo=100):
    SONGS[key] = dict(title=title, composer=composer, bars=bars, meter=meter,
                      tempo=tempo, notes=notes(bars, meter))

ode_a = 'E4 E4 F4 G4 | G4 F4 E4 D4 | C4 C4 D4 E4'
ode_end = 'D4:6 C4:2 C4:8'
add('ode_to_joy', 'Ode to Joy - Beethoven', 'Beethoven',
    f'{ode_a} | E4:6 D4:2 D4:8 | {ode_a} | {ode_end} | '
    'D4 D4 E4 C4 | D4 E4:2 F4:2 E4 C4 | D4 E4:2 F4:2 E4 D4 | C4 D4 G3:8 | '
    f'{ode_a} | {ode_end}')

elise = ('E5:1 D#5:1 E5:1 B4:1 D5:1 C5:1 | A4:2 R:1 C4:1 E4:1 A4:1 | '
         'B4:2 R:1 E4:1 G#4:1 B4:1 | C5:2 R:1 E4:1 E5:1 D#5:1 | '
         'E5:1 D#5:1 E5:1 B4:1 D5:1 C5:1 | A4:2 R:1 C4:1 E4:1 A4:1 | '
         'B4:2 R:1 E4:1 C5:1 B4:1')
add('fur_elise', 'Fur Elise - opening theme', 'Beethoven',
    f'R:4 E5:1 D#5:1 | {elise} | A4:4 E5:1 D#5:1 | {elise} | A4:4 R:2', (3, 8), 72)

spring_a = 'G#4:2 G#4:2 G#4:2 F#4:1 E4:1 B4:6 B4:1 A4:1'
spring_b = 'G#4:2 A4:1 B4:1 A4:2 G#4:2 F#4:2 D#4:2 B3:2 E4:2'
spring_c = 'B4:2 A4:1 G#4:1 A4:2 B4:2 C#5:2 B4:4 E4:2'
add('spring', 'Spring - opening theme', 'Vivaldi',
    f'R:14 E4:2 | {spring_a} | {spring_a} | {spring_b} | {spring_a} | {spring_a} | '
    'G#4:2 A4:1 B4:1 A4:2 G#4:2 F#4:4 R:2 E4:2 | '
    f'{spring_c} | {spring_c} | C#5:2 B4:4 A4:2 G#4:2 F#4:1 E4:1 F#4:4 | '
    'E4:4 R:2 E4:2 B4:2 A4:1 G#4:1 A4:2 B4:2 | '
    'C#5:2 B4:4 E4:2 B4:2 A4:1 G#4:1 A4:2 B4:2 | '
    'C#5:2 B4:4 E4:2 C#5:2 B4:4 A4:2 | G#4:2 F#4:1 E4:1 F#4:4 E4:8', tempo=100)

canon = ('F#5 E5 D5 C#5 | B4 A4 B4 C#5 | D5 C#5 B4 A4 | G4 F#4 G4 E4 | '
         'D4:2 F#4:2 A4:2 G4:2 F#4:2 D4:2 F#4:2 E4:2 | '
         'D4:2 A3:2 D4:2 B4:2 A4:2 C#5:2 B4:2 A4:2 | '
         'F#4:2 D4:2 E4:2 C#5:2 D5:2 F#5:2 A5:2 A4:2 | D5:16')
add('canon_in_d', 'Canon in D - opening study, twice', 'Pachelbel', f'{canon} | {canon}', tempo=80)

twinkle_a = 'C4 C4 G4 G4 | A4 A4 G4:8 | F4 F4 E4 E4 | D4 D4 C4:8'
add('twinkle', 'Twinkle Twinkle Little Star - traditional', 'Traditional',
    f'{twinkle_a} | G4 G4 F4 F4 | E4 E4 D4:8 | G4 G4 F4 F4 | E4 E4 D4:8 | {twinkle_a}')

rag_a = 'E4:1 C5:2 E4:1 C5:2 E4:1 C5:1'
rag_b = '~:4 ~:1 C5:1 D5:1 D#5:1'
rag_c = 'E5:1 C5:1 D5:1 E5:2 B4:1 D5:2'
rag_d = 'C5:6 D4:1 D#4:1'
add('the_entertainer', 'The Entertainer - first strain', 'Scott Joplin',
    f'R:6 D4:1 D#4:1 | {rag_a} | {rag_b} | {rag_c} | {rag_d} | '
    f'{rag_a} | ~:6 A4:1 G4:1 | F#4:1 A4:1 C5:1 E5:2 D5:1 C5:1 A4:1 | D5:6 D4:1 D#4:1 | '
    f'{rag_a} | {rag_b} | {rag_c} | C5:6 C5:1 D5:1 | '
    'E5:1 C5:1 D5:1 E5:2 C5:1 D5:1 C5:1 | E5:1 C5:1 D5:1 E5:2 C5:1 D5:1 C5:1 | '
    f'{rag_c} | C5:6 R:2', (2, 4), 80)

mary = ('E4 D4 C4 D4 | E4 E4 E4:8 | D4 D4 D4:8 | E4 G4 G4:8 | '
        'E4 D4 C4 D4 | E4 E4 E4 E4 | D4 D4 E4 D4 | C4:16')
add('mary_had_a_little_lamb', 'Mary Had a Little Lamb - twice', 'American traditional', f'{mary} | {mary}')
frere = ('C4 D4 E4 C4 | C4 D4 E4 C4 | E4 F4 G4:8 | E4 F4 G4:8 | '
         'G4:2 A4:2 G4:2 F4:2 E4 C4 | G4:2 A4:2 G4:2 F4:2 E4 C4 | C4 G3 C4:8 | C4 G3 C4:8')
add('frere_jacques', 'Frere Jacques - twice', 'French traditional', f'{frere} | {frere}')
add('auld_lang_syne', 'Auld Lang Syne - verse and chorus', 'Scottish traditional',
    'R:12 G3 | C4:6 B3:2 C4 E4 | D4:6 C4:2 D4 E4:2 D4:2 | C4:6 C4:2 E4 G4 | A4:12 A4 | '
    'G4:6 E4:2 E4 C4 | D4:6 C4:2 D4 E4:2 D4:2 | C4:6 A3:2 A3 G3 | C4:12 A4 | '
    'G4:6 E4:2 E4 C4 | D4:6 C4:2 D4 A4 | G4:6 E4:2 E4 G4 | A4:12 C5 | '
    'G4:6 E4:2 E4 C4 | D4:6 C4:2 D4 E4:2 D4:2 | C4:6 A3:2 A3 G3 | C4:12 R:4', tempo=88)
yankee = ('C4:2 C4:2 D4:2 E4:2 | C4:2 E4:2 D4:2 G3:2 | C4:2 C4:2 D4:2 E4:2 | C4:4 B3:4 | '
          'C4:2 C4:2 D4:2 E4:2 | F4:2 E4:2 D4:2 C4:2 | B3:2 G3:2 A3:2 B3:2 | C4:4 C4:4 | '
          'A3:3 B3:1 A3:2 G3:2 | A3:2 B3:2 C4:4 | G3:3 A3:1 G3:2 F3:2 | E3:4 G3:4 | '
          'A3:3 B3:1 A3:2 G3:2 | A3:2 B3:2 C4:2 A3:2 | G3:2 C4:2 B3:2 D4:2 | C4:4 C4:4')
add('yankee_doodle', 'Yankee Doodle - verse and chorus, twice', 'American traditional', f'{yankee} | {yankee}', (2, 4))
add('brahms_lullaby', 'Lullaby - vocal melody', 'Johannes Brahms',
    'R:8 E4:2 E4:2 | G4:6 E4:2 E4 | G4 R:4 E4:2 G4:2 | C5 B4:6 A4:2 | A4 G4 D4:2 E4:2 | '
    'F4 D4 D4:2 E4:2 | F4 R:4 D4:2 F4:2 | B4:2 A4:2 G4 B4 | C5 R:4 C4:2 C4:2 | '
    'C5:8 A4:2 F4:2 | G4:8 E4:2 C4:2 | F4 G4 A4 | G4:8 C4:2 C4:2 | '
    'C5:8 A4:2 F4:2 | G4:8 E4:2 C4:2 | F4 E4 D4 | C4:8 R:4', (3, 4), 84)
minuet_a = ('D5 G4:2 A4:2 B4:2 C5:2 | D5 G4 G4 | E5 C5:2 D5:2 E5:2 F#5:2 | G5 G4 G4 | '
            'C5 D5:2 C5:2 B4:2 A4:2 | B4 C5:2 B4:2 A4:2 G4:2')
add('minuet_in_g', 'Minuet in G - both sections', 'Christian Petzold',
    f'{minuet_a} | F#4 G4:2 A4:2 B4:2 G4:2 | A4:12 | {minuet_a} | A4 B4:2 A4:2 G4:2 F#4:2 | G4:12 | '
    'B5 G5:2 A5:2 B5:2 G5:2 | A5 D5:2 E5:2 F#5:2 D5:2 | G5 E5:2 F#5:2 G5:2 D5:2 | C#5 B4:2 C#5:2 A4 | '
    'A4:2 B4:2 C#5:2 D5:2 E5:2 F#5:2 | G5 F#5 E5 | F#5 A4 C#5 | D5:12 | '
    'D5 G4:2 F#4:2 G4 | E5 G4:2 F#4:2 G4 | D5 C5 B4 | A4:2 G4:2 F#4:2 G4:2 A4 | '
    'D4:2 E4:2 F#4:2 G4:2 A4:2 B4:2 | C5 B4 A4 | B4:2 D5:2 G4 F#4 | G4:12', (3, 4), 100)
# Bring the whole Minuet down one octave, preserving every interval.
SONGS['minuet_in_g']['notes'] = [(p - 12 if p is not None else None, d) for p, d in SONGS['minuet_in_g']['notes']]

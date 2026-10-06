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
            if int(units) <= 0:
                raise ValueError(f'Bar {index}: duration must be positive: {token}')
            duration = int(units) * 120
            total += int(units)
            if name == '~':
                if not result or result[-1][0] is None:
                    raise ValueError('Tie needs a preceding note')
                result[-1] = (result[-1][0], result[-1][1] + duration)
                continue
            match = re.fullmatch(r'([A-G])([#b]?)([3-5])', name)
            if name != 'R' and match is None:
                raise ValueError(f'Bar {index}: invalid note: {name}')
            pitch = None if name == 'R' else (12 * (int(match[3]) + 1)
                + {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11}[match[1]]
                + {'': 0, '#': 1, 'b': -1}[match[2]])
            result.append((pitch, duration))
        if total != bar_units:
            raise ValueError(f'Bar {index}: {total} units, expected {bar_units}: {bar}')
    return result


SONGS = {}
def add(key, title, composer, bars, meter=(4, 4), tempo=100, transpose=0):
    melody = [(pitch + transpose if pitch is not None else None, duration)
              for pitch, duration in notes(bars, meter)]
    SONGS[key] = dict(title=title, composer=composer, bars=bars, meter=meter,
                      tempo=tempo, transpose=transpose, notes=melody)

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
add('canon_in_d', 'Canon in D - opening study, twice', 'Pachelbel', f'{canon} | {canon}', tempo=80, transpose=-12)

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
    'D4:2 E4:2 F#4:2 G4:2 A4:2 B4:2 | C5 B4 A4 | B4:2 D5:2 G4 F#4 | G4:12', (3, 4), 100, transpose=-12)

row = ('C4 C4 C4 D4 | E4:8 E4 D4 | E4 F4 G4:8 | C5 C5 C5 G4 | '
       'G4 G4 E4 E4 | E4 C4 C4 C4 | G4 F4 E4 D4 | C4:16')
add('row_your_boat', 'Row, Row, Row Your Boat - twice', 'Traditional', f'{row} | {row}', tempo=96)

jingle = ('E4 E4 E4:8 | E4 E4 E4:8 | E4 G4 C4 D4 | E4:16 | '
          'F4 F4 F4 F4 | F4 E4 E4:8 | E4 D4 D4 E4 | D4:8 G4:8')
jingle_end = ('E4 E4 E4:8 | E4 E4 E4:8 | E4 G4 C4 D4 | E4:16 | '
              'F4 F4 F4 F4 | F4 E4 E4:8 | G4 G4 F4 D4 | C4:16')
add('jingle_bells', 'Jingle Bells - simplified refrain', 'James Lord Pierpont',
    f'{jingle} | {jingle_end}', tempo=116)

# Both sections of the traditional melody; padded quarter-note pickup.
greensleeves = ('R:8 A4 | C5:8 D5 | E5:6 F5:2 E5 | D5:8 B4 | G4:6 A4:2 B4 | '
               'C5:8 A4 | A4:6 G#4:2 A4 | B4:8 G#4 | E4:8 A4 | '
               'C5:8 D5 | E5:6 F5:2 E5 | D5:8 B4 | G4:6 A4:2 B4 | '
               'C5:6 B4:2 A4 | G#4:6 F#4:2 G#4 | A4:12 | A4:12 | '
               'G5:12 | G5:6 F5:2 E5 | D5:8 B4 | G4:6 A4:2 B4 | '
               'C5:8 A4 | A4:6 G#4:2 A4 | B4:8 G#4 | E4:12 | '
               'G5:12 | G5:6 F5:2 E5 | D5:8 B4 | G4:6 A4:2 B4 | '
               'C5:6 B4:2 A4 | G#4:6 F#4:2 G#4 | A4:12 | A4:12')
add('greensleeves', 'Greensleeves - melody study', 'Traditional', greensleeves,
    (3, 4), 90, transpose=-12)

# Familiar single-line teaching versions; historical melody references and
# deliberate simplifications are recorded in content/library/README.md.
amazing = ('R:8 G3 | C4:6 E4:2 C4 | E4:8 D4 | C4:8 A3 | G3:8 G3 | '
           'C4:6 E4:2 C4 | E4:8 D4 | G4:12 | ~:8 E4:2 G4:2 | '
           'G4:6 E4:2 C4 | E4:8 D4 | C4:8 A3 | G3:8 G3 | '
           'C4:6 E4:2 C4 | E4:8 D4 | C4:12 | ~:8 R:4')
add('amazing_grace', 'Amazing Grace - New Britain melody', 'Traditional',
    amazing, (3, 4), 80)

london = ('G4:2 A4:2 G4:2 F4:2 | E4:2 F4:2 G4:4 | D4:2 E4:2 F4:4 | E4:2 F4:2 G4:4 | '
          'G4:2 A4:2 G4:2 F4:2 | E4:2 F4:2 G4:4 | D4:4 G4:4 | E4:2 C4:6')
add('london_bridge', 'London Bridge - twice', 'English traditional',
    f'{london} | {london}', (2, 4), 80)

add('old_macdonald', 'Old MacDonald Had a Farm - melody study', 'Traditional',
    'C4 C4 C4 G3 | A3 A3 G3:8 | E4 E4 D4 D4 | C4:12 R:4 | '
    'G3:2 G3:2 C4 C4 C4 | G3:2 G3:2 C4 C4 C4 | '
    'C4:2 C4:2 C4 C4:2 C4:2 C4 | C4:2 C4:2 C4:2 C4:2 C4:8 | '
    'C4 C4 C4 G3 | A3 A3 G3:8 | E4 E4 D4 D4 | C4:12 R:4', tempo=96)

add('when_the_saints', 'When the Saints Go Marching In - melody study', 'Traditional',
    'R:4 C4 E4 F4 | G4:16 | R:4 C4 E4 F4 | G4:16 | '
    'R:4 C4 E4 F4 | G4:8 E4:8 | C4:8 E4:8 | D4:12 R:4 | '
    'R:8 E4 D4 | C4:8 C4:8 | E4:8 G4 G4 | F4:16 | '
    'R:4 E4 F4 G4 | E4:8 C4:8 | D4:8 C4:8 | C4:12 R:4', tempo=100)

aura = ('G3 C4 B3 C4 | D4 A3 D4:8 | C4 B3 A3 B3 | C4:12 R:4')
add('aura_lee', 'Aura Lee - verse and refrain', 'George R. Poulton',
    f'{aura} | {aura} | E4 E4 E4:8 | E4 E4 E4:8 | E4:6 D4:2 C4 D4 | E4:16 | '
    'E4 E4 F4:6 E4:2 | D4 A3 D4:6 D4:2 | D4:2 C4:6 E4:6 D4:2 | C4:12 R:4',
    tempo=88)

add('silent_night', 'Silent Night - melody', 'Franz Xaver Gruber',
    'G4:6 A4:2 G4:4 | E4:12 | G4:6 A4:2 G4:4 | E4:12 | '
    'D5:8 D5:4 | B4:12 | C5:8 C5:4 | G4:12 | '
    'A4:8 A4:4 | C5:6 B4:2 A4:4 | G4:6 A4:2 G4:4 | E4:12 | '
    'A4:8 A4:4 | C5:6 B4:2 A4:4 | G4:6 A4:2 G4:4 | E4:12 | '
    'D5:8 D5:4 | F5:6 D5:2 B4:4 | C5:12 | E5:12 | '
    'C5:4 G4:4 E4:4 | G4:6 F4:2 D4:4 | C4:12 | ~:8 R:4', (6, 8), 72, transpose=-12)

camptown = ('G4:2 G4:2 E4:2 G4:2 | A4:2 G4:2 E4:4 | E4:2 D4:6 | E4:2 D4:6 | '
            'G4:2 G4:2 E4:2 G4:2 | A4:2 G4:2 E4:4 | D4:2 D4:2 E4:2 D4:2 | C4:6 R:2 | '
            'C4:2 C4:2 E4:2 G4:2 | C5:8 | A4:2 A4:2 C5:2 A4:2 | G4:8 | '
            'G4:2 G4:2 E4:2 G4:2 | A4:2 G4:2 E4:4 | D4:2 D4:2 E4:2 D4:2 | C4:6 R:2')
add('camptown_races', 'Camptown Races - melody study, twice', 'Stephen Foster',
    f'{camptown} | {camptown}', (2, 4), 96)

clair = ('C4 C4 C4 D4 | E4:8 D4:8 | C4 E4 D4 D4 | C4:16')
add('au_clair_de_la_lune', 'Au Clair de la Lune - melody', 'French traditional',
    f'{clair} | {clair} | D4 D4 D4 D4 | A3:8 A3:8 | D4 C4 B3 A3 | G3:16 | {clair}', tempo=88)

hot_cross = ('E4 D4 C4:8 | E4 D4 C4:8 | '
             'C4:2 C4:2 C4:2 C4:2 D4:2 D4:2 D4:2 D4:2 | E4 D4 C4:8')
add('hot_cross_buns', 'Hot Cross Buns - three times', 'English traditional',
    f'{hot_cross} | {hot_cross} | {hot_cross}', tempo=80)

add('simple_gifts', 'Simple Gifts - Shaker melody study', 'Joseph Brackett',
    'R:12 G3:2 G3:2 | C4 C4:2 D4:2 E4:2 C4:2 E4:2 F4:2 | '
    'G4 G4:2 G4:2 E4 D4:2 C4:2 | D4 D4 D4 D4 | D4:2 E4:2 D4:2 B3:2 G3 G3 | '
    'C4:2 B3:2 C4:2 D4:2 E4 D4:2 D4:2 | E4 F4 G4:6 G4:2 | '
    'D4 D4:2 E4:2 D4 C4:2 C4:2 | D4 C4:2 B3:2 D4:8 | '
    'G4:8 E4:6 D4:2 | E4:2 F4:2 E4:2 D4:2 C4:6 D4:2 | '
    'E4 E4:2 F4:2 G4 E4 | D4 D4:2 E4:2 D4:6 G3:2 | '
    'C4:8 C4:6 D4:2 | E4 E4:2 F4:2 G4 G4:2 G4:2 | '
    'D4 D4 E4 E4:2 D4:2 | C4 C4 C4:8', tempo=88)

# Single-line 1894 Sakura melody, transposed down a perfect fourth.
# The fixed E/B practice bass avoids imposing a major-key chord progression.
add('sakura_sakura', 'Sakura Sakura - melody study', 'Japanese traditional',
    'A4 A4 B4:8 | A4 A4 B4:8 | A4 B4 C5 B4 | A4 B4:2 A4:2 F4:8 | '
    'E4 C4 E4 F4 | E4 E4:2 C4:2 B3:8 | '
    'A4 B4 C5 B4 | A4 B4:2 A4:2 F4:8 | E4 C4 E4 F4 | E4 E4:2 C4:2 B3:8 | '
    'A4 A4 B4:8 | A4 A4 B4:8 | D4 E4 F4:8 | B4:2 A4:2 F4 E4:8', tempo=80)

weasel = ('C4:4 C4:2 D4:4 D4:2 | E4:2 G4:2 E4:2 C4:6 | '
          'C4:4 C4:2 D4:4 D4:2 | E4:6 C4:2 R:4 | '
          'C4:4 C4:2 D4:4 D4:2 | E4:2 G4:2 E4:2 C4:6 | '
          'A4:2 R:4 D4:4 F4:2 | E4:6 C4:2 R:4')
add('pop_goes_the_weasel', 'Pop Goes the Weasel - twice', 'English traditional',
    f'{weasel} | {weasel}', (6, 8), 90)

add('home_on_the_range', 'Home on the Range - verse and chorus', 'Daniel E. Kelley',
    'R:8 G3 | G3 C4 D4 | E4:8 C4:2 B3:2 | A3 F4 F4 | F4:8 E4:2 F4:2 | '
    'G4:6 C4:2 C4 | C4 B3 C4 | D4:12 | ~:4 R:4 G3:2 G3:2 | '
    'G3 C4 D4 | E4:8 C4:2 B3:2 | A3 F4 F4 | F4:8 F4:2 F4:2 | '
    'E4:6 D4:2 C4 | B3 C4 D4 | C4:12 | ~:4 R:8 | '
    'G4:12 | F4 E4:6 D4:2 | E4:12 | ~:4 R:4 G3:2 G3:2 | '
    'C4:6 C4:2 C4 | C4 B3 C4 | D4:12 | ~:4 R:4 G3:2 G3:2 | '
    'G3 C4 D4 | E4:8 C4:2 B3:2 | A3 F4 F4 | F4:8 F4:2 F4:2 | '
    'E4:6 D4:2 C4 | B3 C4 D4 | C4:12 | ~:4 R:8', (3, 4), 84)

susanna_open = ('E4 G4 G4:6 A4:2 | G4 E4 C4:6 D4:2')
add('oh_susanna', 'Oh! Susanna - melody study', 'Stephen Foster',
    f'R:12 C4:2 D4:2 | {susanna_open} | E4 E4 D4 C4 | D4:12 C4:2 D4:2 | '
    f'{susanna_open} | E4 E4 D4 D4 | C4:12 R:4 | '
    'F4:8 F4:8 | A4 C5:8 A4 | G4 G4 E4 C4 | D4:12 C4:2 D4:2 | '
    f'{susanna_open} | E4 E4 D4 D4 | C4:12 R:4', tempo=100)

# Deliberately simple practice basses. Except for the Canon ground bass, these
# are editorial additions, not the composers' accompaniment. Each root lasts one bar;
# the MIDI recipe plays it, then its fifth, as two separate low notes.
# A tuple instead specifies each successive bass pitch within that bar.
BASS_ROOTS = {
    'ode_to_joy': [48, 43, 48, 43, 48, 43, 48, 48, 43, 43, 48, 48, 43, 43, 48, 48],
    'fur_elise': [45, 52, 45, 52, 45, 52, 45, 52, 45, 52, 45, 52, 45, 52, 45, 45, 45],
    'spring': [40, 40, 47, 40, 45, 40, 47, 40, 45, 40, 47, 40, 45, 47],
    # Four ground-bass notes per bar, matching the melody's harmonic pace.
    # The final study bar uses an authored tonic/fifth cadence.
    'canon_in_d': ([(50, 45, 47, 42), (43, 50, 43, 45)] * 3
                   + [(50, 45, 47, 42), 50]) * 2,
    'twinkle': [48, 48, 41, 48, 43, 48, 43, 48, 48, 48, 41, 48],
    'the_entertainer': [48, 48, 43, 48, 41, 48, 43, 48, 43, 48, 43, 48, 41, 48, 43, 48, 48],
    'mary_had_a_little_lamb': [48, 48, 43, 48, 48, 48, 43, 48] * 2,
    'frere_jacques': [48, 48, 43, 43, 41, 41, 48, 48] * 2,
    'auld_lang_syne': [48, 48, 43, 48, 41, 48, 43, 48, 48, 48, 43, 48, 41, 48, 43, 48, 48],
    'yankee_doodle': [48, 43, 48, 43, 48, 41, 43, 48, 41, 48, 43, 48, 41, 48, 43, 48] * 2,
    'brahms_lullaby': [48, 48, 43, 48, 41, 43, 48, 43, 48, 41, 48, 41, 48, 41, 43, 48, 48],
    'minuet_in_g': [43, 43, 48, 43, 48, 43, 50, 43, 43, 48, 43, 48, 43, 50, 43, 43,
                    43, 50, 43, 48, 43, 50, 43, 50, 43, 48, 43, 48, 43, 50, 43, 43],
    'row_your_boat': [48, 48, 41, 48, 48, 48, 43, 48] * 2,
    'jingle_bells': [48, 48, 48, 48, 41, 48, 43, 43, 48, 48, 48, 48, 41, 48, 43, 48],
    'greensleeves': [45, 45, 48, 43, 43, 45, 41, 40, 40, 45, 48, 43, 43, 45, 40, 45, 45,
                      48, 48, 43, 43, 45, 41, 40, 40, 48, 48, 43, 43, 45, 40, 45, 45],
    'amazing_grace': [48, 48, 48, 45, 43, 48, 48, 43, 43, 48, 48, 45, 43, 48, 43, 48, 48],
    'london_bridge': [48, 48, 43, 48, 48, 48, 43, 48] * 2,
    'old_macdonald': [48, 41, 43, 48, 48, 48, 48, 43, 48, 41, 43, 48],
    'when_the_saints': [48, 48, 48, 48, 48, 48, 48, 43, 43, 48, 48, 41, 41, 48, 43, 48],
    'aura_lee': [48, 50, 43, 48, 48, 50, 43, 48, 48, 48, 48, 48, 41, 50, 50, 48],
    'silent_night': [48, 48, 48, 48, 43, 43, 48, 48, 41, 41, 48, 48,
                     41, 41, 48, 48, 43, 43, 48, 48, 48, 43, 48, 48],
    'camptown_races': [48, 48, 43, 43, 48, 48, 43, 48, 48, 48, 41, 48, 48, 48, 43, 48] * 2,
    'au_clair_de_la_lune': [48, 48, 43, 48, 48, 48, 43, 48, 50, 50, 43, 43, 48, 48, 43, 48],
    'hot_cross_buns': [48, 48, 43, 48] * 3,
    'simple_gifts': [43, 48, 48, 43, 43, 48, 48, 43, 43, 48, 48, 48, 43, 48, 48, 43, 48],
    'sakura_sakura': [40] * 14,
    'pop_goes_the_weasel': [48, 48, 43, 48, 48, 48, 41, 48] * 2,
    'home_on_the_range': [43, 48, 48, 41, 41, 48, 48, 43, 43, 48, 48, 41, 41, 48, 43, 48, 48,
                          48, 43, 48, 48, 48, 48, 43, 43, 48, 48, 41, 41, 48, 43, 48, 48],
    'oh_susanna': [48, 48, 48, 48, 43, 48, 48, 43, 48, 41, 41, 48, 43, 48, 48, 43, 48],
}
for key, song in SONGS.items():
    roots = BASS_ROOTS[key]
    if len(roots) != len(song['bars'].split('|')):
        raise ValueError(f'{key}: bass progression must cover every bar')
    song['bass_roots'] = roots

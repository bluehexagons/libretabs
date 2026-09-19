# Playing with LibreTabs

[Open the player](https://bluehexagons.github.io/libretabs/play/) · [Downloads](https://github.com/bluehexagons/libretabs/releases) · [Back to README](../README.md)

LibreTabs shows you where to play notes on a six-string guitar, plays a reference
sound, and helps you repeat music at your own pace. You can start with the built-in
music; you do not need a music file or an account. It does not listen to your
guitar, tell you whether you played correctly, or tune your instrument.

This guide describes the current prototype. The planned six-lesson course is
not yet available. Generated guitar arrangements and notation still need musician
review; treat them as practice suggestions.

## Your first five minutes

1. Open the player. An exercise is already loaded. Read **Quick start**, then
   choose **Start practicing** to close the guide. This does not start the sound.
2. Press **Play** and listen once without playing your guitar. The clicks before
   the music are a **count-in**: time to get ready. The moving line follows the
   music, and outlined numbers show the notes sounding now.
3. Open **Menu → Playback** and choose a slower speed, such as **50%** under
   **Speed presets**. That means half the original speed, with the same pitches.
   Choose **Stop** to return to the beginning, then **Play** to try again.
4. Follow just a few numbers on the guitar tabs, using the reading guide below.
   It is fine to listen again before joining in.
5. To repeat a short section, open **Menu → Loop**, set **From** to **1** and
   **Through** to **2**, then choose **Turn loop on**. Close the menu and press
   **Play**. Both measures repeat. Choose **Turn loop off** when you want to
   continue through the song.

For another tune, open **Menu → Songs** and look for **Starter** choices, such as
Twinkle, Twinkle Little Star. These have simpler rhythms and smaller note ranges;
they are still generated practice arrangements. Some tunes begin with silence.
Wait for the moving line to reach the first note.

## Read the guitar tabs

**Tablature**, usually called **tabs**, is a map of the guitar strings. Read it
from left to right. The six horizontal lines represent strings, not musical
pitches on a staff:

| Tab line, top to bottom | Guitar string | Standard open-string note |
| --- | --- | --- |
| Top | 1 · thinnest, highest sounding | E |
| Second | 2 | B |
| Third | 3 | G |
| Fourth | 4 | D |
| Fifth | 5 | A |
| Bottom | 6 · thickest, lowest sounding | E |

A **fret** is a metal strip across the guitar neck. A number on a tab line tells
you which fret to use on that string, not which finger to use. For **3**, press
the string just behind the third metal fret, on the side toward the headstock,
then pluck that string. **0** means pluck the open string without pressing it.
Numbers lined up vertically ask for notes at the same time; this is a **chord**.

The tabs assume **standard tuning**: E–A–D–G–B–E from thickest to thinnest string.
Use a separate tuner if needed. Changing the app's handed layout changes where
controls sit; it does not reverse the tab lines or change the tuning.

## Follow the timing

A **beat** is the regular pulse you can count or tap along with. A **measure**
(also called a bar) groups beats between vertical dividing lines. A **rest** is
written silence: do not start a note there.

The five-line **staff** is the sheet music reference. Higher positions mean
higher pitches, and note shapes describe how long notes last. You can begin with
the tabs and learn the staff gradually. In this player, a quarter note lasts one
beat, a half note two, and an eighth note half a beat. A dot adds half the note's
length; a tie joins notes of the same pitch into one held sound. Guitar treble
notation is written an octave higher than it sounds: the same note name in the
next higher register.

Open brackets mark upcoming notes; complete outlines mark sounding notes. These
are playback cues, not feedback about your playing. Fret numbers remain the
instruction even when colors or optional shapes are shown. **!** or **△** means
there is an arrangement warning; open **Songs → About this arrangement**.

The prototype rounds rhythms for display. Playback keeps the imported timing,
so unusually detailed rhythms may not line up exactly with the simplified symbols.

## Choose music or open your own file

In **Menu → Songs**, choose a built-in melody or **Open MIDI file**. A **MIDI file**
contains note and timing instructions; it is not a recording such as an MP3,
a photograph of sheet music, or a guitar-tab document. Use a `.mid` or `.midi` file.

If several parts appear, use **Choose the part to practice**. A part is one line
of music or instrument from the file. The score shows the selected part. Try a
simple melody first; a whole piano or orchestral part may be difficult to fit on
a guitar. Drum-only files have no pitched part to turn into guitar tabs.

Current limits are Standard MIDI formats 0 and 1, 256 KiB per file, 32 tracks,
8,192 events, 2,048 notes, 256 measures and 10 minutes. These are maximum import
limits, not a promise that every file within them will make readable guitar music.
If import fails, try a shorter or simpler file; the previous song remains available.

Imported files stay on your device and are available only for the open session.
Reopen them after reloading or restarting. Preference saving does not save songs
or practice progress. See [privacy details](privacy.md).

## Adjust playback and repeat a passage

- **Playback speed:** 100% is the original speed; 50% is half speed. **Slower −5%**
  and **Faster +5%** make small changes. **Original speed** restores 100%. At 0%,
  playback pauses; raise the speed and press Play to continue.
- **Custom starting BPM:** BPM means beats per minute. A starting value of 60 is
  one beat per second. Later tempo changes keep their proportions. Changing speed
  changes how quickly notes arrive, not their pitch.
- **Beat clicks (metronome):** adds a click on each beat to help you keep time.
  **Count in before playing** adds preparation clicks on a fresh start; resuming
  after Pause continues immediately. Use Stop then Play for a fresh start.
- **Move to a passage:** click or tap the music to move playback there. The
  position slider also lets you move through the song. **Stop** returns to the
  beginning of the song, or the beginning of an enabled loop.
- **Loop:** From and Through include the first and last measures you choose.
  **Repeat this measure** sets and enables a one-measure loop. **Start at current
  measure** and **End at current measure** set the range from the current position.
- **Volume & parts:** adjust instrument and click volume separately. Use
  **Mute my part** to play your selected part yourself while hearing enabled
  other parts. Uncheck it to hear the reference again. **Hear part** controls
  the other parts; it does not change the selected score.

## Understand the arrangement choices

Open **Menu → Songs → About this arrangement → How do you want to play?**

| Choice | How to read it | What to check |
| --- | --- | --- |
| Basic tab | Suggested string and fret for each placed note, favoring low frets | Some notes cannot be placed; a displayed chord is not guaranteed comfortable |
| Strum with a pick | Sweep the bracketed string range; X asks you to touch a string lightly to keep it quiet | Crowded chords may leave notes out of the tab |
| Fingerpick | T = thumb; I, M, R = index, middle, ring of your picking hand | Suggestions use up to four picking fingers; they do not spread simultaneous notes into a sequence |

**B** marks a possible **barre**, where one fretting finger presses several strings
at the same fret. Check the warnings and included-note counts. Changing arrangement
style changes the tab suggestions; the staff and audio keep the source notes,
including notes omitted from the tab. MIDI generally does not say which guitar
finger, pick direction, slide or bend to use, so these tabs are not an exact
transcription of someone's guitar performance.

## Make the music easier to see

Open **Menu → Score view** for reading and layout choices:

- **Smooth scrolling** follows the music. **Manual pages** lets you read at your
  own pace. **Pages · follow playback** turns pages with the sound.
- Use the page arrows or swipe horizontally to turn a page. Turning pages
  manually turns off following without moving playback. Enable **Follow playback**
  to resume automatic turns. Tapping a position on the music does move playback.
- **Music lines** controls how many consecutive lines fit on screen. Fewer lines
  give each line more height. **Note spacing** changes the horizontal gaps;
  **Staff height** changes the height of the five-line sheet music reference.
- Add, reorder or resize sheet music, guitar-tab and piano rows. The piano row
  shows sounding notes; it is not a connected MIDI keyboard or a playing test.
  **Restore default rows** returns to the initial row layout.

**Theater** uses the window for more music and remembers a separate layout.
Try it on a desktop or tablet as well as a larger screen. Controls normally hide
when playback starts; **Show controls** or **F10** brings them back. In
**Menu → Theater**, enable **Keep controls visible while playing** if you prefer.
**Fullscreen** is a separate button; press it again or Escape to leave fullscreen.
Theater does not connect to a TV itself; use your device's screen-mirroring controls.

**Menu → Appearance & text** includes lettering, text size, light/dark appearance,
reduced motion, optional shape cues, control location and preferred hand. Text size
changes controls; use score layout or music zoom to improve music readability.
For a stationary reading view, choose Manual pages as well as reduced motion.

## Print, capture and play reference notes

**Menu → Print your music:** choose tabs, sheet music or both, a measure range,
and A4 or US Letter. Select **Prepare pages**, then **Save printable file**.
Open the saved `libretabs-score.html` in a browser and print or choose Save as PDF.
Use the matching paper size and turn off browser headers and footers. The file
works offline and retains the prototype's arrangement limitations.

**Menu → Capture & overlay:** choose the music, background and placement, then
**Enter capture view** for a score-only layout. Use separate recording or streaming
software to record it; LibreTabs does not record video. F8, Escape or a tap returns
to the player. Space still plays or pauses. Entering capture does not start audio.

**Menu → Keyboard notes:** play reference pitches with your computer keyboard.
The default Z X C V B N M comma keys play C D E F G A B C; S D G H J play the
intervening black piano keys. Hold a key to sustain its note, then release it.
Minus and equals lower or raise the register by an octave. An alternate A-row
layout is available; **Help** lists its keys. These keys work with menus closed,
including while paused, and do not record notes or assess your playing.

## Get help and recover

Open **Menu → Quick start** to reread the introduction or change **Show on startup**.
**Menu → Help** explains the symbols and shortcuts. Hover over a control for a
hint, hold an action button on touch, or focus a control and press F1.
Tab moves keyboard focus. With menus closed, Space plays or pauses; left/right
arrows move by measure or turn a manual page. When the position slider has focus,
arrows move one beat, Page Up/Down one measure, and Home/End to the start/end.

| Problem | Try this |
| --- | --- |
| No sound | Press Play, check device/browser volume, raise Instrument volume in Volume & parts, and turn off Mute my part. Try a built-in exercise. |
| Playback will not advance | Check that speed is above 0%, then press Play. Returning from a hidden browser tab also requires Play. |
| The tune keeps repeating | Open Loop and choose Turn loop off. |
| The page stopped following | Turning a page manually disables following. Enable Follow playback in Score view. |
| Notes are missing from tabs | Read About this arrangement. Try Basic tab, another part or simpler music. Omitted tab notes may still sound. |
| File rejected | Check that it is MIDI, read the error, and try a shorter file or a built-in song. Renaming an audio file to `.mid` will not convert it. |
| Settings do not survive a restart | Check for a session-only storage message. Browser privacy settings or unavailable storage can prevent saving. |

Windows/Linux downloads run after extracting the entire ZIP; no Godot installation
is needed. Browser offline use requires a completed first download and retained
site storage. A downloaded web ZIP must be hosted; double-clicking its HTML file
will not run the player. If the main web player cannot start, try the compatibility
player linked from the [public guide](https://bluehexagons.github.io/libretabs/).

For a problem you cannot resolve, [report it](https://github.com/bluehexagons/libretabs/issues)
with the app version, device/browser, what you tried and what happened. Use a
built-in song or a redistributable example so someone else can reproduce it.

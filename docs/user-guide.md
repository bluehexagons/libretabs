# Playing with LibreTabs

[Open the player](https://bluehexagons.github.io/libretabs/play/) · [Downloads](https://github.com/bluehexagons/libretabs/releases) · [Back to README](../README.md)

LibreTabs shows you where to play notes on a six-string guitar, plays a reference
sound, and helps you repeat music at your own pace. You can start with the built-in
music; you do not need a music file or an account. Optional playing inputs add
keyboard/MIDI feedback and experimental single-note microphone listening. The
tuner estimates pitch; it does not adjust your instrument for you.

This guide describes the current prototype. The planned six-lesson course is
not yet available. Generated guitar arrangements and notation still need musician
review; treat them as practice suggestions.

## Try another interface

Open **Menu → Interface** to compare the current player (**Classic**) with three
alternatives:

- **Focus:** a plain music stand with Play and speed above the score, sharing
  one slim toolbar on wide screens. Secondary actions are in Menu.
- **Touch:** navigation tabs and a wide, labeled Play button above a separate
  row of practice actions. Short windows use a compact dock; short landscape
  screens put controls on your preferred hand side.
- **Workspace:** a labeled controls rail, plus a separate score setup panel on
  large screens. Smaller windows and enlarged text use the compact player.

Select a choice, then **Done** to return to practice. Switching keeps your song,
playback position, speed, loop, music layout and listening connection. The choice
is saved on this device; choosing Classic returns to the original interface.
Theater and capture use their usual shared music views. These are comparison
layouts; a final redesign has not been selected.

## Your first five minutes

1. Open the player. An exercise is already loaded. Choose **Start practicing**
   in **Quick start**. This does not start the sound. To change how the music is
   shown, choose **Practice layouts** in Quick start or Menu.
2. Press **Play** and listen once without playing your guitar. The clicks before
   the music are a **count-in**: time to get ready. The moving line follows the
   music. Rounded outlines mark sounding tab numbers; slightly larger, bolder
   staff noteheads mark sounding notes without changing their shape.
3. Open **Menu → Playback** and choose a slower speed, such as **50%** under
   **Speed presets**. That means half the original speed, with the same pitches.
   Choose **Restart** beside Play to return to the beginning. If sound is
   playing, it continues from the start.
4. Follow just a few numbers on the guitar tabs, using the reading guide below.
   It is fine to listen again before joining in.
5. To repeat a short section, open **Menu → Loop**, set **From** to **1** and
   **Through** to **2**, then choose **Play selected section**. Both measures
   repeat after your usual count-in. Choose **Turn loop off** when you want to
   continue through the song.

For another tune, choose **Songs** (also in the Theater header). Search by title
or composer, or open **Show filters & sort** to narrow by suggested level,
playing time, starting BPM or suggested instrument. **First steps** songs appear first
by default.
The level is a teaching suggestion for this short arrangement, not a tested
performance grade. The guitar and piano suggestions describe the intended
practice arrangement; they do not claim every song has been checked on a
physical instrument. Some tunes begin with silence.
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
Use Menu → Tuner & listening, or a separate tuner. Changing the app's handed layout changes where
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

A curved underline marks the next note. Sounding tab numbers have a rounded
outline; sounding staff noteheads become slightly larger and bolder while
retaining their filled or hollow shape. Gentle ripples mark tab note starts
when reduced motion is off. These are playback cues, not feedback about your
playing. Fret numbers remain the
instruction even when colors or optional shapes are shown. **!** or **△** means
there is an arrangement warning; open **Songs → About this arrangement**.

The prototype rounds rhythms for display. Playback keeps the imported timing,
so unusually detailed rhythms may not line up exactly with the simplified symbols.

## Choose music or open your own file

In **Songs** (also in the Theater header), use **Listen** to hear up to 12 seconds
from the first note of a built-in song. Listen keeps your current song open and
pauses any playing practice audio. Use **Try** to open the song for practice.
Search by title or composer, or expand the filters to browse by suggested level,
length, starting speed, and instrument. **Open MIDI file** loads your own music.
A **MIDI file** contains note and timing instructions; it is not
a recording such as an MP3, a photograph of sheet music, or a guitar-tab
document. Use a `.mid` or `.midi` file.

If several parts appear, use **Choose the part to practice**. A part is one line
of music or instrument from the file. The main score shows the selected part;
paired staff layouts can also show its companion part. Try a
simple melody first; a whole piano or orchestral part may be difficult to fit on
a guitar. Drum-only files have no pitched part to turn into guitar tabs.

Current limits are Standard MIDI formats 0 and 1, 256 KiB per file, 32 tracks,
8,192 events, 2,048 notes, 256 measures and 10 minutes. These are maximum import
limits, not a promise that every file within them will make readable guitar music.
If import fails, try a shorter or simpler file; the previous song remains available.

Imported files stay on your device and are available only for the open session.
Reopen them after reloading or restarting. Settings and learned marks are saved;
the imported music, selected part, speed, position and loop are not. See
[privacy details](privacy.md).

## Keep track of what you have learned

In **Songs**, check **Learned** on a library card whenever you feel ready. The
current piece also has **I've learned this piece**, including built-in exercises
and imported MIDI. Uncheck it whenever you want to return to it. Playing a piece
or receiving tuner feedback never checks it automatically.

Choose **To learn** or **Learned** to filter the library; **All pieces** shows
everything again. Exercises show their mark in the example selector. For an
imported piece, reopen the same MIDI to see its mark, even if its filename changed.
Editing the MIDI makes it a different piece. No imported song list is stored.

Marks stay in this device's app profile or browser storage. **Settings → Learning
progress** shows the totals. **Clear learned marks** confirms before removing
them; your settings stay. If storage is unavailable or unreadable, the visible
notice explains that new marks may last only for this session.

## Saved settings and defaults

LibreTabs remembers sound, effects, count-in, beat clicks, volumes, keyboard
layout/octave/visibility/feedback, regular reading mode, song sorting and tuner
instrument/sensitivity/reference. It also keeps the existing appearance, text,
interface, notation rows, handedness, control edge and regular/Theater layout
preferences. Microphone/controller connections, calibration and temporary musical
muting still need an explicit action each session.

Open **Settings → Reset settings** to restore defaults after confirmation. It
pauses playback and stops microphone capture, keeps your current piece and learned
marks, and brings back Quick start on the next launch. If saved settings could not
be cleared, a notice explains that the defaults apply for this session and older
values may return next time.

## Adjust playback and repeat a passage

- **Playback speed:** 100% is the original speed; 50% is half speed. **Slower −5%**
  and **Faster +5%** make small changes. **Original speed** restores 100%. At 0%,
  playback pauses; raise the speed and press Play to continue.
- **Custom starting BPM:** BPM means beats per minute. A starting value of 60 is
  one beat per second. Later tempo changes keep their proportions. Changing speed
  changes how quickly notes arrive, not their pitch.
- **Beat clicks (metronome):** adds a click on each beat to help you keep time.
  **Count in before playing** adds preparation clicks on a fresh start; resuming
  after Pause continues immediately. Use **Menu → Playback → Stop**, then Play,
  when you want a new count-in.
- **Move to a passage:** click or tap the music to move playback there. In
  scrolling view, drag sideways across the music to browse without changing playback.
  The position slider lets you seek through the song. **Restart** returns to the beginning of
  the song, or the beginning of an enabled loop.
- **Loop:** From and Through include the first and last measures you choose.
  **Repeat this measure** sets and enables a one-measure loop. **Start at current
  measure** and **End at current measure** set the range from the current position.
  **Play selected section** starts at the first selected measure and repeats,
  using your count-in setting. **Repeat whole song** selects all measures and
  returns to the beginning; paused playback waits for Play. Turning looping off
  keeps the selected range for later.
- **When a song finishes:** the music stays visible and Play becomes **Replay**.
  The final notes and their room echo fade out briefly.
  Choose Replay to start again, tap an earlier passage and Play to practice from
  there, or choose **Songs** to switch tunes. A new song waits for you to press
  Play, with keyboard focus on that button.
- **Volume & parts:** choose **Synth piano** (the default), **Soft keys**,
  **Plucked strings**, or **Pure tone**, and adjust instrument and click volume
  separately. Your sound choice is saved on this device and applies to new notes
  in all enabled song parts and computer-keyboard previews. These generated
  practice sounds do not reproduce the original MIDI instruments. Use
  **Mute focused part** to play that part yourself while hearing the other one.
  **Hear Melody/Treble/Bass** controls the other part in a built-in song.
  The part switches appear first in this menu and keep playback and any count-in
  moving. Unmuting a held note brings it back at its current position instead of
  repeating its attack.
  Already queued audio and the short room echo may take a moment to fade.
  Each mute choice is kept when you switch focus; muting changes sound, not the
  displayed notes.
- **Sound effects:** open **Menu → Settings → Sound effects**, also reachable
  from Volume & parts. **Room ambience (reverb)** adds a short room echo and
  starts at a gentle 18%; its amount slider ranges from 0 to 40%.
  **Soft chorus** blends gently moving copies of each note for a wider sound
  and starts off. Effects apply to every instrument and keyboard preview, while
  metronome clicks remain clear. Changes are saved on this device. Use the
  separate switches or **Turn both effects off** to reduce audio processing.
  If a dense song stutters, leave Soft chorus off.
  Instrument volume also controls the echoes; stopping or seeking clears them.

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

Open **Menu → Practice layouts** (or choose a layout in **Quick start**) for
one-step guitar tabs, pick strumming, fingerpicking, bass-staff reading, or
piano treble-plus-bass staff reading. Choose **Piano · staffs + playable keys**
to show both staffs and the on-screen keyboard. The layout menu stays open as
you compare choices; choose **Done · return to practice** when ready.
**Treble focus** and **Bass focus** give
the selected part more room and show the other part on a smaller five-line
**mini staff**. The built-in songs have original simple bass lines on separate
MIDI parts; these are practice additions, not historical accompaniments.
**Try a two-hand piano exercise** loads an original short piece with separately
selectable treble and bass parts. Piano keys
can also show which notes sound now. Piano and bass staffs show actual sounding
pitches; guitar tabs still describe six-string E-standard guitar and are not
bass-guitar fingering. A two-part piano layout places the higher and lower
parts on the respective staffs. With a single MIDI part, it splits notes at
middle C as a reading aid. A file with more than two pitched parts still
requires selecting one practice part; it is not automatically arranged for two
hands.

Menu and dropdown lists scroll at the distance you drag with a finger. Drag
through a choice list to browse it, then tap a choice to select it.

Open **Menu → Score view** for reading and layout choices:

- **Smooth scrolling** follows the music. **Manual pages** lets you read at your
  own pace. **Pages · follow playback** turns pages with the sound.
- Use the page arrows or swipe horizontally to turn a page. Turning pages
  manually turns off following without moving playback. Enable **Follow playback**
  to resume automatic turns. Tapping a position on the music does move playback.
- In smooth scrolling, drag sideways on the music to browse without seeking.
  Tap a note to play from it. After browsing or turning a page manually, the
  Play/Pause button becomes **Back to current note**. It returns to the current
  playback position without starting or pausing sound. Space still plays or pauses.
- The **Music lines** dropdown beside the player also switches between
  **Smooth scrolling** and pages with one to six lines. Choosing pages enables
  following playback. Fewer lines give each line more height.
  **Note spacing** changes the horizontal gaps;
  **Staff height** changes the height of the five-line sheet music reference.
- Add, reorder or resize guitar, concert-pitch treble or bass, compact mini-staff, guitar-tab, and
  piano rows. The piano row
  shows sounding notes; it is not a connected MIDI keyboard or a playing test.
  **Restore default rows** returns to the initial row layout.

**Theater** uses the window for more music and remembers a separate layout.
Try it on a desktop or tablet as well as a larger screen. Controls normally hide
when playback starts; **Show controls** or **F10** brings them back. In
**Menu → Theater**, enable **Keep controls visible while playing** if you prefer.
**Fullscreen** is a separate button; press it again or Escape to leave fullscreen.
Theater does not connect to a TV itself; use your device's screen-mirroring controls.

**Menu → Appearance & text** includes lettering, text size, Device setting, Light,
Dark and Midnight appearance. Device setting follows the device's light or dark
preference. Midnight uses black around and behind the music for OLED screens.
Choose a backdrop for the space around the music in Light and Dark. Solid color,
Warm cream and Cool slate are plain; Ribbon pattern, Soft gradient, Horizon wash
and Quiet dots add subtle decoration. Midnight always remains black. The menu also includes
reduced motion, optional shape cues, control location and preferred hand. Text size
changes controls; use score layout or music zoom to improve music readability.
For a stationary reading view, choose Manual pages as well as reduced motion.

## Print, capture and play reference notes

**Menu → Print your music:** choose tabs, sheet music or both, a measure range,
and A4 or US Letter. Select **Prepare pages**, then **Save printable file**.
The filename includes the song title, such as `libretabs-Ode to Joy · Beethoven.html`.
Open the saved HTML in a browser and print or choose Save as PDF.
Use the matching paper size and turn off browser headers and footers. The file
works offline. Measures share continuous rows with a clef and time signature at
the start of each row; crowded measures receive more space. Printing retains
the prototype's arrangement limitations.

**Menu → Capture & overlay:** choose the music, background and placement, then
**Preview overlay**. The toolbar has **Play/Pause**, **Settings** and **Back to
player**. Choose **Clean frame** to hide the toolbar for separate recording or
streaming software; tap the frame or press F10 to reveal controls again. The
mouse pointer stays visible. Escape or F8 returns to the player; Space plays or
pauses. Previewing never starts audio automatically. LibreTabs does not record
video.

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
| No sound | Press Play, check device/browser volume, raise Instrument volume in Volume & parts, and enable the part you want to hear. Try a built-in exercise. |
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
with the version shown in **Menu → About LibreTabs**, device/browser, what you tried and what happened. Use a
built-in song or a redistributable example so someone else can reproduce it.

## Playing along with keys

Open Menu → Playing inputs → Show keyboard & return to practice, or choose the
**Piano · staffs + playable keys** layout. Tap or hold
keys, or use the existing computer-keyboard note layout. On the focused piano,
Left/Right selects a note and Space/Enter holds it. Higher/lower range presets and
the −/+ octave buttons change the visible range without transposing the song.
Outlined keys show your notes; small circles show the song's sounding pitches.

Playback continues while pitch and approximate attack timing are compared with
the selected practice part. Different notes and octave errors are distinguished.
Staff diamonds show your pitch, with a hollow expected pitch when different.
Tab positions are suggestions, not evidence of which string you actually played.
Use Stop all input notes to release input sound. Input state is session-only.

## MIDI controllers

Menu → Playing inputs → Connect MIDI requests access to connected controllers.
Choose one device/channel or all inputs. The on-screen piano opens automatically;
return to practice to play it. Notes, velocity and sustain are supported. Turn off
“Play MIDI notes through the app” if your electronic instrument already produces
sound. Pitch bend, expression and instrument changes are not interpreted.

MIDI reports which keys were played, so simultaneous notes can be compared
individually. It cannot measure the acoustic tuning of the instrument. Browser
MIDI availability varies; an unsupported browser retains the other input modes.
Denied access has a recovery message. For an embedded player, opening the player
in its own tab may allow permissions that the embedding site does not grant.

On short landscape screens, swipe or scroll the controls column to reach lower
actions. Keyboard focus also scrolls controls into view.

## Tuner and single-note listening

1. Open **Tuner & listening** from Menu or the wide-screen header. Choose your
   **Instrument** at the top, then press **Start listening** and allow microphone
   access. Choose **Acoustic piano** for a traditional piano or **Electronic piano**
   for an electronic piano heard through its speakers. A direct MIDI connection
   uses MIDI input instead. Room setup is optional.
2. Sound one clear, steady note. The tuner shows a target note and needle: left
   means low/flat, right means high/sharp. Aim for the center diamond. Uncertain
   input clears the needle. Choose automatic nearest-note tuning, a standard
   open string, or **Choose a note** to select a note and octave (C4 is middle C).
   The lock icon holds the current detected note as the target.
3. **Mute song notes** silences app music, keyboard notes and their echoes while
   keeping the metronome and count-in audible. Saved volumes and playback position
   are preserved. The same switch is available beside the practice controls.
   Use headphones if the microphone picks up the clicks.
4. **Use microphone in practice** starts or resumes listening and enables pitch
   feedback together, then returns to the score. Press Play to play along. Only
   the selected part is compared; overlapping source notes show the single-note
   limitation. You can turn feedback off in **Input settings** and keep tuning.
5. **Pause listening** temporarily pauses analysis and feedback without repeating
   permissions. **Resume listening** waits for a fresh note. The microphone icons
   beside the player provide the same actions, with help on long press or hover.
   **Stop microphone**, under Input settings, releases capture.
6. Expand **Input settings** to change the device, sensitivity, pitch reference or
   timing compensation. Changing devices stops capture; press Start again. A4
   defaults to 440 Hz. **Check room noise** measures three quiet seconds followed
   by three separate steady notes; use it when background sound causes detections.
   Higher sensitivity accepts softer notes but never goes below a measured noise
   floor. Setup does not change the tuning reference. **Tuner help** has the note
   range, target and privacy details.

Listening is designed for one note at a time. Dampen ringing guitar strings and
avoid piano sustain during these exercises. Even when a song expects one note,
other audible sounds can confuse the detector; it cannot reliably recognize and
reject every chord. Clean electric guitar through an interface is a useful setup.
Evaluation ranges are A1–C7 for both pianos, D2–F6 for guitars, A1–F6 for
voice, A0–F5 for bass, F#3–C7 for violin and F#3–F6 for ukulele. These are
detector limits, not claims about a singer’s range.
Distortion, effects, very low piano notes and real-device accuracy remain testing
boundaries. These range profiles do not change imported pitches or tuning.

Microphone timing is off by default. After measuring an input/output setup, enter
its additional input-delay compensation and enable approximate attack timing.
Detection tracks the attack separately from the later stable-pitch estimate.
Uncertain or unassociated attacks remain unassessed. A tap-along exercise cannot
separate human timing error from device latency. Setup or device changes disable
microphone timing again. Keyboard/MIDI timing is also approximate.

Stop microphone releases the stream. Hiding the app or leaving its window stops
active capture; returning does not restart it automatically. Tuner instrument,
sensitivity and reference are remembered. Devices, targets and calibration last
for this session; audio is never saved or uploaded.

## Hands-free note commands

Enable **Menu → Settings → Hands-free note commands** to control practice while
your hands stay on an instrument. This is off by default. Start listening
separately in **Tuner & listening**; the setting never starts it for you. Use
headphones or mute playback speakers to avoid commands triggered by the app's own
sound. The switch is remembered on this device and can be turned off at any time.

Wait through the three-second settling period, then leave about a second of
quiet. Play **E4 → Bb4 → F4 → B4**, one note at a time. Bb4 is also shown as A#4 on the tuner. On a standard-tuned guitar,
these are frets **0 → 6 → 1 → 7** on the thinnest string. Hold each note for roughly
three quarters of a second, then damp it for roughly a third of a second before the next.
Release the final note to open the command menu. You can start on a different
note as long as the pitch distances remain the same; the menu adapts its notes.

With the E4 activation phrase, choose:

| Play twice, with a quiet gap | Action |
| --- | --- |
| E4 | Play or pause |
| F#4 | Replay the current loop, or the song, from its start |
| G#4 | Reduce speed by five percentage points |
| A4 | Increase speed by five percentage points |

The first command note shows a confirmation prompt. Repeat it and release it to
execute. You have eight seconds to choose, then four seconds to confirm. A wrong
note, uncertain or interrupted detection, closing the menu or pressing Cancel
cancels the pending action. Wait three seconds and a quiet gap before another
phrase. Calibration, import, unrelated menus and capture presentation temporarily
block commands; ordinary tuning and practice controls continue to work.

These are separate notes, not chords. The unusual activation phrase and quiet
gaps reduce accidental matches but do not guarantee that a song or noisy room
cannot trigger them. Reliable real-instrument and browser detection remains an
evaluation goal; disable note commands if they interfere with tuning or practice.

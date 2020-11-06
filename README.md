# 🌆🅲🅸🆃🆈🆇🅴🅽☯️ 8 & 16 bit hijinx and programming!

# GPIO Tracker - Commodore 64 Version

Version: 1.0 by Deadline

This program will set the user port output for 32 pin GPIO board from Dorktronic.

- (THIS IS SUBJECT TO CHANGE) Up to 256 Tracks, Up to 16 Patterns of 256 different states, Speed up or Slow down during playback, Stop playback with the programmable commands, control additional daisy chained machines running relay tracker using joystick control mode (JCM). No limit to the number of daisy chained relay trackers.

## Notes:
If you're going to attempt to compile this, you'll need:
* Edit Build.bat to set it for your environment
* DASM compiler
* the Macros and Constants from https://github.com/cityxen/Commodore64_Programming repo
* GPIOTracker Data is located from $4000 - $9fff (Note this could be reworked to use RAM Expansion devices in the future, or some other enhanced method than it is using now)


## Commands:

### Storage

D - change drive number (toggles between drives 08,09,10,11)

F - change filename (allows you to change the working filename)

$ - shows directory of current disk

S - saves data to filename on drive

L - loads data from filename from drive

E - Erase File

### Track

F1 - Moves Track Block Cursor UP

F3 - Moves Track Block Cursor DOWN

F2 - Track Block Length DOWN

F4 - Track Block Length UP

### Pattern

; - Changes Pattern for current track UP

: - Changes Pattern for current track DOWN

Cursor Down - Move Pattern Cursor Down

Cursor Up - Move Pattern Cursor Up

CTRL - Advance inner track cursor

1-8 - Toggle relay

MINUS - Turn off all relays

PLUS - Turn on all relays

HOME - Move Pattern Cursor to TOP

CLR - Move Pattern Cursor to BOTTOM

F5 - Pattern Cursor Page UP

F7 - Pattern Cursor Page DOWN

C - Change Command

        Command   Value
        SPEED   = 00 - 1f (Change the speed of playback.. Lower = Faster)
        STOP    = IGNORED (Stops playback)
        FUTURE  = IGNORED (Future command slot available with values from 00-1f)

\* - Change Command Data Value Up (Command Data range is from 00-3F)

= - Change Command Data Value Down

### Additional Features

J - Toggle Joystick Control Mode (JCM Modes: OFF,PLAY)

        OFF  = Joystick doesn't affect anything
        PLAY = While fire button is pressed, track will play
        Future modes:
        *SS   = Fire toggles playback (start / stop)
        *FREE = Up,Down,Left,Right toggle relays 1-4 Fire+Up,Down,Left or Right, toggle relays 2-8
        *TRAK = Up Move Pattern Cursor Up, Down Move Pattern Cursor Down
        *EDIT = Move Joystick Cursor within Pattern area to move, Fire toggle relay bit
        (* SS,FREE,TRAK,EDIT JCM modes do not work yet)

N - Clear memory

SPACE - Play/Pause

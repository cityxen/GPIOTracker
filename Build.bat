rem Build Dorktronic i2c.s
dasm i2c.s -oi2c.ml -f3 -si2c.symbols

rem Build using retro-dev-tools ( see: https://github.com/cityxen/retro-dev-tools )
start /b genkickass-script.bat -t C64 -o prg_files -m true -s true -l "RETRO_DEV_LIB"
KickAss.bat gpiotracker.asm

rem Alternatively, use your own build location
rem java -jar PATH:\to\your\KickAss\KickAss.jar gpiotracker.asm
@echo off

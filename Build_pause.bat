dasm i2c.s -oi2c.ml
copy Kickass.cfg E:\pc_tools\KickAssembler\Kickass.cfg
java -jar E:\pc_tools\KickAssembler\KickAss.jar gpiotracker.asm
@echo off
rem mkdir X:\temp\prg_xfer\GPIOTracker
rem xcopy * X:\temp\prg_xfer\GPIOTracker\* /Y /S
pause

dir=$(dirname 0)
# Build Dorktronic i2c ML
dasm i2c.s -oi2c.ml -f3 -si2c.symbols
# Build using retro-dev-tools ( see: https://github.com/cityxen/retro-dev-tools )
genkickass-script.py -t C64 -o prg_files -m true -s true -l "RETRO_DEV_LIB"
kickass gpiotracker.asm

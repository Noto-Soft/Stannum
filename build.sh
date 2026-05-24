#/usr/bin/env bash
rm -f os.img
mkdir -p build

fasm src/boot/boot.asm build/boot.bin

fasm src/kernel/kernel.asm build/kernel.bin

fasm src/drivers/high.asm build/high.drv
fasm src/drivers/serial.asm build/serial.dev
fasm src/drivers/pcspk.asm build/pcspk.dev
fasm src/drivers/vga.asm build/vga.dev

fasm src/userspace/scli.asm build/scli.com
fasm src/userspace/hello.asm build/hello.com
fasm src/userspace/writef.asm build/writef.com
fasm src/userspace/copyf.asm build/copyf.com
fasm src/userspace/beeper.asm build/beeper.com
fasm src/userspace/video12.asm build/video12.com
fasm src/userspace/video13.asm build/video13.com
fasm src/userspace/image.asm build/image.com
#fasm src/userspace/vesatest.asm build/vesatest.com
fasm src/userspace/panick.asm build/panick.com
fasm src/userspace/echo.asm build/echo.com
fasm src/userspace/notagame.asm build/notagame.com

fasm src/tunes/mouth.asm build/mouth.tun
fasm src/tunes/scale.asm build/scale.tun
fasm src/tunes/pb95.asm build/pb95.tun
fasm src/tunes/eight52.asm build/eight52.tun
fasm src/tunes/atsol.asm build/atsol.tun

# gcc -m16 -ffreestanding -nostdlib -fno-pie -fno-pic -Wl,--oformat=binary -s -o build/ctest.bin src/ctest.c

touch os.img
truncate -s 1440k os.img
mkfs.fat -n STANNUM -F 12 -f 1 os.img

dd if=build/boot.bin of=os.img count=3 bs=1 conv=notrunc status=none
dd if=build/boot.bin of=os.img seek=72 skip=72 count=440 bs=1 conv=notrunc status=none

mcopy -i os.img build/kernel.bin "::kernel.bin"

mcopy -i os.img build/high.drv "::high.drv"
mcopy -i os.img build/serial.dev "::serial.dev"
mcopy -i os.img build/pcspk.dev "::pcspk.dev"
mcopy -i os.img build/vga.dev "::vga.dev"

mcopy -i os.img build/scli.com "::scli.com"
mcopy -i os.img build/hello.com "::hello.com"
mcopy -i os.img build/writef.com "::writef.com"
mcopy -i os.img build/copyf.com "::copyf.com"
mcopy -i os.img build/echo.com "::echo.com"
#mcopy -i os.img build/vesatest.com "::vesatest.com"
mcopy -i os.img build/beeper.com "::beeper.com"
mcopy -i os.img build/video12.com "::video12.com"
mcopy -i os.img build/video13.com "::video13.com"
mcopy -i os.img build/image.com "::image.com"
mcopy -i os.img build/panick.com "::panick.com"
mcopy -i os.img build/notagame.com "::notagame.com"

mcopy -i os.img src/userspace/config/config.sys "::config.sys"
mcopy -i os.img src/userspace/config/usr.cfg "::usr.cfg"

mcopy -i os.img LICENSE "::license.txt"
mcopy -i os.img src/userspace/docs/abc.txt "::abc.txt"
mcopy -i os.img spec/extensions.txt "::extens.txt"
mcopy -i os.img src/userspace/docs/delete.txt "::delete.txt"
mcopy -i os.img spec/memory.txt "::memory.txt"

mcopy -i os.img build/mouth.tun "::mouth.tun"
mcopy -i os.img build/scale.tun "::scale.tun"
mcopy -i os.img build/pb95.tun "::pb95.tun"
mcopy -i os.img build/eight52.tun "::eight52.tun"
mcopy -i os.img build/atsol.tun "::atsol.tun"

mcopy -i os.img assets/scp079.raw "::scp079.raw"
mcopy -i os.img assets/maroi.raw "::maroi.raw"
mcopy -i os.img assets/listen.raw "::listen.raw"
mcopy -i os.img assets/franklin.raw "::franklin.raw"

fatsort os.img -q

if [[ "$1" == "test" ]]; then
    bash test.sh
else
    echo "[build.sh] Run \"bash build.sh test\" to build and then boot into qemu (qemu-system-x86 package required)"
fi
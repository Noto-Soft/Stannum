#/usr/bin/env bash
rm -f os.img
mkdir -p build

fasm src/boot.asm build/boot.bin
fasm src/kernel.asm build/kernel.bin
fasm src/scli.asm build/scli.com
fasm src/hello.asm build/hello.com
fasm src/repeat.asm build/repeat.com
fasm src/tell.asm build/tell.com
fasm src/tsrtest.asm build/tsrtest.com

touch os.img
truncate -s 1440k os.img
echo "Created os.img"
mkfs.fat -n STANNUM -F 12 -f 1 os.img > /dev/null
echo "[MKFS.FAT] Formatted os.img to FAT12"

dd if=build/boot.bin of=os.img count=3 bs=1 conv=notrunc status=none
dd if=build/boot.bin of=os.img seek=72 skip=72 count=440 bs=1 conv=notrunc status=none
echo "[DD] Wrote bootloader"

mcopy -i os.img build/kernel.bin "::kernel.bin"
echo "[MCOPY] Wrote kernel.bin"
mcopy -i os.img build/scli.com "::scli.com"
echo "[MCOPY] Wrote scli.com"

mcopy -i os.img build/hello.com "::hello.com"
echo "[MCOPY] Wrote hello.com"
mcopy -i os.img build/repeat.com "::repeat.com"
echo "[MCOPY] Wrote repeat.com"
mcopy -i os.img build/tell.com "::tell.com"
echo "[MCOPY] Wrote tell.com"
mcopy -i os.img build/tsrtest.com "::tsrtest.com"
echo "[MCOPY] Wrote tsrtest.com"

mcopy -i os.img src/reminder.txt "::reminder.txt"
echo "[MCOPY] Wrote reminder.txt"
mcopy -i os.img src/woohey.txt "::woohey.txt"
echo "[MCOPY] Wrote woohey.txt"

if [[ "$1" == "test" ]]; then
    qemu-system-i386 --drive file=os.img,if=floppy,format=raw
else
    echo "[build.sh] Run \"bash build.sh test\" to build and then boot into qemu (qemu-system-x86 package required)"
fi
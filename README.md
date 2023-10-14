## Debugging UBoot Data Abort


## Dev Environment Requirements
- Previously installed cross-compiler toolchain in `${HOME}/x-tools/arm-training-linux-musleabihf/bin/` built by crosstool-ng
- Cross-compiler toolchain prefix of `arm-linux-`
- Target architecture of `arm`
- Source the env variables script: `source ./load-build-env.sh`

## Resources
- Mailing list archives highlighting the bug: https://lore.kernel.org/all/7536b9e1-de7a-a492-6951-485d4eb75df1@163.com/T/#u
- UBoot mailing list discussing a potential fix: https://lists.denx.de/pipermail/u-boot/2023-July/524187.html
- Suggested debugging technique based on crash dump: https://lore.kernel.org/all/20230722002652.220ae94d@xps-13/t/#u


## Scenario
- Multiple TFTP transfers causes data abort error:
```
Filename 'testfile.txt'.
Load address: 0x80000000
Loading: ##################################################  11 Bytes
         1000 Bytes/s
done
Bytes transferred = 11 (b hex)
=> 
---- Sent utf8 encoded message: "\n" ----

data abort
pc : [<9ff7f2a8>]          lr : [<9ffdbfbc>]
reloc pc : [<8081c2a8>]    lr : [<80878fbc>]
sp : 9df2d980  ip : 9ffdbfbc     fp : 9df5c0d4
r10: 9df4f9e4  r9 : 9df42ea0     r8 : 00000080
r7 : 00000024  r6 : 00000001     r5 : 9ffdbe9c  r4 : 00000120
r3 : 9ffdbf00  r2 : 9df506c0     r1 : 9ffdbea4  r0 : 9df50620
Flags: Nzcv  IRQs off  FIQs on  Mode SVC_32 (T)
Code: 0601 68c3 6046 6886 (60f3) 609e 
Resetting CPU ...
```

## U-boot usb-ethernet config
```
=> setenv ipaddr 192.168.0.100
=> setenv serverip 192.168.0.1
=> setenv ethprime usb_ether
=> setenv usbnet_devaddr f8:dc:7a:00:00:02
=> setenv usbnet_hostaddr f8:dc:7a:00:00:01
=> saveenv
```

## Host usb-ethernet config

```
$ nmcli con add type ethernet ifname enxf8dc7a000001 ip4 192.168.0.1/24
```

# Debugging

We have the following crash dump: 
```
pc : [<9ff7f2a8>]          lr : [<9ffdbfbc>]
reloc pc : [<8081c2a8>]    lr : [<80878fbc>]
```

Referencing the `u-boot.map` file:
```
 .text.free     0x8081bde8      0x16c common/dlmalloc.o
                0x8081bde8                free
 .text.malloc   0x8081bf54      0x418 common/dlmalloc.o
                0x8081bf54                malloc
 .text.calloc   0x8081c36c       0x9c common/dlmalloc.o
                0x8081c36c                calloc
```
Shows that the crash happens in the `malloc` function.  

Unpacking the u-boot binary at the relevant addresses:
- Dump object file data: `${CROSS_COMPILE}objdump -lS ${BUILDDIR}/u-boot`
- Filter for just our relevant `pc` and `lr` addresses: 
  - `${CROSS_COMPILE}objdump -lS ${BUILDDIR}/u-boot | grep -A 10 -B 20 8081c2a8`
  - `${CROSS_COMPILE}objdump -lS ${BUILDDIR}/u-boot | grep -A 10 -B 20 80878fbc`

The resulting instructions show a bad memory access during `malloc` operations:
```
/home/tudor/dev/embedded_linux/debug-uboot-data-abort/u-boot/common/dlmalloc.c:1464
            unlink(victim, bck, fwd);
8081c2a2:       68c3            ldr     r3, [r0, #12]
/home/tudor/dev/embedded_linux/debug-uboot-data-abort/u-boot/common/dlmalloc.c:1463
            set_head(victim, nb | PREV_INUSE);
8081c2a4:       6046            str     r6, [r0, #4]
/home/tudor/dev/embedded_linux/debug-uboot-data-abort/u-boot/common/dlmalloc.c:1464
            unlink(victim, bck, fwd);
8081c2a6:       6886            ldr     r6, [r0, #8]
8081c2a8:       60f3            str     r3, [r6, #12]
8081c2aa:       609e            str     r6, [r3, #8]
```

Hinting at some related "use after free" or "double free" bug.


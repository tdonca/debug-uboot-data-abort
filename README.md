## Debugging UBoot Data Abort


## Dev Environment Requirements
- Previously installed cross-compiler toolchain in `${HOME}/x-tools/arm-training-linux-musleabihf/bin/` built by crosstool-ng
- Cross-compiler toolchain prefix of `arm-linux-`
- Target architecture of `arm`
- Source the env variables script: `source ./load-build-env.sh`

## Resources
- Mailing list archives highlighting the bug: https://lore.kernel.org/all/7536b9e1-de7a-a492-6951-485d4eb75df1@163.com/T/#u
- UBoot mailing list discussing a potential fix: https://lists.denx.de/pipermail/u-boot/2023-July/524187.html


## Scenario
- Multiple TFTP transfers causes data abort error:
```
Using usb_ether device
TFTP from server 192.168.0.1; our IP address is 192.168.0.100
Filename 'am335x-boneblack.dtb'.
Load address: 0x82000000
Loading: ##################################################  68.3 KiB
         4.2 MiB/s
done
Bytes transferred = 69937 (11131 hex)
data abort
pc : [<9ff7b00a>]          lr : [<9ff74f81>]
reloc pc : [<8081c00a>]    lr : [<80815f81>]
sp : 9df299f8  ip : 00000020     fp : 00000003
r10: 9df29a60  r9 : 9df3eea0     r8 : 00000200
r7 : 00000003  r6 : 00000010     r5 : 9ffdb3fc  r4 : 0000000c
r3 : 00000010  r2 : 9df4a900     r1 : 00000001  r0 : 9df4c418
Flags: Nzcv  IRQs off  FIQs on  Mode SVC_32 (T)
Code: 68c2 6881 f023 0303 (60ca) 4403 
Resetting CPU ...
```

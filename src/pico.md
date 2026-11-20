# Pico Boards

Raspberry Pi Pico is a family of microcontroller boards. 
There are two generations:

| Generation | Microcontroller | CPU choices | Clock | SRAM | Board flash |
|---|---|---|---|---|---|
| Pico | RP2040 | 2 × Arm Cortex-M0+ | up to 133 MHz | 264 KB | 2 MB |
| Pico 2 | RP2350A | 2 × Arm Cortex-M33 **or** 2 × Hazard3 RISC-V | up to 150 MHz | 520 KB | 4 MB |

Pico 2 is the preferred generation for a new project when its slightly higher
price is acceptable. It provides faster cores, almost twice the SRAM, twice
the flash, hardware floating point on Arm, and additional security features.
The original Pico remains useful for its simple Cortex-M0+ architecture and
very broad ecosystem support.

## Current board variants

Each generation is available without wireless hardware, with wireless
hardware (`W`), and with or without pre-soldered headers.

| Board | Chip | Wireless | Headers |
|---|---|---|---|
| Raspberry Pi Pico | RP2040 | No | No |
| Raspberry Pi Pico H | RP2040 | No | Yes |
| Raspberry Pi Pico W | RP2040 | Wi-Fi + Bluetooth | No |
| Raspberry Pi Pico WH | RP2040 | Wi-Fi + Bluetooth | Yes |
| Raspberry Pi Pico 2 | RP2350A | No | No |
| Raspberry Pi Pico 2 with headers | RP2350A | No | Yes |
| Raspberry Pi Pico 2 W | RP2350A | Wi-Fi + Bluetooth | No |
| Raspberry Pi Pico 2 W with headers | RP2350A | Wi-Fi + Bluetooth | Yes |

The first generation abbreviates “with headers” as `H` or `WH`. Raspberry Pi
does not use that abbreviation in the official Pico 2 product names.

The matching generations retain the same basic 40-pin form factor:

- Pico 2 and Pico 2 with headers have the same board pinout as Pico and Pico H.
- Pico 2 W and Pico 2 W with headers have the same board pinout as Pico W and
  Pico WH.
- Boards without headers require soldered pins or another suitable connection
  before they can be used on a breadboard.

## RP2040: first-generation Pico

The RP2040 name encodes several chip properties:

- `RP`: Raspberry Pi;
- `2`: two processor cores;
- `0`: Cortex-M0+ processor generation;
- `4`: RAM size code, calculated as `floor(log2(RAM / 16 KB))`;
- `0`: no on-chip non-volatile storage.

RP2040 provides two Cortex-M0+ cores, 264 KB SRAM, USB 1.1, and eight
Programmable I/O (PIO) state machines. The Pico board adds 2 MB external QSPI
flash and exposes 26 multi-function GPIO pins.

For Embedded Rust with Embassy, use:

```text
Rust target:         thumbv6m-none-eabi
embassy-rp feature:  rp2040
probe-rs chip:       RP2040
```

## RP2350A: Pico 2

RP2350 is not merely a faster RP2040. It contains two Arm Cortex-M33 cores and
two open-source Hazard3 RISC-V cores. A program selects one architecture at
boot; it does not run all four cores simultaneously. Pico 2 uses the `A`
package variant of the chip, hence `RP2350A`.

The RP2350 name follows the same scheme:

- `RP`: Raspberry Pi;
- `2`: two active processor cores;
- `3`: Cortex-M33 processor generation;
- `5`: RAM size code for 520 KB SRAM;
- `0`: no on-chip non-volatile storage.

RP2350 adds 12 PIO state machines, Arm TrustZone, secure boot support, hardware
SHA-256 acceleration, and other security features. The Pico 2 board adds 4 MB
external QSPI flash while retaining 26 exposed multi-function GPIO pins.

This workshop uses the Arm Cortex-M33 mode, which has the most direct Embassy
setup:

```text
Rust target:         thumbv8m.main-none-eabihf
embassy-rp feature:  rp235xa
probe-rs chip:       RP235x
```

The `eabihf` target uses the Cortex-M33 hardware floating-point unit. The
RP2350 RISC-V cores are valuable for experimentation, but require a different
build target and project configuration.

## Wireless models

Pico W, Pico WH, Pico 2 W, and Pico 2 W with headers add an Infineon CYW43439
radio with:

- 2.4 GHz 802.11 b/g/n Wi-Fi;
- Bluetooth 5.2, including Bluetooth Low Energy (BLE);
- an onboard antenna.

The radio is connected internally to the RP chip. It does not consume any of
the 26 GPIO pins exposed at the board edges.

On every W board, the onboard LED is connected to **CYW43 GPIO 0**, not directly
to RP GPIO 25. Consequently, a wireless-board blinky must initialize the
CYW43 driver. See the [four Embassy blinky examples](./embassy-basics.md) for a
side-by-side comparison.

## SWD connector differences

All Pico boards provide the same three SWD signals: `SWDIO`, `GND`, and
`SWCLK`. The connector position and style vary:

- on non-wireless boards, it is at the bottom edge;
- on wireless boards, it is below the microcontroller, near the board centre;
- boards without headers use three through-hole pads;
- boards with headers use a keyed three-pin JST-style connector.

The SWD connector does not power the target. See the
[Debug Probe chapter](./debugprobe.md) before wiring a probe.

## Important links

- [Official Pico-series documentation](https://www.raspberrypi.com/documentation/microcontrollers/pico-series.html)
- [RP2040 datasheet](https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf)
- [RP2350 datasheet](https://datasheets.raspberrypi.com/rp2350/rp2350-datasheet.pdf)
- [Pico and Pico W datasheet](https://datasheets.raspberrypi.com/pico/pico-datasheet.pdf)
- [Pico 2 datasheet](https://datasheets.raspberrypi.com/pico/pico-2-datasheet.pdf)
- [Getting started with Pico](https://datasheets.raspberrypi.com/pico/getting-started-with-pico.pdf)
- [Raspberry Pi datasheet archive](https://datasheets.raspberrypi.com/)

# Set up the development environment

This guide prepares Linux, macOS, or Windows 11 for Embedded Rust development
with Embassy on either wireless Pico generation:

| Board | Microcontroller | Rust target | `embassy-rp` feature |
|---|---|---|---|
| Raspberry Pi Pico W / Pico WH | RP2040 (Cortex-M0+) | `thumbv6m-none-eabi` | `rp2040` |
| Raspberry Pi Pico 2 W / Pico 2 W with headers | RP2350A (Cortex-M33) | `thumbv8m.main-none-eabihf` | `rp235xa` |

We first flash through USB in BOOTSEL mode. This requires only the target board
and a USB cable. Afterwards, we configure an SWD debug probe for automatic
flashing, `defmt`/RTT logs, panic reports, breakpoints, and single-stepping.

The W boards drive their on-board LED through the CYW43 wireless chip. Use a
wireless-board example; a normal Pico GPIO blinky will not operate that LED.

## 1. Install host prerequisites

Choose the section for your operating system.

### Ubuntu or another Debian-based Linux

```sh
sudo apt update
sudo apt install -y \
  build-essential cmake curl git libssl-dev libudev-dev pkg-config
```

The udev rules required for an SWD probe can be installed now:

```sh
curl --proto '=https' --tlsv1.2 -o /tmp/69-probe-rs.rules \
  https://probe.rs/files/69-probe-rs.rules
sudo install -m 0644 /tmp/69-probe-rs.rules /etc/udev/rules.d/69-probe-rs.rules
sudo udevadm control --reload
sudo udevadm trigger
```

Unplug and reconnect the probe after installing the rules. See the current
[probe-rs Linux instructions](https://probe.rs/docs/getting-started/probe-setup/#linux-udev-rules)
if access is still denied.

### macOS

Install Apple's command-line developer tools:

```sh
xcode-select --install
```

Complete the installer dialog before continuing. CMSIS-DAP probes need no
additional macOS driver.

### Windows 11

1. Install [Git for Windows](https://git-scm.com/download/win).
2. Download and run [`rustup-init.exe`](https://rustup.rs/). When prompted,
   allow Rust to install the Visual Studio C++ Build Tools, or install the
   **Desktop development with C++** workload yourself.
3. Use a normal 64-bit PowerShell terminal for the remaining commands. Native
   Windows is recommended; WSL requires USB forwarding and separate Linux udev
   configuration.

A Pico or official Raspberry Pi Debug Probe using CMSIS-DAP normally needs no
extra Windows driver. Do not replace its driver with Zadig/WinUSB unless
`probe-rs` reports a driver problem and its documentation requires that change
for the particular probe.

## 2. Install Rust

On Linux and macOS, run:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Choose the standard installation and restart the terminal afterwards. On
Windows, close and reopen PowerShell after running `rustup-init.exe` so that
`%USERPROFILE%\.cargo\bin` is on `PATH`.

Install stable Rust and both Pico compilation targets:

```sh
rustup update stable
rustup default stable
rustup target add thumbv6m-none-eabi
rustup target add thumbv8m.main-none-eabihf
```

Verify the installation:

```sh
rustc --version
cargo --version
rustup target list --installed
```

Embassy is a collection of Rust crates declared in a project's `Cargo.toml`.
There is no global Embassy program to install. Current Embassy projects use
stable Rust; this setup does not require nightly Rust or the `rust-src`
component.

## 3. Install picotool and the Embedded Rust tools

`picotool` supports RP2040 and RP2350 ELF and UF2 files. Download the current
pre-built package for Windows, macOS, or Linux from the official
[`pico-sdk-tools` releases](https://github.com/raspberrypi/pico-sdk-tools/releases),
extract it, and add the directory containing the `picotool` executable to
`PATH`. Alternatively, follow the
[`picotool` build instructions](https://github.com/raspberrypi/picotool#building--installing).

Verify it in a new terminal:

```sh
picotool version
```

Install the remaining tools in a Unix shell or PowerShell:

```sh
cargo install --locked probe-rs-tools
cargo install --locked flip-link
cargo install --locked cargo-generate
```

`probe-rs-tools` installs `probe-rs`, `cargo-embed`, and `cargo-flash`. Check
the commands:

```sh
probe-rs --version
cargo generate --version
flip-link --version
```

## 4. Install Visual Studio Code

Install [Visual Studio Code](https://code.visualstudio.com/download), then add:

```sh
code --install-extension rust-lang.rust-analyzer
code --install-extension probe-rs.probe-rs-debugger
```

If `code` is not on `PATH`, install **rust-analyzer** and **Debugger for
probe-rs** from VS Code's Extensions view. CodeLLDB and the Microsoft C/C++
extension are not required for the `probe-rs` workflow.

## 5. Create a Blinky project

```sh
cargo install cargo-generate
cargo generate gh:koehlma/rust-embedded-template --name blinky
``

### CYW43 firmware

The wireless examples embed binary firmware for the CYW43439. Obtain the files
expected by the selected example from Embassy's official
[`cyw43-firmware` directory](https://github.com/embassy-rs/embassy/tree/main/cyw43-firmware):

- `43439A0.bin` — Wi-Fi firmware;
- `43439A0_clm.bin` — regulatory/CLM data;
- the NVRAM file referenced by the example, currently `nvram_rp2040.bin` for
  the official Pico W-series examples.

Keep these files together and use the exact paths expected by the example.
Firmware, CLM, and NVRAM data form a matched set; do not substitute similarly
named files from an unrelated project.

Wi-Fi examples also need a network name and password. Keep credentials in a
local, ignored configuration or environment variables as supported by the
workshop project. Never commit real Wi-Fi credentials.

## 6. First flash: drag and drop a UF2

Build the selected wireless blinky using the target configured by the project:

```sh
cargo build --release
```

The ELF is located below the corresponding target directory, for example:

```text
target/thumbv6m-none-eabi/release/<binary-name>
target/thumbv8m.main-none-eabihf/release/<binary-name>
```

Convert that ELF to UF2:

```sh
picotool uf2 convert -t elf \
  target/<rust-target>/release/<binary-name> <binary-name>.uf2
```

Then flash it:

1. Disconnect the target board from USB.
2. Hold **BOOTSEL** while reconnecting USB.
3. Release BOOTSEL when a removable drive appears:
   - `RPI-RP2` for Pico W;
   - `RP2350` for Pico 2 W.
4. Copy `<binary-name>.uf2` to that drive using Finder, File Explorer, or your
   desktop's file manager.

The drive automatically ejects and the application starts. The on-board LED
should blink through CYW43. This first flash does not require a debug probe.

## 7. Automate USB flashing with picotool

`picotool` can load the compiled ELF directly. Configure the project's
`.cargo/config.toml` runner for its target:

```toml
[target.thumbv6m-none-eabi]
runner = "picotool load --update --verify --execute -t elf"
```

or:

```toml
[target.thumbv8m.main-none-eabihf]
runner = "picotool load --update --verify --execute -t elf"
```

Put the board into BOOTSEL mode and verify that it is visible:

```sh
picotool info
cargo run --release
```

This remains a USB flashing workflow. For live logs and source-level
debugging, continue with SWD.

## 8. Debug connector (SWD)

Both probe options below provide a CMSIS-DAP-compatible USB-to-SWD connection.
They allow automatic ELF flashing without BOOTSEL, `defmt`/RTT output, panic
reports, breakpoints, and single-stepping.

The target's three-pin debug connector carries only **SWDIO**, **GND**, and
**SWCLK**. It has no power pin: power the target separately through USB or
`VSYS`. The connector's position differs between W and non-W boards; see the
official [Pico-series SWD documentation](https://www.raspberrypi.com/documentation/microcontrollers/pico-series.html#debug-connector-swd).

### Option A: official Raspberry Pi Debug Probe (recommended)

The official probe is the plug-and-play option. It includes a USB cable and
JST-SH-to-JST-SH, JST-SH-to-female-header, and JST-SH-to-male-header cables.
Use its **D** port for SWD:

| Debug Probe | Target Pico |
|---|---|
| `SC` (orange) | `SWCLK` |
| `GND` (black) | `GND` |
| `SD` (yellow) | `SWDIO` |

Pico WH and Pico 2 W with headers have a keyed three-pin connector that accepts
the JST-SH cable. Pico W and Pico 2 W without headers require soldered pins or
a suitable adapter and the female-header cable.

Follow the official [Raspberry Pi Debug Probe guide and labelled wiring
images](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html#getting-started).
If probe and target have separate power sources, connect their grounds before
connecting the signal wires; a voltage difference can damage the hardware.

The probe's **U** port is an optional UART bridge. UART is not needed for SWD
flashing or `defmt` over RTT.

### Option B: use a second Pico-series board as the probe

A first-generation Pico or a Pico 2 can run Raspberry Pi's official
`debugprobe` firmware and provide the same CMSIS-DAP SWD interface. Firmware
selection depends on the **probe board**, not the target:

- first-generation Pico as probe: `debugprobe_on_pico.uf2`;
- Pico 2 as probe: `debugprobe_on_pico2.uf2`.

See [Use a Pico as a debug probe](./debugprobe.md) for firmware installation,
the complete SWD/UART pin table, power options, and the workshop wiring images.
The [breadboard wiring page](./steckbrett-verdrahtung.md) contains the detailed
workshop circuit.

## 9. Configure probe-rs

Connect either probe and check that the host detects it:

```sh
probe-rs list
```

Replace the `picotool` runner with the correct SWD runner.

For Pico W:

```toml
[target.thumbv6m-none-eabi]
runner = "probe-rs run --chip RP2040"
```

For Pico 2 W:

```toml
[target.thumbv8m.main-none-eabihf]
runner = "probe-rs run --chip RP235x --protocol swd"
```

Build, flash, and stream `defmt` output:

```sh
cargo run
```

Use an optimized build when desired:

```sh
cargo run --release
```

Keep debug information enabled in the project's release profile if you want
useful backtraces and source-level debugging in release builds:

```toml
[profile.release]
debug = 2
```

## Troubleshooting

- **`cargo`, `rustc`, or `picotool` is not found:** restart the terminal and
  check that its installation directory is on `PATH`.
- **The build uses the wrong instruction set:** compare the Cargo build target
  and `embassy-rp` feature with the table at the top of this page.
- **The on-board LED does not blink:** use the W-board example, confirm all
  CYW43 firmware files and paths, and check that CYW43 initialization succeeds.
- **`picotool info` finds no board:** reconnect it while holding BOOTSEL and
  check for the `RPI-RP2` or `RP2350` drive.
- **`probe-rs list` finds no probe:** reconnect it and, on Linux, recheck the
  udev rules.
- **The probe is found but cannot connect:** verify target power and common
  ground, then check that SWDIO and SWCLK are not reversed.
- **A Pico used as probe does not appear:** confirm that the UF2 matches the
  probe generation (`debugprobe_on_pico.uf2` or `debugprobe_on_pico2.uf2`).
- **Flashing reports the wrong chip:** use `RP2040` for Pico W and `RP235x` for
  Pico 2 W.

## Upstream references

- [Embassy repository and examples](https://github.com/embassy-rs/embassy)
- [picotool](https://github.com/raspberrypi/picotool)
- [probe-rs installation](https://probe.rs/docs/getting-started/installation/)
- [Rust installation](https://www.rust-lang.org/tools/install)
- [Raspberry Pi Pico-series documentation](https://www.raspberrypi.com/documentation/microcontrollers/pico-series.html)

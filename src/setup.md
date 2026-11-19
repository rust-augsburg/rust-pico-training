# Set up the development environment

This guide prepares Linux, macOS, or Windows 11 for Embedded Rust development
with either of these wireless boards:

| Board | Microcontroller | Rust target | HAL |
|---|---|---|---|
| Raspberry Pi Pico W / Pico WH | RP2040 (Cortex-M0+) | `thumbv6m-none-eabi` | `rp2040-hal` |
| Raspberry Pi Pico 2 W / Pico 2 WH | RP2350 (Cortex-M33) | `thumbv8m.main-none-eabihf` | `rp235x-hal` |

The host setup is the same for both boards. The project configuration, linker
memory map, HAL, and `probe-rs` chip selection must match the board. The `W`
models also drive their on-board LED through the CYW43 wireless chip, so an
example written for a non-wireless Pico's GPIO LED may compile but will not
blink the on-board LED.

This course uses an SWD debug probe and `probe-rs`. USB/UF2 flashing is
described as an alternative at the end of this page.

## 1. Install host prerequisites

Choose the section for your operating system.

### Ubuntu or another Debian-based Linux

```sh
sudo apt update
sudo apt install -y \
  build-essential cmake curl git libssl-dev libudev-dev pkg-config
```

Linux also needs udev rules so that `probe-rs` can access a USB debug probe
without `sudo`:

```sh
curl --proto '=https' --tlsv1.2 -o /tmp/69-probe-rs.rules \
  https://probe.rs/files/69-probe-rs.rules
sudo install -m 0644 /tmp/69-probe-rs.rules /etc/udev/rules.d/69-probe-rs.rules
sudo udevadm control --reload
sudo udevadm trigger
```

Unplug and reconnect the debug probe. If access is still denied, follow the
current [probe-rs Linux setup instructions](https://probe.rs/docs/getting-started/probe-setup/#linux-udev-rules).

### macOS

Install Apple's command-line developer tools (Git and a native compiler are
included):

```sh
xcode-select --install
```

Complete the installer dialog before continuing. A CMSIS-DAP probe, including
a Pico running Debug Probe firmware, needs no additional macOS driver.
Homebrew is optional and is not required by this guide.

### Windows 11

1. Install [Git for Windows](https://git-scm.com/download/win).
2. Download and run [`rustup-init.exe`](https://rustup.rs/). When prompted,
   allow Rust to install the Visual Studio C++ Build Tools, or install the
   **Desktop development with C++** workload yourself.
3. Use a normal 64-bit PowerShell terminal for the remaining Windows commands.
   Native Windows is recommended for USB debugging; WSL requires USB forwarding
   and separate Linux udev configuration.

A Pico used as a CMSIS-DAP debug probe normally needs no extra Windows driver.
Do not replace its driver with Zadig/WinUSB unless `probe-rs` reports a driver
problem and the [probe-rs probe setup page](https://probe.rs/docs/getting-started/probe-setup/)
requires it for that particular probe.

## 2. Install Rust

On Linux and macOS, run:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Choose the standard installation. Restart the terminal afterwards (or load the
environment as instructed by the installer).

On Windows 11, Rust was installed by `rustup-init.exe` in the preceding
section. Close and reopen PowerShell so that `%USERPROFILE%\.cargo\bin` is on
`PATH`.

Update stable Rust and install the targets for **both** Pico generations:

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

The final command must list both targets shown above.

## 3. Install the Embedded Rust tools

These commands are identical in a Unix shell and PowerShell:

```sh
cargo install --locked probe-rs-tools
cargo install --locked flip-link
cargo install --locked cargo-generate
```

`probe-rs-tools` installs the `probe-rs`, `cargo-embed`, and `cargo-flash`
commands. The old command `cargo install probe-rs --features cli` is obsolete.

Check that the tools can be found:

```sh
probe-rs --version
probe-rs list
cargo generate --version
flip-link --version
```

`probe-rs list` may report no probes until one is connected, but it should not
report that the command is missing.

## 4. Install Visual Studio Code

Install [Visual Studio Code](https://code.visualstudio.com/download), then add:

```sh
code --install-extension rust-lang.rust-analyzer
code --install-extension probe-rs.probe-rs-debugger
```

If `code` is not on `PATH`, install the extensions from VS Code's Extensions
view instead. The CodeLLDB or Microsoft C/C++ extension is not required for
debugging through `probe-rs`.

## 5. Prepare and connect a debug probe

The target Pico W/Pico 2 W cannot debug itself. Use a Raspberry Pi Debug Probe,
or flash a second Pico-series board with the current
[Raspberry Pi Debug Probe firmware](https://github.com/raspberrypi/debugprobe/releases):

- `debugprobe_on_pico.uf2` for a first-generation Pico used as the probe;
- `debugprobe_on_pico2.uf2` for a Pico 2 used as the probe.

Connect the probe's SWDIO, SWCLK, and GND to the target board. The target also
needs power. Then verify the host connection:

```sh
probe-rs list
```

The debug-probe firmware depends on the **probe board**, not on whether the
target is a Pico W or Pico 2 W.

## 6. Use the correct project configuration

Start from the template for the target board's microcontroller:

```sh
# Raspberry Pi Pico W (RP2040)
cargo generate --git https://github.com/rp-rs/rp2040-project-template

# Raspberry Pi Pico 2 W (RP2350)
cargo generate --git https://github.com/rp-rs/rp235x-project-template
```

Do not switch an existing project merely by changing the Rust target. Its HAL
dependencies, `memory.x`, linker flags, and runner must also match the chip.
The generated `.cargo/config.toml` should use this pairing for Pico W:

```toml
[build]
target = "thumbv6m-none-eabi"

[target.thumbv6m-none-eabi]
runner = "probe-rs run --chip RP2040"
```

For Pico 2 W, the corresponding configuration is:

```toml
[build]
target = "thumbv8m.main-none-eabihf"

[target.thumbv8m.main-none-eabihf]
runner = "probe-rs run --chip RP235x --protocol swd"
```

The current RP235x template includes both `probe-rs` and `picotool` runner
examples; uncomment the `probe-rs` line and comment out the `picotool` line for
the SWD workflow used in this course.

Build and flash from the generated project directory:

```sh
cargo build
cargo run --release
```

## Optional: flash through USB instead of SWD

Both generations support BOOTSEL mode. Hold **BOOTSEL** while connecting USB;
the board appears as `RPI-RP2` (Pico W) or `RP2350` (Pico 2 W). You can then
copy a suitable UF2 file to that drive.

For command-line USB flashing and UF2 conversion, use a current
[`picotool`](https://github.com/raspberrypi/picotool) release. It supports both
RP2040 and RP2350 ELF files. Follow its platform-specific installation guide,
then configure it as the Cargo runner as documented by
[`rp-hal`](https://github.com/rp-rs/rp-hal#loading-over-usb-with-picotool).

`elf2uf2-rs` is an RP2040-era tool and is therefore not installed as a common
dependency here. Prefer `picotool` when the same workflow must support both
Pico W and Pico 2 W.

## Troubleshooting

- **`cargo` or `rustc` is not found:** restart the terminal. On Windows, check
  that `%USERPROFILE%\.cargo\bin` is on `PATH`; on Linux/macOS, check
  `$HOME/.cargo/bin`.
- **The build uses the wrong instruction set:** check the `[build] target` in
  `.cargo/config.toml` against the table at the top of this page.
- **`probe-rs` cannot open the probe on Linux:** reconnect it after installing
  the udev rules and check `probe-rs list` again.
- **`probe-rs` cannot identify the target:** check the SWD wiring and confirm
  that the runner/chip name belongs to RP2040 or RP2350 as appropriate.
- **The on-board LED does not blink:** use a Pico **W**/**2 W** example that
  initializes CYW43; the wireless boards do not connect that LED directly to a
  normal RP GPIO pin.

Current upstream references:

- [`rp-hal` programming and target guidance](https://github.com/rp-rs/rp-hal#programming)
- [probe-rs installation](https://probe.rs/docs/getting-started/installation/)
- [Rust installation](https://www.rust-lang.org/tools/install)
- [Raspberry Pi Pico-series documentation](https://www.raspberrypi.com/documentation/microcontrollers/pico-series.html)

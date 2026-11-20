# Set up Rust for ESP32 boards

This additional guide covers bare-metal Embedded Rust with
[`esp-hal`](https://docs.espressif.com/projects/rust/esp-hal/). It uses
[`esp-generate`](https://github.com/esp-rs/esp-generate) to create a project and
[`espflash`](https://github.com/esp-rs/espflash) to flash it over USB. An
ESP-IDF application using `std` has a different setup and is not covered here.

## 1. Choose a chip architecture

“ESP32” is a product family, not a CPU architecture. Check the full name
printed on the module before installing a toolchain.

| CPU architecture | Common chips | Rust toolchain | Recommendation |
|---|---|---|---|
| **RISC-V** | ESP32-C2, C3, C5, C6, C61, H2, H4, P4, and S31 | Standard upstream Rust | **Preferred for a new project** |
| **Xtensa** | Original ESP32, ESP32-S2, and ESP32-S3 | Espressif's Rust/LLVM fork | Use when the board or its peripherals require it |

The letter in the product name is not a reliable architecture test: for
example, the ESP32-P4 and ESP32-S31 are RISC-V chips. Check the current
[`esp-hal` support table](https://docs.espressif.com/projects/rust/esp-hal/main/index.html)
when using a new device. The ESP8266 is not supported by `esp-hal` and is
outside this guide.

For a workshop or first project, choose an **ESP32-C3** or **ESP32-C6** board.
Both use the normal Rust toolchain and avoid the additional Xtensa compiler.

## 2. Install the common tools

First install Rust with [`rustup`](https://rustup.rs/). On Windows 11, use a
normal 64-bit PowerShell terminal and allow `rustup-init.exe` to install the
Visual Studio C++ Build Tools when prompted. On macOS, install Apple's command
line tools first if they are missing:

```sh
xcode-select --install
```

After reopening the terminal, install the ESP project generator and serial
flasher:

```sh
rustup update stable
cargo install esp-generate --locked
cargo install espflash --locked
```

Verify the commands:

```sh
rustc --version
esp-generate --version
espflash --version
```

Use a USB **data** cable. Some development boards contain a CP210x, CH340, or
FTDI USB-to-serial chip and may need its manufacturer's driver on macOS or
Windows. On Linux, make sure your user may access the serial port; the exact
group and udev rules depend on the distribution.

## 3. Recommended setup: RISC-V

RISC-V ESP32 chips use upstream Rust. Install `rust-src` and the targets used
by the common starter boards:

```sh
rustup toolchain install stable --component rust-src
rustup target add riscv32imc-unknown-none-elf
rustup target add riscv32imac-unknown-none-elf
```

The usual pairing is:

| Board | Rust target |
|---|---|
| ESP32-C2 or ESP32-C3 | `riscv32imc-unknown-none-elf` |
| ESP32-C6 or ESP32-H2 | `riscv32imac-unknown-none-elf` |

Other RISC-V chips may require a different target. Let `esp-generate` create
the configuration for the exact selected chip instead of copying a target
from another board.

Create a project:

```sh
esp-generate
```

In the interactive menu:

1. Enter a project name and destination.
2. Select the exact chip on the development board.
3. Keep `espflash` as the flashing method.
4. Select the **Embassy** option if the application should use the async
   Embassy executor; otherwise generate the basic `esp-hal` example.
5. Generate the project, change into its directory, and read its `README.md`.

The generated `rust-toolchain.toml` and `.cargo/config.toml` are authoritative
for that chip. Build, flash, and open the serial monitor with:

```sh
cargo run --release
```

On many boards `espflash` enters the bootloader automatically. If it cannot
connect, hold **BOOT**, tap **EN/RESET**, release **BOOT**, and retry.

## 4. Alternative setup: Xtensa

The original ESP32, ESP32-S2, and ESP32-S3 use Xtensa cores. Xtensa is not an
upstream Rust target, so these chips require Espressif's toolchain manager
[`espup`](https://github.com/esp-rs/espup):

```sh
cargo install espup --locked
espup install
```

On Linux and macOS, `espup install` prints the path of a generated environment
file. Source that file in every new shell, or add the printed command to the
shell startup file. A typical installation prints a command similar to:

```sh
. "$HOME/export-esp.sh"
```

Use the exact path printed on your machine. This extra environment step is not
needed on Windows.

Now create and run the project in the same way as for RISC-V:

```sh
esp-generate
cd <generated-project>
cargo run --release
```

Select **ESP32**, **ESP32-S2**, or **ESP32-S3** as appropriate. Do not replace
the generated Xtensa target with a RISC-V target, and do not try to install an
Xtensa target using `rustup target add`.

## 5. Embassy on ESP32

Embassy works on supported RISC-V and Xtensa chips through `esp-hal`. Select
the Embassy option in `esp-generate`; the generator supplies compatible
`esp-hal`, `embassy-executor`, and time-driver configuration. Start with the
generated versions rather than combining dependency versions from unrelated
examples.

For Wi-Fi, Bluetooth, or IEEE 802.15.4, choose a chip that actually contains
the required radio and consult the generated example. Radio support differs
between chips even when their CPU architecture is the same. Never commit
network credentials.

## Troubleshooting

- **Wrong chip selected:** regenerate the project for the exact module; flash
  layout, target features, and peripherals differ between ESP32 variants.
- **No serial port:** try a known data cable, another USB port, the board's
  labelled USB/UART connector, and any required USB-to-serial driver.
- **Permission denied on Linux:** add the user to the distribution's serial
  device group or install its udev rule, then log out and reconnect the board.
- **Flashing cannot start:** close other serial monitors and use the
  BOOT/EN sequence described above.
- **Xtensa compiler is not found:** source the environment file produced by
  `espup install` in the current terminal.
- **An old tutorial uses `esp-template`:** use `esp-generate` instead; the old
  template repository is archived.

The official [Rust on ESP Book](https://docs.espressif.com/projects/rust/book/)
contains the current toolchain and board-specific details.

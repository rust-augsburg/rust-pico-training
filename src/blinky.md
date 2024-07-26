#  Run [blinky example](https://github.com/rust-augsburg/blinky)


## Clone the repo

```sh
git clone https://github.com/rust-augsburg/blinky
cd blinky
```

## Setup Pico in BOOTSEL mode

To keep the setup minimal we via flash our pico via UF2 (USB Flashing Format).
Therefore you have to put your Pico in BOOTSEL mode:

1. **Locate the BOOTSEL button:** This small rectangular button is usually positioned near the micro USB port on your Pico board.

2. **Hold the BOOTSEL button:** Press and hold the BOOTSEL button firmly.

3. **Connect the Micro USB cable:** While still holding the BOOTSEL button, connect the other end of the micro USB cable to your computer.

4. **Release the BOOTSEL button:** Once the computer recognizes the Pico, you can release the BOOTSEL button.


## Run

```sh
cargo run
```

<!--
## Possible Issues:

### error: unsupported output in build script of `defmt v0.3.7`

Update the toolchain: 

```sh
rustup update
```
-->


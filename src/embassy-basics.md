# Embassy Basics

Embassy provides an async executor, timers, and hardware drivers for embedded
Rust. These examples all blink the LED built into a Raspberry Pi Pico board,
but the LED connection differs between the standard and wireless boards.

| Board | Chip | Rust target | `embassy-rp` feature | LED control |
|---|---|---|---|---|
| Pico | RP2040 | `thumbv6m-none-eabi` | `rp2040` | GPIO 25 |
| Pico W | RP2040 | `thumbv6m-none-eabi` | `rp2040` | CYW43 GPIO 0 |
| Pico 2 | RP2350A | `thumbv8m.main-none-eabihf` | `rp235xa` | GPIO 25 |
| Pico 2 W | RP2350A | `thumbv8m.main-none-eabihf` | `rp235xa` | CYW43 GPIO 0 |

The examples assume the project dependencies and linker configuration from the
[setup chapter](./setup.md). The numbered comments are explained immediately
after each program.

## Pico (RP2040)

```rust
#![no_std] // [1]
#![no_main]

use defmt_rtt as _;
use embassy_executor::Spawner;
use embassy_rp::gpio::{Level, Output};
use embassy_time::Timer;
use panic_probe as _;

#[embassy_executor::main(
    executor = "embassy_rp::executor::Executor",
    entry = "cortex_m_rt::entry"
)] // [2]
async fn main(_spawner: Spawner) {
    let p = embassy_rp::init(Default::default()); // [3]
    let mut led = Output::new(p.PIN_25, Level::Low); // [4]

    loop {
        led.set_high();
        Timer::after_millis(500).await; // [5]
        led.set_low();
        Timer::after_millis(500).await;
    }
}
```

1. `no_std` removes the operating-system standard library; `no_main` lets the
   Cortex-M runtime provide the reset entry point.
2. The macro creates the executor and runs this async `main` task.
3. `embassy_rp::init` configures the RP2040 and returns ownership tokens for
   its peripherals and pins.
4. The non-wireless Pico LED is wired directly to GPIO 25.
5. Awaiting an Embassy timer suspends this task without a busy-wait loop.

## Pico W (RP2040 + CYW43439)

The Pico W LED is connected to the CYW43 wireless chip, not directly to an
RP2040 GPIO. Even a blinky program must therefore start the CYW43 driver.

```rust
#![no_std]
#![no_main]

use cyw43::aligned_bytes;
use cyw43_pio::{DEFAULT_CLOCK_DIVIDER, PioSpi};
use defmt::unwrap;
use defmt_rtt as _;
use embassy_executor::Spawner;
use embassy_rp::gpio::{Level, Output};
use embassy_rp::peripherals::{DMA_CH0, DMA_CH1, PIO0};
use embassy_rp::pio::{InterruptHandler, Pio};
use embassy_rp::{bind_interrupts, dma};
use embassy_time::Timer;
use panic_probe as _;
use static_cell::StaticCell;

bind_interrupts!(struct Irqs { // [1]
    PIO0_IRQ_0 => InterruptHandler<PIO0>;
    DMA_IRQ_0 => dma::InterruptHandler<DMA_CH0>,
        dma::InterruptHandler<DMA_CH1>;
});

#[embassy_executor::task]
async fn cyw43_task(
    runner: cyw43::Runner<
        'static,
        cyw43::SpiBus<Output<'static>, PioSpi<'static, PIO0, 0>>,
        cyw43::Cyw43439,
    >,
) -> ! {
    runner.run().await // [2]
}

#[embassy_executor::main(
    executor = "embassy_rp::executor::Executor",
    entry = "cortex_m_rt::entry"
)]
async fn main(spawner: Spawner) {
    let p = embassy_rp::init(Default::default());
    let fw = aligned_bytes!("../firmware/43439A0.bin"); // [3]
    let clm = aligned_bytes!("../firmware/43439A0_clm.bin");
    let nvram = aligned_bytes!("../firmware/nvram_rp2040.bin");

    let pwr = Output::new(p.PIN_23, Level::Low);
    let cs = Output::new(p.PIN_25, Level::High);
    let mut pio = Pio::new(p.PIO0, Irqs);
    let spi = PioSpi::new( // [4]
        &mut pio.common,
        pio.sm0,
        DEFAULT_CLOCK_DIVIDER,
        pio.irq0,
        cs,
        p.PIN_24,
        p.PIN_29,
        dma::Channel::new(p.DMA_CH0, Irqs),
        dma::Channel::new(p.DMA_CH1, Irqs),
    );

    static STATE: StaticCell<cyw43::State> = StaticCell::new();
    let state = STATE.init(cyw43::State::new());
    let (_net, mut control, runner) =
        cyw43::new(state, pwr, spi, fw, nvram).await; // [5]
    spawner.spawn(unwrap!(cyw43_task(runner)));
    control.init(clm, cyw43::Config::default()).await;

    loop {
        control.gpio_set(0, true).await; // [6]
        Timer::after_millis(500).await;
        control.gpio_set(0, false).await;
        Timer::after_millis(500).await;
    }
}
```

1. PIO and DMA interrupts move data between the RP2040 and CYW43.
2. The CYW43 runner must remain alive in its own Embassy task.
3. Firmware, CLM, and NVRAM are compiled into the program. Adjust these paths
   to the files in the project; use the matched files described in
   [CYW43 firmware setup](./setup.md#cyw43-firmware).
4. PIO implements the private SPI connection to the wireless chip. These are
   internal board connections, not pins to wire on the breadboard.
5. `cyw43::new` separates the background runner from the control interface.
6. The onboard LED is CYW43 GPIO 0, so changing it is an async driver call.

## Pico 2 (RP2350A)

The minimal source is almost identical to the Pico example. The important
difference is the build configuration: select `rp235xa` and compile for
`thumbv8m.main-none-eabihf`.

```rust
#![no_std] // [1]
#![no_main]

use defmt_rtt as _;
use embassy_executor::Spawner;
use embassy_rp::gpio::{Level, Output};
use embassy_time::Timer;
use panic_probe as _;

#[embassy_executor::main(
    executor = "embassy_rp::executor::Executor",
    entry = "cortex_m_rt::entry"
)]
async fn main(_spawner: Spawner) {
    let p = embassy_rp::init(Default::default()); // [2]
    let mut led = Output::new(p.PIN_25, Level::Low); // [3]

    loop {
        led.set_high();
        Timer::after_millis(500).await; // [4]
        led.set_low();
        Timer::after_millis(500).await;
    }
}
```

1. The Rust source does not name the CPU. Cargo's target and the `rp235xa`
   feature select the Cortex-M33/RP2350A implementation.
2. The same HAL API initializes the RP2350 and returns its peripheral tokens.
3. The non-wireless Pico 2 also connects its LED directly to GPIO 25.
4. The executor can run other tasks while this one awaits the timer.

## Pico 2 W (RP2350A + CYW43439)

The Pico 2 W follows the same CYW43 design as the Pico W. Its RP2350 clocking
requires the `RM2_CLOCK_DIVIDER` selected by Embassy's official example.

```rust
#![no_std]
#![no_main]

use cyw43::aligned_bytes;
use cyw43_pio::{PioSpi, RM2_CLOCK_DIVIDER}; // [1]
use defmt::unwrap;
use defmt_rtt as _;
use embassy_executor::Spawner;
use embassy_rp::gpio::{Level, Output};
use embassy_rp::peripherals::{DMA_CH0, DMA_CH1, PIO0};
use embassy_rp::pio::{InterruptHandler, Pio};
use embassy_rp::{bind_interrupts, dma};
use embassy_time::Timer;
use panic_probe as _;
use static_cell::StaticCell;

bind_interrupts!(struct Irqs {
    PIO0_IRQ_0 => InterruptHandler<PIO0>;
    DMA_IRQ_0 => dma::InterruptHandler<DMA_CH0>,
        dma::InterruptHandler<DMA_CH1>;
});

#[embassy_executor::task]
async fn cyw43_task(
    runner: cyw43::Runner<
        'static,
        cyw43::SpiBus<Output<'static>, PioSpi<'static, PIO0, 0>>,
        cyw43::Cyw43439,
    >,
) -> ! {
    runner.run().await // [2]
}

#[embassy_executor::main(
    executor = "embassy_rp::executor::Executor",
    entry = "cortex_m_rt::entry"
)]
async fn main(spawner: Spawner) {
    let p = embassy_rp::init(Default::default());
    let fw = aligned_bytes!("../firmware/43439A0.bin"); // [3]
    let clm = aligned_bytes!("../firmware/43439A0_clm.bin");
    let nvram = aligned_bytes!("../firmware/nvram_rp2040.bin");

    let pwr = Output::new(p.PIN_23, Level::Low);
    let cs = Output::new(p.PIN_25, Level::High);
    let mut pio = Pio::new(p.PIO0, Irqs);
    let spi = PioSpi::new(
        &mut pio.common,
        pio.sm0,
        RM2_CLOCK_DIVIDER, // [4]
        pio.irq0,
        cs,
        p.PIN_24,
        p.PIN_29,
        dma::Channel::new(p.DMA_CH0, Irqs),
        dma::Channel::new(p.DMA_CH1, Irqs),
    );

    static STATE: StaticCell<cyw43::State> = StaticCell::new();
    let state = STATE.init(cyw43::State::new());
    let (_net, mut control, runner) =
        cyw43::new(state, pwr, spi, fw, nvram).await; // [5]
    spawner.spawn(unwrap!(cyw43_task(runner)));
    control.init(clm, cyw43::Config::default()).await;

    loop {
        control.gpio_set(0, true).await; // [6]
        Timer::after_millis(500).await;
        control.gpio_set(0, false).await;
        Timer::after_millis(500).await;
    }
}
```

1. The Pico 2 W example uses the RP2350-specific radio clock divider.
2. As on Pico W, the background runner continuously services the CYW43.
3. Pico 2 W currently uses the same CYW43439 firmware, CLM, and
   `nvram_rp2040.bin` data as Embassy's official example.
4. Do not replace `RM2_CLOCK_DIVIDER` with `DEFAULT_CLOCK_DIVIDER`; SPI may run
   too fast for reliable communication on Pico 2 W.
5. Initialization returns a network device, a control handle, and the runner.
6. The LED remains CYW43 GPIO 0; it is not RP2350 GPIO 25.

## Compare the four programs

The standard boards demonstrate Embassy's smallest pattern: initialize the
HAL, configure one GPIO, then await timers in an infinite loop. The W boards
add PIO, DMA, firmware, and a permanent driver task because their LEDs sit
behind the wireless controller. This is a hardware difference, not overhead
introduced by async Rust.

For maintained, buildable versions, compare Embassy's official
[RP2040 examples](https://github.com/embassy-rs/embassy/tree/main/examples/rp/src/bin)
and
[RP235x examples](https://github.com/embassy-rs/embassy/tree/main/examples/rp235x/src/bin).

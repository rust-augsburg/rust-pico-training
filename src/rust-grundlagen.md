# Rust Basics

```rust,editable
fn main() {
    // Immutable variable with explicit type annotation (default in Rust)
    let _logical: bool = true;

    // Mutable variable: `mut` is required to reassign or borrow mutably
    let mut mutable: i32 = 12;

    // Pass a mutable reference (&mut) so the function can mutate in place
    modify_value(&mut mutable);
    println!("Modified value: {}", mutable);

    // Pass an immutable reference (&) to borrow without taking ownership or mutating
    show_value(&mutable);

    demo_for_loop();
}

fn modify_value(value: &mut i32) {
    // Dereference (*) to update the underlying i32 value
    *value += 9;
}

fn show_value(value: &i32) {
    // `println!` auto-dereferences `&i32` for `Display`, so `*value` isn't needed here
    println!("Show value: {}", value);
}

fn demo_for_loop() {
    // Half-open range `0..3` yields 0, 1, and 2 (`0..=3` would include 3)
    for i in 0..3 {
        println!("Loop iteration: {i}");
    }
}
```

Obiger Code nutzt <https://play.rust-lang.org/> zum Ausführen.

## Links

[Rust by Example](https://doc.rust-lang.org/stable/rust-by-example/) zum Nachschlagen

[Rust Book](https://doc.rust-lang.org/book/) zum Lernen

[Rustlings](https://rustlings.cool/) zum Üben

[Mainmatter: Learn Rust, one exercise at a time](https://github.com/mainmatter/100-exercises-to-learn-rust)

[Mainmatter: Migrate C to Rust, one exercise at a time](https://github.com/mainmatter/migrating-c-to-rust)

[crates.io](https://crates.io/)

[docs.rs](https://docs.rs/)


# Don't Guess, Test: Built-in Assertions in Rust 

```rust,editable
fn main() {
    let mut s = String::from("rust");
    s.push_str(" lang");

    assert_eq!(s, "rust lang");
    assert_ne!(s, "rust");
    assert!(s.contains("lang"));

    println!("Assertions passed: {s}");
}

#[cfg(test)]
mod tests {
    #[test]
    fn string_tests() {
        let s = String::from("  hello ").trim().to_string();
        assert_eq!(s, "hello");
        assert!(s.starts_with("he"));
    }
}
```

# Extended CheatSheet

```rust,editable
fn main() {
    // --- 1. Immutability & Mutability ---
    let _logical: bool = true; // Immutable by default
    let mut mutable: i32 = 12; // Mutable (`i32` implements `Copy`)

    modify_value(&mut mutable); // Pass a mutable reference (&mut)
    println!("Modified value: {}", mutable);
    show_value(&mutable); // Pass an immutable reference (&)

    // --- 2. Ownership vs. Borrowing ---
    // Heap-allocated `String` does NOT implement `Copy` -> moving transfers ownership.
    let greeting = String::from("hello");
    let moved_greeting = greeting; // `greeting` is moved and can no longer be used
    // println!("{}", greeting); // ERROR: borrow of moved value: `greeting`

    // Borrow with `&String` (or `&str`) to read without taking ownership.
    let len = measure_text(&moved_greeting);
    println!("'{}' has length {}", moved_greeting, len);

    // --- 3. Slices (`String` vs. `&str`) ---
    // A string slice (`&str`) views part of a `String` or string literal without owning it.
    let full_text = String::from("rust cheatsheet");
    let first_word: &str = &full_text[0..4]; // "rust" (byte indices; mind UTF-8 boundaries)
    let literal_slice: &str = "static slice"; // Lives in binary ('static lifetime)
    println!("Slice: {first_word}, literal: {literal_slice}");

    // --- 4. Borrow Checker Rules ---
    // Rule A: You can have MANY immutable borrows (`&T`) OR ONE mutable borrow (`&mut T`),
    // never both at the same time while a borrow is active.
    let mut note = String::from("draft");
    let r1 = &note;
    let r2 = &note;
    println!("Immutable borrows: {r1}, {r2}");
    // r1 and r2 are no longer used after this point (Non-Lexical Lifetimes / NLL),
    // so a mutable borrow is now allowed:
    let r_mut = &mut note;
    r_mut.push_str(" v2");
    println!("Mutated note: {r_mut}");

    // Rule B: References must never outlive the data they point to (no dangling references).
    // (See `dangling_example` note below.)

    // --- 5. Exhaustive `match` Statement ---
    demo_match(1);
    demo_match(2);
    demo_match(42);
    demo_for_loop();
}

fn modify_value(value: &mut i32) {
    *value += 9;
}

fn show_value(value: &i32) {
    // `println!` auto-dereferences `&i32` for `Display`
    println!("Show value: {}", value);
}

fn measure_text(text: &str) -> usize {
    // Accepting `&str` works for both `&String` (via deref coercion) and `&str` slices
    text.len()
}

fn demo_match(code: i32) {
    // `match` is an expression and must be exhaustive: every possible `i32` value
    // must be handled, which is why the catch-all `_` arm is required here.
    let status = match code {
        1 => "Started",
        2 => "In Progress",
        3..=5 => "Review Stage", // Inclusive range pattern
        other if other < 0 => "Invalid negative code", // Match guard
        _ => "Other / Catch-all", // Required to cover remaining values
    };
    println!("Code {code} -> {status}");
}

fn demo_for_loop() {
    for i in 0..3 {
        println!("Loop iteration: {i}");
    }
}

// Why Rust forbids dangling references:
// fn dangle() -> &String {
//     let s = String::from("temporary");
//     &s // ERROR: `s` is dropped at the end of `dangle()`, leaving `&s` dangling
// }
```


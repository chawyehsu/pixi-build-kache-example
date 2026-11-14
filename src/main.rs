use anyhow::Result;
use clap::{Arg, Command};

fn main() -> Result<()> {
    let matches = Command::new("hello-kache")
        .version(env!("CARGO_PKG_VERSION"))
        .about("Tiny demo of pixi build + kache compilation caching")
        .arg(Arg::new("name").default_value("world"))
        .get_matches();

    let name = matches.get_one::<String>("name").expect("has a default");
    println!("Hello, {}!", name);

    Ok(())
}

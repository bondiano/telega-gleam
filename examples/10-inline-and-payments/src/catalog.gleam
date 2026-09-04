//// The shop's inventory. A real bot would read this from a database through
//// `ctx.dependencies`; keeping it a constant list makes the example about
//// inline mode and payments rather than about storage.

import gleam/list
import gleam/string

pub type Item {
  Item(
    /// Also the invoice payload: it is what comes back in the pre-checkout
    /// query and in the successful payment, so it has to identify the order.
    id: String,
    title: String,
    description: String,
    /// Price in Telegram Stars (XTR has no fractional units).
    stars: Int,
  )
}

pub const items = [
  Item(
    id: "theme-nord",
    title: "Nord theme",
    description: "A cold, quiet palette for long nights",
    stars: 50,
  ),
  Item(
    id: "theme-solar",
    title: "Solarized theme",
    description: "The classic, in both flavours",
    stars: 50,
  ),
  Item(
    id: "pack-emoji",
    title: "Emoji pack",
    description: "120 hand-drawn reactions",
    stars: 100,
  ),
  Item(
    id: "pack-sounds",
    title: "Sound pack",
    description: "Notification sounds that do not startle anyone",
    stars: 100,
  ),
  Item(
    id: "sub-pro",
    title: "Pro for a month",
    description: "Everything above, plus early access",
    stars: 250,
  ),
]

/// Case-insensitive substring search over title and description. An empty
/// query returns everything — that is what the user sees when they type the
/// bot's name and stop.
pub fn search(query: String) -> List(Item) {
  let needle = query |> string.trim |> string.lowercase
  use item <- list.filter(items)
  needle == ""
  || string.contains(string.lowercase(item.title), needle)
  || string.contains(string.lowercase(item.description), needle)
}

pub fn find(id: String) -> Result(Item, Nil) {
  list.find(items, fn(item) { item.id == id })
}

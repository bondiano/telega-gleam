//// Shared unsafe type coercion utility.

@external(erlang, "erlang", "term_to_binary")
fn to_binary(value: a) -> BitArray

@external(erlang, "erlang", "binary_to_term")
fn from_binary(binary: BitArray) -> b

@internal
pub fn unsafe_coerce(value: value_type) -> result_type {
  value |> to_binary |> from_binary
}

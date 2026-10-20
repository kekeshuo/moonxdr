///|
/// Compatibility signed32 literal utility from 0.1.0. New schema parsing uses
/// parse_integer_constant, with context-sensitive range validation.
pub fn parse_constant_number(
  text : String,
  offset? : Int = 0,
) -> Int raise XdrError {
  constant_i32(parse_integer_constant(text, offset~), offset)
}

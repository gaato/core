// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Error for malformed Base32 input.
///
/// `Malformed(input)` holds the entire input view passed to `decode`, including
/// any whitespace, rather than the suffix starting at the error position.
pub suberror Malformed {
  Malformed(StringView)
} derive(@debug.Debug)

///|
/// Decodes Base32 using the alphabet from RFC 4648 section 6.
///
/// Both padded and unpadded input are accepted. By default, only uppercase
/// letters and digits `2` through `7` are accepted. Set `casefold=true` to also
/// accept ASCII lowercase letters, including mixed case. Digits `0` and `1`
/// are never mapped to letters.
///
/// Set `ignore_whitespace=true` to skip spaces, tabs, CR, and LF anywhere in
/// the input, including between padding characters and after them. Other
/// whitespace is always rejected. Both options default to false.
///
/// Raises `Malformed` for invalid characters, impossible lengths, misplaced or
/// incomplete padding, or nonzero unused bits in the final symbol. Padding
/// may appear only at the end, followed by ignored whitespace if enabled.
/// Empty input decodes to empty bytes.
///
/// ```mbt check
/// test {
///   inspect(@base32.decode("MZXW6==="), content="b\"foo\"")
///   inspect(@base32.decode("mZxW6", casefold=true), content="b\"foo\"")
/// }
/// ```
pub fn decode(
  text : StringView,
  casefold~ : Bool = false,
  ignore_whitespace~ : Bool = false,
) -> Bytes raise Malformed {
  let buffer = @buffer.Buffer(size_hint=text.length() / 8 * 5)
  let mut pending = 0
  let mut bits = 0
  let mut symbols = 0
  let mut padding = 0
  for code_unit in text.code_units() {
    match code_unit {
      ' ' | '\t' | '\r' | '\n' => {
        guard ignore_whitespace else { raise Malformed(text) }
      }
      '=' => {
        guard symbols is (2 | 4 | 5 | 7) else { raise Malformed(text) }
        padding += 1
        guard padding <= 8 - symbols else { raise Malformed(text) }
      }
      _ => {
        guard padding == 0 else { raise Malformed(text) }
        let value = match code_unit {
          'A'..<='Z' => code_unit.to_int() - 'A'
          'a'..<='z' if casefold => code_unit.to_int() - 'a'
          '2'..<='7' => code_unit.to_int() - '2' + 26
          _ => raise Malformed(text)
        }
        pending = (pending << 5) | value
        bits += 5
        symbols = (symbols + 1) % 8
        if bits >= 8 {
          bits -= 8
          buffer.write_byte((pending >> bits).to_byte())
          // Retain only unused bits; at most twelve bits are held at a time.
          pending = pending & ((1 << bits) - 1)
        }
      }
    }
  }
  guard symbols is (0 | 2 | 4 | 5 | 7) && pending == 0 else {
    raise Malformed(text)
  }
  guard padding == 0 || padding == 8 - symbols else { raise Malformed(text) }
  buffer.to_bytes()
}

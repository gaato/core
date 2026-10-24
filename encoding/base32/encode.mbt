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
const BASE32 : Bytes = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

///|
/// Encodes bytes as Base32 using the uppercase alphabet from RFC 4648 section 6.
///
/// When `padding` is true (the default), `=` completes the final group of eight
/// characters. No whitespace is inserted.
///
/// ```mbt check
/// test {
///   inspect(@base32.encode(b"foo"), content="MZXW6===")
///   inspect(@base32.encode(b"foo", padding=false), content="MZXW6")
/// }
/// ```
pub fn encode(bytes : BytesView, padding~ : Bool = true) -> String {
  let remainder = bytes.length() % 5
  let tail_length = if remainder == 0 {
    0
  } else if padding {
    8
  } else {
    (remainder * 8 + 4) / 5
  }
  let builder = StringBuilder(size_hint=bytes.length() / 5 * 8 + tail_length)
  for byte in bytes; pending = 0, bits = 0 {
    let pending = (pending << 8) | byte.to_int()
    let mut bits = bits + 8
    while bits >= 5 {
      bits -= 5
      builder.write_char(BASE32[(pending >> bits) & 31].to_char())
    }
    // Retain at most four bits, so the accumulator never exceeds twelve bits.
    continue pending & ((1 << bits) - 1), bits
  } nobreak {
    if bits != 0 {
      builder.write_char(BASE32[pending << (5 - bits)].to_char())
    }
  }
  if padding && remainder != 0 {
    let symbols = (remainder * 8 + 4) / 5
    for _ in symbols..<8 {
      builder.write_char('=')
    }
  }
  builder.to_string()
}

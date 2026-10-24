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
test "quickcheck: padded and unpadded round trips" {
  @quickcheck.check(
    (input : (Bytes, Bool)) => {
      let (bytes, padding) = input
      @base32.decode(@base32.encode(bytes, padding~)) == bytes
    },
    count=200,
  )
}

///|
test "quickcheck: arbitrary case mixtures round trip with casefold" {
  @quickcheck.check(
    (input : (Bytes, Array[Bool], Bool)) => {
      let (bytes, flips, padding) = input
      let chars = @base32.encode(bytes, padding~).to_array()
      for i in 0..<chars.length() {
        if !flips.is_empty() && flips[i % flips.length()] {
          chars[i] = chars[i].to_ascii_lowercase()
        }
      }
      @base32.decode(String::from_array(chars), casefold=true) == bytes
    },
    count=200,
  )
}

///|
test "quickcheck: whitespace anywhere round trips with both options" {
  @quickcheck.check(
    (input : (Bytes, Array[(UInt32, UInt32)], Bool, Bool)) => {
      let (bytes, edits, padding, casefold) = input
      let encoded = @base32.encode(bytes, padding~)
      let chars = (if casefold { encoded.to_lower() } else { encoded }).to_array()
      let spaces : ReadOnlyArray[Char] = [' ', '\t', '\r', '\n']
      for (position, choice) in edits {
        let index = (position % (chars.length() + 1).reinterpret_as_uint()).reinterpret_as_int()
        chars.insert(index, spaces[(choice % 4).reinterpret_as_int()])
      }
      @base32.decode(
        String::from_array(chars),
        casefold~,
        ignore_whitespace=true,
      ) ==
      bytes
    },
    count=200,
  )
}

///|
test "quickcheck: nonalphabet insertions always raise" {
  @quickcheck.check(
    (input : (Bytes, UInt32, UInt32, Bool)) => {
      let (bytes, position, choice, padding) = input
      let chars = @base32.encode(bytes, padding~).to_array()
      let invalid : ReadOnlyArray[Char] = [
        '0', '1', '8', '9', '$', '-', '_', '中',
      ]
      let index = (position % (chars.length() + 1).reinterpret_as_uint()).reinterpret_as_int()
      chars.insert(
        index,
        invalid[(choice % invalid.length().reinterpret_as_uint()).reinterpret_as_int()],
      )
      let text = String::from_array(chars)
      try @base32.decode(text, casefold=true, ignore_whitespace=true) catch {
        Malformed(input) => input == text
      } noraise {
        _ => false
      }
    },
    count=200,
  )
}

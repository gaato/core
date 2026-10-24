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
// RFC 4648 section 10, with the corresponding unpadded spellings.
let rfc_vectors : ReadOnlyArray[(Bytes, String, String)] = [
  (b"", "", ""),
  (b"f", "MY======", "MY"),
  (b"fo", "MZXQ====", "MZXQ"),
  (b"foo", "MZXW6===", "MZXW6"),
  (b"foob", "MZXW6YQ=", "MZXW6YQ"),
  (b"fooba", "MZXW6YTB", "MZXW6YTB"),
  (b"foobar", "MZXW6YTBOI======", "MZXW6YTBOI"),
]

///|
test "encode RFC 4648 vectors with and without padding" {
  for (bytes, padded, unpadded) in rfc_vectors {
    assert_eq(@base32.encode(bytes), padded)
    assert_eq(@base32.encode(bytes, padding=false), unpadded)
  }
}

///|
test "encode binary data most significant bit first" {
  inspect(@base32.encode(b"\x00"), content="AA======")
  inspect(@base32.encode(b"\x01"), content="AE======")
  inspect(@base32.encode(b"\x80"), content="QA======")
  inspect(@base32.encode(b"\xff"), content="74======")
  inspect(@base32.encode(b"\x00\x00\x00\x00\x00"), content="AAAAAAAA")
  inspect(@base32.encode(b"\xff\xff\xff\xff\xff"), content="77777777")
}

///|
test "encode a nonzero-offset BytesView" {
  let bytes = b"!foo?"
  inspect(@base32.encode(bytes[1:4]), content="MZXW6===")
  inspect(@base32.encode(bytes[1:4], padding=false), content="MZXW6")
}

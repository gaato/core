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
fn expect_malformed(
  text : StringView,
  casefold~ : Bool = false,
  ignore_whitespace~ : Bool = false,
) -> Unit raise {
  try @base32.decode(text, casefold~, ignore_whitespace~) catch {
    Malformed(input) => assert_eq(input, text)
  } noraise {
    _ => fail("expected Malformed for \{Repr(text)}")
  }
}

///|
test "decode RFC 4648 vectors with and without padding" {
  for (bytes, padded, unpadded) in rfc_vectors {
    assert_eq(@base32.decode(padded), bytes)
    assert_eq(@base32.decode(unpadded), bytes)
  }
}

///|
test "decode binary data" {
  let vectors : ReadOnlyArray[(String, Bytes)] = [
    ("AA======", b"\x00"),
    ("AE======", b"\x01"),
    ("QA======", b"\x80"),
    ("74======", b"\xff"),
    ("AAAAAAAA", b"\x00\x00\x00\x00\x00"),
    ("77777777", b"\xff\xff\xff\xff\xff"),
  ]
  for (text, bytes) in vectors {
    assert_eq(@base32.decode(text), bytes)
  }
}

///|
test "decode lowercase and mixed case only when casefold is enabled" {
  for (_, padded, unpadded) in rfc_vectors {
    if padded != "" {
      expect_malformed(padded.to_lower())
      expect_malformed(unpadded.to_lower())
      expect_malformed(padded.to_lower(), ignore_whitespace=true)
    }
  }
  inspect(@base32.decode("my======", casefold=true), content="b\"f\"")
  inspect(@base32.decode("mZxW6===", casefold=true), content="b\"foo\"")
  inspect(@base32.decode("mZxW6", casefold=true), content="b\"foo\"")
  inspect(@base32.decode("", casefold=true), content="b\"\"")
}

///|
test "decode ASCII whitespace only when ignore_whitespace is enabled" {
  let spaces : ReadOnlyArray[Char] = [' ', '\t', '\r', '\n']
  for (bytes, padded, unpadded) in rfc_vectors {
    for text in [padded, unpadded] {
      for space in spaces {
        for i in 0..<=text.length() {
          let spaced = "\{text[:i]}\{space}\{text[i:]}"
          expect_malformed(spaced)
          expect_malformed(spaced, casefold=true)
          assert_eq(@base32.decode(spaced, ignore_whitespace=true), bytes)
        }
      }
    }
  }
  inspect(
    @base32.decode(" \tM \rY =\n= = = = = \t", ignore_whitespace=true),
    content="b\"f\"",
  )
  inspect(@base32.decode(" \t\r\n", ignore_whitespace=true), content="b\"\"")
}

///|
test "decode casefold and whitespace options together" {
  let text = " \tm Z\rx W\n6 = = = \t"
  expect_malformed(text)
  expect_malformed(text, casefold=true)
  expect_malformed(text, ignore_whitespace=true)
  inspect(
    @base32.decode(text, casefold=true, ignore_whitespace=true),
    content="b\"foo\"",
  )
}

///|
test "decode rejects impossible unpadded lengths" {
  for
    text in ["A", "AAA", "AAAAAA", "AAAAAAAAA", "AAAAAAAAAAA", "AAAAAAAAAAAAAA"] {
    expect_malformed(text)
  }
}

///|
test "decode rejects malformed padding and data after padding" {
  let inputs : ReadOnlyArray[String] = [
    "=", "========", "A=======", "AAA=====", "AAAAAA==", "MY=", "MY=====", "MY=======",
    "MZXQ===", "MZXQ=====", "MZXW6==", "MZXW6====", "MZXW6YQ==", "MZXW6YTB=", "M=Y======",
    "MY===A==", "MY======A", "MY======MY======", "MZXW6YTBMY======A",
  ]
  for text in inputs {
    expect_malformed(text)
    expect_malformed(text, casefold=true, ignore_whitespace=true)
  }
  expect_malformed("MY====== \tA", ignore_whitespace=true)
  expect_malformed("MY===== \t", ignore_whitespace=true)
}

///|
test "decode rejects nonzero unused bits in every partial group" {
  let inputs : ReadOnlyArray[(String, String)] = [
    ("MZ", "MZ======"),
    ("MZXR", "MZXR===="),
    ("MZXW7", "MZXW7==="),
    ("MZXW6YR", "MZXW6YR="),
  ]
  for (unpadded, padded) in inputs {
    expect_malformed(unpadded)
    expect_malformed(padded)
    expect_malformed("MZXW6YTB" + unpadded)
    expect_malformed("MZXW6YTB" + padded)
    expect_malformed(padded.to_lower(), casefold=true)
  }
  expect_malformed("\tmz====== \n", casefold=true, ignore_whitespace=true)
}

///|
test "decode rejects nonalphabet characters without visual mappings" {
  let invalid : ReadOnlyArray[Char] = [
    '0', '1', '8', '9', '-', '_', '+', '/', '$', '\u{00}', '\u{0b}', '\u{0c}', '\u{a0}',
    '\u{2003}', '\u{feff}', '中', '😀',
  ]
  for char in invalid {
    expect_malformed("MY======\{char}")
    expect_malformed("M\{char}======", casefold=true, ignore_whitespace=true)
  }
}

///|
test "decode a nonzero-offset StringView" {
  let text = "☃MZXW6===☃"
  inspect(@base32.decode(text[1:9]), content="b\"foo\"")
}

///|
test "Malformed preserves the complete input view" {
  let wrapped = "☃MZXW6===!☃"
  let text = wrapped[1:10]
  try @base32.decode(text) catch {
    Malformed(input) as err => {
      inspect(input, content="MZXW6===!")
      @debug.debug_inspect(
        err,
        content="Malformed(<StringView: \"MZXW6===!\">)",
      )
    }
  } noraise {
    _ => fail("expected Malformed")
  }
  let spaced = " \tmY===== \n"
  expect_malformed(spaced, casefold=true, ignore_whitespace=true)
}

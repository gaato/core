# Base32

Base32 encoding and decoding using the standard `A–Z2–7` alphabet from
[RFC 4648 section 6](https://www.rfc-editor.org/rfc/rfc4648.html#section-6).
This package does not implement Base32hex or other Base32 alphabets.

## Encoding

`encode` accepts bytes and returns uppercase ASCII without line breaks.
Padding with `=` is enabled by default; set `padding=false` to omit it.

```mbt check
///|
test "encode" {
  inspect(@base32.encode(b"foo"), content="MZXW6===")
  inspect(@base32.encode(b"foo", padding=false), content="MZXW6")
}
```

## Decoding

`decode` returns bytes and accepts both padded and unpadded input. Empty input
returns empty bytes. Lowercase letters and whitespace are rejected by default.

```mbt check
///|
test "decode" {
  inspect(@base32.decode("MZXW6==="), content="b\"foo\"")
  inspect(@base32.decode("MZXW6"), content="b\"foo\"")
}
```

Set `casefold=true` to accept ASCII lowercase letters, including mixed case.
The digits `0` and `1` are never interpreted as letters.

```mbt check
///|
test "decode mixed case" {
  inspect(@base32.decode("mZxW6", casefold=true), content="b\"foo\"")
}
```

Set `ignore_whitespace=true` to ignore spaces, tabs, CR, and LF anywhere in the
input, including between padding characters and after them. Other whitespace
remains invalid. The two options are independent and both default to false.

```mbt check
///|
test "decode with whitespace and lowercase" {
  inspect(
    @base32.decode(" \tmZxW6 = = =\r\n", casefold=true, ignore_whitespace=true),
    content="b\"foo\"",
  )
}
```

## Malformed input

`decode` raises `Malformed` on invalid characters, impossible lengths,
misplaced or incomplete padding, or nonzero unused bits in the last symbol.
Padding must complete the final eight-character group; data after padding is
rejected. Concatenated padded encodings are not accepted.

`Malformed(input)` holds the **entire input view** passed to `decode`, including
any ignored whitespace. It does not hold only the suffix starting at the error.

```mbt check
///|
test "malformed input" {
  try @base32.decode("MZ======") catch {
    Malformed(input) => inspect(input, content="MZ======")
  } noraise {
    _ => fail("expected Malformed")
  }
}
```

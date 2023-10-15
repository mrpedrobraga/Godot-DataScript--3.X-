# Datascript (3.x)

Create simple scripts for your game as data (for now, only in JSON).

Hello world:

```json
[["write", "Hello world!"]]
```

## Syntax:

Literal:

```jsonc
// Normal JSON literals
true
false
1.0
3.0
"Hey there"  // << Be careful with strings, they are special
```

Instruction:

```jsonc
// A function call is an array where the very first element is a string.
// and the rest are the parameters.

// The string is the function that gets called.
["<function_name>", ...params]

// What I meant by strings being special is that strings will turn arrays into function calls.

// This is a function call:
["wait", 1.0]
```

Block:

```jsonc
// A block is an array of instructions / literals

[
  ["write", "Hello world! x1"],
  ["write", "Hello world! x2"]
]

// The interpreter know that this is a block
// because the first element is an Array, an instruction.

// If the first element was a string, this would be
// treated as an instruction, right?
[
  "Hello World!", // This tried to call a function named "Hello World!" lmao
  ["write", "Hello world! x2"]
]

// If the array starts with the string "()"
// It'll be properly interpreted as a block
[
  "()",
  "Hello world!"   // No problem with having a string here, since it's the *second* item.
  ["write", "Hello world! x2"],
]
```

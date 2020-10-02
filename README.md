
TODO:
- More of an API write-up
- More LaTeX examples

# Introduction

Script | Rough description
-- | --
`code_lib.lua`   | General Lua library that exposes "classes" `Word` and `Code`
`mld_tex.lua`    | Used in a Lualatex compiled TeX document for Chapter 1 material
`linear_tex.lua` | Also used in a Lualatex compiled TeX document, but for Chapter 2 material

# Using with Lua

To use `code_lib` in Lua, only Lua is required.
Simply call `require("code_lib")` to expose `Word` and `Code`.

Things to note:
- To `require("code_lib")`, the `code_lib.lua` file needs to be in the same directory as where
you are working:
    - `/use/home/You/code_lib.lua` needs to exist
    if you're writing a Lua file at `/usr/home/You/test.lua`.
    - `/use/home/You/code_lib.lua` needs to exist
    if you're in a Lua REPL and working at `/usr/home/You/`.

## Examples

```lua
require("code_lib")

-- Note that the Code class can be used for any collection of block code words
local S = Code:parse("0011010,1010110,0000011,1010101")

print(C)        -- [0011010,1010110,0000011,1010101]
print(C:ref())  -- [1010110,0011010,0000011,0000000]
print(C:rref()) -- [1001100,0011001,0000011,0000000]
```


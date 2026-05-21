---@module 'luassert'

local Util = require("ajans.util")

describe("split_words", function()
  -- should split a string in alpha / non-alpha parts
  local cases = {
    { "abcd", { "abcd" } },
    { "abcd ", { "abcd", " " } },
    { " ", { " " } },
    { "abcd.", { "abcd", "." } },
    { "abcd.?", { "abcd", ".", "?" } },
    { "abc123", { "abc123" } },
    { "123abc", { "123abc" } },
    { "abc 123", { "abc", " ", "123" } },
    { "abc\t123", { "abc", "\t", "123" } },
    { "abc\n123", { "abc", "\n", "123" } },
    { "abc.def", { "abc", ".", "def" } },
    { "abc.def.ghi", { "abc", ".", "def", ".", "ghi" } },
    { "abc_def", { "abc_def" } },
    { "abc-def", { "abc", "-", "def" } },
    { "abc+def", { "abc", "+", "def" } },
    { "abc*def", { "abc", "*", "def" } },
    { "abc/def", { "abc", "/", "def" } },
    { "abc=def", { "abc", "=", "def" } },
    { "café", { "café" } },
    { "😀", { "😀" } },
    { "foo😀bar", { "foo", "😀", "bar" } },
    { "ありがとう", { "あ", "り", "が", "と", "う" } },
    {
      'local diff = require("ajans.nes.diff").diff(edit)',
      {
        "local",
        " ",
        "diff",
        " ",
        "=",
        " ",
        "require",
        "(",
        '"',
        "ajans",
        ".",
        "nes",
        ".",
        "diff",
        '"',
        ")",
        ".",
        "diff",
        "(",
        "edit",
        ")",
      },
    },
  }

  for _, case in ipairs(cases) do
    it(case[1] .. " => " .. vim.inspect(case[2]), function()
      -- vim.o.iskeyword = "@,48-57,_,192-255"
      assert.are.same(case[2], Util.split_words(case[1]))
    end)
  end
end)

describe("split_chars", function()
  -- ensure split_chars breaks strings into individual characters
  local cases = {
    { "abc", { "a", "b", "c" } },
    { "abc def", { "a", "b", "c", " ", "d", "e", "f" } },
    { "abc\tdef", { "a", "b", "c", "\t", "d", "e", "f" } },
    { "abc\ndef", { "a", "b", "c", "\n", "d", "e", "f" } },
    { "0.1", { "0", ".", "1" } },
    { "😀", { "😀" } },
    { "😀😃", { "😀", "😃" } },
    { "👍🏼", { "👍", "🏼" } },
    { "café", { "c", "a", "f", "é" } },
    { "ありがとう", { "あ", "り", "が", "と", "う" } },
  }

  for _, case in ipairs(cases) do
    it(case[1] .. " => " .. vim.inspect(case[2]), function()
      assert.are.same(case[2], Util.split_chars(case[1]))
    end)
  end
end)

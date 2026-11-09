-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+Left/Right and Alt(Option)+Left/Right jump between words separated by
-- whitespace, like in a shell or most text editors.
-- (LazyVim used Ctrl+Left/Right for window resizing; drag the split border with the mouse instead.)
local map = vim.keymap.set
for _, mod in ipairs({ "C", "M" }) do
  -- normal, visual, operator-pending: B / W move to the start of the previous / next word
  map({ "n", "x", "o" }, "<" .. mod .. "-Left>", "B", { desc = "Previous word (whitespace)" })
  map({ "n", "x", "o" }, "<" .. mod .. "-Right>", "W", { desc = "Next word (whitespace)" })
  -- insert mode: run B / W without leaving insert mode (the built-in jump also stops at punctuation)
  map("i", "<" .. mod .. "-Left>", "<C-o>B", { desc = "Previous word (whitespace)" })
  map("i", "<" .. mod .. "-Right>", "<C-o>W", { desc = "Next word (whitespace)" })
  -- ":" command line: the built-in jump is already whitespace-based
  map("c", "<" .. mod .. "-Left>", "<C-Left>", { desc = "Previous word (whitespace)" })
  map("c", "<" .. mod .. "-Right>", "<C-Right>", { desc = "Next word (whitespace)" })
end

-- Remove LazyVim's Ctrl+Up/Down window resizing too, so no Ctrl+arrow changes window sizes.
pcall(vim.keymap.del, "n", "<C-Up>")
pcall(vim.keymap.del, "n", "<C-Down>")

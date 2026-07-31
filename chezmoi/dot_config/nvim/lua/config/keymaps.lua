local map = vim.keymap.set

-- Leave insert mode without reaching for Escape.
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Add future custom mappings below.

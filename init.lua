local M = {}

-- State
M.config = {}

-- Command setup
function M.setup()
  vim.api.nvim_create_user_command("NvimGym", function()
    M.open_menu()
  end, {})
end

-- Main Menu
function M.open_menu()
  local lines = {
    "🏋️  Nvim Gym - Muscle Memory Trainer 🏋️",
    "",
    "Choose a Training Module:",
    "",
    "1. Module 1: The Basics (Standard Vim) [hjkl, w/b, i/a]",
    "2. Module 2: Custom Config (Your Keymaps) [C-nav, Buffers]",
    "3. Module 3: Pro Skills (LSP & Advanced) [gd, gr, ca]",
    "",
    "Press [1-3] to start, or q to quit."
  }

  -- Create a floating window for the menu
  local buf = vim.api.nvim_create_buf(false, true)
  local width = 60
  local height = #lines + 4
  local ui = vim.api.nvim_list_uis()[1]
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (ui.width - width) / 2,
    row = (ui.height - height) / 2,
    style = "minimal",
    border = "rounded"
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  
  -- Set content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Keymaps for the menu
  local start_module = function(mod_num)
    vim.api.nvim_win_close(win, true)
    if mod_num == 1 then require("nvim-gym.basic_game").start()
    elseif mod_num == 2 then require("nvim-gym.custom_game").start()
    elseif mod_num == 3 then require("nvim-gym.lsp_game").start()
    end
  end

  vim.keymap.set("n", "1", function() start_module(1) end, { buffer = buf })
  vim.keymap.set("n", "2", function() start_module(2) end, { buffer = buf })
  vim.keymap.set("n", "3", function() start_module(3) end, { buffer = buf })
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
  vim.keymap.set("n", "<Esc>", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
  
  -- Lock the buffer
  vim.opt_local.modifiable = false
  vim.opt_local.buftype = "nofile"
  vim.opt_local.cursorline = true
end

return M

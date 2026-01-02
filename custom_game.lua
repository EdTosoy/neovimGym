local M = {}

function M.start()
  local lines = {
    "Module 2: Custom Config (Your Setup)",
    "",
    "1. Window Hopper (<C-h>, <C-j>, <C-k>, <C-l>)",
    "2. Window Shaper (<C-Arrows>)",
    "3. Buffer Surfer (<S-h>, <S-l>)",
    "4. The Mover (Visual Mode J, K)",
    "",
    "Select a level [1-4] or q to quit."
  }
  
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
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local start_level = function(level)
    vim.api.nvim_win_close(win, true)
    if level == 1 then M.level_window_hopper()
    elseif level == 2 then M.level_window_shaper()
    elseif level == 3 then M.level_buffer_surfer()
    elseif level == 4 then M.level_mover()
    end
  end

  vim.keymap.set("n", "1", function() start_level(1) end, { buffer = buf })
  vim.keymap.set("n", "2", function() start_level(2) end, { buffer = buf })
  vim.keymap.set("n", "3", function() start_level(3) end, { buffer = buf })
  vim.keymap.set("n", "4", function() start_level(4) end, { buffer = buf })
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
  
  vim.opt_local.modifiable = false
  vim.opt_local.buftype = "nofile"
end

-- Level 1: Window Hopper
function M.level_window_hopper()
  -- Close other windows first
  vim.cmd("only")
  
  -- Create 3x3 grid
  vim.cmd("split")
  vim.cmd("split")
  vim.cmd("vsplit")
  vim.cmd("wincmd j")
  vim.cmd("vsplit")
  vim.cmd("wincmd j")
  vim.cmd("vsplit") -- Rough grid

  -- Pick a target window
  local wins = vim.api.nvim_list_wins()
  local target_win = wins[math.random(#wins)]
  
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    if win == target_win then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"", "   GO HERE!   ", "   (Use C-h/j/k/l)   "})
      -- Win condition
      vim.api.nvim_create_autocmd("WinEnter", {
        callback = function()
          if vim.api.nvim_get_current_win() == target_win then
            print("🎉 Nice moves! Press q to quit.")
            vim.cmd("only") -- Clean up
            return true -- Delete autocmd
          end
        end
      })
    else
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"", "   .   "})
    end
  end
  print("Use <C-h/j/k/l> to jump to the target!")
end

-- Level 2: Window Shaper
function M.level_window_shaper()
  vim.cmd("only")
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "Resize this window using:",
    "Ctrl + Arrow Keys",
    "",
    "Make it WIDER!"
  })
  print("Use Ctrl+Arrows to resize. (Press q to quit)")
  vim.keymap.set("n", "q", ":only<CR>", { buffer = buf })
end

-- Level 3: Buffer Surfer
function M.level_buffer_surfer()
  -- Create 10 buffers
  for i = 1, 10 do
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, "Buffer_" .. i)
    if i == 7 then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"THIS IS THE WINNER!", "You found it.", "Press q to quit."})
    else
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"Not this one...", "Use Shift+l (next) or Shift+h (prev)"})
    end
    vim.keymap.set("n", "q", ":%bd|bd#<CR>", { buffer = buf }) -- Close all
  end
  vim.cmd("b 1")
  print("Use <S-l> and <S-h> to surf buffers. Find Buffer 7!")
end

-- Level 4: The Mover
function M.level_mover()
  local lines = {
    "1. Step One",
    "3. Step Three (WRONG PLACE)",
    "2. Step Two",
    "4. Step Four"
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  print("Use Visual Mode (v) then J or K to reorder the list correctly.")
  vim.keymap.set("n", "q", ":bd!<CR>", { buffer = buf })
end

return M

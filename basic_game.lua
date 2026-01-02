local M = {}

function M.start()
  local lines = {
    "Module 1: The Basics",
    "",
    "1. The Crawler (h, j, k, l)",
    "2. The Sprinter (w, b, 0, $, gg, G)",
    "3. The Editor (i, a, x, dd)",
    "4. The Surgeon (cw, ci\", yy, p)",
    "",
    "Select a level [1-4] or q to quit."
  }
  
  -- Re-use menu logic (simplified for now)
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
    if level == 1 then M.level_crawler()
    elseif level == 2 then M.level_sprinter()
    elseif level == 3 then M.level_editor()
    elseif level == 4 then M.level_surgeon()
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

-- Level 1: The Crawler
function M.level_crawler()
  local start_time = os.time()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  
  local maze = {
    "START HERE -> ####################",
    "              #                  #",
    "              #  ########  ####  #",
    "              #  #      #  #  #  #",
    "              #  #  ##  #  #  #  #",
    "              #  #  #   #     #  #",
    "              #  ####   #######  #",
    "              #                  #",
    "              #################### -> GOAL (Place cursor on X)",
    "                                      X"
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, maze)
  vim.api.nvim_win_set_cursor(0, {1, 0})
  
  print("Use h, j, k, l to move. Reach the X! Timer started...")
  
  -- Disable arrow keys to force hjkl
  local opts = { buffer = buf }
  vim.keymap.set("n", "<Up>", "<nop>", opts)
  vim.keymap.set("n", "<Down>", "<nop>", opts)
  vim.keymap.set("n", "<Left>", "<nop>", opts)
  vim.keymap.set("n", "<Right>", "<nop>", opts)

  -- Check position
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local row, col = cursor[1], cursor[2]
      -- Goal is at last line, last char
      if row == #maze and col >= #maze[#maze]-1 then
        local elapsed = os.time() - start_time
        print("🎉 VICTORY! Time: " .. elapsed .. "s. Press q to quit.")
        vim.keymap.set("n", "q", ":bd!<CR>", { buffer = buf })
        return true -- delete autocmd
      end
    end
  })
end

-- Level 2: The Sprinter (Placeholder for now)
function M.level_sprinter()
  M.level_template("Use w, b, $, 0 to jump around words.", {
    "word1 word2 word3 word4 word5",
    "Jump to the end of the line ($)",
    "Jump to the start of the line (0)",
    "word word word word word word",
  })
end

-- Level 3: The Editor
function M.level_editor()
  M.level_template("Fix the typos. delete (x), insert (i), delete line (dd)", {
    "Thhis line haas extra letters. (Use x)",
    "This line is missing lettrs. (Use i)",
    "DELETE THIS JAR JAR BINKS LINE (Use dd)",
    "Perfect line."
  })
end

-- Level 4: The Surgeon
function M.level_surgeon()
  M.level_template("Advanced Editing. Change Inner Quotes (ci\")", {
    "local name = \"change_me_please\"",
    "local config = \"wrong_value\"",
    "Change the values inside the quotes using ci\""
  })
end

function M.level_template(instructions, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  print(instructions .. " (Press q to quit)")
  vim.keymap.set("n", "q", ":bd!<CR>", { buffer = buf })
end

return M

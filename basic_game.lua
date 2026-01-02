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

-- Level 1: The Crawler (Arcade Mode)
function M.level_crawler()
  local score = 0
  local time_limit = 30
  local start_time = os.time()
  local running = true

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  
  -- Create a large arena
  local lines = {}
  for i=1, 20 do table.insert(lines, string.rep(" ", 60)) end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Helper to spawn target
  local function spawn_target()
    -- Clear old target (redraw board)
    for i=1, 20 do lines[i] = string.rep(" ", 60) end
    
    -- Random pos (lines 1-20, cols 0-59)
    local r = math.random(1, 20)
    local c = math.random(0, 59)
    
    -- Inject X
    lines[r] = string.sub(lines[r], 1, c) .. "X" .. string.sub(lines[r], c+2)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    return r, c
  end

  local target_r, target_c = spawn_target()
  vim.api.nvim_win_set_cursor(0, {10, 30}) -- Start in middle

  print("Crawler Arcade: Use hjkl to hit 'X'. You have " .. time_limit .. "s! GO!")

  -- Game Loop / Input Check
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      if not running then return true end
      
      -- Check timer
      local elapsed = os.time() - start_time
      local remaining = time_limit - elapsed
      
      if remaining <= 0 then
        running = false
        print("⏰ TIME'S UP! Final Score: " .. score .. " hits.")
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "GAME OVER",
          "Score: " .. score,
          "Press q to quit"
        })
        vim.keymap.set("n", "q", ":bd!<CR>", { buffer = buf })
        return true
      end

      -- Check collision
      local cursor = vim.api.nvim_win_get_cursor(0)
      local r, c = cursor[1], cursor[2]
      
      if r == target_r and c == target_c then
        score = score + 1
        target_r, target_c = spawn_target()
        print("Score: " .. score .. " | Time: " .. remaining .. "s")
      end
    end
  })
  
  -- Disable cheats
  local opts = { buffer = buf }
  for _, key in ipairs({"<Up>", "<Down>", "<Left>", "<Right>"}) do
    vim.keymap.set("n", key, "<nop>", opts)
  end
  vim.keymap.set("n", "q", ":bd!<CR>", { buffer = buf })
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

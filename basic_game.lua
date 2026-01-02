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

local function show_game_over(buf, score, restart_cb, next_cb)
  local lines = {
    "   🎉 GAME OVER! 🎉",
    "",
    "   Final Score: " .. score,
    "",
    "   [r] Restart Level",
    "   [n] Next Level",
    "   [m] Main Menu",
    "   [q] Quit"
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.opt_local.modifiable = false
  
  local opts = { buffer = buf }
  vim.keymap.set("n", "r", function() 
    vim.cmd("bd!")
    restart_cb() 
  end, opts)
  
  vim.keymap.set("n", "n", function() 
    vim.cmd("bd!")
    if next_cb then next_cb() else print("No next level!") end
  end, opts)
  
  vim.keymap.set("n", "m", function()
    vim.cmd("bd!")
    require("nvim-gym").open_menu()
  end, opts)
  
  vim.keymap.set("n", "q", ":bd!<CR>", opts)
end

-- Level 1: The Crawler (Gamified Arcade)
function M.level_crawler()
  -- Game State
  local score = 0
  local combo = 1
  local combo_timer = 0
  local time_limit = 30
  local start_time = os.time()
  local running = true
  
  -- Visual Assets
  local targets = {"👾", "👻", "👹", "🤖", "👽"}
  local colors = {"#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff"}
  
  -- Setup Highlights
  vim.api.nvim_set_hl(0, "GymTarget", { fg = "#ff007c", bold = true })
  vim.api.nvim_set_hl(0, "GymHud", { fg = "#00ff00", bold = true })
  
  -- Create Board
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  local width = 60
  local height = 20
  local lines = {}
  for i=1, height do table.insert(lines, string.rep(" ", width)) end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Create HUD Window
  local hud_buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]
  local hud_win = vim.api.nvim_open_win(hud_buf, false, {
    relative = "editor",
    width = 20,
    height = 3,
    col = ui.width - 22,
    row = 1,
    style = "minimal",
    border = "rounded"
  })

  local function update_hud(remaining)
    if not vim.api.nvim_buf_is_valid(hud_buf) then return end
    vim.api.nvim_buf_set_lines(hud_buf, 0, -1, false, {
      "SCORE: " .. score,
      "COMBO: x" .. combo .. (combo > 1 and " 🔥" or ""),
      "TIME : " .. remaining .. "s"
    })
  end

  -- Target Logic
  local target_r, target_c
  local target_char = ""
  
  local function spawn_target()
    -- Clear board
    for i=1, height do lines[i] = string.rep(" ", width) end
    
    -- Pick randoms
    target_r = math.random(1, height)
    target_c = math.random(0, width - 2)
    target_char = targets[math.random(#targets)]
    
    -- Inject Target
    -- Note: Emojis can take multiple bytes, simplified for now
    lines[target_r] = string.sub(lines[target_r], 1, target_c) .. target_char .. string.sub(lines[target_r], target_c+2)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Add Highlight (using matchaddpos for simplicity)
    vim.fn.clearmatches()
    vim.fn.matchaddpos("GymTarget", {{target_r, target_c+1}})
  end

  spawn_target()
  vim.api.nvim_win_set_cursor(0, {height/2, width/2}) 
  
  print("START! Chase the monsters! (Use hjkl)")

  -- Game Loop
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      if not running then return true end
      
      -- Time Logic
      local elapsed = os.time() - start_time
      local remaining = time_limit - elapsed
      
      if remaining <= 0 then
        running = false
        vim.api.nvim_win_close(hud_win, true)
        running = false
        vim.api.nvim_win_close(hud_win, true)
        print("🎉 GAME OVER! Final Score: " .. score)
        show_game_over(buf, score, M.level_crawler, M.level_sprinter)
        return true
      end
      
      -- Combo Decay (reset if > 2s since last hit)
      if os.time() - combo_timer > 2 and combo > 1 then
        combo = 1
      end
      
      -- Collision Logic
      local cursor = vim.api.nvim_win_get_cursor(0)
      local r, c = cursor[1], cursor[2]
      
      -- Loosen collision detection for emojis (they can involve next col)
      if r == target_r and (c == target_c or c == target_c + 1) then
        score = score + (10 * combo)
        combo = combo + 1
        combo_timer = os.time()
        spawn_target()
      end
      
      update_hud(remaining)
    end
  })
  
  -- Controls
  local opts = { buffer = buf }
  for _, key in ipairs({"<Up>", "<Down>", "<Left>", "<Right>"}) do
    vim.keymap.set("n", key, "<nop>", opts)
  end
  vim.keymap.set("n", "q", function() 
    running = false
    vim.api.nvim_win_close(hud_win, true)
    vim.cmd("bd!") 
    require("nvim-gym").open_menu() -- Return to menu logic
  end, opts)
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

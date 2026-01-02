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

-- Level 2: The Sprinter
function M.level_sprinter()
  local score = 0
  local time_limit = 30
  local start_time = os.time()
  local running = true
  
  -- Word bank
  local words = {"neovim", "motion", "buffer", "window", "lua", "plugin", "macro", "visual", "yank", "paste", "delete", "change", "insert", "append", "line", "column", "quickfix"}
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  
  -- Create HUD (reuse logic? simpler to inline for now)
  local hud_buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]
  local hud_win = vim.api.nvim_open_win(hud_buf, false, {
    relative = "editor", width = 20, height = 3, col = ui.width - 22, row = 1, style = "minimal", border = "rounded"
  })
  
  local function update_hud(remaining)
    if not vim.api.nvim_buf_is_valid(hud_buf) then return end
    vim.api.nvim_buf_set_lines(hud_buf, 0, -1, false, {"SCORE: " .. score, "TIME : " .. remaining .. "s", ""})
  end

  -- Highlight setup
  vim.api.nvim_set_hl(0, "GymTargetWord", { fg = "#00ffff", bold = true, underline = true })

  local sentences = {}
  local target_word = ""
  local target_pos = {1, 0} -- row, col
  
  local function generate_level()
    sentences = {}
    for i=1, 15 do
      local line = ""
      for j=1, 8 do line = line .. words[math.random(#words)] .. " " end
      table.insert(sentences, line)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, sentences)
    
    -- Pick target
    local r = math.random(1, 15)
    local line_text = sentences[r]
    -- Find a word start
    local attempts = 0
    while attempts < 50 do
        local w_idx = math.random(1, #words) -- Random word index from bank IS NOT enough, we need position in line
        -- Simplified: Pick a random space and next word
        local space_indices = {}
        local current_pos = 0
        while true do
            local found = string.find(line_text, " ", current_pos + 1)
            if not found then break end
            table.insert(space_indices, found)
            current_pos = found
        end
        
        if #space_indices > 0 then
           local rnd_space = space_indices[math.random(#space_indices)]
           target_pos = {r, rnd_space} -- Actually char after space is better, but simplified
           -- Let's just highlight a range
           vim.fn.clearmatches()
           vim.fn.matchaddpos("GymTargetWord", {{r, rnd_space + 1, 5}}) -- Highlight 5 chars
           break
        end
        attempts = attempts + 1
    end
  end
  
  generate_level()
  print("Jump to the BLUE words using w, b, f, t!")

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      if not running then return true end
      local elapsed = os.time() - start_time
      local remaining = time_limit - elapsed
      
      if remaining <= 0 then
        running = false
        vim.api.nvim_win_close(hud_win, true)
        show_game_over(buf, score, M.level_sprinter, M.level_editor)
        return true
      end
      
      local cursor = vim.api.nvim_win_get_cursor(0)
      -- Simple collision: if cursor line is correct and within range of highlight
      if cursor[1] == target_pos[1] and math.abs(cursor[2] - target_pos[2]) < 5 then
        score = score + 1
        generate_level()
      end
      
      update_hud(remaining)
    end
  })
  
  vim.keymap.set("n", "q", function() running = false; vim.cmd("bd!"); require("nvim-gym").open_menu() end, { buffer = buf })
end

-- Level 3: The Editor
function M.level_editor()
  local score = 0
  local time_limit = 45
  local start_time = os.time()
  local running = true
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  
  local hud_buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]
  local hud_win = vim.api.nvim_open_win(hud_buf, false, {
    relative = "editor", width = 20, height = 3, col = ui.width - 22, row = 1, style = "minimal", border = "rounded"
  })
  local function update_hud(remaining)
     if vim.api.nvim_buf_is_valid(hud_buf) then
        vim.api.nvim_buf_set_lines(hud_buf, 0, -1, false, {"SCORE: " .. score, "TIME : " .. remaining .. "s", ""})
     end
  end

  local function generate_lines()
      local t = math.random(1, 3)
      if t == 1 then
         return {"Fix thhis.", "Fix this.", "Use x"}
      elseif t == 2 then
         return {"BAD LINE", "", "Use dd"}
      else
         return {"Open .", "Open sesame.", "Use a/i to add 'sesame'"}
      end
  end
  local current_target = ""
  
  local function spawn()
     local data = generate_lines()
     local text = data[1]
     current_target = data[2]
     local hint = data[3]
     
     vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Hint: " .. hint,
        "",
        text, 
     })
  end
  spawn()

  vim.api.nvim_create_autocmd({"TextChanged", "CursorMoved"}, {
    buffer = buf,
    callback = function()
       if not running then return true end
       local elapsed = os.time() - start_time
       local remaining = time_limit - elapsed
       
       if remaining <= 0 then
         running = false
         vim.api.nvim_win_close(hud_win, true)
         show_game_over(buf, score, M.level_editor, M.level_surgeon)
         return true
       end
       
       update_hud(remaining)
       
       local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
       if current_target == "" then 
          if #lines < 3 or lines[3] == nil or lines[3] == "" then
             score = score + 1
             spawn()
          end
       else 
          if #lines >= 3 and lines[3] == current_target then
             score = score + 1
             spawn()
          end
       end
    end
  })
  
  vim.keymap.set("n", "q", function() running = false; vim.cmd("bd!"); require("nvim-gym").open_menu() end, { buffer = buf })
end

-- Level 4: The Surgeon
function M.level_surgeon()
  local score = 0
  local time_limit = 60
  local start_time = os.time()
  local running = true
  
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  
  -- HUD logic
  local hud_buf = vim.api.nvim_create_buf(false, true)
  local ui = vim.api.nvim_list_uis()[1]
  local hud_win = vim.api.nvim_open_win(hud_buf, false, {
    relative = "editor", width = 20, height = 3, col = ui.width - 22, row = 1, style = "minimal", border = "rounded"
  })
  local function update_hud(remaining)
     if vim.api.nvim_buf_is_valid(hud_buf) then
        vim.api.nvim_buf_set_lines(hud_buf, 0, -1, false, {"SCORE: " .. score, "TIME : " .. remaining .. "s", ""})
     end
  end

  local bank = {
    { q = 'local name = "bad_name"', a = 'local name = "good_name"', hint = "Change inside quotes to 'good_name'" },
    { q = 'print("wrong_msg")', a = 'print("hello_world")', hint = "Change to 'hello_world'" },
    { q = 'return "fail"', a = 'return "success"', hint = "Change to 'success'" }
  }
  
  local current_target = ""
  
  local function spawn()
     local task = bank[math.random(#bank)]
     current_target = task.a
     
     vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Instructions: " .. task.hint,
        "",
        task.q, 
     })
  end
  spawn()

  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    buffer = buf,
    callback = function()
       if not running then return true end
       local elapsed = os.time() - start_time
       local remaining = time_limit - elapsed
       
       if remaining <= 0 then
         running = false
         vim.api.nvim_win_close(hud_win, true)
         show_game_over(buf, score, M.level_surgeon, nil)
         return true
       end
       
       update_hud(remaining)
       
       local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
       if #lines >= 3 and lines[3] == current_target then
          score = score + 1
          spawn()
       end
    end
  })
  
  -- Simple controls update
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
       if running then 
          local elapsed = os.time() - start_time
          update_hud(time_limit - elapsed)
       end
    end
  })

  vim.keymap.set("n", "q", function() running = false; vim.cmd("bd!"); require("nvim-gym").open_menu() end, { buffer = buf })
end

function M.level_template(instructions, lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  print(instructions .. " (Press q to quit)")
  vim.keymap.set("n", "q", ":bd!<CR>", { buffer = buf })
end

return M

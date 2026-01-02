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

-- Level 1: Window Hopper (Arcade Mode)
function M.level_window_hopper()
  local score = 0
  local time_limit = 45 -- Slightly longer for window jumps
  local start_time = os.time()
  local running = true
  
  -- Close other windows first
  vim.cmd("only")
  
  -- Create 3x3 grid
  vim.cmd("split")
  vim.cmd("split")
  vim.cmd("vsplit")
  vim.cmd("wincmd j")
  vim.cmd("vsplit")
  vim.cmd("wincmd j")
  vim.cmd("vsplit") 
  
  -- Setup buffers for all windows
  local wins = vim.api.nvim_list_wins()
  local bufs = {}
  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, buf)
    bufs[win] = buf
  end

  local function pick_new_target()
    local current = vim.api.nvim_get_current_win()
    local candidates = {}
    for _, w in ipairs(wins) do
      if w ~= current then table.insert(candidates, w) end
    end
    print(#candidates)
    return candidates[math.random(#candidates)]
  end
  
  local target_win = pick_new_target()
  
  local function update_ui(remaining)
    for _, win in ipairs(wins) do
      local buf = bufs[win]
      if win == target_win then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "   🎯 TARGET 🎯",
          "   (Jump Here!)",
          "",
          "Score: " .. score,
          "Time: " .. remaining .. "s"
        })
        -- Highlight it? maybe later
      else
         vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
           "   .",
           "",
           "",
           "Score: " .. score
         })
      end
    end
  end
  
  update_ui(time_limit)
  print("Use <C-h/j/k/l> to catch the target window!")

  -- Game Loop
  vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
      if not running then return true end
      
      local elapsed = os.time() - start_time
      local remaining = time_limit - elapsed
      
      if remaining <= 0 then
        running = false
        print("⏰ TIME'S UP! Final Score: " .. score)
        vim.cmd("only") -- Reset layout
        
        -- Create a clean result buffer
        local res_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(res_buf)
        show_game_over(res_buf, score, M.level_window_hopper, M.level_window_shaper)
        return true
      end
      
      if vim.api.nvim_get_current_win() == target_win then
        score = score + 1
        target_win = pick_new_target()
        update_ui(remaining)
        print("Nice! Score: " .. score)
      end
      
      update_ui(remaining)
    end
  })
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
    "Make it WIDER!",
    "",
    "When done, press:",
    "[n] Next Level (Buffer Surfer)",
    "[q] Quit"
  })
  print("Use Ctrl+Arrows to resize.")
  local opts = { buffer = buf }
  vim.keymap.set("n", "q", function() vim.cmd("only"); require("nvim-gym").open_menu() end, opts)
  vim.keymap.set("n", "n", function() 
    vim.cmd("only")
    M.level_buffer_surfer()
  end, opts)
end

-- Level 3: Buffer Surfer
function M.level_buffer_surfer()
  local score = 0
  local time_limit = 45
  local start_time = os.time()
  local running = true
  
  -- Create HUD
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

  local buffers = {}
  local labels = {"Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel"}
  
  -- Create buffers
  for i, label in ipairs(labels) do
     local b = vim.api.nvim_create_buf(false, true)
     vim.api.nvim_buf_set_name(b, "Gym_" .. label)
     vim.api.nvim_buf_set_lines(b, 0, -1, false, {
        "   BUFFER: " .. label,
        "",
        "   Use Shift+L (next) / Shift+H (prev)",
        "   Find the Target!" 
     })
     table.insert(buffers, b)
     -- Bind quit
     vim.keymap.set("n", "q", function() 
        running = false
        vim.cmd("bd!")
        -- Cleanup all
        for _, bf in ipairs(buffers) do 
           if vim.api.nvim_buf_is_valid(bf) then vim.api.nvim_buf_delete(bf, {force=true}) end
        end
        require("nvim-gym").open_menu()
     end, { buffer = b })
  end
  
  -- Set all buffers to be listed? 
  -- nvim_create_buf(listed, scratch) -> true, true?
  -- Actually, `vim.api.nvim_create_buf(true, false)` creates a listed buffer.
  -- My create_buf(false, true) creates unlisted scratch... might not work with bnext/bprev depending on config.
  -- Let's try to set them listed.
  for _, b in ipairs(buffers) do
     vim.bo[b].buflisted = true
  end
  
  -- Start at 1
  vim.api.nvim_set_current_buf(buffers[1])
  
  local target_buf = buffers[math.random(#buffers)]
  local target_name = labels[1] -- placeholder
  
  local function pick_target()
     local idx = math.random(#buffers)
     target_buf = buffers[idx]
     target_name = labels[idx]
     print("GO TO BUFFER: " .. target_name)
  end
  pick_target()
  
  vim.api.nvim_create_autocmd("BufEnter", {
     callback = function()
        if not running then return true end
        local elapsed = os.time() - start_time
        local remaining = time_limit - elapsed
        
        if remaining <= 0 then
           running = false
           vim.api.nvim_win_close(hud_win, true)
           -- Cleanup buffers
           for _, bf in ipairs(buffers) do 
              if vim.api.nvim_buf_is_valid(bf) then vim.api.nvim_buf_delete(bf, {force=true}) end
           end
           
           -- Show Game Over
           local res_buf = vim.api.nvim_create_buf(false, true)
           vim.api.nvim_set_current_buf(res_buf)
           show_game_over(res_buf, score, M.level_buffer_surfer, M.level_mover)
           return true
        end
        
        update_hud(remaining)
        
        if vim.api.nvim_get_current_buf() == target_buf then
           score = score + 1
           -- Show success msg?
           pick_target()
           -- Force redraw of message on current buffer?
           print("FOUND IT! Next: " .. target_name)
        end
     end
  })
end

-- Level 4: The Mover
function M.level_mover()
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

  local function spawn()
     local correct = {"1. Step One", "2. Step Two", "3. Step Three", "4. Step Four", "5. Step Five"}
     -- Shuffle
     local shuffled = {unpack(correct)}
     for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
     end
     
     vim.api.nvim_buf_set_lines(buf, 0, -1, false, shuffled)
     print("Sort lines 1-5 using Visual Mode + J/K!")
  end
  spawn()
  
  local correct_str = "1. Step One2. Step Two3. Step Three4. Step Four5. Step Five"

  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    buffer = buf,
    callback = function()
       if not running then return true end
       local elapsed = os.time() - start_time
       local remaining = time_limit - elapsed
       
       if remaining <= 0 then
         running = false
         vim.api.nvim_win_close(hud_win, true)
         show_game_over(buf, score, M.level_mover, nil)
         return true
       end
       
       update_hud(remaining)
       
       local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
       local combined = table.concat(lines, "")
       if combined == correct_str then
          score = score + 1
          spawn()
          print("Perfect! Next round...")
       end
    end
  })
  
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
       if running then update_hud(time_limit - (os.time() - start_time)) end
    end
  })

  vim.keymap.set("n", "q", function() running = false; vim.cmd("bd!"); require("nvim-gym").open_menu() end, { buffer = buf })
end

return M

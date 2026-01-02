local M = {}

function M.start()
  local lines = {
    "Module 3: Pro Skills (LSP & Mock)",
    "",
    "1. The Navigator (gd, gr, K)",
    "2. The Refactorer (ca, rn)",
    "",
    "Select a level [1-2] or q to quit."
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
    if level == 1 then M.level_navigator()
    elseif level == 2 then M.level_refactorer()
    end
  end

  vim.keymap.set("n", "1", function() start_level(1) end, { buffer = buf })
  vim.keymap.set("n", "2", function() start_level(2) end, { buffer = buf })
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
  
  vim.opt_local.modifiable = false
  vim.opt_local.buftype = "nofile"
end

-- Level 1: The Navigator
function M.level_navigator()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  
  local code = {
    "// Use gd (Definition) to jump to the function",
    "// Use K (Hover) to see docs",
    "",
    "func main() {",
    "  utils.DoSomething() <--- Cursor here, press gd",
    "}",
    "",
    "",
    "// .... (lots of lines) ....",
    "",
    "",
    "func DoSomething() {",
    "  print('Hello')",
    "}"
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, code)
  
  -- Mock gd mapping for this game
  local opts = { buffer = buf }
  vim.keymap.set("n", "gd", function()
     -- Jump to line 12
     vim.api.nvim_win_set_cursor(0, {12, 0})
     print("✅ Correct! You jumped to the definition.")
  end, opts)
  
  vim.keymap.set("n", "K", function()
     print("ℹ️  Documentation: This function does something cool.")
  end, opts)
  
  vim.keymap.set("n", "q", ":bd!<CR>", opts)
  print("Use 'gd' on 'DoSomething' to jump to its definition. (q to quit)")
end

-- Level 2: The Refactorer
function M.level_refactorer()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  
  local code = {
    "local messy_var_name = 10",
    "print(messy_var_name)",
    "",
    "Use <leader>rn to rename 'messy_var_name' to 'clean'",
    "Use <leader>ca to open code actions"
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, code)
  
  local opts = { buffer = buf }
  
  -- Mock Rename
  vim.keymap.set("n", "<leader>rn", function()
    vim.ui.input({ prompt = "New Name: " }, function(input)
      if input then
        -- Simple replace in buffer
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        for i, line in ipairs(lines) do
          lines[i] = string.gsub(line, "messy_var_name", input)
        end
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        print("✅ Renamed!")
      end
    end)
  end, opts)

  -- Mock Code Action
  vim.keymap.set("n", "<leader>ca", function()
    vim.ui.select({"1. Fix Imports", "2. Extract Function"}, { prompt = "Code Actions" }, function(choice)
      if choice then print("Action Applied: " .. choice) end
    end)
  end, opts)
  
  vim.keymap.set("n", "q", ":bd!<CR>", opts)
  print("Use <leader>rn to rename. (q to quit)")
end

return M

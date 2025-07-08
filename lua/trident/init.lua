local manager = require("trident.manager")
local pikes_manager = require("trident.pike_manager")
local pikes_ui = require("trident.pike_ui")

local M = {
  _opts = {
    cycle = false,
    height = 0.4,
    shorten_paths = true,
    silent = false,

    pikes_keybinds = {
      create_prefix = "tm",
      delete_prefix = "td",
      jump_prefix = ";",
      -- list = "tp",
      -- toggle_view = "tM",
    },

    win = {
      -- buf or float
      win_type = "buf",

      -- for the buf wintype
      buf_split = "belowright",

      float = {
        width = 0.6,
        height = 0.4,
        border = "single",
        title = "[♆ TRIDENT ♆]",
        transparent = false,
      },
    },
  },
}

local notify = vim.notify
function M.notify(msg, level)
  if not M._opts.silent then
    notify(msg, level)
  end
end

function M.setup(opts)
  M._opts = vim.tbl_extend("force", M._opts, opts or {})
end

M.add = function(filepath)
  if filepath == nil or filepath == "" then
    filepath = vim.api.nvim_buf_get_name(0)
  end
  manager.add_file(filepath)
end

M.remove = function(filepath)
  if filepath == nil or filepath == "" then
    filepath = vim.api.nvim_buf_get_name(0)
  end
  manager.remove_file(filepath)
end

M.get_all = function()
  return manager.get_marks()
end

M.get_project_marks = function()
  return M.get_all()
end

M.purge = function()
  manager.purge_project()
end

M.move = function(from, to)
  require("trident.manager").move(from, to)
end

M.ui = require("trident.ui")

M.list = function()
  M.ui.open_picker()
end

function M.next()
  local marks = manager.get_marks()
  if #marks == 0 then
    return
  end

  local current = vim.api.nvim_buf_get_name(0)
  local idx
  for i, f in ipairs(marks) do
    if f == current then
      idx = i
      break
    end
  end

  if not idx then
    vim.cmd("edit " .. vim.fn.fnameescape(marks[1]))
    return
  end

  local next_idx = idx + 1
  if next_idx > #marks then
    if M._opts.cycle then
      next_idx = 1
    else
      require("trident").notify("No next file", vim.log.levels.INFO)
      return
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(marks[next_idx]))
end

function M.prev()
  local marks = manager.get_marks()
  if #marks == 0 then
    return
  end

  local current = vim.api.nvim_buf_get_name(0)
  local idx
  for i, f in ipairs(marks) do
    if f == current then
      idx = i
      break
    end
  end

  if not idx then
    vim.cmd("edit " .. vim.fn.fnameescape(marks[#marks]))
    return
  end

  local prev_idx = idx - 1
  if prev_idx < 1 then
    if M._opts.cycle then
      prev_idx = #marks
    else
      require("trident").notify("No previous file", vim.log.levels.INFO)
      return
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(marks[prev_idx]))
end

function M.add_pike(opts)
  -- opts: { filepath, line, name?, type? }
  opts.filepath = opts.filepath or vim.api.nvim_buf_get_name(0)
  pikes_manager.add_pike(opts)
  pikes_ui.place_pike_signs()
end

function M.remove_pike(opts)
  pikes_manager.remove_pike(opts)
  require("trident.pike_ui").place_pike_signs()
end

function M.get_all_pikes()
  return pikes_manager.get_pikes()
end

function M.get_pikes_for_file(filepath)
  filepath = filepath or vim.api.nvim_buf_get_name(0)
  return pikes_manager.get_pikes_for_file(filepath)
end

function M.purge_pikes()
  pikes_manager.purge()
end

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local pikes_ui = require("trident.pike_ui")
    pikes_ui.place_pike_signs()
  end,
})

function M.jump_to_pike(letter)
  local pike = pikes_manager.find_by_letter(letter)
  if not pike then
    vim.notify("No pike with letter: " .. letter, vim.log.levels.WARN)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(pike.filepath))
  vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
end

function M.next_pike()
  local pikes = pikes_manager.get_all_sorted()
  if #pikes == 0 then
    vim.notify("No pikes to jump to", vim.log.levels.INFO)
    return
  end

  local curr_file = vim.api.nvim_buf_get_name(0)
  local curr_line = vim.api.nvim_win_get_cursor(0)[1]

  for _, pike in ipairs(pikes) do
    if pike.filepath > curr_file or (pike.filepath == curr_file and pike.line > curr_line) then
      vim.cmd("edit " .. vim.fn.fnameescape(pike.filepath))
      vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
      return
    end
  end

  local first = pikes[1]
  vim.cmd("edit " .. vim.fn.fnameescape(first.filepath))
  vim.api.nvim_win_set_cursor(0, { first.line, 0 })
end

function M.prev_pike()
  local pikes = pikes_manager.get_all_sorted()
  if #pikes == 0 then
    vim.notify("No pikes to jump to", vim.log.levels.INFO)
    return
  end

  local curr_file = vim.api.nvim_buf_get_name(0)
  local curr_line = vim.api.nvim_win_get_cursor(0)[1]

  for i = #pikes, 1, -1 do
    local pike = pikes[i]
    if pike.filepath < curr_file or (pike.filepath == curr_file and pike.line < curr_line) then
      vim.cmd("edit " .. vim.fn.fnameescape(pike.filepath))
      vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
      return
    end
  end

  local last = pikes[#pikes]
  vim.cmd("edit " .. vim.fn.fnameescape(last.filepath))
  vim.api.nvim_win_set_cursor(0, { last.line, 0 })
end

function M.update_pike_type(letter, new_type)
  local ok = pikes_manager.update_type(letter, new_type)
  if ok then
    require("trident").notify("Updated pike " .. letter .. " to type: " .. new_type)
    require("trident.pike_ui").place_pike_signs()
  else
    require("trident").notify("No pike found with letter " .. letter, vim.log.levels.WARN)
  end
end

function M.next_pike_local()
  local curr_buf = vim.api.nvim_get_current_buf()
  local curr_file = vim.api.nvim_buf_get_name(curr_buf)
  local curr_line = vim.api.nvim_win_get_cursor(0)[1]

  local pikes = pikes_manager.get_pikes_for_file(curr_file)
  if #pikes == 0 then
    vim.notify("No pikes in current buffer", vim.log.levels.INFO)
    return
  end

  table.sort(pikes, function(a, b)
    return a.line < b.line
  end)

  for _, pike in ipairs(pikes) do
    if pike.line > curr_line then
      vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
      return
    end
  end

  local first = pikes[1]
  vim.api.nvim_win_set_cursor(0, { first.line, 0 })
end

function M.prev_pike_local()
  local curr_buf = vim.api.nvim_get_current_buf()
  local curr_file = vim.api.nvim_buf_get_name(curr_buf)
  local curr_line = vim.api.nvim_win_get_cursor(0)[1]

  local pikes = pikes_manager.get_pikes_for_file(curr_file)
  if #pikes == 0 then
    vim.notify("No pikes in current buffer", vim.log.levels.INFO)
    return
  end

  table.sort(pikes, function(a, b)
    return a.line < b.line
  end)

  for i = #pikes, 1, -1 do
    local pike = pikes[i]
    if pike.line < curr_line then
      vim.api.nvim_win_set_cursor(0, { pike.line, 0 })
      return
    end
  end

  local last = pikes[#pikes]
  vim.api.nvim_win_set_cursor(0, { last.line, 0 })
end

M.list_pikes = function()
  pikes_ui.open_picker()
end

function M.add_pike_key(letter)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  M.add_pike({ line = line, letter = letter })
end

function M.remove_pike_key(letter)
  M.remove_pike({ letter = letter })
end

function M.jump_to_pike_key(letter)
  M.jump_to_pike(letter)
end

function M.add_pike_with_type_key(letter, type_name)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  M.add_pike({ line = line, letter = letter, type = type_name })
end

function M.clear_pike_type_at_cursor()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local filepath = vim.api.nvim_buf_get_name(0)
  local pikes = require("trident.pike_manager").get_pikes_for_file(filepath)

  for _, pike in ipairs(pikes) do
    if pike.line == line then
      pike.type = nil
      require("trident.pike_manager").set_pikes(pikes)
      require("trident.pike_ui").place_pike_signs(vim.api.nvim_get_current_buf())
      M.notify("Cleared type of pike '" .. pike.letter .. "' at line " .. line)
      return
    end
  end

  M.notify("No pike found at current line", vim.log.levels.WARN)
end

function M.generate_keybinds(opts)
  opts = opts or {}

  local create_label_prefix = opts.create_label_prefix or "tm"
  local delete_label_prefix = opts.delete_label_prefix or "td"
  local jump_label_prefix = opts.jump_label_prefix or ";"
  local create_typed_prefix = opts.create_typed_prefix or "tt"
  local clear_type_key = opts.clear_type_key or "tr"

  local type_map = {
    t = "todo",
    e = "error",
    w = "warn",
    n = "note",
    f = "fix",
    d = "debug",
    b = "bookmark",
    p = "perf",
    h = "hack",
  }

  for c = string.byte("a"), string.byte("z") do
    local letter = string.char(c)

    vim.keymap.set("n", create_label_prefix .. letter, function()
      M.add_pike_key(letter)
    end, { noremap = true, silent = true })

    vim.keymap.set("n", delete_label_prefix .. letter, function()
      M.remove_pike_key(letter)
    end, { noremap = true, silent = true })

    vim.keymap.set("n", jump_label_prefix .. letter, function()
      M.jump_to_pike_key(letter)
    end, { noremap = true, silent = true })

    for tchar, tname in pairs(type_map) do
      vim.keymap.set("n", create_typed_prefix .. letter .. tchar, function()
        M.add_pike_with_type_key(letter, tname)
      end, { noremap = true, silent = true })
    end
  end

  vim.keymap.set("n", create_typed_prefix, function()
    vim.notify("Use " .. create_typed_prefix .. "<letter><type_letter>, e.g. ttct", vim.log.levels.INFO)
  end, { noremap = true, silent = true })

  vim.keymap.set("n", clear_type_key, function()
    M.clear_pike_type_at_cursor()
  end, { noremap = true, silent = true })
end

return M

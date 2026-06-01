local api = vim.api
local fn = vim.fn
local g = vim.g

local txt = require("nvchad.tabufline.utils").txt
local btn = require("nvchad.tabufline.utils").btn
local faces = require("nvchad.tabufline.utils").faces
local spinners = require("nvchad.tabufline.utils").spinners
local is_activewin = require("nvchad.tabufline.utils").is_activewin
local strep = string.rep
local style_buf = require("nvchad.tabufline.utils").style_buf
local cur_buf = api.nvim_get_current_buf
local opts = require("nvconfig").ui.tabufline

local M = {}

------------------------------- btn actions functions -----------------------------------

vim.cmd [[
  function! TbGoToBuf(bufnr,b,c,d)
    call luaeval('require("nvchad.tabufline").goto_buf(_A)', a:bufnr)
  endfunction]]

vim.cmd [[
  function! TbKillBuf(bufnr,b,c,d)
    call luaeval('require("nvchad.tabufline").close_buffer(_A)', a:bufnr)
  endfunction]]

vim.cmd "function! TbNewTab(a,b,c,d) \n tabnew \n endfunction"
vim.cmd "function! TbGotoTab(tabnr,b,c,d) \n execute a:tabnr ..'tabnext' \n endfunction"
vim.cmd "function! TbCloseAllBufs(a,b,c,d) \n lua require('nvchad.tabufline').closeAllBufs() \n endfunction"
vim.cmd "function! TbToggle_theme(a,b,c,d) \n lua require('base46').toggle_theme() \n endfunction"
vim.cmd "function! TbToggleTabs(a,b,c,d) \n let g:TbTabsToggled = !g:TbTabsToggled | redrawtabline \n endfunction"

---------------------------------- functions -------------------------------------------

local function getFileTreeWidth()
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].ft == opts.treeOffsetFt then
      return api.nvim_win_get_width(win)
    end
  end
  return 0
end

local function available_space()
  local str = ""

  for _, key in ipairs(opts.order) do
    if key ~= "buffers" then
      str = str .. M[key]()
    end
  end

  local modules = api.nvim_eval_statusline(str, { use_tabline = true })
  return vim.o.columns - modules.width
end

------------------------------------- modules -----------------------------------------

M.treeOffset = function()
  local w = getFileTreeWidth()
  return w == 0 and "" or "%#NvimTreeNormal#" .. strep(" ", w) .. "%#NvimTreeWinSeparator#" .. "│"
end

M.buffers = function()
  local buffers = {}
  local has_current = false -- have we seen current buffer yet?

  vim.t.bufs = vim.tbl_filter(vim.api.nvim_buf_is_valid, vim.t.bufs)

  for i, nr in ipairs(vim.t.bufs) do
    if ((#buffers + 1) * opts.bufwidth) > available_space() then
      if has_current then
        break
      end

      table.remove(buffers, 1)
    end

    has_current = cur_buf() == nr or has_current
    table.insert(buffers, style_buf(nr, i, opts.bufwidth))
  end

  return table.concat(buffers) .. txt("%=", "Fill") -- buffers + empty space
end

g.TbTabsToggled = 0

M.tabs = function()
  local result, tabs = "", fn.tabpagenr "$"

  if tabs > 1 then
    for nr = 1, tabs, 1 do
      local tab_hl = "TabO" .. (nr == fn.tabpagenr() and "n" or "ff")
      result = result .. btn(" " .. nr .. " ", tab_hl, "GotoTab", nr)
    end

    local new_tabtn = btn(" 󰐕 ", "TabNewBtn", "NewTab")
    local tabstoggleBtn = btn(" TABS ", "TabTitle", "ToggleTabs")
    local small_btn = btn(" 󰅁 ", "TabTitle", "ToggleTabs")

    return g.TbTabsToggled == 1 and small_btn or new_tabtn .. tabstoggleBtn .. result
  end

  return ""
end

M.btns = function()
  local moon = btn(g.toggle_theme_icon, "TabLine", "Toggle_theme")
  return moon
end

local counter = 0
M.faces = function()
  local modes = faces
  if not is_activewin() then
    return ""
  end

  local m = vim.api.nvim_get_mode().mode
  local face = modes[m][1]
  if vim.g.spinner == 'writing' then
    local progress = ({
      "φ  ",
      "__φ",
      "_φ ",
      "__φ",
      "φ  ",
      "_φ ",
    })[counter % 6 + 1]

    face = face:gsub('φ', progress)
  end

  local res = "%#St_" .. modes[m][2] .. "Mode#" .. face
  return res
end

M.spinner = function()
  local spinner = vim.g.spinner and (spinners[vim.g.spinner][(counter % 5) % 4 + 1] or "") or ""
  -- local mode_sep1 = "%#St_" .. modes[m][2] .. "ModeSep#" .. sep_r
  -- local current_mode = "%#St_CommandMode#" .. modes[m][1]
  -- local mode_sep1 = "%#St_CommandModeSep#" .. sep_r
  counter = counter + 1
  return spinner
end

return function()
  local result = {}

  if opts.modules then
    for key, value in pairs(opts.modules) do
      M[key] = value
    end
  end

  for _, v in ipairs(opts.order) do
    table.insert(result, M[v]())
  end

  return table.concat(result)
end

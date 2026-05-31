local M = {}
local api = vim.api
local get_opt = api.nvim_get_option_value
local strep = string.rep
local cur_buf = api.nvim_get_current_buf
local buf_name = api.nvim_buf_get_name
local get_hl = api.nvim_get_hl

M.separators = {
  default = { left = "", right = "" },
  round = { left = "", right = "" },
  block = { left = "█", right = "█" },
  arrow = { left = "", right = "" },
}

M.is_activewin = function()
  return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

M.txt = function(str, hl)
  str = str or ""
  local a = "%#Tb" .. hl .. "#" .. str
  return a
end

M.btn = function(str, hl, func, arg)
  str = hl and M.txt(str, hl) or str
  arg = arg or ""
  return "%" .. arg .. "@Tb" .. func .. "@" .. str .. "%X"
end

local function filename(str)
  return str:match "([^/\\]+)[/\\]*$"
end

local btn = M.btn
local txt = M.txt

local function new_hl(group1, group2)
  local fg = get_hl(0, { name = group1 }).fg
  local bg = get_hl(0, { name = "Tb" .. group2 }).bg
  api.nvim_set_hl(0, group1 .. group2, { fg = fg, bg = bg })
  return "%#" .. group1 .. group2 .. "#"
end

local function gen_unique_name(name, index)
  for i2, nr2 in ipairs(vim.t.bufs) do
    local filepath = filename(buf_name(nr2))
    if index ~= i2 and filepath == name then
      return vim.fn.fnamemodify(buf_name(vim.t.bufs[index]), ":h:t") .. "/" .. name
    end
  end
end

M.style_buf = function(nr, i, w)
  -- add fileicon + name
  local icon = "󰈚 "
  local is_curbuf = cur_buf() == nr
  local tbHlName = "BufO" .. (is_curbuf and "n" or "ff")
  local icon_hl = new_hl("DevIconDefault", tbHlName)

  local name = filename(buf_name(nr))
  name = name and (gen_unique_name(name, i) or name) or " No Name "

  if name ~= " No Name " then
    local devicon, devicon_hl = require("nvim-web-devicons").get_icon(name)

    if devicon then
      icon = " " .. devicon .. " "
      icon_hl = new_hl(devicon_hl, tbHlName)
    end
  end

  -- padding around bufname; 15= maxnamelen + 2 icon & space + 2 close icon
  local pad = math.floor((w - #name - 5) / 2)
  pad = pad <= 0 and 1 or pad

  local maxname_len = w - 5
  name = string.sub(name, 1, maxname_len - 2) .. (#name > maxname_len and ".." or "")
  name = M.txt(name, tbHlName)

  name = strep(" ", pad - 1) .. (icon_hl .. icon .. name) .. strep(" ", pad - 1)

  local close_btn = btn(" 󰅖 ", nil, "KillBuf", nr)
  name = btn(name, nil, "GoToBuf", nr)

  -- modified bufs icon or close icon
  local mod = get_opt("mod", { buf = nr })
  local cur_mod = get_opt("mod", { buf = 0 })

  -- color close btn for focused / hidden  buffers
  if is_curbuf then
    close_btn = cur_mod and txt("  ", "BufOnModified") or txt(close_btn, "BufOnClose")
  else
    close_btn = mod and txt("  ", "BufOffModified") or txt(close_btn, "BufOffClose")
  end

  name = txt(name .. close_btn, "BufO" .. (is_curbuf and "n" or "ff"))

  return name
end

-- 2nd item is highlight groupname St_NormalMode
M.faces = {
  ["n"] = { "[❀ ••]모", "Normal" },
  ["no"] = { "[❀ ••]모(no) ", "Normal" },
  ["nov"] = { "[❀ ••]모(nov) ", "Normal" },
  ["noV"] = { "[❀ ••]모(noV) ", "Normal" },
  ["noCTRL-V"] = { "[❀ ••]모(noC-V) ", "Normal" },
  ["niI"] = { "niI", "Normal" },
  ["niR"] = { "niI", "Normal" },
  ["niV"] = { "niR", "Normal" },
  ["nt"] = { "nt", "NTerminal" },
  ["ntT"] = { "ntT", "NTerminal" },
-- ⬚▧🔲 ⣏⣹ ⛶(╭ರ_•́)
  ["v"] = { "[❀ 👁👁]v", "Visual" },
  ["vs"] = { "[❀ 👁👁]N", "Visual" },
  ["V"] = { "[❀ 👁👁]V", "Visual" },
  ["Vs"] = { "[❀ 👁👁]VN", "Visual" },
  [" "] = { "space mode?", "Visual" },
  [""] = { "[❀ 👁👁]BLOCK ", "Visual" },
  -- [""] = { "[⊃--]⊃ ", "Visual" },

  ["i"] = { "[❀ ••]φ ", "Insert" },
  ["ic"] = { "[❀ ••]φ c ", "Insert" },
  ["ix"] = { "[❀ ••]φ x ", "Insert" },

  ["t"] = { "[■ --]모", "Terminal" },

  ["R"] = { "REPLACE ", "Replace" },
  ["Rc"] = { "REPLACE [Rc] ", "Replace" },
  ["Rx"] = { "REPLACEa [Rx] ", "Replace" },
  ["Rv"] = { "V-REPLACE ", "Replace" },
  ["Rvc"] = { "V-REPLACE [Rvc] ", "Replace" },
  ["Rvx"] = { "V-REPLACE [Rvx] ", "Replace" },

  ["s"] = { "SELECT ", "Select" },
  ["S"] = { "S-LINE ", "Select" },
  -- [""] = { "S-BLOCK ", "Select" },
  ["c"] = { "[❀ ::]모", "Command" },
  ["cv"] = { "[❀ ::]모", "Command" },
  ["ce"] = { "[❀ ::]모", "Command" },
  ["cr"] = { "[❀ ::]모", "Command" },
  ["r"] = { "PROMPT ", "Confirm" },
  ["rm"] = { "MORE ", "Confirm" },
  ["r?"] = { "CONFIRM ", "Confirm" },
  ["x"] = { "CONFIRM ", "Confirm" },
  ["!"] = { "SHELL ", "Terminal" },
}

M.face_fn = function()
local config = require("nvconfig").ui.statusline
local sep_style = config.separator_style
local sep_r = M.separators[sep_style]["right"]
  local modes = M.faces
  if not M.is_activewin() then
    return ""
  end

  local m = vim.api.nvim_get_mode().mode
  -- local current_mode = "%#St_" .. modes[m][2] .. "Mode#" .. modes[m][1]
  -- local mode_sep1 = "%#St_" .. modes[m][2] .. "ModeSep#" .. sep_r
  local current_mode = "%#St_CommandMode#" .. modes[m][1]
  local mode_sep1 = "%#St_CommandModeSep#" .. sep_r
  return current_mode .. mode_sep1
end

return M

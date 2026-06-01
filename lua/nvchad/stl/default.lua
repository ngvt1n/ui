local config = require("nvconfig").ui.statusline
local sep_style = config.separator_style
local utils = require "nvchad.stl.utils"

local sep_icons = utils.separators
local separators = (type(sep_style) == "table" and sep_style) or sep_icons[sep_style]

local sep_l = separators["left"]
local sep_r = separators["right"]

local M = {}

M.sky = (tonumber(os.date('%H')) > 18 and "🌛" or "🌞") .. " /"

M.mode = function()
  if not utils.is_activewin() then
    return ""
  end

  local modes = utils.modes

  local m = vim.api.nvim_get_mode().mode

  local current_mode = "%#St_" .. modes[m][2] .. "Mode#  " .. modes[m][1]
  local mode_sep1 = "%#St_" .. modes[m][2] .. "ModeSep#" .. sep_r
  return current_mode .. mode_sep1 .. "%#ST_EmptySpace#" .. sep_r
end

M.file = function()
  local x = utils.file()
  local name = x[2] .. (sep_style == "default" and " " or "")
  return "%#St_file# " .. name .. "%#St_file_sep#" .. sep_r
end

M.git = function()
  return "%#St_gitIcons#" .. utils.git()
end

M.lsp_msg = function()
  return "%#St_LspMsg#" .. utils.lsp_msg()
end

M.diagnostics = utils.diagnostics

M.lsp = function()
  if rawget(vim, "lsp") and vim.version().minor >= 10 then
    for _, client in ipairs(vim.lsp.get_clients()) do
      if client.attached_buffers[utils.stbufnr()] and client.name ~= "copilot" then
        return (vim.o.columns > 100 and " %#st_lsp#" .. client.name .. " /") or " %#st_lsp#  /"
      end
    end
  end
  return ""
end

M.copilot = function()
  if rawget(vim, "lsp") and vim.version().minor >= 10 then
    for _, client in ipairs(vim.lsp.get_clients()) do
      if client.attached_buffers[utils.stbufnr()] and client.name == "copilot" then
        local c = require "copilot.client"
        return (c.is_disabled()) and "" or "%#St_CopilotSep# %#St_Copilot#  %#St_CopilotSep#▌"
      end
    end
  end
  return ""
end

M.cursor = "%#St_pos_icon#" .. "%#St_Pos_text# %p%% "


M.cwd = function()
  local icon = "%#St_cwd_text#" .. "󰉋"
  local name = vim.uv.cwd() or ""
  name = "%#St_cwd_text#" .. " " .. (name:match "([^/\\]+)[/\\]*$" or name) .. " "
  return (vim.o.columns > 85 and ("%#St_cwd_sep# " .. icon .. name) .. "/") or ""
end

M.clock = function()
  return "/  " .. os.date "%H:%M"
end

M["%="] = "%="

return function()
  return utils.generate("default", M)
end

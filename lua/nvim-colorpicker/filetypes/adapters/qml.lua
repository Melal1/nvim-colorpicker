---@module 'nvim-colorpicker.filetypes.adapters.qml'
---@brief QML adapter for Qt Quick #AARRGGBB

local base = require('nvim-colorpicker.filetypes.base')
local patterns = require('nvim-colorpicker.filetypes.patterns')

---@class QmlAdapter : BaseAdapter
local QmlAdapter = base.BaseAdapter.new({
  filetypes = { "qml" },
  default_format = "hex",
  value_range = "0-255",
  patterns = patterns.combine(
    {
      { pattern = "Qt%.rgba%s*%(%s*[%d%.]+%s*,%s*[%d%.]+%s*,%s*[%d%.]+%s*,%s*[%d%.]+%s*%)", format = "qt_rgba", priority = 95 },
    },
    patterns.universal
  ),
})

function QmlAdapter:format_color(hex, format, alpha)
  local r, g, b = self:hex_to_rgb(hex)
  local a = alpha and self:alpha_to_byte(alpha) or 255

  if format == "qt_rgba" then
    local rf, gf, bf = self:rgb_to_float(r, g, b)
    local af = alpha and self:alpha_to_decimal(alpha) or 1.0
    return string.format("Qt.rgba(%.3f, %.3f, %.3f, %.3f)", rf, gf, bf, af)
  elseif format == "hex" or format == "hex8" then
    if alpha and alpha < 100 then
      return string.format("#%02X%s", a, hex:sub(2):upper())
    end
    return hex
  end

  return hex
end

function QmlAdapter:parse_color(match, format)
  if format == "qt_rgba" then
    local rf, gf, bf, af = match:match("Qt%.rgba%s*%(%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*%)")
    if rf and gf and bf and af then
      local r, g, b = self:float_to_rgb(tonumber(rf), tonumber(gf), tonumber(bf))
      local alpha = self:decimal_to_alpha(tonumber(af))
      return self:rgb_to_hex(r, g, b), alpha
    end
  elseif format == "hex8" then
    local alpha_hex = match:sub(2, 3)
    local alpha_int = tonumber(alpha_hex, 16)
    local alpha = alpha_int and self:byte_to_alpha(alpha_int) or nil
    return "#" .. match:sub(4, 9):upper(), alpha
  elseif format == "hex" then
    return self:normalize_hex(match), nil
  elseif format == "hex3" then
    local short = match:gsub("^#", "")
    if #short == 3 then
      local expanded = short:sub(1, 1):rep(2) .. short:sub(2, 2):rep(2) .. short:sub(3, 3):rep(2)
      return "#" .. expanded:upper(), nil
    end
  end

  local color_format = require('nvim-colorpicker.color.format')
  return color_format.parse_color_string(match)
end

return QmlAdapter

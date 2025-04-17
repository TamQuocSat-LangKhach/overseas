-- SPDX-License-Identifier: GPL-3.0-or-later

Fk:loadTranslationTable(require 'packages/overseas/i18n/en_US', 'en_US')

local prefix = "packages.overseas.pkg."

local overseas_ex = require (prefix .. "overseas_ex")
-- local overseas_sp = require (prefix .. "overseas_sp")
-- local overseas_strategizing = require (prefix .. "overseas_strategizing")
-- local overseas_wuxia = require (prefix .. "overseas_wuxia")
-- local overseas_if = require (prefix .. "overseas_if")
-- local overseas_token = require (prefix .. "overseas_token")

Fk:loadTranslationTable{
  ["overseas"] = "国际服",
}

return {
  overseas_ex,
  -- overseas_sp,
  -- overseas_strategizing,
  -- overseas_wuxia,
  -- overseas_if,
  -- overseas_token,
}

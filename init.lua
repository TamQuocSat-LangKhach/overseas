local overseas_ex = require "packages/overseas/overseas_ex"
local overseas_sp = require "packages/overseas/overseas_sp"
local overseas_sp2 = require"packages/overseas/overseas_sp2"
local overseas_strategizing = require "packages/overseas/overseas_strategizing"
local overseas_wuxia = require "packages/overseas/overseas_wuxia"
local overseas_if = require "packages/overseas/overseas_if"
local overseas_token = require "packages/overseas/overseas_token"

Fk:loadTranslationTable{ ["overseas"] = "国际服" }
Fk:loadTranslationTable(require 'packages/overseas/i18n/en_US', 'en_US')

return {
  overseas_ex,
  overseas_sp,
  overseas_sp2,
  overseas_strategizing,
  overseas_wuxia,
  overseas_if,
  overseas_token,
}

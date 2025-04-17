local osExShenxing = fk.CreateSkill {
  name = "os_ex__shenxing"
}

Fk:loadTranslationTable{
  ["os_ex__shenxing"] = "慎行",
  [":os_ex__shenxing"] = "出牌阶段，你可弃置X张牌，摸一张牌（X为你发动过〖慎行〗的次数且至多为2）。",

  ["#os_ex__shenxing-active"] = "慎行：你可弃置 %arg 张牌，然后摸一张牌",
  ["@os_ex__shenxing"] = "慎行",

  ["$os_ex__shenxing1"] = "事前多思，事后少悔。",
  ["$os_ex__shenxing2"] = "权衡斟酌，再虑一番。",
}

osExShenxing:addEffect("active", {
  can_use = Util.TrueFunc,
  prompt = function (self, player, selected_cards, selected_targets)
    return "#os_ex__shenxing-active:::" .. math.min(player:getMark("@os_ex__shenxing"), 2)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < math.min(player:getMark("@os_ex__shenxing"), 2) and not player:prohibitDiscard(to_select)
  end,
  target_num = 0,
  card_num = function(self, player)
    return math.min(player:getMark("@os_ex__shenxing"), 2)
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osExShenxing.name
    local from = effect.from
    room:addPlayerMark(from, "@os_ex__shenxing")
    room:throwCard(effect.cards, skillName, from)
    room:drawCards(from, 1, skillName)
  end,
})

osExShenxing:addLoseEffect(function(self, player)
  player.room:setPlayerMark(player, "@os_ex__shenxing", 0)
end)

return osExShenxing

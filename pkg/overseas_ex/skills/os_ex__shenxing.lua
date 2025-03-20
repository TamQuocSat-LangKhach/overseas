local os_ex__shenxing = fk.CreateSkill {
  name = "os_ex__shenxing"
}

Fk:loadTranslationTable{
  ['os_ex__shenxing'] = '慎行',
  ['#os_ex__shenxing-active'] = '慎行：你可弃置 %arg 张牌，然后摸一张牌',
  ['@os_ex__shenxing'] = '慎行',
  [':os_ex__shenxing'] = '出牌阶段，你可弃置X张牌，摸一张牌（X为你发动过〖慎行〗的次数且至多为2）。',
  ['$os_ex__shenxing1'] = '事前多思，事后少悔。',
  ['$os_ex__shenxing2'] = '权衡斟酌，再虑一番。',
}

os_ex__shenxing:addEffect('active', {
  can_use = Util.TrueFunc,
  prompt = function (skill, player, selected_cards, selected_targets)
    return "#os_ex__shenxing-active:::" .. math.min(player:getMark("@os_ex__shenxing"), 2)
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < math.min(player:getMark("@os_ex__shenxing"), 2)
  end,
  target_num = 0,
  card_num = function(self, player)
    return math.min(player:getMark("@os_ex__shenxing"), 2)
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:addPlayerMark(from, "@os_ex__shenxing")
    room:throwCard(effect.cards, os_ex__shenxing.name, from)
    room:drawCards(from, 1, os_ex__shenxing.name)
  end,
})

os_ex__shenxing:addEffect('on_lose', {
  on_lose = function (skill, player, is_death)
    player.room:setPlayerMark(player, "@os_ex__shenxing", 0)
  end
})

return os_ex__shenxing

local osLuanlue = fk.CreateSkill {
  name = "os__luanlue",
}

Fk:loadTranslationTable{
  ["os__luanlue"] = "乱掠",
  [":os__luanlue"] = "出牌阶段，你可将X张【杀】当做【顺手牵羊】对一名本阶段未成为过【顺手牵羊】目标的角色使用" ..
  "（X为你以此法使用过【顺手牵羊】的次数）。你使用的【顺手牵羊】不能被响应。",

  ["@os__luanlue"] = "乱掠",
  ["os__luanlue-tag"] = "乱掠",

  ["$os__luanlue1"] = "合兵寇河内，聚众掠太原。",
  ["$os__luanlue2"] = "联白波之众，掠河东之地。",
}

osLuanlue:addEffect("viewas", {
  anim_type = "control",
  pattern = "snatch",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return Fk:getCardById(to_select).trueName == "slash" and #selected < player:getMark("@os__luanlue")
  end,
  view_as = function(self, player, cards)
    if #cards ~= player:getMark("@os__luanlue") then
      return nil
    end
    local c = Fk:cloneCard("snatch")
    c.skillName = osLuanlue.name .. "-tag"
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    player.room:addPlayerMark(player, "@os__luanlue")
    table.removeOne(use.card.skillNames, osLuanlue.name .. "-tag")
    use.card.skillName = osLuanlue.name
  end,
})

osLuanlue:addEffect("prohibit", {
  is_prohibited = function(self, from, to, card)
    return
      to:getMark("_os__luanlue-phase") > 0 and
      card and
      card.name == "snatch" and
      table.contains(card.skillNames, osLuanlue.name .. "-tag")
  end,
})

osLuanlue:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.name == "snatch" and player:hasSkill(osLuanlue.name)
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.forEach(player.room.players, function(p)
      table.insertIfNeed(data.disresponsiveList, p)
    end)
  end,
})

osLuanlue:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.name == "snatch" and player.room.current.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__luanlue-phase")
  end,
})

return osLuanlue

local os__zhuiting_other = fk.CreateSkill {
  name = "os__zhuiting_other"
}

Fk:loadTranslationTable{
  ['os__zhuiting_other&'] = '坠廷',
  [':os__zhuiting_other&'] = '当一张锦囊牌对刘协生效前，你可以将一张与之颜色相同的手牌当【无懈可击】使用。',
}

os__zhuiting_other:addEffect('viewas', {
  anim_type = "control",
  pattern = "nullification",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and
      Fk:getCardById(to_select).color == player:getMark("os__zhuiting_activated") and
      player:getMark("os__zhuiting_activated") ~= Card.NoColor
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("nullification")
    card.skillName = skill.name
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_response = function (skill, player, response)
    return (not response and
      (response == nil or player:getMark("os__zhuiting_activated") ~= 0) and
      not player:isKongcheng())
  end,
})

os__zhuiting_other:addEffect(fk.HandleAskForPlayCard, {
  can_refresh = function(self, event, target, player, data)
    if data.afterRequest and (data.extra_data or {}).os__zhuiting_effected then
      return player:getMark("os__zhuiting_activated") ~= 0
    end

    return
      player:hasSkill(os__zhuiting_other) and
      data.eventData and
      data.eventData.to and
      player.room:getPlayerById(data.eventData.to):hasSkill(os__zhuiting) and
      Exppattern:Parse(data.pattern):match(Fk:cloneCard("nullification"))
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if data.afterRequest then
      room:setPlayerMark(player, "os__zhuiting_activated", 0)
    else
      room:setPlayerMark(player, "os__zhuiting_activated", data.eventData.card.color)
      data.extra_data = data.extra_data or {}
      data.extra_data.os__zhuiting_effected = true
    end
  end,
})

return os__zhuiting_other

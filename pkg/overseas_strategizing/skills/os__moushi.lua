local os__moushi = fk.CreateSkill {
  name = "os__moushi"
}

Fk:loadTranslationTable{
  ['os__moushi'] = '谋识',
  ['@os__moushi'] = '谋识',
  [':os__moushi'] = '锁定技，当你受到伤害时，若造成伤害的牌与上次对你造成伤害的牌颜色相同，则你防止此伤害。',
  ['$os__moushi1'] = '潜谋于无形，胜于不争不费。',
  ['$os__moushi2'] = '欲思其成，必虑其败也。',
}

os__moushi:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(os__moushi.name) and data.card and data.card.color == player:getMark("_" .. os__moushi.name)
  end,
  on_use = Util.TrueFunc,

  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(os__moushi.name, true) and data.card and data.card.color ~= Card.NoColor
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_" .. os__moushi.name, data.card.color)
    if player:hasSkill(os__moushi.name, true) then 
      room:setPlayerMark(player, "@" .. os__moushi.name, data.card:getColorString())
    end
  end,
})

return os__moushi

local os__jintao = fk.CreateSkill {
  name = "os__jintao"
}

Fk:loadTranslationTable{
  ['os__jintao'] = '进讨',
  [':os__jintao'] = '锁定技，你使用【杀】无距离限制且次数+1。你出牌阶段使用的第一张【杀】伤害值基数+1，第二张【杀】不可响应。',
  ['$os__jintao1'] = '一雪前耻，誓报前仇！',
  ['$os__jintao2'] = '量敌而进，直讨吴境！',
}

os__jintao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__jintao.name) then
      local filter = function (e)
        return e.data[1].from == player.id and e.data[1].card.trueName == "slash"
      end
      local times = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 3, filter, Player.phase)
      event:setCostData(self, times)
      return data.card.trueName == "slash" and player.phase == Player.Play and times <= 2
    end
  end,
  on_use = function(self, event, target, player, data)
    local num = event:getCostData(self)
    if num == 1 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif num == 2 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, target in ipairs(player.room.alive_players) do
        table.insertIfNeed(data.disresponsiveList, target.id)
      end
    end
  end,
})

os__jintao:addEffect('targetmod', {
  anim_type = "offensive",
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(os__jintao.name) and skill.trueName == "slash_skill") and 1 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill(os__jintao.name) and skill.trueName == "slash_skill") and 999 or 0
  end,
})

return os__jintao

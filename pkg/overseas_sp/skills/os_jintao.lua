local osJintao = fk.CreateSkill {
  name = "os__jintao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__jintao"] = "进讨",
  [":os__jintao"] = "锁定技，你使用【杀】无距离限制且次数+1。你出牌阶段使用的第一张【杀】伤害值基数+1，第二张【杀】不可响应。",

  ["$os__jintao1"] = "一雪前耻，誓报前仇！",
  ["$os__jintao2"] = "量敌而进，直讨吴境！",
}

osJintao:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(osJintao.name) then
      local filter = function (e)
        return e.data.from == player and e.data.card.trueName == "slash"
      end
      local times = #player.room.logic:getEventsOfScope(GameEvent.UseCard, 3, filter, Player.HistoryPhase)
      
      if data.card.trueName == "slash" and player.phase == Player.Play and times <= 2 then
        event:setCostData(self, times)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local num = event:getCostData(self)
    if num == 1 then
      data.additionalDamage = (data.additionalDamage or 0) + 1
    elseif num == 2 then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(player.room.alive_players) do
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end,
})

osJintao:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(osJintao.name) and skill.trueName == "slash_skill") and 1 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill(osJintao.name) and skill.trueName == "slash_skill") and 999 or 0
  end,
})

return osJintao

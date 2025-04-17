local osExQiushou = fk.CreateSkill {
  name = "os_ex__qiushou",
  tags = { Skill.Lord, Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os_ex__qiushou"] = "酋首",
  [":os_ex__qiushou"] = "主公技，锁定技，当【南蛮入侵】的使用结算结束后，若此牌造成的伤害大于3点或有角色因此死亡，所有蜀势力和群势力角色各摸一张牌。",
}

osExQiushou:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(osExQiushou.name) and data.card.trueName == "savage_assault") then return end
    if data.damageDealt then
      local num = 0
      for _, v in pairs(data.damageDealt) do
        num = num + v
      end
      if num > 3 then return true end
    end
    local room = player.room
    return #room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
      local deathData = e.data
      if deathData.damage and e:findParent(GameEvent.UseCard) and e:findParent(GameEvent.UseCard).id == room.logic:getCurrentEvent().id then
        return true
      end
    end, Player.HistoryPhase) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return table.contains({ "shu", "qun" }, p.kingdom) end)
    if #targets == 0 then return end
  
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if p:isAlive() then
        p:drawCards(1, osExQiushou.name)
      end
    end
  end,
})

return osExQiushou

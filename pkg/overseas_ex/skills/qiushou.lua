local qiushou = fk.CreateSkill {
  name = "os_ex__qiushou$"
}

Fk:loadTranslationTable{ }

qiushou:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(qiushou.name) and data.card.trueName == "savage_assault") then return end
    if data.damageDealt then
      local num = 0
      for _, v in pairs(data.damageDealt) do
        num = num + v
      end
      if num > 3 then return true end
    end
    local room = player.room
    return #room.logic:getEventsOfScope(GameEvent.Death, 1, function (e)
      local deathData = e.data[1]
      if deathData.damage and e:findParent(GameEvent.UseCard) and e:findParent(GameEvent.UseCard).id == room.logic:getCurrentEvent().id then
        return true
      end
    end, Player.HistoryPhase) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return table.contains({"shu", "qun"}, p.kingdom) end)
    if #targets == 0 then return end
    targets = table.map(targets, Util.IdMapper)
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        p:drawCards(1, qiushou.name)
      end
    end
  end,
})

return qiushou

local osXiongjun = fk.CreateSkill {
  name = "os__xiongjun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__xiongjun"] = "凶军",
  [":os__xiongjun"] = "锁定技，当你于一个回合内第一次造成伤害后，所有拥有〖凶军〗的角色各摸一张牌。",

  ["$os__xiongjun1"] = "凶兵愤戾，尽诛长安之民！",
  ["$os__xiongjun2"] = "继董公之命，逞凶戾之兵。",
}

osXiongjun:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if target ~= player or not player:hasSkill(osXiongjun.name) then
      return false
    end

    local events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
      return e.data.from == player
    end, Player.HistoryTurn)
    return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osXiongjun.name
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if p:hasSkill(skillName, true) then
        p:drawCards(1, skillName)
      end
    end
  end,
})

return osXiongjun

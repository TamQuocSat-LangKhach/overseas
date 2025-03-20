local os__xiongjun = fk.CreateSkill {
  name = "os__xiongjun"
}

Fk:loadTranslationTable{
  ['os__xiongjun'] = '凶军',
  [':os__xiongjun'] = '锁定技，当你于一个回合内第一次造成伤害后，所有拥有〖凶军〗的角色各摸一张牌。',
  ['$os__xiongjun1'] = '凶兵愤戾，尽诛长安之民！',
  ['$os__xiongjun2'] = '继董公之命，逞凶戾之兵。',
}

os__xiongjun:addEffect(fk.Damage, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if target ~= player or not player:hasSkill(os__xiongjun.name) then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e) 
      return e.data[1].from == player
    end, Player.HistoryTurn)
    return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
  end,
  on_use = function(self, event, target, player)
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if p:hasSkill(os__xiongjun.name) and not p.dead then
        p:drawCards(1, os__xiongjun.name)
      end
    end
  end,
})

return os__xiongjun

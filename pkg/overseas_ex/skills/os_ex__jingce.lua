local os_ex__jingce = fk.CreateSkill {
  name = "os_ex__jingce"
}

Fk:loadTranslationTable{
  ['os_ex__jingce'] = '精策',
  ['@os_ex__strategy'] = '策',
  [':os_ex__jingce'] = '当你出牌阶段使用的第X张牌结算结束后（X为你的体力值），你可摸两张牌，然后若这不是你此阶段第一次摸牌或此回合你已造成过伤害，你获得1枚“策”。',
  ['$os_ex__jingce1'] = '方策精详，有备无患。',
  ['$os_ex__jingce2'] = '精兵拒敌，策守如山。',
}

os_ex__jingce:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(os_ex__jingce) or player.phase ~= Player.Play then return false end 
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e) 
      local use = e.data[1]
      return use.from == player.id
    end, Player.HistoryPhase)
    return #events >= player.hp and events[player.hp].id == player.room.logic:getCurrentEvent().id
  end,
  on_use = function(self, event, target, player, data)
    local invoke = false
    local room = player.room
    if #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == player end) > 0 then
      invoke = true
    end
    if not invoke and #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.to == player.id and move.moveReason == fk.ReasonDraw then return true end
      end
    end, Player.HistoryPhase) == 1 then
      invoke = true
    end
    player:drawCards(2, os_ex__jingce.name)
    if invoke and not player.dead then
      room:addPlayerMark(player, "@os_ex__strategy", 1)
    end
  end,
})

return os_ex__jingce

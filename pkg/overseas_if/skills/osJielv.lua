local osJielv = fk.CreateSkill {
  name = "os__jielv"
}

Fk:loadTranslationTable{
  ['os__jielv'] = '竭虑',
  [':os__jielv'] = '锁定技，一名角色的回合结束时，若你于本回合内未对其使用过牌，则你失去1点体力；当你受到1点伤害或失去1点体力后，若你的体力上限小于7，则你加1点体力上限。',
  ['$os__jielv1'] = '竭一国之材，尽万人之力！',
  ['$os__jielv2'] = '穷力尽心，亮定以血补天！',
}

osJielv:addEffect(fk.TurnEnd, {
  can_trigger = function (self, event, target, player)
    if not player:hasSkill(osJielv.name) then
      return false
    end

    return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      return use.from == player.id and table.contains(TargetGroup:getRealTargets(use.tos), target.id)
    end, Player.HistoryTurn) == 0
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    room:loseHp(player, 1, osJielv.name)
  end,
})

osJielv:addEffect(fk.Damaged, {
  can_trigger = function (self, event, target, player)
    if not player:hasSkill(osJielv.name) then
      return false
    end

    return target == player and player.maxHp < 7
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, math.min(event == fk.Damaged and data.damage or data.num, 7 - player.maxHp))
  end,
})

osJielv:addEffect(fk.HpLost, {
  can_trigger = function (self, event, target, player)
    if not player:hasSkill(osJielv.name) then
      return false
    end

    return target == player and player.maxHp < 7
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    room:changeMaxHp(player, math.min(event == fk.HpLost and data.num or data.num, 7 - player.maxHp))
  end,
})

return osJielv

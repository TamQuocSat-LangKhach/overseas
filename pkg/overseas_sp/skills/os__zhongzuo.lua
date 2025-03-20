local os__zhongzuo = fk.CreateSkill {
  name = "os__zhongzuo"
}

Fk:loadTranslationTable{
  ['os__zhongzuo'] = '忠佐',
  ['#os__zhongzuo-ask'] = '忠佐：你可令一名角色摸两张牌，若其已受伤，你摸一张牌',
  [':os__zhongzuo'] = '一名角色的结束阶段结束时，若你于本回合内造成或受到过伤害，你可令一名角色摸两张牌，若其已受伤，你摸一张牌。',
  ['$os__zhongzuo1'] = '历经磨难，不改佐国之志。',
  ['$os__zhongzuo2'] = '建功立业，唯愿天下早定。',
}

os__zhongzuo:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and player:hasSkill(os__zhongzuo.name) and player:getMark("_os__zhongzuo_available-turn") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__zhongzuo-ask",
      skill_name = os__zhongzuo.name,
      cancelable = true
    })

    if #target > 0 then
      event:setCostData(self, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local p = room:getPlayerById(event:getCostData(self))
    p:drawCards(2, os__zhongzuo.name)
    if p:isWounded() and not player.dead then player:drawCards(1, os__zhongzuo.name) end
  end,
})

os__zhongzuo:addEffect({fk.Damage, fk.Damaged}, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__zhongzuo_available-turn") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "_os__zhongzuo_available-turn", 1)
  end,
})

return os__zhongzuo

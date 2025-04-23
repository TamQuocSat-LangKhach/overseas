local osZhongzuo = fk.CreateSkill {
  name = "os__zhongzuo"
}

Fk:loadTranslationTable{
  ["os__zhongzuo"] = "忠佐",
  [":os__zhongzuo"] = "一名角色的结束阶段结束时，若你于本回合内造成或受到过伤害，你可令一名角色摸两张牌，若其已受伤，你摸一张牌。",

  ["#os__zhongzuo-ask"] = "忠佐：你可令一名角色摸两张牌，若其已受伤，你摸一张牌",

  ["$os__zhongzuo1"] = "历经磨难，不改佐国之志。",
  ["$os__zhongzuo2"] = "建功立业，唯愿天下早定。",
}

osZhongzuo:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return
      target.phase == Player.Finish and
      player:hasSkill(osZhongzuo.name) and
      #player.room.logic:getActualDamageEvents(
        1,
        function(e) return e.data.from == player or e.data.to == player end,
        Player.HistoryTurn
      ) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getAlivePlayers(false),
        min_num = 1,
        max_num = 1,
        prompt = "#os__zhongzuo-ask",
        skill_name = osZhongzuo.name,
      }
    )

    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhongzuo.name

    local p = event:getCostData(self)
    p:drawCards(2, skillName)
    if p:isWounded() and player:isAlive() then
      player:drawCards(1, skillName)
    end
  end,
})

return osZhongzuo

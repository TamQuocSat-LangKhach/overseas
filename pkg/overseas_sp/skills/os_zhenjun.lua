local osZhenjun = fk.CreateSkill {
  name = "os__zhenjun"
}

Fk:loadTranslationTable{
  ["os__zhenjun"] = "镇军",
  [":os__zhenjun"] = "出牌阶段开始时，你可交给一名其他角色一张牌，令其使用一张非黑色的【杀】：若其执行，" ..
  "则此【杀】结算后你摸一张牌，若此【杀】造成过伤害，你额外摸伤害值数张牌；若其不执行，则你可对其或其攻击范围内的一名角色造成1点伤害。",

  ["#os__zhenjun-target"] = "你可选择一张牌，交给一名其他角色，对其发动“镇军”",
  ["#os__zhenjun_slash"] = "镇军：请使用一张非黑色的【杀】",
  ["#os__zhenjun-damage"] = "镇军：你可对 %dest 或其攻击范围内的一名角色造成1点伤害",

  ["$os__zhenjun1"] = "将怀其威，则镇其军。",
  ["$os__zhenjun2"] = "治军之道，得之于严。",
}

osZhenjun:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osZhenjun.name) and
      player.phase == Player.Play and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local plist, cid = player.room:askToChooseCardsAndPlayers(
      player,
      {
        targets = player.room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        min_card_num = 1,
        max_card_num = 1,
        prompt = "#os__zhenjun-target",
        skill_name = osZhenjun.name,
      }
    )
    if #plist > 0 then
      event:setCostData(self, { plist[1], cid })
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osZhenjun.name
    local room = player.room
    local to = event:getCostData(self)[1]
    room:doIndicate(player, { to })

    room:moveCardTo(event:getCostData(self)[2], Player.Hand, to, fk.ReasonGive, skillName, nil, false, player)
    local use = room:askToUseCard(
      to,
      {
        pattern = "slash|.|heart,diamond,nosuit",
        prompt = "#os__zhenjun_slash",
        skill_name = "slash",
      }
    )
    if use then
      room:useCard(use)
      local num = 0
      if use.damageDealt then
        for _, v in pairs(use.damageDealt) do
          num = num + v
        end
      end
      player:drawCards(num + 1, skillName)
    else
      local victim = room:askToChoosePlayers(
        player,
        {
          targets = table.filter(room.alive_players, function(p)
            return (p == to or to:inMyAttackRange(p))
          end),
          min_num = 1,
          max_num = 1,
          prompt = "#os__zhenjun-damage::" .. to.id,
          skill_name = skillName,
        }
      )
      if #victim > 0 then 
        room:damage{
          from = player,
          to = victim[1],
          damage = 1,
          skillName = skillName,
        }
      end
    end
  end,
})

return osZhenjun

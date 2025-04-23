local osYangshi = fk.CreateSkill {
  name = "os__yangshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__yangshi"] = "扬师",
  [":os__yangshi"] = "锁定技，当你受到伤害后，你的攻击范围+1，若所有其他角色均在你的攻击范围内，则改为从牌堆获得一张【杀】。",

  ["@os__yangshi"] = "扬师",

  ["$os__yangshi1"] = "扬师北疆，剪覆胡奴！",
  ["$os__yangshi2"] = "陈兵百万，慑敌心胆！",
}

osYangshi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osYangshi.name
    local room = player.room
    if
      table.every(room:getOtherPlayers(player, false), function(p)
        return player:inMyAttackRange(p)
      end)
    then
      local cids = room:getCardsFromPileByRule("slash")
      if #cids > 0 then
        room:obtainCard(player, cids[1], false, fk.ReasonPrey, player, skillName)
      end
    else
      room:addPlayerMark(player, "@" .. skillName)
    end
  end,
})

osYangshi:addEffect("atkrange", {
  correct_func = function(self, from, to)
    return from:getMark("@" .. osYangshi.name)
  end,
})

return osYangshi

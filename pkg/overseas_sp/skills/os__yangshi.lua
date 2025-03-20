local os__yangshi = fk.CreateSkill {
  name = "os__yangshi",
}

Fk:loadTranslationTable{
  ['os__yangshi'] = '扬师',
  ['@os__yangshi'] = '扬师',
  [':os__yangshi'] = '锁定技，当你受到伤害后，你的攻击范围+1，若所有其他角色均在你的攻击范围内，则改为从牌堆获得一张【杀】。',
  ['$os__yangshi1'] = '扬师北疆，剪覆胡奴！',
  ['$os__yangshi2'] = '陈兵百万，慑敌心胆！',
}

os__yangshi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  frequency = Skill.Compulsory,
  on_use = function(self, event, target, player)
    local room = player.room
    if table.every(room:getOtherPlayers(player, false), function(p)
      return player:inMyAttackRange(p)
    end) then
      local cids = room:getCardsFromPileByRule("slash")
      if #cids > 0 then
        room:obtainCard(player, cids[1], false, fk.ReasonPrey)
      end
    else
      room:addPlayerMark(player, "@" .. os__yangshi.name, 1)
    end
  end,
})

os__yangshi:addEffect('atkrange', {
  name = "#os__yangshiAR",
  correct_func = function(self, from, to)
    return from:getMark("@" .. os__yangshi.name)
  end,
})

return os__yangshi

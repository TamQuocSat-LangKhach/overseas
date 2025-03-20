local os__xingqi = fk.CreateSkill {
  name = "os__xingqi"
}

Fk:loadTranslationTable{
  ['os__xingqi'] = '星启',
  ['os__mibei'] = '秘备',
  ['@@os__xingqi_nodistance'] = '星启无距离限制',
  [':os__xingqi'] = '觉醒技，准备阶段开始时，若场上的牌数大于你的体力值，则你回复1点体力，然后若〖秘备〗未完成，你从牌堆中获得每种类别的牌各一张；若〖秘备〗已完成，本局游戏你使用牌无距离限制。',
  ['$os__xingqi1'] = '司马氏虽权尊势重，吾等徐图亦无不可！',
  ['$os__xingqi2'] = '先谋后事者昌，先事后谋者亡！'
}

os__xingqi:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Start and player:usedSkillTimes(os__xingqi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    local num = 0
    for _, p in ipairs(player.room.alive_players) do
      num = num + #p:getCardIds({Player.Equip, Player.Judge})
    end
    return num > player.hp
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = os__xingqi.name,
    })
    if player:getQuestSkillState("os__mibei") ~= "succeed" then
      local cards = {}
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
      room:obtainCard(player, cards, false, fk.ReasonPrey)
    else
      room:setPlayerMark(player, "@@os__xingqi_nodistance", 1)
    end
  end,
})

local os__xingqi_nodistance = fk.CreateSkill {
  name = "#os__xingqi_nodistance"
}

os__xingqi_nodistance:addEffect('targetmod', {
  bypass_distances = function(self, player, skill_name)
    return player:getMark("@@os__xingqi_nodistance") > 0
  end,
})

return os__xingqi, os__xingqi_nodistance

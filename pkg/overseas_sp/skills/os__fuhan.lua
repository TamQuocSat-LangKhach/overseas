local os__fuhan = fk.CreateSkill {
  name = "os__fuhan"
}

Fk:loadTranslationTable{
  ['os__fuhan'] = '扶汉',
  ['@meiying'] = '梅影',
  ['#os__fuhan-invoke'] = '扶汉：你可弃所有“梅影”，从5张蜀势力武将牌中选择一张获得其所有技能，将体力上限调整为%arg，回复1点体力',
  ['@os__fuhan'] = '扶汉',
  ['os__queshi'] = '鹊拾',
  [':os__fuhan'] = '限定技，准备阶段开始时，你可弃所有“梅影”，然后从五张未登场的蜀势力武将牌中选择一张，获得其所有技能，并将体力上限调整为以此移去“梅影”的数量（最少为2，最多为8），回复1点体力。',
  ['$os__fuhan1'] = '承先父之志，扶汉兴刘。',
  ['$os__fuhan2'] = '天将降大任于我。',
}

os__fuhan:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__fuhan.name) and player.phase == Player.Start and player:getMark("@meiying") > 0 and player:usedSkillTimes(os__fuhan.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player)
    local maxHp = math.min(math.max(player:getMark("@meiying"), 2), 8)
    return player.room:askToSkillInvoke(player, {
      skill_name = os__fuhan.name,
      prompt = "#os__fuhan-invoke:::" .. maxHp
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local num = player:getMark("@meiying")
    room:setPlayerMark(player, "@meiying", 0)
    local generals = table.filter(room.general_pile, function (general_name)
      local general = Fk.generals[general_name]
      return general.kingdom == "shu"
    end)
    if #generals > 0 then
      generals = table.random(generals, 5)
      local general = Fk.generals[room:askToChooseGeneral(player, {
        generals = generals,
        n = 1,
        no_convert = true
      })]
      room:setPlayerMark(player, "@os__fuhan", general.name)
      local skills = general:getSkillNameList(player.role == "lord" and #room.players > 4)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, false)
      local maxHp = math.min(math.max(num, 2), 8)
      room:changeMaxHp(player, maxHp - player.maxHp)
      room:recover({ who = player, num = 1, skillName = os__fuhan.name })
    end
    if player:hasSkill("os__queshi") then
      local cardId = U.prepareDeriveCards(room, {{"moon_spear", Card.Diamond, 12}}, "os__queshi_spear")[1]
      if table.contains({Card.PlayerEquip, Card.PlayerJudge, Card.DiscardPile, Card.DrawPile, Card.Void}, room:getCardArea(cardId)) then
        room:obtainCard(player, cardId, true, fk.ReasonPrey)
      end
    end
  end,
})

return os__fuhan

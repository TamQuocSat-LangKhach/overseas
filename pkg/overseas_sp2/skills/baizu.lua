local baizu = fk.CreateSkill {
  name = "os__baizu"
}

Fk:loadTranslationTable{
  ['os__baizu'] = '败族',
  ['@os__baizu'] = '败族',
  ['#os__baizu-ask'] = '败族：选择 %arg 名其他角色，你和这些角色各弃置一张手牌',
  [':os__baizu'] = '锁定技，结束阶段，若你已受伤且有手牌，你须选择X名其他角色，令你与这些角色同时弃置一张手牌，然后你对弃置与你相同类型牌的其他角色造成1点伤害（X为你的体力值）。<a href=>历战</a>：X+1。',
  ['$os__baizu1'] = '今袁氏之势，岂独因我？',
  ['$os__baizu2'] = '长幼之序不明，何惜操戈以正！',
}

baizu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player == target and target:hasSkill(skill.name) and player.phase == Player.Finish
      and player:isWounded() and not player:isKongcheng()
      and (player.hp + player:getMark("@os__baizu")) > 0
      and table.find(player.room.alive_players, function(p)
        return p ~= player and not p:isKongcheng()
      end)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local x = player.hp + player:getMark("@os__baizu")
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p ~= player and not p:isKongcheng()
    end), Util.IdMapper)
    if #targets > x then
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = x,
        max_num = x,
        prompt = "#os__baizu-ask:::" .. x,
        skill_name = skill.name,
        cancelable = false,
      })
    else
      room:doIndicate(player.id, targets)
    end
    table.insert(targets, player.id)
    targets = table.map(targets, Util.Id2PlayerMapper)
    local cardsMap = U.askForJointCard(targets, 1, 1, false, skill.name, false, nil, "#AskForDiscard:::1:1", nil, true)
    local moveInfos = {}
    local victims = {}
    local cardType = #cardsMap[player.id] > 0 and Fk:getCardById(cardsMap[player.id][1]).type or 0
    for _, p in ipairs(targets) do
      local throw = cardsMap[p.id]
      if #throw > 0 then
        if p ~= player and Fk:getCardById(throw[1]).type == cardType then
          table.insert(victims, p.id)
        end
        table.insert(moveInfos, {
          ids = throw,
          from = p.id,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonDiscard,
          proposer = p.id,
          skillName = skill.name,
        })
      end
    end
    if #moveInfos == 0 then return false end
    room:moveCards(table.unpack(moveInfos))
    if #victims == 0 then return false end
    room:sortPlayersByAction(victims)
    for _, pid in ipairs(victims) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = skill.name,
        }
      end
    end
  end,
})

baizu:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player)
    return player == target and player:hasSkill(skill.name) and player:usedSkillTimes(baizu.name) > 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:addPlayerMark(player, "@os__baizu")
  end,
})

baizu:on_lose(function (skill, player)
  player.room:setPlayerMark(player, "@os__baizu", 0)
end)

return baizu

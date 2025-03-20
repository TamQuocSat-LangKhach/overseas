local os__qingtao = fk.CreateSkill {
  name = "os__qingtao"
}

Fk:loadTranslationTable{
  ['os__qingtao'] = '清滔',
  ['#os__qingtao-ask'] = '清滔：你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌',
  [':os__qingtao'] = '摸牌阶段结束时，你可重铸一张牌，然后若此牌为【酒】或非基本牌，你摸一张牌。若你未发动此技能，你可于此回合的结束阶段开始时发动此技能。',
  ['$os__qingtao1'] = '君子当如滔流，循道而不失其行。',
  ['$os__qingtao2'] = '探赜索隐，钩深致远。日月在躬，隐之弥曜。',
}

os__qingtao:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__qingtao) and (event == fk.EventPhaseStart and player.phase == Player.Finish and player:getMark("_os__qingtao_invoked-turn") == 0)
  end,
  on_cost = function(self, event, target, player)
    local id = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = os__qingtao.name,
      prompt = "#os__qingtao-ask",
      cancelable = true
    })
    if #id > 0 then
      event:setCostData(self, id)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:recastCard(event:getCostData(self)[1], player, os__qingtao.name)
    if not player.dead then
      local card = Fk:getCardById(event:getCostData(self)[1])
      if card.name == "analeptic" or card.type ~= Card.TypeBasic then
        player:drawCards(1, os__qingtao.name)
      end
      room:setPlayerMark(player, "_os__qingtao_invoked-turn", 1)
    end
  end,
})

os__qingtao:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__qingtao) and (event == fk.EventPhaseEnd and player.phase == Player.Draw)
  end,
  on_cost = function(self, event, target, player)
    local id = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      skill_name = os__qingtao.name,
      prompt = "#os__qingtao-ask",
      cancelable = true
    })
    if #id > 0 then
      event:setCostData(self, id)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:recastCard(event:getCostData(self)[1], player, os__qingtao.name)
    if not player.dead then
      local card = Fk:getCardById(event:getCostData(self)[1])
      if card.name == "analeptic" or card.type ~= Card.TypeBasic then
        player:drawCards(1, os__qingtao.name)
      end
      room:setPlayerMark(player, "_os__qingtao_invoked-turn", 1)
    end
  end,
})

return os__qingtao

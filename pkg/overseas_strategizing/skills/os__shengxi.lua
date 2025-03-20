local os__shengxi = fk.CreateSkill {
  name = "os__shengxi"
}

Fk:loadTranslationTable{
  ['os__shengxi'] = '生息',
  ['#os__shengxi-ask'] = '生息：你可选择一种智囊，从牌堆中获得之并摸一张牌',
  [':os__shengxi'] = '①准备阶段开始时，你可获得一张<a href=>【调剂盐梅】</a>。②结束阶段开始时，若你于此回合内使用过牌且没有造成过伤害，你可从牌堆中获得一张你指定的<a href=>智囊</a>并摸一张牌。',
  ['$os__shengxi1'] = '利治小之宜，秉居静之理。',
  ['$os__shengxi2'] = '外却骆谷之师，内保宁缉之实。',
}

os__shengxi:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player)
    if player == target and player:hasSkill(skill.name) then
      if player.phase == Player.Start then return true end
      if player.phase == Player.Finish then
        return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
          return e.data[1].from == player.id
        end, Player.HistoryTurn) > 0 and
          #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == player end) == 0
      end
    end
  end,
  on_cost = function(self, event, target, player)
    if player.phase == Player.Start then
      return player.room:askToSkillInvoke(player, { skill_name = skill.name })
    else
      local choice = player.room:askToChoice(player, {
        choices = {"dismantlement", "nullification", "ex_nihilo", "Cancel"},
        skill_name = skill.name,
        prompt = "#os__shengxi-ask"
      })
      if choice ~= "Cancel" then
        event:setCostData(skill, choice)
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player.phase == Player.Start then
      local get = nil
      local shengxi_derivecards = { {"redistribute", Card.Spade, 6}, {"redistribute", Card.Club, 6}, {"redistribute", Card.Heart, 6}, {"redistribute", Card.Diamond, 6} }
      local cards = table.filter(U.prepareDeriveCards(room, shengxi_derivecards, "shengxi_derivecards"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #cards > 0 then
        get = table.random(cards)
      else
        local cids = room:getCardsFromPileByRule("redistribute")
        if #cids > 0 then get = cids[1] end
      end
      if get then
        room:obtainCard(player, get, true, fk.ReasonPrey, player.id, skill.name, MarkEnum.DestructIntoDiscard)
      end
    else
      local id = room:getCardsFromPileByRule(event:getCostData(skill))
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey, player.id, skill.name)
      end
      if not player.dead then player:drawCards(1, skill.name) end
    end
  end,
})

return os__shengxi

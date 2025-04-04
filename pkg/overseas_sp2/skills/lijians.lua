local lijians = fk.CreateSkill {
  name = "os__lijians",
}

Fk:loadTranslationTable{
  ['os__lijians'] = '力谏',
  ['@os__lijians'] = '力谏',
  ['#os__lijians-invoke'] = '力谏：你可获得任意张此阶段因弃置而移至弃牌堆里的牌，然后将其余牌交给 %dest',
  ['os__lijians_all_get'] = '获得所有牌',
  ['os__lijians_get'] = '获得选中牌，其余交还',
  ['os__lijians_back'] = '交还选中牌，其余获得',
  ['#os__lijian-cards'] = '力谏：你可获得任意张此阶段因弃置而移至弃牌堆里的牌，将其余牌交给%dest',
  ['os__lijians_all_back'] = '交还所有牌',
  ['#os__lijian-card'] = '力谏：你可获得此牌或交给 %dest',
  [':os__lijians'] = '<a href=>昂扬技</a>，其他角色的弃牌阶段结束时，你可获得任意张此阶段因弃置而移至弃牌堆里的牌，然后将其余牌交给其，若其获得的牌数大于你，则你对其造成1点伤害。<a href=>激昂</a>：八张牌进入弃牌堆。',
  ['$os__lijians1'] = '陛下欲复昔日桓公之事乎？',
  ['$os__lijians2'] = '君者当御贤于后，安可校勇于猛兽！',
}

lijians:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(lijians.name) or target.phase ~= Player.Discard or target == player or player:getMark("@os__lijians") ~= 0 then return false end
    local room = player.room
    return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if room:getCardArea(info.cardId) == Card.DiscardPile then
              return true
            end
          end
        end
      end
      return false
    end, Player.HistoryPhase) > 0
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local cards = {}
    room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            local id = info.cardId
            if room:getCardArea(id) == Card.DiscardPile then
              table.insertIfNeed(cards, id)
            end
          end
        end
      end
      return false
    end, Player.HistoryPhase)
    if #cards == 0 then return end
    local skill_name = lijians.name
    local prompt = "#os__lijians-invoke::" .. target.id
    if room:askToSkillInvoke(player, {skill_name = skill_name, prompt = prompt}) then
      room:doIndicate(player.id, {target.id})
      event:setCostData(self, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = event:getCostData(self)
    room:setPlayerMark(player, "@os__lijians", 8)
    local to_get, cids, to_back = {}, {}, {}
    local choice = "os__lijians_all_get"
    if #cards > 1 then
      cids, choice = U.askforChooseCardsAndChoice(player, cards, {"os__lijians_get", "os__lijians_back"}, lijians.name,
        "#os__lijian-cards::" .. target.id, {"os__lijians_all_get", "os__lijians_all_back"}, 0, #cards)
    else
      choice = U.askforViewCardsAndChoice(player, cards, {"os__lijians_all_get", "os__lijians_all_back"}, lijians.name, "#os__lijian-card::" .. target.id)
    end
    if choice == "os__lijians_all_get" then
      to_get = cards
    elseif choice == "os__lijians_back" then
      to_back = cids
      local tmp = table.simpleClone(cards)
      for _, c in ipairs(cids) do
        table.removeOne(tmp, c)
      end
      to_get = tmp
    elseif choice == "os__lijians_all_back" then
      to_back = cards
    elseif choice == "os__lijians_get" then
      to_get = cids
      local tmp = table.simpleClone(cards)
      for _, c in ipairs(cids) do
        table.removeOne(tmp, c)
      end
      to_back = tmp
    end
    if #to_get > 0 then
      room:obtainCard(player, to_get, true, fk.ReasonJustMove, player.id)
    end
    if #to_back > 0 and not target.dead then
      room:moveCardTo(to_back, Card.PlayerHand, target, fk.ReasonGive, lijians.name, nil, true, player.id)
    end
    if target.dead or player.dead then return end
    if #to_back > #to_get then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = lijians.name,
      }
    end
  end,
})

lijians:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(lijians.name) and player:getMark("@os__lijians") > 0 and table.find(target.data, function(move) return move.toArea == Card.DiscardPile end)
  end,
  on_use = function(self, event, target, player)
    local num = player:getMark("@os__lijians")
    for _, move in ipairs(target.data) do
      if move.toArea == Card.DiscardPile then
        num = num - #move.moveInfo
      end
    end
    player.room:setPlayerMark(player, "@os__lijians", math.max(num, 0))
  end,
})

lijians:on_lose(function(self, player, is_death)
  player.room:setPlayerMark(player, "@os__lijians", 0)
end)

return lijians

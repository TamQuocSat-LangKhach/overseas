local os__shelie = fk.CreateSkill {
  name = "os__shelie"
}

Fk:loadTranslationTable{
  ['os__shelie'] = '涉猎',
  ['#os__shelie_extra'] = '涉猎',
  ['@os__shelie-turn'] = '涉猎',
  ['#os__shelie_extra-ask'] = '涉猎：选择执行一个额外的阶段',
  ['#os__shelie_extra_log'] = '%from 发动“%arg”，执行一个额外的 %arg2',
  [':os__shelie'] = '①摸牌阶段，你可改为亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张。②每轮限一次，结束阶段开始时，若你本回合使用过四种花色的牌，你选择执行一个额外的摸牌阶段或出牌阶段且不能与上次选择相同。',
  ['$os__shelie1'] = '尘世之间，岂有吾所未闻之事？',
  ['$os__shelie2'] = '往事皆知，未来尽料。',
}

os__shelie:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__shelie) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = room:getNCards(5)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
      skillName = os__shelie.name,
      proposer = player.id,
    })
    local get = {}
    for _, id in ipairs(cards) do
      local suit = Fk:getCardById(id).suit
      if table.every(get, function (id2)
        return Fk:getCardById(id2).suit ~= suit
      end) then
        table.insert(get, id)
      end
    end
    get = room:askToArrangeCards(player, {
      skill_name = os__shelie.name,
      card_map = cards,
      prompt = "#shelie-choose",
      box_size = 0,
      max_limit = {5, 4},
      min_limit = {0, #get},
      pattern = ".",
      poxi_type = "shelie"
    })[2]
    if #get > 0 then
      room:moveCardTo(get, Player.Hand, player, fk.ReasonPrey, os__shelie.name, nil, true, player.id)
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
    return true
  end,
})

os__shelie:addEffect(fk.EventPhaseStart, {
  name = "#os__shelie_extra",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__shelie) and player.phase == Player.Finish and type(player:getMark("@os__shelie-turn")) == "table" and #player:getMark("@os__shelie-turn") == 4 and player:usedSkillTimes(os__shelie.name, Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player)
    local choices = {"phase_draw", "phase_play"}
    if player:getMark("_os__shelie") ~= 0 then
      table.removeOne(choices, player:getMark("_os__shelie"))
    end
    event:setCostData(self, player.room:askToChoice(player, {
      choices = choices,
      skill_name = os__shelie.name,
      prompt = "#os__shelie_extra-ask"
    }))
    return true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:sendLog{
      type = "#os__shelie_extra_log",
      from = player.id,
      arg = os__shelie.name,
      arg2 = event:getCostData(self),
    }
    room:setPlayerMark(player, "_os__shelie", event:getCostData(self))
    player:gainAnExtraPhase(event:getCostData(self) == "phase_draw" and Player.Draw or Player.Play)
  end,

  can_refresh = function(self, event, target, player)
    return target == player and player:hasSkill(os__shelie, true) and player.phase ~= Player.NotActive and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player)
    local suitsRecorded = player:getTableMark("@os__shelie-turn")
    table.insertIfNeed(suitsRecorded, data.card:getSuitString(true))
    player.room:setPlayerMark(player, "@os__shelie-turn", suitsRecorded)
  end,

  on_acquire = function (self, player, is_start)
    if player.phase ~= Player.NotActive then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event then
        local suitsRecorded = player:getTableMark("@os__shelie-turn")
        local use
        room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
          use = e.data[1]
          if use.from == player.id then
            table.insertIfNeed(suitsRecorded, use.card:getSuitString(true))
          end
          return false
        end, turn_event.id)
        room:setPlayerMark(player, "@os__shelie-turn", suitsRecorded)
      end
    end
  end,
})

return os__shelie

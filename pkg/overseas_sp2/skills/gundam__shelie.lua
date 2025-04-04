local gundam__shelie = fk.CreateSkill {
  name = "gundam__shelie"
}

Fk:loadTranslationTable{
  ['gundam__shelie'] = '涉猎',
  ['#gundam__shelie_extra'] = '涉猎',
  ['@gundam__shelie-turn'] = '涉猎',
  ['#gundam__shelie_extra-ask'] = '涉猎：选择执行一个额外的阶段',
  ['#gundam__shelie_extra_log'] = '%from 发动“%arg”，执行一个额外的 %arg2',
  [':gundam__shelie'] = '摸牌阶段，你可改为亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张。每轮限一次，结束阶段开始时，若你本回合使用牌花色数不小于你的体力值，你选择执行一个额外的摸牌阶段或出牌阶段。',
  ['$gundam__shelie1'] = '尘世之间，岂有吾所未闻之事？',
  ['$gundam__shelie2'] = '往事皆知，未来尽料。',
}

-- 主技能效果
gundam__shelie:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(gundam__shelie) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = room:getNCards(5)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
      skillName = gundam__shelie.name,
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
      skill_name = gundam__shelie.name,
      card_map = cards,
      prompt = "#shelie-choose",
      box_size = 0,
      max_limit = {5, 4},
      min_limit = {0, #get},
      pattern = ".",
      poxi_type = "shelie",
      default_choice = {{}, get}
    })[2]
    if #get > 0 then
      room:moveCardTo(get, Player.Hand, player, fk.ReasonPrey, gundam__shelie.name, nil, true, player.id)
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

-- 额外效果
gundam__shelie:addEffect(fk.EventPhaseStart, {
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(gundam__shelie) and player.phase == Player.Finish and #player:getTableMark("@gundam__shelie-turn") >= player.hp and player:usedSkillTimes("#gundam__shelie_extra", Player.HistoryRound) < 1
  end,
  on_cost = function(self, event, target, player)
    event:setCostData(skill, player.room:askToChoice(player, {
      choices = {"phase_draw", "phase_play"},
      prompt = "#gundam__shelie_extra",
      skill_name = "#gundam__shelie_extra-ask"
    }))
    return true
  end,
  on_use = function(self, event, target, player)
    local cost_data = event:getCostData(skill)
    player.room:sendLog{
      type = "#gundam__shelie_extra_log",
      from = player.id,
      arg = gundam__shelie.name,
      arg2 = cost_data,
    }
    player:gainAnExtraPhase(cost_data == "phase_draw" and Player.Draw or Player.Play)
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player)
    return target == player and player:hasSkill(gundam__shelie, true) and player.phase ~= Player.NotActive and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function(self, event, target, player)
    local suitsRecorded = player:getTableMark("@gundam__shelie-turn")
    table.insertIfNeed(suitsRecorded, data.card:getSuitString(true))
    player.room:setPlayerMark(player, "@gundam__shelie-turn", suitsRecorded)
  end,

  on_acquire = function (skill, player, is_start)
    if player.phase ~= Player.NotActive then
      local room = player.room
      local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      if turn_event then
        local suitsRecorded = player:getTableMark("@gundam__shelie-turn")
        local use
        room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
          use = e.data[1]
          if use.from == player.id then
            table.insertIfNeed(suitsRecorded, use.card:getSuitString(true))
          end
          return false
        end, turn_event.id)
        room:setPlayerMark(player, "@gundam__shelie-turn", suitsRecorded)
      end
    end
  end,
})

return gundam__shelie

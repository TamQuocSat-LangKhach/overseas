local osBeiding = fk.CreateSkill {
  name = "os__beiding"
}

Fk:loadTranslationTable{
  ['os__beiding'] = '北定',
  ['@$os__beiding_names'] = '北定',
  ['#os__beiding-choose'] = '北定：请选择至多%arg种牌名记录，你于此回合弃牌阶段结束时按顺序依次使用',
  ['#os__beiding-replace'] = '北定：请为牌名【%arg】替换具体牌名',
  ['os_huan__beiding'] = '北定',
  ['@@os__beiding_card-inhand'] = '北定',
  ['#os__beiding_use'] = '北定',
  ['#os__beiding-use'] = '北定：请视为使用【%arg】',
  [':os__beiding'] = '一名角色的准备阶段开始时，你可以声明并记录至多X种未被〖北定〗记录过的基本牌或普通锦囊牌牌名。若如此做，此回合的弃牌阶段结束时，你视为依次使用本回合记录的牌（无距离限制），若此牌的目标不包含当前回合角色，其摸一张牌（X为你的体力值）。',
  ['$os__beiding1'] = '众将同心扶汉，北伐或可功成。',
  ['$os__beiding2'] = '虽失天时地利，亦有三分胜机！',
}

osBeiding:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player)
    return target.phase == Player.Start and player:hasSkill(osBeiding.name) and player.hp > 0
  end,
  on_cost = function (self, event, target, player)
    local cardNames = U.getAllCardNames("bt")
    cardNames = table.filter(
      cardNames,
      function(name) return not table.contains(player:getTableMark("@$os__beiding_names"), name) end
    )

    local realNameMapper = {}
    for _, cardName in ipairs(cardNames) do
      local realNames = table.filter(cardNames, function(name) return name:endsWith("__" .. cardName) end)
      if #realNames > 0 then
        realNameMapper[cardName] = realNames
      end
    end
    cardNames = table.filter(cardNames, function(name) return #name:split("__") == 1 end)

    if #cardNames == 0 then
      return false
    end

    local room = player.room
    local namesChosen = room:askToChoices(player, {
      choices = cardNames,
      min_num = 1,
      max_num = player.hp,
      skill_name = osBeiding.name,
      prompt = "#os__beiding-choose:::" .. player.hp
    })
    if #namesChosen == 0 then
      return false
    end

    for _, cardName in ipairs(namesChosen) do
      local realNames = realNameMapper[cardName]
      if realNames then
        table.insert(realNames, 1, cardName)
        local name = room:askToChoice(player, {
          choices = realNames,
          skill_name = osBeiding.name,
          prompt = "#os__beiding-replace:::" .. cardName
        })
        local index = table.indexOf(namesChosen, cardName)
        table.remove(namesChosen, index)
        table.insert(namesChosen, index, name)
      end
    end

    event:setCostData(self, namesChosen)
    return true
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    local namesChosen = event:getCostData(self)

    local namesChosenThisTurn = player:getTableMark("os__beiding_names-turn")
    table.insertTable(namesChosenThisTurn, namesChosen)
    room:setPlayerMark(player, "os__beiding_names-turn", namesChosenThisTurn)

    namesChosen = table.map(namesChosen, function(name)
      local realName = name:split("__")
      return realName[#realName]
    end)
    local beidingNames = player:getTableMark("@$os__beiding_names")
    table.insertTable(beidingNames, namesChosen)
    room:setPlayerMark(player, "@$os__beiding_names", beidingNames)

    if player:hasSkill("os_huan__beiding", true) then
      for _, id in ipairs(player:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if table.contains(beidingNames, card.trueName) and card:getMark("@@os__beiding_card-inhand") ~= 1 then
          room:setCardMark(card, "@@os__beiding_card-inhand", 1)
        end
      end
    end
  end
})

osBeiding:addEffect(fk.EventPhaseEnd, {
  can_trigger = function (self, event, target, player)
    return target.phase == Player.Discard and player:getMark("os__beiding_names-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player)
    local room = player.room
    local namesChosenThisTurn = player:getTableMark("os__beiding_names-turn")
    for _, name in ipairs(namesChosenThisTurn) do
      if not player:isAlive() then
        break
      end

      -- 牌名彩蛋
      local names = {"fire_attack", "fire__slash", "nullification"}
      if table.contains(names, name) then
        player:broadcastSkillInvoke("os__beiding_names", table.indexOf(names, name))
      end

      local use = U.askForUseVirtualCard(room, player, name, nil, osBeiding.name, "#os__beiding-use:::" .. name, false, true, true)
      if use and not table.contains(TargetGroup:getRealTargets(use.tos), target.id) and not target.dead then
        target:drawCards(1, osBeiding.name)
      end
    end
  end
})

return osBeiding

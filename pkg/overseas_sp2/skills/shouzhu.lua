local shouzhu = fk.CreateSkill {
  name = "os__shouzhu"
}

Fk:loadTranslationTable{
  ['os__shouzhu'] = '受嘱',
  ['#os__shouzhu-ask'] = '你可选择一名其他角色成为你的 受嘱 同心角色',
  ['#os__shouzhu-give'] = '受嘱：你可交给 %src 至多四张牌，若不少于两张，你摸一张牌，然后与其一起执行同心',
  ['@os__shouzhu'] = '受嘱同心',
  ['#os__shouzhu'] = '受嘱：将任意张牌置于牌堆底，将其余牌置入弃牌堆',
  [':os__shouzhu'] = '出牌阶段开始时，你的<a href=>同心角色</a>可至多交给你四张牌，若X不小于2，则其摸一张牌，然后执行<a href=>同心效果</a>：观看牌堆顶X张牌，然后将其中任意张牌置于牌堆底，将其余牌置入弃牌堆。（X为你本次以此法获得牌的数量）',
  ['$os__shouzhu1'] = '临别教诲，均谨记在心。',
  ['$os__shouzhu2'] = '兄长此去，恰如龙入青天。',
}

shouzhu:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(shouzhu.name) 
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__shouzhu-ask",
      skill_name = shouzhu.name
    })
    if #targets > 0 then
      event:setCostData(skill, targets[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = event:getCostData(skill)
    room:setPlayerMark(player, "@os__shouzhu", room:getPlayerById(to).general)
    room:setPlayerMark(player, "_os__shouzhu", to)
  end,
})

shouzhu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(shouzhu.name) and (player.phase == Player.Play and player:getMark("_os__shouzhu") ~= 0)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local cards = room:askToCards(room:getPlayerById(player:getMark("_os__shouzhu")), {
      min_num = 1,
      max_num = 4,
      include_equip = true,
      skill_name = shouzhu.name,
      prompt = "#os__shouzhu-give:" .. player.id
    })
    if #cards > 0 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = event:getCostData(skill)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, shouzhu.name, nil, false, player.id)
    local num = #cards
    if num > 1 then
      local companion = room:getPlayerById(player:getMark("_os__shouzhu"))
      if not companion.dead then
        companion:drawCards(1, shouzhu.name)
      end
      for _, p in ipairs{player, companion} do
        if not p.dead then
          local ret = room:askToGuanxing(p, {
            cards = room:getNCards(num),
            top_limit = {num, num},
            bottom_limit = {0, 0},
            skill_name = shouzhu.name,
            title = "#os__shouzhu",
            skip = true
          })
          local discard, bottom = ret["pile_discard"], ret["bottom"]
          room:moveCardTo(discard, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, shouzhu.name, nil, true, p.id)
          for i = 1, #bottom do
            table.removeOne(room.draw_pile, bottom[i])
            table.insert(room.draw_pile, bottom[i])
          end
          room:sendLog{
            type = "#GuanxingResult",
            from = p.id,
            arg = 0,
            arg2 = #bottom,
          }
        end
      end
    end
  end,
})

shouzhu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("_os__shouzhu") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "_os__shouzhu", 0)
    player.room:setPlayerMark(player, "@os__shouzhu", 0)
  end,
})

return shouzhu

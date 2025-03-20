local os__miaolue = fk.CreateSkill {
  name = "os__miaolue"
}

Fk:loadTranslationTable{
  ['os__miaolue'] = '妙略',
  ['os__miaolue_underhanding'] = '获得一张【瞒天过海】并摸一张牌',
  ['os__miaolue_zhinang'] = '从牌堆或弃牌堆获得一张你指定的智囊',
  ['#os__miaolue-ask'] = '妙略：选择一种“智囊”，从牌堆或弃牌堆获得一张',
  [':os__miaolue'] = '游戏开始时，你获得两张<a href=>【瞒天过海】</a>；当你受到1点伤害后，你可选择：1. 获得一张<a href=>【瞒天过海】</a>并摸一张牌；2. 从牌堆或弃牌堆获得一张你指定的<a href=>智囊</a>。',
  ['$os__miaolue1'] = '智者通权达变，以解临近之难。',
  ['$os__miaolue2'] = '依吾计而行，此患乃除耳。',
}

os__miaolue:addEffect(fk.GameStart, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__miaolue) then return false end
    return event == fk.GameStart or (target == player and not player.dead)
  end,
  on_trigger = function(self, event, target, player)
    self:doCost(event, target, player)
  end,
  on_cost = function(self, event, target, player)
    if event == fk.GameStart then
      return true
    else
      local choice = player.room:askToChoice(player, {
        choices = {"os__miaolue_underhanding", "os__miaolue_zhinang", "Cancel"},
        skill_name = os__miaolue.name,
      })
      if choice ~= "Cancel" then
        event:setCostData(self, choice)
        return true
      end
      self.cancel_cost = true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local miaolue_derivecards = { {"underhanding", Card.Spade, 5}, {"underhanding", Card.Club, 5},
      {"underhanding", Card.Heart, 5}, {"underhanding", Card.Diamond, 5} }
    if event == fk.GameStart then
      local cids = table.filter(U.prepareDeriveCards(room, miaolue_derivecards, "os__miaolue_derivecards"), function (id)
        return room:getCardArea(id) == Card.Void
      end)
      if #cids > 0 then
        room:obtainCard(player, table.random(cids, 2), false, fk.ReasonPrey, player.id, os__miaolue.name, MarkEnum.DestructIntoDiscard)
      end
    else
      local cost_data = event:getCostData(self)
      if cost_data == "os__miaolue_underhanding" then
        local id
        local cids = U.prepareDeriveCards(room, miaolue_derivecards, "os__miaolue_derivecards")
        for _, cid in ipairs(cids) do
          if room:getCardArea(cid) == Card.Void then --优先拿游戏外的
            id = cid
            break
          end
        end
        if not id then
          for _, cid in ipairs(cids) do
            if room:getCardArea(cid) == Card.DrawPile then --再拿牌堆里的
              id = cid
              break
            end
          end
        end
        if id then
          room:obtainCard(player, id, false, fk.ReasonPrey, player.id, os__miaolue.name, MarkEnum.DestructIntoDiscard)
        end
        player:drawCards(1, os__miaolue.name)
      else
        local choice = room:askToChoice(player, {
          choices = {"dismantlement", "nullification", "ex_nihilo"},
          skill_name = os__miaolue.name,
          prompt = "#os__miaolue-ask",
        })
        local id = room:getCardsFromPileByRule(choice, 1, "allPiles")
        if #id > 0 then
          room:obtainCard(player, id[1], false, fk.ReasonPrey)
        end
      end
    end
  end,
})

os__miaolue:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__miaolue) then return false end
    return target == player and not player.dead
  end,
  on_trigger = function(self, event, target, player)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost then break end
      self:doCost(event, target, player)
    end
  end,
  on_cost = function(self, event, target, player)
    local choice = player.room:askToChoice(player, {
      choices = {"os__miaolue_underhanding", "os__miaolue_zhinang", "Cancel"},
      skill_name = os__miaolue.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local miaolue_derivecards = { {"underhanding", Card.Spade, 5}, {"underhanding", Card.Club, 5},
      {"underhanding", Card.Heart, 5}, {"underhanding", Card.Diamond, 5} }
    local cost_data = event:getCostData(self)
    if cost_data == "os__miaolue_underhanding" then
      local id
      local cids = U.prepareDeriveCards(room, miaolue_derivecards, "os__miaolue_derivecards")
      for _, cid in ipairs(cids) do
        if room:getCardArea(cid) == Card.Void then --优先拿游戏外的
          id = cid
          break
        end
      end
      if not id then
        for _, cid in ipairs(cids) do
          if room:getCardArea(cid) == Card.DrawPile then --再拿牌堆里的
            id = cid
            break
          end
        end
      end
      if id then
        room:obtainCard(player, id, false, fk.ReasonPrey, player.id, os__miaolue.name, MarkEnum.DestructIntoDiscard)
      end
      player:drawCards(1, os__miaolue.name)
    else
      local choice = room:askToChoice(player, {
        choices = {"dismantlement", "nullification", "ex_nihilo"},
        skill_name = os__miaolue.name,
        prompt = "#os__miaolue-ask",
      })
      local id = room:getCardsFromPileByRule(choice, 1, "allPiles")
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey)
      end
    end
  end,
})

return os__miaolue

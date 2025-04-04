local os__danfa = fk.CreateSkill {
  name = "os__danfa"
}

Fk:loadTranslationTable{
  ['os__danfa'] = '丹法',
  ['@os__danfa-turn'] = '丹法',
  ['os__cinnabar'] = '丹',
  ['#os__danfa-put'] = '丹法：你可将一张牌置于你的武将牌上，称为“丹”',
  [':os__danfa'] = '①准备阶段或结束阶段开始时，你可将一张牌置于你的武将牌上，称为“丹”。②每回合每种花色限一次，当你使用与一张“丹”相同花色的牌时，你摸一张牌。',
  ['$os__danfa1'] = '取五灵三使之药，炼九光七曜之丹。',
  ['$os__danfa2'] = '云液踊跃成雪霜，流珠之英能延年。',
}

os__danfa:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if (target ~= player or not player:hasSkill(os__danfa)) then return false end
    return (player.phase == Player.Start or player.phase == Player.Finish) and not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local id = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__danfa.name,
      cancelable = true,
      prompt = "#os__danfa-put",
    })
    if #id > 0 then
      event:setCostData(self, id[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local cost_data = event:getCostData(self)
    player:addToPile("os__cinnabar", cost_data, true, os__danfa.name)
  end,
})

os__danfa:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if (target ~= player or not player:hasSkill(os__danfa)) then return false end
    local suitsRecorded = player:getTableMark("@os__danfa-turn")
    local os__cinnabar = table.map(player:getPile("os__cinnabar"), function(cid) return Fk:getCardById(cid):getSuitString() end)
    local suit = data.card:getSuitString()
    return not table.contains(suitsRecorded, "log_" .. suit) and table.contains(os__cinnabar, suit)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, os__danfa.name)
    if player:isAlive() then
      player.room:addTableMark(player, "@os__danfa-turn", "log_" .. data.card:getSuitString())
    end
  end,
})

return os__danfa

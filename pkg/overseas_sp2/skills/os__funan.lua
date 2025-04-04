local os__funan = fk.CreateSkill {
  name = "os__funan"
}

Fk:loadTranslationTable{
  ['os__funan'] = '复难',
  ['@@os__funan_update'] = '复难2级',
  [':os__funan'] = '1级：其他角色响应你使用的牌时，你可令其获得你使用的牌，其本回合不能使用或打出之，然后你获得其使用或打出的牌。<br/>2级：其他角色响应你使用的牌时，你可获得其使用或打出的牌。',
  ['$os__funan1'] = '礼尚往来，乃君子风范。',
  ['$os__funan2'] = '以子之矛，攻子之盾。',
}

os__funan:addEffect(fk.CardUseFinished, {
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__funan.name) and data.responseToEvent and data.responseToEvent.from == player.id and target ~= player and
      ((event == fk.CardUseFinished and data.toCard) or
      (event == fk.CardRespondFinished)) and 
      ((player:getMark("@@os__funan_update") == 0 and data.responseToEvent.card and player.room:getCardArea(data.responseToEvent.card) == Card.Processing) or 
      (player:getMark("@@os__funan_update") > 0 and data.card))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@os__funan_update") == 0 then
      local card = data.responseToEvent.card
      room:obtainCard(target, card, false, fk.ReasonPrey)
      local cidsRecorded = target:getTableMark("_os__funan-turn")
      table.insertTable(cidsRecorded, card:isVirtual() and card.subcards or {card.id})
      room:setPlayerMark(target, "_os__funan-turn", cidsRecorded)
    end
    if data.card and player:isAlive() then
      room:obtainCard(player, data.card, false, fk.ReasonPrey)
    end
  end,
})

os__funan:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    if type(player:getMark("_os__funan-turn")) == "table" then return table.contains(player:getMark("_os__funan-turn"), card.id) end
  end,
  prohibit_response = function(self, player, card)
    if type(player:getMark("_os__funan-turn")) == "table" then return table.contains(player:getMark("_os__funan-turn"), card.id) end
  end,
})

return os__funan

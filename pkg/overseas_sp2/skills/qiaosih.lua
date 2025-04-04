local qiaosih = fk.CreateSkill {
  name = "os__qiaosih"
}

Fk:loadTranslationTable{
  ['os__qiaosih'] = '峭嗣',
  [':os__qiaosih'] = '结束阶段，你可获得其他角色本回合进入弃牌堆的牌，然后若你以此法获得牌的数量小于X，你失去1点体力（X为你的体力值）。',
  ['$os__qiaosih1'] = '身居长位，犹处峭崖之巅。',
  ['$os__qiaosih2'] = '为长而不得承嗣，岂有善终乎？',
}

qiaosih:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if not (player == target and player:hasSkill(qiaosih.name) and player.phase == Player.Finish) then return end
    local room = player.room
    local ids = table.filter(player:getTableMark("_os__qiaosih-turn"), function(id) return room:getCardArea(id) == Card.DiscardPile end)
    if #ids > 0 then 
      event:setCostData(self, ids)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local ids = event:getCostData(self)
    room:obtainCard(player, ids, true, fk.ReasonPrey, player.id)
    if #ids < player.hp and not player.dead then
      room:loseHp(player, 1, qiaosih.name)
    end
  end,
})

qiaosih:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player)
    return player.room.current == player
  end,
  on_use = function (self, event, target, player)
    local room = player.room
    local record = player:getTableMark("_os__qiaosih-turn")
    for _, move in ipairs(event.data) do
      if move.from and move.from ~= player.id and move.to ~= move.from then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insertIfNeed(record, id)
          end
        end
      end
    end
    room:setPlayerMark(player, "_os__qiaosih-turn", record)
  end,
})

return qiaosih

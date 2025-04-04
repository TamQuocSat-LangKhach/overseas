local os__xingluan = fk.CreateSkill {
  name = "os__xingluan"
}

Fk:loadTranslationTable{
  ['os__xingluan'] = '兴乱',
  ['#os__xingluan-ask'] = '兴乱：选择其中一种类别的牌并分配',
  ['#os__xingluan-give'] = '兴乱：将这些牌分配给任意名角色（每名角色至多三张）',
  [':os__xingluan'] = '结束阶段开始时，你可亮出牌堆顶的六张牌，然后将其中一种类别的牌分配给任意名角色（每名角色至多三张），以此法获得牌数大于0且不小于你的角色各失去1点体力。',
  ['$os__xingluan1'] = '既朝廷不赦，何不反击一搏？',
  ['$os__xingluan2'] = '反扑长安，势要天翻地覆！'
}

os__xingluan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cids = room:getNCards(6)
    room:moveCards({
      ids = cids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = skill.name,
      proposer = player.id,
    })
    if not player.dead then
      local listNames = {"basic", "trick", "equip"}
      local listCards = { {}, {}, {} }
      cids = table.filter(cids, function(id) return room:getCardArea(id) == Card.Processing end)
      for _, cid in ipairs(cids) do
        local cardType = Fk:getCardById(cid).type
        table.insertIfNeed(listCards[cardType], cid)
      end
      local choice = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, skill.name, "#os__xingluan-ask", false, false)
      local cards = listCards[table.indexOf(listNames, choice[1])]
      local move = room:askToYiji(player, {
        cards = cards,
        targets = room:getAlivePlayers(false),
        skill_name = skill.name,
        min_num = #cards,
        max_num = #cards,
        prompt = "#os__xingluan-give",
        expand_pile = cards,
        skip = true,
        single_max = 3
      })
      local num = #move[player.id]
      local victims = {}
      for pid, c in pairs(move) do
        if #c >= num and #c > 0 then
          table.insert(victims, pid)
        end
      end
      room:doYiji(move, player.id, skill.name)
      room:sortPlayersByAction(victims)
      for _, pid in ipairs(victims) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          room:loseHp(p, 1, skill.name)
        end
      end
    end
    room:cleanProcessingArea(cids, skill.name)
  end,
})

return os__xingluan

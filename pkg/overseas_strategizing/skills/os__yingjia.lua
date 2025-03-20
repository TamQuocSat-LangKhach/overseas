local os__yingjia = fk.CreateSkill {
  name = "os__yingjia"
}

Fk:loadTranslationTable{
  ['os__yingjia'] = '迎驾',
  ['#os__yingjia-target'] = '迎驾：你可弃置一张手牌并选择一名角色，其获得一个额外的回合',
  [':os__yingjia'] = '一名角色的回合结束时，若你于此回合内使用过至少两张同名锦囊牌，你可弃置一张手牌并选择一名角色，其获得一个额外的回合。',
  ['$os__yingjia1'] = '行非常之事，乃有非常之功，愿将军三思。',
  ['$os__yingjia2'] = '将军今留匡弼，事势不便，惟移驾幸许耳。',
}

os__yingjia:addEffect(fk.TurnEnd, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__yingjia.name) then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 998, function(e)
      local use = e.data[1]
      return use.from == player.id and use.card.type == Card.TypeTrick
    end, Player.HistoryTurn)
    if #events > 0 then
      local usedCardNames = {}
      table.forEach(events, function(e)
        table.insertIfNeed(usedCardNames, e.data[1].card.name)
      end)
      return #events > #usedCardNames
    end
  end,
  on_cost = function(self, event, target, player)
    local plist, cid = player.room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = table.map(player.room.alive_players, Util.IdMapper),
      pattern = ".|.|.|hand",
      prompt = "#os__yingjia-target",
      skill_name = os__yingjia.name
    })
    if #plist > 0 then
      event:setCostData(skill, {plist[1], cid})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = event:getCostData(skill)[1]
    room:throwCard(event:getCostData(skill)[2], os__yingjia.name, player)
    room:getPlayerById(to):gainAnExtraTurn()
  end
})

return os__yingjia

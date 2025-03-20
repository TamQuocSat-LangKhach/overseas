local os__kaizeng_others = fk.CreateSkill {
  name = "os__kaizeng_others&"
}

Fk:loadTranslationTable{
  ['os__kaizeng_others&'] = '慨赠',
  ['os__kaizeng'] = '慨赠',
  ['#os__kaizeng-give'] = '慨赠：你可交给 %src 任意张手牌',
  [':os__kaizeng_others&'] = '出牌阶段限一次，你可指定一种基本牌牌名或非基本牌类别，令侠鲁肃选择是否交给你任意张手牌。若其交给你多于一张牌，其摸一张牌；若其中包含你指定的牌名/类别的牌，其从牌堆中获得一张不同牌名/类别的牌。',
}

os__kaizeng_others:addEffect('active', {
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(os__kaizeng_others.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  interaction = function(skill)
    local choiceList = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(choiceList, card.trueName) and card.type == Card.TypeBasic and not card.is_derived then
        table.insert(choiceList, card.trueName)
      end
    end
    table.insertTable(choiceList, {"trick", "equip"})
    return UI.ComboBox { choices = choiceList }
  end,
  on_use = function(self, room, effect)
    local choice = skill.interaction.data
    if not choice then choice = "slash" end--return false end
    local player = room:getPlayerById(effect.from)
    local targets = table.filter(room:getOtherPlayers(player, false), function(p) return p:hasSkill("os__kaizeng") and p:usedSkillTimes("os__kaizeng", Player.HistoryPhase) == 0 end)
    if #targets == 0 then return false end
    local to
    if #targets == 1 then
      to = targets[1]
    else
      to = room:getPlayerById(room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        skill_name = os__kaizeng_others.name,
        cancelable = false
      })[1])
    end
    room:doIndicate(player.id, {to.id})
    local cids = room:askToCards(to, {
      min_num = 1,
      max_num = 999,
      include_equip = false,
      skill_name = "os__kaizeng",
      cancelable = true,
      prompt = "#os__kaizeng-give:" .. player.id
    })
    if #cids > 0 then
      to:addSkillUseHistory("os__kaizeng")
      room:notifySkillInvoked(to, "os__kaizeng", "support")
      to:broadcastSkillInvoke("os__kaizeng")
      room:moveCardTo(cids, Player.Hand, player, fk.ReasonGive, os__kaizeng_others.name, nil, true)
      if #cids > 1 then
        to:drawCards(1, "os__kaizeng")
      end
      local CardType = (choice == "trick" or choice == "equip")
      if table.find(table.map(cids, Util.Id2CardMapper), function(card)
        return (CardType and card:getTypeString() == choice or card.trueName == choice)
      end) then
        local id = room:getCardsFromPileByRule(CardType and ".|.|.|.|.|^" .. choice or "^" .. choice .. "|.|.|.|.|basic")
        if #id > 0 then
          room:obtainCard(to, id[1], false, fk.ReasonPrey)
        end
      end
    end
  end,
})

return os__kaizeng_others

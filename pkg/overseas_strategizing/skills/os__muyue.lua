local os__muyue = fk.CreateSkill {
  name = "os__muyue"
}

Fk:loadTranslationTable{
  ['os__muyue'] = '睦约',
  [':os__muyue'] = '出牌阶段限一次，你选择一个基本牌或普通锦囊牌的牌名，弃置一张牌并选择一名角色，令其从牌堆中获得该牌名的牌。若你弃置的牌的牌名与该牌名相同，你下次发动此技能无需弃牌。',
  ['$os__muyue1'] = '歃血盟誓，以告神明。',
}

os__muyue:addEffect('active', {
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:usedSkillTimes(os__muyue.name, Player.HistoryPhase) < 1
  end,
  card_num = function(player)
    return player:getMark("os__muyue_status") + 1
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < player:getMark("os__muyue_status") + 1
  end,
  interaction = function(skill)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.trueName) and (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_derived then
        table.insert(allCardNames, card.trueName)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and skill.interaction.data
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local name = skill.interaction.data
    if not name then return false end
    if #effect.cards > 0 and Fk:getCardById(effect.cards[1]).trueName == name then 
      room:setPlayerMark(player, "os__muyue_status", -1)
    else
      room:setPlayerMark(player, "os__muyue_status", 0)
    end
    room:throwCard(effect.cards, os__muyue.name, player)
    local id = room:getCardsFromPileByRule(name)
    if #id > 0 then
      room:obtainCard(target, id[1], false, fk.ReasonPrey)
    end
  end,
})

return os__muyue
  ```


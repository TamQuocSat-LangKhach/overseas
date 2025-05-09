local os__jichou = fk.CreateSkill {
  name = "os__jichou"
}

Fk:loadTranslationTable{
  ['os__jichou'] = '急筹',
  ['#os__jichou'] = '急筹：你可视为使用一种普通锦囊牌，然后本局游戏你无法以此法或自手牌中使用此牌名的牌，且不可响应此牌名的牌',
  ['@$os__jichou'] = '急筹',
  ['os__jilun'] = '机论',
  ['@$os__jilun'] = '机论',
  ['#os__jichou_dr'] = '急筹',
  ['os__jichou_give&'] = '<font color=>急筹[给牌]</font>',
  [':os__jichou'] = '①每回合限一次，你可视为使用一种普通锦囊牌，然后本局游戏你无法以此法或自手牌中使用此牌名的牌，且不可响应此牌名的牌。②出牌阶段限一次，你可将手牌中“急筹”使用过的其牌名的一张牌交给一名角色。',
  ['$os__jichou1'] = '此危亡之时，当出此急谋。',
  ['$os__jichou2'] = '急筹布画，运策捭阖。',
}

os__jichou:addEffect("viewas", {
  card_filter = Util.FalseFunc,
  card_num = 0,
  prompt = "#os__jichou",
  pattern = ".|.|.|.|.|trick",
  interaction = function(skill)
    local allCardNames, cardNames = {}, {}
    local os__jichouRecord = skill.player:getTableMark("@$os__jichou")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:cloneCard(Fk:getCardById(id).name)
      if card:isCommonTrick() and not table.contains(allCardNames, card.name) and not table.contains(os__jichouRecord, card.name) and not card.is_derived then
        table.insert(allCardNames, card.name)
        if not skill.player:prohibitUse(card) and ((Fk.currentResponsePattern == nil and skill.player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
          table.insert(cardNames, card.name)
        end
      end
    end
    return UI.ComboBox { choices = cardNames, all_choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = skill.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = os__jichou.name
    return c
  end,
  before_use = function(self, player, use)
    if player:hasSkill("os__jilun") then
      local record = player:getTableMark("@$os__jilun")
      table.insert(record, use.card.name)
      player.room:setPlayerMark(player, "@$os__jilun", record)
    end
  end,
  enabled_at_play = function(self, player)
    local os__jichouRecord = player:getTableMark("@$os__jichou")
    if player:usedSkillTimes(os__jichou.name) > 0 then return false end
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:cloneCard(Fk:getCardById(id).name)
      if card:isCommonTrick() and not table.contains(os__jichouRecord, card.name) and not card.is_derived and not player:prohibitUse(card) and ((Fk.currentResponsePattern == nil and player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        return true
      end
    end
    return false
  end,
  enabled_at_response = function(self, player)
    local os__jichouRecord = player:getTableMark("@$os__jichou")
    if player:usedSkillTimes(os__jichou.name) > 0 then return false end
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:cloneCard(Fk:getCardById(id).name)
      if card:isCommonTrick() and not table.contains(os__jichouRecord, card.name) and not card.is_derived and not player:prohibitUse(card) and ((Fk.currentResponsePattern == nil and player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        return true
      end
    end
    return false
  end,
})

os__jichou:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if not table.contains(player:getCardIds(Player.Hand), card.id) then return false end
    return table.contains(player:getTableMark("@$os__jichou"), card.name)
  end,
})

os__jichou:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return table.contains(player:getTableMark("@$os__jichou"), data.card.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertIfNeed(data.disresponsiveList, player.id)
  end,

  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return player == target and table.contains(data.card.skillNames, "os__jichou")
    else
      return data == os__jichou and player == target
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      local record = player:getTableMark("@$os__jichou")
      table.insert(record, data.card.name)
      player.room:setPlayerMark(player, "@$os__jichou", record)
    else
      player.room:handleAddLoseSkills(player, event == fk.EventAcquireSkill and "os__jichou_give&" or "-os__jichou_give&", nil, false, true)
    end
  end,
})

return os__jichou

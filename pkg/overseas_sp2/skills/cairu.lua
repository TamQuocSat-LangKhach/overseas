local cairu = fk.CreateSkill {
  name = "os__cairu"
}

Fk:loadTranslationTable{
  ['os__cairu'] = '才濡',
  ['#os__cairu-active'] = '才濡：将两张颜色不同的牌当【火攻】/【铁索连环】/【无中生有】使用（每回合每牌名限两次）',
  ['@$os__cairu-turn'] = '才濡 已使用',
  [':os__cairu'] = '你可将两张颜色不同的牌当作【火攻】、【铁索连环】、【无中生有】使用。（每回合每种牌名限两次）',
  ['$os__cairu1'] = '勤学广才，秉宁静以待致远。',
  ['$os__cairu2'] = '读群书而后知，见众贤而思进。',
}

cairu:addEffect('viewas', {
  pattern = "fire_attack,iron_chain,ex_nihilo",
  prompt = "#os__cairu-active",
  interaction = function()
    local all_names = {"fire_attack", "iron_chain", "ex_nihilo"}
    local names = U.getViewAsCardNames(player, cairu.name, all_names)
    names = table.filter(names, function(n) return not table.contains(player:getTableMark("@$os__cairu-turn"), n) end)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  card_num = 2,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then
      return table.contains(player:getCardIds("he"), to_select) and Fk:getCardById(to_select).color ~= Fk:getCardById(selected[1]).color
    elseif #selected == 2 then
      return false
    end
    return table.contains(player:getCardIds("he"), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 2 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = cairu.name
    return card
  end,
  before_use = function(self, player, use)
    local name = use.card.name
    local record = player:getTableMark("_os__cairu-turn")
    record[name] = (record[name] or 0) + 1
    player.room:setPlayerMark(player, "_os__cairu-turn", record)
    if record[name] >= 2 then
      record = player:getTableMark("@$os__cairu-turn")
      table.insert(record, name)
      player.room:setPlayerMark(player, "@$os__cairu-turn", record)
    end
  end,
  enabled_at_play = function(self, player)
    local all_names = {"fire_attack", "iron_chain", "ex_nihilo"}
    local names = U.getViewAsCardNames(player, cairu.name, all_names)
    return table.find(names, function(n) return not table.contains(player:getTableMark("@$os__cairu-turn"), n) end)
  end,
  enabled_at_response = function(self, player, response)
    if response then return end
    local all_names = {"fire_attack", "iron_chain", "ex_nihilo"}
    local names = U.getViewAsCardNames(player, cairu.name, all_names)
    return table.find(names, function(n) return not table.contains(player:getTableMark("@$os__cairu-turn"), n) end)
  end
})

return cairu

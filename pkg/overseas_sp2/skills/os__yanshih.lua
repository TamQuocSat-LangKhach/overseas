local os__yanshih = fk.CreateSkill {
  name = "os__yanshih"
}

Fk:loadTranslationTable{
  ['os__yanshih'] = '延势',
  ['@@os__yanshiUp'] = '延势 已升级',
  [':os__yanshih'] = '一级：限定技，你可将一张【杀】当【决斗】、【兵临城下】或<a href=>智囊</a>牌使用。<br/>二级：限定技，你可将一张【杀】当【决斗】、【兵临城下】或<a href=>智囊</a>牌使用。<a href=>历战</a>：复原此技能。',
  ['$os__yanshih1'] = '今破曹军，明日当直取许都！',
  ['$os__yanshih2'] = '全军整肃，此战不得有失！',
}

os__yanshih:addEffect('viewas', {
  frequency = Skill.Limited,
  pattern = "duel,enemy_at_the_gates,dismantlement,nullification,ex_nihilo",
  interaction = function()
    local all_names = {"duel", "enemy_at_the_gates", "dismantlement", "nullification", "ex_nihilo"}
    local names = U.getViewAsCardNames(Self, "taoluan", all_names)
    if #names > 0 then
      return U.CardNameBox { choices = names, all_choices = all_names }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    return Fk:getCardById(to_select).trueName == "slash"
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = os__yanshih.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(os__yanshih.name, Player.HistoryGame) == 0
  end,
  enabled_at_response = function (self, player, response)
    return player:usedSkillTimes(os__yanshih.name, Player.HistoryGame) == 0 and not response
  end
})

os__yanshih:addEffect(fk.TurnEnd, {
  can_refresh = function(self, event, target, player)
    return player == target and player:usedSkillTimes(os__yanshih.name) > 0 and player:getMark("@@os__yanshiUp") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    player:setSkillUseHistory(os__yanshih.name, 0, Player.HistoryGame)
  end
})

return os__yanshih

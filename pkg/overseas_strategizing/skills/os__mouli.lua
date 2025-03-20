local os__mouli = fk.CreateSkill {
  name = "os__mouli"
}

Fk:loadTranslationTable{
  ['os__mouli'] = '谋立',
  ['os__mouliFailed'] = '谋立失败，牌堆中没有该基本牌',
  [':os__mouli'] = '每回合限一次，当你需要使用基本牌时，你可使用牌堆中（系统选择）的基本牌。',
  ['$os__mouli1'] = '僣孽为害，吾岂可谋而不行？',
  ['$os__mouli2'] = '澄汰王室，迎立宗子。',
}

os__mouli:addEffect('viewas', {
  card_filter = Util.FalseFunc,
  card_num = 0,
  pattern = ".|.|.|.|.|basic",
  interaction = function(self)
    local allCardNames, cardNames = {}, {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      local name = card.name
      if not table.contains(allCardNames, name) and card.type == Card.TypeBasic and not card.is_derived then
        table.insert(allCardNames, name)
        local card = Fk:cloneCard(name)
        if not self.player:prohibitUse(card) and ((Fk.currentResponsePattern == nil and self.player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
          table.insert(cardNames, name)
        end
      end
    end
    return UI.ComboBox { choices = cardNames , all_choices = allCardNames }
  end,
  view_as = function(self)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = os__mouli.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(os__mouli.name) == 0
  end,
  enabled_at_response = function(self, player, cardResponsing)
    return player:usedSkillTimes(os__mouli.name) == 0 and not cardResponsing
  end,
  before_use = function(self, player, use)
    local cids = player.room:getCardsFromPileByRule(".|.|.|.|" .. use.card.name)
    if #cids > 0 then
      use.card:addSubcards(cids)
    else
      player.room:doBroadcastNotify("ShowToast", Fk:translate("os__mouliFailed"))
      return os__mouli.name
    end
  end,
})

return os__mouli

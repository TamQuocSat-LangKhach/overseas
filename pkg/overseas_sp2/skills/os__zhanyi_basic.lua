local os__zhanyi_basic = fk.CreateSkill {
  name = "os__zhanyi_basic&"
}

Fk:loadTranslationTable{
  ['os__zhanyi_basic&'] = '战意',
  ['#os__zhanyi_basic-prompt'] = '你可将一张基本牌当成任意基本牌使用',
  ['os__zhanyi'] = '战意',
  ['@os__zhanyi-phase'] = '战意',
  [':os__zhanyi_basic&'] = '你可将一张基本牌当成任意基本牌使用',
}

os__zhanyi_basic:addEffect('viewas', {
  card_num = 1,
  prompt = "#os__zhanyi_basic-prompt",
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type == Card.TypeBasic
  end,
  pattern = ".|.|.|.|.|basic",
  interaction = function(self)
    local all_names = U.getAllCardNames("b")
    local names = U.getViewAsCardNames(player, "os__zhanyi", all_names)
    if #names > 0 then
      return UI.ComboBox { choices = names, all_choices = all_names }
    end
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice or #cards ~= 1 then return end
    local c = Fk:cloneCard(choice)
    c:addSubcards(cards)
    c.skillName = os__zhanyi_basic.name
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@os__zhanyi-phase") == "basic"
  end,
  enabled_at_response = function(self, player, resp)
    return player:getMark("@os__zhanyi-phase") == "basic" and not resp
  end,
})

return os__zhanyi_basic

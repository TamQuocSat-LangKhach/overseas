local os__yingji = fk.CreateSkill {
  name = "os__yingji"
}

Fk:loadTranslationTable{
  ['os__yingji'] = '应机',
  [':os__yingji'] = '当你于回合外需要使用/打出一张基本牌或普通锦囊牌时，若你没有手牌，你可摸一张牌并视为使用/打出此牌。',
  ['$os__yingji1'] = '辩适于世，论合于时。',
  ['$os__yingji2'] = '辩言出于口，不失思忖心。',
}

os__yingji:addEffect('viewas', {
  card_filter = Util.FalseFunc,
  card_num = 0,
  pattern = ".|.|.|.|.|basic,trick",
  interaction = function(self)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and (card.type == Card.TypeBasic or card:isCommonTrick()) and not card.is_derived and ((Fk.currentResponsePattern == nil and self.player:canUse(card)) or (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) and not self.player:prohibitUse(card) then
        table.insert(allCardNames, card.name)
      end
    end
    return UI.ComboBox { choices = allCardNames }
  end,
  view_as = function(self, player, cards)
    local choice = self.interaction.data
    if not choice then return end
    local c = Fk:cloneCard(choice)
    c.skillName = os__yingji.name
    return c
  end,
  before_use = function(self, player, use)
    player:drawCards(1, os__yingji.name)
  end,
  enabled_at_play = function(self, player)
    return player.phase == Player.NotActive and player:isKongcheng() and player:hasSkill(os__yingji.name)
  end,
  enabled_at_response = function(self, player)
    return player.phase == Player.NotActive and player:isKongcheng() and player:hasSkill(os__yingji.name)
  end,
})

return os__yingji

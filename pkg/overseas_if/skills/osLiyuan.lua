local osLiyuan = fk.CreateSkill {
  name = "os__liyuan"
}

Fk:loadTranslationTable{
  ['os__liyuan'] = '离渊',
  ['#os__liyuan-viewas'] = '发动 离渊，将1张对应装备栏已被废除的装备牌当普【杀】使用或打出，然后摸1张牌',
  ['#os__liyuan_trigger'] = '离渊',
  [':os__liyuan'] = '你可以将一张对应装备栏已被废除的装备牌当普【杀】使用或打出（无距离、次数限制，不计次数）。当你以此法使用或打出牌时，你摸一张牌。',
  ['$os__liyuan1'] = '退临深意，幡然腾空！',
  ['$os__liyuan2'] = '爪甲碎尽，引灵显辉！',
}

osLiyuan:addEffect('viewas', {
  anim_type = "offensive",
  prompt = "#os__liyuan-viewas",
  pattern = "slash",
  card_filter = function(self, player, to_select, selected)
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    return card.type == Card.TypeEquip and table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(card.sub_type))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = osLiyuan.name
    c:addSubcard(cards[1])
    return c
  end,
  before_use = function(self, player, use)
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return table.find(player.equipSlots, function (slot)
      return table.contains(player.sealedSlots, slot)
    end)
  end,
  enabled_at_response = function(self, player, response)
    return table.find(player.equipSlots, function (slot)
      return table.contains(player.sealedSlots, slot)
    end)
  end
})

osLiyuan:addEffect(fk.CardUsing, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(osLiyuan) and table.contains(data.card.skillNames, osLiyuan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, osLiyuan.name)
  end,
})

osLiyuan:addEffect(fk.CardResponding, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(osLiyuan) and table.contains(data.card.skillNames, osLiyuan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, osLiyuan.name)
  end,
})

osLiyuan:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, osLiyuan.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, osLiyuan.name)
  end,
})

return osLiyuan

local liyuan = fk.CreateSkill {
  name = "os__liyuan",
}

Fk:loadTranslationTable{
  ["os__liyuan"] = "离渊",
  [":os__liyuan"] = "你可以将一张对应装备栏已被废除的装备牌当【杀】使用或打出（无距离次数限制）。"..
  "当你以此法使用或打出牌时，你摸一张牌。",

  ["#os__liyuan"] = "离渊：将一张对应装备栏已废除的装备牌当【杀】使用或打出，然后摸一张牌",

  ["$os__liyuan1"] = "退临深意，幡然腾空！",
  ["$os__liyuan2"] = "爪甲碎尽，引灵显辉！",
}

liyuan:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#os__liyuan",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip and
      table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(Fk:getCardById(to_select).sub_type))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local c = Fk:cloneCard("slash")
    c.skillName = liyuan.name
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

local spec = {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liyuan.name) and table.contains(data.card.skillNames, liyuan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, liyuan.name)
  end,
}

liyuan:addEffect(fk.CardUsing, spec)
liyuan:addEffect(fk.CardResponding, spec)

liyuan:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, liyuan.name)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, liyuan.name)
  end,
})

return liyuan

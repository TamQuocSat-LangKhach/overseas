local kuiduan = fk.CreateSkill {
  name = "os__kuiduan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__kuiduan"] = "溃端",
  [":os__kuiduan"] = "锁定技，当你使用【杀】指定唯一目标后，你与其各将随机两张手牌标记为“溃端”牌（视为【杀】）。当“溃端”牌造成伤害时，"..
  "若伤害来源拥有的“溃端”牌数大于受到伤害的角色，则此伤害+1。",

  ["@@os__kuiduan_rout-inhand"] = "溃端",

  ["$os__kuiduan1"] = "蜀军大败，吾等岂能失此战机！",
  ["$os__kuiduan2"] = "求胜心切，竟轻中敌计。",
}

kuiduan:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(kuiduan.name) and target == player and data.card.trueName == "slash" and
      data:isOnlyTarget(data.to)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    for _, p in ipairs{player, data.to} do
      local cards = table.filter(p:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") == 0
      end)
      cards = table.random(cards, math.min(2, #cards)) ---@type integer[]
      if #cards > 0 then
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id), "@@os__kuiduan_rout-inhand", 1)
        end
      end
    end
  end,
})

---@param player ServerPlayer
local function getRoutNum(player)
  return #table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") > 0 end)
end

kuiduan:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if target ~= player or data.card == nil or data.chain then return false end
    local c_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, false)
    if c_event == nil then return false end
    local use_data = c_event.data
    return (use_data.extra_data or {}).os__kuiduan and data.card == use_data.card and player == use_data.from and
      getRoutNum(player) > getRoutNum(data.to)
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
  end,
})

kuiduan:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and #Card:getIdList(data.card) == 1 and
      Fk:getCardById(Card:getIdList(data.card)[1]):getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.os__kuiduan = true
  end,
})

kuiduan:addEffect("filter", {
  mute = true,
  card_filter = function(self, player, card)
    return card:getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

return kuiduan

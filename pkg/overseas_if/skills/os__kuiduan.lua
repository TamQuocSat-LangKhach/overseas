local os__kuiduan = fk.CreateSkill {
  name = "os__kuiduan"
}

Fk:loadTranslationTable{
  ['os__kuiduan'] = '溃端',
  ['@@os__kuiduan_rout-inhand'] = '溃端',
  ['#os__kuiduan_dmg'] = '溃端',
  ['#os__kuiduan_slash'] = '溃端',
  [':os__kuiduan'] = '锁定技，当你使用【杀】指定唯一目标后，你与其各将随机两张手牌标记为“溃端”牌（只能当【杀】使用或打出）。当“溃端”牌造成伤害时，若伤害来源拥有的“溃端”牌数大于受到伤害的角色，则此伤害+1。<font color=>“溃端”牌暂实现为锁定视为技</font>',
  ['$os__kuiduan1'] = '蜀军大败，吾等岂能失此战机！',
  ['$os__kuiduan2'] = '求胜心切，竟轻中敌计。',
}

-- 添加触发技能效果
os__kuiduan:addEffect(fk.TargetSpecified, {
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(os__kuiduan.name) and player == target and data.card.trueName == "slash"
      and #TargetGroup:getRealTargets(data.tos) > 0 and U.isOnlyTarget(player.room:getPlayerById(data.to), data, event)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    for _, p in ipairs{player, to} do
      local cards = table.filter(p:getCardIds("h"), function (id) return Fk:getCardById(id):getMark("@@os__kuiduan_rout-inhand") == 0 end)
      cards = table.random(cards, math.min(2, #cards)) ---@type integer[]
      if #cards > 0 then
        table.forEach(cards, function(id) room:addCardMark(Fk:getCardById(id), "@@os__kuiduan_rout-inhand") end)
      end
    end
  end,
})

-- 添加伤害技能效果
os__kuiduan:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    if target ~= player or data.card == nil or data.chain then return false end
    local c_event = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect, false)
    if c_event == nil then return false end
    local use_data = c_event.data[1]
    return (use_data.extra_data or {}).os__kuiduan and data.card == use_data.card and player.id == use_data.from and getRoutNum(player) > getRoutNum(data.to)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    player.room:notifySkillInvoked(player, os__kuiduan.name)
    data.damage = data.damage + 1
  end,

  can_refresh = function(self, event, target, player, data)
    if player ~= target then return end
    local cards = Card:getIdList(data.card)
    return #cards == 1 and Fk:getCardById(cards[1]):getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    event:setCostData(self, { os__kuiduan = true })
  end,
})

-- 添加过滤技能效果
os__kuiduan:addEffect('filter', {
  name = "#os__kuiduan_slash",
  card_filter = function(self, player, card)
    return card:getMark("@@os__kuiduan_rout-inhand") > 0
  end,
  view_as = function(self, player, card)
    return Fk:cloneCard("slash", card.suit, card.number)
  end,
})

return os__kuiduan

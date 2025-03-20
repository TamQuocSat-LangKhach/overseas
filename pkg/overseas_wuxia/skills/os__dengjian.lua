local os__dengjian = fk.CreateSkill {
  name = "os__dengjian"
}

Fk:loadTranslationTable{
  ['os__dengjian'] = '登剑',
  ['@@os__fencing-inhand'] = '剑法',
  [':os__dengjian'] = '其他角色的弃牌阶段结束时，你可从弃牌堆随机获得一张其本回合使用造成过伤害的非转化的【杀】（每轮每种颜色限一次），此【杀】标记为“剑法”（“剑法”：无次数限制）。',
  ['$os__dengjian1'] = '百家剑法之长，皆凝于此剑！',
  ['$os__dengjian2'] = '君剑法超群，观之似有所得！',
}

os__dengjian:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player)
    if not (target.phase == Player.Discard and player:hasSkill(os__dengjian) and player ~= target) then return end
    local cards = {}
    local record = player:getTableMark("_os__dengjian-round")
    player.room.logic:getActualDamageEvents(1, function(e)
      local damage = e.data[1]
      if damage.from == target and damage.card then
        local c = damage.card ---@class Card
        if c.trueName == "slash" and U.isPureCard(c) and not table.contains(record, c.color) and player.room:getCardArea(c) == Card.DiscardPile then
          table.insertTableIfNeed(cards, Card:getIdList(c))
        end
      end
      return false
    end)
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = event:getCostData(self).cards
    local card = table.random(cards) ---@type integer
    room:obtainCard(player, card, true, fk.ReasonPrey, player.id, os__dengjian.name, "@@os__fencing-inhand")
    room:addTableMark(player, "_os__dengjian-round", Fk:getCardById(card, true).color)
  end,
})

local os__dengjian_buff = fk.CreateSkill {
  name = "os__dengjian_buff"
}

os__dengjian_buff:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card:getMark("@@os__fencing-inhand") > 0
  end,
})

return os__dengjian

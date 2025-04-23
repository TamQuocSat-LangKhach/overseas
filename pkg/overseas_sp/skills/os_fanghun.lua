local osFanghun = fk.CreateSkill {
  name = "os__fanghun"
}

Fk:loadTranslationTable{
  ["os__fanghun"] = "芳魂",
  [":os__fanghun"] = "①当你使用【杀】指定目标后或成为【杀】的目标后，你获得1枚“梅影”。②你可弃1枚“梅影”以发动〖龙胆〗并摸一张牌。",

  ["@meiying"] = "梅影",
  ["#os__fanghun_gain"] = "芳魂",

  ["$os__fanghun1"] = "万花凋落尽，一梅独傲霜。",
  ["$os__fanghun2"] = "暗香疏影处，凌风踏雪来！",
}

-- ViewAsSkill
osFanghun:addEffect("viewas", {
  pattern = "slash,jink",
  card_filter = function(self, player, to_select, selected)
    if #selected == 1 then return false end
    local _c = Fk:getCardById(to_select)
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    else
      return false
    end
    return
      (Fk.currentResponsePattern == nil and player:canUse(c)) or
      (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local _c = Fk:getCardById(cards[1])
    local c
    if _c.trueName == "slash" then
      c = Fk:cloneCard("jink")
    elseif _c.name == "jink" then
      c = Fk:cloneCard("slash")
    end
    --c.skillName = self.name
    c.skillNames = c.skillNames or {}
    table.insert(c.skillNames, osFanghun.name)
    table.insert(c.skillNames, "longdan")
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  enabled_at_response = function(self, player)
    return player:getMark("@meiying") > 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@meiying")
    player:drawCards(1, osFanghun.name)
  end,
})



-- TriggerSkill
osFanghun:addEffect(fk.TargetSpecified, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osFanghun.name) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osFanghun.name
    local room = player.room
    room:notifySkillInvoked(player, skillName)
    if not table.contains(data.card.skillNames, skillName) then --避免重叠
      player:broadcastSkillInvoke(skillName)
    end
    room:addPlayerMark(player, "@meiying")
  end,
})

osFanghun:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osFanghun.name) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@meiying")
  end,
})

return osFanghun

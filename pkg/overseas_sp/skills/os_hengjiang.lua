local osHengjiang = fk.CreateSkill {
  name = "os__hengjiang"
}

Fk:loadTranslationTable{
  ["os__hengjiang"] = "横江",
  [":os__hengjiang"] = "当你使用基本牌或普通锦囊牌指定唯一目标后，若此时为你的出牌阶段且你于此阶段内未发动过此技能，" ..
  "你可将此牌的目标改为攻击范围内的所有角色，此牌结算结束后你摸X张牌（X为响应此牌的角色数）。",

  ["$os__hengjiang1"] = "江横索寒，阻敌绝境之中！",
  ["$os__hengjiang2"] = "霸必奋勇杀敌，一雪夷陵之耻！",
}

osHengjiang:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osHengjiang.name) and
      player:usedSkillTimes(osHengjiang.name, Player.HistoryPhase) < 1 and
      player.phase == Player.Play and
      data.firstTarget and
      data:isOnlyTarget(data.to) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = data.card
    data:cancelTarget(data.to)
    local targets = table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and not player:isProhibited(p, card)
    end)
    if #targets == 0 then return false end
    data.extra_data = data.extra_data or {}
    data.extra_data.os__hengjiangUser = player.id
    room:doIndicate(player, targets)
    table.forEach(targets, function(p)
      data:addTarget(p)
    end)
  end,
})

osHengjiang:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      (data.extra_data or {}).os__hengjiangUser == player.id and
      (data.extra_data or {}).os__hengjiangResponsors
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(#data.extra_data.os__hengjiangResponsors, osHengjiang.name)
  end,
})

osHengjiang:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return
      data.responseToEvent and
      (data.responseToEvent.extra_data or {}).os__hengjiangUser and
      not table.contains(data.responseToEvent.extra_data.os__hengjiangResponsors or {}, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    data.responseToEvent.extra_data.os__hengjiangResponsors = data.responseToEvent.extra_data.os__hengjiangResponsors or {}
    table.insertIfNeed(data.responseToEvent.extra_data.os__hengjiangResponsors, target.id)
  end,
})

return osHengjiang

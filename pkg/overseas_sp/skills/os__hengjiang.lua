local os__hengjiang = fk.CreateSkill {
  name = "os__hengjiang"
}

Fk:loadTranslationTable{
  ['os__hengjiang'] = '横江',
  [':os__hengjiang'] = '当你使用基本牌或普通锦囊牌指定唯一目标后，若此时为你的出牌阶段且你于此阶段内未发动过此技能，你可将此牌的目标改为攻击范围内的所有角色，此牌结算结束后你摸X张牌（X为响应此牌的角色数）。',
  ['$os__hengjiang1'] = '江横索寒，阻敌绝境之中！',
  ['$os__hengjiang2'] = '霸必奋勇杀敌，一雪夷陵之耻！',
}

os__hengjiang:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__hengjiang.name) and player:usedSkillTimes(os__hengjiang.name, Player.HistoryPhase) < 1 and player.phase == Player.Play and data.firstTarget and #AimGroup:getAllTargets(data.tos) == 1 and (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = data.card
    AimGroup:cancelTarget(data, data.to)
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) and not player:isProhibited(p, card)
    end), Util.IdMapper)
    if #targets == 0 then return false end
    data.card.extra_data = data.card.extra_data or {}
    data.card.extra_data.os__hengjiangUser = player.id
    room:doIndicate(player.id, targets)
    table.forEach(targets, function(pid)
      AimGroup:addTargets(room, data, pid)
    end)
  end,
})

os__hengjiang:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and (data.card.extra_data or {}).os__hengjiangUser == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getMark("_os__hengjiang_count"), os__hengjiang.name)
    player.room:setPlayerMark(player, "_os__hengjiang_count", 0)
  end,

  can_refresh = function(self, event, target, player, data)
    return (data.card.extra_data or {}).os__hengjiangUser == player.id and
      data.responseToEvent and data.responseToEvent.from == player.id and target:getMark("_os__hengjiang_counted-phase") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "_os__hengjiang_count")
    player.room:addPlayerMark(target, "_os__hengjiang_counted-phase")
  end,
})

return os__hengjiang

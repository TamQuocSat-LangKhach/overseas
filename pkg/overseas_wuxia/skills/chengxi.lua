local chengxi = fk.CreateSkill {
  name = "os__chengxi"
}

Fk:loadTranslationTable{
  ['os__chengxi'] = '承袭',
  ['@os__chengxi'] = '承袭',
  [':os__chengxi'] = '出牌阶段对每名角色限一次，你可摸一张牌并与一名角色拼点，若你：赢，你使用的下一张基本牌或普通锦囊牌结算结束后，你视为对相同目标使用一张无次数限制的同名牌；没赢，其视为对你使用一张无距离限制的【杀】。',
  ['$os__chengxi1'] = '从今日始，血婆娑由我继之。',
  ['$os__chengxi2'] = '夏侯之名，吾师之愿，子萼定不相负！',
}

chengxi:addEffect('active', {
  can_use = function(self, player)
    return table.find(Fk:currentRoom().alive_players, function(p)
      return p.id ~= player.id and player:canPindian(p, true) and not table.contains(player:getTableMark("_os__chengxi-turn"), p.id)
    end)
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= player.id and player:canPindian(target, true) and not table.contains(player:getTableMark("_os__chengxi-turn"), to_select) and #selected == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addTableMark(player, "_os__chengxi-turn", target.id)
    player:drawCards(1, chengxi.name)
    if not player:canPindian(target) then return end
    local pindian = player:pindian({target}, chengxi.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(player, "@os__chengxi")
    else
      local slash = Fk:cloneCard("slash")
      if target:canUseTo(slash, player, { bypass_times = true, bypass_distances = true }) then
        room:useVirtualCard("slash", nil, target, player, chengxi.name, true)
      end
    end
  end,
})

chengxi:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@os__chengxi") > 0 and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and #TargetGroup:getRealTargets(data.tos) > 0 and not (data.extra_data or {}).os__chengxiUse
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = TargetGroup:getRealTargets(data.tos) -- bye-bye, collateral
    local num = player:getMark("@os__chengxi")
    for _ = 1, num do
      if player.dead then break end
      room:removePlayerMark(player, "@os__chengxi")
      player:broadcastSkillInvoke(chengxi.name)
      local anim_type = (data.card.is_damage_card or table.contains({"dismantlement", "snatch", "chasing_near"}, data.card.name) or data.card.is_derived) and "offensive" or "support"
      room:notifySkillInvoked(player, chengxi.name, anim_type)
      local card = Fk:cloneCard(data.card.name)
      local _targets = table.filter(table.map(targets, Util.Id2PlayerMapper), function(p) return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true }) end)
      local use = {} ---@type CardUseStruct
      use.from = player.id
      use.tos = table.map(_targets, function(p) return { p.id } end)
      use.card = card
      use.extra_use = true
      use.extra_data = use.extra_data or {}
      use.extra_data.os__chengxiUse = true
      room:useCard(use)
    end
  end,
})

return chengxi

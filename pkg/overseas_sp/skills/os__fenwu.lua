local os__fenwu = fk.CreateSkill {
  name = "os__fenwu"
}

Fk:loadTranslationTable{
  ['os__fenwu'] = '奋武',
  ['#os__fenwu_plus-ask'] = '奋武：你可选择一名其他角色，失去1点体力，视为对其使用一张伤害+1的【杀】',
  ['#os__fenwu-ask'] = '奋武：你可选择一名其他角色，失去1点体力，视为对其使用一张【杀】',
  [':os__fenwu'] = '结束阶段开始时，你可失去1点体力，视为你对一名其他角色使用一张【杀】。若本回合你使用过超过一种基本牌，此【杀】伤害值基数+1。',
  ['$os__fenwu1'] = '合围夷道，兵困吴贼！',
  ['$os__fenwu2'] = '纵兵摧城，奋武破敌！',
}

os__fenwu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__fenwu.name) and
      player.phase == Player.Finish and player.hp > 0 and player:canUse(Fk:cloneCard("slash"), {bypass_times = true, bypass_distances = true})
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local card = Fk:cloneCard("slash")
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true })
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end

    local basic_cards = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data[1]
      if use.from == player.id and use.card.type == Card.TypeBasic then
        table.insertIfNeed(basic_cards, use.card.trueName)
        if #basic_cards > 1 then return true end
      end
      return false
    end, Player.HistoryTurn)

    local damage_plus = #basic_cards > 1
    local targets = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = damage_plus and "#os__fenwu_plus-ask" or "#os__fenwu-ask",
      skill_name = os__fenwu.name,
      cancelable = true
    })
    if #targets > 0 then
      event:setCostData(self, {targets[1], damage_plus})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:loseHp(player, 1, os__fenwu.name)
    local slash = Fk:cloneCard("slash")
    slash.skillName = os__fenwu.name
    local new_use = {
      from = player.id,
      tos = { {event:getCostData(self)[1]} },
      card = slash,
    } ---@type CardUseStruct

    if event:getCostData(self)[2] then
      new_use.additionalDamage = (new_use.additionalDamage or 0) + 1
    end
    room:useCard(new_use)
  end,
})

return os__fenwu

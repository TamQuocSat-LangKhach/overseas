local osFenwu = fk.CreateSkill {
  name = "os__fenwu"
}

Fk:loadTranslationTable{
  ["os__fenwu"] = "奋武",
  [":os__fenwu"] = "结束阶段开始时，你可失去1点体力，视为你对一名其他角色使用一张【杀】。若本回合你使用过超过一种基本牌，此【杀】伤害值基数+1。",

  ["#os__fenwu_plus-ask"] = "奋武：你可选择一名其他角色，失去1点体力，视为对其使用一张伤害+1的【杀】",
  ["#os__fenwu-ask"] = "奋武：你可选择一名其他角色，失去1点体力，视为对其使用一张【杀】",

  ["$os__fenwu1"] = "合围夷道，兵困吴贼！",
  ["$os__fenwu2"] = "纵兵摧城，奋武破敌！",
}

osFenwu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osFenwu.name) and
      player.phase == Player.Finish and
      player.hp > 0 and
      player:canUse(Fk:cloneCard("slash"), { bypass_times = true, bypass_distances = true })
  end,
  on_cost = function(self, event, target, player)
    local room = player.room

    local basic_cards = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player and use.card.type == Card.TypeBasic then
        table.insertIfNeed(basic_cards, use.card.trueName)
        if #basic_cards > 1 then return true end
      end
      return false
    end, Player.HistoryTurn)

    local damage_plus = #basic_cards > 1
    local use = room:askToUseVirtualCard(
      player,
      {
        name = "slash",
        skill_name = osFenwu.name,
        extra_data = { bypass_distances = true },
        skip = true,
      }
    )

    if use then
      if damage_plus then
        use.additionalDamage = (use.additionalDamage or 0) + 1
      end
      event:setCostData(self, use)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:loseHp(player, 1, osFenwu.name)

    room:useCard(event:getCostData(self))
  end,
})

return osFenwu

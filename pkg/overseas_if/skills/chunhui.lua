local chunhui = fk.CreateSkill {
  name = "os__chunhui",
}

Fk:loadTranslationTable{
  ["os__chunhui"] = "春晖",
  [":os__chunhui"] = "每回合限一次，当你距离1以内体力值不大于你的角色成为伤害类普通锦囊牌的目标后，你可以令其观看你的手牌" ..
  "并获得其中一张牌（若为你则跳过）；此牌结算结束后，若未对其造成伤害，你摸一张牌。",

  ["#os__chunhui-invoke"] = "春晖：你可以令 %dest 观看你的手牌并获得其中一张牌",
  ["#os__chunhui-ask"] = "春晖：获得 %src 一张手牌",

  ["$os__chunhui1"] = "寸草春晖，熏蒿雨怆。",
  ["$os__chunhui2"] = "凯风自南，吹彼棘心。",
}

chunhui:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chunhui.name) and player:usedSkillTimes(chunhui.name, Player.HistoryTurn) == 0 and
      player:compareDistance(target, 1, "<=") and target.hp <= player.hp and data.card:isCommonTrick() and data.card.is_damage_card and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = chunhui.name,
      prompt = "#os__chunhui-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player ~= target then
      local card = room:askToChooseCard(target, {
        target = player,
        flag = { card_data = { { player.general, player:getCardIds("h") } } },
        skill_name = chunhui.name,
        prompt = "#os__chunhui-ask:" .. player.id
      })
      room:obtainCard(target, card, false, fk.ReasonPrey, player, chunhui.name)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.os__chunhui = data.extra_data.os__chunhui or {}
    data.extra_data.os__chunhui[player] = target
  end,
})

chunhui:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.extra_data and data.extra_data.os__chunhui then
      local to = data.extra_data.os__chunhui[player]
      return to and not (data.damageDealt and data.damageDealt[to])
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, chunhui.name)
  end,
})

return chunhui

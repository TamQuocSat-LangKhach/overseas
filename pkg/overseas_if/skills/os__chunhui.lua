local os__chunhui = fk.CreateSkill {
  name = "os__chunhui"
}

Fk:loadTranslationTable{
  ['os__chunhui'] = '春晖',
  ['#os__chunhui-invoke'] = '春晖：你可令 %dest 观看你的手牌并获得其中一张牌',
  ['#os__chunhui-ask'] = '春晖：选择获得%src一张手牌',
  ['#os__chunhui_after'] = '春晖',
  [':os__chunhui'] = '每回合限一次，当你距离1以内且体力值不大于你的角色成为伤害类普通锦囊的目标后，若你有手牌，你可发动此技能，若其不为你，你令其观看你的手牌并获得其中一张牌。此牌结算结束后，若未对其造成伤害，你摸一张牌。',
}

os__chunhui:addEffect(fk.TargetConfirmed, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__chunhui.name) and player:usedSkillTimes(os__chunhui.name) == 0 and player:compareDistance(target, 1, "<=")
      and target.hp <= player.hp and data.card:isCommonTrick() and data.card.is_damage_card and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, { skill_name = os__chunhui.name, prompt = target ~= player and "#os__chunhui-invoke::" .. target.id or nil }) then
      event:setCostData(self, {tos = {target.id} })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player ~= target then
      local card = room:askToChooseCard(target, {
        target = player,
        flag = { card_data = { { "$Hand", player:getCardIds(Player.Hand) } } },
        skill_name = os__chunhui.name,
        prompt = "#os__chunhui-ask:" .. player.id
      })
      room:obtainCard(target, card, false, fk.ReasonJustMove, player.id, os__chunhui.name)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.os__chunhui = data.extra_data.os__chunhui or {}
    data.extra_data.os__chunhui[player.id] = target.id
  end,
})

os__chunhui:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, player, data)
    if not player.dead and data.extra_data and data.extra_data.os__chunhui then
      local to = data.extra_data.os__chunhui[player.id]
      return to and not (data.damageDealt and data.damageDealt[to] and data.damageDealt[to] > 0)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player, data)
    player:broadcastSkillInvoke(os__chunhui.name)
    player.room:notifySkillInvoked(player, os__chunhui.name, "drawcard")
    player:drawCards(1, os__chunhui.name)
  end,
})

return os__chunhui

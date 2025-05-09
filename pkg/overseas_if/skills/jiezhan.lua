local jiezhan = fk.CreateSkill {
  name = "os__jiezhan",
}

Fk:loadTranslationTable{
  ["os__jiezhan"] = "竭战",
  [":os__jiezhan"] = "其他角色的出牌阶段开始时，若其在你攻击范围内，你可以摸一张牌，然后其视为对你使用一张无距离限制且计入次数限制的【杀】。",

  ["#os__jiezhan-invoke"] = "竭战：你可以摸一张牌，令 %dest 视为对你使用一张计入次数的【杀】",

  ["$os__jiezhan1"] = "血尽鳞碎，不改匡汉之志！",
  ["$os__jiezhan2"] = "龙胆虎威，百险千难誓相随！",
}

jiezhan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jiezhan.name) and target.phase == Player.Play and player:inMyAttackRange(target)
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = jiezhan.name,
      prompt = "#os__jiezhan-invoke::" .. target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, jiezhan.name)
    if not (player.dead or target.dead) then
      player.room:useVirtualCard("slash", nil, target, player, jiezhan.name, false)
    end
  end
})

return jiezhan

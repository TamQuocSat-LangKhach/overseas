local os__zhongyi = fk.CreateSkill {
  name = "os__zhongyi"
}

Fk:loadTranslationTable{
  ['os__zhongyi'] = '忠义',
  ['@os__zhongyi'] = '忠义',
  ['os__zhongyi_draw'] = '摸%arg张牌',
  ['os__zhongyi_recover'] = '回复%arg点体力',
  ['beishui_os__zhongyi'] = '背水：失去%arg点体力',
  [':os__zhongyi'] = '锁定技，①你使用【杀】无距离限制。②当你使用【杀】结算结束后，你选择一项：1.摸等同于此【杀】造成伤害值数牌；2.回复等同于此【杀】造成伤害值数体力；背水：你失去X点体力（X为本局你选择此技能背水的次数+1）。',
  ['$os__zhongyi1'] = '忠照白日，义贯长虹！',
  ['$os__zhongyi2'] = '忠铸吾骨，义全吾身！',
}

os__zhongyi:addEffect(fk.CardUseFinished, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(os__zhongyi) and data.card.trueName == "slash" and data.damageDealt
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = 0
    for _, n in pairs(data.damageDealt) do
      num = num + n
    end
    local x = player:getMark("@os__zhongyi") + 1
    local all_choices = {"os__zhongyi_draw:::" .. num, "os__zhongyi_recover:::" .. num, "beishui_os__zhongyi:::" .. x}
    local choices = table.clone(all_choices)
    if not player:isWounded() then table.remove(choices, 2) end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__zhongyi.name,
      detailed = false,
      all_choices = all_choices
    })
    if choice:startsWith("beishui") then
      room:addPlayerMark(player, "@os__zhongyi")
      room:loseHp(player, x)
      if player.dead then return end
    end
    if not choice:startsWith("os__zhongyi_recover") then
      player:drawCards(num, os__zhongyi.name)
    end
    if not choice:startsWith("os__zhongyi_draw") and not player.dead then
      room:recover{
        who = player,
        num = math.min(num, player.maxHp - player.hp),
        recoverBy = player,
        skillName = os__zhongyi.name,
      }
    end
  end,
})

os__zhongyi:addEffect("targetmod", {
  name = "#os__zhongyi_buff",
  frequency = Skill.Compulsory,
  bypass_distances = function(self, player, skill, scope)
    return player:hasSkill(os__zhongyi) and skill.trueName == "slash_skill"
  end,
})

return os__zhongyi

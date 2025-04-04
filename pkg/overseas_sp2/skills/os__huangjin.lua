local os__huangjin = fk.CreateSkill {
  name = "os__huangjin"
}

Fk:loadTranslationTable{
  ['os__huangjin'] = '黄巾',
  [':os__huangjin'] = '锁定技，当你成为【杀】的目标时，你判定：若结果点数与此【杀】点数差值不大于1，则此【杀】对你无效。',
}

os__huangjin:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = data.card.number
    local judge = {
      who = player,
      reason = skill.name,
      pattern = num > 0 and (".|" .. num-1 .. "~" .. num+1 ) or nil,
    }
    room:judge(judge)
    if num > 0 and math.abs(judge.card.number - num) < 2 then
      table.insertIfNeed(data.nullifiedTargets, player.id)
    end
  end,
})

return os__huangjin

local os__yilie = fk.CreateSkill {
  name = "os__yilie"
}

Fk:loadTranslationTable{
  ['os__yilie'] = '毅烈',
  ['os__yilie_times'] = '使用【杀】的次数上限+1',
  ['os__yilie_draw'] = '当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌',
  ['beishui_os__yilie'] = '背水：你失去1点体力',
  ['@os__yilie-phase'] = '毅烈',
  ['yl_times_draw'] = '摸牌 多出杀',
  ['yl_times'] = '多出杀',
  ['yl_draw'] = '摸牌',
  ['#os__yilie_do'] = '毅烈',
  [':os__yilie'] = '出牌阶段开始时，你可选择此阶段内：1.使用【杀】的次数上限+1；2.当你使用的【杀】指定处于连环状态的角色为目标后，或被【闪】抵消后，摸一张牌；背水：你失去1点体力。',
  ['$os__yilie1'] = '区区绳索，就想挡住吾等去路？！',
  ['$os__yilie2'] = '以身索敌，何惧同伤！',
}

-- TriggerSkill Effect
os__yilie:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__yilie) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player)
    local choices = {"os__yilie_times", "os__yilie_draw", "beishui_os__yilie" ,"Cancel"}
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = os__yilie.name
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "beishui_os__yilie" then
      room:setPlayerMark(player, "@os__yilie-phase", "yl_times_draw")
      room:loseHp(player, 1, os__yilie.name)
    elseif choice == "os__yilie_times" then
      room:setPlayerMark(player, "@os__yilie-phase", "yl_times")
    elseif choice == "os__yilie_draw" then
      room:setPlayerMark(player, "@os__yilie-phase", "yl_draw")
    end
  end,
})

-- TargetModSkill Effect
os__yilie:addEffect('targetmod', {
  name = "#os__yilieBuff",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return (player:getMark("@os__yilie-phase") ~= 0 and string.find(player:getMark("@os__yilie-phase"), "times")) and 1 or 0
    end
  end,
})

-- TriggerSkill Effect for os__yilie_do
os__yilie:addEffect({fk.CardEffectCancelledOut, fk.TargetSpecified}, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if event == fk.CardEffectCancelledOut then
      return target == player and player:getMark("@os__yilie-phase") ~= 0 and string.find(player:getMark("@os__yilie-phase"), "draw") and data.card.trueName == "slash"
    else
      if target == player and player:hasSkill(os__yilie) and
        data.card.trueName == "slash" and
        player:getMark("@os__yilie-phase") ~= 0 and string.find(player:getMark("@os__yilie-phase"), "draw") and data.to then
        local to = player.room:getPlayerById(data.to)
        return to.chained
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    player:drawCards(1, os__yilie.name)
  end,
})

return os__yilie

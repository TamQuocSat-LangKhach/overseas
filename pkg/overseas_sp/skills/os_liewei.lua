local osLiewei = fk.CreateSkill {
  name = "os__liewei",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__liewei"] = "裂围",
  [":os__liewei"] = "锁定技，当一名角色死亡后，若其是你杀死的，你选择：1.摸两张牌；2.若〖挫锐〗发动过，令〖挫锐〗于此局游戏内的发动次数上限+1。",

  ["os__cuorui"] = "挫锐",
  ["os__liewei_draw"] = "摸两张牌",
  ["os__liewei_cuorui"] = "令〖挫锐〗于此局游戏内的发动次数上限+1",

  ["$os__liewei1"] = "敌阵已乱，速速突围！",
  ["$os__liewei2"] = "杀你，如同捻死一只蚂蚁！",
}

osLiewei:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osLiewei.name) and data.damage and data.damage.from == player
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osLiewei.name
    if
      player:usedSkillTimes("os__cuorui", Player.HistoryGame) < 1 or
      player.room:askToChoice(
        player,
        {
          choices = { "os__liewei_draw", "os__liewei_cuorui" },
          skill_name = skillName,
        }
      ) == "os__liewei_draw"
    then
      player:drawCards(2, skillName)
    else
      player:addSkillUseHistory("os__cuorui", -1)
    end
  end,
})

return osLiewei

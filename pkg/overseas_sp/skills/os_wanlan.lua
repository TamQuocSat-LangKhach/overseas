local osWanlan = fk.CreateSkill {
  name = "os__wanlan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__wanlan"] = "挽澜",
  [":os__wanlan"] = "限定技，当一名角色进入濒死状态时，你可发动此技能，若你有手牌则你弃置所有手牌，令其回复体力至1点，此次濒死结算结束后，你对当前回合角色造成1点伤害。",

  ["$os__wanlan1"] = "挽狂澜于既倒，扶大厦于将倾。",
  ["$os__wanlan2"] = "深受国恩，今日便是报偿之时！",
}

osWanlan:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osWanlan.name) and player:usedSkillTimes(osWanlan.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osWanlan.name
    local room = player.room
    player:throwAllCards("h")
    if target:isAlive() then
      room:recover{
        who = target,
        num = 1 - target.hp,
        recoverBy = player,
        skillName = skillName,
      }
    end
    local current = room.logic:getCurrentEvent()
    local death_event = current:findParent(GameEvent.Dying, true)
    if not death_event then
      return false
    end

    death_event:addExitFunc(function ()
      if room.current and room.current:isAlive() then
        room:damage{
          from = player,
          to = room.current,
          damage = 1,
          skillName = skillName,
        }
      end
    end)
  end,
})

return osWanlan

local os__wanlan = fk.CreateSkill {
  name = "os__wanlan"
}

Fk:loadTranslationTable{
  ['os__wanlan'] = '挽澜',
  [':os__wanlan'] = '限定技，当一名角色进入濒死状态时，你可发动此技能，若你有手牌则你弃置所有手牌，令其回复体力至1点，此次濒死结算结束后，你对当前回合角色造成1点伤害。',
  ['$os__wanlan1'] = '挽狂澜于既倒，扶大厦于将倾。',
  ['$os__wanlan2'] = '深受国恩，今日便是报偿之时！',
}

os__wanlan:addEffect(fk.EnterDying, {
  anim_type = "support",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and player:usedSkillTimes(os__wanlan.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player:getHandcardNum() > 0 then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = player:getHandcardNum(),
        skill_name = os__wanlan.name,
      })
    end
    if not target.dead then
      room:recover({
        who = target,
        num = 1 - target.hp,
        recoverBy = player,
        skillName = os__wanlan.name,
      })
    end
    local current = room.logic:getCurrentEvent()
    local death_event = current:findParent(GameEvent.Dying, true)
    death_event:addExitFunc(function ()
      if not room.current.dead then
        room:damage{
          from = player,
          to = room.current,
          damage = 1,
          skillName = os__wanlan.name,
        }
      end
    end)
  end,
})

return os__wanlan

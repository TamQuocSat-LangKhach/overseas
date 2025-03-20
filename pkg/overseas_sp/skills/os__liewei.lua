local os__liewei = fk.CreateSkill {
  name = "os__liewei"
}

Fk:loadTranslationTable{
  ['os__liewei'] = '裂围',
  ['os__cuorui'] = '挫锐',
  ['os__liewei_draw'] = '摸两张牌',
  ['os__liewei_cuorui'] = '令〖挫锐〗于此局游戏内的发动次数上限+1',
  [':os__liewei'] = '锁定技，当一名角色死亡后，若其是你杀死的，你选择：1.摸两张牌；2.若〖挫锐〗发动过，令〖挫锐〗于此局游戏内的发动次数上限+1。',
  ['$os__liewei1'] = '敌阵已乱，速速突围！',
  ['$os__liewei2'] = '杀你，如同捻死一只蚂蚁！',
}

os__liewei:addEffect(fk.Deathed, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__liewei.name) and data.damage and data.damage.from == player
  end,
  on_use = function(self, event, target, player, data)
    if player:usedSkillTimes("os__cuorui", Player.HistoryGame) < 1 or
      player.room:askToChoice(player, {
        choices = {"os__liewei_draw", "os__liewei_cuorui"},
        skill_name = os__liewei.name,
      }) == "os__liewei_draw" then
      player:drawCards(2, os__liewei.name)
    else
      player:addSkillUseHistory("os__cuorui", -1)
    end
  end,
})

return os__liewei

local yanzuo = fk.CreateSkill {
  name = "os__yanzuok$"
}

Fk:loadTranslationTable{
  ['os__renxian'] = '任贤',
}

yanzuo:addEffect(fk.Damage, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(yanzuo.name) and target and target.kingdom == "shu" and
      player:usedSkillTimes(yanzuo.name, Player.HistoryTurn) < 2 then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      return turn_event and turn_event.data[1] == target and turn_event.data[2].reason == "os__renxian"
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, yanzuo.name)
  end,
})

return yanzuo

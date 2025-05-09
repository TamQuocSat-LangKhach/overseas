local yanzuo = fk.CreateSkill {
  name = "os__yanzuok",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__yanzuok"] = "延祚",
  [":os__yanzuok"] = "主公技，锁定技，每回合限两次，当其他蜀势力角色于“任贤”回合内造成伤害后，你摸两张牌。",

  ["$os__yanzuok1"] = "若无忠臣良将，焉有今日之功！",
  ["$os__yanzuok2"] = "卿等安国定疆，方有今日之统！",
}

yanzuo:addEffect(fk.Damage, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(yanzuo.name) and target and target.kingdom == "shu" and
      player:usedSkillTimes(yanzuo.name, Player.HistoryTurn) < 2 then
      local turn_event = player.room.logic:getCurrentEvent():findParent(GameEvent.Turn)
      return turn_event and turn_event.data.who == target and turn_event.data.reason == "os__renxian"
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(2, yanzuo.name)
  end,
})

return yanzuo

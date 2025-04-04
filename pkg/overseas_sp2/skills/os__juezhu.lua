local os__juezhu = fk.CreateSkill {
  name = "os__juezhu"
}

Fk:loadTranslationTable{
  ['os__juezhu'] = '决助',
  ['@os__juezhu'] = '决助',
  [':os__juezhu'] = '限定技，出牌阶段，你可废除一个坐骑栏，令一名角色获得〖飞影〗并废除其判定区。其死亡后，你恢复以此法废除的坐骑栏。',
  ['$os__juezhu1'] = '曹君速上马，洪自断后。',
  ['$os__juezhu2'] = '天下可无洪，不可无君。',
}

-- Active Skill Effect
os__juezhu:addEffect('active', {
  anim_type = "support",
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(os__juezhu.name, Player.HistoryGame) < 1 and (#player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 or #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0 )
  end,
  card_filter = Util.FalseFunc,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  interaction = function(self, player)
    local all_choices = {"DefensiveRideSlot", "OffensiveRideSlot"}
    local choices = table.clone(all_choices)
    if #player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0 then
      table.remove(choices)
    end
    if #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0 then
      table.remove(choices, 1)
    end
    return UI.ComboBox{ choices = choices, all_choices = all_choices}
  end,
  on_use = function(self, player, room, use)
    local choice = skill.interaction.data
    if not choice then return false end
    local target = room:getPlayerById(use.tos[1])
    local slot = choice == "OffensiveRideSlot" and Player.OffensiveRideSlot or Player.DefensiveRideSlot
    room:abortPlayerArea(player, {slot})
    room:handleAddLoseSkills(target, "feiying")
    room:abortPlayerArea(target, {Player.JudgeSlot})
    room:setPlayerMark(player, "@os__juezhu", target.general)
    room:setPlayerMark(player, "_os__juezhu", {target.id, slot})
  end
})

-- Trigger Skill Effect
os__juezhu:addEffect(fk.Deathed, {
  mute = true,
  can_trigger = function(self, event, player, target, data)
    return player:getMark("_os__juezhu") ~= 0 and player:getMark("_os__juezhu")[1] == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, player, room, target, data)
    room:resumePlayerArea(player, player:getMark("_os__juezhu")[2])
    room:setPlayerMark(player, "_os__juezhu", 0)
  end
})

return os__juezhu

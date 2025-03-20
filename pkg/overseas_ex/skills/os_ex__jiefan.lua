local os_ex__jiefan = fk.CreateSkill {
  name = "os_ex__jiefan"
}

Fk:loadTranslationTable{
  ['os_ex__jiefan'] = '解烦',
  ['#os_ex__jiefan-discard'] = '解烦：弃置一张武器牌，否则 %dest 摸一张牌',
  [':os_ex__jiefan'] = '限定技，出牌阶段，你可选择一名角色，令攻击范围内有其的所有角色选择一项：1.弃置一张武器牌；2.令其摸一张牌。当你上一次发动〖解烦〗指定的角色进入濒死状态时，此技能视为未发动过。',
  ['$os_ex__jiefan1'] = '休想乘人之危！',
  ['$os_ex__jiefan2'] = '退后，这里交给我！',
}

os_ex__jiefan:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(os_ex__jiefan.name, Player.HistoryGame) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_tip = function (self, player, to_select, selected, selected_cards, card, selectable, extra_data)
    if #selected == 0 then return end
    if to_select == selected[1] then
      return "jiefan_target"
    else
      local p = Fk:currentRoom():getPlayerById(to_select)
      local target = Fk:currentRoom():getPlayerById(selected[1])
      if p:inMyAttackRange(target) then
        return { {content = "jiefaned", type = "warning"} }
      end
    end
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(room:getPlayerById(effect.from), "_os_ex__jiefan", target.id)
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p:inMyAttackRange(target) then
        if #room:askToDiscard(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          pattern = ".|.|.|.|.|weapon",
          prompt = "#os_ex__jiefan-discard::" .. target.id,
          skill_name = os_ex__jiefan.name
        }) == 0 then
          target:drawCards(1, os_ex__jiefan.name)
        end
      end
    end
  end,
})

os_ex__jiefan:addEffect(fk.EnterDying, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os_ex__jiefan) and player:getMark("_os_ex__jiefan") == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("os_ex__jiefan")
    room:notifySkillInvoked(player, "os_ex__jiefan")
    room:setPlayerMark(player, "_os_ex__jiefan", 0)
    player:addSkillUseHistory(os_ex__jiefan.name, -1)
  end,
})

return os_ex__jiefan

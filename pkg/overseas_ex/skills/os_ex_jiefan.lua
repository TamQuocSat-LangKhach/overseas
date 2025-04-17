local osExJiefan = fk.CreateSkill {
  name = "os_ex__jiefan",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os_ex__jiefan"] = "解烦",
  [":os_ex__jiefan"] = "限定技，出牌阶段，你可选择一名角色，令攻击范围内有其的所有角色选择一项：" ..
  "1.弃置一张武器牌；2.令其摸一张牌。当你上一次发动〖解烦〗指定的角色进入濒死状态时，此技能视为未发动过。",

  ["#os_ex__jiefan-discard"] = "解烦：弃置一张武器牌，否则 %dest 摸一张牌",

  ["$os_ex__jiefan1"] = "休想乘人之危！",
  ["$os_ex__jiefan2"] = "退后，这里交给我！",
}

osExJiefan:addEffect("active", {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(osExJiefan.name, Player.HistoryGame) < 1
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
      if to_select:inMyAttackRange(selected[1]) then
        return { { content = "jiefan_tos", type = "warning" } }
      end
    end
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osExJiefan.name
    local target = effect.tos[1]
    room:setPlayerMark(effect.from, "_os_ex__jiefan", target.id)
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p:inMyAttackRange(target) then
        if
          #room:askToDiscard(
            p,
            {
              min_num = 1,
              max_num = 1,
              pattern = ".|.|.|.|.|weapon",
              prompt = "#os_ex__jiefan-discard::" .. target.id,
              skill_name = skillName,
            }
          ) == 0
        then
          target:drawCards(1, skillName)
        end
      end
    end
  end,
})

osExJiefan:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osExJiefan.name) and player:getMark("_os_ex__jiefan") == target.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os_ex__jiefan", 0)
    player:addSkillUseHistory(osExJiefan.name, -1)
  end,
})

return osExJiefan

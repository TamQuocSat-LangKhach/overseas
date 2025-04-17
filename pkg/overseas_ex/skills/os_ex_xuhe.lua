local osExXuhe = fk.CreateSkill {
  name = "os_ex__xuhe"
}

Fk:loadTranslationTable{
  ["os_ex__xuhe"] = "虚吓",
  [":os_ex__xuhe"] = "当你使用的【杀】被一名角色的【闪】抵消后，你可令其选择一项：1. 你对其造成1点伤害；2. 当本回合你使用的下一张牌对其造成伤害时，伤害+2。",

  ["@@os_ex__xuhe-turn"] = "虚吓 伤害+2",
  ["#os_ex__xuhe"] = "你想对 %src 发动技能“虚吓”吗？",
  ["os_ex__xuhe_dmg"] = "受到%src造成的1点伤害",
  ["os_ex__xuhe_next"] = "本回合%src使用的下一张牌对你伤害+2",
  ["#os_ex__xuhe-ask"] = "%src 对你发动“虚吓”，请选择一项",
  
  ["$os_ex__xuhe1"] = "谁，还敢过来一战？！",
  ["$os_ex__xuhe2"] = "欺我无谋？定要汝等血偿！",
}

osExXuhe:addEffect(fk.CardEffectCancelledOut, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osExXuhe.name) and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      {
        skill_name = osExXuhe.name,
        prompt = "#os_ex__xuhe:" .. data.to.id,
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExXuhe.name
    local room = player.room
    local targetPlayer = data.to
    local choice = room:askToChoice(
      targetPlayer,
      {
        choices = { "os_ex__xuhe_dmg:" .. player.id, "os_ex__xuhe_next:" .. player.id },
        skill_name = skillName,
        prompt = "#os_ex__xuhe-ask:" .. player.id,
      }
    )
    if choice:startsWith("os_ex__xuhe_dmg") then
      room:damage{
        from = player,
        to = targetPlayer,
        damage = 1,
        skill_name = skillName,
      }
    else
      room:addTableMarkIfNeed(targetPlayer, "@@os_ex__xuhe-turn", player.id)
    end
  end,
})

osExXuhe:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.find(
        player.room.alive_players,
        function(p) return table.contains(p:getTableMark("@@os_ex__xuhe-turn"), player.id) end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "_os_ex__xuhe-turn")
    data.extra_data = data.extra_data or {}
    data.extra_data.os_ex__xuheUser = player.id

    local tempTargets = table.filter(
      player.room.alive_players,
      function(p) return table.contains(p:getTableMark("@@os_ex__xuhe-turn"), player.id) end
    )
    room.logic:getCurrentEvent():addExitFunc(function()
      table.forEach(tempTargets, function(p)
        room:removeTableMark(p, "@@os_ex__xuhe-turn", player.id)
      end)
    end)
  end,
})

osExXuhe:addEffect(fk.DamageCaused, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return
      target == player and
      table.contains(data.to:getTableMark("@@os_ex__xuhe-turn"), player.id) and
      (parentUseData and (parentUseData.data.extra_data or {}).os_ex__xuheUser == player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data:changeDamage(2)
  end,
})

return osExXuhe

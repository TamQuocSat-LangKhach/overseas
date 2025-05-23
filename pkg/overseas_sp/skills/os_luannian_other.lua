local osLuannianOther = fk.CreateSkill {
  name = "os__luannian_other&"
}

Fk:loadTranslationTable{
  ["os__luannian_other&"] = "乱年",
  [":os__luannian_other&"] = "出牌阶段限一次，你可弃置X张牌对一名“雄争”角色造成1点伤害（X为“乱年”本轮发动的次数+1）。",

  ["#os__luannian_other-active"] = "乱年：你可弃置牌对一名“雄争”角色造成1点伤害",

  ["@os__luannian-round"] = "乱年",
}

osLuannianOther:addEffect("active", {
  mute = true,
  prompt = "#os__luannian_other-active",
  can_use = function(self, player)
    if player:usedSkillTimes(osLuannianOther.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
      local room = Fk:currentRoom()
      local lord --手动
      for _, p in ipairs(room.alive_players) do
        if p:hasSkill("os__luannian") and p ~= player then
          lord = p
          break
        end
      end
      if not lord then return false end
      local target
      for _, p in ipairs(room.alive_players) do
        if p:getMark("_os__xiongzheng-round") > 0 then
          target = p
          break
        end
      end
      if target then
        return true
      end
    end
    return false
  end,
  card_num = function(self, player)
    local lord
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("os__luannian") and p ~= player then
        lord = p
        break
      end
    end
    return lord:getMark("@os__luannian-round") + 1
  end,
  card_filter = function(self, player, to_select, selected)
    local lord
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("os__luannian") and p ~= player then
        lord = p
        break
      end
    end
    return #selected < lord:getMark("@os__luannian-round") + 1 and not player:prohibitDiscard(to_select)
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select:getMark("_os__xiongzheng-round") > 0
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osLuannianOther.name
    local player = effect.from
    local target = effect.tos[1]
    room:notifySkillInvoked(player, "os__luannian")
    player:broadcastSkillInvoke("os__luannian")
    if not target:isAlive() then
      return
    end

    room:doIndicate(effect.from, { target })
    local lord
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__luannian") and p ~= player then
        lord = p
        break
      end
    end
    room:addPlayerMark(lord, "@os__luannian-round", 1)
    room:throwCard(effect.cards, skillName, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = skillName,
    }
  end,
})

return osLuannianOther

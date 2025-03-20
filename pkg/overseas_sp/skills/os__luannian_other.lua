local os__luannian_other = fk.CreateSkill {
  name = "os__luannian_other&"
}

Fk:loadTranslationTable{
  ['os__luannian_other&'] = '乱年',
  ['os__luannian'] = '乱年',
  ['@os__luannian-round'] = '乱年',
  [':os__luannian_other&'] = '出牌阶段限一次，你可弃置X张牌对“雄争”角色造成1点伤害（X为“乱年”本轮发动的次数+1）。',
}

os__luannian_other:addEffect('active', {
  anim_type = "offensive",
  mute = true,
  can_use = function(self, player)
    if player:usedSkillTimes(skill.name, Player.HistoryPhase) < 1 and player.kingdom == "qun" then
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
    return #selected < lord:getMark("@os__luannian-round") + 1
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, "os__luannian")
    player:broadcastSkillInvoke("os__luannian")
    local target
    for _, p in ipairs(room.alive_players) do
      if p:getMark("_os__xiongzheng-round") > 0 then
        target = p
        break
      end
    end
    if not target then return false end
    room:doIndicate(effect.from, { target.id })
    local lord
    for _, p in ipairs(room.alive_players) do
      if p:hasSkill("os__luannian") and p ~= player then 
        lord = p 
        break 
      end
    end
    room:addPlayerMark(lord, "@os__luannian-round", 1)
    local discards = room:askToDiscard(player, {
      min_num = lord:getMark("@os__luannian-round") + 1,
      max_num = lord:getMark("@os__luannian-round") + 1,
      skill_name = skill.name,
      cancelable = false
    })
    if discards then
      room:throwCard(discards, skill.name, player)
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = skill.name,
      }
    end
  end,
})

return os__luannian_other

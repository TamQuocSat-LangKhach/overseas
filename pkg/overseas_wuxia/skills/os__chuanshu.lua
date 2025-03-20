local os__chuanshu = fk.CreateSkill {
  name = "os__chuanshu"
}

Fk:loadTranslationTable{
  ['os__chuanshu'] = '传术',
  ['#os__chuanshu-ask'] = '传术：选择一名角色：其拼点牌点数+3且下一张【杀】伤害+1直到你下回合开始',
  ['@os__chuanshu'] = '传术',
  ['#os__chuanshu_delay'] = '传术',
  [':os__chuanshu'] = '限定技，准备阶段开始时，你可选择一名角色：直到你下回合开始，其拼点牌点数+3，且其使用下一张【杀】对你以外的角色造成伤害+1，且此【杀】造成伤害时，若其不为你，你摸等同伤害值的牌。',
  ['$os__chuanshu1'] = '此术集百家之法，当传万世。',
  ['$os__chuanshu2'] = '某虽无名于世，此术可传之万年。',
}

os__chuanshu:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__chuanshu.name) and player.phase == Player.Start
      and player:usedSkillTimes(os__chuanshu.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__chuanshu-ask",
      skill_name = os__chuanshu.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    room:addTableMark(to, "@os__chuanshu", player.general)
    room:addTableMark(to, "_os__chuanshu_slash", player.id)
    room:addTableMark(player, "_os__chuanshu", {to.id, player.general})
  end,
})

os__chuanshu:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:getMark("@os__chuanshu") == 0 then return false end
    local parentUseEvent = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseEvent then
      local parentUseData = parentUseEvent.data[1]
      if parentUseData.card == data.card and (parentUseData.extra_data or {}).os__chuanshuUser == player.id then
        local froms = (parentUseData.extra_data or {}).os__chuanshuSource
        return #froms > 1 or froms[1] ~= data.to.id
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__chuanshu.name, "offensive")
    player:broadcastSkillInvoke("os__chuanshu")
    local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData == nil then return end
    local invoker = {}
    local froms = (parentUseData.data[1].extra_data or {}).os__chuanshuSource
    table.removeOne(froms, data.to.id)
    data.damage = data.damage + #froms
    for _, pid in ipairs(froms) do
      local p = room:getPlayerById(pid)
      if not p.dead and pid ~= player.id then
        p:drawCards(data.damage, os__chuanshu.name)
      end
    end
  end,
})

os__chuanshu:addEffect(fk.PindianCardsDisplayed, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@os__chuanshu") ~= 0 and (data.from == player or table.contains(data.tos, player))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__chuanshu.name, "special")
    player:broadcastSkillInvoke("os__chuanshu")
    local num = 3 * #player:getMark("@os__chuanshu")
    room:changePindianNumber(data, player, num, os__chuanshu.name)
  end,
})

os__chuanshu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chuanshu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, dat in ipairs(player:getMark("_os__chuanshu")) do
      room:removeTableMark(room:getPlayerById(dat[1]), "@os__chuanshu", dat[2])
    end
    room:setPlayerMark(player, "_os__chuanshu", 0)
  end,
})

os__chuanshu:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chuanshu_slash") ~= 0 and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.os__chuanshuUser = player.id
    data.extra_data.os__chuanshuSource = player:getMark("_os__chuanshu_slash")
    room:setPlayerMark(player, "_os__chuanshu_slash", 0)
  end,
})

os__chuanshu:addEffect(fk.BuryVictim, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("_os__chuanshu") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, dat in ipairs(player:getMark("_os__chuanshu")) do
      room:removeTableMark(room:getPlayerById(dat[1]), "@os__chuanshu", dat[2])
    end
    room:setPlayerMark(player, "_os__chuanshu", 0)
  end,
})

return os__chuanshu

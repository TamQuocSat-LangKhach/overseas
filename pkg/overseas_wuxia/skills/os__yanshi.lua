local os__yanshi = fk.CreateSkill {
  name = "os__yanshi"
}

Fk:loadTranslationTable{
  ['os__yanshi'] = '言誓',
  ['@@os__oath'] = '誓',
  ['#os__yanshi-choose'] = '言誓：请选择一名其他角色',
  ['@os__yanshi'] = '言誓',
  [':os__yanshi'] = '①游戏开始时，你选择一名其他角色。②当你或“言誓”角色受到除你与其以外的角色造成的伤害后，若伤害来源没有“誓”，伤害来源获得1枚“誓”。③你对有“誓”的角色使用牌无距离限制且对其造成的伤害+1。④当你对有“誓”的角色造成伤害后，你摸等同于伤害数的牌并弃其1枚“誓”。',
  ['$os__yanshi1'] = '骨肉至亲，血脉相连。',
  ['$os__yanshi2'] = '挟长持短，昼夜哀酸！',
  ['$os__yanshi3'] = '当以贼血，污此白刃！',
}

os__yanshi:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__yanshi.name) then return false end
    return true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__yanshi-choose",
      skill_name = os__yanshi.name,
      cancelable = false
    })
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    player:broadcastSkillInvoke(os__yanshi.name, 1)
    room:notifySkillInvoked(player, os__yanshi.name, "special")
    room:setPlayerMark(player, "@os__yanshi", to.general)
    room:setPlayerMark(player, "_os__yanshi", to.id)
  end,
})

os__yanshi:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__yanshi.name) then return false end
    return (target == player or player:getMark("_os__yanshi") == target.id) and not target.dead and data.from and not data.from.dead and data.from:getMark("@@os__oath") == 0 and data.from ~= player and data.from ~= player.room:getPlayerById(player:getMark("_os__yanshi"))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os__yanshi.name, 2)
    room:notifySkillInvoked(player, os__yanshi.name, "masochism")
    room:addPlayerMark(data.from, "@@os__oath")
  end,
})

os__yanshi:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__yanshi.name) then return false end
    return target == player and not data.to.dead and data.to:getMark("@@os__oath") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(data.damage, os__yanshi.name)
    room:removePlayerMark(data.to, "@@os__oath")
  end,
})

os__yanshi:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__yanshi.name) then return false end
    return target == player and data.to:getMark("@@os__oath") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os__yanshi.name, 3)
    room:notifySkillInvoked(player, os__yanshi.name, "offensive")
    data.damage = data.damage + 1
  end,
})

os__yanshi:addEffect('targetmod', {
  bypass_distances = function(self, from, _, _, to)
    if from and from:hasSkill(os__yanshi.name) and to then
      return to:getMark("@@os__oath") > 0
    end
  end,
})

return os__yanshi

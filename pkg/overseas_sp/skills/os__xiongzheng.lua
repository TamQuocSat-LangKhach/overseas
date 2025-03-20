local os__xiongzheng = fk.CreateSkill {
  name = "os__xiongzheng"
}

Fk:loadTranslationTable{
  ['os__xiongzheng'] = '雄争',
  ['#os__xiongzheng-ask'] = '你可对一名未被“雄争”选择过的角色发动“雄争”',
  ['#os__xiongzheng_judge'] = '雄争',
  ['@os__xiongzheng'] = '雄争',
  ['os__xiongzheng_slash'] = '视为对任意名本轮未对“雄争”角色造成伤害的其他角色使用【杀】',
  ['os__xiongzheng_draw'] = '令任意名本轮对对“雄争”角色造成过伤害的角色摸两张牌',
  ['#os__xiongzheng-slash'] = '选择任意名角色，视为分别对这些角色使用【杀】',
  ['#os__xiongzheng-draw'] = '选择任意名角色，各摸两张牌',
  [':os__xiongzheng'] = '每轮开始时，你可选择一名未被此技能选择过的角色。若如此做，则本轮结束时，你可选择一项：1. 视为依次对任意名本轮未对其造成过伤害的其他角色使用一张【杀】；2. 令任意名本轮对其造成过伤害的角色摸两张牌。',
  ['$os__xiongzheng1'] = '西凉男儿，怀天下之志！',
  ['$os__xiongzheng2'] = '金戈铁马，争乱世之雄！',
}

os__xiongzheng:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__xiongzheng.name) then return false end
    player.room:setPlayerMark(player, "@" .. os__xiongzheng.name, 0)
    local targets = table.map(
      table.filter(player.room.alive_players, function(p)
        return (p:getMark("_os__xiongzheng") == 0)
      end), Util.IdMapper )
    if #targets > 0 then
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player)
    local targets = table.map(
      table.filter(player.room.alive_players, function(p)
        return (p:getMark("_os__xiongzheng") == 0)
      end), Util.IdMapper )
    local target = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__xiongzheng-ask",
      skill_name = os__xiongzheng.name,
      cancelable = true
    })
    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local target = room:getPlayerById(event:getCostData(skill))
    room:setPlayerMark(player, "@" .. os__xiongzheng.name, target.general)
    room:addPlayerMark(target, "_os__xiongzheng", 1)
    room:addPlayerMark(target, "_os__xiongzheng-round", 1)
  end,
})

os__xiongzheng:addEffect(fk.RoundEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__xiongzheng.name) and player:getMark("@os__xiongzheng") ~= 0
  end,
  on_cost = function(self, event, target, player)
    local choices = {"os__xiongzheng_slash", "os__xiongzheng_draw", "Cancel"}
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = os__xiongzheng.name
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__xiongzheng.name)
    local choice = event:getCostData(skill)
    if choice == "os__xiongzheng_slash" then
      local availableTargets = table.map(
        table.filter(room:getOtherPlayers(player, false), function(p)
          return (p:getMark("_os__xiongzheng_damage-round") == 0)
        end),
        Util.IdMapper
      )
      local targets = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = #availableTargets,
        prompt = "#os__xiongzheng-slash",
        skill_name = os__xiongzheng.name,
        cancelable = true
      })
      if #targets > 0 then
        room:notifySkillInvoked(player, "os__xiongzheng")
        local slash = Fk:cloneCard("slash")
        slash.skillName = os__xiongzheng.name
        local new_use = {} ---@type CardUseStruct
        new_use.from = player.id
        new_use.card = slash
        room:sortPlayersByAction(targets)
        for _, pid in ipairs(targets) do
          if player.dead or room:getPlayerById(pid).dead then return false end
          room:useVirtualCard("slash", nil, player, {room:getPlayerById(pid)}, os__xiongzheng.name, true)
        end
      end
    else
      local availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return (p:getMark("_os__xiongzheng_damage-round") > 0)
        end),
        Util.IdMapper
      )
      local targets = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = #availableTargets,
        prompt = "#os__xiongzheng-draw",
        skill_name = os__xiongzheng.name,
        cancelable = true
      })
      if #targets > 0 then
        room:notifySkillInvoked(player, "os__xiongzheng", "drawcard")
        room:sortPlayersByAction(targets)
        table.forEach(targets, function(pid)
          room:getPlayerById(pid):drawCards(2, os__xiongzheng.name)
        end)
      end
    end
  end,
})

return os__xiongzheng

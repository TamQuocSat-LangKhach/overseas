local os__zongkui = fk.CreateSkill {
  name = "os__zongkui"
}

Fk:loadTranslationTable{
  ['os__zongkui'] = '纵傀',
  ['@@os__puppet'] = '傀',
  ['#os__zongkui-ask'] = '纵傀：选择一名其他角色，令其获得一枚“傀”',
  [':os__zongkui'] = '回合开始后，你可指定一名没有“傀”的其他角色，令其获得1枚“傀”。每轮开始时，体力值最小且没有“傀”的一名其他角色获得1枚“傀”。',
  ['$os__zongkui1'] = '不要抵抗，接受我的操纵吧。',
  ['$os__zongkui2'] = '当我的傀儡，你将受益良多。',
}

os__zongkui:addEffect(fk.RoundStart, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__zongkui.name) then return false end
    local targets = table.filter(player.room.alive_players, function(p)
      return p:getMark("@@os__puppet") == 0 and p ~= player
    end)
    if #targets > 0 then
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local n = 999
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      if p.hp < n then
        n = p.hp
      end
    end
    local availableTargets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("@@os__puppet") == 0 and p.hp == n and p ~= player
    end), Util.IdMapper)
    if #availableTargets == 0 then return false end
    local target = room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__zongkui-ask",
        skill_name = os__zongkui.name,
        cancelable = false
      }
    )
    event:setCostData(skill, #target > 0 and target[1] or table.random(availableTargets)) --权宜
    return true
  end,
  on_use = function(self, event, target, player)
    local cost_data = event:getCostData(skill)
    player.room:addPlayerMark(player.room:getPlayerById(cost_data), "@@os__puppet")
  end,
})

os__zongkui:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__zongkui.name) or (event == fk.TurnStart and target ~= player) then return false end
    local targets = table.filter(player.room.alive_players, function(p)
      return p:getMark("@@os__puppet") == 0 and p ~= player
    end)
    if #targets > 0 then
      return true
    end
    return false
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p:getMark("@@os__puppet") == 0 and p ~= player
    end), Util.IdMapper)
    local target = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__zongkui-ask",
        skill_name = os__zongkui.name,
        cancelable = true
      }
    )
    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local cost_data = event:getCostData(skill)
    player.room:addPlayerMark(player.room:getPlayerById(cost_data), "@@os__puppet")
  end,
})

return os__zongkui

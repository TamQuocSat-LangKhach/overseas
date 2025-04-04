local os__dingzhen = fk.CreateSkill {
  name = "os__dingzhen"
}

Fk:loadTranslationTable{
  ['os__dingzhen'] = '定镇',
  ['#os__dingzhen-ask'] = '你可对任意名至你距离 %arg 以内的角色发动“定镇”',
  ['#os__dingzhen-discard'] = '定镇：弃置一张【杀】，否则本轮中回合内使用的第一张牌不能指定 %dest 为目标',
  ['@@os__dingzhen-round'] = '定镇',
  [':os__dingzhen'] = '每轮开始时，你可选择至你距离为X以内的任意名角色（X为你当前体力值），令这些角色弃置一张【杀】，否则本轮中其回合内使用的第一张牌不能指定你为目标。',
  ['$os__dingzhen1'] = '招抚流民，兴复县邑。',
  ['$os__dingzhen2'] = '容民畜众，群羌归土。',
}

os__dingzhen:addEffect(fk.RoundStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__dingzhen.name) then return false end
    local num = player.hp
    return table.find(player.room.alive_players, function(p)
      return p:compareDistance(player, num, "<=")
    end)
  end,
  on_cost = function(self, event, target, player)
    local num = player.hp
    local available_targets = table.map(
      table.filter(player.room.alive_players, function(p)
        return p:compareDistance(player, num, "<=")
      end),
      Util.IdMapper
    )
    local targets = player.room:askToChoosePlayers(player, {
      targets = available_targets,
      min_num = 1,
      max_num = 99,
      prompt = "#os__dingzhen-ask:::" .. tostring(player.hp),
      skill_name = os__dingzhen.name,
      cancelable = true
    })
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local targets = event:getCostData(self)
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local p = room:getPlayerById(pid)
      if not p.dead then
        local discard = room:askToDiscard(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          pattern = "slash",
          prompt = "#os__dingzhen-discard::" .. player.id,
          skill_name = os__dingzhen.name
        })
        if #discard == 0 then
          room:setPlayerMark(p, "@@os__dingzhen-round", 1)
          room:addTableMark(p, "_os__dingzhen_to-round", player.id)
        end
      end
    end
  end,
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@@os__dingzhen-round") > 0 and player.phase ~= Player.NotActive and player:getMark("_os__dingzhen_use-turn") == 0
  end,
  on_refresh = function(self, event, target, player)
    player.room:setPlayerMark(player, "_os__dingzhen_use-turn", 1)
  end,
})

local os__dingzhen_prohibit = fk.CreateSkill {
  name = "#os__dingzhen_prohibit"
}
os__dingzhen_prohibit:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@os__dingzhen-round") > 0 and table.contains(from:getTableMark("_os__dingzhen_to-round"), to.id)
      and from:getMark("_os__dingzhen_use-turn") == 0 and from.phase ~= Player.NotActive
  end,
})

return os__dingzhen

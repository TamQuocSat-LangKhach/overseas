local os__zhengrong = fk.CreateSkill {
  name = "os__zhengrong"
}

Fk:loadTranslationTable{
  ['os__zhengrong'] = '征荣',
  ['#os__zhengrong-ask'] = '征荣：你可选择一名其他角色，将其一张牌置于你的武将牌上',
  ['$os__glory'] = '荣',
  [':os__zhengrong'] = '当你于你的出牌阶段对其他角色使用（此局游戏）累计偶数张牌结算结束后，或当你于出牌阶段第一次造成伤害后，你可选择一名其他角色，将其一张牌扣置于你的武将牌上，称为“荣”。',
  ['$os__zhengrong1'] = '此役兵戈所向，贼众望风披靡。',
  ['$os__zhengrong2'] = '世袭兵道，唯愿一扫蛮夷。',
}

os__zhengrong:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__zhengrong) and player.phase == Player.Play then
      return (data.extra_data or {}).os__zhengrong_able
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return (not p:isNude())
      end),
      Util.IdMapper
    )
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__zhengrong-ask",
      skill_name = os__zhengrong.name,
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = os__zhengrong.name,
    })
    player:addToPile("$os__glory", card, false, os__zhengrong.name)
  end,
})

os__zhengrong:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__zhengrong) and player.phase == Player.Play then
      local _data = player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].from == player end, Player.HistoryPhase)
      return #_data > 0 and _data[1].data[1] == data
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return (not p:isNude())
      end),
      Util.IdMapper
    )
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__zhengrong-ask",
      skill_name = os__zhengrong.name,
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = os__zhengrong.name,
    })
    player:addToPile("$os__glory", card, false, os__zhengrong.name)
  end,
})

os__zhengrong:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__zhengrong, true) and player.phase == Player.Play
      and table.find(TargetGroup:getRealTargets(data.tos), function(pid) return pid ~= player.id end)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "_os__zhengrong_count")
    if player:getMark("_os__zhengrong_count") % 2 == 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.os__zhengrong_able = true
    end
  end,
})

return os__zhengrong

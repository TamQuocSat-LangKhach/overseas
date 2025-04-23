local osZhengrong = fk.CreateSkill {
  name = "os__zhengrong"
}

Fk:loadTranslationTable{
  ["os__zhengrong"] = "征荣",
  [":os__zhengrong"] = "当你于你的出牌阶段对其他角色使用（此局游戏）累计偶数张牌结算结束后，" ..
  "或当你于出牌阶段第一次造成伤害后，你可选择一名其他角色，将其一张牌扣置于你的武将牌上，称为“荣”。",

  ["#os__zhengrong-ask"] = "征荣：你可选择一名其他角色，将其一张牌置于你的武将牌上",
  ["$os__glory"] = "荣",

  ["$os__zhengrong1"] = "此役兵戈所向，贼众望风披靡。",
  ["$os__zhengrong2"] = "世袭兵道，唯愿一扫蛮夷。",
}

osZhengrong:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(osZhengrong.name) and player.phase == Player.Play then
      return (data.extra_data or {}).os__zhengrong_able
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__zhengrong-ask",
        skill_name = osZhengrong.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhengrong.name
    local room = player.room
    local to = event:getCostData(self)
    local card = room:askToChooseCard(
      player,
      {
        target = to,
        flag = "he",
        skill_name = skillName,
      }
    )
    player:addToPile("$os__glory", card, false, skillName, player)
  end,
})

osZhengrong:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(osZhengrong.name) and player.phase == Player.Play then
      local _data = player.room.logic:getActualDamageEvents(1, function(e) return e.data.from == player end, Player.HistoryPhase)
      return #_data > 0 and _data[1].data == data
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__zhengrong-ask",
        skill_name = osZhengrong.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhengrong.name
    local room = player.room
    local to = event:getCostData(self)
    local card = room:askToChooseCard(
      player,
      {
        target = to,
        flag = "he",
        skill_name = skillName,
      }
    )
    player:addToPile("$os__glory", card, false, skillName, player)
  end,
})

osZhengrong:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osZhengrong.name, true) and
      player.phase == Player.Play and
      table.find(data.tos, function(p) return p ~= player end)
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

return osZhengrong

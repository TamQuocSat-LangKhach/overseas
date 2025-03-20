local os__xiangyu = fk.CreateSkill {
  name = "os__xiangyu"
}

Fk:loadTranslationTable{
  ['os__xiangyu'] = '翔羽',
  ['@os__xiangyu-turn'] = '翔羽',
  [':os__xiangyu'] = '锁定技，①你的回合内，每有一名角色失去过牌，本回合你的攻击范围便+1（至多+5）。②你使用【杀】指定一名角色为目标时，若你与其距离小于你的攻击范围，则其需依次使用两张【闪】才能抵消此【杀】。',
  ['$os__xiangyu1'] = '此战必是有死无生！',
  ['$os__xiangyu2'] = '抢占先机，占尽优势！',
}

os__xiangyu:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.card.trueName == "slash" and player:distanceTo(player.room:getPlayerById(data.to)) < player:getAttackRange()
  end,
  on_use = function(self, event, target, player, data)
    data.fixedResponseTimes = data.fixedResponseTimes or {}
    data.fixedResponseTimes["jink"] = 2
  end,
})

os__xiangyu:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then return false end
    local room = player.room
    for _, move in ipairs(data) do
      if move.from and room:getPlayerById(move.from):getMark("_os__xiangyu-turn") == 0 and
        table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local target = {}
    for _, move in ipairs(data) do
      if move.from and room:getPlayerById(move.from):getMark("_os__xiangyu-turn") == 0 and
        table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end) then
        table.insertIfNeed(target, move.from)
      end
    end
    table.forEach(target, function(pid)
      room:addPlayerMark(room:getPlayerById(pid), "_os__xiangyu-turn")
    end)
    local num = math.min(5, player:getMark("_os__xiangyu_num-turn") + #target)
    room:setPlayerMark(player, "_os__xiangyu_num-turn", num)
    if player:hasSkill(skill.name, true) then room:setPlayerMark(player, "@os__xiangyu-turn", num) end
  end,
})

local os__xiangyuAR = fk.CreateAttackRangeSkill{
  name = "#os__xiangyuAR",
  correct_func = function(self, from, to)
    return from:hasSkill(os__xiangyu.name) and from:getMark("_os__xiangyu_num-turn") or 0
  end,
}

return os__xiangyu

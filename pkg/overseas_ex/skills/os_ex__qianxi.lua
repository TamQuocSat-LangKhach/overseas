local os_ex__qianxi = fk.CreateSkill {
  name = "os_ex__qianxi"
}

Fk:loadTranslationTable{
  ['os_ex__qianxi'] = '潜袭',
  ['#os_ex__qianxi-choose'] = '潜袭：选择距离为1的一名角色，令其本回合不能使用或打出 %arg 的手牌',
  ['@os_ex__qianxi'] = '潜袭',
  [':os_ex__qianxi'] = '准备阶段开始时，你可摸一张牌，然后弃置一张牌，令距离为1的一名角色本回合不能使用或打出与你以此法弃置的牌颜色相同的手牌，然后结束阶段开始时，若你于本回合使用【杀】对其造成过伤害，你令其不能使用或打出另一种颜色的牌至其下回合结束。',
  ['$os_ex__qianxi1'] = '暗影深处，袭敌斩首！',
  ['$os_ex__qianxi2'] = '擒贼先擒王，打蛇打七寸！',
}

os_ex__qianxi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os_ex__qianxi) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(1, os_ex__qianxi.name)
    if player.dead then return end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os_ex__qianxi.name,
      cancelable = false,
      pattern = ".",
      prompt = "#qianxi-discard"
    })
    if player.dead then return end
    local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
      return player:distanceTo(p) == 1 end), Util.IdMapper)
    if #targets == 0 then return false end
    local color = Fk:getCardById(card[1]):getColorString()
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__qianxi-choose:::" .. color,
      skill_name = os_ex__qianxi.name,
      cancelable = false
    })[1]
    room:setPlayerMark(room:getPlayerById(to), "@qianxi-turn", color)
    room:setPlayerMark(player, "_os_ex__qianxi_target-turn", to)
  end,
})

os_ex__qianxi:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player)
    if target ~= player then return end
    if player.phase == Player.Finish and player:getMark("_os_ex__qianxi_done-turn") > 0 then return true end
    return false
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local p = room:getPlayerById(player:getMark("_os_ex__qianxi_target-turn"))
    if p then
      room:setPlayerMark(p, "@os_ex__qianxi", p:getMark("@qianxi-turn") == "red" and "black" or "red")
    end
  end,
})

os_ex__qianxi:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return not data.to.dead and player:getMark("_os_ex__qianxi_target-turn") == data.to.id
      and data.card and data.card.trueName == "slash" and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "_os_ex__qianxi_done-turn", 1)
  end,
})

os_ex__qianxi:addEffect(fk.AfterTurnEnd, {
  can_refresh = function(self, event, target, player)
    return player:getMark("@os_ex__qianxi") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@os_ex__qianxi", 0)
  end,
})

local os_ex__qianxi_prohibit = fk.CreateSkill {
  name = "os_ex__qianxi_prohibit"
}

os_ex__qianxi_prohibit:addEffect('prohibit', {
  prohibit_use = function(self, player, card)
    if player:getMark("@os_ex__qianxi") ~= 0 and card:getColorString() == player:getMark("@os_ex__qianxi") then return true end
    if player:getMark("@qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@qianxi-turn") then return true end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@os_ex__qianxi") ~= 0 and card:getColorString() == player:getMark("@os_ex__qianxi") then return true end
    if player:getMark("@qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@qianxi-turn") then return true end
  end,
})

return os_ex__qianxi, os_ex__qianxi_prohibit

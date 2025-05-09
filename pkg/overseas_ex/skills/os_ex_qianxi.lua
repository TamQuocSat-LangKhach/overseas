local osExQianxi = fk.CreateSkill {
  name = "os_ex__qianxi"
}

Fk:loadTranslationTable{
  ["os_ex__qianxi"] = "潜袭",
  [":os_ex__qianxi"] = "准备阶段开始时，你可摸一张牌，然后弃置一张牌，令距离为1的一名角色本回合不能使用或打出与你以此法弃置的牌颜色相同的手牌，" ..
  "然后结束阶段开始时，若你于本回合使用【杀】对其造成过伤害，你令其不能使用或打出另一种颜色的牌至其下回合结束。",

  ["#os_ex__qianxi-choose"] = "潜袭：选择距离为1的一名角色，令其本回合不能使用或打出 %arg 的手牌",
  ["@os_ex__qianxi"] = "潜袭",

  ["$os_ex__qianxi1"] = "暗影深处，袭敌斩首！",
  ["$os_ex__qianxi2"] = "擒贼先擒王，打蛇打七寸！",
}

osExQianxi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osExQianxi.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExQianxi.name
    local room = player.room
    player:drawCards(1, skillName)
    if not player:isAlive() then
      return false
    end

    local card = room:askToDiscard(
      player,
      {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skillName,
        cancelable = false,
        prompt = "#qianxi-discard",
      }
    )
    if not player:isAlive() then
      return false
    end

    local targets = table.filter(
      room:getOtherPlayers(player, false),
      function(p)
        return player:distanceTo(p) == 1
      end
    )
    if #targets == 0 then
      return false
    end

    local color = Fk:getCardById(card[1]):getColorString()
    local to = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os_ex__qianxi-choose:::" .. color,
        skill_name = skillName,
        cancelable = false,
      }
    )[1]
    room:setPlayerMark(to, "@qianxi-turn", color)
    room:setPlayerMark(player, "_os_ex__qianxi_target-turn", to.id)
  end,
})

osExQianxi:addEffect(fk.EventPhaseStart, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player.phase == Player.Finish and
      player:getMark("_os_ex__qianxi_target-turn") ~= 0 and
      #player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        local to = damage.to
        return
          damage.from == player and
          to and
          damage.card ~= nil and
          damage.card.trueName == "slash" and
          player:getMark("_os_ex__qianxi_target-turn") == to.id
      end, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local p = room:getPlayerById(player:getMark("_os_ex__qianxi_target-turn"))
    if p then
      room:setPlayerMark(p, "@os_ex__qianxi", p:getMark("@qianxi-turn") == "red" and "black" or "red")
    end
  end,
})

osExQianxi:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@os_ex__qianxi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os_ex__qianxi", 0)
  end,
})

osExQianxi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@os_ex__qianxi") ~= 0 and card:getColorString() == player:getMark("@os_ex__qianxi") then return true end
    if player:getMark("@qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@qianxi-turn") then return true end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@os_ex__qianxi") ~= 0 and card:getColorString() == player:getMark("@os_ex__qianxi") then return true end
    if player:getMark("@qianxi-turn") ~= 0 and card:getColorString() == player:getMark("@qianxi-turn") then return true end
  end,
})

return osExQianxi

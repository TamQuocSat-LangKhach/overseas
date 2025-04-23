local osQingkou = fk.CreateSkill {
  name = "os__qingkou"
}

Fk:loadTranslationTable{
  ["os__qingkou"] = "轻寇",
  [":os__qingkou"] = "准备阶段开始时，你可视为使用一张【决斗】。此【决斗】结算结束后，造成伤害的角色摸一张牌，若为你，你跳过此回合的判定阶段和弃牌阶段。",

  ["#os__qingkou-ask"] = "轻寇：你可选择一名其他角色，视为对其使用一张【决斗】",

  ["$os__qingkou1"] = "哈哈哈哈，鼠辈岂能当我大汉雄师？",
  ["$os__qingkou2"] = "凛凛汉将，岂畏江东鼠辈？",
}

osQingkou:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osQingkou.name) and
      player.phase == Player.Start and
      player:canUse(Fk:cloneCard("duel"))
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local use = room:askToUseVirtualCard(
      player,
      {
        name = "duel",
        skill_name = osQingkou.name,
        skip = true,
      }
    )
    if use then
      event:setCostData(self, use)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osQingkou.name
    local room = player.room
    local use = event:getCostData(self)
    room:useCard(use)

    local damage = (use.extra_data or {}).os__qingkouDamage
    if damage then
      local players = {}
      for k, _ in pairs(damage) do
        table.insert(players, room:getPlayerById(k))
      end
      room:sortByAction(players)
      for _, p in ipairs(players) do
        if p:isAlive() then
          p:drawCards(damage[p.id], skillName)
          if p == player then
            p:broadcastSkillInvoke(skillName)
            p:skip(Player.Judge)
            p:skip(Player.Discard)
          end
        end
      end
    end
  end,
})

osQingkou:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, osQingkou.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local use = room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data
    use.extra_data = use.extra_data or {}
    use.extra_data.os__qingkouDamage = use.extra_data.os__qingkouDamage or {}
    use.extra_data.os__qingkouDamage[player.id] = (use.extra_data.os__qingkouDamage[player.id] or 0) + 1
  end,
})

return osQingkou

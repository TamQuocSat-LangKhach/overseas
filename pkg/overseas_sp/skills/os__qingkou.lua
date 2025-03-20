local os__qingkou = fk.CreateSkill {
  name = "os__qingkou"
}

Fk:loadTranslationTable{
  ['os__qingkou'] = '轻寇',
  ['#os__qingkou-ask'] = '轻寇：你可选择一名其他角色，视为对其使用一张【决斗】',
  [':os__qingkong'] = '准备阶段开始时，你可视为使用一张【决斗】。此【决斗】结算结束后，造成伤害的角色摸一张牌，若为你，你跳过此回合的判定阶段和弃牌阶段。',
  ['$os__qingkou1'] = '哈哈哈哈，鼠辈岂能当我大汉雄师？',
  ['$os__qingkou2'] = '凛凛汉将，岂畏江东鼠辈？',
}

os__qingkou:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__qingkou) and
      player.phase == Player.Start and player:canUse(Fk:cloneCard("duel"))
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local card = Fk:cloneCard("duel")
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return player:canUseTo(card, p, { bypass_times = true, bypass_distances = true })
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local targets = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      prompt = "#os__qingkou-ask",
      skill_name = os__qingkou.name,
      cancelable = true,
      targets = availableTargets
    })
    if #targets > 0 then
      event:setCostData(self, targets[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local card = Fk:cloneCard("duel")
    card.skillName = os__qingkou.name
    local use = { ---@type CardUseStruct
      from = player.id,
      tos = {{event:getCostData(self)}},
      card = card,
    }
    room:useCard(use)
    local damage = (use.extra_data or {}).os__qingkouDamage
    if damage then
      local players = {}
      for k, _ in pairs(damage) do
        table.insert(players, k)
      end
      room:sortPlayersByAction(players)
      for _, pid in ipairs(players) do
        local p = room:getPlayerById(pid)
        if not p.dead then
          p:drawCards(damage[pid], os__qingkou.name)
          if pid == player.id then
            p:broadcastSkillInvoke(os__qingkou.name)
            p:skip(Player.Judge)
            p:skip(Player.Discard)
          end
        end
      end
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, os__qingkou.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local use = room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data[1]
    use.extra_data = use.extra_data or {}
    use.extra_data.os__qingkouDamage = use.extra_data.os__qingkouDamage or {}
    use.extra_data.os__qingkouDamage[player.id] = (use.extra_data.os__qingkouDamage[player.id] or 0) + 1
  end,
})

return os__qingkou

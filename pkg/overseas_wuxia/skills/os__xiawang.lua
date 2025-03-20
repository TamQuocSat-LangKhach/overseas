local os__xiawang = fk.CreateSkill {
  name = "os__xiawang"
}

Fk:loadTranslationTable{
  ['os__xiawang'] = '侠望',
  ['#os__xiawang-ask'] = '你可对 %src 使用【杀】。若此【杀】造成了伤害，则在当前伤害事件结束结算后结束当前阶段',
  [':os__xiawang'] = '当至你距离不大于1的角色受到黑色牌造成的伤害后，你可对伤害来源使用【杀】。若此【杀】造成了伤害，则在当前伤害结束结算后结束当前阶段。',
  ['$os__xiawang1'] = '天下兴亡，侠客当为之己任。',
  ['$os__xiawang2'] = '隐居江湖之远，敢争天下之先！',
}

os__xiawang:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__xiawang.name) and target:distanceTo(player) < 2 and data.card and data.card.color == Card.Black and not (target.dead or player.dead) and data.from and not (data.from.dead or data.from == player)
  end,
  on_cost = function(self, event, target, player, data)
    local use = player.room:askToUseCard(player, {
      skill_name = "os__xiawang-ask:" .. data.from.id,
      pattern = "slash",
      extra_data = { exclusive_targets = {data.from.id}, bypass_distances = true }
    })
    if use then
      event:setCostData(skill.name, use)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = event:getCostData(skill.name)
    use.extra_data = use.extra_data or {}
    use.extra_data.os__xiawangUser = player.id
    room:useCard(use)
    if player:getMark("_os__xiawang-phase") > 0 then
      data.os__xiawang = true
    end
  end,

  can_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return parentUseData and (parentUseData.data[1].extra_data or {}).os__xiawangUser == player.id
    else
      return data.os__xiawang == true
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "_os__xiawang-phase")
    else
      local current = player.room.logic:getCurrentEvent()
      local use_event = current:findParent(GameEvent.UseCard)
      if not use_event then return end
      local phase_event = use_event:findParent(GameEvent.Phase)
      if not phase_event then return end
      use_event:addExitFunc(function()
        phase_event:shutdown()
      end)
    end
  end,
})

return os__xiawang

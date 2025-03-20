local os__moukui = fk.CreateSkill {
  name = "os__moukui"
}

Fk:loadTranslationTable{
  ['os__moukui'] = '谋溃',
  ['os__moukui_draw'] = '摸一张牌',
  ['os__moukui_discard'] = '弃置其一张手牌',
  ['beishui_os__moukui'] = '背水：若此【杀】未令其进入濒死状态，其弃置你一张牌',
  ['#os__moukui_delay'] = '谋溃',
  [':os__moukui'] = '当你使用【杀】指定目标后，你可选择一项：1.摸一张牌；2.弃置其一张手牌；背水：此【杀】结算后，若此【杀】未令其进入濒死状态，其弃置你一张牌。',
  ['$os__moukui1'] = '你的死期到了。',
  ['$os__moukui2'] = '同归于尽吧。',
}

os__moukui:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__moukui.name) and
      data.card.trueName == "slash" and data.to
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"os__moukui_draw", "os__moukui_discard", "beishui_os__moukui", "Cancel"}
    local choices = table.clone(all_choices)
    local target = room:getPlayerById(data.to)
    if target:isKongcheng() then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__moukui.name,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self)
    local target = room:getPlayerById(data.to)
    if choice ~= "os__moukui_discard" then
      player:drawCards(1, os__moukui.name)
    end
    if choice ~= "os__moukui_draw" then
      if not target:isKongcheng() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "h",
          skill_name = os__moukui.name,
        })
        room:throwCard(card, os__moukui.name, target, player)
      end
      if choice == "beishui_os__moukui" then
        data.card.extra_data = data.card.extra_data or {}
        data.card.extra_data.os__moukuiUser = player.id
        data.card.extra_data.os__moukuiTargets = data.card.extra_data.os__moukuiTargets or {}
        table.insert(data.card.extra_data.os__moukuiTargets, target.id)
      end
    end
  end,
})

os__moukui:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return player == target and (data.card.extra_data or {}).os__moukuiUser == player.id and (data.card.extra_data or {}).os__moukuiTargets
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs((data.card.extra_data or {}).os__moukuiTargets) do
      local target = room:getPlayerById(pid)
      if target and not player:isNude() and not target.dead then
        room:throwCard(room:askToChooseCard(target, {
          target = player,
          flag = "he",
          skill_name = os__moukui.name,
        }), os__moukui.name, player, target)
      end
    end
  end,
})

os__moukui:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return data.damage and data.damage.card and (data.damage.card.extra_data or {}).os__moukuiUser == player.id and (data.damage.card.extra_data or {}).os__moukuiTargets and table.contains((data.damage.card.extra_data or {}).os__moukuiTargets, target.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    table.removeOne((data.damage.card.extra_data or {}).os__moukuiTargets, target.id)
  end,
})

return os__moukui

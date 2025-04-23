local osMoukui = fk.CreateSkill {
  name = "os__moukui"
}

Fk:loadTranslationTable{
  ["os__moukui"] = "谋溃",
  [":os__moukui"] = "当你使用【杀】指定目标后，你可选择一项：1.摸一张牌；2.弃置其一张手牌；背水：此【杀】结算后，若此【杀】未令其进入濒死状态，其弃置你一张牌。",

  ["os__moukui_draw"] = "摸一张牌",
  ["os__moukui_discard"] = "弃置其一张手牌",
  ["beishui_os__moukui"] = "背水：若此【杀】未令其进入濒死状态，其弃置你一张牌",
  ["#os__moukui_delay"] = "谋溃",

  ["$os__moukui1"] = "你的死期到了。",
  ["$os__moukui2"] = "同归于尽吧。",
}

osMoukui:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osMoukui.name) and
      data.card.trueName == "slash" and
      data.to
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = { "os__moukui_draw", "os__moukui_discard", "beishui_os__moukui", "Cancel" }
    local choices = table.clone(all_choices)
    local to = data.to
    if to:isKongcheng() then
      table.remove(choices, 2)
    end
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osMoukui.name,
        all_choices = all_choices,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osMoukui.name
    local room = player.room
    local choice = event:getCostData(self)
    local to = data.to
    if choice ~= "os__moukui_discard" then
      player:drawCards(1, skillName)
    end
    if choice ~= "os__moukui_draw" then
      if not to:isKongcheng() then
        local card = room:askToChooseCard(
          player,
          {
            target = to,
            flag = "h",
            skill_name = skillName,
          }
        )
        room:throwCard(card, skillName, to, player)
      end
      if choice == "beishui_os__moukui" then
        data.extra_data = data.extra_data or {}
        data.extra_data.os__moukuiUser = player.id
        data.extra_data.os__moukuiTargets = data.extra_data.os__moukuiTargets or {}
        table.insertIfNeed(data.extra_data.os__moukuiTargets, to.id)
      end
    end
  end,
})

osMoukui:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      player == target and (data.extra_data or {}).os__moukuiUser == player.id and (data.extra_data or {}).os__moukuiTargets
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osMoukui.name
    local room = player.room
    for _, pid in ipairs((data.extra_data or {}).os__moukuiTargets) do
      local to = room:getPlayerById(pid)
      if to and not player:isNude() and to:isAlive() then
        room:throwCard(
          room:askToChooseCard(
            to,
            {
              target = player,
              flag = "he",
              skill_name = skillName,
            }
          ),
          skillName,
          player,
          to
        )
      end
    end
  end,
})

osMoukui:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    local useData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return
      data.damage and
      data.damage.card and
      useData and
      (useData.data.extra_data or {}).os__moukuiUser == player.id and
      (useData.data.extra_data or {}).os__moukuiTargets and
      table.contains((useData.data.extra_data or {}).os__moukuiTargets, target.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local useData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if useData and (useData.data.extra_data or {}).os__moukuiTargets then
      table.removeOne(useData.data.extra_data.os__moukuiTargets, target.id)
      if #useData.data.extra_data.os__moukuiTargets == 0 then
        useData.data.extra_data.os__moukuiTargets = nil
      end
    end
  end,
})

return osMoukui

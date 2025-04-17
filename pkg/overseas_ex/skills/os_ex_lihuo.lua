local osExLihuo = fk.CreateSkill {
  name = "os_ex__lihuo"
}

Fk:loadTranslationTable{
  ["os_ex__lihuo"] = "疠火",
  [":os_ex__lihuo"] = "①你使用普【杀】可改为火【杀】，当此【杀】结算结束后，若此【杀】令其他角色进入过濒死状态，" ..
  "你失去1点体力。②当你使用火【杀】选择目标后，可多选择一个目标。",

  ["#os_ex__lihuo-targets"] = "疠火：你可选择一名角色，令其也成为此火【杀】的目标",
  ["#os_ex__lihuo_judge"] = "疠火",

  ["$os_ex__lihuo1"] = "将士们，引火对敌！",
  ["$os_ex__lihuo2"] = "和我同归于尽吧！",
}

osExLihuo:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osExLihuo.name) and data.card.name == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local card = Fk:cloneCard("fire__slash", data.card.suit, data.card.number)
    for k, v in pairs(data.card) do
      if card[k] == nil then
        card[k] = v
      end
    end
    if data.card:isVirtual() then
      card.subcards = data.card.subcards
    else
      card.id = data.card.id
    end
    card.skillNames = data.card.skillNames
    card.skillName = osExLihuo.name
    data.card = card
    data.extra_data = data.extra_data or {}
    data.extra_data.os_ex__lihuoUser = player.id
  end,
})

osExLihuo:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(osExLihuo.name) and data.card.name == "fire__slash"
  end,
  on_cost = function(self, event, target, player, data)
    local targets = data:getExtraTargets({ bypass_times = true })
    if #targets == 0 then
      return false
    end

    local tos = player.room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os_ex__lihuo-targets",
        skill_name = osExLihuo.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self)[1])
  end,
})

osExLihuo:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return
      player:isAlive() and
      (data.extra_data or {}).os_ex__lihuoUser == player.id and
      data.extra_data.os_ex__lihuoDying == true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    player.room:loseHp(player, 1, osExLihuo.name)
  end,
})

osExLihuo:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player, data)
    if target == player or not data.damage or not data.damage.card then
      return false
    end

    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and (parentUseData.data.extra_data or {}).os_ex__lihuoUser == player.id
  end,
  on_refresh = function(self, event, target, player)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if parentUseData then
      parentUseData.data.extra_data = parentUseData.data.extra_data or {}
      parentUseData.data.extra_data.os_ex__lihuoDying = true
    end
  end,
})

return osExLihuo

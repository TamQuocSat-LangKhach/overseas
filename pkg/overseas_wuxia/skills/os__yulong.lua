local os__yulong = fk.CreateSkill {
  name = "os__yulong"
}

Fk:loadTranslationTable{
  ['os__yulong'] = '驭龙',
  ['#os__yulong-ask'] = '驭龙：你可与一名目标拼点',
  [':os__yulong'] = '当你使用【杀】指定第一个目标后，你可与其中一名目标拼点。若你：赢，若此【杀】造成伤害则不计入次数，且你此次的拼点牌为：黑色，此【杀】的伤害+1；红色，此【杀】不可被响应。',
  ['$os__yulong1'] = '三尺青锋，为君驭六龙，定九州！',
  ['$os__yulong2'] = '十年砺剑，当率千军之众，堪万夫之雄！',
}

os__yulong:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.firstTarget and data.card.trueName == "slash" and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = {}
    for _, p in ipairs(room.alive_players) do
      if table.contains(AimGroup:getAllTargets(data.tos), p.id) and player:canPindian(p) then
        table.insert(availableTargets, p.id)
      end
    end

    if #availableTargets == 0 then
      return false
    end
    if #availableTargets == 1 then
      event:setCostData(skill, availableTargets[1])
      return room:askToSkillInvoke(player, {skill_name = skill.name})
    else
      local result = room:askToChoosePlayers(player, {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__yulong-ask",
        skill_name = skill.name,
        cancelable = true
      })
      if #result > 0 then
        event:setCostData(skill, result[1])
        return true
      else
        return false
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(event:getCostData(skill))
    local pd = player:pindian({target}, skill.name, nil)
    if pd.results[event:getCostData(skill)].winner == player then
      data.card.extra_data = data.card.extra_data or {}
      data.card.extra_data.os__yulong = true
      if pd.fromCard.color == Card.Black then
        data.card.extra_data.os__yulongBlack = true
      elseif pd.fromCard.color == Card.Red then
        --data.disresponsive = true
        data.card.extra_data.os__yulongRed = true
      end
    end
  end,
})

os__yulong:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    if not (target == player and data.card and data.card.trueName == "slash") then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    local invoke = parentUseData and (parentUseData.data[1].card.extra_data or {}).os__yulong == true
    if not invoke then return false end
    return (parentUseData.data[1].card.extra_data or {}).os__yulongAddHistory == nil
  end,
  on_refresh = function(self, event, target, player, data)
    player:addCardUseHistory("slash", -1)
    player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard).data[1].card.extra_data.os__yulongAddHistory = true
  end,
})

os__yulong:addEffect(fk.DamageCaused, {
  can_refresh = function(self, event, target, player, data)
    if not (target == player and data.card and data.card.trueName == "slash") then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    local invoke = parentUseData and (parentUseData.data[1].card.extra_data or {}).os__yulong == true
    if not invoke then return false end
    return (parentUseData.data[1].card.extra_data or {}).os__yulongBlack == true
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

os__yulong:addEffect(fk.TargetConfirmed, {
  can_refresh = function(self, event, target, player, data)
    if not (target == player and data.card and data.card.trueName == "slash") then return false end
    return (data.card.extra_data or {}).os__yulongRed == true
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsive = true
  end,
})

return os__yulong

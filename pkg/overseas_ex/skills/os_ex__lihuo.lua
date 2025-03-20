local os_ex__lihuo = fk.CreateSkill {
  name = "os_ex__lihuo"
}

Fk:loadTranslationTable{
  ['os_ex__lihuo'] = '疠火',
  ['#os_ex__lihuo-targets'] = '疠火：你可选择一名角色，令其也成为此火【杀】的目标',
  ['#os_ex__lihuo_judge'] = '疠火',
  [':os_ex__lihuo'] = '①你使用普【杀】可改为火【杀】，当此【杀】结算结束后，若此【杀】令其他角色进入过濒死状态，你失去1点体力。②当你使用火【杀】选择目标后，可多选择一个目标。',
  ['$os_ex__lihuo1'] = '将士们，引火对敌！',
  ['$os_ex__lihuo2'] = '和我同归于尽吧！',
}

os_ex__lihuo:addEffect(fk.AfterCardUseDeclared, {
  can_trigger = function(self, event, target, player)
    if not (target == player and player:hasSkill(os_ex__lihuo.name)) then return false end
    return data.card.name == "slash"
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, { skill_name = os_ex__lihuo.name })
  end,
  on_use = function(self, event, target, player)
    local fireSlash = Fk:cloneCard("fire__slash")
    fireSlash.skillName = os_ex__lihuo.name
    fireSlash:addSubcard(data.card)
    data.card = fireSlash
    data.extra_data = data.extra_data or {}
    data.extra_data.os_ex__lihuoUser = player.id
  end,
})

os_ex__lihuo:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player)
    if not (target == player and player:hasSkill(os_ex__lihuo.name)) then return false end
    return data.card.name == "fire__slash"
  end,
  on_cost = function(self, event, target, player)
    local targets = player.room:getUseExtraTargets(data)
    if #targets == 0 then return false end
    local tos = player.room:askToChoosePlayers(player, { 
      targets = targets, 
      min_num = 1, 
      max_num = 1, 
      prompt = "#os_ex__lihuo-targets", 
      skill_name = os_ex__lihuo.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    table.insert(data.tos, event:getCostData(self))
  end,
})

os_ex__lihuo:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player)
    return not player.dead and (data.extra_data or {}).os_ex__lihuoUser == player.id and data.extra_data.os_ex__lihuoDying == true
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    player.room:loseHp(player, 1, os_ex__lihuo.name)
  end,
})

os_ex__lihuo:addEffect(fk.EnterDying, {
  can_refresh = function(self, event, target, player)
    if target == player or not data.damage or not data.damage.card then return false end
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    return parentUseData and (parentUseData.data[1].extra_data or {}).os_ex__lihuoUser == player.id
  end,
  on_refresh = function(self, event, target, player)
    local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    parentUseData.data[1].extra_data = parentUseData.data[1].extra_data or {}
    parentUseData.data[1].extra_data.os_ex__lihuoDying = true
  end,
})

return os_ex__lihuo

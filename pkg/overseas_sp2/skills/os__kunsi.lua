local os__kunsi = fk.CreateSkill {
  name = "os__kunsi"
}

Fk:loadTranslationTable{
  ['os__kunsi'] = '困兕',
  ['#os__kunsi-promot'] = '困兕：视为对一名未指定过的角色使用【杀】（无次数和距离限制）',
  ['os__linglu'] = '令戮',
  [':os__kunsi'] = '出牌阶段，你可视为对一名未以此法指定过的角色使用【杀】（无次数和距离限制）。若此【杀】未造成伤害，则其拥有〖令戮〗直到你的下个回合开始后。其指定你为〖令戮〗的目标时，可令〖令戮〗的失败结算进行两次。',
  ['$os__kunsi1'] = '豺狼虎兕雄壮，西园将校威风！',
  ['$os__kunsi2'] = '灵帝遗命，岂容尔等放肆？'
}

os__kunsi:addEffect('viewas', {
  anim_type = "offensive",
  prompt = "#os__kunsi-promot",
  card_num = 0,
  view_as = function(self, player)
    local card = Fk:cloneCard("slash")
    card.skillName = skill.name
    return card
  end,
  before_use = function(self, player, useData)
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.os__kunsiUser = player.id
    useData.extraUse = true
    local targets = TargetGroup:getRealTargets(useData.tos)
    useData.extra_data.os__kunsiTarget = targets
    local room = player.room
    table.forEach(targets, function(pid)
      room:addPlayerMark(room:getPlayerById(pid), "_os__kunsi")
    end)
  end,
  enabled_at_play = function (skill, player)
    return player.phase == Player.Play
  end,
  enabled_at_response = Util.FalseFunc,
})

os__kunsi:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return scope == Player.HistoryPhase and card and table.contains(card.skillNames, "os__kunsi")
  end,
  bypass_distances = function (skill, player, skill, card, to)
    return card and table.contains(card.skillNames, "os__kunsi")
  end,
})

os__kunsi:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return to:getMark("_os__kunsi") > 0 and card and card.name == "slash" and table.contains(card.skillNames, "os__kunsi")
  end,
})

os__kunsi:addEffect({fk.CardUseFinished, fk.Damaged, fk.TurnStart}, {
  mute = true,
  can_refresh = function(self, event, target, player, data)
    if event == fk.CardUseFinished then
      return target == player and (data.extra_data or {}).os__kunsiUser == player.id
    elseif event == fk.Damaged then
      local parentUseData = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return parentUseData and (parentUseData.data[1].extra_data or {}).os__kunsiUser == player.id
    else
      return target == player and player:getMark("_os__linglu") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      local targets = (data.extra_data or {}).os__kunsiTarget
      local os__linglu = player:getTableMark("_os__linglu")
      table.insertTable(os__linglu, targets)
      room:setPlayerMark(player, "_os__linglu", os__linglu)
      for _, pid in ipairs(targets) do
        local target = room:getPlayerById(pid)
        if not target:hasSkill("os__linglu") then
          room:handleAddLoseSkills(target, "os__linglu")
          room:setPlayerMark(target, "_os__linglu_jianshuo", player.id)
        end
      end
    elseif event == fk.Damaged then
      local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      table.removeOne(parentUseData.data[1].extra_data.os__kunsiTarget, data.to.id)
    else
      table.forEach(player:getMark("_os__linglu"), function(pid)
        room:handleAddLoseSkills(room:getPlayerById(pid), "-os__linglu")
      end)
    end
  end,
})

return os__kunsi

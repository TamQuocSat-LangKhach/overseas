local huzhong = fk.CreateSkill {
  name = "os__huzhong",
}

Fk:loadTranslationTable{
  ['os__huzhong'] = '护众',
  ['os__huzhong_own'] = '此【杀】可额外选择一个目标',
  ['os__huzhong_other'] = '弃置%dest一张手牌',
  ['#os__huzhong-extra'] = '护众：此【杀】可额外选择一个目标',
  ['@os__huzhong-phase'] = '护众',
  [':os__huzhong'] = '当你使用普【杀】于出牌阶段指定其他角色为唯一目标时，你可摸一张牌并选择一项：1.此【杀】可额外选择一个目标；2.你弃置其一张手牌。然后若此【杀】造成伤害，你本阶段使用【杀】次数+1。',
  ['$os__huzhong1'] = '此难当头，吾誓保百姓无恙！',
  ['$os__huzhong2'] = '天崩于前，吾必先众人而死！',
}

huzhong:addEffect(fk.TargetSpecifying, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(huzhong.name) and player.phase == Player.Play and data.firstTarget and data.card.name == "slash" and U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) and
      ((#player.room:getUseExtraTargets(data, true, true) > 0 and table.find(player:getCardIds("h"), function(c) return not player:prohibitDiscard(Fk:getCardById(c)) end)) or not player.room:getPlayerById(data.to):isKongcheng())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(1, huzhong.name)
    if player.dead then return end
    local all_choices = {"os__huzhong_own", "os__huzhong_other::" .. data.to}
    local choices = table.simpleClone(all_choices)
    local targets = room:getUseExtraTargets(data, true, true)
    if #targets == 0 then
      table.remove(choices, 1)
    end
    local to = room:getPlayerById(data.to)
    if to:isKongcheng() then
      table.remove(choices)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = huzhong.name,
      all_choices = all_choices
    })
    if choice == "os__huzhong_own" then
      local victims = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__huzhong-extra",
        skill_name = huzhong.name,
        cancelable = true
      })
      if #victims > 0 then
        local victim = victims[1]
        AimGroup:addTargets(room, data, victim)
      end
    else
      local cid = room:askToChooseCard(player, {
        target = to,
        flag = "h",
        skill_name = huzhong.name
      })
      room:throwCard({cid}, huzhong.name, to, player)
    end
    data.extra_data = data.extra_data or {}
    data.extra_data.os__huzhong = true
  end,
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).os__huzhong and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(huzhong.name)
    room:notifySkillInvoked(player, huzhong.name, "offensive")
    room:addPlayerMark(player, "@os__huzhong-phase")
  end,
})

huzhong:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.extra_data or {}).os__huzhong and data.damageDealt
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(huzhong.name)
    room:notifySkillInvoked(player, huzhong.name, "offensive")
    room:addPlayerMark(player, "@os__huzhong-phase")
  end,
})

local huzhong_buff = fk.CreateTargetModSkill{
  name = "#os__huzhong_buff",
  residue_func = function(self, player, skill, scope)
    if player:getMark("@os__huzhong-phase") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@os__huzhong-phase")
    end
  end,
}

return huzhong

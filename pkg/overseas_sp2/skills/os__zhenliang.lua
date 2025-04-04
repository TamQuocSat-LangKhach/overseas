local os__zhenliang = fk.CreateSkill {
  name = "os__zhenliang"
}

Fk:loadTranslationTable{
  ['os__zhenliang'] = '贞良',
  ['os__duty'] = '任',
  ['#os__zhenliang_defend'] = '贞良',
  ['#os__zhenliang-discard'] = '贞良：你可弃置一张牌，令 %src 受到的伤害-1',
  [':os__zhenliang'] = '转换技，阳：出牌阶段限一次，你可弃置一张牌并选择你攻击范围内的一名其他角色，对其造成1点伤害；阴：你的回合外，当你或你攻击范围内的一名角色受到伤害时，你可弃置一张牌，令此伤害-1。若你以此法弃置的牌与“任”颜色相同，你摸一张牌。',
  ['$os__zhenliang1'] = '贞洁贤良，吾之本心。',
  ['$os__zhenliang2'] = '风霜以别草木之性，危乱而见贞良之节。',
}

-- ActiveSkill effect
os__zhenliang:addEffect('active', {
  anim_type = "switch",
  switch_skill_name = "os__zhenliang",
  can_use = function(self, player)
    return player:usedSkillTimes(os__zhenliang.name, Player.HistoryPhase) < 1 and player:getSwitchSkillState(os__zhenliang.name) == fk.SwitchYang
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected < 1
  end,
  target_num = 1,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select))
  end,
  on_use = function(self, room, effect)
    if #effect.cards ~= 1 then return end
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, os__zhenliang.name, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = os__zhenliang.name,
    }
    if #player:getPile("os__duty") > 0 and Fk:getCardById(effect.cards[1]):compareColorWith(Fk:getCardById(player:getPile("os__duty")[1])) then
      player:drawCards(1, os__zhenliang.name)
    end
  end,
})

-- TriggerSkill effect
os__zhenliang:addEffect(fk.DamageInflicted, {
  anim_type = "switch",
  switch_skill_name = "os__zhenliang",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__zhenliang.name) then return false end
    return player:getSwitchSkillState("os__zhenliang") == fk.SwitchYin and (target == player or player:inMyAttackRange(target)) and not player:isNude() and player.phase == Player.NotActive
  end,
  on_cost = function(self, event, target, player, data)
    local cids = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__zhenliang.name,
      cancelable = true,
      prompt = "#os__zhenliang-discard:" .. target.id,
    })
    if #cids > 0 then
      event:setCostData(skill, cids)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("os__zhenliang")
    player:addSkillUseHistory("os__zhenliang")
    room:throwCard(event:getCostData(skill), os__zhenliang.name, player, player)
    data.damage = data.damage - 1
    if #player:getPile("os__duty") > 0 and Fk:getCardById(event:getCostData(skill)[1]):compareColorWith(Fk:getCardById(player:getPile("os__duty")[1])) then
      player:drawCards(1, os__zhenliang.name)
    end
  end,
})

return os__zhenliang

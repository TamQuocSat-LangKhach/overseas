local xiayong = fk.CreateSkill {
  name = "os__xiayong"
}

Fk:loadTranslationTable{
  ['os__xiayong'] = '狭勇',
  [':os__xiayong'] = '锁定技，你为目标角色或使用者的【决斗】造成伤害时，若受到此牌伤害的角色：为你，你随机弃置一张手牌；不为你，此伤害+1。',
  ['$os__xiayong1'] = '一招之差，不足决此战胜负！',
  ['$os__xiayong2'] = '这般身手，也敢来战我？',
}

xiayong:addEffect(fk.DamageCaused, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not (player:hasSkill(xiayong.name) and data.card and data.card.trueName == "duel") then return end
    local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, false)
    if use_event == nil then return false end
    return (table.contains(TargetGroup:getRealTargets(use_event.data[1].tos), player.id) or use_event.data[1].from == player.id) and
      player.room.logic:damageByCardEffect(false) and (data.to ~= player or not player:isKongcheng())
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.to == player then
      room:notifySkillInvoked(player, xiayong.name, "negative")
      player:broadcastSkillInvoke(xiayong.name, 1)
      local cards = table.filter(player:getCardIds(Player.Hand), function(id) return not player:prohibitDiscard(Fk:getCardById(id)) end)
      if #cards > 0 then
        room:throwCard(table.random(cards), { skill_name = xiayong.name }, player)
      end
    else
      room:notifySkillInvoked(player, xiayong.name, "offensive")
      player:broadcastSkillInvoke(xiayong.name, 2)
      room:doIndicate(player.id, {data.to.id})
      data.damage = data.damage + 1
    end
  end,
})

return xiayong

local horsetailWhiskSkill = fk.CreateSkill {
  name = "#horsetail_whisk_skill",
  attached_equip = "horsetail_whisk",
}

Fk:loadTranslationTable{
  ['#horsetail_whisk_skill'] = '太极拂尘',
  ['#horsetail_whisk-ask'] = '太极拂尘：弃置一张牌，否则不可响应此【杀】。若弃置的为%arg，%src将获得之',
  [':#horsetail_whisk_skill'] = '当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。',
}

horsetailWhiskSkill:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(horsetailWhiskSkill.name) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, horsetailWhiskSkill.name, "offensive")
    target = data.to
    local cids = room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = horsetailWhiskSkill.name,
      cancelable = true,
      prompt = "#horsetail_whisk-ask:" .. player.id .. "::" .. "log_" .. data.card:getSuitString()
    })
    if #cids == 0 then
      data.disresponsive = true
    elseif data.card:compareSuitWith(Fk:getCardById(cids[1])) then
      room:obtainCard(player, cids, true, fk.ReasonJustMove, player, horsetailWhiskSkill.name)
    end
  end,
})

return horsetailWhiskSkill

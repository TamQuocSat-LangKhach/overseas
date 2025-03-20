local horsetailWhiskSkill = fk.CreateSkill {
  name = "#horsetail_whisk_skill"
}

Fk:loadTranslationTable{
  ['#horsetail_whisk_skill'] = '太极拂尘',
  ['horsetail_whisk'] = '太极拂尘',
  ['#horsetail_whisk-ask'] = '太极拂尘：弃置一张牌，否则不可响应此【杀】。若弃置的为%arg，%src将获得之',
  [':#horsetail_whisk_skill'] = '当你使用的【杀】指定目标后，目标角色需弃置一张牌，否则不可响应此【杀】；若其弃置的牌与此【杀】花色相同，你获得之。',
}

horsetailWhiskSkill:addEffect(fk.TargetSpecified, {
  attached_equip = "horsetail_whisk",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(horsetailWhiskSkill.name) and data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, horsetailWhiskSkill.name, "offensive")
    local target = room:getPlayerById(data.to)
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
      room:obtainCard(player, cids[1], true, fk.ReasonJustMove)
    end
  end,
})

return horsetailWhiskSkill

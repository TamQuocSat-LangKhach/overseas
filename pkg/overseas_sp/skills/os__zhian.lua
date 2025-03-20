local os__zhian = fk.CreateSkill {
  name = "os__zhian"
}

Fk:loadTranslationTable{
  ['os__zhian'] = '治暗',
  ['os__zhian_discard'] = '从场上弃置%arg',
  ['os__zhian_get'] = '弃置一张手牌，获得%arg',
  ['os__zhian_damage'] = '对%dest造成1点伤害',
  ['#os__zhian-ask'] = '治暗：%dest 使用了%arg，你可选择一项',
  [':os__zhian'] = '每回合限一次，当一名角色使用装备牌或延时锦囊牌结算结束后，你可选择一项：1. 从场上弃置此牌；2. 弃置一张手牌，获得此牌；3. 对其造成1点伤害。',
  ['$os__zhian1'] = '此等蝼蚁不除，必溃千丈之堤！',
  ['$os__zhian2'] = '尔等权贵贪赃枉法，岂可轻饶？！',
}

os__zhian:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__zhian.name) and target ~= player and (data.card.type == Card.TypeEquip or data.card.sub_type == Card.SubtypeDelayedTrick) and player:usedSkillTimes(os__zhian.name) < 1
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local room = player.room
    local card_area = room:getCardArea(data.card)
    if card_area == Card.PlayerEquip or card_area == Card.PlayerJudge then 
      table.insert(choices, "os__zhian_discard:::" .. data.card:toLogString()) 
    end
    if not player:isKongcheng() then 
      table.insert(choices, "os__zhian_get:::" .. data.card:toLogString()) 
    end
    table.insertTable(choices, {"os__zhian_damage::" .. target.id, "Cancel"})
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__zhian.name,
      prompt = "#os__zhian-ask::" .. target.id .. ":" .. data.card:toLogString(),
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local choice = event:getCostData(self)
    if choice:startsWith("os__zhian_discard") then
      local card = data.card
      local owner = room:getCardOwner(card)
      room:throwCard(card:isVirtual() and card.subcards or {card.id}, os__zhian.name, owner, player)
    elseif choice:startsWith("os__zhian_get") then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = os__zhian.name,
        cancelable = false,
      })
      room:obtainCard(player, data.card, false, fk.ReasonJustMove)
    else
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = os__zhian.name,
      }
    end
  end,
})

return os__zhian

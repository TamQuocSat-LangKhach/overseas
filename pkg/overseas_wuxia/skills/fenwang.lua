local fenwang = fk.CreateSkill {
  name = "os__fenwang"
}

Fk:loadTranslationTable{
  ['os__fenwang'] = '焚亡',
  ['#os__fenwang-discard'] = '焚亡：弃置一张手牌，否则此伤害+1',
  [':os__fenwang'] = '锁定技，①当你受到属性伤害时，你须弃置一张手牌，否则此伤害+1。②当你对其他角色造成普通伤害时，若你的手牌数大于其手牌数，此伤害+1。',
  ['$os__fenwang1'] = '洛阳逢此大难，吾，亦难脱身。',
  ['$os__fenwang2'] = '大火之下，黑影，已无所遁形！',
}

fenwang:addEffect(fk.DamageInflicted, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(fenwang.name) then return end
    return data.damageType ~= fk.NormalDamage
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = fenwang.name,
      cancelable = true,
      prompt = "#os__fenwang-discard",
      skip = true
    })
    event:setCostData(fenwang, card)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, fenwang.name, "negative")
    player:broadcastSkillInvoke(fenwang.name, 1)
    if #event:getCostData(fenwang) > 0 then
      room:throwCard(event:getCostData(fenwang), fenwang.name, player)
    else
      data.damage = data.damage + 1
    end
  end,
})

fenwang:addEffect(fk.DamageCaused, {
  mute = true,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(fenwang.name) then return end
    return data.damageType == fk.NormalDamage and player:getHandcardNum() > data.to:getHandcardNum()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, fenwang.name, "offensive")
    player:broadcastSkillInvoke(fenwang.name, 2)
    data.damage = data.damage + 1
  end,
})

return fenwang

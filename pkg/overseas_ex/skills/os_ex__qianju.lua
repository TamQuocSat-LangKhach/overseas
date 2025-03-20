local os_ex__qianju = fk.CreateSkill {
  name = "os_ex__qianju"
}

Fk:loadTranslationTable{
  ['os_ex__qianju'] = '千驹',
  [':os_ex__qianju'] = '锁定技，你计算与其他角色的距离-X（X为你的装备区里的牌数）；每回合限一次，当你对你至其的距离小于2的角色造成伤害后，你将牌堆或弃牌堆中一张装备牌置入你的装备区。',
}

os_ex__qianju:addEffect(fk.Damage, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and (data.extra_data or {}).kuanggucheck and player:usedSkillTimes(os_ex__qianju.name) == 0
  end,
  on_use = function(self, event, target, player, data)
    local subtypes = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
    local room = player.room
    local choices = {}
    for _, s in ipairs(subtypes) do
      if player:hasEmptyEquipSlot(s) then
        table.insert(choices, s)
      end
    end
    local cards = {}
    local draw_pile = table.simpleClone(room.draw_pile)
    table.insertTable(draw_pile, room.discard_pile)
    for i = 1, #draw_pile do
      local card = Fk:getCardById(draw_pile[i])
      if table.contains(choices, card.sub_type) then
        table.insert(cards, draw_pile[i])
      end
    end
    if #cards > 0 then
      room:moveCardIntoEquip(player, table.random(cards), os_ex__qianju.name, false, player.id)
    end
  end,
})

os_ex__qianju:addEffect(fk.BeforeHpChanged, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and player == data.damageEvent.from and player:compareDistance(target, 2, "<")
  end,
  on_refresh = function(self, event, target, player, data)
    data.damageEvent.extra_data = data.damageEvent.extra_data or {}
    data.damageEvent.extra_data.kuanggucheck = true
  end,
})

local os_ex__qianju_distance = fk.CreateSkill {
  name = "#os_ex__qianju_distance"
}

os_ex__qianju_distance:addEffect('distance', {
  correct_func = function(self, from, to)
    if from:hasSkill(os_ex__qianju.name) then
      return -#from:getCardIds(Player.Equip)
    end
  end,
})

return os_ex__qianju

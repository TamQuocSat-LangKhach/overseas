local os__shenxing = fk.CreateSkill {
  name = "os__shenxing"
}

Fk:loadTranslationTable{
  ['os__shenxing'] = '神行',
  [':os__shenxing'] = '锁定技，若你的坐骑区没有牌，你与其他角色的距离-1，你的手牌上限+1。',
}

os__shenxing:addEffect('distance', {
  correct_func = function(self, from, to)
    if from:hasSkill(skill.name) and #from:getEquipments(Card.SubtypeOffensiveRide) + #from:getEquipments(Card.SubtypeDefensiveRide) == 0 then
      return -1
    end
  end,
})

os__shenxing:addEffect('maxcards', {
  correct_func = function(self, player)
    if player:hasSkill(skill.name) and #player:getEquipments(Card.SubtypeOffensiveRide) + #player:getEquipments(Card.SubtypeDefensiveRide) == 0 then
      return 1
    end
    return 0
  end,
})

return os__shenxing

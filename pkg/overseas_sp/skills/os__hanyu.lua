local os__hanyu = fk.CreateSkill {
  name = "os__hanyu"
}

Fk:loadTranslationTable{
  ['os__hanyu'] = '捍御',
  [':os__hanyu'] = '锁定技，游戏开始时，你从牌堆获得不同类别的牌各一张。',
  ['$os__hanyu1'] = '霸起泰山，称雄东方！',
  ['$os__hanyu2'] = '乱贼何惧，霸自可御之！',
}

os__hanyu:addEffect(fk.GameStart, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = {}
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|basic"))
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|trick"))
    table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|equip"))
    room:obtainCard(player, cards, false, fk.ReasonPrey)
  end,
})

return os__hanyu

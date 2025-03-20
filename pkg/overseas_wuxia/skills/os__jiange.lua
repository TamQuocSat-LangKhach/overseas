local os__jiange = fk.CreateSkill {
  name = "os__jiange"
}

Fk:loadTranslationTable{
  ['os__jiange'] = '剑歌',
  [':os__jiange'] = '每回合限一次，你可将一张非基本牌当【杀】使用或打出（无距离与次数限制且不计入次数）。若此时为你的回合外，你摸一张牌。',
  ['$os__jiange1'] = '纵剑为舞，击缶而歌！',
  ['$os__jiange2'] = '辞亲历山野，仗剑唱大风！',
}

os__jiange:addEffect('viewas', {
  pattern = "slash",
  card_filter = function(self, player, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c:addSubcards(cards)
    c.skillName = os__jiange.name
    return c
  end,
  before_use = function(self, player, use)
    if player.phase == Player.NotActive then player:drawCards(1, { skill_name = os__jiange.name }) end
    use.extraUse = true
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(os__jiange.name) == 0
  end,
  enabled_at_response = function(self, player)
    return player:usedSkillTimes(os__jiange.name) == 0
  end,
})

os__jiange:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(os__jiange) and card and table.contains(card.skillNames, os__jiange.name)) and 999 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill(os__jiange) and card and table.contains(card.skillNames, os__jiange.name)) and 999 or 0
  end,
})

return os__jiange

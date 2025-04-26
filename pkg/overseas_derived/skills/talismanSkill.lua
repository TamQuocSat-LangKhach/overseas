local talismanSkill = fk.CreateSkill {
  name = "#talisman_skill",
  tags = {Skill.Compulsory},
  attached_equip = "talisman",
}

Fk:loadTranslationTable{
  ['#talisman_skill'] = '冲应神符',
  ['@$talisman'] = '神符',
  [':#talisman_skill'] = '锁定技，①当你受到伤害后，记录造成此伤害的牌的牌名；②当你受到伤害时，若造成此伤害的牌的牌名被记录过，此伤害-1。',
}

talismanSkill:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(talismanSkill.name) and data.card and table.contains(player:getTableMark("@$talisman"), data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(-1)
  end,
})

talismanSkill:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(talismanSkill.name) and data.card
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "@$talisman", data.card.trueName)
  end,
})

return talismanSkill

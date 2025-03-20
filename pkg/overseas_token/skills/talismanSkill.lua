local talismanSkill = fk.CreateSkill {
  name = "#talisman_skill"
}

Fk:loadTranslationTable{
  ['#talisman_skill'] = '冲应神符',
  ['talisman'] = '冲应神符',
  ['@$talisman'] = '神符',
  [':#talisman_skill'] = '锁定技，当你受到一种牌名的牌造成的伤害后，本局游戏同牌名的牌对你造成的伤害-1。',
}

talismanSkill:addEffect(fk.DamageInflicted, {
  attached_equip = "talisman",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(talismanSkill.name) and data.card and type(player:getMark("@$talisman")) == "table" and table.contains(player:getMark("@$talisman"), data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    player.room:notifySkillInvoked(player, talismanSkill.name, "defensive")
    data.damage = data.damage - 1
  end,
})

talismanSkill:addEffect(fk.Damaged, {
  attached_equip = "talisman",
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(talismanSkill.name) and data.card
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@$talisman", data.card.trueName)
  end,
})

return talismanSkill

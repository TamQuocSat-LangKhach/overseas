local os__juyan = fk.CreateSkill {
  name = "os__juyan"
}

Fk:loadTranslationTable{
  ['os__juyan'] = '炬湮',
  [':os__juyan'] = '锁定技，当你对一名角色造成火焰伤害后，你摸一张牌，然后令其减1点体力上限。',
}

os__juyan:addEffect(fk.Damage, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__juyan.name) and player == target and data.damageType == fk.FireDamage and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, os__juyan.name)
    if data.to.dead or player.dead then return end
    player.room:changeMaxHp(data.to, -1)
  end,
})

return os__juyan

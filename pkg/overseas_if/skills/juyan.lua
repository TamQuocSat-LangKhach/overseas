local juyan = fk.CreateSkill {
  name = "os__juyan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__juyan"] = "炬湮",
  [":os__juyan"] = "锁定技，当你对一名角色造成火焰伤害后，你摸一张牌，然后令其减1点体力上限。",

  ["$os__juyan1"] = "火攻之计虽败，亦可舍生以助功成！",
  ["$os__juyan2"] = "哈哈哈，老夫此身有何足惜，但求破贼而已！",
}

juyan:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(juyan.name) and data.damageType == fk.FireDamage and not data.to.dead
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, juyan.name)
    if data.to.dead then return end
    player.room:changeMaxHp(data.to, -1)
  end,
})

return juyan

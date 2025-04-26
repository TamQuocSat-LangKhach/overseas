local celestialCalabashSkill = fk.CreateSkill {
  name = "#celestial_calabash_skill",
  tags = {Skill.Compulsory},
  attached_equip = "celestial_calabash",
}

Fk:loadTranslationTable{
  ['#celestial_calabash_skill'] = '灵宝仙葫',
  [':#celestial_calabash_skill'] = '锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。',
}

local function ccOnUse(self, event, target, player)
  local room = player.room
  --room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
  room:changeMaxHp(player, 1)
  room:recover({ who = player, num = 1, recoverBy = player, skillName = celestialCalabashSkill.name})
end

celestialCalabashSkill:addEffect(fk.DamageCaused, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(celestialCalabashSkill.name) and target == player and data.damage > 1
  end,
  on_use = ccOnUse,
})

celestialCalabashSkill:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(celestialCalabashSkill.name) and target ~= player
  end,
  on_use = ccOnUse,
})

return celestialCalabashSkill

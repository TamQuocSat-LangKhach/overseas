local celestialCalabashSkill = fk.CreateSkill {
  name = "#celestial_calabash_skill"
}

Fk:loadTranslationTable{
  ['#celestial_calabash_skill'] = '灵宝仙葫',
  ['celestial_calabash'] = '灵宝仙葫',
  [':#celestial_calabash_skill'] = '锁定技，当你造成大于1点的伤害时或一名角色死亡时，你增加1点体力上限并回复1点体力。',
}

celestialCalabashSkill:addEffect(fk.DamageCaused, {
  attached_equip = "celestial_calabash",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(celestialCalabashSkill.name) then return false end
    return target == player and data.damage > 1
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    --room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
    room:notifySkillInvoked(player, celestialCalabashSkill.name, "support")
    room:changeMaxHp(player, 1)
    room:recover({ who = player, num = 1, recoverBy = player, skillName = celestialCalabashSkill.name})
  end,
})

celestialCalabashSkill:addEffect(fk.Death, {
  attached_equip = "celestial_calabash",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(celestialCalabashSkill.name) then return false end
    return target ~= player
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    --room:setEmotion(player, "./packages/overseas/image/anim/moon_spear")
    room:notifySkillInvoked(player, celestialCalabashSkill.name, "support")
    room:changeMaxHp(player, 1)
    room:recover({ who = player, num = 1, recoverBy = player, skillName = celestialCalabashSkill.name})
  end,
})

return celestialCalabashSkill

local osHuanJielv = fk.CreateSkill {
  name = "os_huan__jielv"
}

Fk:loadTranslationTable{
  ['os_huan__jielv'] = '竭虑',
  [':os_huan__jielv'] = '锁定技，当你减1点体力上限后，你回复1点体力。',
  ['$os_huan__jielv1'] = '出箕谷，饮河洛，所至长安！',
  ['$os_huan__jielv2'] = '破司马，废伪政，誓还帝都！',
}

osHuanJielv:addEffect(fk.MaxHpChanged, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(osHuanJielv.name) and data.num < 0 and player:isWounded()
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{
      who = player,
      num = -data.num,
      recoverBy = player,
      skill_name = osHuanJielv.name,
    }
  end
})

return osHuanJielv

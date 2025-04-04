local os__yiju = fk.CreateSkill {
  name = "os__yiju"
}

Fk:loadTranslationTable{
  ['os__yiju'] = '蚁聚',
  ['os__revelation'] = '示',
  [':os__yiju'] = '若你有“示”，①你于出牌阶段使用【杀】的次数上限和攻击范围均为你的体力值。②当你受到伤害时，你将“示”置入弃牌堆，令此伤害+1。',
  ['$os__yiju1'] = '鸱张蚁聚，为从天道！',
  ['$os__yiju2'] = '黄天之道，苍天之示。',
}

os__yiju:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__yiju.name) and #player:getPile("os__revelation") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return data.damage > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(Fk:getCardById(player:getPile("os__revelation")[1]), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, os__yiju.name, "os__revelation")
    data.damage = data.damage + 1
  end,
})

os__yiju:addEffect('targetmod', {
  name = "#os__yijuTargetMod",
  residue_func = function(self, player, skill, scope)
    return (player:hasSkill(os__yiju.name) and #player:getPile("os__revelation") > 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase) and player.hp - 1 or 0
  end,
})

os__yiju:addEffect('atkrange', {
  name = "#os__yijuAR",
  correct_func = function(self, from, to)
    return (from:hasSkill(os__yiju.name) and #from:getPile("os__revelation") > 0) and from.hp or 0
  end,
})

return os__yiju

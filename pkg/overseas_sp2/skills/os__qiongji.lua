local os__qiongji = fk.CreateSkill {
  name = "os__qiongji"
}

Fk:loadTranslationTable{
  ['os__qiongji'] = '穷技',
  ['os__pomp&'] = '威',
  [':os__qiongji'] = '锁定技，当你受到伤害时，若你没有“威”，伤害值+1；每回合限一次，当你使用或打出“威”时，你摸一张牌。',
  ['$os__qiongji1'] = '吾计虽穷，势不可衰！',
  ['$os__qiongji2'] = '战在其势，何妨技穷？',
}

os__qiongji:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(skill.name) then return false end
    return #player:getPile("os__pomp&") == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os__qiongji.name)
    room:notifySkillInvoked(player, os__qiongji.name, "negative")
    data.damage = data.damage + 1
  end,
})

os__qiongji:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(skill.name) then return false end
    return player:usedSkillTimes("os__qiongji_draw") == 0 and player:getMark("_os__pomp") ~= 0 and table.find(data.card:isVirtual() and data.card.subcards or {data.card.id}, function(id)
      return table.contains(player:getMark("_os__pomp"), id)
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os__qiongji.name)
    room:notifySkillInvoked(player, os__qiongji.name, "drawcard")
    player:addSkillUseHistory("os__qiongji_draw")
    player:drawCards(1, os__qiongji.name)
  end,
})

os__qiongji:addEffect(fk.CardResponding, {
  can_trigger = function(self, event, target, player, data)
    if target ~= player or not player:hasSkill(skill.name) then return false end
    return player:usedSkillTimes("os__qiongji_draw") == 0 and player:getMark("_os__pomp") ~= 0 and table.find(data.card:isVirtual() and data.card.subcards or {data.card.id}, function(id)
      return table.contains(player:getMark("_os__pomp"), id)
    end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os__qiongji.name)
    room:notifySkillInvoked(player, os__qiongji.name, "drawcard")
    player:addSkillUseHistory("os__qiongji_draw")
    player:drawCards(1, os__qiongji.name)
  end,
})

return os__qiongji

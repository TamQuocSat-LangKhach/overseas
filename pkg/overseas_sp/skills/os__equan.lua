local os__equan = fk.CreateSkill {
  name = "os__equan"
}

Fk:loadTranslationTable{
  ['os__equan'] = '恶泉',
  ['@os__poison'] = '毒',
  ['@@os__equan-turn'] = '恶泉',
  [':os__equan'] = '锁定技，当一名角色于你回合内受到伤害后，其获得等同于伤害值的“毒”。准备阶段开始时，所有有“毒”的角色失去X点体力并弃所有“毒”（X为其拥有的“毒”数)，以此法进入濒死状态的角色本回合技能失效。',
  ['$os__equan1'] = '哈哈哈哈哈哈，有此毒泉，大王尽可宽心。',
  ['$os__equan2'] = '有此四泉足矣，何用刀兵？',
}

os__equan:addEffect(fk.Damaged, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and player.phase ~= Player.NotActive and not target.dead
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.Damaged then
      room:addPlayerMark(target, "@os__poison", data.damage)
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("@os__poison") > 0 and not p.dead then
          room:setPlayerMark(p, "_os__equan", 1)
          room:loseHp(p, p:getMark("@os__poison"), os__equan.name)
          room:setPlayerMark(p, "@os__poison", 0)
          room:setPlayerMark(p, "_os__equan", 0)
        end
      end
    end
  end,
})

os__equan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and target.phase == Player.Start
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getMark("@os__poison") > 0 and not p.dead then
        room:setPlayerMark(p, "_os__equan", 1)
        room:loseHp(p, p:getMark("@os__poison"), os__equan.name)
        room:setPlayerMark(p, "@os__poison", 0)
        room:setPlayerMark(p, "_os__equan", 0)
      end
    end
  end,
})

os__equan:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and target:getMark("_os__equan") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(target, "@@os__equan-turn", 1)
    room:setPlayerMark(target, "_os__equan", 0)
  end,
})

local os__equan_invalidity = fk.CreateInvaliditySkill {
  name = "#os__equan_invalidity",
  invalidity_func = function(self, from, skill)
    return from:getMark("@@os__equan-turn") > 0 and skill:isPlayerSkill(from)
  end
}

return os__equan

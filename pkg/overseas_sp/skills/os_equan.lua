local osEquan = fk.CreateSkill {
  name = "os__equan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__equan"] = "恶泉",
  [":os__equan"] = "锁定技，当一名角色于你回合内受到伤害后，其获得等同于伤害值的“毒”；准备阶段开始时，" ..
  "所有有“毒”的角色失去X点体力并弃所有“毒”（X为其拥有的“毒”数)，以此法进入濒死状态的角色本回合技能失效。",

  ["@os__poison"] = "毒",
  ["@@os__equan-turn"] = "恶泉",

  ["$os__equan1"] = "哈哈哈哈哈哈，有此毒泉，大王尽可宽心。",
  ["$os__equan2"] = "有此四泉足矣，何用刀兵？",
}

osEquan:addEffect(fk.Damaged, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osEquan.name) and player.phase ~= Player.NotActive and target:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "@os__poison", data.damage)
  end,
})

osEquan:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osEquan.name) and
      target.phase == Player.Start and
      table.find(player.room.alive_players, function(p) return p:getMark("@os__poison") > 0 end)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:getMark("@os__poison") > 0 and p:isAlive() then
        room:setPlayerMark(p, "_os__equan", 1)
        room:loseHp(p, p:getMark("@os__poison"), osEquan.name)
        room:setPlayerMark(p, "@os__poison", 0)
        room:setPlayerMark(p, "_os__equan", 0)
      end
    end
  end,
})

osEquan:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osEquan.name) and target:getMark("_os__equan") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(target, "@@os__equan-turn", 1)
    room:setPlayerMark(target, "_os__equan", 0)
  end,
})

osEquan:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("@@os__equan-turn") > 0 and skill:isPlayerSkill(from)
  end,
})

return osEquan

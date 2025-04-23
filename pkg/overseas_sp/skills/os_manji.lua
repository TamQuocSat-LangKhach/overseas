local osManji = fk.CreateSkill {
  name = "os__manji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os__manji"] = "蛮汲",
  [":os__manji"] = "锁定技，当其他角色失去体力后，若你的体力值不大于其，你回复1点体力；若你的体力值不小于其，你摸一张牌。",

  ["$os__manji1"] = "嗯~~不错，不错。",
  ["$os__manji2"] = "额哈哈哈哈哈哈，痛快！痛快！",
}

osManji:addEffect(fk.HpLost, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osManji.name) and target ~= player and target:isAlive()
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osManji.name
    if target.hp >= player.hp then
      local room = player.room
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skill_name = skillName,
      }
    end
    if target.hp <= player.hp then
      player:drawCards(1, skillName)
    end
  end,
})

return osManji

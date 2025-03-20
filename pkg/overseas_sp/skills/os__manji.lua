local os__manji = fk.CreateSkill {
  name = "os__manji"
}

Fk:loadTranslationTable{
  ['os__manji'] = '蛮汲',
  [':os__manji'] = '锁定技，当其他角色失去体力后，若你的体力值不大于其，你回复1点体力；若你的体力值不小于其，你摸一张牌。',
  ['$os__manji1'] = '嗯~~不错，不错。',
  ['$os__manji2'] = '额哈哈哈哈哈哈，痛快！痛快！',
}

os__manji:addEffect(fk.HpLost, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__manji.name) and target ~= player and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    if target.hp >= player.hp then
      local room = player.room
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skill_name = os__manji.name,
      })
    end
    if target.hp <= player.hp then
      player:drawCards(1, os__manji.name)
    end
  end,
})

return os__manji

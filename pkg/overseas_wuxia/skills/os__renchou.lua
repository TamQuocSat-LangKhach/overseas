local os__renchou = fk.CreateSkill {
  name = "os__renchou"
}

Fk:loadTranslationTable{
  ['os__renchou'] = '刃仇',
  [':os__renchou'] = '锁定技，当你或“言誓”角色死亡时，若另一名角色A存活，且来源B不是A，则A对B造成X点伤害（X为A的体力值）。',
  ['$os__renchou1'] = '塞亡父之冤魂，血三弟之永恨！',
  ['$os__renchou2'] = '禄福夜雪白，都亭朝霞红！'
}

os__renchou:addEffect(fk.Death, {
  frequency = Skill.Compulsory,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__renchou.name, false, true) or (target ~= player and player:getMark("_os__yanshi") ~= target.id) then return false end 
    local from = player.dead and player.room:getPlayerById(player:getMark("_os__yanshi")) or player
    return from and not from.dead and data.damage and data.damage.from and not data.damage.from.dead and data.damage.from ~= from
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local from = player.dead and room:getPlayerById(player:getMark("_os__yanshi")) or player 
    room:damage{
      from = from,
      to = data.damage.from,
      damage = from.hp,
      skill_name = os__renchou.name,
    }
  end,
})

return os__renchou

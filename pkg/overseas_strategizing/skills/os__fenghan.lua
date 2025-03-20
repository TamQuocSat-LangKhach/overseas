local os__fenghan = fk.CreateSkill {
  name = "os__fenghan"
}

Fk:loadTranslationTable{
  ['os__fenghan'] = '锋悍',
  ['#os__fenghan-ask'] = '锋悍：你可令至多 %arg 名角色各摸一张牌',
  [':os__fenghan'] = '每回合限一次，当你使用【杀】或伤害锦囊牌指定第一个目标后，你可令至多X名角色摸一张牌（X为目标数）。',
}

os__fenghan:addEffect(fk.TargetSpecified, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return 
      target == player and
      player:hasSkill(os__fenghan.name) and
      data.firstTarget and player:usedSkillTimes(os__fenghan.name) < 1 and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local num = #AimGroup:getAllTargets(data.tos)
    local result = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = num,
      prompt = "#os__fenghan-ask:::" .. num,
      skill_name = os__fenghan.name
    })
    if #result > 0 then
      event:setCostData(self, result)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self)
    for _, id in ipairs(targets) do
      room:getPlayerById(id):drawCards(1, os__fenghan.name)
    end
  end,
})

return os__fenghan

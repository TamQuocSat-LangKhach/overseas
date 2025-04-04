local os__didao = fk.CreateSkill {
  name = "os__didao"
}

Fk:loadTranslationTable{
  ['os__didao'] = '地道',
  ['#os__didao-ask'] = '地道：你可打出一张牌替换 %src 的判定，若与原判定牌颜色相同，你摸一张牌',
  [':os__didao'] = '当一名角色的判定牌生效前，你可打出一张牌替换之，若与原判定牌颜色相同，你摸一张张牌。',
}

os__didao:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(skill.name) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askToResponse(player, {
      skill_name = skill.name,
      pattern = ".|.|.|hand,equip",
      prompt = "#os__didao-ask:" .. target.id,
      cancelable = true
    })
    if card ~= nil then
      event:setCostData(skill, card)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local invoke = false
    if event:getCostData(skill):compareColorWith(data.card) then invoke = true end
    player.room:retrial(event:getCostData(skill), player, data, skill.name, true)
    if invoke and not player.dead then
      player:drawCards(1, skill.name)
    end
  end,
})

return os__didao

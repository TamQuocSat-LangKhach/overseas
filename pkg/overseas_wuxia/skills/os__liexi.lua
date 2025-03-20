local os__liexi = fk.CreateSkill {
  name = "os__liexi"
}

Fk:loadTranslationTable{
  ['os__liexi'] = '烈袭',
  ['#os__liexi-ask'] = '烈袭：你可弃置任意张牌，点击“确定”后选择一名其他角色',
  ['#os__liexi-target'] = '烈袭：你可选择一名其他角色',
  [':os__liexi'] = '准备阶段开始时，你可弃置任意张牌并选择一名其他角色，若你弃置的牌数大于其体力值，则你对其造成1点伤害；否则其对你造成1点伤害；若你弃置的牌中包含武器牌，你对其造成1点伤害。',
  ['$os__liexi1'] = '短兵强击，贯汝心扉！',
  ['$os__liexi2'] = '性刚情烈，目不容奸！'
}

os__liexi:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__liexi.name) and player.phase == Player.Start and not player:isNude()
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local ids = room:askToDiscard(player, {
      min_num = 1,
      max_num = #player:getCardIds(Player.Hand) + #player:getCardIds(Player.Equip),
      include_equip = true,
      skill_name = os__liexi.name,
      cancelable = true,
      skip = true,
      prompt = "#os__liexi-ask",
    })
    if #ids > 0 then
      local victim = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os__liexi-target",
        skill_name = os__liexi.name,
        cancelable = true
      })
      if #victim > 0 then
        event:setCostData(self, {victim[1], ids})
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cost_data = event:getCostData(self)
    local ids = cost_data[2]
    local target_player = room:getPlayerById(cost_data[1])
    room:throwCard(ids, os__liexi.name, player)
    if #ids > target_player.hp then
      room:damage{
        from = player,
        to = target_player,
        damage = 1,
        skillName = os__liexi.name,
      }
    else
      room:damage{
        from = target_player,
        to = player,
        damage = 1,
        skillName = os__liexi.name,
      }
    end
    if not table.every(ids, function(id)
      return Fk:getCardById(id).sub_type ~= Card.SubtypeWeapon
    end) then
      room:damage{
        from = player,
        to = target_player,
        damage = 1,
        skillName = os__liexi.name,
      }
    end
  end,
})

return os__liexi

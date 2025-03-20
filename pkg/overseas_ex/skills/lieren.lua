local lieren = fk.CreateSkill {
  name = "os_ex__lieren"
}

Fk:loadTranslationTable{
  ['os_ex__lieren'] = '烈刃',
  ['#os_ex__lieren-invoke'] = '烈刃：你可以与 %src 点，若赢，你获得其一张牌，若没赢，你们获得对方拼点牌',
  [':os_ex__lieren'] = '当你使用【杀】指定目标后，你可以与其拼点，若你赢，你获得其一张牌；若你没赢，你获得其拼点的牌，其获得你拼点的牌。',
  ['$os_ex__lieren1'] = '有我手中飞刀在，何惧蜀军！',
  ['$os_ex__lieren2'] = '长矛，飞刀，烈火，都来吧！'
}

lieren:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lieren.name) and data.card and data.card.trueName == "slash" and player:canPindian(player.room:getPlayerById(data.to))
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lieren.name,
      prompt = "#os_ex__lieren-invoke:"..data.to
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(data.to)
    local pindian = player:pindian({target}, lieren.name)
    if player.dead then return end
    if pindian.results[target.id].winner == player then
      if not target:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = lieren.name
        })
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    else
      room:delay(1200)
      room:obtainCard(player, pindian.results[target.id].toCard, true, fk.ReasonJustMove)
      if target.dead then return end
      room:obtainCard(target, pindian.fromCard, true, fk.ReasonJustMove)
    end
  end,
})

return lieren

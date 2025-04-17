local osExLieren = fk.CreateSkill {
  name = "os_ex__lieren"
}

Fk:loadTranslationTable{
  ["os_ex__lieren"] = "烈刃",
  [":os_ex__lieren"] = "当你使用【杀】指定目标后，你可以与其拼点，若你赢，你获得其一张牌；若你没赢，你获得其拼点的牌，其获得你拼点的牌。",

  ["#os_ex__lieren-invoke"] = "烈刃：你可以与 %src 点，若赢，你获得其一张牌，若没赢，你们获得对方拼点牌",

  ["$os_ex__lieren1"] = "有我手中飞刀在，何惧蜀军！",
  ["$os_ex__lieren2"] = "长矛，飞刀，烈火，都来吧！"
}

osExLieren:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osExLieren.name) and
      data.card and
      data.card.trueName == "slash" and
      player:canPindian(data.to)
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      {
        skill_name = osExLieren.name,
        prompt = "#os_ex__lieren-invoke:" .. data.to.id,
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExLieren.name
    local room = player.room
    local to = data.to
    local pindian = player:pindian({ to }, skillName)
    if not player:isAlive() then return end
    if pindian.results[to].winner == player then
      if not to:isNude() then
        local card = room:askToChooseCard(
          player,
          {
            target = to,
            flag = "he",
            skill_name = skillName,
          }
        )
        room:obtainCard(player, card, false, fk.ReasonPrey, player, skillName)
      end
    else
      room:delay(1200)
      if room:getCardArea(pindian.results[to].toCard) == Card.DiscardPile then
        room:obtainCard(player, pindian.results[to].toCard, true, fk.ReasonJustMove, player, skillName)
      end
      if not to:isAlive() or room:getCardArea(pindian.fromCard) ~= Card.DiscardPile then return end
      room:obtainCard(to, pindian.fromCard, true, fk.ReasonJustMove, to, skillName)
    end
  end,
})

return osExLieren

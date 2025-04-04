local os__guimen = fk.CreateSkill {
  name = "os__guimen"
}

Fk:loadTranslationTable{
  ['os__guimen'] = '鬼门',
  ['#os__guimen-target'] = '鬼门：对一名其他角色造成2点雷电伤害',
  [':os__guimen'] = '锁定技，当你因弃置而失去黑桃牌后，你判定：若结果点数与你弃置的其中一张黑桃牌点数差值不大于1，则对一名其他角色造成2点雷电伤害。',
}

os__guimen:addEffect(fk.AfterCardsMove, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).suit == Card.Spade then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).suit == Card.Spade then
            table.insertIfNeed(cids, Fk:getCardById(info.cardId).number)
          end
        end
      end
    end

    local judge = {
      who = player,
      reason = os__guimen.name,
      pattern = num > 0 and (".|" .. num-1 .. "~" .. num+1 ) or nil,
    }
    room:judge(judge)
    if num > 0 and judge.card.number - num < 2 and judge.card.number - num > -2 then
      local pids = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os__guimen-target",
        skill_name = os__guimen.name,
        cancelable = false
      })
      if #pids > 0 then
        room:damage{
          from = player,
          to = pids[1],
          damage = 2,
          damageType = fk.ThunderDamage,
          skillName = os__guimen.name,
        }
      end
    end
  end,
})

return os__guimen

local osDingfa = fk.CreateSkill {
  name = "os__dingfa"
}

Fk:loadTranslationTable{
  ["os__dingfa"] = "定法",
  [":os__dingfa"] = "弃牌阶段结束时，若本回合你失去的牌数不小于你的体力值，你可以选择一项：1. 回复1点体力；2. 对一名其他角色造成1点伤害。",

  ["os__dingfa_damage"] = "对一名其他角色造成1点伤害",
  ["os__dingfa_recover"] = "回复1点体力",
  ["#os__dingfa-target"] = "定法：选择一名其他角色，对其造成1点伤害",
  ["@os__dingfa-turn"] = "定法",

  ["$os__dingfa1"] = "峻礼教之防，准五服以制罪。",
  ["$os__dingfa2"] = "礼律并重，臧善否恶，宽简弼国。",
}

osDingfa:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if not (player == target and player:hasSkill(osDingfa.name) and player.phase == Player.Discard) then
      return false
    end

    local num = 0
    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
      for _, move in ipairs(e.data) do
        if move.from == player and (move.to ~= player or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          num = num + #table.filter(move.moveInfo, function(info)
            return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
          end)
        end
      end
      if num >= player.hp then return true end
    end, Player.HistoryTurn)
    return
      num >= player.hp and
      (player:isWounded() or #player.room:getOtherPlayers(player, false) > 0)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local choices = {}
    if #room:getOtherPlayers(player, false) > 0 then
      table.insert(choices, "os__dingfa_damage")
    end
    if player:isWounded() then
      table.insert(choices, "os__dingfa_recover")
    end
    if #choices == 0 then
      return false
    end

    table.insert(choices, "Cancel")
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osDingfa.name,
        all_choices = { "os__dingfa_damage", "os__dingfa_recover", "Cancel" },
      }
    )

    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osDingfa.name
    local room = player.room
    local cost_data = event:getCostData(self)
    if cost_data == "os__dingfa_recover" then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
    else
      local targets = room:getOtherPlayers(player, false)
      if #targets == 0 then
        return false
      end

      local tos = room:askToChoosePlayers(
        player,
        {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#os__dingfa-target",
          skill_name = skillName,
          cancelable = false,
        }
      )

      room:damage{
        from = player,
        to = tos[1],
        damage = 1,
        skillName = skillName,
      }
    end
  end,
})

osDingfa:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player)
    return player:hasSkill(osDingfa.name) and player.phase ~= Player.NotActive
  end,
  on_refresh = function(self, event, target, player, data)
    local num = 0
    for _, move in ipairs(data) do
      if move.from == player and (move.to ~= player or (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
        num = num + #table.filter(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
    if num > 0 then
      player.room:addPlayerMark(player, "@os__dingfa-turn", num)
    end
  end,
})

return osDingfa

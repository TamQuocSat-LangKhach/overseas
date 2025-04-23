local osShuaiyan = fk.CreateSkill {
  name = "os__shuaiyan"
}

Fk:loadTranslationTable{
  ["os__shuaiyan"] = "率言",
  [":os__shuaiyan"] = "弃牌阶段开始时，若你的手牌数大于1，你可展示所有手牌，令一名其他角色交给你一张牌。",

  ["#os__shuaiyan-ask"] = "率言：你可展示所有手牌，选择一名其他角色，令其交给你一张牌",
  ["#os__shuaiyan-card"] = "率言：交给 %dest 一张牌",

  ["$os__shuaiyan1"] = "并魏之日，想来便是两国争战之时。",
  ["$os__shuaiyan2"] = "在下所言，至诚至率。",
}

osShuaiyan:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osShuaiyan.name) and
      player.phase == Player.Discard and
      player:getHandcardNum() > 1 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__shuaiyan-ask",
        skill_name = osShuaiyan.name,
        cancelable = true,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osShuaiyan.name
    local room = player.room
    player:showCards(player:getCardIds("h"))

    local to = event:getCostData(self).tos[1]
    if not to:isNude() then
      local c = room:askToChooseCards(
        to,
        {
          min = 1,
          max = 1,
          target = to,
          flag = "he",
          skill_name = skillName,
          prompt = "#os__shuaiyan-card::" .. player.id,
        }
      )
      if #c > 0 then
        room:moveCardTo(c[1], Player.Hand, player, fk.ReasonGive, skillName, nil, false, to)
      end
    end
  end,
})

return osShuaiyan

local osZhenxi = fk.CreateSkill {
  name = "os__zhenxi"
}

Fk:loadTranslationTable{
  ["os__zhenxi"] = "震袭",
  [":os__zhenxi"] = "每回合限一次，当你使用【杀】指定目标后，你可选择一项：1.弃置其X张手牌（X为你至其的距离，不足则全弃）；" ..
  "2.移动其场上的一张牌。若其体力值大于你或为全场最高，则你可背水。",

  ["os__zhenxi_discard"] = "弃置其%arg张手牌",
  ["os__zhenxi_move"] = "移动其场上的一张牌",
  ["beishui_os__zhenxi"] = "背水",
  ["#os__zhenxi-ask"] = "震袭：选择要将 %src 场上的牌移动给的角色",

  ["$os__zhenxi1"] = "戮胡首领，捣其王廷！",
  ["$os__zhenxi2"] = "震疆扫寇，袭贼平戎！"
}

osZhenxi:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if
      target == player and
      player:hasSkill(osZhenxi.name) and
      data.card.trueName == "slash" and
      player:usedSkillTimes(osZhenxi.name) < 1 and
      data.to
    then
      local to = data.to
      if to:getHandcardNum() >= player:distanceTo(to) then return true end
      return table.find(player.room.alive_players, function(p) return to:canMoveCardsInBoardTo(p) end)
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local room = player.room
    local to = data.to
    if not to:isKongcheng() then
      table.insert(choices, "os__zhenxi_discard:::" .. player:distanceTo(to))
    end
    if
      table.find(room.alive_players, function(p)
        return to:canMoveCardsInBoardTo(p)
      end)
    then
      table.insert(choices, "os__zhenxi_move")
    end
    if
      to.hp > player.hp or
      table.every(room:getOtherPlayers(to, false), function(p)
        return to.hp >= p.hp
      end)
    then
      table.insert(choices, "beishui_os__zhenxi")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osZhenxi.name,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osZhenxi.name
    local room = player.room
    local to = data.to
    local choice = event:getCostData(self)
    if choice ~= "os__zhenxi_move" and not to:isKongcheng() then
      local n = math.min(player:distanceTo(to), to:getHandcardNum())
      local cards = room:askToChooseCards(
        player,
        {
          min = n,
          max = n,
          flag = "h",
          skill_name = skillName,
          target = to,
        }
      )
      room:throwCard(cards, skillName, to, player)
    end
    if choice == "os__zhenxi_move" or choice == "beishui_os__zhenxi" then
      local targets = table.filter(player.room.alive_players, function(p)
        return to:canMoveCardsInBoardTo(p)
      end)
      if #targets > 0 then
        local tos = room:askToChoosePlayers(
          player,
          {
            min_num = 1,
            max_num = 1,
            targets = targets,
            prompt = "#os__zhenxi-ask:" .. to.id,
            skill_name = skillName,
            cancelable = false,
          }
        )
        if #tos > 0 then
          room:askToMoveCardInBoard(
            player,
            {
              target_one = to,
              target_two = tos[1],
              skill_name = skillName,
              move_from = to,
            }
          )
        end
      end
    end
  end,
})

return osZhenxi

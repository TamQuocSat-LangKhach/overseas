local os__zhenxi = fk.CreateSkill {
  name = "os__zhenxi"
}

Fk:loadTranslationTable{
  ['os__zhenxi'] = '震袭',
  ['os__zhenxi_discard'] = '弃置其%arg张手牌',
  ['os__zhenxi_move'] = '移动其场上的一张牌',
  ['beishui_os__zhenxi'] = '背水',
  ['#os__zhenxi-ask'] = '震袭：选择要将 %src 场上的牌移动给的角色',
  [':os__zhenxi'] = '每回合限一次，当你使用【杀】指定目标后，你可选择一项：1.弃置其X张手牌（X为你至其的距离，不足则全弃）；2.移动其场上的一张牌。若其体力值大于你或为全场最高，则你可背水。',
  ['$os__zhenxi1'] = '戮胡首领，捣其王廷！',
  ['$os__zhenxi2'] = '震疆扫寇，袭贼平戎！'
}

os__zhenxi:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__zhenxi.name) and
      data.card.trueName == "slash" and player:usedSkillTimes(os__zhenxi.name) < 1 and data.to then
      local to = player.room:getPlayerById(data.to)
      if to:getHandcardNum() >= player:distanceTo(to) then return true end
      return table.find(player.room.alive_players, function(p) return to:canMoveCardsInBoardTo(p, nil) end)
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {}
    local room = player.room
    local target = room:getPlayerById(data.to)
    if not target:isKongcheng() then
      table.insert(choices, "os__zhenxi_discard:::" .. player:distanceTo(target))
    end
    if table.find(player.room.alive_players, function(p)
      return target:canMoveCardsInBoardTo(p, nil)
    end) then
      table.insert(choices, "os__zhenxi_move")
    end
    if (target.hp > player.hp or table.every(room:getOtherPlayers(target), function(p)
      return target.hp >= p.hp
    end)) then
      table.insert(choices, "beishui_os__zhenxi")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__zhenxi.name
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(data.to)
    local choice = event:getCostData(self)
    if choice ~= "os__zhenxi_move" and not target:isKongcheng() then
      local n = math.min(player:distanceTo(target), target:getHandcardNum())
      local cards = room:askToChooseCards(player, {
        min_num = n,
        max_num = n,
        flag = "h",
        skill_name = os__zhenxi.name,
        target = target
      })
      room:throwCard(cards, os__zhenxi.name, target, player)
    end
    if choice == "os__zhenxi_move" or choice == "beishui_os__zhenxi" then
      local targets = table.map(table.filter(player.room.alive_players, function(p)
        return target:canMoveCardsInBoardTo(p, nil)
      end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          prompt = "#os__zhenxi-ask:" .. target.id,
          skill_name = os__zhenxi.name
        })
        if #to > 0 then
          room:askToMoveCardInBoard(player, {
            target_one = target,
            target_two = room:getPlayerById(to[1]),
            skill_name = os__zhenxi.name
          })
        end
      end
    end
  end,
})

return os__zhenxi

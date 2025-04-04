local zhilue = fk.CreateSkill {
  name = "os_xing__zhilue"
}

Fk:loadTranslationTable{
  ['os_xing__zhilue'] = '知略',
  ['os_xing__zhilue_draw'] = '此回合你摸牌阶段额定摸牌数+1，使用的第一张【杀】不计入次数且无距离限制',
  ['os_xing__zhilue_move'] = '移动场上的一张牌，若此牌为：装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1',
  ['#os_xing__zhilue-movecard'] = '知略：移动场上的一张牌，若此牌为：装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1',
  ['@@os_xing__zhilue-turn'] = '知略',
  [':os_xing__zhilue'] = '准备阶段开始时，你可选择一项：1. 移动场上的一张牌，若此牌为：装备牌，你失去1点体力；延时锦囊牌，你此回合手牌上限-1；2. 此回合你摸牌阶段额定摸牌数+1，使用的第一张【杀】不计入次数且无距离限制。',
  ['$os_xing__zhilue1'] = '时以进而取之，无则磨锋以待。',
  ['$os_xing__zhilue2'] = '知敌之薄弱，略我之计谋。',
}

-- 第一个触发技
zhilue:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zhilue) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local choices = {"os_xing__zhilue_draw", "Cancel"}
    local room = player.room
    if #room:canMoveCardInBoard() > 0 then
      table.insert(choices, 1, "os_xing__zhilue_move")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhilue.name,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = event:getCostData(self)
    if choice == "os_xing__zhilue_move" then
      local targets = room:askToChooseToMoveCardInBoard(player, {
        skill_name = zhilue.name,
      })
      local card = room:askToMoveCardInBoard(player, {
        target_one = room:getPlayerById(targets[1]),
        target_two = room:getPlayerById(targets[2]),
        skill_name = zhilue.name
      }).card
      if player.dead then return end
      if card.type == Card.TypeEquip then
        room:loseHp(player, 1, zhilue.name)
      elseif card.sub_type == Card.SubtypeDelayedTrick then
        room:addPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 1)
      end
    else
      room:addPlayerMark(player, "@@os_xing__zhilue-turn")
    end
  end,
})

-- 第二个触发技（draw效果）
zhilue:addEffect(fk.DrawNCards, {
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("@@os_xing__zhilue-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + player:getMark("@@os_xing__zhilue-turn")
  end,
})

-- 目标修正技能（buff效果）
zhilue:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope, card)
    return (player:hasSkill(zhilue) and skill.trueName == "slash_skill") and 1 or 0
  end,
  distance_limit_func = function(self, player, skill, card)
    return (player:hasSkill(zhilue) and skill.trueName == "slash_skill" and player:usedCardTimes("slash", Player.HistoryTurn) == 0) and 998 or 0
  end,
})

return zhilue

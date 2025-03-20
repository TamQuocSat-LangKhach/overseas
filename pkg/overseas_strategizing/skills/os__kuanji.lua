local os__kuanji = fk.CreateSkill{
  name = "os__kuanji"
}

Fk:loadTranslationTable{
  ['os__kuanji'] = '宽济',
  ['#os__kuanji-ask'] = '宽济：你可令一名其他角色获得其中的任意张牌',
  ['#os__kuanji-cards'] = '宽济：令 %dest 获得其中任意张牌',
  ['os__kuanji_all'] = '令其获得全部',
  ['os__kuanji_selected'] = '令其获得选择的牌',
  [':os__kuanji'] = '每回合限一次，当你的牌非因使用而置入弃牌堆后，你可令一名其他角色获得其中的任意张牌。',
  ['$os__kuanji1'] = '功以才成，业由才广，弃才不用，非长计也。',
  ['$os__kuanji2'] = '舍此不任而防后患，是备风波而废舟楫也。',
}

os__kuanji:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__kuanji.name) or player:usedSkillTimes(os__kuanji.name) > 0 then return false end
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        return table.find(move.moveInfo, function(info)
          return info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local other_players = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local target = room:askToChoosePlayers(player, {
      targets = other_players,
      min_num = 1,
      max_num = 1,
      prompt = "#os__kuanji-ask",
      skill_name = os__kuanji.name
    })
    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    target = event:getCostData(skill)
    local cards = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        table.forEach(move.moveInfo, function(info)
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(cards, info.cardId)
          end
        end)
      end
    end
    local cids
    local choice = "os__kuanji_all"
    if #cards > 1 then
      cids, choice = U.askToChooseCardsAndChoices(player, {
        choices = {"os__kuanji_selected"},
        skill_name = os__kuanji.name,
        prompt = "#os__kuanji-cards::" .. target:name(),
        all_choices = {"os__kuanji_all"},
        min_num = 1,
        max_num = #cards
      }, cards)
    end
    if choice == "os__kuanji_all" then
      cids = cards
    end
    if #cids > 0 then
      room:obtainCard(target, cids, true, fk.ReasonJustMove, player.id)
    end
  end,
})

return os__kuanji

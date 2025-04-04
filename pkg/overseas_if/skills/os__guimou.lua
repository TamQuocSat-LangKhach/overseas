local os__guimou = fk.CreateSkill {
  name = "os__guimou"
}

Fk:loadTranslationTable{
  ['os__guimou'] = '鬼谋',
  ['#os__guimou-retrial'] = '鬼谋：选择一张牌改判%dest的%arg，其余置于牌堆顶',
  [':os__guimou'] = '每回合限两次，当一名角色的判定牌生效前，你可观看牌堆底的四张牌，选择其中一张牌代替之，然后将其余牌以任意顺序置于牌堆顶。',
  ['$os__guimou1'] = '将在外而君死社稷，自不受他人之治。',
  ['$os__guimou2'] = '诸葛贼计已穷，且看老夫此番谋略何如。',
}

os__guimou:addEffect(fk.AskForRetrial, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__guimou.name) and player:usedSkillTimes(os__guimou.name) < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4, "bottom")
    local result = room:askToArrangeCards(player, {
      skill_name = os__guimou.name,
      card_map = {cards, "Bottom", {}, "Retrial", {}, "Top"},
      prompt = "#os__guimou-retrial::" .. target.id .. ":" .. data.reason,
      box_size = 4,
      max_limit = {0, 1, 3},
      min_limit = {0, 1, 3}
    })
    local card = result[2][1]
    player.room:retrial(Fk:getCardById(card), player, data, os__guimou.name)
    if player.dead then return end
    local top = table.reverse(result[3])
    room:moveCards({
      ids = top,
      from = target.id,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = os__guimou.name,
      proposer = player.id,
      moveVisible = false,
      visiblePlayers = {player.id},
    })
  end
})

return os__guimou

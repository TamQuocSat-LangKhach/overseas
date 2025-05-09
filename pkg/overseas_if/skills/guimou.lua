local guimou = fk.CreateSkill {
  name = "os__guimou",
}

Fk:loadTranslationTable{
  ["os__guimou"] = "鬼谋",
  [":os__guimou"] = "每回合限两次，当一名角色的判定牌生效前，你可以观看牌堆底的四张牌，选择其中一张牌代替之，然后将其余牌以任意顺序置于牌堆顶。",

  ["#os__guimou-invoke"] = "缓释：你可以观看牌堆底四张牌，选择其中一张修改 %dest 的“%arg”判定",
  ["#os__guimou-retrial"] = "鬼谋：选择一张牌修改 %dest 的“%arg”判定，其余置于牌堆顶",

  ["$os__guimou1"] = "将在外而君死社稷，自不受他人之治。",
  ["$os__guimou2"] = "诸葛贼计已穷，且看老夫此番谋略何如。",
}

guimou:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(guimou.name) and player:usedSkillTimes(guimou.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = guimou.name,
      prompt = "#os__guimou-invoke::"..target.id..":"..data.reason
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4, "bottom")
    local result = room:askToArrangeCards(player, {
      skill_name = guimou.name,
      card_map = {cards, "Bottom", {}, "Retrial", {}, "Top"},
      prompt = "#os__guimou-retrial::" .. target.id .. ":" .. data.reason,
      box_size = 4,
      max_limit = {0, 1, 3},
      min_limit = {0, 1, 3}
    })
    local card = result[2][1]
    room:changeJudge{
      card = Fk:getCardById(card),
      player = player,
      data = data,
      skillName = guimou.name,
    }
    local top = table.reverse(result[3])
    room:moveCards({
      ids = top,
      from = target,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonPut,
      skillName = guimou.name,
      proposer = player,
      moveVisible = false,
      visiblePlayers = {player},
    })
  end
})

return guimou

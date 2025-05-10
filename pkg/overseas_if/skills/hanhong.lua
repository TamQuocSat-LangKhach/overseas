local hanhong = fk.CreateSkill {
  name = "os__hanhong",
}

Fk:loadTranslationTable{
  ["os__hanhong"] = "翰鸿",
  [":os__hanhong"] = "出牌阶段每种花色限一次，你可以声明一种花色并弃置X张牌（X为你手牌中花色最多的牌数），观看牌堆顶前等量张你声明花色的牌，"..
  "获得其中一张牌。若你弃置了♣牌，你摸一张牌。",

  ["#os__hanhong"] = "翰鸿：声明一种花色，弃置%arg张牌，从牌堆获得一张此花色的牌",
  ["#os__hanhong-prey"] = "翰鸿：获得其中一张牌",

  ["$os__hanhong1"] = "鸿雁携诗去，天地入怀来！",
  ["$os__hanhong2"] = "正合凌霄瀚，弃梅引凤彰！",
}

local hanhongCount = function (player)
    local suits = {}
    for _, id in ipairs(player:getCardIds("h")) do
      local suit = Fk:getCardById(id).suit
      if suit ~= Card.NoSuit then
        suits[suit] = (suits[suit] or 0) + 1
      end
    end
    local max = 0
    for _, num in pairs(suits) do
      if num > max then
        max = num
      end
    end
    return max
end

hanhong:addEffect("active", {
  anim_type = "drawcard",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#os__hanhong:::"..hanhongCount(player)
  end,
  card_num = function (self, player)
    return hanhongCount(player)
  end,
  target_num = 0,
  interaction = function (self, player)
    local all_choices = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choices = table.filter(all_choices, function (choice)
      return not table.contains(player:getTableMark("os__hanhong-phase"), choice)
    end)
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(hanhong.name, Player.HistoryPhase) == 0
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected < hanhongCount(player) and not player:prohibitDiscard(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:addTableMark(player, "os__hanhong-phase", self.interaction.data)
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = self.interaction.data,
      toast = true,
    }
    local yes = table.find(effect.cards, function (id)
      return Fk:getCardById(id).suit == Card.Club
    end)
    room:throwCard(effect.cards, hanhong.name, player, player)
    if player.dead then return end
    local cards = {}
    for _, id in ipairs(room.draw_pile) do
      if Fk:getCardById(id):getSuitString(true) == self.interaction.data then
        table.insert(cards, id)
        if #cards >= #effect.cards then
          break
        end
      end
    end
    if #cards > 0 then
      local card = room:askToChooseCard(player, {
        target = player,
        flag = { card_data = {{ "toObtain", cards }} },
        skill_name = hanhong.name,
        prompt = "#os__hanhong-prey",
      })
      room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonJustMove, hanhong.name, nil, false, player)
      if player.dead then return end
    end
    if yes then
      player:drawCards(1, hanhong.name)
    end
  end,
})

hanhong:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "os__hanhong-phase", 0)
end)

return hanhong

local os_ex__gongqi = fk.CreateSkill {
  name = "os_ex__gongqi"
}

Fk:loadTranslationTable{
  ['os_ex__gongqi'] = '弓骑',
  ['#os_ex__gongqi-ask'] = '弓骑：你可弃置一名其他角色的一张牌',
  [':os_ex__gongqi'] = '①你的攻击范围无限。②出牌阶段限一次，你可弃置一张牌，你于此阶段内使用与弃置的牌花色相同的【杀】无次数限制。若弃置的为装备牌，你可弃置一名其他角色的一张牌。',
  ['$os_ex__gongqi1'] = '鼠辈，哪里走！',
  ['$os_ex__gongqi2'] = '吃我一箭！',
}

-- 主动技能效果
os_ex__gongqi:addEffect('active', {
  anim_type = "offensive",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(os_ex__gongqi.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, os_ex__gongqi.name, player)
    room:setPlayerMark(player, "_os_ex__gongqi-turn", Fk:getCardById(effect.cards[1]).suit)
    if player:isAlive() and Fk:getCardById(effect.cards[1]).type == Card.TypeEquip then
      local to = room:askToChoosePlayers(player, {
        targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
          return not p:isNude()
        end), Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os_ex__gongqi-ask",
        skill_name = os_ex__gongqi.name,
        cancelable = true
      })
      if #to > 0 then
        local target = room:getPlayerById(to[1])
        local id = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = os_ex__gongqi.name
        })
        room:throwCard({id}, os_ex__gongqi.name, target, player)
      end
    end
  end,
})

-- 攻击范围技能效果
os_ex__gongqi:addEffect('atkrange', {
  name = "#os_ex__gongqi_attackrange",
  correct_func = function (self, from, to)
    return from:hasSkill(os_ex__gongqi) and math.huge or 0
  end,
})

-- 目标修正技能效果
os_ex__gongqi:addEffect('targetmod', {
  name = "#os_ex__gongqi_buff",
  anim_type = "offensive",
  bypass_times = function (self, player, skill, scope, card, to)
    return player:getMark("_os_ex__gongqi-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase and card and card.suit == player:getMark("_os_ex__gongqi-turn")
  end
})

return os_ex__gongqi

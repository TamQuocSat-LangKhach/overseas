local os__yuhua = fk.CreateSkill {
  name = "os__yuhua"
}

Fk:loadTranslationTable{
  ['os__yuhua'] = '羽化',
  ['os__yuhuaDraw'] = '摸%arg张牌',
  [':os__yuhua'] = '锁定技，弃牌阶段，你的非基本牌不计入手牌上限。当你于回合外失去非基本牌后，你可观看牌堆顶的X张牌并将其置于牌堆顶或牌堆底，然后你可摸X张牌（X为你此次失去牌的数量且至多为5）。',
  ['$os__yuhua1'] = '凤羽飞烟，乘化仙尘。',
  ['$os__yuhua2'] = '此乃仙人之物，不可轻弃。',
}

os__yuhua:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) or player.phase ~= Player.NotActive then return false end
    for _, move in ipairs(data) do
      if move.from == player.id then
        if table.find(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and Fk:getCardById(info.cardId).type ~= Card.TypeBasic
        end) then return true end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, { skill_name = skill.name })
  end,
  on_use = function(self, event, target, player, data)
    local num = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        num = num + #table.filter(move.moveInfo, function(info)
          return (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
        end)
      end
    end
    num = math.min(5, num)
    local room = player.room
    room:askToGuanxing(player, { cards = room:getNCards(num) })
    if room:askToChoice(player, {
      choices = {"os__yuhuaDraw:::" .. num, "Cancel"},
      skill_name = skill.name,
    }) ~= "Cancel" then
      player:drawCards(num, os__yuhua.name)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return player == target and player:hasSkill(skill.name) and player.phase == Player.Discard
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(skill.name)
    player.room:notifySkillInvoked(player, skill.name, "defensive")
  end,
})

local os__yuhuaMax = fk.CreateMaxCardsSkill{
  name = "#os__yuhuaMax",
  exclude_from = function(self, player, card)
    return player:hasSkill(os__yuhua) and card.type ~= Card.TypeBasic
  end,
}

os__yuhua:addRelatedSkill(os__yuhuaMax)

return os__yuhua

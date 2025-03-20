local os__ejian = fk.CreateSkill {
  name = "os__ejian"
}

Fk:loadTranslationTable{
  ['os__ejian'] = '恶荐',
  ['#os__ejian-invoke'] = '你想对 %dest 发动技能“恶荐”吗？',
  ['os__ejian_discard'] = '弃置除获得的牌外和获得的牌类别相同的牌',
  ['os__ejian_damage'] = '受到1点伤害',
  [':os__ejian'] = '当其他角色获得你的牌后，若其有除此牌以外的牌与此牌类别相同的牌，你可令其选择：1. 弃置这些牌；2. 受到你造成的1点伤害。',
  ['$os__ejian1'] = '为政者当沙汰秽浊，显拔幽滞，以顺民心。',
  ['$os__ejian2'] = '此所谓寡助之至，天下叛之矣。',
}

os__ejian:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__ejian.name) then return false end
    for _, move in ipairs(data) do
      local toPlayer = move.to and player.room:getPlayerById(move.to) or nil
      local fromPlayer = move.from and player.room:getPlayerById(move.from) or nil
      if fromPlayer and fromPlayer == player and toPlayer and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            local id = info.cardId
            table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
            table.insert(fromCard, id)
          end
        end
        local cids = toPlayer:getCardIds{Player.Hand, Player.Equip}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            return true
          end
        end
      end
    end
    return false
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      local toPlayer = move.to and player.room:getPlayerById(move.to) or nil
      local fromPlayer = move.from and player.room:getPlayerById(move.from) or nil
      if fromPlayer and fromPlayer == player and toPlayer and move.to ~= player.id and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            local id = info.cardId
            table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
            table.insert(fromCard, id)
          end
        end
        local cids = toPlayer:getCardIds{Player.Hand, Player.Equip}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            table.insertIfNeed(targets, move.to)
            break
          end
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(os__ejian.name) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = os__ejian.name,
      prompt = "#os__ejian-invoke::" .. target.id,
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local cards = {}
    for _, move in ipairs(data) do
      local toPlayer = move.to and player.room:getPlayerById(move.to) or nil
      local fromPlayer = move.from and player.room:getPlayerById(move.from) or nil
      if fromPlayer and fromPlayer == player and fromPlayer:hasSkill(os__ejian.name) and toPlayer == target and move.toArea == Card.PlayerHand then
        local cardType = {}
        local fromCard = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          table.insertIfNeed(cardType, Fk:getCardById(id):getTypeString())
          table.insert(fromCard, id)
        end
        local cids = target:getCardIds{Player.Hand, Player.Equip}
        for _, id in ipairs(cids) do
          if table.contains(cardType, Fk:getCardById(id):getTypeString()) and not table.contains(fromCard, id) then
            table.insert(cards, id)
          end
        end
        if #cards > 0 then
          break
        end
      end
    end
    local choice = room:askToChoice(target, {
      choices = {"os__ejian_discard", "os__ejian_damage"},
      skill_name = os__ejian.name,
    })
    if choice == "os__ejian_damage" then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = os__ejian.name,
      }
    else
      room:throwCard(cards, os__ejian.name, target)
    end
  end,
})

return os__ejian

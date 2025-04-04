local os__tuidao = fk.CreateSkill {
  name = "os__tuidao"
}

Fk:loadTranslationTable{
  ['os__tuidao'] = '颓盗',
  ['#os__tuidao-ask2'] = '颓盗：你可废除你的一个坐骑栏，从牌堆中获得两张指定类别的牌，选择另一名角色作为新的“随征”角色',
  ['#os__tuidao-ask'] = '颓盗：你可废除你与 %dest 的一个坐骑栏，获得其所有指定类别的牌，选择另一名角色作为新的“随征”角色',
  ['#os__tuidao-card2'] = '颓盗：选择一个牌的类别，从牌堆中获得两张该类别的牌',
  ['#os__tuidao-card'] = '颓盗：选择一个牌的类别，获得 %dest 所有该类别的牌',
  ['#os__tuidao-new'] = '颓盗：选择一个新的“随征”角色，令其获得刚刚撸到的牌',
  ['@os__suizheng'] = '随征',
  [':os__tuidao'] = '限定技，准备阶段开始时，若“随征”角色体力值不大于2或已死亡，你可废除你与其的一个坐骑栏位，然后选择一个类别的牌，获得其所有该类别的牌（若其已死亡，则改为从牌堆中获得两张指定类别的牌），然后选择另一名其他角色作为新的“随征”角色，并令其获得这些牌。',
  ['$os__tuidao1'] = '将军大势已去，续无可奈何啊。',
  ['$os__tuidao2'] = '续投明主，还望将军勿怪才是。',
}

os__tuidao:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player)
    if target ~= player or not player:hasSkill(os__tuidao) or player:getMark("_os__suizheng") == 0 or player.phase ~= Player.Start then return false end 
    local to = player.room:getPlayerById(player:getMark("_os__suizheng"))
    if not (to.hp <= 2 or to.dead) then return false end
    return (#player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0 and #to:getAvailableEquipSlots(Card.SubtypeOffensiveRide) > 0)
      or (#player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0 and #to:getAvailableEquipSlots(Card.SubtypeDefensiveRide) > 0)
  end,
  on_cost = function(self, event, target, player)
    local all_choices = {"DefensiveRideSlot", "OffensiveRideSlot", "Cancel"}
    local choices = {"DefensiveRideSlot", "OffensiveRideSlot"}
    local to = player.room:getPlayerById(player:getMark("_os__suizheng"))
    local dead = to.dead
    if #player:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0 or (not dead and #to:getAvailableEquipSlots(Card.SubtypeOffensiveRide) == 0) then
      table.remove(choices)
    end
    if #player:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0 or (not dead and #to:getAvailableEquipSlots(Card.SubtypeDefensiveRide) == 0) then
      table.remove(choices, 1)
    end
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = os__tuidao.name,
      prompt = dead and "#os__tuidao-ask2" or "#os__tuidao-ask::" .. to.id,
      detailed = false,
      all_choices = all_choices
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local choice = event:getCostData(self)
    local room = player.room
    local to = room:getPlayerById(player:getMark("_os__suizheng"))
    local slot = choice == "OffensiveRideSlot" and Player.OffensiveRideSlot or Player.DefensiveRideSlot
    room:abortPlayerArea(player, {slot})
    local dead = to.dead
    if not dead then room:abortPlayerArea(to, {slot}) end
    local choices = {"basic", "trick", "equip"}
    choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__tuidao.name,
      prompt = dead and "#os__tuidao-card2" or "#os__tuidao-card::" .. to.id
    })
    local cards = dead and room:getCardsFromPileByRule(".|.|.|.|.|" .. choice, 2) or
    table.filter(to:getCardIds{Player.Hand, Player.Equip}, function(id) return Fk:getCardById(id):getTypeString() == choice end)
    if #cards > 0 then
      room:obtainCard(player, cards, false, fk.ReasonPrey)
    end
    local targets = table.map(table.filter(room.alive_players, function(p) return p ~= player and p ~= to end), Util.IdMapper)
    if #targets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__tuidao-new",
      skill_name = os__tuidao.name
    })[1]
    room:setPlayerMark(player, "_os__suizheng", target)
    local new_target = room:getPlayerById(target)
    room:setPlayerMark(player, "@os__suizheng", new_target.general)
    if #cards > 0 then
      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, new_target, fk.ReasonPrey, os__tuidao.name, nil, false, player.id)
      end
    end
  end,
})

return os__tuidao

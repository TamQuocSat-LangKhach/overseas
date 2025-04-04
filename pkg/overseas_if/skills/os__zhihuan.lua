local os__zhihuan = fk.CreateSkill {
  name = "os__zhihuan"
}

Fk:loadTranslationTable{
  ['os__zhihuan'] = '治宦',
  ['#os__zhihuan-invoke'] = '你可发动〖治宦〗，防止对 %dest 的伤害',
  ['os__zhihuan_target'] = '获得其装备区里的一张牌',
  ['os__zhihuan_pile'] = '获得并使用一张牌堆或弃牌堆中与你空置的装备栏对应类型的装备牌',
  ['@@os__zhihuan_discard'] = '被治宦',
  ['#os__zhihuan_delay'] = '治宦',
  [':os__zhihuan'] = '当你使用【杀】造成伤害时，你可防止此伤害并选择一项：1. 获得其装备区里的一张牌；2. 获得并使用一张牌堆或弃牌堆中与你空置的装备栏对应类型的装备牌。若如此做，其下次使用【闪】时随机弃置两张手牌。',
  ['$os__zhihuan1'] = '贪行祸国，谗言媚主，汝罪不容诛！',
  ['$os__zhihuan2'] = '阉宦小人，何以蔽天！',
}

os__zhihuan:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(os__zhihuan.name) and data.card and data.card.trueName == "slash"
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = os__zhihuan.name,
      prompt = "#os__zhihuan-invoke::" .. data.to.id
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    target = data.to
    local choices
    if #target:getCardIds(Player.Equip) > 0 then
      choices = {"os__zhihuan_target", "os__zhihuan_pile"}
    else
      choices = {"os__zhihuan_pile"}
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__zhihuan.name
    })
    if choice == "os__zhihuan_target" then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "e",
        skill_name = os__zhihuan.name
      })
      room:obtainCard(player.id, card, true, fk.ReasonPrey, player.id, os__zhihuan.name)
    else
      local subtype_string_table = {
        [Card.SubtypeArmor] = "armor",
        [Card.SubtypeWeapon] = "weapon",
        [Card.SubtypeTreasure] = "treasure",
        [Card.SubtypeDelayedTrick] = "delayed_trick",
        [Card.SubtypeDefensiveRide] = "defensive_ride",
        [Card.SubtypeOffensiveRide] = "offensive_ride",
      }
      local slots = table.simpleClone(player:getAvailableEquipSlots())
      table.shuffle(slots)
      for _, slot in ipairs(slots) do
        if player.dead then return end
        local type = Util.convertSubtypeAndEquipSlot(slot)
        if #player:getEquipments(type) < #player:getAvailableEquipSlots(type) then
          local ids = room:getCardsFromPileByRule(".|.|.|.|.|"..subtype_string_table[type], 1, "allPiles")
          if #ids > 0 then
            room:obtainCard(player, ids[1], true, fk.ReasonPrey, player.id, os__zhihuan.name)
            if not player.dead then
              room:useCard{
                from = player.id,
                tos = {{player.id}},
                card = Fk:getCardById(ids[1]),
              }
              break
            end
          end
        end
      end
    end
    room:setPlayerMark(target, "@@os__zhihuan_discard", 1)
    return true
  end,
})

os__zhihuan:addEffect(fk.CardUsing, {
  name = "#os__zhihuan_delay",
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return player == target and data.card.trueName == "jink" and player:getMark("@@os__zhihuan_discard") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local cards = player:getCardIds(Player.Hand)
    local room = player.room
    room:setPlayerMark(player, "@@os__zhihuan_discard", 0)
    if #cards > 0 then
      room:throwCard(table.random(cards, 2), os__zhihuan.name, player, player)
    end
  end,
})

return os__zhihuan

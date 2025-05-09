local zhihuan = fk.CreateSkill {
  name = "os__zhihuan",
}

Fk:loadTranslationTable{
  ["os__zhihuan"] = "治宦",
  [":os__zhihuan"] = "当你使用【杀】造成伤害时，你可以防止此伤害并选择一项：1.获得其装备区里的一张牌；" ..
  "2.获得并使用一张牌堆或弃牌堆中与你空置的装备栏对应类型的装备牌。若如此做，其下次使用【闪】时随机弃置两张手牌。",

  ["#os__zhihuan-invoke"] = "治宦：你可以防止对 %dest 造成的伤害并执行效果",
  ["os__zhihuan_prey"] = "获得%dest装备区一张牌",
  ["os__zhihuan_equip"] = "获得并使用一张装备",
  ["@@os__zhihuan_discard"] = "被治宦",

  ["$os__zhihuan1"] = "贪行祸国，谗言媚主，汝罪不容诛！",
  ["$os__zhihuan2"] = "阉宦小人，何以蔽天！",
}

zhihuan:addEffect(fk.DamageCaused, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhihuan.name) and
      data.card and data.card.trueName == "slash"
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhihuan.name,
      prompt = "#os__zhihuan-invoke::" .. data.to.id
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    data:preventDamage()
    local choices
    if #data.to:getCardIds("e") > 0 then
      choices = {"os__zhihuan_prey::"..data.to.id, "os__zhihuan_equip"}
    else
      choices = {"os__zhihuan_equip"}
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhihuan.name,
    })
    if choice:startsWith("os__zhihuan_prey") then
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = "e",
        skill_name = zhihuan.name,
      })
      room:obtainCard(player, card, true, fk.ReasonPrey, player, zhihuan.name)
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
            local id = table.random(ids)
            room:obtainCard(player, id, true, fk.ReasonPrey, player, zhihuan.name)
            if not player.dead and table.contains(player:getCardIds("h"), id) and
              player:canUseTo(Fk:getCardById(id), player) then
              room:useCard{
                from = player,
                tos = {player},
                card = Fk:getCardById(id),
              }
            end
            break
          end
        end
      end
    end
    if not data.to.dead then
      room:setPlayerMark(data.to, "@@os__zhihuan_discard", 1)
    end
  end,
})

zhihuan:addEffect(fk.CardUsing, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and data.card.trueName == "jink" and player:getMark("@@os__zhihuan_discard") > 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@os__zhihuan_discard", 0)
    local cards = table.filter(player:getCardIds("h"), function (id)
      return not player:prohibitDiscard(id)
    end)
    if #cards > 0 then
      room:throwCard(table.random(cards, 2), zhihuan.name, player, player)
    end
  end,
})

return zhihuan

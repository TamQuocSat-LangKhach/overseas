local chihui = fk.CreateSkill {
  name = "os__chihui",
}

Fk:loadTranslationTable{
  ["os__chihui"] = "炽灰",
  [":os__chihui"] = "其他角色的回合开始时，你可以废除一个装备栏，选择：1.弃置其区域里的一张牌；"..
  "2.将牌堆里的一张对应副类别的牌置入其装备区。若如此做，你失去1点体力，摸X张牌（X为你已损失的体力值且至多为2）。",

  ["#os__chihui-choice"] = "炽灰：你可以废除一个装备栏，对 %dest 执行一项",

  ["os__chihui_discard"] = "弃置%dest区域里的一张牌",
  ["os__chihui_putequip"] = "将%arg置入%dest的装备区",

  ["$os__chihui1"] = "愿舍身以照长夜，助父亲突破重围！",
  ["$os__chihui2"] = "冷夜孤光，亦怀炽焰于心。",
}

chihui:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(chihui.name) and target ~= player and
      not target.dead and #player:getAvailableEquipSlots() > 0
  end,
  on_cost = function (self, event, target, player, data)
    local all_choices = {
      "WeaponSlot",
      "ArmorSlot",
      "DefensiveRideSlot",
      "OffensiveRideSlot",
      "TreasureSlot"
    }
    local subtypes = {
      Card.SubtypeWeapon,
      Card.SubtypeArmor,
      Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide,
      Card.SubtypeTreasure
    }
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    table.insert(all_choices, "Cancel")
    table.insert(choices, "Cancel")
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = chihui.name,
      prompt = "#os__chihui-choice::" .. target.id,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:abortPlayerArea(player, {event:getCostData(self).choice})
    if player.dead or target.dead then return end

    local subtype = Util.convertSubtypeAndEquipSlot(event:getCostData(self))
    local mapper = {
      [Card.SubtypeWeapon] = "weapon",
      [Card.SubtypeArmor] = "armor",
      [Card.SubtypeOffensiveRide] = "offensive_horse",
      [Card.SubtypeDefensiveRide] = "defensive_horse",
      [Card.SubtypeTreasure] = "treasure",
    }
    local all_choices = {
      "os__chihui_discard::" .. target.id,
      "os__chihui_putequip::" .. target.id .. ":" .. mapper[subtype],
    }
    local choices = {}
    if not target:isAllNude() then
      table.insert(choices, all_choices[1])
    end
    if target:hasEmptyEquipSlot(subtype) then
      table.insert(choices, all_choices[2])
    end
    if #choices == 0 then return false end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = chihui.name,
      all_choices = all_choices,
    })
    if choice == all_choices[1] then
      local card = room:askToChooseCard(player, {
        target = target,
        flag = "hej",
        skill_name = chihui.name
      })
      room:throwCard(card, chihui.name, target, player)
    else
      local cards = table.filter(room.draw_pile, function(id)
        return Fk:getCardById(id).sub_type == subtype
      end)
      if #cards > 0 then
        room:moveCardIntoEquip(target, table.random(cards), chihui.name, false, player)
      end
    end
    if player.dead then return end
    room:loseHp(player, 1, chihui.name)
    if player.dead then return end
    local x = player:getLostHp()
    if x > 0 then
      room:drawCards(player, math.min(x, 2), chihui.name)
    end
  end
})

return chihui

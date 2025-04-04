local osHuangzhu = fk.CreateSkill { name = "os__huangzhu" }

Fk:loadTranslationTable {
  ['os__huangzhu'] = '煌烛',
  ['@$os__huangzhu'] = '煌烛',
  ['#os__huangzhu-choice'] = '是否发动 煌烛，选择一个已被废除的装备栏',
  ['#os__huangzhu-invoke'] = '是否发动 煌烛，视为拥有至多2张已记录的装备牌的技能',
  [':os__huangzhu'] = '准备阶段，你可以选择一个已被废除的装备栏，从牌堆或弃牌堆中随机获得一张对应副类别的装备牌（若无则随机获得一张装备牌），并记录此牌牌名。出牌阶段开始时，你可以选择或变更至多两个已记录且对应装备栏已被废除的装备牌牌名（每种副类别限一个），视为拥有这些装备牌的技能直到此装备栏被恢复。',
  ['$os__huangzhu1'] = '赤心所愿，只愿天下清明！',
  ['$os__huangzhu2'] = '魏室初兴，长夜终尽。',
}

osHuangzhu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(osHuangzhu.name) and target == player then
      if player.phase == Player.Start then
        return table.find(player.equipSlots, function (slot)
          return table.contains(player.sealedSlots, slot)
        end)
      elseif player.phase == Player.Play then
        return #player:getTableMark("@$os__huangzhu") > 0 and table.find(player.equipSlots, function (slot)
          return table.contains(player.sealedSlots, slot)
        end)
      end
    end
  end,
  on_cost = function(self, event, target, player)
    if player.phase == Player.Start then
      local all_choices = {
        "WeaponSlot",
        "ArmorSlot",
        "DefensiveRideSlot",
        "OffensiveRideSlot",
        "TreasureSlot"
      }
      local choices = {}
      for i = 1, 5, 1 do
        if table.contains(player.sealedSlots, all_choices[i]) then
          table.insert(choices, all_choices[i])
        end
      end
      table.insert(all_choices, "Cancel")
      table.insert(choices, "Cancel")
      local choice = player.room:askToChoice(player, {
        choices = choices,
        skill_name = osHuangzhu.name,
        prompt = "#os__huangzhu-choice",
        detailed = false,
        all_choices = all_choices
      })
      if choice ~= "Cancel" then
        event:setCostData(self, choice)
        return true
      end
    elseif player.phase == Player.Play then
      return player.room:askToSkillInvoke(player, {
        skill_name = osHuangzhu.name,
        prompt = "#os__huangzhu-invoke"
      })
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if player.phase == Player.Start then
      local subtype_string_table = {
        [Player.ArmorSlot] = "armor",
        [Player.WeaponSlot] = "weapon",
        [Player.TreasureSlot] = "treasure",
        [Player.DefensiveRideSlot] = "defensive_ride",
        [Player.OffensiveRideSlot] = "offensive_ride",
      }
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|" .. subtype_string_table[event:getCostData(self)], 1, "allPiles")
      if #cards == 0 then
        cards = room:getCardsFromPileByRule(".|.|.|.|.|equip", 1, "allPiles")
      end
      if #cards == 0 then return false end
      local card = Fk:getCardById(table.random(cards))
      local card_names = player:getTableMark("@$os__huangzhu")
      if table.insertIfNeed(card_names, card.name) then
        room:setPlayerMark(player, "@$os__huangzhu", card_names)
      end
      room:obtainCard(player, card, true, fk.ReasonJustMove, player.id, osHuangzhu.name)
    else
      local card_names = player:getTableMark("@$os__huangzhu")
      local names = {}
      local choices = table.filter(card_names, function(name)
        local card = Fk:cloneCard(name)
        return table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(card.sub_type))
      end)
      if #choices == 0 then return false end
      local name1 = room:askToChoice(player, {
        choices = choices,
        skill_name = osHuangzhu.name
      })
      table.insert(names, name1)
      local subtype = Fk:cloneCard(name1).sub_type
      choices = table.filter(choices, function(name)
        local card = Fk:cloneCard(name)
        return card.sub_type ~= subtype and table.contains(player.sealedSlots, Util.convertSubtypeAndEquipSlot(card.sub_type))
      end)
      if #choices > 0 then
        table.insert(choices, "Cancel")
        name1 = room:askToChoice(player, {
          choices = choices,
          skill_name = osHuangzhu.name
        })
        if name1 ~= "Cancel" then
          table.insert(names, name1)
        end
      end
      local all_slots = {
        "WeaponSlot",
        "ArmorSlot",
        "DefensiveRideSlot",
        "OffensiveRideSlot",
        "TreasureSlot"
      }
      for _, slot in ipairs(all_slots) do
        local name = player:getMark("@os__huangzhu_" .. slot)
        if type(name) == "string" then
          room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
          local card = Fk:cloneCard(name)
          if card then
            card:onUninstall(room, player)
          end
        end
      end
      for _, name in ipairs(names) do
        local card = Fk:cloneCard(name)
        if card then
          room:setPlayerMark(player, "@os__huangzhu_" .. Util.convertSubtypeAndEquipSlot(card.sub_type), name)
          card:onInstall(room, player)
        end
      end
    end
  end,
})

osHuangzhu:addEffect(fk.AreaResumed, {
  can_refresh = function(self, event, target, player)
    return player:hasSkill(osHuangzhu.name) and player == target
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    for _, slot in ipairs(target.data.slots) do
      local name = player:getMark("@os__huangzhu_" .. slot)
      if type(name) == "string" then
        room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
        local card = Fk:cloneCard(name)
        if card then
          card:onUninstall(room, player)
        end
      end
    end
  end,
})

osHuangzhu:addEffect("on_lose", {
  on_lose = function(self, player)
    local room = player.room
    room:setPlayerMark(player, "@$os__huangzhu", 0)
    local all_slots = {
      "WeaponSlot",
      "ArmorSlot",
      "DefensiveRideSlot",
      "OffensiveRideSlot",
      "TreasureSlot"
    }
    for _, slot in ipairs(all_slots) do
      local name = player:getMark("@os__huangzhu_" .. slot)
      if type(name) == "string" then
        room:setPlayerMark(player, "@os__huangzhu_" .. slot, 0)
        local card = Fk:cloneCard(name)
        if card then
          card:onUninstall(room, player)
        end
      end
    end
  end,
})

return osHuangzhu

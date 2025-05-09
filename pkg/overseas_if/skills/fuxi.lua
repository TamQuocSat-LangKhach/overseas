local fuxi = fk.CreateSkill {
  name = "os__fuxi",
  tags = { Skill.Permanent },
}

Fk:loadTranslationTable{
  ["os__fuxi"] = "赴曦",
  [":os__fuxi"] = "持恒技，当你进入濒死状态时，或你的装备栏均被废除后，你可以选择一至两项，然后<a href='os_ruhuan_caoang'>“入幻”</a>"..
  "并将体力回复至体力上限：<br>1.获得一个额外回合；<br>2.此次“入幻”时保留〖炽灰〗；<br>3.将手牌摸至X张（X为你的体力上限且至多为5）；<br>"..
  "4.恢复所有装备栏（你的装备栏均被废除时方可选择此项）。",

  ["os_ruhuan_caoang"] = "变身为幻形态：<br>" ..
  "<b>煌烛</b>：准备阶段，你可以选择一个已被废除的装备栏，从牌堆或弃牌堆中随机获得一张对应副类别的装备牌"..
  "（若无则随机获得一张装备牌），并记录此牌牌名。"..
  "出牌阶段开始时，你可以选择或变更至多两个已记录且对应装备栏已被废除的装备牌牌名（每种副类别限一个），"..
  "视为拥有这些装备牌的技能直到此装备栏被恢复。<br>"..
  "<b>离渊</b>：你可以将一张对应装备栏已被废除的装备牌当普【杀】使用或打出（无距离、次数限制，不计次数）。"..
  "当你以此法使用或打出牌时，你摸一张牌。<br>"..
  "<b>冀筏</b>：锁定技，当你进入濒死状态时，你减X点体力上限（X为你上次发动〖赴曦〗时选择的项数），"..
  "选择此次“退幻”时保留〖煌烛〗或〖离渊〗，然后<a href='os_tuihuan_caoang'>“退幻”</a>并将体力回复至体力上限。",

  ["#os__fuxi-choice"] = "赴曦：你可以执行至多两项，然后“入幻”",
  ["os__fuxi1"] = "获得额外回合",
  ["os__fuxi2"] = "入幻时保留〖炽灰〗",
  ["os__fuxi3"] = "将手牌摸至%arg张",
  ["os__fuxi4"] = "恢复所有装备栏",

  ["$os__fuxi1"] = "身为残叶之灰，此心亦向光明。",
  ["$os__fuxi2"] = "煌煌昔日，吾可复见之。",
}

local spec = {
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local x = math.min(player.maxHp, 5)
    local all_choices = {
      "os__fuxi1",
      "os__fuxi2",
      "os__fuxi3:::" .. tostring(x),
      "os__fuxi4",
    }
    local choices = {"os__fuxi2"}
    if room.logic:getCurrentEvent():findParent(GameEvent.Turn, true) then
      table.insert(choices, all_choices[1])
    end
    if player:getHandcardNum() < x then
      table.insert(choices, all_choices[3])
    end
    if #player:getAvailableEquipSlots() == 0 then
      table.insert(choices, all_choices[4])
    end
    choices = room:askToChoices(player, {
      choices = choices,
      min_num = 1,
      max_num = 2,
      skill_name = fuxi.name,
      prompt = "#os__fuxi-choice",
      all_choices = all_choices,
      cancelable = true,
    })
    if #choices > 0 then
      event:setCostData(self, {choice = choices})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = event:getCostData(self).choice
    if table.contains(choices, "os__fuxi1") then
      player:gainAnExtraTurn()
    end
    if table.find(choices, function (choice)
      return choice:startsWith("os__fuxi3")
    end) then
      local x = math.min(5, player.maxHp) - player:getHandcardNum()
      if x > 0 then
        room:drawCards(player,x, fuxi.name)
        if player.dead then return end
      end
    end
    if table.contains(choices, "os__fuxi4") then
      local slots = table.simpleClone(player.sealedSlots)
      table.removeOne(slots, Player.JudgeSlot)
      local x = #slots
      if x > 0 then
        room:resumePlayerArea(player, slots)
        if player.dead then return end
      end
    end

    local x = player.maxHp - player.hp
    if x > 0 then
      room:recover{
        who = player,
        num = x,
        recoverBy = player,
        skillName = fuxi.name,
      }
      if player.dead then return end
    end

    room:setPlayerMark(player, fuxi.name, #choices)

    local skills = table.contains(choices, "os__fuxi2") and "" or "-os__chihui|"
    room:handleAddLoseSkills(player, skills .. "-os__fuxi|os__huangzhu|os__liyuan|os__jifa", nil, true, false)
    if player.general == "os_if__caoang" then
      room:setPlayerProperty(player, "general", "os_if_huan__caoang")
    end
    if player.deputyGeneral == "os_if__caoang" then
      room:setPlayerProperty(player, "deputyGeneral", "os_if_huan__caoang")
    end
  end,
}

fuxi:addEffect(fk.EnterDying, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuxi.name)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

fuxi:addEffect(fk.AreaAborted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuxi.name) and
      #player:getAvailableEquipSlots() == 0 and
      table.find(data.slots, function (slot)
        return slot ~= Player.JudgeSlot
      end)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return fuxi

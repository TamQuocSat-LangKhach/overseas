local osFuxi = fk.CreateSkill {
  name = "os__fuxi"
}

Fk:loadTranslationTable{
  ['os__fuxi'] = '赴曦',
  ['os__fuxi1'] = '获得额外回合',
  ['os__fuxi2'] = '保留〖炽灰〗',
  ['os__fuxi3'] = '将手牌摸至%arg张',
  ['os__fuxi4'] = '恢复所有装备栏',
  ['#os__fuxi-choice'] = '是否发动 赴曦，选择1-2项依序执行，然后“入幻”',
  ['os_if__caoang'] = '幻曹昂',
  ['os_if_huan__caoang'] = '幻曹昂',
  [':os__fuxi'] = '持恒技，当你进入濒死状态时，或你的装备栏均被废除后，你可以选择一至两项并<a href=>“入幻”</a>并将体力回复至体力上限：1.获得一个额外回合；2.此次“入幻”时保留〖炽灰〗；3.将手牌摸至X张（X为你的体力上限且至多为5）；4.恢复所有装备栏（你的装备栏均被废除时方可选择此项）。',
  ['$os__fuxi1'] = '身为残叶之灰，此心亦向光明。',
  ['$os__fuxi2'] = '煌煌昔日，吾可复见之。',
}

osFuxi:addEffect({fk.EnterDying, fk.AreaAborted}, {
  can_trigger = function(self, event, target, player)
    if target ~= player or not player:hasSkill(osFuxi.name) then return false end
    if event == fk.EnterDying then
      return player.dying
    elseif event == fk.AreaAborted then
      return (#data.slots > 0 or data.slots[1] ~= Player.JudgeSlot) and #player:getAvailableEquipSlots() == 0
    end
  end,
  on_cost = function (self, event, target, player)
    local room = player.room
    local x = math.min(player.maxHp, 5)
    local all_choices = {
      "os__fuxi1",
      "os__fuxi2",
      "os__fuxi3:::" .. tostring(x),
      "os__fuxi4"
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
      skill_name = osFuxi.name,
      prompt = "#os__fuxi-choice",
      detailed = false,
      all_choices = all_choices
    })
    if #choices > 0 then
      event:setCostData(self, choices)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choices = event:getCostData(self)
    if table.contains(choices, "os__fuxi1") then
      player:gainAnExtraTurn()
    end
    if table.find(
      choices,
      function (choice) return choice:startsWith("os__fuxi3")
      end) then
      local x = math.min(5, player.maxHp) - player:getHandcardNum()
      if x > 0 then
        room:drawCards(player,x, osFuxi.name)
        if player.dead then return false end
      end
    end
    if table.contains(choices, "os__fuxi4") then
      local slots = table.simpleClone(player.sealedSlots)
      table.removeOne(slots, Player.JudgeSlot)
      local x = #slots
      if x > 0 then
        room:resumePlayerArea(player, slots)
        if player.dead then return false end
      end
    end

    local x = player.maxHp - player.hp
    if x > 0 then
      room:recover({
        who = player,
        num = x,
        recoverBy = player,
        skillName = osFuxi.name,
      })
      if player.dead then return false end
    end

    room:setPlayerMark(player, osFuxi.name, #choices)

    local skills = table.contains(choices, "os__fuxi2") and "" or "-os__chihui|"
    room:handleAddLoseSkills(player, skills .. "-os__fuxi|os__huangzhu|os__liyuan|os__jifa", nil, true, false)
    if player.general == "os_if__caoang" then
      room:setPlayerProperty(player, "general", "os_if_huan__caoang")
    end
    if player.deputyGeneral == "os_if__caoang" then
      room:setPlayerProperty(player, "deputyGeneral", "os_if_huan__caoang")
    end

  end,
})

return osFuxi

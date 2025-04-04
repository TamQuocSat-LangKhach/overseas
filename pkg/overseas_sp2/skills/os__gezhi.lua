local os__gezhi = fk.CreateSkill {
  name = "os__gezhi"
}

Fk:loadTranslationTable{
  ['os__gezhi'] = '革制',
  ['os__fengqix'] = '烽起',
  ['#os__gezhi-ask'] = '革制：你可重铸一张手牌',
  ['#os__gezhi-target'] = '你可选择一名角色，对其发动“革制”',
  ['os__gezhi_ar'] = '攻击范围+2',
  ['os__gezhi_maxcard'] = '手牌上限+2',
  ['os__gezhi_maxhp'] = '体力上限+1',
  ['os__gezhi_lordskill'] = '获得你武将牌上的主公技',
  ['@@os__gezhi_ar'] = '革制攻击范围+2',
  [':os__gezhi'] = '①当你于你的出牌阶段使用牌时，若为你此阶段首次使用此类型的牌，你可重铸一张手牌。②出牌阶段结束时，若本阶段你以此法重铸了至少两张牌，你可令一名角色选择一项：1. 攻击范围+2；2. 手牌上限+2；3. 体力上限+1。（每名角色每项限一次）',
  ['$os__gezhi1'] = '改革旧制，保我汉室长存！',
  ['$os__gezhi2'] = '革除旧弊，方乃中兴！',
}

os__gezhi:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) or player.phase ~= Player.Play then return false end
    local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e) 
      local use = e.data[1]
      return use.from == player.id and use.card.type == data.card.type
    end, Player.HistoryTurn)
    return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
  end,
  on_cost = function(self, event, target, player, data)
    local id = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = skill.name,
      cancelable = true,
      prompt = "#os__gezhi-ask",
    })
    if #id > 0 then
      event:setCostData(skill, id[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recastCard(event:getCostData(skill), player, skill.name)
  end,
})

os__gezhi:addEffect(fk.EventPhaseEnd, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(skill.name) or player.phase ~= Player.Play then return false end
    if player:usedSkillTimes(skill.name, Player.HistoryPhase) < 2 then return false end
    for _, p in ipairs(player.room.alive_players) do
      local num = 3
      if player:hasSkill("os__fengqix") then
        for _, skill_name in ipairs(Fk.generals[p.general]:getSkillNameList(true)) do
          if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
            num = 4
            break
          end
        end
        if target.deputyGeneral and target.deputyGeneral ~= "" then
          for _, skill_name in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(true)) do
            if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
              num = 4
              break
            end
          end
        end
      end
      return #p:getMark("_os__gezhi") < num
    end
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = {}
    for _, p in ipairs(player.room.alive_players) do
      if p:getMark("_os__gezhi") == 0 then
        table.insert(availableTargets, p.id)
      elseif #p:getMark("_os__gezhi") < 3 then
        table.insert(availableTargets, p.id)
      elseif #p:getMark("_os__gezhi") == 3 then
        if player:hasSkill("os__fengqix") then
          for _, skill_name in ipairs(Fk.generals[p.general]:getSkillNameList(true)) do
            if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
              table.insert(availableTargets, p.id)
              break
            end
          end
          if target.deputyGeneral and target.deputyGeneral ~= "" then
            for _, skill_name in ipairs(Fk.generals[p.deputyGeneral]:getSkillNameList(true)) do
              if Fk.skills[skill_name].lordSkill and not p:hasSkill(skill_name) then
                table.insertIfNeed(availableTargets, p.id)
                break
              end
            end
          end
        end
      end
    end
    if #availableTargets == 0 then return false end
    local target = player.room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__gezhi-target",
      skill_name = skill.name,
      cancelable = true,
    })
    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targetPlayer = room:getPlayerById(event:getCostData(skill))
    local allChoices = {"os__gezhi_ar", "os__gezhi_maxcard", "os__gezhi_maxhp"}
    if player:hasSkill("os__fengqix") then
      for _, skill_name in ipairs(Fk.generals[targetPlayer.general]:getSkillNameList(true)) do
        if Fk.skills[skill_name].lordSkill and not targetPlayer:hasSkill(skill_name) then
          table.insert(allChoices, "os__gezhi_lordskill")
          break
        end
      end
      if target.deputyGeneral and target.deputyGeneral ~= "" then
        for _, skill_name in ipairs(Fk.generals[target.deputyGeneral]:getSkillNameList(true)) do
          if Fk.skills[skill_name].lordSkill and not targetPlayer:hasSkill(skill_name) then
            table.insertIfNeed(allChoices, "os__gezhi_lordskill")
            break
          end
        end
      end
    end
    local choices = {}
    if targetPlayer:getMark("_os__gezhi") ~= 0 then
      for i = 1, #allChoices do
        if not table.contains(targetPlayer:getMark("_os__gezhi"), i) then
          table.insert(choices, allChoices[i])
        end
      end
    else
      choices = allChoices
    end
    local record = targetPlayer:getTableMark("_os__gezhi")
    local choice = room:askToChoice(targetPlayer, {
      choices = choices,
      skill_name = skill.name,
    })
    if choice == "os__gezhi_lordskill" then
      local skills = {}
      for _, skill_name in ipairs(Fk.generals[targetPlayer.general]:getSkillNameList(true)) do
        if Fk.skills[skill_name].lordSkill and not targetPlayer:hasSkill(skill_name) then
          table.insertIfNeed(skills, skill_name)
        end
      end
      if target.deputyGeneral and target.deputyGeneral ~= "" then
        for _, skill_name in ipairs(Fk.generals[target.deputyGeneral]:getSkillNameList(true)) do
          if Fk.skills[skill_name].lordSkill and not targetPlayer:hasSkill(skill_name) then
            table.insertIfNeed(skills, skill_name)
          end
        end
      end
      if #skills > 0 then
        room:handleAddLoseSkills(targetPlayer, table.concat(skills, "|"), nil, true, false)
      end
      table.insert(record, 4)
    elseif choice == "os__gezhi_ar" then
      room:addPlayerMark(targetPlayer, "@@os__gezhi_ar")
      table.insert(record, 1)
    elseif choice == "os__gezhi_maxcard" then
      room:addPlayerMark(targetPlayer, MarkEnum.AddMaxCards, 2)
      table.insert(record, 2)
    else
      room:changeMaxHp(targetPlayer, 1)
      table.insert(record, 3)
    end
    room:setPlayerMark(targetPlayer, "_os__gezhi", record)
  end,
})

local os__gezhi_ar = fk.CreateAttackRangeSkill{
  name = "#os__gezhi_ar",
  correct_func = function(self, from, to)
    return (from:getMark("@@os__gezhi_ar") ~= 0) and from:getMark("@@os__gezhi_ar") * 2 or 0
  end,
}

return os__gezhi

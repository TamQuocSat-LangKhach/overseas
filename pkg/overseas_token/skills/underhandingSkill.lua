local underhandingSkill = fk.CreateSkill {
  name = "underhanding_skill"
}

Fk:loadTranslationTable{
  ['underhanding_skill'] = '瞒天过海',
  ['#underhanding_skill'] = '选择一至两名区域内有牌的其他角色，依次获得其区域内的一张牌，然后依次交给其一张牌',
  ['#underhanding-card'] = '瞒天过海：交给 %dest 一张牌',
}

underhandingSkill:addEffect('active', {
  prompt = "#underhanding_skill",
  can_use = Util.CanUse,
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
  end,
  target_filter = Util.TargetFilter,
  on_effect = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local to = room:getPlayerById(effect.to)
    if not to:isAllNude() then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "hej",
        skill_name = underhandingSkill.name
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player.id, underhandingSkill.name)
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data[1]
        use.extra_data = use.extra_data or {}
        use.extra_data.underhanding_targets = use.extra_data.underhanding_targets or {}
        table.insertIfNeed(use.extra_data.underhanding_targets, to.id)
      end
    end
  end,
  on_action = function (self, room, use, finished)
    if not finished then return end
    local player = room:getPlayerById(use.from)
    if player.dead or player:isNude() then return end
    local targets = (use.extra_data or {}).underhanding_targets or {}
    if #targets == 0 then return end
    room:sortPlayersByAction(targets)
    for _, pid in ipairs(targets) do
      local target = room:getPlayerById(pid)
      if not player:isNude() and not target.dead and not player.dead then
        local c = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = underhandingSkill.name,
          prompt = "#underhanding-card::" .. pid
        })[1]
        room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, underhandingSkill.name, nil, false, player.id)
      end
    end
  end
})

return underhandingSkill

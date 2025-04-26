local underhandingSkill = fk.CreateSkill {
  name = "underhanding_skill"
}

Fk:loadTranslationTable{
  ["underhanding_skill"] = "瞒天过海",
  ["underhanding_action"] = "瞒天过海",
  ["#underhanding-card"] = "瞒天过海：交给 %dest 一张牌",
  [":underhanding_skill"] = "选择一至两名区域内有牌的其他角色，依次获得其区域内的一张牌，然后依次交给其一张牌",
}

underhandingSkill:addEffect('cardskill', {
  min_target_num = 1,
  max_target_num = 2,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player and not to_select:isAllNude()
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, effect)
    local player = effect.from
    local to = effect.to
    if not to:isAllNude() then
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "hej",
        skill_name = underhandingSkill.name
      })
      room:obtainCard(player, id, false, fk.ReasonPrey, player.id, underhandingSkill.name)
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      if e then
        local use = e.data
        use.extra_data = use.extra_data or {}
        use.extra_data.underhanding_targets = use.extra_data.underhanding_targets or {}
        table.insertIfNeed(use.extra_data.underhanding_targets, to.id)
      end
    end
  end,
  on_action = function (self, room, use, finished)
    if not finished then return end
    local player = use.from
    if player.dead or player:isNude() then return end
    local targets = (use.extra_data or {}).underhanding_targets or {}
    if #targets == 0 then return end
    targets = table.map(targets, Util.Id2PlayerMapper)
    room:sortByAction(targets)
    for _, target in ipairs(targets) do
      if not player:isNude() and not target.dead and not player.dead then
        local c = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = underhandingSkill.name,
          prompt = "#underhanding-card::" .. target.id
        })[1]
        room:moveCardTo(c, Player.Hand, target, fk.ReasonGive, underhandingSkill.name, nil, false, player.id)
      end
    end
  end
})

underhandingSkill:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card and card.name == "underhanding"
  end,
})

return underhandingSkill

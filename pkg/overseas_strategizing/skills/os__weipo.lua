local os__weipo = fk.CreateSkill {
  name = "os__weipo"
}

Fk:loadTranslationTable{
  ['os__weipo'] = '危迫',
  [':os__weipo'] = '出牌阶段限一次，你可令一名角色弃置一张牌，然后令其获得一张<a href=>【兵临城下】</a>或由你指定的一种<a href=>智囊</a>。',
  ['$os__weipo1'] = '想必……将军心中已有所计较。',
  ['$os__weipo2'] = '谌言尽于此，采纳与否还凭将军。',
}

os__weipo:addEffect('active', {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(os__weipo.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  target_num = 1,
  interaction = UI.ComboBox{choices = {"enemy_at_the_gates", "dismantlement", "nullification", "ex_nihilo"}},
  on_use = function(self, room, effect)
    local choice = skill.interaction.data
    if not choice then choice = "enemy_at_the_gates" end
    local target = room:getPlayerById(effect.tos[1])
    room:askToDiscard(target, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__weipo.name,
      cancelable = false
    })
    local id
    if choice == "enemy_at_the_gates" then
      local weipo_derivecards = { {"enemy_at_the_gates", Card.Spade, 7}, {"enemy_at_the_gates", Card.Club, 7},
        {"enemy_at_the_gates", Card.Club, 13} }
      local cids = U.prepareDeriveCards(room, weipo_derivecards, "os__weipo_derivecards")
      for _, cid in ipairs(cids) do
        if room:getCardArea(cid) == Card.Void then
          id = cid
          break
        end
      end
      if not id then
        for _, cid in ipairs(cids) do
          if room:getCardArea(cid) == Card.DrawPile then
            id = cid
            break
          end
        end
      end
    else
      for _, cid in ipairs(Fk:getAllCardIds()) do --在这里
        if Fk:getCardById(cid).name == choice and room:getCardArea(cid) == Card.Void then --优先拿游戏外的
          id = cid
          break
        end
      end
      if not id then
        local cids = room:getCardsFromPileByRule(choice, 1) --？
        if #cids > 0 then id = cids[1] end
      end
    end
    if id then
      room:obtainCard(target, id, false, fk.ReasonPrey, effect.from, os__weipo.name, choice == "enemy_at_the_gates" and MarkEnum.DestructIntoDiscard or nil )
    end
  end,
})

return os__weipo

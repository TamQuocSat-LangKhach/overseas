local guihan = fk.CreateSkill {
  name = "os__guihanh",
}

Fk:loadTranslationTable{
  ["os__guihanh"] = "归汉",
  [":os__guihanh"] = "出牌阶段限一次，你可以选择至多三名有手牌的其他角色，然后展示牌堆顶牌，这些角色依次选择一项：1.将一张同类别牌置于牌堆顶；"..
  "2.失去1点体力。然后你选择一项：1.摸X张牌；2.获得牌堆第X+1张开始的两张牌。（X为以此法置于牌堆顶的牌数）",

  ["#os__guihanh"] = "归汉：选择至多三名角色，这些角色选择将一张牌置于牌堆顶或失去1点体力",
  ["#os__guihanh-ask"] = "归汉：将一张%arg置于牌堆顶，或点“取消”失去1点体力",
  ["os__guihanh1"] = "摸%arg张牌",
  ["os__guihanh2"] = "获得牌堆第%arg张开始的两张牌",

  ["$os__guihanh1"] = "天下分合，终不改汉祚之名！",
  ["$os__guihanh2"] = "平安南北，终携百姓致太平！",
}

guihan:addEffect("active", {
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 3,
  prompt = "#os__guihanh",
  can_use = function(self, player)
    return player:usedSkillTimes(guihan.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (skill, player, to_select, selected, selected_cards)
    return #selected < 3 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local c = room:getNCards(1)
    local type = Fk:getCardById(c[1]):getTypeString()
    room:turnOverCardsFromDrawPile(player, c, guihan.name, true)
    room:sortByAction(effect.tos)
    local n = 0
    for _, target in ipairs(effect.tos) do
      if not target.dead then
        local card = room:askToCards(target, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = guihan.name,
          cancelable = true,
          pattern = ".|.|.|.|.|" .. type,
          prompt = "#os__guihanh-ask:::" .. type,
        })
        if #card > 0 then
          n = n + 1
          room:moveCards({
            ids = card,
            from = target,
            toArea = Card.DrawPile,
            moveReason = fk.ReasonPut,
            skillName = guihan.name,
            moveVisible = true,
            drawPilePosition = 1,
          })
        else
          room:loseHp(target, 1, guihan.name)
        end
      end
    end
    room:cleanProcessingArea(c)
    if player.dead then return end
    local choices = {"os__guihanh2:::"..(n + 1)}
    if n > 0 then
      table.insert(choices, 1, "os__guihanh1:::" .. n)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = guihan.name,
    })
    if choice:startsWith("os__guihanh1") then
      player:drawCards(n, guihan.name)
    else
      local ids = {}
      if #room.draw_pile > n then
        table.insert(ids, room.draw_pile[n + 1])
      end
      if #room.draw_pile > n + 1 then
        table.insert(ids, room.draw_pile[n + 2])
      end
      if #ids == 0 then return end
      room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonJustMove, guihan.name, nil, false, player)
    end
  end,
})

return guihan

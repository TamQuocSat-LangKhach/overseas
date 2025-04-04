local osHuanji = fk.CreateSkill {
  name = "os__huanji"
}

Fk:loadTranslationTable{
  ['os__huanji'] = '幻计',
  ['#os__huanji-active'] = '幻计：你可减1点体力上限为〖北定〗增加体力值数量的牌名记录',
  ['@$os__beiding_names'] = '北定',
  ['#os__beiding-choose'] = '北定：请选择至多%arg种牌名记录，你于此回合弃牌阶段结束时按顺序依次使用',
  ['@@os__beiding_card-inhand'] = '北定',
  [':os__huanji'] = '出牌阶段限一次，你可以减1点体力上限，在〖北定〗记录中增加X种牌名（X为你的体力值）。',
  ['$os__huanji1'] = '以计中之计，调雍凉戴甲，天下备鞍！',
  ['$os__huanji2'] = '借计代兵，以一隅抗九州！',
}

osHuanji:addEffect('active', {
  name = "os__huanji",
  prompt = "#os__huanji-active",
  anim_type = "support",
  target_num = 0,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(osHuanji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:changeMaxHp(from, -1)
    if not from:isAlive() or from.hp < 1 then
      return
    end

    local cardNames = U.getAllCardNames("bt")
    cardNames = table.filter(
      cardNames,
      function(name) return not table.contains(from:getTableMark("@$os__beiding_names"), name) end
    )

    if #cardNames == 0 then
      return false
    end
    cardNames = table.filter(cardNames, function(name) return #name:split("__") == 1 end)

    local namesChosen = room:askToChoices(from, {
      choices = cardNames,
      min_num = from.hp,
      max_num = from.hp,
      skill_name = osHuanji.name,
      prompt = "#os__beiding-choose:::" .. from.hp
    })
    local beidingNames = from:getTableMark("@$os__beiding_names")
    table.insertTable(beidingNames, namesChosen)
    room:setPlayerMark(from, "@$os__beiding_names", beidingNames)

    for _, id in ipairs(from:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if table.contains(beidingNames, card.trueName) and card:getMark("@@os__beiding_card-inhand") ~= 1 then
        room:setCardMark(card, "@@os__beiding_card-inhand", 1)
      end
    end
  end,
})

return osHuanji

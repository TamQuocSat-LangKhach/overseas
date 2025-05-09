local huanji = fk.CreateSkill {
  name = "os__huanji"
}

Fk:loadTranslationTable{
  ["os__huanji"] = "幻计",
  [":os__huanji"] = "出牌阶段限一次，你可以减1点体力上限，在〖北定〗记录中增加X种牌名（X为你的体力值）。",

  ["#os__huanji"] = "幻计：减1点体力上限，为“北定”增加体力值数量的牌名记录",
  ["#os__huanji-choice"] = "幻计：为“北定”%arg个牌名记录",

  ["$os__huanji1"] = "以计中之计，调雍凉戴甲，天下备鞍！",
  ["$os__huanji2"] = "借计代兵，以一隅抗九州！",
}

local U = require "packages/utility/utility"

huanji:addEffect("active", {
  anim_type = "support",
  prompt = "#os__huanji",
  target_num = 0,
  card_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(huanji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:changeMaxHp(player, -1)
    if player.dead or player.hp < 1 then return end

    local all_choices = Fk:getAllCardNames("bt", true)
    local choices = table.filter(all_choices, function (name)
      return not table.contains(player:getTableMark("@$os__beiding_names"), name)
    end)
    if #choices == 0 then return end
    local n = math.min(player.hp, #choices)
    choices = U.askForChooseCardNames(room, player, choices, n, n, huanji.name,
      "#os__huanji-choice:::"..n, all_choices, false)

    local record = player:getTableMark("@$os__beiding_names")
    table.insertTable(record, choices)
    room:setPlayerMark(player, "@$os__beiding_names", record)

    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if table.contains(record, card.trueName) then
        room:setCardMark(card, "@@os__beiding_card-inhand", 1)
      end
    end
  end,
})

return huanji

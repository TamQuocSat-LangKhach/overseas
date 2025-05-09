local beiding = fk.CreateSkill {
  name = "os__beiding",
}

Fk:loadTranslationTable{
  ["os__beiding"] = "北定",
  [":os__beiding"] = "一名角色的准备阶段，你可以声明并记录至多X种未被〖北定〗记录过的基本牌或普通锦囊牌牌名。" ..
  "若如此做，此回合的弃牌阶段结束时，你视为依次使用本回合记录的牌（无距离限制），若此牌的目标不包含当前回合角色，" ..
  "其摸一张牌（X为你的体力值）。",

  ["@$os__beiding_names"] = "北定",
  ["#os__beiding-choice"] = "北定：请选择至多%arg种牌名记录，你于此回合弃牌阶段结束时按顺序依次使用",
  ["#os__beiding-use"] = "北定：请视为使用【%arg】",

  ["$os__beiding1"] = "众将同心扶汉，北伐或可功成。",
  ["$os__beiding2"] = "虽失天时地利，亦有三分胜机！",

  -- 牌特殊语音
  ["$os__beiding_names1"] = "卧龙吐息之间，贼众灰飞烟灭！", -- 火攻
  ["$os__beiding_names2"] = "地火喑喑，焚将百万鱼龙！", -- 火杀
  ["$os__beiding_names3"] = "君臣将帅同心，敌必无可乘之机！", -- 无懈
}

local U = require "packages/utility/utility"

beiding:addEffect(fk.EventPhaseStart, {
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Start and player:hasSkill(beiding.name) and player.hp > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local all_choices = Fk:getAllCardNames("bt")
    local choices = table.filter(all_choices, function (name)
      return not table.contains(player:getTableMark("@$os__beiding_names"), Fk:cloneCard(name).trueName)
    end)
    if #choices == 0 then return end
    local n = math.min(player.hp, #choices)
    choices = U.askForChooseCardNames(room, player, choices, n, n, beiding.name,
      "#os__beiding-choice:::"..n, all_choices, true)
    if #choices > 0 then
      event:setCostData(self, {choices = choices})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice

    local record = player:getTableMark("os__beiding_names-turn")
    table.insertTable(record, choice)
    room:setPlayerMark(player, "os__beiding_names-turn", record)

    choice = table.map(choice, function (name)
      return Fk:cloneCard(name).trueName
    end)
    local beidingNames = player:getTableMark("@$os__beiding_names")
    table.insertTable(beidingNames, choice)
    room:setPlayerMark(player, "@$os__beiding_names", beidingNames)

    if player:hasSkill("os_huan__beiding", true) then
      for _, id in ipairs(player:getCardIds("h")) do
        local card = Fk:getCardById(id)
        if table.contains(beidingNames, card.trueName) then
          room:setCardMark(card, "@@os__beiding_card-inhand", 1)
        end
      end
    end
  end
})

beiding:addEffect(fk.EventPhaseEnd, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target.phase == Player.Discard and player:getMark("os__beiding_names-turn") ~= 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local all_names = table.simpleClone(player:getTableMark("os__beiding_names-turn"))
    for _, name in ipairs(all_names) do
      if player.dead then return end

      -- 牌名彩蛋
      local names = {"fire_attack", "fire__slash", "nullification"}
      if table.contains(names, name) then
        player:broadcastSkillInvoke("os__beiding_names", table.indexOf(names, name))
      end

      local use = room:askToUseVirtualCard(player, {
        name = name,
        skill_name = beiding.name,
        prompt = "#os__beiding-invoke:::" .. name,
        cancelable = false,
        extra_data = {
          bypass_distances = true,
          bypass_times = true,
          extraUse = true,
        },
      })
      if use and not table.contains(use.tos, target) and not target.dead then
        target:drawCards(1, beiding.name)
      end
    end
  end
})

return beiding

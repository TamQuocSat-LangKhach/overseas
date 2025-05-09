local shiyi = fk.CreateSkill {
  name = "os__shiyih",
}

Fk:loadTranslationTable{
  ["os__shiyih"] = "拾忆",
  [":os__shiyih"] = "出牌阶段限一次，你可以与一名其他角色互相观看手牌，各展示自己的一张手牌，" ..
  "然后从牌堆或弃牌堆中获得一张与此牌类型相同的牌。若你与其展示的牌：类型相同，你与其摸两张牌；" ..
  "类型不同，你与其从牌堆或弃牌堆中获得一张与展示的牌类型相同的牌。",

  ["#os__shiyih"] = "拾忆：你可与一名其他角色互相观看手牌，然后各展示自己的一张手牌",
  ["#os__shiyih-view"] = "拾忆：观看%dest的手牌，展示自己的一张手牌",
  ["#os__shiyih-ask"] = "拾忆：展示一张手牌",

  ["$os__shiyih1"] = "淯水涛声，亦如当年。",
  ["$os__shiyih2"] = "断玨凭引，溯念前尘。",
}

Fk:addPoxiMethod{
  name = "os__shiyih",
  prompt = function (data, extra_data)
    return extra_data.prompt
  end,
  card_filter = function (to_select, selected, data, extra_data)
    if data and #selected == 0 then
      return table.contains(data[2][2], to_select)
    end
  end,
  feasible = function(selected, data)
    return data and #selected == 1
  end,
  default_choice = function(data)
    if not data then return {} end
    local cids = table.random(data[2][2], 1)
    return cids
  end,
}

local function shiyiObtain(room, players, ret, from, skillName)
  local cards
  for _, p in ipairs(players) do
    if not p.dead then
      cards = room:getCardsFromPileByRule(".|.|.|.|.|" .. Fk:getCardById(ret[p.id][1]):getTypeString(), 1, "allPiles")
      if #cards > 0 then room:obtainCard(p, cards, false, fk.ReasonPrey, from, skillName) end
    end
  end
end

local function shiyiPoxiData(p, player, target, skillName)
  local other = p == player and target or player
  local ret = {
    other,
    { {Fk:translate(other.general) + (other.deputyGeneral ~= "" and ("/" .. Fk:translate(other.deputyGeneral)) or ""), other:getCardIds("h")},
      {Fk:translate(p.general) + (p.deputyGeneral ~= "" and ("/" .. Fk:translate(p.deputyGeneral)) or ""), p:getCardIds("h")} -- TODO: 规范化
    }, -- card_data
    {
      to = other.id,
      skillName = skillName,
      prompt = "#os__shiyih-view::" .. other.id,
    } -- extra_data
  }
  return ret
end

shiyi:addEffect("active", {
  anim_type = "support",
  prompt = "#os__shiyih",
  card_num = 0,
  target_num = 1,
  can_use = function (self, player)
    return player:usedSkillTimes(shiyi.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = Util.FalseFunc,
  target_filter = function (self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function (self, room, effect)
    local player = effect.from
    local target = effect.tos[1]

    local targets = {player, target}
    local poxi = Fk.poxi_methods[shiyi.name]
    local command = "AskForPoxi"
    local req = Request:new(targets, command)
    req.focus_text = shiyi.name

    local other, card_data, extra_data
    for _, p in ipairs(targets) do
      other, card_data, extra_data = table.unpack(shiyiPoxiData(p, player, target, shiyi.name)) -- FIXME: 注释有误

      req:setData(p, {
        type = shiyi.name,
        data = card_data,
        extra_data = extra_data,
        cancelable = false
      })

      local log = {
        type = "#WatchCard",
        from = p.id,
        card = other:getCardIds("h"),
      }
      p:doNotify("GameLog", json.encode(log))
    end
    req:ask()
    local ret = {}
    for _, p in ipairs(targets) do
      local result = req:getResult(p)

      _, card_data, extra_data = table.unpack(shiyiPoxiData(p, player, target, shiyi.name))

      if result == "" then
        ret[p.id] = poxi.default_choice(card_data, extra_data)
      else
        ret[p.id] = poxi.post_select(result, card_data, extra_data)
      end
    end

    player:showCards(ret[player.id])
    if not target.dead then
      target:showCards(ret[target.id])
    end
    shiyiObtain(room, targets, ret, player, shiyi.name)
    if Fk:getCardById(ret[target.id][1]).type == Fk:getCardById(ret[player.id][1]).type then
      for _, p in ipairs(targets) do
        if not p.dead then
          p:drawCards(2, shiyi.name)
        end
      end
    else
      shiyiObtain(room, targets, ret, player, shiyi.name)
    end
  end,
})

return shiyi

local xianyuan = fk.CreateSkill {
  name = "os__xianyuan",
}

Fk:loadTranslationTable{
  ["os__xianyuan"] = "仙援",
  [":os__xianyuan"] = "每轮开始时，你获得2枚“仙援”（一名角色至多有3枚“仙缘”）。出牌阶段，你可以将任意枚“仙援”分配给其他角色。" ..
  "有“仙援”的角色出牌阶段开始时，你选择一项：1.观看其手牌，将其中至多X张牌以任意顺序置于牌堆顶；2.其摸X张牌（X为其“仙援”数）。"..
  "若不为你，你移除其所有“仙援”。",

  ["#os__xianyuan"] = "仙援：将任意枚“仙援”标记交给其他角色",
  ["@os__xianyuan"] = "仙援",
  ["os__xianyuan_draw"] = "%dest摸%arg张牌",
  ["os__xianyuan_put"] = "观看%dest的手牌，将其中至多%arg张牌置于牌堆顶",
  ["#os__xianyuan-put"] = "仙援：观看%dest的手牌，并且可以将其中至多%arg张牌置于牌堆顶",

  ["$os__xianyuan1"] = "顺天者，天助之。",
  ["$os__xianyuan2"] = "所思所寻，皆得天应。",
}

---@param room Room
---@param player ServerPlayer
---@param target ServerPlayer
---@param num integer
local function addXianyuanMark(room, player, target, num)
  local n = target:getMark("@os__xianyuan")
  n = math.min(3, num + n)
  room:setPlayerMark(target, "@os__xianyuan", n)
  if player ~= target then
    room:addTableMarkIfNeed(player, "_os__xianyuan", target.id)
  end
end

xianyuan:addEffect("active", {
  anim_type = "support",
  prompt = "#os__xianyuan",
  target_num = 1,
  card_num = 0,
  interaction = function(self, player)
    return UI.Spin {
      from = 1,
      to = player:getMark("@os__xianyuan"),
    }
  end,
  can_use = function(self, player)
    return player:getMark("@os__xianyuan") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local num = self.interaction.data or 1
    room:removePlayerMark(player, "@os__xianyuan", num)
    addXianyuanMark(room, player, target, num)
  end,
})

xianyuan:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(xianyuan.name) and target.phase == Player.Play and target:getMark("@os__xianyuan") > 0
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = target:getMark("@os__xianyuan")
    local choices = {"os__xianyuan_draw::" .. target.id .. ":" .. x}
    if not target:isKongcheng() then
      table.insert(choices, 1, "os__xianyuan_put::" .. target.id .. ":" .. x)
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xianyuan.name,
    })
    if choice:startsWith("os__xianyuan_put") then
      local handcards = target:getCardIds("h")
      local top = room:askToArrangeCards(player, {
        skill_name = xianyuan.name,
        card_map = {handcards, "$Hand", "Top"},
        prompt = "#os__xianyuan-put::" .. target.id .. ":" .. tostring(x),
        box_size = 7,
        max_limit = {0, x},
      })[2]
      top = table.reverse(top)
      room:moveCards({
        ids = top,
        from = target,
        toArea = Card.DrawPile,
        moveReason = fk.ReasonPut,
        skillName = xianyuan.name,
        proposer = player,
        moveVisible = false,
        visiblePlayers = {player},
      })
    else
      target:drawCards(x, xianyuan.name)
    end
    if target ~= player then
      room:setPlayerMark(target, "@os__xianyuan", 0)
      for _, p in ipairs(room.alive_players) do
        room:removeTableMark(p, "_os__xianyuan", target.id)
      end
    end
  end,
})

xianyuan:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xianyuan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    addXianyuanMark(player.room, player, player, 2)
    local room = player.room
    player:broadcastSkillInvoke("os__xianyuan")
    if event == fk.RoundStart then
      room:notifySkillInvoked(player, "os__xianyuan", "support")
      addXianyuanMark(room, player, player, 2)
    else
      local x = target:getMark("@os__xianyuan")
      room:doIndicate(player.id, {target.id})
      local choices = {"os__xianyuan_draw::" .. target.id .. ":" .. x}
      if not target:isKongcheng() then
        table.insert(choices, 1, "os__xianyuan_put::" .. target.id .. ":" .. x)
      end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = xianyuan.name
      })
      if choice:startsWith("os__xianyuan_put") then
        room:notifySkillInvoked(player, "os__xianyuan", "control")
        local handcards = target:getCardIds(Player.Hand)
        local top = room:askToArrangeCards(player, {
          skill_name = "os__xianyuan",
          card_map = {handcards, "$Hand", "Top"},
          prompt = "#os__xianyuan-put::" .. target.id .. ":" .. tostring(x),
          box_size = 7,
          max_limit = {0, x},
        })[2]
        top = table.reverse(top)
        room:moveCards({
          ids = top,
          from = target.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = "os__xianyuan",
          proposer = player.id,
          moveVisible = false,
          visiblePlayers = {player.id},
        })
      else
        room:notifySkillInvoked(player, "os__xianyuan", "drawcard")
        target:drawCards(x, xianyuan.name)
      end
      if target ~= player then
        room:setPlayerMark(target, "@os__xianyuan", 0)
        for _, p in ipairs(room.alive_players) do
          room:removeTableMark(p, "_os__xianyuan", target.id)
        end
      end
    end
  end,
})

xianyuan:addLoseEffect(function (self, player, is_death)
  local room = player.room
  if player:getMark("_os__xianyuan") ~= 0 then
    for _, p in ipairs(room.alive_players) do
      if p:getMark("@os__xianyuan") > 0 and
        not table.find(room:getOtherPlayers(player, false), function (p2)
          return table.contains(p2:getTableMark("_os__xianyuan"), p.id)
        end) then
        room:setPlayerMark(p, "@os__xianyuan", 0)
      end
    end
    room:setPlayerMark(player, "_os__xianyuan", 0)
  end
end)

return xianyuan

local xianyuan = fk.CreateSkill {
  name = "os__xianyuan"
}

Fk:loadTranslationTable{
  ['os__xianyuan'] = '仙援',
  ['#os__xianyuan-active'] = '发动 仙援，令一名其他角色获得任意枚“仙援”标记',
  ['@os__xianyuan'] = '仙援',
  ['#os__xianyuan_trigger'] = '仙援',
  ['os__xianyuan_draw'] = '%dest摸%arg张牌',
  ['os__xianyuan_put'] = '观看%dest的手牌，将其中至多%arg张牌置于牌堆顶',
  ['#os__xianyuan-put'] = '仙援：观看%dest的手牌，并且可以将其中至多%arg张牌置于牌堆顶',
  [':os__xianyuan'] = '①每轮开始时，你获得2枚“仙援”。（一名角色至多有3枚“仙缘”）②出牌阶段，你可以将任意枚“仙援”分配给其他角色。③有“仙援”的角色出牌阶段开始时，你选择一项：1. 观看其手牌，将其中至多X张牌以任意顺序置于牌堆顶；2. 其摸X张牌。（X为其“仙援”数）然后若此时不是你的回合，你移除其所有“仙援”。',
  ['$os__xianyuan1'] = '顺天者，天助之。',
  ['$os__xianyuan2'] = '所思所寻，皆得天应。',
}

-- Active Skill Effect
xianyuan:addEffect('active', {
  anim_type = "support",
  prompt = "#os__xianyuan-active",
  target_num = 1,
  card_num = 0,
  can_use = function(self, player)
    return player:getMark("@os__xianyuan") ~= 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select.id ~= player.id
  end,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = Self:getMark("@os__xianyuan"),
    }
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local num = self.interaction.data or 1
    room:removePlayerMark(player, "@os__xianyuan", num)
    addXianyuanMark(room, player, target, num)
  end,
})

-- Trigger Skill Effect
xianyuan:addEffect(fk.RoundStart + fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(xianyuan) then return false end
    return event == fk.RoundStart or (target.phase == Player.Play and target:getMark("@os__xianyuan") > 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
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
  on_lose = function (self, player)
    local room = player.room
    if player:getMark("_os__xianyuan") ~= 0 then
      for _, p in ipairs(room.alive_players) do
        if p:getMark("@os__xianyuan") > 0 and not table.find(room:getOtherPlayers(player, false), function (p2)
          return table.contains(p2:getTableMark("_os__xianyuan"), p.id)
        end) then
          room:setPlayerMark(p, "@os__xianyuan", 0)
        end
      end
      room:setPlayerMark(player, "_os__xianyuan", 0)
    end
  end,
})

return xianyuan

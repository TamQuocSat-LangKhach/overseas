local osJuchen = fk.CreateSkill {
  name = "os__juchen"
}

Fk:loadTranslationTable{
  ["os__juchen"] = "聚尘",
  [":os__juchen"] = "结束阶段开始时，若你的手牌数和体力值均非全场最大，你可令所有角色弃置一张牌，然后你获得其中处于弃牌堆中的红色牌。",

  ["#os__juchen-ask"] = "聚尘：弃置一张牌，若为红色，%dest 将获得之",

  ["$os__juchen1"] = "流沙聚散，黄巾浮沉。",
  ["$os__juchen2"] = "积土为台，聚尘为砂。",
}

osJuchen:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player:hasSkill(osJuchen.name) and
      player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:getHandcardNum() > player:getHandcardNum()
      end) and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p.hp > player.hp
      end)
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osJuchen.name
    local room = player.room
    local prompt = "#os__juchen-ask::" .. player.id
    local ids = {}
    for _, p in ipairs(room:getAlivePlayers()) do --顺序
      local cids = room:askToDiscard(
        p,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
          prompt = prompt,
        }
      )

      if #cids > 0 then
        local id = cids[1]
        if Fk:getCardById(id).color == Card.Red then
          table.insert(ids, id)
        end
      end
    end
    ids = table.filter(ids, function(id)
      return room:getCardArea(id) == Card.DiscardPile
    end)
    if #ids > 0 and player:isAlive() then
      room:moveCardTo(ids, Player.Hand, player, fk.ReasonJustMove, skillName, nil, true, player)
    end
  end,
})

return osJuchen

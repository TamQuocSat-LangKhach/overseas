local os__mingren = fk.CreateSkill {
  name = "os__mingren"
}

Fk:loadTranslationTable{
  ['os__mingren'] = '明任',
  ['os__duty'] = '任',
  ['#os__mingren-exchange'] = '明任：你可用一张手牌替换“任”',
  ['#os__mingren-put'] = '明任：请将一张手牌置于武将牌上',
  [':os__mingren'] = '①游戏开始时，你摸一张牌，将一张手牌置于武将牌上，称为“任”。②出牌阶段开始或结束时，你可用一张手牌替换“任”。',
  ['$os__mingren1'] = '吾之任，君之明举！',
  ['$os__mingren2'] = '得义真所救，吾任之必尽瘁以报。',
}

os__mingren:addEffect({fk.GameStart, fk.EventPhaseStart, fk.EventPhaseEnd}, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__mingren.name) then return false end
    return (event == fk.GameStart or (target == player and player.phase == Player.Play and not player:isKongcheng() and #player:getPile("os__duty") > 0))
  end,
  on_cost = function(self, event, target, player)
    if event == fk.GameStart then
      return true
    else
      local cids = player.room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = os__mingren.name,
        cancelable = true,
        prompt = "#os__mingren-exchange"
      })
      if #cids > 0 then
        event:setCostData(self, cids[1])
        return true
      end
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.GameStart then
      player:drawCards(1, os__mingren.name)
      if not player:isKongcheng() then
        local cids = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = os__mingren.name,
          cancelable = true,
          prompt = "#os__mingren-put"
        })
        if #cids > 0 then
          player:addToPile("os__duty", cids[1], true, os__mingren.name)
        end
      end
    else
      player:addToPile("os__duty", event:getCostData(self), true, os__mingren.name)
      room:moveCardTo(player:getPile("os__duty")[1], Player.Hand, player, fk.ReasonJustMove, os__mingren.name, "os__duty")
    end
  end,
})

return os__mingren

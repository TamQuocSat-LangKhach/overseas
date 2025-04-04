local os__fengji = fk.CreateSkill {
  name = "os__fengji"
}

Fk:loadTranslationTable{
  ['os__fengji'] = '蜂集',
  ['os__revelation'] = '示',
  ['@os__fengji'] = '蜂集',
  ['#os__fengji-ask'] = '蜂集：你可将一张牌置于武将牌上，称为“示”并施法',
  ['#os__fengji-conjure'] = '蜂集：施法，第X个回合结束前，从牌堆中获得X张与“示”同名的牌，然后将“示”置入弃牌堆',
  ['#os__fengji_conjure'] = '蜂集',
  [':os__fengji'] = '出牌阶段开始时，若你没有“示”，你可将一张牌置于武将牌上，称为“示”并施法X=1~3回合：{从牌堆中获得X张与“示”同名的牌，然后将“示”置入弃牌堆。}<br/><font color=>#"<b>施法</b>"<br/>一名角色的回合结束前，施法标记-1，减至0时执行施法效果。施法期间不能重复施法同一技能。',
  ['$os__fengji1'] = '蜂趋蚁附，皆为道来。',
  ['$os__fengji2'] = '蜂攒蚁集，皆为道往！',
}

-- 主技能
os__fengji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os__fengji.name) and
      player.phase == Player.Play and not player:isNude() and #player:getPile("os__revelation") == 0 and player:getMark("@os__fengji") == 0
  end,
  on_cost = function(self, event, target, player)
    local cids = player.room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = os__fengji.name,
      cancelable = true,
      prompt = "#os__fengji-ask",
    })
    if #cids > 0 then
      event:setCostData(self, cids[1])
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local cost_data = event:getCostData(self)
    player:addToPile("os__revelation", cost_data, true, os__fengji.name)
    local num = player.room:askToChoice(player, {
      choices = {"1", "2", "3"},
      skill_name = os__fengji.name,
      prompt = "#os__fengji-conjure",
    })
    player.room:setPlayerMark(player, "@os__fengji", num .. "-" .. num)
  end,
})

-- 子技能
os__fengji:addEffect(fk.TurnEnd, {
  name = "#os__fengji_conjure",
  mute = true,
  can_trigger = function(self, event, target, player)
    return player:getMark("@os__fengji") ~= 0 and string.sub(player:getMark("@os__fengji"), -1) == "0"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengji"), "-")
    local num = tonumber(nums[1])
    if #player:getPile("os__revelation") > 0 then
      room:notifySkillInvoked(player, "os__fengji")
      player:broadcastSkillInvoke("os__fengji")
      room:obtainCard(player, room:getCardsFromPileByRule(Fk:getCardById(player:getPile("os__revelation")[1]).trueName, num), false, fk.ReasonPrey)
      room:moveCardTo(Fk:getCardById(player:getPile("os__revelation")[1]), Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, os__fengji.name, "os__revelation")
    end
    room:setPlayerMark(player, "@os__fengji", 0)
  end,
  can_refresh = function(self, event, target, player)
    return player:getMark("@os__fengji") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local nums = string.split(player:getMark("@os__fengji"), "-")
    local num = tonumber(nums[1])
    local num2 = tonumber(nums[2]) - 1
    room:setPlayerMark(player, "@os__fengji", num .. "-" .. num2)
  end,
})

return os__fengji

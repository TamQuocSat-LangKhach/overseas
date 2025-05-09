local lifengh = fk.CreateSkill {
  name = "os__lifengh",
}

Fk:loadTranslationTable{
  ["os__lifengh"] = "砺锋",
  [":os__lifengh"] = "出牌阶段，你可以弃置两张点数不同的牌，对一名距离X以内的角色造成1点伤害（X为这两张牌点数之差），其受到此伤害时，"..
  "可以重铸一张手牌（没有手牌则改为摸一张牌），若此牌点数介于这两张牌点数闭区间，防止此伤害且本回合此技能失效。",

  ["#os__lifengh"] = "砺锋：弃两张牌，对一名距离这两张牌点数之差以内的角色造成1点伤害",
  ["#os__lifengh-draw"] = "砺锋：%src 对你造成伤害，是否摸一张牌？若点数介于[%arg, %arg2]则防止伤害且其“砺锋”失效",
  ["#os__lifengh-recast"] = "砺锋：%src 对你造成伤害，是否重铸一张手牌？若点数介于[%arg, %arg2]则防止伤害且其“砺锋”失效",

  ["$os__lifengh1"] = "十载磨一剑，今日欲以贼三军拭锋！",
  ["$os__lifengh2"] = "业火炼锋，江水淬刃，方铸此师！",
}

lifengh:addEffect("active", {
  anim_type = "offensive",
  prompt = "#os__lifengh",
  card_num = 2,
  target_num = 1,
  can_use = Util.TrueFunc,
  card_filter = function (self, player, to_select, selected)
    if #selected < 2 and not player:prohibitDiscard(to_select) then
      if #selected == 0 then
        return true
      else
        return Fk:getCardById(to_select).number ~= Fk:getCardById(selected[1]).number
      end
    end
  end,
  target_filter = function (self, player, to_select, selected, selected_cards)
    if #selected_cards == 2 then
      return player:distanceTo(to_select) <=
        math.abs(Fk:getCardById(selected_cards[1]).number - Fk:getCardById(selected_cards[2]).number)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local nums = table.map(effect.cards, function (id)
      return Fk:getCardById(id).number
    end)
    room:throwCard(effect.cards, lifengh.name, player, player)
    if target.dead then return end
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = lifengh.name,
      extra_data = {
        os__lifengh = {player.id, nums},
      }
    }
  end,
})

lifengh:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.skillName == lifengh.name
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local src = room:getPlayerById(data.extra_data.os__lifengh[1])
    local nums = data.extra_data.os__lifengh[2]
    table.sort(nums)
    local card = {}
    if player:isKongcheng() and room:askToSkillInvoke(player, {
      skill_name = "os__lifengh",
      prompt = "#os__lifengh-draw:"..src.id..":"..nums[1]..":"..nums[2],
    }) then
      card = player:drawCards(1, lifengh.name)
    elseif not player:isKongcheng() then
      card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = lifengh.name,
        cancelable = true,
        prompt = "#os__lifengh-recast:"..src.id.."::"..nums[1]..":"..nums[2],
      })
      if #card > 0 then
        room:recastCard(card, player, lifengh.name)
      end
    end
    if #card > 0 then
      local n = Fk:getCardById(card[1]).number
      if n >= nums[1] and n <= nums[2] then
        room:invalidateSkill(src, "os__lifengh", "-turn")
        data:preventDamage()
      end
    end
  end,
})

return lifengh

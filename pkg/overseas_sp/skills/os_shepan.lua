local osShepan = fk.CreateSkill {
  name = "os__shepan"
}

Fk:loadTranslationTable{
  ["os__shepan"] = "慑叛",
  [":os__shepan"] = "每回合限一次，当你成为其他角色使用牌的目标时，你可选择一项：1.摸一张牌；" ..
  "2.将其区域内一张牌置于牌堆顶，然后若你与其手牌数相同，则此技能视为未发动过，且你可令此牌对你无效。",

  ["os__shepan_draw"] = "摸一张牌",
  ["os__shepan_put"] = "将其区域内一张牌置于牌堆顶",
  ["#os__shepan"] = "你可选择一项，对 %dest 发动技能“慑叛”",
  ["os__shepan_nullify"] = "令此牌对你无效",
  ["#os__shepan_nullify"] = "慑叛：你可令【%arg】对你无效",

  ["$os__shepan1"] = "遣五军案大道发还，贼望必喜而轻敌。",
  ["$os__shepan2"] = "以所获铠马驰环城，贼见必怒而失智。",
}

osShepan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osShepan.name) and
      player:usedSkillTimes(osShepan.name) < 1 and
      data.from ~= player
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local from = data.from
    local choices = { "os__shepan_draw", "Cancel" }
    if not from:isAllNude() then table.insert(choices, 2, "os__shepan_put") end
    local choice = room:askToChoice(
      player,
      {
        choices = choices,
        skill_name = osShepan.name,
        prompt = "#os__shepan::" .. data.from.id,
      }
    )
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osShepan.name
    local choice = event:getCostData(self)
    local room = player.room
    local from = data.from
    if choice == "os__shepan_draw" then
      player:drawCards(1, skillName)
    else
      local id = room:askToChooseCard(
        player,
        {
          target = from,
          flag = "hej",
          skill_name = skillName,
        }
      )
      room:moveCardTo(id, Card.DrawPile, nil, fk.ReasonPut, skillName, nil, false, player)
    end
    if player:getHandcardNum() == from:getHandcardNum() then
      player:addSkillUseHistory(skillName, -1)
      if
        room:askToChoice(
          player,
          {
            choices = { "os__shepan_nullify", "Cancel" },
            skill_name = skillName,
            prompt = "#os__shepan_nullify:::" .. data.card.name
          }
        ) == "os__shepan_nullify"
      then
        data.nullified = true
        if data.card.sub_type == Card.SubtypeDelayedTrick then
          data:cancelTarget(player)
        end
      end
    end
  end,
})

return osShepan

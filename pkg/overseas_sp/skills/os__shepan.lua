local os__shepan = fk.CreateSkill {
  name = "os__shepan"
}

Fk:loadTranslationTable{
  ['os__shepan'] = '慑叛',
  ['os__shepan_draw'] = '摸一张牌',
  ['os__shepan_put'] = '将其区域内一张牌置于牌堆顶',
  ['#os__shepan'] = '你可选择一项，对 %dest 发动技能“慑叛”',
  ['os__shepan_nullify'] = '令此牌对你无效',
  ['#os__shepan_nullify'] = '慑叛：你可令【%arg】对你无效',
  [':os__shepan'] = '每回合限一次，当你成为其他角色使用牌的目标时，你可选择一项：1.摸一张牌；2.将其区域内一张牌置于牌堆顶，然后若你与其手牌数相同，则此技能视为未发动过，且你可令此牌对你无效。',
  ['$os__shepan1'] = '遣五军案大道发还，贼望必喜而轻敌。',
  ['$os__shepan2'] = '以所获铠马驰环城，贼见必怒而失智。',
}

os__shepan:addEffect(fk.TargetConfirming, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__shepan) and player:usedSkillTimes(os__shepan.name) < 1 and data.from ~= player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local from = room:getPlayerById(data.from)
    local choices = {"os__shepan_draw", "Cancel"}
    if not from:isAllNude() then table.insert(choices, 2, "os__shepan_put") end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__shepan.name,
      prompt = "#os__shepan::" .. data.from
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local choice = event:getCostData(self)
    local room = player.room
    local from = room:getPlayerById(data.from)
    if choice == "os__shepan_draw" then
      player:drawCards(1, os__shepan.name)
    else
      room:moveCardTo({room:askToChooseCard(player, {
        target = from,
        flag = "hej",
        skill_name = os__shepan.name
      })}, Card.DrawPile, nil, fk.ReasonPut, os__shepan.name, nil, false)
    end
    if player:getHandcardNum() == from:getHandcardNum() then
      player:addSkillUseHistory(os__shepan.name, -1)
      if room:askToChoice(player, {
        choices = {"os__shepan_nullify", "Cancel"},
        skill_name = os__shepan.name,
        prompt = "#os__shepan_nullify:::" .. data.card.name
      }) == "os__shepan_nullify" then
        table.insertIfNeed(data.nullifiedTargets, player.id)
        if data.card.sub_type == Card.SubtypeDelayedTrick then
          AimGroup:cancelTarget(data, player.id)
        end
      end
    end
  end,
})

return os__shepan

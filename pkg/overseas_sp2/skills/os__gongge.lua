local os__gongge = fk.CreateSkill {
  name = "os__gongge"
}

Fk:loadTranslationTable{
  ['os__gongge'] = '攻阁',
  ['os__gongge_draw'] = '摸%arg张牌',
  ['os__gongge_damage'] = '对%src伤害+%arg',
  ['os__gongge_discard'] = '弃置%src%arg张牌',
  ['#os__gongge-choice'] = '你想对 %dest 发动技能“攻阁”吗？',
  ['@os__gongge'] = '攻阁',
  ['os__gonggeDraw'] = '摸牌',
  ['os__gonggeDiscard'] = '弃牌',
  ['os__gonggeDamage'] = '加伤',
  ['#os__gongge_judge'] = '攻阁',
  ['@@os__gongge_skip'] = '攻阁跳摸牌',
  ['#os__gongge-cards'] = '攻阁：交给 %dest %arg张牌',
  [':os__gongge'] = '每回合限一次，当你使用伤害类的牌指定目标后，你可选择一项：1. 摸X+1张牌，若此牌被其响应，你跳过下次摸牌阶段；2. 弃置其X+1张牌，此牌结算后，若其体力值不小于你，你交给其X张牌；3. 此牌对其伤害值基数+X，此牌结算后其回复X点体力。（X为其武将技能数）',
  ['$os__gongge1'] = '弓弩并射难近其身，若退又恐难安己命！',
  ['$os__gongge2'] = '既已决心反之，当速擒吕布以溃其兵士！',
  ['$os__gongge3'] = '今行至如此，唯殊死一搏！',
}

-- 主技能
os__gongge:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__gongge) and player:usedSkillTimes(os__gongge.name) < 1 and data.card.is_damage_card and data.to
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local target = room:getPlayerById(data.to)
    local x = #getTrueSkills(target)
    local choices = {"os__gongge_draw:::" .. x + 1, "os__gongge_damage:" .. data.to ..  "::" .. x, "Cancel"}
    if #target:getCardIds{Player.Equip, Player.Hand} > x then table.insert(choices, 2, "os__gongge_discard:" .. data.to .. "::" .. x + 1) end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = os__gongge.name,
      prompt = "#os__gongge-choice::" .. data.to,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__gongge.name, "offensive")
    data.card.extra_data = data.card.extra_data or {}
    data.card.extra_data.os__gonggeTarget = data.to
    data.card.extra_data.os__gonggeUser = player.id
    local target = room:getPlayerById(data.to)
    room:doIndicate(player.id, {target.id})
    local choice = event:getCostData(self)
    local x = #getTrueSkills(target)
    if choice:startsWith("os__gongge_draw") then
      player:broadcastSkillInvoke(os__gongge.name, 1)
      player:drawCards(x+1, os__gongge.name)
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDraw")
    elseif choice:startsWith("os__gongge_discard") then
      player:broadcastSkillInvoke(os__gongge.name, 2)
      local cards = room:askToChooseCards(player, {
        min_num = x + 1,
        max_num = x + 1,
        target = target,
        flag = "he",
        skill_name = os__gongge.name
      })
      room:throwCard(cards, os__gongge.name, target, player)
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDiscard")
    elseif choice:startsWith("os__gongge_damage") then
      player:broadcastSkillInvoke(os__gongge.name, 3)
      data.additionalDamage = (data.additionalDamage or 0) + x
      room:setPlayerMark(player, "@os__gongge", "os__gonggeDamage")
    end
  end,
})

-- 判断技能
os__gongge:addEffect({fk.CardUseFinished, fk.EventPhaseChanging}, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player then return false end
    if event == fk.EventPhaseChanging then
      return data.to == Player.Draw and player:getMark("@@os__gongge_skip") ~= 0
    else
      return (data.card.extra_data or {}).os__gonggeUser == player.id and player:getMark("@os__gongge") ~= 0
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseChanging then
      room:setPlayerMark(player, "@@os__gongge_skip", 0)
      return true
    else
      local target = room:getPlayerById(data.card.extra_data.os__gonggeTarget)
      if target.dead then
        room:setPlayerMark(player, "@os__gongge", 0)
      end
      local x = #getTrueSkills(target)
      if player:getMark("@os__gongge") == "os__gonggeDiscard" then
        if target.hp >= player.hp then
          local cids
          if #player:getCardIds{Player.Equip, Player.Hand}> x then
            cids = room:askToCards(player, {
              min_num = x,
              max_num = x,
              include_equip = true,
              skill_name = os__gongge.name,
              prompt = "#os__gongge-cards::" .. target.id .. ":" .. x,
            })
          else
            cids = player:getCardIds{Player.Equip, Player.Hand}
          end
          if #cids > 0 then
            room:moveCardTo(cids, Player.Hand, target, fk.ReasonGive, os__gongge.name, nil, false)
          end
        end
      elseif player:getMark("@os__gongge") == "os__gonggeDamage" then
        room:recover({
          who = target,
          num = math.min(x, target.maxHp - target.hp),
          recoverBy = player,
          skillName = os__gongge.name,
        })
      end
      room:setPlayerMark(player, "@os__gongge", 0)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__gongge") == "os__gonggeDraw" and ((event == fk.CardUseFinished and data.toCard and (data.toCard.extra_data or {}).os__gonggeTarget == target.id) or (event == fk.CardRespondFinished and (data.responseToEvent.card.extra_data or {}).os__gonggeTarget == target.id)) and
      data.responseToEvent and data.responseToEvent.from == player.id 
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@os__gongge_skip", 1)
  end,
})

return os__gongge

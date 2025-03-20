local os__jiekuang = fk.CreateSkill {
  name = "os__jiekuang"
}

Fk:loadTranslationTable{
  ['os__jiekuang'] = '竭匡',
  ['os__jiekuang_hp'] = '失去1点体力',
  ['os__jiekuang_maxhp'] = '减1点体力上限',
  ['#os__jiekuang'] = '竭匡：你可失去1点体力或减1点体力上限，代替 %src 成为【%arg】的目标',
  [':os__jiekuang'] = '每回合限一次，当一名体力值小于你的角色成为其他角色使用基本牌或普通锦囊牌的唯一目标后，若没有角色处于濒死状态，你可失去1点体力或减1点体力上限，然后你代替其成为此牌目标。当此牌结算结束后，若此牌未造成伤害且此牌的使用者可成为此牌的合法目标，则视为你对此牌的使用者使用一张同名牌。',
  ['$os__jiekuang1'] = '昔汉帝安疆之恩，今当竭力以报。',
  ['$os__jiekuang2'] = '发兵援汉，以示竭忠之心。',
}

os__jiekuang:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__jiekuang.name) and target.hp < player.hp and player:usedSkillTimes(os__jiekuang.name) < 1 and data.from ~= player.id and #AimGroup:getAllTargets(data.tos) == 1 
      and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and table.every(player.room.alive_players, function(p)
        return not p.dying
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local choices = {"os__jiekuang_hp", "os__jiekuang_maxhp", "Cancel"}
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = os__jiekuang.name,
      prompt = "#os__jiekuang:" .. data.to .. "::" .. data.card.name
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(skill)
    if choice == "os__jiekuang_hp" then 
      room:loseHp(player, 1, os__jiekuang.name)
    else 
      room:changeMaxHp(player, -1) 
    end
    if player.dead then return false end
    data.extra_data = data.extra_data or {}
    data.extra_data.os__jiekuangUser = player.id
    AimGroup:cancelTarget(data, data.to)
    local user = room:getPlayerById(data.from)
    if not user:isProhibited(player, data.card) then
      AimGroup:addTargets(room, data, player.id)
    end
  end,
})

os__jiekuang:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return data.card and (data.extra_data or {}).os__jiekuangUser == player.id and not player:prohibitUse(Fk:cloneCard(data.card.name)) and not player:isProhibited(target, Fk:cloneCard(data.card.name))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:useVirtualCard(data.card.name, nil, player, target, os__jiekuang.name)
  end,
})

os__jiekuang:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return data.card and (data.card.extra_data or {}).os__jiekuangUser == player.id
  end,
  on_refresh = function(self, event, target, player, data)
    data.card.extra_data.os__jiekuangUser = nil
  end,
})

return os__jiekuang

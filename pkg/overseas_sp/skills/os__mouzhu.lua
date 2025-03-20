local os__mouzhu = fk.CreateSkill {
  name = "os__mouzhu"
}

Fk:loadTranslationTable{
  ['os__mouzhu'] = '谋诛',
  ['#os__mouzhu-card'] = '谋诛：你可将一张牌交给 %dest',
  ['#os__mouzhu-ask'] = '谋诛：选择 %dest 视为对你使用伤害基数为 %arg 的【杀】或【决斗】',
  [':os__mouzhu'] = '出牌阶段限一次，你可选择一名其他角色A，然后除其外体力值不大于你的其他角色B依次选择是否交给你一张牌。若你未因此获得牌，则你与所有B失去1点体力；否则A选择你视为对其使用一张伤害值基数为X的【杀】或【决斗】（X为你以此法获得的牌数且至多为4）。',
  ['$os__mouzhu1'] = '汝等罪大恶极，快快伏法。',
  ['$os__mouzhu2'] = '宦官专权，今必诛之。',
}

os__mouzhu:addEffect('active', {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(skill.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local hp = player.hp
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return (p.hp <= hp and p ~= target)
    end),
      Util.IdMapper)
    room:doIndicate(player.id, targets)
    local x = 0
    for _, p in ipairs(targets) do
      p = room:getPlayerById(p)
      local cids = room:askToCards(p, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = skill.name,
        cancelable = true,
        prompt = "#os__mouzhu-card::" .. player.id
      })
      if #cids > 0 then
        room:moveCardTo(cids[1], Player.Hand, player, fk.ReasonGive, skill.name, nil, false)
        x = x + 1
      end
    end

    if x == 0 then
      table.insert(targets, 1, player.id)
      table.forEach(targets, function(p)
        room:loseHp(room:getPlayerById(p), 1, skill.name)
      end)
    else
      local card = Fk:cloneCard(room:askToChoice(target, {
        choices = {"slash", "duel"},
        skill_name = skill.name,
        prompt = "#os__mouzhu-ask::" .. player.id .. ":" .. tostring(x)
      }))
      card.skillName = skill.name
      local new_use = {}
      new_use.from = player.id
      new_use.tos = { {target.id} }
      new_use.card = card
      new_use.additionalDamage = math.min(x - 1, 3)
      new_use.extraUse = true
      room:useCard(new_use)
    end
  end,
})

return os__mouzhu

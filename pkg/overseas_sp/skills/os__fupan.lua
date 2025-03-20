local os__fupan = fk.CreateSkill {
  name = "os__fupan"
}

Fk:loadTranslationTable{
  ['os__fupan'] = '复叛',
  ['#os__fupan-give'] = '复叛：交给一名其他角色一张牌',
  ['os__fupan_dmg'] = '对%dest造成1点伤害，然后不能再以此法交给其牌',
  [':os__fupan'] = '当你造成或受到伤害后，你可摸X张牌（X为伤害值），然后交给一名其他角色一张牌。若你未以此法交给过其牌，你摸两张牌；否则，你可对其造成1点伤害，然后你不能再以此法交给其牌。',
  ['$os__fupan1'] = '胜者为王，吾等……无话可说……',
  ['$os__fupan2'] = '今乱平阳之地，汉人如何可防？',
  ['$os__fupan3'] = '此为吾等，复兴匈奴之良机！',
}

os__fupan:addEffect(fk.Damage, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(data.damage, skill.name)
    if player.dead then return end
    local os__fupan_invalid = player:getTableMark("_os__fupan_invalid")
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return not table.contains(os__fupan_invalid, p.id)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 or player:isNude() then return false end
    local plist, cid = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = availableTargets,
      min_target_num = 1,
      max_target_num = 1,
      prompt = "#os__fupan-give",
      skill_name = skill.name,
      target_tip_name = "os__fupan_tip"
    })
    local pid = plist[1]
    room:moveCardTo(cid, Player.Hand, room:getPlayerById(pid), fk.ReasonGive, skill.name, nil, false)

    if player.dead then return end
    local targetedFirstTime = table.contains(player:getTableMark("_os__fupan_once"), pid)

    if not targetedFirstTime then
      room:addTableMark(player, "_os__fupan_once", pid)
      player:drawCards(2, skill.name)
    elseif room:askToChoice(player, {
        choices = {"os__fupan_dmg::" .. pid, "Cancel"},
        skill_name = skill.name
      }) ~= "Cancel" then
      table.insertIfNeed(os__fupan_invalid, pid)
      room:setPlayerMark(player, "_os__fupan_invalid", os__fupan_invalid)
      room:damage{
        from = player,
        to = room:getPlayerById(pid),
        damage = 1,
        skillName = skill.name,
      }
    end
  end
})

os__fupan:addEffect(fk.Damaged, {
  anim_type = "drawcard",
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(data.damage, skill.name)
    if player.dead then return end
    local os__fupan_invalid = player:getTableMark("_os__fupan_invalid")
    local availableTargets = table.map(
      table.filter(room:getOtherPlayers(player, false), function(p)
        return not table.contains(os__fupan_invalid, p.id)
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 or player:isNude() then return false end
    local plist, cid = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = availableTargets,
      min_target_num = 1,
      max_target_num = 1,
      prompt = "#os__fupan-give",
      skill_name = skill.name,
      target_tip_name = "os__fupan_tip"
    })
    local pid = plist[1]
    room:moveCardTo(cid, Player.Hand, room:getPlayerById(pid), fk.ReasonGive, skill.name, nil, false)

    if player.dead then return end
    local targetedFirstTime = table.contains(player:getTableMark("_os__fupan_once"), pid)

    if not targetedFirstTime then
      room:addTableMark(player, "_os__fupan_once", pid)
      player:drawCards(2, skill.name)
    elseif room:askToChoice(player, {
        choices = {"os__fupan_dmg::" .. pid, "Cancel"},
        skill_name = skill.name
      }) ~= "Cancel" then
      table.insertIfNeed(os__fupan_invalid, pid)
      room:setPlayerMark(player, "_os__fupan_invalid", os__fupan_invalid)
      room:damage{
        from = player,
        to = room:getPlayerById(pid),
        damage = 1,
        skillName = skill.name,
      }
    end
  end
})

os__fupan:addEffect("on_lose", {
  on_use = function(self, event, target, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "_os__fupan_once", 0)
    room:setPlayerMark(player, "_os__fupan_invalid", 0)
  end
})

return os__fupan
